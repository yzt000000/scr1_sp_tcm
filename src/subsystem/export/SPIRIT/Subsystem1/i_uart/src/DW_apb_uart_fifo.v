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
// File Version     :        $Revision: #16 $ 
// Revision: $Id: //dwh/DW_ocb/DW_apb_uart/amba_dev/src/DW_apb_uart_fifo.v#16 $ 
//
// File :                       DW_apb_uart_tx.v
// Author:                      Marc Wall
//
//
// Date :                       $Date: 2016/08/26 $
// Abstract     :               Top level FIFO module for the DW_apb_uart
//                              macro-cell. May include internal DW RAM
//                              (when configured), else it will connect
//                              to an external RAM via I/F signals 
//
//
// ---------------------------------------------------------------------
// ---------------------------------------------------------------------

module i_uart_DW_apb_uart_fifo
  (
   // Inputs
   pclk,
   presetn,
   tx_push,
   tx_pop,
   rx_push,
   rx_pop,
   tx_fifo_rst,
   rx_fifo_rst,
   tx_push_data,
   rx_push_data,
   // Outputs
   tx_full,
   tx_empty,
   //tx_almost_empty,
   rx_full,
   rx_empty,
   rx_overflow,
   tx_pop_data,
   rx_pop_data
   );

   input                             pclk;             // APB clock 
   input                             presetn;          // APB async reset
   input                             tx_push;          // tx fifo pop
   input                             tx_pop;           // tx fifo pop
   input                             rx_push;          // rx fifo push
   input                             rx_pop;           // rx fifo pop
   input                             tx_fifo_rst;      // tx fifo reset
   input                             rx_fifo_rst;      // rx fifo reset
                                                       // output enable
                                                       // from external ram
   input  [`TXFIFO_RW-1:0]           tx_push_data;     // data to the tx fifo
                                                       // from external ram
   input  [`RXFIFO_RW-1:0]           rx_push_data;     // data to the tx fifo

   output                            tx_full;          // tx fifo full status
   output                            tx_empty;         // tx fifo empty status
   //output                          tx_almost_empty;  // tx fifo almost empty status
   output                            rx_full;          // rx fifo full status
   output                            rx_empty;         // rx fifo empty status
   output                            rx_overflow;      // rx fifo overflow status
                                                       // enable for external
                                                       // ram, active low
                                                       // enable for external
                                                       // ram, active low
                                                       // enable for external
                                                       // ram, active low
                                                       // enable for external
                                                       // ram, active low
                                                       // enable for external
                                                       // ram, active low
                                                       // enable for external
                                                       // ram, active low
                                                       // to external ram
                                                       // for external ram
                                                       // for external ram
   output [`TXFIFO_RW-1:0]           tx_pop_data;      // data from the tx fifo
                                                       // to external ram
                                                       // for external ram
                                                       // for external ram
   output [`RXFIFO_RW-1:0]           rx_pop_data;      // data from the rx fifo

   wire                              tx_we_n;          // tx fifo write 
                                                       // enable, active low
   wire                              rx_we_n;          // rx fifo write
                                                       // enable, active low
   wire                              tx_fifo_rst_n;    // tx fifo reset,
                                                       // active low
   wire                              tx_push_n;        // tx fifo push,
                                                       // active low
   wire                              tx_pop_n;         // tx fifo pop,
                                                       // active low
   wire                              rx_fifo_rst_n;    // rx fifo reset,
                                                       // active low
   wire                              rx_push_n;        // rx fifo push,
                                                       // active low
   wire                              rx_pop_n;         // rx fifo pop,
                                                       // active low
   wire                              rx_overflow;      // rx fifo overflow status
   wire                              tx_full;          // tx fifo full status 
   wire                              tx_empty;         // tx fifo empty status
   wire                              rx_full;          // rx fifo full status 
   wire                              rx_empty;         // rx fifo empty status

   wire   [`FIFO_ADDR_WIDTH-1:0]     tx_wr_addr;       // tx fifo write address
   wire   [`FIFO_ADDR_WIDTH-1:0]     tx_rd_addr;       // tx fifo read address
   wire   [`TXFIFO_RW-1:0]           tx_push_data;     // tx fifo write data
   wire   [`TXFIFO_RW-1:0]           tx_pop_data;      // tx fifo read data
   wire   [`TXFIFO_RW-1:0]           tx_data_out;      // tx fifo internal
                                                       // (dw) ram read data
   wire   [`FIFO_ADDR_WIDTH-1:0]     rx_wr_addr;       // rx fifo write address
   wire   [`FIFO_ADDR_WIDTH-1:0]     rx_rd_addr;       // rx fifo read address
   wire   [`RXFIFO_RW-1:0]           rx_push_data;     // rx fifo write data
   wire   [`RXFIFO_RW-1:0]           rx_pop_data;      // rx fifo read data
   wire   [`RXFIFO_RW-1:0]           rx_data_out;      // rx fifo dw ram read data
   //leda NTL_CON13A off
   //LMD: Non driving internal net 
   //LJ:  These are dummy wires used to supress the unconnected 
   //     port warnings by Leda tool and will not be driving any nets.
   wire                              rx_af_full;       // rx fifo almost full status
   //leda NTL_CON13A on
 
   //leda NTL_CON13A off
   //LMD: Non driving internal net 
   //LJ:  These are dummy wires used to supress the unconnected 
   //     port warnings by Leda tool and will not be driving any nets.
   wire tx_ae_unconn, tx_af_unconn, tx_hf_unconn, tx_error_unconn; 
   wire rx_ae_unconn, rx_hf_unconn, rx_error_unconn; 
   wire [`FIFO_ADDR_WIDTH-1:0] tx_wc_unconn;
   wire [`FIFO_ADDR_WIDTH-1:0] rx_wc_unconn;
   wire tx_nen_unconn, tx_nf_unconn, tx_nxt_error_unconn;
   wire rx_nen_unconn, rx_nf_unconn, rx_nxt_error_unconn;
   //leda NTL_CON13A on
      

  // CRM 9000533265 
