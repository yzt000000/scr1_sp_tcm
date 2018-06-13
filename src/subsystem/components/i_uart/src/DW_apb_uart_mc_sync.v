// ---------------------------------------------------------------------
//
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
// Release version :  4.01a
// File Version     :        $Revision: #10 $ 
// Revision: $Id: //dwh/DW_ocb/DW_apb_uart/amba_dev/src/DW_apb_uart_mc_sync.v#10 $ 
//
// File :                       DW_apb_uart_mc_sync.v
// Author:                      Marc Wall
//
//
// Date :                       $Date: 2016/08/26 $
// Abstract     :               Modem control synchronization module for
//                              the DW_apb_uart macro-cell
//
//
// ---------------------------------------------------------------------
// ---------------------------------------------------------------------

module i_uart_DW_apb_uart_mc_sync
  (
   // Inputs
   clk,
   resetn,
   cts_n,
   dsr_n,
   dcd_n,
   ri_n,
   
   // Outputs
   sync_cts_n,
   sync_dsr_n,
   sync_dcd_n,
   sync_ri_n
   );

   input                             clk;                 // clock 
   input                             resetn;              // async reset
   input                             cts_n;               // clear to send,
                                                          // active low
   input                             dsr_n;               // data set ready,
                                                          // active low
   input                             dcd_n;               // data carrier detect,
                                                          // active low
   input                             ri_n;                // ring indicator,
                                                          // active low

   output                            sync_cts_n;          // synd'ed clear to send,         
                                                          // active low
   output                            sync_dsr_n;          // synd'ed data set ready,        
                                                          // active low
   output                            sync_dcd_n;          // synd'ed data carrier detect,
                                                          // active low
   output                            sync_ri_n;           // synd'ed ring indicator,        
                                                          // active low

   wire                              cts_n;               // clear to send,
                                                          // active low
   wire                              sync_cts_n;          // synd'ed clear to
                                                          // send, active low
   wire                              dsr_n;               // data set ready,
                                                          // active low
   wire                              sync_dsr_n;          // synd'ed data set
                                                          // ready, active low
   wire                              dcd_n;               // data carrier detect,
                                                          // active low
   wire                              sync_dcd_n;          // synd'ed data carrier
                                                          // detect, active low
   wire                              ri_n;                // ring indicator,
                                                          // active low
   wire                              sync_ri_n;           // synd'ed ring indicator,
                                                          // active low
   wire                              async2ckl_cts_n;
   wire                              sasync2ckl_sync_cts_n;

   // Level synchronizer for cts_n
   i_uart_DW_apb_uart_bcm21
    #(
             .WIDTH        (1),
             .F_SYNC_TYPE  (2)
     ) U_DW_apb_uart_bcm21_async2ckl_cts_n_cksyzr
     (
      .clk_d    (clk),
      .rst_d_n  (resetn),
      .init_d_n (1'b1),
      .data_s   (async2ckl_cts_n),
      .test     (1'b0),
      .data_d   (sasync2ckl_sync_cts_n)
     );

   assign async2ckl_cts_n = cts_n;
   assign sync_cts_n = sasync2ckl_sync_cts_n;

   wire                              async2ckl_dsr_n;
   wire                              sasync2ckl_sync_dsr_n;

   // Level synchronizer for dsr_n
   i_uart_DW_apb_uart_bcm21
    #(
             .WIDTH        (1),
             .F_SYNC_TYPE  (2)
     ) U_DW_apb_uart_bcm21_async2ckl_dsr_n_cksyzr
     (
      .clk_d    (clk),
      .rst_d_n  (resetn),
      .init_d_n (1'b1),
      .data_s   (async2ckl_dsr_n),
      .test     (1'b0),
      .data_d   (sasync2ckl_sync_dsr_n)
     );

   assign async2ckl_dsr_n = dsr_n;
   assign sync_dsr_n = sasync2ckl_sync_dsr_n;

   wire                              async2ckl_dcd_n;
   wire                              sasync2ckl_sync_dcd_n;

   // Level synchronizer for dcd_n
   i_uart_DW_apb_uart_bcm21
    #(
             .WIDTH        (1),
             .F_SYNC_TYPE  (2)
     ) U_DW_apb_uart_bcm21_async2ckl_dcd_n_cksyzr
     (
      .clk_d    (clk),
      .rst_d_n  (resetn),
      .init_d_n (1'b1),
      .data_s   (async2ckl_dcd_n),
      .test     (1'b0),
      .data_d   (sasync2ckl_sync_dcd_n)
     );

   assign async2ckl_dcd_n = dcd_n;
   assign sync_dcd_n = sasync2ckl_sync_dcd_n;

   wire                              async2ckl_ri_n;
   wire                              sasync2ckl_sync_ri_n;

   // Level synchronizer for ri_n
   i_uart_DW_apb_uart_bcm21
    #(
             .WIDTH        (1),
             .F_SYNC_TYPE  (2)
     ) U_DW_apb_uart_bcm21_async2ckl_ri_n_cksyzr
     (
      .clk_d    (clk),
      .rst_d_n  (resetn),
      .init_d_n (1'b1),
      .data_s   (async2ckl_ri_n),
      .test     (1'b0),
      .data_d   (sasync2ckl_sync_ri_n)
     );

  assign async2ckl_ri_n = ri_n; 
  assign sync_ri_n = sasync2ckl_sync_ri_n; 

endmodule // DW_apb_uart_mc_sync
