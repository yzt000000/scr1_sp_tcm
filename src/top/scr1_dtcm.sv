/// Copyright by Syntacore LLC © 2016-2021. See LICENSE for details
/// @file       <scr1_dtcm.sv>
/// @brief      Data Tightly-Coupled Memory (DTCM)
///
/// @details    One bank of the TCM: a SINGLE-PORT synchronous RAM that owns
///             its own address window (SCR1_DTCM_ADDR_PATTERN), exactly like
///             the DTCM of a classic MCU.
///
///             The single port is shared between the instruction interface and
///             the data interface, so accesses are arbitrated:
///               * data accesses have priority (this is a DTCM)
///               * a fetch that has been pending for SCR1_MAX_WAIT clocks
///                 becomes "urgent" and takes over
///               * if both sides are urgent the grant strictly alternates
///             The last point is what prevents the IFU from being starved by a
///             continuous data-access stream.
///
///             Protocol is fully pipelined: the address is driven in the
///             grant cycle, the RAM delivers the data on the next clock, and
///             the response is raised in that same next clock together with
///             the data. A new access may be granted every clock.

`include "scr1_memif.svh"
`include "scr1_arch_description.svh"

`ifdef SCR1_TCM_EN
module scr1_dtcm
#(
    parameter SCR1_TCM_SIZE  = `SCR1_IMEM_AWIDTH'h00010000,
    // Number of clocks a request may lose arbitration before it is treated
    // as urgent. 0 disables the anti-starvation boost (strict priority).
    parameter int unsigned SCR1_MAX_WAIT = 2
)
(
    // Control signals
    input   logic                           clk,
    input   logic                           rst_n,

    // Core instruction interface
    output  logic                           imem_req_ack,
    input   logic                           imem_req,
    input   type_scr1_mem_cmd_e             imem_cmd,
    input   logic [`SCR1_IMEM_AWIDTH-1:0]   imem_addr,
    output  logic [`SCR1_IMEM_DWIDTH-1:0]   imem_rdata,
    output  type_scr1_mem_resp_e            imem_resp,

    // Core data interface
    output  logic                           dmem_req_ack,
    input   logic                           dmem_req,
    input   type_scr1_mem_cmd_e             dmem_cmd,
    input   type_scr1_mem_width_e           dmem_width,
    input   logic [`SCR1_DMEM_AWIDTH-1:0]   dmem_addr,
    input   logic [`SCR1_DMEM_DWIDTH-1:0]   dmem_wdata,
    output  logic [`SCR1_DMEM_DWIDTH-1:0]   dmem_rdata,
    output  type_scr1_mem_resp_e            dmem_resp
);

//-------------------------------------------------------------------------------
// Local parameters
//-------------------------------------------------------------------------------
localparam int unsigned SCR1_AWIDTH  = $clog2(SCR1_TCM_SIZE);
// This bank grants data accesses by default
localparam bit          SCR1_IMEM_PRIO = 1'b0;

//-------------------------------------------------------------------------------
// Local signal declaration
//-------------------------------------------------------------------------------
logic                                   imem_grant;
logic                                   dmem_grant;
logic                                   imem_grant_r;
logic                                   dmem_grant_r;
logic                                   last_served_d;

logic [1:0]                             imem_wait_cnt;
logic [1:0]                             dmem_wait_cnt;
logic                                   imem_urgent;
logic                                   dmem_urgent;

logic                                   mem_wen;
logic                                   mem_ren;
logic [SCR1_AWIDTH-1:2]                 mem_addr;
logic [3:0]                             mem_byteen;
logic [`SCR1_DMEM_DWIDTH-1:0]           mem_writedata;
logic [`SCR1_DMEM_DWIDTH-1:0]           mem_rdata;

logic [3:0]                             dmem_byteen;
logic [`SCR1_DMEM_DWIDTH-1:0]           dmem_writedata;
logic [1:0]                             dmem_rdata_shift_reg;

//-------------------------------------------------------------------------------
// Arbitration
//-------------------------------------------------------------------------------
// Pending counters: how long a request has been losing arbitration
always_ff @(posedge clk, negedge rst_n) begin
    if (~rst_n) begin
        imem_wait_cnt <= '0;
        dmem_wait_cnt <= '0;
    end else begin
        imem_wait_cnt <= (~imem_req)      ? '0
                       : (imem_grant)     ? '0
                       : (&imem_wait_cnt) ? imem_wait_cnt
                       : imem_wait_cnt + 1'b1;
        dmem_wait_cnt <= (~dmem_req)      ? '0
                       : (dmem_grant)     ? '0
                       : (&dmem_wait_cnt) ? dmem_wait_cnt
                       : dmem_wait_cnt + 1'b1;
    end
end

assign imem_urgent = imem_req & (imem_wait_cnt >= SCR1_MAX_WAIT[1:0]);
assign dmem_urgent = dmem_req & (dmem_wait_cnt >= SCR1_MAX_WAIT[1:0]);

always_comb begin
    if (imem_req && dmem_req) begin
        if (imem_urgent ^ dmem_urgent) begin
            // Exactly one side is starving: serve it
            imem_grant = imem_urgent;
            dmem_grant = dmem_urgent;
        end else if (imem_urgent && dmem_urgent) begin
            // Both are starving: strictly alternate to stay fair
            imem_grant =  last_served_d;
            dmem_grant = ~last_served_d;
        end else begin
            // Nobody is starving: configured priority applies
            imem_grant =  SCR1_IMEM_PRIO;
            dmem_grant = ~SCR1_IMEM_PRIO;
        end
    end else begin
        imem_grant = imem_req;
        dmem_grant = dmem_req;
    end
end

always_ff @(posedge clk, negedge rst_n) begin
    if (~rst_n) begin
        imem_grant_r  <= 1'b0;
        dmem_grant_r  <= 1'b0;
        last_served_d <= 1'b0;
    end else begin
        imem_grant_r  <= imem_grant;
        dmem_grant_r  <= dmem_grant;
        if (dmem_grant) last_served_d <= 1'b1;
        if (imem_grant) last_served_d <= 1'b0;
    end
end

//-------------------------------------------------------------------------------
// Core interface handshakes and responses
//-------------------------------------------------------------------------------
// req_ack is the back-pressure: a request is accepted only when it is granted
assign imem_req_ack = imem_grant;
assign dmem_req_ack = dmem_grant;

// The RAM has one register stage: data of a granted access appears on the next
// clock, and the response is raised together with that data.
assign imem_resp = imem_grant_r ? SCR1_MEM_RESP_RDY_OK : SCR1_MEM_RESP_NOTRDY;
assign dmem_resp = dmem_grant_r ? SCR1_MEM_RESP_RDY_OK : SCR1_MEM_RESP_NOTRDY;

//-------------------------------------------------------------------------------
// Access composing
//-------------------------------------------------------------------------------
always_comb begin
    dmem_writedata = dmem_wdata;
    dmem_byteen    = 4'b1111;
    case (dmem_width)
        SCR1_MEM_WIDTH_BYTE : begin
            dmem_writedata = {(`SCR1_DMEM_DWIDTH /  8){dmem_wdata[7:0]}};
            dmem_byteen    = 4'b0001 << dmem_addr[1:0];
        end
        SCR1_MEM_WIDTH_HWORD : begin
            dmem_writedata = {(`SCR1_DMEM_DWIDTH / 16){dmem_wdata[15:0]}};
            dmem_byteen    = 4'b0011 << {dmem_addr[1], 1'b0};
        end
        default : begin
        end
    endcase
