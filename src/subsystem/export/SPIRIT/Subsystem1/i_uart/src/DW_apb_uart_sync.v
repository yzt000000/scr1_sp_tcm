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
// File Version     :        $Revision: #18 $ 
// Revision: $Id: //dwh/DW_ocb/DW_apb_uart/amba_dev/src/DW_apb_uart_sync.v#18 $ 
//
// File :                       DW_apb_uart_sync.v
//
//
// Author:                      Marc Wall
// Date :                       $Date: 2016/08/26 $
// Abstract     :               Top level synchronization module for the
//                              DW_apb_uart macro-cell.
//
//
// ---------------------------------------------------------------------
// ---------------------------------------------------------------------

module i_uart_DW_apb_uart_sync
  (
   // Inputs
   pclk,
   presetn,
   sclk,
   s_rst_n,
   divsr_wd,
   xbreak,
   lb_en,
   tx_start,
   tx_finish,
   rx_in_prog,
   rx_finish,
   char_to,
   // 20100816 jduarte end
   cnt_ens_ed,
   char_info_wd,
   divsr,
   char_info,
   tx_data,
   rx_data,
   to_det_cnt_ens,
   // Outputs
   sync_divsr_wd,
   sync_break,
   sync_lb_en,
   sync_tx_start,
   sync_tx_finish,
   sync_rx_in_prog,
   sync_rx_finish,
   sync_char_to,
   sync_divsr,
   sync_char_info,
   sync_tx_data,
   sync_to_det_cnt_ens,
   sync_rx_data
   );

   // pclk domain input signals
   input                              pclk;                   // APB clock
   input                              presetn;                // APB async reset
   input                              divsr_wd;               // baud clock divisor
                                                              // write detect
                                                              // divisor write detect
   input                              xbreak;                 // break control
   input                              lb_en;                  // loopback enable
   input                              tx_start;               // start serial
                                                              // transmission
   // jduarte 20110316 begin
   // each signal sent to the timeout detector will now be individually
   // synchronized to avoid any signal change being masked by the synchronizers
   // input                              cnt_ens_ed;             // count enables
   //                                                            // edge detect
   input  [`TO_DET_CNT_ENS_WIDTH-1:0] cnt_ens_ed;             // count enables
                                                              // edge detect
   // jduarte 20110316 end
   input                              char_info_wd;           // char_info
                                                              // write detect

   // sclk domain input signals
   input                              sclk;                   // serial I/F clock
   input                              s_rst_n;                // serial I/F active
                                                              // low async reset
   input                              tx_finish;              // serial transmission
                                                              // of current character
                                                              // finished
   input                              rx_in_prog;             // serial reception
                                                              // in progress
   input                              rx_finish;              // serial reception of
                                                              // current character
                                                              // finished
   input                              char_to;                // character timeout
   // 20100816 jduarte begin
   // Additional pins for STAR 9000405367 fix
   // 20100816 jduarte ebd

                                                              // power request from
                                                              // the sclk domain

   // scan input signal

   // pclk domain input busses
   input  [15:0]                      divsr;                  // baud clock divisor

   input  [5:0]                       char_info;              // serial character
                                                              // information
   input  [`TXFIFO_RW-1:0]            tx_data;                // data to be
                                                              // transmitted
   input  [`TO_DET_CNT_ENS_WIDTH-1:0] to_det_cnt_ens;         // timeout detect
                                                              // count enables

   //RS485 registers

   // sclk domain input busses
   input  [`RXFIFO_RW-1:0]            rx_data;                // received data

   // sclk domain synd'ed output signals
   output                             sync_divsr_wd;          // synd'ed baud clock
                                                              // divisor write detect
                                                              // divisor write detect
   output                             sync_break;             // synd'ed break control
   output                             sync_lb_en;             // synd'ed loopback enable
   output                             sync_tx_start;          // synd'ed start serial
                                                              // transmission

   // pclk domain synd'ed output signals
   output                             sync_tx_finish;         // synd'ed serial transmission
                                                              // of current character
                                                              // finished
   output                             sync_rx_in_prog;        // synd'ed serial reception
                                                              // in progress
   output                             sync_rx_finish;         // synd'ed serial reception of
                                                              // current character
                                                              // finished
   output                             sync_char_to;           // synd'ed character timeout
   // 20100816 jduarte begin
   // Additional pin for STAR 9000405367 fix
   // 20100816 jduarte end

   // sclk domain synd'ed output busses
   output [15:0]                      sync_divsr;             // synd'ed baud clock divisor
                                                              // clock divisor
   output [5:0]                       sync_char_info;         // synd'ed serial character

                                                              // information
   output [`TXFIFO_RW-1:0]            sync_tx_data;           // synd'ed data to be
                                                              // transmitted
   output [`TO_DET_CNT_ENS_WIDTH-1:0] sync_to_det_cnt_ens;    // synd'ed timeout detect
                                                              // count enables



   // pclk domain synd'ed output busses
   output [`RXFIFO_RW-1:0]            sync_rx_data;           // synd'ed received data

   wire                               tx_start;               // start serial
                                                              // transmission
   wire                               sync_tx_start;          // synd'ed start serial
                                                              // transmission
   wire                               rx_finish;              // serial reception of
                                                              // current character
                                                              // finished
   wire                               sync_rx_finish;         // synd'ed serial reception of
                                                              // current character
                                                              // finished
   wire                               divsr_wd;               // baud clock divisor
                                                              // write detect
   wire                               sync_divsr_wd;          // synd'ed baud clock
   wire                               char_info_wd;           // char_info
                                                              // write detect
   wire                               xbreak;                  // break control
   wire                               sync_break;             // synd'ed break
                                                              // control
   wire                               lb_en;                  // loopback enable
   wire                               sync_lb_en;             // synd'ed loopback
                                                              // enable
   // jduarte 20110316 begin
   // each signal sent to the timeout detector will now be individually
   // synchronized to avoid any signal change being masked by the synchronizers
   // wire                               cnt_ens_ed;             // count enables
   //                                                            // edge detect
   //                                                            // count enable
   wire   [`TO_DET_CNT_ENS_WIDTH-1:0] cnt_ens_ed;             // count enables
                                                              // edge detect
                                                              // count enable
   // jduarte 20110316 end
   wire                               sync_char_to;           // synd'ed character
                                                              // timeout
   wire                               char_to;                // character timeout
   // 20100816 jduarte begin
   // Additional signal for STAR 9000405367 fix
   // 20100816 jduarte end

   wire                               tx_finish;              // serial transmission
                                                              // of current character
                                                              // finished
   wire                               sync_tx_finish;         // synd'ed serial
                                                              // transmission of
                                                              // current character
                                                              // finished
   wire                               rx_in_prog;             // serial reception
                                                              // in progress
   wire                               sync_rx_in_prog;        // synd'ed serial
                                                              // reception in
                                                              // progress
   wire   [`TXFIFO_RW-1:0]            tx_data;                // data to be
                                                              // transmitted
   wire   [`TXFIFO_RW-1:0]            sync_tx_data;           // synd'ed data to be
                                                              // transmitted
   wire   [`RXFIFO_RW-1:0]            rx_data;                // received data
   wire   [`RXFIFO_RW-1:0]            sync_rx_data;           // synd'ed received data
   wire   [15:0]                      divsr;                  // baud clock divisor
   wire   [15:0]                      sync_divsr;             // synd'ed baud clock divisor
   wire   [5:0]                       char_info;              // serial character
   wire   [5:0]                       sync_char_info;         // synd'ed serial5
                                                              // character information
   wire   [`TO_DET_CNT_ENS_WIDTH-1:0] to_det_cnt_ens;         // timeout detect
                                                              // count enables
   wire   [`TO_DET_CNT_ENS_WIDTH-1:0] sync_to_det_cnt_ens;    // synd'ed timeout
                                                              // detect count enables

  //leda NTL_CON12A off
  //LMD: Undriven internal net 
  //LJ:  These are dummy wires used to supress the unconnected port warnings by
  //     Leda tool and will be undriven.Hence can be waived.
  //leda NTL_CON13A off
  //LMD: Non driving internal net 
  //LJ:  These are dummy wires used to supress the unconnected port warnings by
  //     Leda tool and will not be driving any nets.Hence can be waived.
   wire dr_1_unconn, dr_5_unconn, dr_7_unconn, dr_8_unconn;
