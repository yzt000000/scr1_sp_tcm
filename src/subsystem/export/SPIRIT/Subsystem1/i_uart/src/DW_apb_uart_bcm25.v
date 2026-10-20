
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
// Filename    : DW_apb_uart_bcm25.v
// Revision    : $Id: //dwh/DW_ocb/DW_apb_uart/amba_dev/src/DW_apb_uart_bcm25.v#8 $
// Author      : Bruce Dean 12.4.2005
// Description : DW_apb_uart_bcm25.v Verilog module for DWbb
//
// DesignWare IP ID: 5393fe38
//
////////////////////////////////////////////////////////////////////////////////
module i_uart_DW_apb_uart_bcm25 (
             clk_s,
             rst_s_n,
             init_s_n,
             send_s,
             data_s,
             empty_s,
             full_s,
             done_s,

             clk_d,
             rst_d_n,
             init_d_n,
             data_avail_d,
             data_d,

             test
           );

 parameter WIDTH       = 8;  // RANGE 1 to 1024
 parameter PEND_MODE   = 1;  // RANGE 0 to 1
 parameter ACK_DELAY   = 1;  // RANGE 0 to 1
 parameter F_SYNC_TYPE = 2;  // RANGE 0 to 4
 parameter R_SYNC_TYPE = 2;  // RANGE 0 to 4
 parameter TST_MODE    = 0;  // RANGE 0 to 2
 parameter VERIF_EN    = 1;  // RANGE 0 to 4
 parameter SEND_MODE   = 0;  // RANGE 0 to 1
 parameter SVA_TYPE     = 0;

 input             clk_s;    //Source clock 
 input             rst_s_n;  //Source domain asynch.reset (active low)
 input             init_s_n; //Source domain synch. reset (active low)
 input             send_s;   //Source domain send request input 
 input [WIDTH-1:0] data_s;   //Source domain send data input 
 output             empty_s;  //Source domain transaction regs empty 
 output             full_s;   //Source domain transaction regs full 
 output             done_s;   //Source domain transaction done output 

 input             clk_d;    //Destination clock 
 input             rst_d_n;  //Destination domain asynch. reset (active low)
 input             init_d_n; //Destination domain synch. reset (active low)
 output             data_avail_d; //Destination domain data update output 
 output [WIDTH-1:0] data_d;   // WIDTH Destination domain data output 

 input             test;     //Scan test mode select input 
  reg  [WIDTH-1:0] data_s_reg;
  reg  [WIDTH-1:0] data_d_reg;
  wire [WIDTH-1:0] data_s_mux;
 
  reg  send_reg;

  reg  busy_pnr;
  wire busy_s_pnd;

  wire busy_s_pas;
  reg  busy_int;
  wire ack_s_pas;
  wire event_d_pas;
  wire data_s_ren;
  wire data_s_pen;

  wire send_in;
  wire send_en;
  reg  dr_bsy;
  wire dr_bsy_nxt;


  wire done_s_nxt;
  wire busy_s_nxt;

  reg  data_avail_reg;
  wire data_d_nxt;


`ifndef SYNTHESIS
`ifndef DWC_DISABLE_CDC_METHOD_REPORTING
  initial begin
    if ((F_SYNC_TYPE > 0)&&(F_SYNC_TYPE < 8))
       $display("Information: *** Instance %m module is using the <Data Bus Synchronizer With Acknowledge (5)> Clock Domain Crossing Method ***");
  end

