/// Copyright by Syntacore LLC © 2016-2021. See LICENSE for details
/// @file       <scr1_tcm_ahb_sbr.sv>
/// @brief      AHB subordinate (slave) bridge for external TCM access
///
/// @details    Converts an external AHB master port into the internal TCM
///             memif-style request. It allows other bus masters (DMA engines,
///             host CPUs, debug masters...) to load programs and data directly
///             into the ITCM/DTCM through a dedicated AHB subordinate port.
///
///             Address map (real TCM addresses, same view as the core):
///                 0x0048_0000 .. 0x0048_FFFF   ITCM window
///                 0x0049_0000 .. 0x0049_FFFF   DTCM window
///                 anything else                ERROR response (two-cycle)
///
///             Transfers: SINGLE and bursts are supported. Burst beats with
///             HTRANS = SEQ are accepted in the IDLE state (after a BUSY
///             pause or a gap) and - pipelined - in the completion cycle of
///             the previous beat, so an INCR/WRAP burst streams at 2 clocks
///             per beat in the steady state. The address of every beat is
///             latched from HADDR as driven by the master (increment or wrap
///             is the master's business), HBURST is not decoded.
///
///             HSIZE of 8/16/32 bits is supported. The address must be
///             aligned to the transfer size (an AHB requirement) - a
///             misaligned transfer produces a two-cycle ERROR response
///             instead of silently returning rotated data.
///
///             Only ONE memif transaction is generated per accepted beat:
///             the request is withdrawn after req_ack, so the TCM bank does
///             not grant (and the RAM does not access) the same beat twice.
///
///             The bridge is reset by the system reset (not the core reset),
///             and so are the TCM banks (see the top level): an external
///             master can load the TCM while the CPU is still held in reset -
///             the banks answer normally because the core issues no
///             competing requests while it is in reset, i.e. reset-time
///             loading is naturally prioritized.

