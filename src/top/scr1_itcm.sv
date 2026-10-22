/// Copyright by Syntacore LLC © 2016-2021. See LICENSE for details
/// @file       <scr1_itcm.sv>
/// @brief      Instruction Tightly-Coupled Memory (ITCM)
///
/// @details    One bank of the TCM: a SINGLE-PORT synchronous RAM that owns
///             its own address window (SCR1_ITCM_ADDR_PATTERN), exactly like
///             the ITCM of a classic MCU.
///
///             The single port is shared between the instruction interface,
///             the data interface and the external subordinate (slave) port,
///             so accesses are arbitrated:
///               * instruction fetches have priority (this is an ITCM),
///                 data accesses come next, the external subordinate port is
///                 served last
///               * a request that has been pending for SCR1_MAX_WAIT clocks
///                 becomes "urgent" and takes over (the subordinate port uses
///                 a longer SCR1_SLV_MAX_WAIT threshold)
///               * if several sides are urgent the grant strictly rotates
///             The last point is what prevents the LSU / the external master
///             from being starved by a continuous instruction-fetch stream.
///
///             Protocol is fully pipelined: the address is driven in the
///             grant cycle, the RAM delivers the data on the next clock, and
///             the response is raised in that same next clock together with
///             the data. A new access may be granted every clock.

`include "scr1_memif.svh"
`include "scr1_arch_description.svh"

`ifdef SCR1_TCM_EN
module scr1_itcm
#(
    parameter SCR1_TCM_SIZE  = `SCR1_IMEM_AWIDTH'h00010000,
    // Number of clocks a core request may lose arbitration before it is
    // treated as urgent. 0 disables the anti-starvation boost (strict priority).
    parameter int unsigned SCR1_MAX_WAIT = 2,
    // Number of clocks the external subordinate (slave) port may lose
    // arbitration before it is treated as urgent
    parameter int unsigned SCR1_SLV_MAX_WAIT = 8
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
    output  type_scr1_mem_resp_e            dmem_resp,

    // External subordinate (slave) interface
    output  logic                           slv_req_ack,
    input   logic                           slv_req,
    input   type_scr1_mem_cmd_e             slv_cmd,
    input   type_scr1_mem_width_e           slv_width,
    input   logic [`SCR1_DMEM_AWIDTH-1:0]   slv_addr,
    input   logic [`SCR1_DMEM_DWIDTH-1:0]   slv_wdata,
    output  logic [`SCR1_DMEM_DWIDTH-1:0]   slv_rdata,
    output  type_scr1_mem_resp_e            slv_resp
);

//-------------------------------------------------------------------------------
// Local parameters
//-------------------------------------------------------------------------------
localparam int unsigned SCR1_AWIDTH  = $clog2(SCR1_TCM_SIZE);
// This bank grants instruction fetches by default
localparam bit          SCR1_IMEM_PRIO = 1'b1;

//-------------------------------------------------------------------------------
// Local signal declaration
//-------------------------------------------------------------------------------
logic                                   imem_grant;
logic                                   dmem_grant;
logic                                   slv_grant;
logic                                   imem_grant_r;
logic                                   dmem_grant_r;
logic                                   slv_grant_r;
logic [1:0]                             last_served;

logic [3:0]                             imem_wait_cnt;
logic [3:0]                             dmem_wait_cnt;
logic [3:0]                             slv_wait_cnt;
logic                                   imem_urgent;
logic                                   dmem_urgent;
logic                                   slv_urgent;

logic                                   mem_wen;
logic                                   mem_ren;
logic [SCR1_AWIDTH-1:2]                 mem_addr;
logic [3:0]                             mem_byteen;
logic [`SCR1_DMEM_DWIDTH-1:0]           mem_writedata;
logic [`SCR1_DMEM_DWIDTH-1:0]           mem_rdata;

logic [3:0]                             dmem_byteen;
logic [`SCR1_DMEM_DWIDTH-1:0]           dmem_writedata;
logic [1:0]                             dmem_rdata_shift_reg;

