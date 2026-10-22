/// Copyright by Syntacore LLC © 2016-2021. See LICENSE for details
/// @file       <scr1_tcm.sv>
/// @brief      Tightly-Coupled Memory (TCM) top
///
/// @details    The TCM is implemented as TWO INDEPENDENT single-port memories,
///             in the same way a classic MCU separates ITCM and DTCM:
///
///                 ITCM  SCR1_ITCM_ADDR_PATTERN (0x0048_0000, 64K)
///                 DTCM  SCR1_DTCM_ADDR_PATTERN (0x0049_0000, 64K)
///
///             Each bank owns its own address window and its own single-port
///             RAM, so an instruction fetch in the ITCM window and a data
///             access in the DTCM window proceed fully in parallel - the two
///             banks never contend with each other. Contention only happens
///             when both interfaces hit the SAME bank, and is then resolved by
///             the arbiter inside that bank.
///
///             At router level both windows are covered by a single combined
///             window (SCR1_TCM_ADDR_MASK/PATTERN, 128K here); the ITCM/DTCM
///             split is resolved here.
///
///             Besides the core imem/dmem interfaces the TCM also exposes an
///             external subordinate (slave) port (sbr_*), fed by the AHB
///             subordinate bridge (scr1_tcm_ahb_sbr). It lets other bus
///             masters load programs and data into the ITCM/DTCM. Inside each
///             bank the subordinate port participates in the single-port
///             arbitration with the lowest priority plus an anti-starvation
///             boost, so reset-time loading (core idle) proceeds without
///             contention and runtime writes interleave safely with core
///             accesses.
///
///             The external interface (imem/dmem, memif protocol) and the
///             handshaking are unchanged with respect to the original
///             dual-port implementation, so no change is required in the
///             routers, the bridges or the testbench.

`include "scr1_memif.svh"
`include "scr1_arch_description.svh"

`ifdef SCR1_TCM_EN
module scr1_tcm
#(
    parameter SCR1_ITCM_SIZE = `SCR1_IMEM_AWIDTH'h00010000,
    parameter SCR1_DTCM_SIZE = `SCR1_IMEM_AWIDTH'h00010000
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

    // External subordinate interface (from the AHB subordinate bridge)
    output  logic                           sbr_req_ack,
    input   logic                           sbr_req,
    input   type_scr1_mem_cmd_e             sbr_cmd,
    input   type_scr1_mem_width_e           sbr_width,
    input   logic [`SCR1_DMEM_AWIDTH-1:0]   sbr_addr,
    input   logic [`SCR1_DMEM_DWIDTH-1:0]   sbr_wdata,
    output  logic [`SCR1_DMEM_DWIDTH-1:0]   sbr_rdata,
    output  type_scr1_mem_resp_e            sbr_resp
);

//-------------------------------------------------------------------------------
// Local signal declaration
//-------------------------------------------------------------------------------
// Requests routed to each bank
logic                                   i_imem_req;
logic                                   i_imem_req_ack;
logic [`SCR1_IMEM_DWIDTH-1:0]           i_imem_rdata;
type_scr1_mem_resp_e                    i_imem_resp;

logic                                   i_dmem_req;
logic                                   i_dmem_req_ack;
logic [`SCR1_DMEM_DWIDTH-1:0]           i_dmem_rdata;
type_scr1_mem_resp_e                    i_dmem_resp;

logic                                   d_imem_req;
logic                                   d_imem_req_ack;
logic [`SCR1_IMEM_DWIDTH-1:0]           d_imem_rdata;
type_scr1_mem_resp_e                    d_imem_resp;

logic                                   d_dmem_req;
logic                                   d_dmem_req_ack;
logic [`SCR1_DMEM_DWIDTH-1:0]           d_dmem_rdata;
type_scr1_mem_resp_e                    d_dmem_resp;

logic                                   i_slv_req;
logic                                   i_slv_req_ack;
logic [`SCR1_DMEM_DWIDTH-1:0]           i_slv_rdata;
type_scr1_mem_resp_e                    i_slv_resp;

logic                                   d_slv_req;
logic                                   d_slv_req_ack;
logic [`SCR1_DMEM_DWIDTH-1:0]           d_slv_rdata;
type_scr1_mem_resp_e                    d_slv_resp;