`include "scr1_ahb.svh"
`include "scr1_memif.svh"
`include "scr1_arch_description.svh"

`ifdef SCR1_TCM_EN
module scr1_tcm_ahb_sbr (
    // Control signals
    input  logic                           clk,
    input  logic                           rst_n,

    // AHB subordinate interface (driven by an external master)
    input  logic [3:0]                     hprot,
    input  logic [2:0]                     hburst,
    input  logic [2:0]                     hsize,
    input  logic [1:0]                     htrans,
    input  logic                           hmastlock,
    input  logic [SCR1_AHB_WIDTH-1:0]      haddr,
    input  logic                           hwrite,
    input  logic [SCR1_AHB_WIDTH-1:0]      hwdata,
    input  logic                           hreadyin,
    output logic                           hreadyout,
    output logic [SCR1_AHB_WIDTH-1:0]      hrdata,
    output logic                           hresp,

    // TCM slave memif request (to scr1_tcm sbr port)
    output logic                           sbr_req,
    output type_scr1_mem_cmd_e             sbr_cmd,
    output type_scr1_mem_width_e           sbr_width,
    output logic [`SCR1_DMEM_AWIDTH-1:0]   sbr_addr,
    output logic [`SCR1_DMEM_DWIDTH-1:0]   sbr_wdata,
    input  logic                           sbr_req_ack,
    input  logic [`SCR1_DMEM_DWIDTH-1:0]   sbr_rdata,
    input  type_scr1_mem_resp_e            sbr_resp
);

//-------------------------------------------------------------------------------
// Local parameters
//-------------------------------------------------------------------------------
typedef enum logic [1:0] {
    SCR1_SBR_FSM_IDLE = 2'd0,
    SCR1_SBR_FSM_WAIT = 2'd1,
    SCR1_SBR_FSM_ERR1 = 2'd2,
    SCR1_SBR_FSM_ERR2 = 2'd3
} type_scr1_sbr_fsm_e;

//-------------------------------------------------------------------------------
// Local signal declaration
//-------------------------------------------------------------------------------
type_scr1_sbr_fsm_e                         fsm;

logic                                       addr_phase;
logic                                       resp_ok;
logic                                       resp_err;
logic                                       burst_cont;
logic                                       tcm_hit;
logic                                       size_ok;
logic                                       req_ok;

// Latched address-phase attributes (of the beat currently in WAIT)
logic                                       lat_write;
logic [2:0]                                 lat_size;
logic [SCR1_AHB_WIDTH-1:0]                 lat_addr;

// One-transaction-per-beat request control
logic                                       req_active_r;

// Read data: combinational on the completion cycle, registered afterwards
logic [SCR1_AHB_WIDTH-1:0]                 rd_shifted;
logic [SCR1_AHB_WIDTH-1:0]                 lat_rdata;

//-------------------------------------------------------------------------------
// Response qualification
//-------------------------------------------------------------------------------
// The completion cycle of the current beat is the cycle in which the TCM
// response arrives: HREADYOUT is raised in THIS cycle and HRDATA is driven
// combinationally from the bank output (the master samples both at the end
// of this cycle)
assign resp_ok  = (fsm == SCR1_SBR_FSM_WAIT) & (sbr_resp == SCR1_MEM_RESP_RDY_OK);
assign resp_err = (fsm == SCR1_SBR_FSM_WAIT) & (sbr_resp == SCR1_MEM_RESP_RDY_ER);

//-------------------------------------------------------------------------------
// Address phase qualification
//-------------------------------------------------------------------------------
// A new beat is sampled
//   - in the IDLE state (a fresh NONSEQ, or a SEQ after a BUSY pause / gap)
//   - in the completion cycle of the previous beat (pipelined back-to-back
//     NONSEQ/SEQ: the address of the next beat is already on the bus and is
//     accepted together with the completion of the previous one)
// In both cases the bus must allow sampling (HREADYIN = 1). A completion
// cycle with HTRANS = IDLE/BUSY ends the stream and returns the FSM to IDLE.
assign addr_phase = ((fsm == SCR1_SBR_FSM_IDLE) | resp_ok)
                    & ((htrans == SCR1_HTRANS_NONSEQ)
                       | (htrans == SCR1_HTRANS_SEQ))
                    & hreadyin;

// Continue the burst without going through IDLE
assign burst_cont = resp_ok & addr_phase;

//-------------------------------------------------------------------------------
// Address decode and alignment check
//-------------------------------------------------------------------------------
assign tcm_hit = ((haddr & SCR1_TCM_ADDR_MASK) == SCR1_TCM_ADDR_PATTERN);

// Supported transfer sizes: 8/16/32 bits, address aligned to the size (an
// AHB requirement). A misaligned transfer is answered with ERROR instead of
// silently rotating the word.
assign size_ok = (hsize == SCR1_HSIZE_8B)
               | ((hsize == SCR1_HSIZE_16B) & ~haddr[0])
               | ((hsize == SCR1_HSIZE_32B) & (haddr[1:0] == 2'b00));

assign req_ok = tcm_hit & size_ok;

//-------------------------------------------------------------------------------
// FSM
//-------------------------------------------------------------------------------
always_ff @(posedge clk, negedge rst_n) begin
    if (~rst_n) begin
        fsm <= SCR1_SBR_FSM_IDLE;
    end else begin
        case (fsm)
            SCR1_SBR_FSM_IDLE : begin
                if (addr_phase) begin
                    fsm <= req_ok ? SCR1_SBR_FSM_WAIT : SCR1_SBR_FSM_ERR1;
                end
            end
            SCR1_SBR_FSM_WAIT : begin
                if (resp_ok) begin
                    if (burst_cont) begin
                        // Pipelined beat: the new address/size/write have
                        // been latched in this very cycle, stay in WAIT
                        fsm <= SCR1_SBR_FSM_WAIT;
                    end else begin
                        fsm <= SCR1_SBR_FSM_IDLE;
                    end
                end else if (resp_err) begin
                    // Defensive: the TCM banks never error, but if they do,
                    // report it to the master instead of hanging
                    fsm <= SCR1_SBR_FSM_ERR1;
                end
            end
            SCR1_SBR_FSM_ERR1 : begin
                fsm <= SCR1_SBR_FSM_ERR2;
            end
            SCR1_SBR_FSM_ERR2 : begin
                fsm <= SCR1_SBR_FSM_IDLE;
            end
            default : begin
                fsm <= SCR1_SBR_FSM_IDLE;
            end
        endcase
    end
end

always_ff @(posedge clk, negedge rst_n) begin
    if (~rst_n) begin
        lat_write <= 1'b0;
        lat_size  <= '0;
        lat_addr  <= '0;
    end else if (addr_phase) begin
        lat_write <= hwrite;
        lat_size  <= hsize;
        lat_addr  <= haddr;
    end
end

//-------------------------------------------------------------------------------
// TCM request generation - exactly ONE memif transaction per beat
//-------------------------------------------------------------------------------
// req_active_r marks "this beat has been issued but not yet accepted".
// It is set when a beat is sampled (addr_phase, including the pipelined
// case) and cleared as soon as the bank grants it (req_ack). sbr_req is
// therefore asserted for the issue cycles only - the bank does not grant
// (and the RAM does not access) the same beat twice while the response is
// being produced.
always_ff @(posedge clk, negedge rst_n) begin
    if (~rst_n) begin
        req_active_r <= 1'b0;
    end else if (addr_phase) begin
        req_active_r <= 1'b1;
    end else if (sbr_req_ack) begin
        req_active_r <= 1'b0;
    end
end


assign sbr_req   = (fsm == SCR1_SBR_FSM_WAIT) & req_active_r;
assign sbr_cmd   = lat_write ? SCR1_MEM_CMD_WR : SCR1_MEM_CMD_RD;
assign sbr_addr  = lat_addr;
assign sbr_wdata = hwdata;

always_comb begin
    case (lat_size)
        SCR1_HSIZE_8B  : begin
            sbr_width = SCR1_MEM_WIDTH_BYTE;
        end
        SCR1_HSIZE_16B : begin
            sbr_width = SCR1_MEM_WIDTH_HWORD;
        end
        default : begin
            sbr_width = SCR1_MEM_WIDTH_WORD;
        end
    endcase
end

//-------------------------------------------------------------------------------
// Read data return
//-------------------------------------------------------------------------------
// The TCM bank returns sub-word data right-justified (byte lane at [7:0]);
// AHB requires it back on the lanes addressed by HADDR. On the completion
// cycle the shifted data is driven combinationally (valid together with
// HREADYOUT); afterwards the registered copy stays on HRDATA.
always_comb begin
    case (lat_size)
        SCR1_HSIZE_8B  : begin
            rd_shifted = sbr_rdata << (8 * lat_addr[1:0]);
        end
        SCR1_HSIZE_16B : begin
            rd_shifted = sbr_rdata << (16 * lat_addr[1]);
        end
        default : begin
            rd_shifted = sbr_rdata;
        end
    endcase
end

always_ff @(posedge clk, negedge rst_n) begin
    if (~rst_n) begin
        lat_rdata <= '0;
    end else if (resp_ok) begin
        lat_rdata <= rd_shifted;
    end
end

assign hrdata = resp_ok ? rd_shifted : lat_rdata;

//-------------------------------------------------------------------------------
// AHB response
//-------------------------------------------------------------------------------
// HREADYOUT is high in the IDLE state and in the completion cycle of a beat
// (possibly overlapped with the acceptance of the next pipelined beat).
// The ERROR response takes the two standard cycles: ERR1 (not ready) and
// ERR2 (ready) - both with HRESP = 1.
assign hreadyout = (fsm == SCR1_SBR_FSM_IDLE)
                   | resp_ok
                   | (fsm == SCR1_SBR_FSM_ERR2);

assign hresp = (fsm == SCR1_SBR_FSM_ERR1) | (fsm == SCR1_SBR_FSM_ERR2);

endmodule : scr1_tcm_ahb_sbr

`endif // SCR1_TCM_EN