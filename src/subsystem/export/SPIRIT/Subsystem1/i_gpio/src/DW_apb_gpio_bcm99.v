
//  ------------------------------------------------------------------------
//
//                    (C) COPYRIGHT 2013 - 2016 SYNOPSYS, INC.
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
// Filename    : DW_apb_gpio_bcm99.v
// Revision    : $Id: //dwh/DW_ocb/DW_apb_gpio/amba_dev/src/DW_apb_gpio_bcm99.v#2 $
// Author      : Liming SU    06/19/15
// Description : DW_apb_gpio_bcm99.v Verilog module for DWbb
//
// DesignWare IP ID: e0f12a12
//
////////////////////////////////////////////////////////////////////////////////

module i_gpio_DW_apb_gpio_bcm99 (
  clk_d,
  rst_d_n,
  data_s,
  data_d
);

parameter ACCURATE_MISSAMPLING = 0; // RANGE 0 to 1

input  clk_d;      // clock input from destination domain
input  rst_d_n;    // active low asynchronous reset from destination domain
input  data_s;     // data to be synchronized from source domain
output data_d;     // data synchronized to destination domain

localparam WIDTH = 1;


  `ifdef DW_MODEL_MISSAMPLES


// { START Latency Accurate modeling
  initial begin : set_setup_hold_delay_PROC

  end // set_setup_hold_delay_PROC


  reg [WIDTH-1:0] setup_mux_ctrl, hold_mux_ctrl;
  initial setup_mux_ctrl = {WIDTH{1'b0}};
  initial hold_mux_ctrl  = {WIDTH{1'b0}};
  
  wire [WIDTH-1:0] data_s_q;
  reg clk_d_q;
  initial clk_d_q = 1'b0;
  reg [WIDTH-1:0] setup_mux_out, d_muxout;
  reg [WIDTH-1:0] d_ff1, d_ff2;
  integer i,j,k;
  
  
  //Delay the destination clock
  always @ (posedge clk_d)
  #`DW_HOLD_MUX_DELAY clk_d_q = 1'b1;

  always @ (negedge clk_d)
  #`DW_HOLD_MUX_DELAY clk_d_q = 1'b0;
  
  //Delay the source data
  assign #`DW_SETUP_MUX_DELAY data_s_q = (!rst_d_n) ? {WIDTH{1'b0}}:data_s;

  //setup_mux_ctrl controls the data entering the flip flop 
  always @ (data_s or data_s_q or setup_mux_ctrl) begin
    for (i=0;i<=WIDTH-1;i=i+1) begin
      if (setup_mux_ctrl[i])
        setup_mux_out[i] = data_s_q[i];
      else
        setup_mux_out[i] = data_s;
    end
  end

  always @ (posedge clk_d_q or negedge rst_d_n) begin
    if (rst_d_n == 1'b0)
      d_ff2 <= {WIDTH{1'b0}};
    else
      d_ff2 <= setup_mux_out;
  end

  always @ (posedge clk_d or negedge rst_d_n) begin
    if (rst_d_n == 1'b0) begin
      d_ff1          <= {WIDTH{1'b0}};
      setup_mux_ctrl <= {WIDTH{1'b0}};
      hold_mux_ctrl  <= {WIDTH{1'b0}};
    end
    else begin
      d_ff1          <= setup_mux_out;
      setup_mux_ctrl <= $random;  //randomize mux_ctrl
      hold_mux_ctrl  <= $random;  //randomize mux_ctrl
    end
  end


//hold_mux_ctrl decides the clock triggering the flip-flop
always @(hold_mux_ctrl or d_ff2 or d_ff1) begin
      for (k=0;k<=WIDTH-1;k=k+1) begin
        if (hold_mux_ctrl[k])
          d_muxout[k] = d_ff2[k];
        else
          d_muxout[k] = d_ff1[k];
      end
end
// END Latency Accurate modeling }


 //Assertions


  `endif

`ifdef DW_MODEL_MISSAMPLES
generate if (ACCURATE_MISSAMPLING == 1) begin : GEN_DATA_PRE_AM_EQ_1
// Replace code between "SINGLE FF SYNCRONIZER BEGIN" and "SINGLE FF SYNCRONIZER END"
// with an instance of your customized register cell
// SINGLE FF SYNCRONIZER BEGIN
  reg data_d_pre;
  always @(posedge clk_d or negedge rst_d_n) begin : a1000_PROC
    if (!rst_d_n)
      data_d_pre <= 1'b0;
    else
      data_d_pre <= d_muxout;
  end
  assign data_d = data_d_pre;
// SINGLE FF SYNCRONIZER END
end else begin : GEN_DATA_PRE_AM_EQ_0
// Replace code between "DOUBLE FF SYNCRONIZER BEGIN" and "DOUBLE FF SYNCRONIZER END"
// with your customized register cell(s)
// Option 1: 1 instantiation of a 2 FF cell
// Option 2: 2 instantiations of single FF cells connected serially
// DOUBLE FF SYNCRONIZER BEGIN
  reg data_meta;
  reg data_d_pre;
  always @(posedge clk_d or negedge rst_d_n) begin : a1001_PROC
    if (!rst_d_n) begin
      data_meta  <= 1'b0;
      data_d_pre <= 1'b0;
    end else begin
      data_meta  <= data_s;
      data_d_pre <= data_meta;
    end
  end
  assign data_d = data_d_pre;
// DOUBLE FF SYNCRONIZER END
end endgenerate
`else
// Replace code between "DOUBLE FF SYNCRONIZER BEGIN" and "DOUBLE FF SYNCRONIZER END"
// with your customized register cell(s)
// Option 1: 1 instantiation of a 2 FF cell
// Option 2: 2 instantiations of single FF cells connected serially
// DOUBLE FF SYNCRONIZER BEGIN
  reg data_meta;
  reg data_d_pre;
  always @(posedge clk_d or negedge rst_d_n) begin : a1002_PROC
    if (!rst_d_n) begin
      data_meta  <= 1'b0;
      data_d_pre <= 1'b0;
    end else begin
      data_meta  <= data_s;
      data_d_pre <= data_meta;
    end
  end
  assign data_d = data_d_pre;
// DOUBLE FF SYNCRONIZER END
`endif

endmodule
