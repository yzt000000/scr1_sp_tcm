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
    output  type_scr1_mem_resp_e            dmem_resp
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

// Address decode results
logic                                   itcm_imem_sel;
logic                                   dtcm_imem_sel;
logic                                   itcm_dmem_sel;
logic                                   dtcm_dmem_sel;

//-------------------------------------------------------------------------------
// Address decode
//-------------------------------------------------------------------------------
assign itcm_imem_sel = ((imem_addr & SCR1_ITCM_ADDR_MASK) == SCR1_ITCM_ADDR_PATTERN);
assign dtcm_imem_sel = ((imem_addr & SCR1_DTCM_ADDR_MASK) == SCR1_DTCM_ADDR_PATTERN);
assign itcm_dmem_sel = ((dmem_addr & SCR1_ITCM_ADDR_MASK) == SCR1_ITCM_ADDR_PATTERN);
assign dtcm_dmem_sel = ((dmem_addr & SCR1_DTCM_ADDR_MASK) == SCR1_DTCM_ADDR_PATTERN);

//-------------------------------------------------------------------------------
// Request steering
//-------------------------------------------------------------------------------
assign i_imem_req   = imem_req & itcm_imem_sel;
assign d_imem_req   = imem_req & dtcm_imem_sel;

assign i_dmem_req   = dmem_req & itcm_dmem_sel;
assign d_dmem_req   = dmem_req & dtcm_dmem_sel;

//-------------------------------------------------------------------------------
// Response merging
//-------------------------------------------------------------------------------
// A bank only raises req_ack/resp when it is actually selected, so the merged
// handshake is simply the OR of the two banks.
assign imem_req_ack = i_imem_req_ack | d_imem_req_ack;
assign dmem_req_ack = i_dmem_req_ack | d_dmem_req_ack;

assign imem_rdata   = itcm_imem_sel ? i_imem_rdata : d_imem_rdata;
assign imem_resp    = itcm_imem_sel ? i_imem_resp  : d_imem_resp;

assign dmem_rdata   = itcm_dmem_sel ? i_dmem_rdata : d_dmem_rdata;
assign dmem_resp    = itcm_dmem_sel ? i_dmem_resp  : d_dmem_resp;

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
    .dmem_resp      ( i_dmem_resp   )
);

//-------------------------------------------------------------------------------
// DTCM instance
//-------------------------------------------------------------------------------
scr1_dtcm #(
    .SCR1_TCM_SIZE  ( SCR1_DTCM_SIZE )
) i_dtcm (
    .clk            ( clk           ),
    .rst_n          ( rst_n         ),

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
    .dmem_resp      ( d_dmem_resp   )
);

endmodule : scr1_tcm

`endif // SCR1_TCM_EN