// Address decode results
logic                                   itcm_imem_sel;
logic                                   dtcm_imem_sel;
logic                                   itcm_dmem_sel;
logic                                   dtcm_dmem_sel;
logic                                   itcm_sbr_sel;
logic                                   dtcm_sbr_sel;

// Latched bank ownership of each outstanding (accepted) access
logic                                   itcm_imem_sel_r;
logic                                   dtcm_imem_sel_r;
logic                                   itcm_dmem_sel_r;
logic                                   dtcm_dmem_sel_r;
logic                                   itcm_sbr_sel_r;
logic                                   dtcm_sbr_sel_r;

//-------------------------------------------------------------------------------
// Address decode
//-------------------------------------------------------------------------------
assign itcm_imem_sel = ((imem_addr & SCR1_ITCM_ADDR_MASK) == SCR1_ITCM_ADDR_PATTERN);
assign dtcm_imem_sel = ((imem_addr & SCR1_DTCM_ADDR_MASK) == SCR1_DTCM_ADDR_PATTERN);
assign itcm_dmem_sel = ((dmem_addr & SCR1_ITCM_ADDR_MASK) == SCR1_ITCM_ADDR_PATTERN);
assign dtcm_dmem_sel = ((dmem_addr & SCR1_DTCM_ADDR_MASK) == SCR1_DTCM_ADDR_PATTERN);
assign itcm_sbr_sel  = ((sbr_addr  & SCR1_ITCM_ADDR_MASK) == SCR1_ITCM_ADDR_PATTERN);
assign dtcm_sbr_sel  = ((sbr_addr  & SCR1_DTCM_ADDR_MASK) == SCR1_DTCM_ADDR_PATTERN);

//-------------------------------------------------------------------------------
// Request steering
//-------------------------------------------------------------------------------
assign i_imem_req   = imem_req & itcm_imem_sel;
assign d_imem_req   = imem_req & dtcm_imem_sel;

assign i_dmem_req   = dmem_req & itcm_dmem_sel;
assign d_dmem_req   = dmem_req & dtcm_dmem_sel;

assign i_slv_req    = sbr_req  & itcm_sbr_sel;
assign d_slv_req    = sbr_req  & dtcm_sbr_sel;


//-------------------------------------------------------------------------------
// Bank ownership latching
//-------------------------------------------------------------------------------
// The response of an access arrives one clock after it was accepted, and the
// requester may have redirected its address in the meantime (a taken branch
// out of the TCM window, a new load address). Selecting the bank for the
// response merge from the CURRENT address would then look at the wrong bank
// and drop the response of the access still in flight - the router would wait
// forever and would have to re-drive the already-accepted request (a handshake
// violation: an extra transaction on a stateful subordinate). Instead the
// bank that owns each outstanding access is latched in the accept cycle
// (req & req_ack are both combinational on the accepted address, so the
// latched value is exact) and the merge below uses only the latched value.
always_ff @(posedge clk, negedge rst_n) begin
    if (~rst_n) begin
        itcm_imem_sel_r <= 1'b0;
        dtcm_imem_sel_r <= 1'b0;
        itcm_dmem_sel_r <= 1'b0;
        dtcm_dmem_sel_r <= 1'b0;
        itcm_sbr_sel_r  <= 1'b0;
        dtcm_sbr_sel_r  <= 1'b0;
    end else begin
        if (imem_req & imem_req_ack) begin
            itcm_imem_sel_r <= itcm_imem_sel;
            dtcm_imem_sel_r <= dtcm_imem_sel;
        end
        if (dmem_req & dmem_req_ack) begin
            itcm_dmem_sel_r <= itcm_dmem_sel;
            dtcm_dmem_sel_r <= dtcm_dmem_sel;
        end
        if (sbr_req & sbr_req_ack) begin
            itcm_sbr_sel_r  <= itcm_sbr_sel;
            dtcm_sbr_sel_r  <= dtcm_sbr_sel;
        end
    end
end

