
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
// Filename    : DW_ahb_bcm53.v
// Revision    : $Id: //dwh/DW_ocb/DW_ahb/amba_dev/src/DW_ahb_bcm53.v#7 $
// Author      : James Feagans     May 20, 2004
// Description : DW_ahb_bcm53.v Verilog module for DWbb
//
// DesignWare IP ID: eb4374f0
//
////////////////////////////////////////////////////////////////////////////////



  module i_ahb_DW_ahb_bcm53 (
        clk,
        rst_n,
        init_n,
        enable,
        request,
        prior,
        lock,
        mask,
       
        parked,
        granted,
        locked,
        grant,
        grant_index
);

                          
  parameter N           = 4;  // RANGE 2 TO 32
  parameter P_WIDTH     = 2;  // RANGE 1 TO 5
  parameter PARK_MODE   = 1;  // RANGE 0 OR 1
  parameter PARK_INDEX  = 0;  // RANGE 0 TO 31
  parameter OUTPUT_MODE = 1;  // RANGE 0 OR 1
  parameter INDEX_WIDTH = 2;  // RANGE 1 to 5


  input                         clk;     // Clock input
  input                         rst_n;   // active low reset
  input                         init_n;  // active low reset
  input                         enable;  // active high register enable
  input  [N-1: 0]               request; // client request bus
  input  [P_WIDTH*N-1: 0]       prior;   // client priority bus
  input  [N-1: 0]               lock;    // client lock bus
  input  [N-1: 0]               mask;    // client mask bus
  
  output                        parked;  // arbiter parked status flag
  output                        granted; // arbiter granted status flag
  output                        locked;  // arbiter locked status flag
  output [N-1: 0]               grant;   // one-hot client grant bus
  output [INDEX_WIDTH-1: 0]     grant_index; //  index of current granted client


  localparam [INDEX_WIDTH-1:0]  INDEX_WIDTH_SIZED_ONE = 1;

  reg [1:0] current_state, next_state;
  wire [1:0] st_vec;

  wire   [N-1: 0] next_grant;
  reg    [INDEX_WIDTH-1: 0] next_grant_index;
  wire   next_parked, next_granted, next_locked;

  reg    [N-1: 0] grant_int;
  reg    granted_int;


  wire   [(P_WIDTH+INDEX_WIDTH+1)-1: 0] maxp1_priority;
  wire   [INDEX_WIDTH-1: 0] max_prior;
  wire   [N-1: 0] masked_req;
  wire   active_request;



  reg    [(N*INDEX_WIDTH)-1: 0] int_priority;

  reg    [(N*INDEX_WIDTH)-1: 0] decr_prior;

  reg    [(N*(P_WIDTH+INDEX_WIDTH+1))-1: 0] priority_vec;

  reg    [(N*(P_WIDTH+INDEX_WIDTH+1))-1: 0] muxed_pri_vec;

  reg    [(N*INDEX_WIDTH)-1: 0] next_prior;

  wire   [INDEX_WIDTH-1: 0] current_index;
  wire [P_WIDTH+INDEX_WIDTH:00] current_value;                 

  wire   [N-1: 0] temp_gnt;

  localparam [N-1 : 0] PARK_GNT = (PARK_MODE == 0)? 0 : (1 << PARK_INDEX);

  assign maxp1_priority = {P_WIDTH+INDEX_WIDTH+1{1'b1}};
  assign max_prior = {INDEX_WIDTH{1'b1}};

  assign masked_req = request & (~mask);

  assign active_request = |masked_req;

  assign next_locked = granted_int & (|(grant_int & lock));

  assign next_granted = next_locked | active_request;

  assign next_parked = ~next_granted;

  always @(prior or int_priority) begin : PRIORITY_VEC_PROC
    integer i1, j1;
    for (i1=0 ; i1<N ; i1=i1+1) begin
      for (j1=0 ; j1<(P_WIDTH+INDEX_WIDTH+1) ; j1=j1+1) begin
        if (j1 == (P_WIDTH+INDEX_WIDTH+1) - 1) begin
          priority_vec[i1*(P_WIDTH+INDEX_WIDTH+1)+j1] = 1'b0;
        end
        else if (j1 >= INDEX_WIDTH) begin
          priority_vec[i1*(P_WIDTH+INDEX_WIDTH+1)+j1] = prior[i1*P_WIDTH+(j1-(INDEX_WIDTH))];
        end
        else begin
          priority_vec[i1*(P_WIDTH+INDEX_WIDTH+1)+j1] = int_priority[i1*INDEX_WIDTH+j1];
        end
      end
    end
  end

  always @(priority_vec or masked_req or maxp1_priority) begin : MUXED_PRI_VEC_PROC
    integer k1, l1;
    for (k1=0 ; k1<N ; k1=k1+1) begin
      for (l1=0 ; l1<(P_WIDTH+INDEX_WIDTH+1) ; l1=l1+1) begin
        muxed_pri_vec[k1*(P_WIDTH+INDEX_WIDTH+1)+l1] = (masked_req[k1]) ?
          priority_vec[k1*(P_WIDTH+INDEX_WIDTH+1)+l1]: maxp1_priority[l1];
      end
    end
  end

  always @(int_priority) begin : mk_decr_prior_PROC
    reg    [INDEX_WIDTH-1: 0] temp_prior;
    reg    [INDEX_WIDTH  : 0] temp2_prior;
    integer i2, j2, k2;

    for (i2=0 ; i2<N ; i2=i2+1) begin

      for (j2=0 ; j2<INDEX_WIDTH ; j2=j2+1) begin
        temp_prior[j2] = int_priority[i2*INDEX_WIDTH+j2];
      end

      temp2_prior = temp_prior - INDEX_WIDTH_SIZED_ONE;

      for (k2=0 ; k2<INDEX_WIDTH ; k2=k2+1) begin
        decr_prior[i2*INDEX_WIDTH+k2] = temp2_prior[k2];
      end

    end
  end


  assign st_vec = {next_parked, next_locked};

  always @(current_state or st_vec)
  begin : gen_next_state_PROC
    case (current_state)
    2'b00: begin
      case (st_vec)
      2'b00: next_state = 2'b10;
      2'b10: next_state = 2'b01;
      default: next_state = 2'b00;
      endcase
    end
    2'b01: begin
      case (st_vec)
      2'b00: next_state = 2'b10;
      2'b01: next_state = 2'b11;
      default: next_state = 2'b01;
      endcase
    end
    2'b10: begin
      case (st_vec)
      2'b01: next_state = 2'b11;
      2'b10: next_state = 2'b01;
      default: next_state = 2'b10;
      endcase
    end
    default: begin
      case (st_vec)
      2'b00: next_state = 2'b10;
      2'b10: next_state = 2'b01;
      default: next_state = 2'b11;
      endcase
    end
    endcase
  end

  always @(current_state or masked_req or next_grant or int_priority or
                    next_locked or decr_prior or max_prior)
  begin : NEXT_PRIOR_PROC
    integer i3, l3;
    for (i3=0 ; i3<N ; i3=i3+1) begin
      for (l3=0 ; l3<INDEX_WIDTH ; l3=l3+1) begin
        case (current_state)
        2'b00: begin
          if (masked_req[i3]) begin
            if (next_grant[i3]) begin
              next_prior[i3*INDEX_WIDTH+l3] = max_prior[l3];
            end
            else begin
              next_prior[i3*INDEX_WIDTH+l3] = decr_prior[i3*INDEX_WIDTH+l3];
            end
          end
          else begin
            next_prior[i3*INDEX_WIDTH+l3] = max_prior[l3];
          end
        end
        2'b01: begin
          if (next_locked) begin
            if (masked_req[i3]) begin
              if (next_grant[i3]) begin
                next_prior[i3*INDEX_WIDTH+l3] = int_priority[i3*INDEX_WIDTH+l3];
              end
              else begin
                next_prior[i3*INDEX_WIDTH+l3] = decr_prior[i3*INDEX_WIDTH+l3];
              end
            end
            else begin
              next_prior[i3*INDEX_WIDTH+l3] = max_prior[l3];
            end
          end
          else begin
            if (masked_req[i3]) begin
              if (next_grant[i3]) begin
                next_prior[i3*INDEX_WIDTH+l3] = max_prior[l3];
              end
              else begin
                next_prior[i3*INDEX_WIDTH+l3] = decr_prior[i3*INDEX_WIDTH+l3];
              end
            end
            else begin
              next_prior[i3*INDEX_WIDTH+l3] = max_prior[l3];
            end
          end
        end
        default: begin
          if (next_locked) begin
            if (masked_req[i3] == 1'b0) begin
              next_prior[i3*INDEX_WIDTH+l3] = max_prior[l3];
            end
            else begin
              next_prior[i3*INDEX_WIDTH+l3] = int_priority[i3*INDEX_WIDTH+l3];
            end
          end
          else begin
            if (masked_req[i3] == 1'b0) begin
              next_prior[i3*INDEX_WIDTH+l3] = max_prior[l3];
            end
            else begin
              if (next_grant[i3]) begin
                next_prior[i3*INDEX_WIDTH+l3] = max_prior[l3];
              end
              else begin
                next_prior[i3*INDEX_WIDTH+l3] = decr_prior[i3*INDEX_WIDTH+l3];
              end
            end
          end
        end
        endcase
      end
    end
  end

  i_ahb_DW_ahb_bcm01
   #(P_WIDTH+INDEX_WIDTH+1, N, INDEX_WIDTH) U_minmax(
        .a(muxed_pri_vec),
        .tc(1'b0),
        .min_max(1'b0),
        .value(current_value),
        .index(current_index) );

  // Decodes the index determined by minmax into one-hot select line
  
  function [N-1:0] func_decode;
    input [INDEX_WIDTH-1:0]             f_a;    // input
    reg   [(1 << INDEX_WIDTH)-1:0]              f_z;
    begin
      f_z = {1 << INDEX_WIDTH{1'b0}};
      f_z[f_a] = 1'b1;
      func_decode = f_z[N-1:0];
    end
  endfunction

  assign temp_gnt = func_decode( current_index );


  // Select which grant to use: existing, parked, or new
  
  // Selects one of 4 equal sized subsections of an input vector to the specified output 
  function [N-1:0] func_mux;
    input [N*4-1:0]     f_a;    // input bus
    input [2-1:0]       f_sel;  // select
    reg   [N-1:0]       f_z;
    integer                     f_i, f_j, f_k;
    begin
      f_z = {N {1'b0}};
      f_j = 0;
      f_k = 0;   // Temporary fix for a Leda issue
      for (f_i=0 ; f_i<4 ; f_i=f_i+1) begin
        if ($unsigned(f_i) == f_sel) begin
          for (f_k=0 ; f_k<N ; f_k=f_k+1) begin
            f_z[f_k] = f_a[f_j + f_k];
          end // for (f_k
        end // if
        f_j = f_j + N;
      end // for (f_i
      func_mux = f_z;
    end
  endfunction

  assign next_grant = func_mux( ({grant_int,PARK_GNT,grant_int,temp_gnt}), ({next_parked,next_locked}) );



  // Encodes the selected grant into grant_index for output 
  always @ (next_grant) begin : mk_next_grant_index_PROC
    integer i;
    reg [INDEX_WIDTH-1:0] tmp_enc;

    next_grant_index = {INDEX_WIDTH{1'b1}};
    tmp_enc = {INDEX_WIDTH{1'b0}};

    for (i=0 ; i < N ; i=i+1) begin
      if (next_grant[i] == 1'b1) begin
        next_grant_index = next_grant_index & tmp_enc;
      end
      tmp_enc = tmp_enc + INDEX_WIDTH_SIZED_ONE;
    end
  end

  always @(posedge clk or negedge rst_n)
  begin : register_outputs_PROC
    if (rst_n == 1'b0) begin
      current_state       <= 2'b00;
      int_priority        <= {N*INDEX_WIDTH{1'b1}};
      granted_int         <= 1'b0;
      grant_int           <= {N{1'b0}};
    end else if (init_n == 1'b0) begin
      current_state       <= 2'b00;
      int_priority        <= {N*INDEX_WIDTH{1'b1}};
      granted_int         <= 1'b0;
      grant_int           <= {N{1'b0}};
    end else if (enable) begin
      current_state       <= next_state;
      int_priority        <= next_prior;
      granted_int         <= next_granted;
      grant_int           <= next_grant;
    end
  end

  generate if (OUTPUT_MODE == 0)
    begin : GEN_OM_EQ_0
      assign grant      = next_grant & {N{init_n}};
      assign grant_index = next_grant_index | {INDEX_WIDTH{~init_n}};
      assign granted    = next_granted & init_n;
      assign locked     = next_locked & init_n;
    end else begin : GEN_OM_NE_0
      reg    [INDEX_WIDTH-1: 0] grant_index_int;
      reg    locked_int;

      always @(posedge clk or negedge rst_n)
      begin : posedge_reg_PROC
        if (rst_n == 1'b0) begin
          grant_index_int     <= {INDEX_WIDTH{1'b1}};
          locked_int          <= 1'b0;
        end else if (init_n == 1'b0) begin
          grant_index_int     <= {INDEX_WIDTH{1'b1}};
          locked_int          <= 1'b0;
        end else if (enable) begin
          grant_index_int     <= next_grant_index;
          locked_int          <= next_locked;
        end
      end

      assign grant      = grant_int;
      assign grant_index        = grant_index_int;
      assign granted    = granted_int;
      assign locked     = locked_int;
    end
  endgenerate

  generate
    if (PARK_MODE == 0) begin : GEN_PM_EQ_0
      assign parked = 1'b0;
    end else if (OUTPUT_MODE == 0) begin : GEN_PM_NE_0_OM_EQ_0
      assign parked     = next_parked & init_n;
    end else begin : GEN_PM_NE_0_OM_NE_0
      reg    parked_int;

      always @(posedge clk or negedge rst_n)
      begin : gen_parked_int_PROC
        if (rst_n == 1'b0) begin
          parked_int          <= 1'b0;
        end else if (init_n == 1'b0) begin
          parked_int          <= 1'b0;
        end else if (enable) begin
          parked_int          <= next_parked;
        end
      end

      assign parked     = parked_int;
    end
  endgenerate

endmodule