// leda NTL_CON16 off
// LMD: Nets or cell pins should not be tied to logic 0 / logic 1
// LJ : In RTC_FCT mode, the value of threshold is fixed.
  wire [`FIFO_ADDR_WIDTH-1 :0]       int_af_thresh;
// leda NTL_CON16 on


// leda NTL_CON16 off
// LMD: Nets or cell pins should not be tied to logic 0 / logic 1
// LJ : In RTC_FCT mode, the value of threshold is fixed.
   assign int_af_thresh  = {`FIFO_ADDR_WIDTH{1'b1}};
// leda NTL_CON16 on
             
   // ------------------------------------------------------
   // Instance of transmit FIFO controller
   // ------------------------------------------------------

   i_uart_DW_apb_uart_bcm06
    #(
      .DEPTH          (`FIFO_MODE),
      .ERR_MODE       (2),
      .ADDR_WIDTH     (`FIFO_ADDR_WIDTH)
    )
   U_tx_fifo
     (
      .clk            (pclk),
      .rst_n          (presetn),
      .init_n         (tx_fifo_rst_n),
      .push_req_n     (tx_push_n),
      .pop_req_n      (tx_pop_n),
      .diag_n         (1'b1),
      .ae_level       ({`FIFO_ADDR_WIDTH{1'b0}}),
      .af_thresh      ({`FIFO_ADDR_WIDTH{1'b1}}),
      .we_n           (tx_we_n),
      .wr_addr        (tx_wr_addr),
      .rd_addr        (tx_rd_addr),
      .empty          (tx_empty),
      .almost_empty   (tx_ae_unconn),
      .full           (tx_full),
      .almost_full    (tx_af_unconn),
      .half_full      (tx_hf_unconn),
      .error          (tx_error_unconn),
      .wrd_count      (tx_wc_unconn),
      .nxt_empty_n    (tx_nen_unconn),
      .nxt_full       (tx_nf_unconn),
      .nxt_error      (tx_nxt_error_unconn)
      );


   assign tx_fifo_rst_n = ~tx_fifo_rst;
   assign tx_push_n     = ~tx_push;
   assign tx_pop_n      = ~tx_pop;

   // ------------------------------------------------------
   // Instance of transmit FIFO DW RAM block, which is only
   // included if the UART is configured to use internal
   // FIFO memories
   // ------------------------------------------------------

   i_uart_DW_apb_uart_bcm57
    #(
      .DATA_WIDTH     (`TXFIFO_RW),
      .DEPTH          (`FIFO_MODE),
      .MEM_MODE       (0),
      .ADDR_WIDTH     (`FIFO_ADDR_WIDTH)
   )
   U_DW_tx_ram
     (
      .clk            (pclk),
      .rst_n          (presetn),
      .init_n         (1'b1),
      .wr_addr        (tx_wr_addr),
      .rd_addr        (tx_rd_addr),
      .data_in        (tx_push_data),
      .wr_n           (tx_we_n),
      .data_out       (tx_data_out)
      );


   // ------------------------------------------------------
   // Selection between internal and external FIFO RAM
   // If the UART is configured to use external RAM's then
   // TX pop data is the read data from the external RAM
   // (tx_ram_out), else it is the read data from the DW RAM
   // (tx_data_out). All external FIFO RAM signals are driven
   // low if the UART is configured to use internal RAM's,
   // except the active low control signals which are driven
   // high
   // ------------------------------------------------------

   assign tx_pop_data    = tx_data_out;


   // ------------------------------------------------------
   // Instance of receive FIFO controller
   // ------------------------------------------------------
   i_uart_DW_apb_uart_bcm06
    #(
      .DEPTH          (`FIFO_MODE),
      .ERR_MODE       (2),
      .ADDR_WIDTH     (`FIFO_ADDR_WIDTH)
    )U_rx_fifo
     (
      .clk            (pclk),
      .rst_n          (presetn),
      .init_n         (rx_fifo_rst_n),
      .push_req_n     (rx_push_n),
      .pop_req_n      (rx_pop_n),
      .diag_n         (1'b1),
      .ae_level       ({`FIFO_ADDR_WIDTH{1'b0}}),
  // CRM 9000533265 
  // Almost full Threshold = Depth of fifo - 2
      .af_thresh      (int_af_thresh),
      .almost_full    (rx_af_full),
      .we_n           (rx_we_n),
      .wr_addr        (rx_wr_addr),
      .rd_addr        (rx_rd_addr),
      .empty          (rx_empty),
      .almost_empty   (rx_ae_unconn),
      .full           (rx_full),
      .half_full      (rx_hf_unconn),
      .error          (rx_error_unconn),
      .wrd_count      (rx_wc_unconn),
      .nxt_empty_n    (rx_nen_unconn),
      .nxt_full       (rx_nf_unconn),
      .nxt_error      (rx_nxt_error_unconn)
      );



   // the receive FIFO overflow signal get asserted if the RX FIFO is
   // full and a RX push occurs and there is no RX pop at the same time
   assign rx_overflow   = rx_full & (rx_push & (~rx_pop));

   assign rx_fifo_rst_n = ~rx_fifo_rst;
   assign rx_push_n     = ~rx_push;
   assign rx_pop_n      = ~rx_pop;
   // CRM 9000533265
   // Receiver almost full status
   // ------------------------------------------------------
   // Instance of receive FIFO DW RAM block, which is only
   // included if the UART is configured to use internal
   // FIFO memories
   // ------------------------------------------------------
   i_uart_DW_apb_uart_bcm57
    #(
      .DATA_WIDTH     (`RXFIFO_RW),
      .DEPTH          (`FIFO_MODE),
      .MEM_MODE       (0),
      .ADDR_WIDTH     (`FIFO_ADDR_WIDTH)
    )
   U_DW_rx_ram
     (
      .clk            (pclk),
      .rst_n          (presetn),
      .init_n         (1'b1),
      .wr_addr        (rx_wr_addr),
      .rd_addr        (rx_rd_addr),
      .data_in        (rx_push_data),
      .wr_n           (rx_we_n),
      .data_out       (rx_data_out)
      );


   // ------------------------------------------------------
   // Selection between internal and external FIFO RAM
   // If the UART is configured to use external RAM's then
   // RX pop data is the read data from the external RAM
   // (rx_ram_out), else it is the read data from the DW RAM
   // (rx_data_out). All external FIFO RAM signals are driven
   // low if the UART is configured to use internal RAM's,
   // except the active low control signals which are driven
   // high
   // ------------------------------------------------------
   assign rx_pop_data    = rx_data_out;

endmodule