//-------------------------------------------------------------------------------
// Response merging
//-------------------------------------------------------------------------------
// A bank only raises req_ack/resp when it is actually selected, so the merged
// handshake is simply the OR of the two banks. Responses are merged with the
// LATCHED bank ownership - see the latching block above for the rationale.
assign imem_req_ack = i_imem_req_ack | d_imem_req_ack;
assign dmem_req_ack = i_dmem_req_ack | d_dmem_req_ack;
assign sbr_req_ack  = i_slv_req_ack  | d_slv_req_ack;

assign imem_rdata   = itcm_imem_sel_r ? i_imem_rdata : d_imem_rdata;
assign imem_resp    = itcm_imem_sel_r ? i_imem_resp  : d_imem_resp;

assign dmem_rdata   = itcm_dmem_sel_r ? i_dmem_rdata : d_dmem_rdata;
assign dmem_resp    = itcm_dmem_sel_r ? i_dmem_resp  : d_dmem_resp;

assign sbr_rdata    = itcm_sbr_sel_r  ? i_slv_rdata  : d_slv_rdata;
assign sbr_resp     = itcm_sbr_sel_r  ? i_slv_resp   : d_slv_resp;

//-------------------------------------------------------------------------------
// ITCM instance
//-------------------------------------------------------------------------------
scr1_itcm #(
    .SCR1_TCM_SIZE  ( SCR1_ITCM_SIZE )
) i_itcm (
    .clk            ( clk           ),
    .rst_n          ( rst_n         ),

    .imem_req_ack   ( i_imem_req_ack),
    .imem_req       ( i_imem_req    ),
    .imem_cmd       ( imem_cmd      ),
    .imem_addr      ( imem_addr     ),
    .imem_rdata     ( i_imem_rdata  ),
    .imem_resp      ( i_imem_resp   ),

    .dmem_req_ack   ( i_dmem_req_ack),
    .dmem_req       ( i_dmem_req    ),
    .dmem_cmd       ( dmem_cmd      ),
    .dmem_width     ( dmem_width    ),
    .dmem_addr      ( dmem_addr     ),
    .dmem_wdata     ( dmem_wdata    ),
    .dmem_rdata     ( i_dmem_rdata  ),
    .dmem_resp      ( i_dmem_resp   ),

    .slv_req_ack    ( i_slv_req_ack ),
    .slv_req        ( i_slv_req     ),
    .slv_cmd        ( sbr_cmd       ),
    .slv_width      ( sbr_width     ),
    .slv_addr       ( sbr_addr      ),
    .slv_wdata      ( sbr_wdata     ),
    .slv_rdata      ( i_slv_rdata   ),
    .slv_resp       ( i_slv_resp    )
);

//-------------------------------------------------------------------------------
// DTCM instance
//-------------------------------------------------------------------------------
scr1_dtcm #(
    .SCR1_TCM_SIZE  ( SCR1_DTCM_SIZE )
) i_dtcm (
    .clk            ( clk            ),
    .rst_n          ( rst_n          ),

    .imem_req_ack   ( d_imem_req_ack),
    .imem_req       ( d_imem_req    ),
    .imem_cmd       ( imem_cmd      ),
    .imem_addr      ( imem_addr     ),
    .imem_rdata     ( d_imem_rdata  ),
    .imem_resp      ( d_imem_resp   ),

    .dmem_req_ack   ( d_dmem_req_ack),
    .dmem_req       ( d_dmem_req    ),
    .dmem_cmd       ( dmem_cmd      ),
    .dmem_width     ( dmem_width    ),
    .dmem_addr      ( dmem_addr     ),
    .dmem_wdata     ( dmem_wdata    ),
    .dmem_rdata     ( d_dmem_rdata  ),
    .dmem_resp      ( d_dmem_resp   ),

    .slv_req_ack    ( d_slv_req_ack ),
    .slv_req        ( d_slv_req     ),
    .slv_cmd        ( sbr_cmd       ),
    .slv_width      ( sbr_width     ),
    .slv_addr       ( sbr_addr      ),
    .slv_wdata      ( sbr_wdata     ),
    .slv_rdata      ( d_slv_rdata   ),
    .slv_resp       ( d_slv_resp    )
);


endmodule : scr1_tcm

`endif // SCR1_TCM_EN