logic [3:0]                             slv_byteen;
logic [`SCR1_DMEM_DWIDTH-1:0]           slv_writedata;
logic [1:0]                             slv_rdata_shift_reg;

//-------------------------------------------------------------------------------
// Arbitration
//-------------------------------------------------------------------------------
// Pending counters: how long a request has been losing arbitration
always_ff @(posedge clk, negedge rst_n) begin
    if (~rst_n) begin
        imem_wait_cnt <= '0;
        dmem_wait_cnt <= '0;
        slv_wait_cnt  <= '0;
    end else begin
        imem_wait_cnt <= (~imem_req)      ? '0
                       : (imem_grant)     ? '0
                       : (&imem_wait_cnt) ? imem_wait_cnt
                       : imem_wait_cnt + 1'b1;
        dmem_wait_cnt <= (~dmem_req)      ? '0
                       : (dmem_grant)     ? '0
                       : (&dmem_wait_cnt) ? dmem_wait_cnt
                       : dmem_wait_cnt + 1'b1;
        slv_wait_cnt  <= (~slv_req)       ? '0
                       : (slv_grant)      ? '0
                       : (&slv_wait_cnt)  ? slv_wait_cnt
                       : slv_wait_cnt + 1'b1;
    end
end

assign imem_urgent = imem_req & (imem_wait_cnt >= SCR1_MAX_WAIT[3:0]);
assign dmem_urgent = dmem_req & (dmem_wait_cnt >= SCR1_MAX_WAIT[3:0]);
assign slv_urgent  = slv_req  & (slv_wait_cnt  >= SCR1_SLV_MAX_WAIT[3:0]);

always_comb begin
    imem_grant = 1'b0;
    dmem_grant = 1'b0;
    slv_grant  = 1'b0;
    if (imem_urgent | dmem_urgent | slv_urgent) begin
        // At least one requester is starving: grant rotates among the urgent
        // requesters, starting from the one following last_served
        case (last_served)
            2'd0 : begin // last served imem -> try dmem, slv, imem
                if      (dmem_urgent) dmem_grant = 1'b1;
                else if (slv_urgent ) slv_grant  = 1'b1;
                else                  imem_grant = 1'b1;
            end
            2'd1 : begin // last served dmem -> try slv, imem, dmem
                if      (slv_urgent ) slv_grant  = 1'b1;
                else if (imem_urgent) imem_grant = 1'b1;
                else                  dmem_grant = 1'b1;
            end
            default : begin // last served slv -> try imem, dmem, slv
                if      (imem_urgent) imem_grant = 1'b1;
                else if (dmem_urgent) dmem_grant = 1'b1;
                else                  slv_grant  = 1'b1;
            end
        endcase
    end else begin
        // Nobody is starving: configured priority applies - the core first
        // (imem over dmem in this bank), the external subordinate last
        if (SCR1_IMEM_PRIO) begin
            if      (imem_req) imem_grant = 1'b1;
            else if (dmem_req) dmem_grant = 1'b1;
            else if (slv_req ) slv_grant  = 1'b1;
        end else begin
            if      (dmem_req) dmem_grant = 1'b1;
            else if (imem_req) imem_grant = 1'b1;
            else if (slv_req ) slv_grant  = 1'b1;
        end
    end
end

always_ff @(posedge clk, negedge rst_n) begin
    if (~rst_n) begin
        imem_grant_r  <= 1'b0;
        dmem_grant_r  <= 1'b0;
        slv_grant_r   <= 1'b0;
        last_served   <= 2'd0;
    end else begin
        imem_grant_r  <= imem_grant;
        dmem_grant_r  <= dmem_grant;
        slv_grant_r   <= slv_grant;
        if (imem_grant)      last_served <= 2'd0;
        else if (dmem_grant) last_served <= 2'd1;
        else if (slv_grant)  last_served <= 2'd2;
    end
end

//-------------------------------------------------------------------------------
// Core interface handshakes and responses
//-------------------------------------------------------------------------------
// req_ack is the back-pressure: a request is accepted only when it is granted
assign imem_req_ack = imem_grant;
assign dmem_req_ack = dmem_grant;
assign slv_req_ack  = slv_grant;

// The RAM has one register stage: data of a granted access appears on the next
// clock, and the response is raised together with that data.
assign imem_resp = imem_grant_r ? SCR1_MEM_RESP_RDY_OK : SCR1_MEM_RESP_NOTRDY;
assign dmem_resp = dmem_grant_r ? SCR1_MEM_RESP_RDY_OK : SCR1_MEM_RESP_NOTRDY;
assign slv_resp  = slv_grant_r  ? SCR1_MEM_RESP_RDY_OK : SCR1_MEM_RESP_NOTRDY;

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

always_comb begin
    slv_writedata = slv_wdata;
    slv_byteen    = 4'b1111;
    case (slv_width)
        SCR1_MEM_WIDTH_BYTE : begin
            slv_writedata = {(`SCR1_DMEM_DWIDTH /  8){slv_wdata[7:0]}};
            slv_byteen    = 4'b0001 << slv_addr[1:0];
        end
        SCR1_MEM_WIDTH_HWORD : begin
            slv_writedata = {(`SCR1_DMEM_DWIDTH / 16){slv_wdata[15:0]}};
            slv_byteen    = 4'b0011 << {slv_addr[1], 1'b0};
        end
        default : begin
        end
    endcase
end

assign mem_addr      = slv_grant  ? slv_addr[SCR1_AWIDTH-1:2]
                     : dmem_grant ? dmem_addr[SCR1_AWIDTH-1:2]
                     :              imem_addr[SCR1_AWIDTH-1:2];
assign mem_wen       = slv_grant  ? (slv_cmd  == SCR1_MEM_CMD_WR)
                     : dmem_grant ? (dmem_cmd == SCR1_MEM_CMD_WR)
                     :              1'b0;
assign mem_ren       = ~mem_wen;
assign mem_byteen    = slv_grant ? slv_byteen    : dmem_byteen;
assign mem_writedata = slv_grant ? slv_writedata : dmem_writedata;

//-------------------------------------------------------------------------------
// Memory instantiation
//-------------------------------------------------------------------------------
scr1_sp_memory #(
    .SCR1_WIDTH ( `SCR1_DMEM_DWIDTH ),
    .SCR1_SIZE  ( SCR1_TCM_SIZE     )
) i_itcm_mem (
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
        slv_rdata_shift_reg  <= '0;
    end else if (dmem_grant) begin
        dmem_rdata_shift_reg <= dmem_addr[1:0];
    end else if (slv_grant) begin
        slv_rdata_shift_reg  <= slv_addr[1:0];
    end
end

assign dmem_rdata = mem_rdata >> (8 * dmem_rdata_shift_reg);
assign slv_rdata  = mem_rdata >> (8 * slv_rdata_shift_reg);

endmodule : scr1_itcm

`endif // SCR1_TCM_EN
