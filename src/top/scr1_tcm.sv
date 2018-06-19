/// Copyright by Syntacore LLC © 2016-2018. See LICENSE for details
/// @file       <scr1_tcm.sv>
/// @brief      Tightly-Coupled Memory (TCM)
///

`include "scr1_memif.svh"
`include "scr1_arch_description.svh"

`ifdef SCR1_TCM_EN
module scr1_tcm
#(
    parameter SCR1_TCM_SIZE = `SCR1_IMEM_AWIDTH'h00010000
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

logic                           i_imem_req_ack         ;
logic                           i_imem_req             ;
type_scr1_mem_cmd_e             i_imem_cmd             ;
logic [`SCR1_IMEM_AWIDTH-1:0]   i_imem_addr            ;
logic [`SCR1_IMEM_DWIDTH-1:0]   i_imem_rdata           ;
type_scr1_mem_resp_e            i_imem_resp            ;

// Core data interface
logic                           i_dmem_req_ack         ;
logic                           i_dmem_req             ;
type_scr1_mem_cmd_e             i_dmem_cmd             ;
type_scr1_mem_width_e           i_dmem_width           ;
logic [`SCR1_DMEM_AWIDTH-1:0]   i_dmem_addr            ;
logic [`SCR1_DMEM_DWIDTH-1:0]   i_dmem_wdata           ;
logic [`SCR1_DMEM_DWIDTH-1:0]   i_dmem_rdata           ;
type_scr1_mem_resp_e            i_dmem_resp            ;

logic                           d_imem_req_ack         ;
logic                           d_imem_req             ;
type_scr1_mem_cmd_e             d_imem_cmd             ;
logic [`SCR1_IMEM_AWIDTH-1:0]   d_imem_addr            ;
logic [`SCR1_IMEM_DWIDTH-1:0]   d_imem_rdata           ;
type_scr1_mem_resp_e            d_imem_resp            ;

// Core data interface
logic                           d_dmem_req_ack         ;
logic                           d_dmem_req             ;
type_scr1_mem_cmd_e             d_dmem_cmd             ;
type_scr1_mem_width_e           d_dmem_width           ;
logic [`SCR1_DMEM_AWIDTH-1:0]   d_dmem_addr            ;
logic [`SCR1_DMEM_DWIDTH-1:0]   d_dmem_wdata           ;
logic [`SCR1_DMEM_DWIDTH-1:0]   d_dmem_rdata           ;
type_scr1_mem_resp_e            d_dmem_resp            ;

logic  itcm_addr_match ;

assign itcm_addr_match = imem_addr[31:16] == 16'h0048 ; 
assign dtcm_addr_match = dmem_addr[31:16] == 16'h0048 ;

assign i_imem_req    = imem_req   && itcm_addr_match  ;
assign i_imem_cmd    = imem_cmd    ;
assign i_imem_addr   = imem_addr   ;

assign i_dmem_req    = dmem_req   && dtcm_addr_match  ;
assign i_dmem_cmd    = dmem_cmd    ;
assign i_dmem_width  = dmem_width  ;
assign i_dmem_addr   = dmem_addr   ;
assign i_dmem_wdata  = dmem_wdata  ;

assign d_imem_req    = imem_req   && ~itcm_addr_match ;
assign d_imem_cmd    = imem_cmd    ;
assign d_imem_addr   = imem_addr   ;

assign d_dmem_req    = dmem_req   && ~dtcm_addr_match ;
assign d_dmem_cmd    = dmem_cmd    ;
assign d_dmem_width  = dmem_width  ;
assign d_dmem_addr   = dmem_addr   ;
assign d_dmem_wdata  = dmem_wdata  ;

//assign imem_req_ack  = i_imem_req_ack | d_imem_req_ack                      ;
assign imem_req_ack  = 1'b1;
assign imem_rdata    = i_imem_req_ack ? i_imem_rdata   : d_imem_rdata       ;
assign imem_resp     = i_imem_req_ack ? i_imem_resp    : d_imem_resp;

//assign dmem_req_ack  = i_dmem_req_ack | d_dmem_req_ack ;
assign dmem_req_ack  = 1'b1; 
assign dmem_rdata    = i_dmem_req_ack ? i_dmem_rdata   : d_dmem_rdata       ;
assign dmem_resp     = i_dmem_req_ack ? i_dmem_resp    : d_dmem_resp        ;



scr1_itcm #(
        .SCR1_TCM_SIZE  (SCR1_TCM_SIZE)
)
scr1_itcm (/*autoinst*/
       // Interfaces
       .imem_cmd            (i_imem_cmd                          ),
       .imem_resp           (i_imem_resp                         ),
       .dmem_cmd            (i_dmem_cmd                          ),
       .dmem_width          (i_dmem_width                        ),
       .dmem_resp           (i_dmem_resp                         ),
       // Outputs
       .imem_req_ack        (i_imem_req_ack                      ),
       .imem_rdata          (i_imem_rdata[`SCR1_IMEM_DWIDTH-1:0] ),
       .dmem_req_ack        (i_dmem_req_ack),
       .dmem_rdata          (i_dmem_rdata[`SCR1_DMEM_DWIDTH-1:0] ),
       // Inputs
       .clk                 (clk                                 ),
       .rst_n               (rst_n                               ),
       .imem_req            (i_imem_req),
       .imem_addr           (i_imem_addr[`SCR1_IMEM_AWIDTH-1:0]  ),
       .dmem_req            (i_dmem_req),
       .dmem_addr           (i_dmem_addr[`SCR1_DMEM_AWIDTH-1:0]  ),
       .dmem_wdata          (i_dmem_wdata[`SCR1_DMEM_DWIDTH-1:0] )
 );


scr1_dtcm #(
        .SCR1_TCM_SIZE  (SCR1_TCM_SIZE)
)
scr1_dtcm (/*autoinst*/
       // Interfaces
       .imem_cmd            (d_imem_cmd                          ),
       .imem_resp           (d_imem_resp                         ),
       .dmem_cmd            (d_dmem_cmd                          ),
       .dmem_width          (d_dmem_width                        ),
       .dmem_resp           (d_dmem_resp                         ),
       // Outputs
       .imem_req_ack        (d_imem_req_ack                      ),
       .imem_rdata          (d_imem_rdata[`SCR1_IMEM_DWIDTH-1:0] ),
       .dmem_req_ack        (d_dmem_req_ack),
       .dmem_rdata          (d_dmem_rdata[`SCR1_DMEM_DWIDTH-1:0] ),
       // Inputs
       .clk                 (clk                                 ),
       .rst_n               (rst_n                               ),
       .imem_req            (d_imem_req),
       .imem_addr           (d_imem_addr[`SCR1_IMEM_AWIDTH-1:0]  ),
       .dmem_req            (d_dmem_req),
       .dmem_addr           (d_dmem_addr[`SCR1_DMEM_AWIDTH-1:0]  ),
       .dmem_wdata          (d_dmem_wdata[`SCR1_DMEM_DWIDTH-1:0] )
 );
























endmodule : scr1_tcm

`endif // SCR1_TCM_EN
