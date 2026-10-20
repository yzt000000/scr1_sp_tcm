
//  ------------------------------------------------------------------------
//
//                    (C) COPYRIGHT 2002 - 2016 SYNOPSYS, INC.
//                            ALL RIGHTS RESERVED
//
//  This software and the associated documentation are confidential and
//  proprietary to Synopsys, Inc.  Your use or disclosure of this
//  software is subject to the terms and conditions of a written
//  license agreement between you, or your company, and Synopsys, Inc.
//
// The entire notice above must be reproduced on all authorized copies.
//
//  ------------------------------------------------------------------------

//
// Filename    : DW_apb_uart_bcm23.v
// Revision    : $Id: //dwh/DW_ocb/DW_apb_uart/amba_dev/src/DW_apb_uart_bcm23.v#7 $
// Author      : Bruce Dean      June 24, 2004
// Description : DW_apb_uart_bcm23.v Verilog module for DWbb
//
// DesignWare IP ID: 6d82728d
//
////////////////////////////////////////////////////////////////////////////////
module i_uart_DW_apb_uart_bcm23 (
             clk_s, 
             rst_s_n, 
             init_s_n, 
             event_s, 
             ack_s,
             busy_s,

             clk_d, 
             rst_d_n, 
             init_d_n,
             event_d,

             test
             );

 parameter REG_EVENT    = 1;    // RANGE 0 to 1
 parameter REG_ACK      = 1;    // RANGE 0 to 1
 parameter ACK_DELAY    = 1;    // RANGE 0 to 1
 parameter F_SYNC_TYPE  = 2;    // RANGE 0 to 4
 parameter R_SYNC_TYPE  = 2;    // RANGE 0 to 4
 parameter TST_MODE     = 0;    // RANGE 0 to 2
 parameter VERIF_EN     = 1;    // RANGE 0 to 4
 parameter PULSE_MODE   = 0;    // RANGE 0 to 3
 parameter SVA_TYPE     = 0;

 
input  clk_s;                   // clock input for source domain
input  rst_s_n;                 // active low async. reset in clk_s domain
input  init_s_n;                // active low sync. reset in clk_s domain
input  event_s;                 // event pulseack input (active high event)
output ack_s;                   // event pulseack output (active high event)
output busy_s;                  // event pulseack output (active high event)

input  clk_d;                   // clock input for destination domain
input  rst_d_n;                 // active low async. reset in clk_d domain
input  init_d_n;                // active low sync. reset in clk_d domain
output event_d;                 // event pulseack output (active high event)

input  test;                    // test mode input.

wire   tgl_s_event_cc;
wire   tgl_d_event_cc;
reg    tgl_s_event_q;
wire   tgl_s_ack_x;
reg    event_s_cap;

wire   tgl_s_event_x;
wire   tgl_d_event_d;
wire   tgl_d_event_a;

wire   tgl_s_ack_d;
reg    srcdom_ack;
reg    tgl_s_ack_q;
wire   nxt_busy_state;
reg    busy_state;
wire   tgl_d_event_dx;    // event seen via edge detect (before registered)
reg    tgl_d_event_q;     // registered version of event seen
reg    tgl_d_event_qx;    // xor of dest dom data and registered version

`ifndef SYNTHESIS
`ifndef DWC_DISABLE_CDC_METHOD_REPORTING
  initial begin
    if ((F_SYNC_TYPE > 0)&&(F_SYNC_TYPE < 8))
       $display("Information: *** Instance %m module is using the <Toggle Type Event Sychronizer with busy and acknowledge (3)> Clock Domain Crossing Method ***");
  end