`endif
`endif
 
  i_uart_DW_apb_uart_bcm23
   #(0, 0, ACK_DELAY, (F_SYNC_TYPE + 8), (R_SYNC_TYPE + 8), TST_MODE, VERIF_EN, 0, SVA_TYPE)
    U1 ( 
        .clk_s(clk_s), 
        .rst_s_n(rst_s_n), 
        .init_s_n(init_s_n), 
        .event_s(send_en), 
        .clk_d(clk_d), 
        .rst_d_n(rst_d_n), 
        .init_d_n(init_d_n), 
        .test(test), 
        .busy_s(busy_s_pas), 
        .ack_s(ack_s_pas), 
        .event_d(event_d_pas) 
        );

  
  always @ (posedge clk_s or negedge rst_s_n) begin : src_pos_reg_PROC
    if  (rst_s_n == 1'b0)  begin
      data_s_reg <= {WIDTH{1'b0}};
      send_reg   <= 1'b0;
      busy_int   <= 1'b0;
      busy_pnr   <= 1'b0;
      dr_bsy     <= 1'b0;
    end else begin
      if ( init_s_n == 1'b0)  begin
        data_s_reg <= {WIDTH{ 1'b0}};
        send_reg   <= 1'b0;
        busy_int   <= 1'b0;
        busy_pnr   <= 1'b0;
        dr_bsy     <= 1'b0;
      end else begin
        if(data_s_ren == 1'b1) 
          data_s_reg <= data_s_mux;
        send_reg   <= send_s;
        busy_int   <= busy_s_nxt;
        busy_pnr   <= busy_s_pnd;
        dr_bsy     <= dr_bsy_nxt;
      end 
    end 
  end 

  always @ (posedge clk_d or negedge rst_d_n) begin : dest_pos_reg_PROC
    if (rst_d_n == 1'b0 ) begin
       data_d_reg     <= {WIDTH{1'b0}};
       data_avail_reg <= 1'b0;
    end else  begin
      if (init_d_n == 1'b0 ) begin
        data_d_reg     <= {WIDTH{1'b0}};
        data_avail_reg <= 1'b0;
      end else begin
        if(data_d_nxt == 1'b1) 
          data_d_reg   <= data_s_reg;
        data_avail_reg <= data_d_nxt;
      end
    end 
  end


  assign data_s_pen   = busy_s_nxt & send_in;

generate
  if (PEND_MODE == 1) begin : GEN_PM1
    reg  [WIDTH-1:0] data_s_pnd;
    reg  pr_bsy;
    wire pr_bsy_nxt;

    always @ (posedge clk_s or negedge rst_s_n) begin : src_pos_reg_PROC
      if  (rst_s_n == 1'b0)  begin
        data_s_pnd <= {WIDTH{1'b0}};
        pr_bsy     <= 1'b0;
      end else begin
        if ( init_s_n == 1'b0)  begin
          data_s_pnd <= {WIDTH{ 1'b0}};
          pr_bsy     <= 1'b0;
        end else begin
          if(data_s_pen == 1'b1) 
            data_s_pnd <= data_s;
          pr_bsy     <= pr_bsy_nxt;
        end 
      end 
    end

    assign pr_bsy_nxt   = (send_in & (~ pr_bsy) & dr_bsy) 
                        | (pr_bsy & (~ ack_s_pas) & dr_bsy)
                        | (send_in & ack_s_pas & dr_bsy);

    assign busy_s_pnd   = (dr_bsy & pr_bsy_nxt) & (~ack_s_pas);
    assign busy_s_nxt   = (send_in | send_en) | (~ack_s_pas & busy_int) | (ack_s_pas & pr_bsy);
    assign data_s_ren   = (send_in & (~ dr_bsy) & (~busy_int)) | (ack_s_pas & pr_bsy) | (~ dr_bsy & pr_bsy & (~ ack_s_pas));
    assign send_en      = (send_in & (~ dr_bsy)) | (dr_bsy & (~ busy_s_pas));
    assign data_s_mux   = (pr_bsy == 1'b1) ? data_s_pnd : data_s;
    assign dr_bsy_nxt   = (send_en & (~ busy_s_pas)) | (dr_bsy & (~ ack_s_pas)) | (ack_s_pas & pr_bsy) | (pr_bsy & (~ dr_bsy));
  end else begin : GEN_PM0
    assign busy_s_pnd   = send_in | dr_bsy_nxt;
    assign busy_s_nxt   = send_in | dr_bsy_nxt;
    assign data_s_ren   = send_in & (~ busy_s_pas);
    assign send_en      = send_in;
    assign data_s_mux   = data_s;
    assign dr_bsy_nxt   = (send_en & (~ busy_s_pas)) | (dr_bsy & (~ ack_s_pas));
  end
endgenerate

generate
  if (SEND_MODE == 0) begin : GEN_SEND_IN_SM0
    assign send_in = send_s;
  end
  if (SEND_MODE == 1) begin : GEN_SEND_IN_SM1
    assign send_in = send_s && !send_reg;
  end
  if (SEND_MODE == 2) begin : GEN_SEND_IN_SM2
    assign send_in = !send_s && send_reg;
  end
  if (SEND_MODE > 2) begin : GEN_SEND_IN_SM_GT_2
    assign send_in = send_s ^ send_reg;
  end
endgenerate

  assign done_s_nxt = ack_s_pas;
  assign data_d_nxt = event_d_pas;

  assign data_avail_d = data_avail_reg;
  assign data_d       = data_d_reg;
  assign done_s       = done_s_nxt;
  assign empty_s      = busy_int;
  assign full_s       = busy_pnr;
  

`ifdef DWC_BCM_SNPS_ASSERT_ON
`ifndef SYNTHESIS 

  DW_apb_uart_sva04 #(SEND_MODE) P_DATA_SYNC_HS (.*);

  generate if ((F_SYNC_TYPE==0) || (R_SYNC_TYPE==0)) begin : GEN_SINGLE_CLOCK_CANDIDATE
    DW_apb_uart_sva07 #(F_SYNC_TYPE, R_SYNC_TYPE) P_CDC_CLKCOH (.*);
  end endgenerate

`endif // SYNTHESIS
`endif // DWC_BCM_SNPS_ASSERT_ON
 
endmodule