wire empty_s_0_unconn, empty_s_1_unconn, empty_s_2_unconn,
        empty_s_3_unconn, empty_s_4_unconn, empty_s_5_unconn,
   empty_s_7_unconn, empty_s_8_unconn;
   wire full_s_0_unconn, full_s_1_unconn, full_s_2_unconn,
        full_s_3_unconn, full_s_4_unconn, full_s_5_unconn,
   full_s_7_unconn, full_s_8_unconn;
   wire done_s_0_unconn, done_s_1_unconn, done_s_2_unconn,
        done_s_3_unconn, done_s_4_unconn, done_s_5_unconn,
   done_s_7_unconn, done_s_8_unconn;
wire [`TO_DET_CNT_ENS_WIDTH-1:0] dr_6_unconn, empty_s_6_unconn, full_s_6_unconn, done_s_6_unconn;
  //leda NTL_CON12A on
  //leda NTL_CON13A on


   wire [`TXFIFO_RW-1:0] p2sl_tx_data;
   wire [`TXFIFO_RW-1:0] sp2sl_sync_tx_data;
   // Data synchronizer for TX data and TX start
   i_uart_DW_apb_uart_bcm25
    #(
             .WIDTH        (`TXFIFO_RW),
             .PEND_MODE    (0)
   ) U_DW_apb_uart_bcm25_p2sl_tx_data_ssyzr(
             .clk_s        (pclk),
             .rst_s_n      (presetn),
             .init_s_n     (1'b1),
             .send_s       (tx_start),
             .data_s       (p2sl_tx_data),
             .empty_s      (empty_s_0_unconn),
             .full_s       (full_s_0_unconn),
             .done_s       (done_s_0_unconn),

             .clk_d        (sclk),
             .rst_d_n      (s_rst_n),
             .init_d_n     (1'b1),
             .data_d       (sp2sl_sync_tx_data),
             .test (1'b0),
             .data_avail_d (sync_tx_start)
           );
   assign p2sl_tx_data = tx_data;
   assign sync_tx_data = sp2sl_sync_tx_data;

   wire ss2pl_dr_1_unconn;

   // Data synchronizer for TX finish
   i_uart_DW_apb_uart_bcm25
    #(
             .WIDTH        (1),
             .PEND_MODE    (0)
   ) U_DW_apb_uart_bcm25_s2pl_0_psyzr(
             .clk_s        (sclk),
             .rst_s_n      (s_rst_n),
             .init_s_n     (1'b1),
             .send_s       (tx_finish),
             .data_s       (1'b0),
             .empty_s      (empty_s_1_unconn),
             .full_s       (full_s_1_unconn),
             .done_s       (done_s_1_unconn),

             .clk_d        (pclk),
             .rst_d_n      (presetn),
             .init_d_n     (1'b1),
             .data_d       (ss2pl_dr_1_unconn),
             .test (1'b0),
             .data_avail_d (sync_tx_finish)
           );

   assign dr_1_unconn = ss2pl_dr_1_unconn;

   wire [`RXFIFO_RW-1:0] s2pl_rx_data;
   wire [`RXFIFO_RW-1:0] ss2pl_sync_rx_data;
   // Data synchronizer for RX data and RX finish
   i_uart_DW_apb_uart_bcm25
    #(
             .WIDTH        (`RXFIFO_RW),
             .PEND_MODE    (0)
     ) U_DW_apb_uart_bcm25_s2pl_rx_data_psyzr (
             .clk_s        (sclk),
             .rst_s_n      (s_rst_n),
             .init_s_n     (1'b1),
             .send_s       (rx_finish),
             .data_s       (s2pl_rx_data),
             .empty_s      (empty_s_2_unconn),
             .full_s       (full_s_2_unconn),
             .done_s       (done_s_2_unconn),

             .clk_d        (pclk),
             .rst_d_n      (presetn),
             .init_d_n     (1'b1),
             .data_d       (ss2pl_sync_rx_data),

             .test (1'b0),
             .data_avail_d (sync_rx_finish)
           );

   assign s2pl_rx_data = rx_data; 
   assign sync_rx_data = ss2pl_sync_rx_data;

   wire [15:0] p2sl_divsr;
   wire [15:0] sp2sl_sync_divsr;

   // Data synchronizer for baud divisor and baud divisor
   // write detect
   i_uart_DW_apb_uart_bcm25
    #(
             .WIDTH        (16),
             .PEND_MODE    (1)
     ) U_DW_apb_uart_bcm25_p2sl_divsr_ssyzr (
             .clk_s        (pclk),
             .rst_s_n      (presetn),
             .init_s_n     (1'b1),
             .send_s       (divsr_wd),
             .data_s       (p2sl_divsr),
             .empty_s      (empty_s_3_unconn),
             .full_s       (full_s_3_unconn),
             .done_s       (done_s_3_unconn),

             .clk_d        (sclk),
             .rst_d_n      (s_rst_n),
             .init_d_n     (1'b1),
             .data_d       (sp2sl_sync_divsr),
             .test (1'b0),
             .data_avail_d (sync_divsr_wd)
           );

   assign p2sl_divsr = divsr;
   assign sync_divsr = sp2sl_sync_divsr;



   wire [5:0] p2sl_char_info;
   wire [5:0] sp2sl_sync_char_info;

   // Data synchronizer for character information
   i_uart_DW_apb_uart_bcm25
    #(
             .WIDTH        (6),
             .PEND_MODE    (1)
     ) U_DW_apb_uart_bcm25_p2sl_char_info_ssyzr (
             .clk_s        (pclk),
             .rst_s_n      (presetn),
             .init_s_n     (1'b1),
             .send_s       (char_info_wd),
             .data_s       (p2sl_char_info),
             .empty_s      (empty_s_5_unconn),
             .full_s       (full_s_5_unconn),
             .done_s       (done_s_5_unconn),

             .clk_d        (sclk),
             .rst_d_n      (s_rst_n),
             .init_d_n     (1'b1),
             .data_d       (sp2sl_sync_char_info),

             .test (1'b0),
             .data_avail_d (dr_5_unconn)
           );

  assign p2sl_char_info = char_info;
  assign sync_char_info = sp2sl_sync_char_info;

  wire [`TO_DET_CNT_ENS_WIDTH-1:0] p2sl_to_det_cnt_ens;         // timeout detect
  wire [`TO_DET_CNT_ENS_WIDTH-1:0] sp2sl_sync_to_det_cnt_ens;

genvar i;
generate
  for(i=0;i<`TO_DET_CNT_ENS_WIDTH;i=i+1) begin: GEN_DW_APB_UART_BCM25_6
   i_uart_DW_apb_uart_bcm25
    #(
             .WIDTH        (1),
             .PEND_MODE    (1)
     ) U_DW_apb_uart_bcm25_p2sl_p2sl_to_det_cnt_ens_ssyzr (
             .clk_s        (pclk),
             .rst_s_n      (presetn),
             .init_s_n     (1'b1),
             .send_s       (cnt_ens_ed[i]),
             .data_s       (p2sl_to_det_cnt_ens[i]),
             .empty_s      (empty_s_6_unconn[i]),
             .full_s       (full_s_6_unconn[i]),
             .done_s       (done_s_6_unconn[i]),

             .clk_d        (sclk),
             .rst_d_n      (s_rst_n),
             .init_d_n     (1'b1),
             .data_d       (sp2sl_sync_to_det_cnt_ens[i]),
             .test (1'b0),
             .data_avail_d (dr_6_unconn[i])
           );
end
endgenerate

 assign p2sl_to_det_cnt_ens = to_det_cnt_ens;
 assign sync_to_det_cnt_ens = sp2sl_sync_to_det_cnt_ens;

   wire p2sl_xbreak;
   wire sp2sl_sync_break;

// Level synchronizer for break control
   i_uart_DW_apb_uart_bcm21
    #(
             .WIDTH        (1),
             .F_SYNC_TYPE  (2)
     ) U_DW_apb_uart_bcm21_p2sl_xbreak_ssyzr
     (
      .clk_d    (sclk),
      .rst_d_n  (s_rst_n),
      .init_d_n (1'b1),
     .data_s   (p2sl_xbreak),
      .test     (1'b0),
      .data_d   (sp2sl_sync_break)
     );

   assign p2sl_xbreak = xbreak;
   assign sync_break = sp2sl_sync_break;

   wire p2sl_lb_en;
   wire sp2sl_sync_lb_en;

   // Level synchronizer for loopback enable
   i_uart_DW_apb_uart_bcm21
    #(
             .WIDTH        (1),
             .F_SYNC_TYPE  (2)
     ) U_DW_apb_uart_bcm21_p2sl_lb_en_ssyzr
     (
      .clk_d    (sclk),
      .rst_d_n  (s_rst_n),
      .init_d_n (1'b1),
      .data_s   (p2sl_lb_en),
      .test     (1'b0),
      .data_d   (sp2sl_sync_lb_en)
     );

  assign p2sl_lb_en = lb_en;
  assign sync_lb_en = sp2sl_sync_lb_en;



   wire s2pl_char_to;
   wire as2pl_sync_char_to;
   // Level synchronizer for character timeout
   i_uart_DW_apb_uart_bcm21
    #(
             .WIDTH        (1),
             .F_SYNC_TYPE  (2)
     ) U_DW_apb_uart_bcm21_s2pl_char_to_psyzr
     (
      .clk_d    (pclk),
      .rst_d_n  (presetn),
      .init_d_n (1'b1),
      .data_s   (s2pl_char_to),
      .test     (1'b0),
      .data_d   (as2pl_sync_char_to)
     );


   assign s2pl_char_to = char_to;
   assign sync_char_to = as2pl_sync_char_to;
   // 20100816 jduarte begin
   // Additional synchronizer for STAR 9000405367 fix
   // Data synchronizer for rx_pop acknowledge



   // 20100816 jduarte end
   // Data synchronizer for rx_pop_hld


   wire s2pl_rx_in_prog;
   wire ss2pl_sync_rx_in_prog;
   // Level synchronizer for RX in progress
   i_uart_DW_apb_uart_bcm21
    #(
             .WIDTH        (1),
             .F_SYNC_TYPE  (2)
     ) U_DW_apb_uart_bcm21_s2pl_rx_in_prog_psyzr
     (
      .clk_d    (pclk),
      .rst_d_n  (presetn),
      .init_d_n (1'b1),
      .data_s   (s2pl_rx_in_prog),
      .test     (1'b0),
      .data_d   (ss2pl_sync_rx_in_prog)
     );


   assign s2pl_rx_in_prog = rx_in_prog;
   assign sync_rx_in_prog = ss2pl_sync_rx_in_prog;










endmodule // DW_apb_uart_sync