`endif
`endif

  
  always @ (posedge clk_s or negedge rst_s_n) begin : event_lauch_reg_PROC
    if (rst_s_n == 1'b0) begin
      tgl_s_event_q    <= 1'b0;
      busy_state       <= 1'b0;
      srcdom_ack       <= 1'b0;
      tgl_s_ack_q      <= 1'b0;
      event_s_cap      <= 1'b0;
    end else if (init_s_n == 1'b0) begin
      tgl_s_event_q    <= 1'b0;
      busy_state       <= 1'b0;
      srcdom_ack       <= 1'b0;
      tgl_s_ack_q      <= 1'b0;
      event_s_cap      <= 1'b0;
    end else begin
      tgl_s_event_q    <= tgl_s_event_x;
      busy_state       <= nxt_busy_state;
      srcdom_ack       <= tgl_s_ack_x;
      tgl_s_ack_q      <= tgl_s_ack_d;
      event_s_cap      <= event_s;
    end 
  end // always : event_lauch_reg_PROC



  
generate
  if (((F_SYNC_TYPE&7)>1)&&(TST_MODE==2)) begin : GEN_LATCH_frwd_hold
    reg [1-1:0] tgl_s_event_l;
    always @ (clk_s or tgl_s_event_q) begin : LATCH_frwd_hold_PROC
      if (clk_s == 1'b0)
// spyglass disable_block InferLatch
// SMD: Latch inferred
// SJ: SpyGlass uses this rule to detect inferred latches in the design. If the module is intentionally implemented with latches and the latch was intended, then the error could be suppressed.
        tgl_s_event_l = tgl_s_event_q;
// spyglass enable_block InferLatch
    end // LATCH_frwd_hold_PROC

    assign tgl_s_event_cc = (test==1'b1)? tgl_s_event_l : tgl_s_event_q;
  end else begin : GEN_DIRECT_frwd_hold
    assign tgl_s_event_cc = tgl_s_event_q;
  end
endgenerate

  i_uart_DW_apb_uart_bcm21
   #(1, F_SYNC_TYPE+8, TST_MODE, VERIF_EN, 1) U_DW_SYNC_F(
        .clk_d(clk_d),
        .rst_d_n(rst_d_n),
        .init_d_n(init_d_n),
        .data_s(tgl_s_event_cc),
        .test(test),
        .data_d(tgl_d_event_d) );


  
generate
  if (((F_SYNC_TYPE&7)>1)&&(TST_MODE==2)) begin : GEN_LATCH_rvs_hold
    reg [1-1:0] tgl_d_event_l;
    always @ (clk_d or tgl_d_event_a) begin : LATCH_rvs_hold_PROC
      if (clk_d == 1'b0)
// spyglass disable_block InferLatch
// SMD: Latch inferred
// SJ: SpyGlass uses this rule to detect inferred latches in the design. If the module is intentionally implemented with latches and the latch was intended, then the error could be suppressed.
        tgl_d_event_l = tgl_d_event_a;
// spyglass enable_block InferLatch
    end // LATCH_rvs_hold_PROC

    assign tgl_d_event_cc = (test==1'b1)? tgl_d_event_l : tgl_d_event_a;
  end else begin : GEN_DIRECT_rvs_hold
    assign tgl_d_event_cc = tgl_d_event_a;
  end
endgenerate

  i_uart_DW_apb_uart_bcm21
   #(1, R_SYNC_TYPE+8, TST_MODE, VERIF_EN, 1) U_DW_SYNC_R(
        .clk_d(clk_s),
        .rst_d_n(rst_s_n),
        .init_d_n(init_s_n),
        .data_s(tgl_d_event_cc),
        .test(test),
        .data_d(tgl_s_ack_d) );

  always @ (posedge clk_d or negedge rst_d_n) begin : second_sync_PROC
    if (rst_d_n == 1'b0) begin
      tgl_d_event_q      <= 1'b0;
      tgl_d_event_qx     <= 1'b0;
    end else if (init_d_n == 1'b0) begin
      tgl_d_event_q      <= 1'b0;
      tgl_d_event_qx     <= 1'b0;
    end else begin
      tgl_d_event_q      <= tgl_d_event_d;
      tgl_d_event_qx     <= tgl_d_event_dx;
    end
  end // always

generate
    
    if (PULSE_MODE <= 0) begin : GEN_PLSMD0
      assign tgl_s_event_x = tgl_s_event_q   ^ (event_s && (! busy_state));
    end
    
    if (PULSE_MODE == 1) begin : GEN_PLSMD1
      assign tgl_s_event_x = tgl_s_event_q   ^ (! busy_state &(event_s & (! event_s_cap)));
    end
    
    if (PULSE_MODE == 2) begin : GEN_PLSMD2
      assign tgl_s_event_x = tgl_s_event_q  ^ (! busy_state &(event_s_cap & (!event_s)));
    end
    
    if (PULSE_MODE >= 3) begin : GEN_PLSMD3
      assign tgl_s_event_x = tgl_s_event_q ^ (! busy_state & (event_s ^ event_s_cap));
    end

endgenerate
  assign tgl_d_event_dx = tgl_d_event_d ^ tgl_d_event_q;
  //assign tgl_s_event_x  = tgl_s_event_q ^ (event_s & ! busy_s);
  assign tgl_s_ack_x    = tgl_s_ack_d   ^ tgl_s_ack_q;
  assign nxt_busy_state = tgl_s_event_x ^ tgl_s_ack_d;

  generate
    if (REG_EVENT == 0) begin : GEN_RGEVT0
      assign event_d       = tgl_d_event_dx;
    end

    else begin : GEN_RGRVT1
      assign event_d       = tgl_d_event_qx;
    end
  endgenerate

  generate
    if (REG_ACK == 0) begin : GEN_RGACK0
      assign ack_s         = tgl_s_ack_x;
    end

    else begin : GEN_RGACK1
      assign ack_s         = srcdom_ack;
    end
  endgenerate

  generate
    if (ACK_DELAY == 0) begin : GEN_AKDLY0
      assign tgl_d_event_a = tgl_d_event_d;
    end

    else begin : GEN_AKDLY1
      assign tgl_d_event_a = tgl_d_event_q;
    end
  endgenerate


  assign busy_s = busy_state;

`ifdef DWC_BCM_SNPS_ASSERT_ON
`ifndef SYNTHESIS 

  DW_apb_uart_sva03 #(F_SYNC_TYPE&7,  PULSE_MODE) P_PULSEACK_SYNC_HS (.*);

  generate if (SVA_TYPE == 1) begin : GEN_SVATP_EQ_1
    DW_apb_uart_sva02 #(
      .F_SYNC_TYPE    (F_SYNC_TYPE&7),
      .PULSE_MODE     (PULSE_MODE   )
    ) P_PULSE_SYNC_HS (
        .clk_s        (clk_s        )
      , .rst_s_n      (rst_s_n      )
      `ifndef DWC_NO_CDC_INIT
      , .init_s_n     (init_s_n     )
      `endif
      , .event_s      (event_s      )
      , .event_d      (event_d      )
      `ifndef DWC_NO_TST_MODE
      , .test         (test         )
      `endif
    );
  end endgenerate

  generate if ((F_SYNC_TYPE==0) || (R_SYNC_TYPE==0)) begin : GEN_SINGLE_CLOCK_CANDIDATE
    DW_apb_uart_sva07 #(F_SYNC_TYPE, R_SYNC_TYPE) P_CDC_CLKCOH (.*);
  end endgenerate

`endif // SYNTHESIS
`endif // DWC_BCM_SNPS_ASSERT_ON

endmodule