end

assign mem_addr     = dmem_grant ? dmem_addr[SCR1_AWIDTH-1:2]
                                 : imem_addr[SCR1_AWIDTH-1:2];
assign mem_wen      = dmem_grant & (dmem_cmd == SCR1_MEM_CMD_WR);
assign mem_ren      = ~mem_wen;
assign mem_byteen   = dmem_byteen;
assign mem_writedata = dmem_writedata;

//-------------------------------------------------------------------------------
// Memory instantiation
//-------------------------------------------------------------------------------
scr1_sp_memory #(
    .SCR1_WIDTH ( `SCR1_DMEM_DWIDTH ),
    .SCR1_SIZE  ( SCR1_TCM_SIZE     )
) i_dtcm_mem (
    .clk    ( clk           ),
    .wen    ( mem_wen       ),
    .webb   ( mem_byteen    ),
    .ren    ( mem_ren       ),
    .addr   ( mem_addr      ),
    .datain ( mem_writedata ),
    .q      ( mem_rdata     )
);

//-------------------------------------------------------------------------------
// Read data output
//-------------------------------------------------------------------------------
assign imem_rdata = mem_rdata;

always_ff @(posedge clk, negedge rst_n) begin
    if (~rst_n) begin
        dmem_rdata_shift_reg <= '0;
    end else if (dmem_grant) begin
        dmem_rdata_shift_reg <= dmem_addr[1:0];
    end
end

assign dmem_rdata = mem_rdata >> (8 * dmem_rdata_shift_reg);

endmodule : scr1_dtcm

`endif // SCR1_TCM_EN
