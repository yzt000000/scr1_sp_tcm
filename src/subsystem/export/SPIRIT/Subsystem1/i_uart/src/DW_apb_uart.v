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
// File Version     :        $Revision: #20 $ 
// Revision: $Id: //dwh/DW_ocb/DW_apb_uart/amba_dev/src/DW_apb_uart.v#20 $ 
//
// File :                       DW_apb_uart.v
// Author:                      Marc Wall
//
//
// Date :                       $Date: 2016/10/06 $
// Abstract     :               UART Top Level
//
//                                                           (optional)
//                                          (optional)        _________
// _                          _______         _______        |         |
//  \          ______        |       |       |       | /|_|\ | Timeout |
// A \        |      |       |       |       |       |<  _  >| Detector|
// P  | /|_|\ | Bus  | /|_|\ |       |       |       | \| |/ |         |
// B  |<  _  >| I/F  |<  _  >| Reg   | /|_|\ |       |       |_________|
//    | \| |/ | Unit | \| |/ | Block |<  _  >| Sync  |        _______
// I  |       |______|       |       | \| |/ | Block |       |       |
// F  |                      |       |       |       | /|_|\ | Baud  |
//   /        _______  /|_|\ |       |       |       |<  _  >| clock |
// _/        |       |<  _  >|       |       |       | \| |/ | Gen   |
//           | Reset | \| |/ |_______|       |       |       |_______|
//           | Block |        ^     ^        |       |        ________
//           |_______|       / \   / \       |       | /|_|\ |        |
//                           | |   | |       |       |<  _  >| Serial |
//                           \ /   \ /       |_______| \| |/ | TX     |
//                            v     v            ^           | Block  |
//                      |-------|  |-------|    / \          |________|
//                      |       |  |       |    | |
//                      | FIFO  |  | Modem |    \ /
//                      | Block |  | Ctrl  |     v
//                      |       |  | Sync  | |--------|
//                      |_______|  |_______| |        |
//                     (optional)            | Serial |
//                                           | RX     |
//                                           | Block  |
//                                           |________|
//
// Hierarchy of the DW_apb_uart:
//                           Reset Block           (DW_apb_uart_rst)
//                           Bus I/F Unit          (DW_apb_uart_biu)
//                           Register Block        (DW_apb_uart_regfile)
//                           FIFO Block            (DW_apb_uart_fifo)
//                             DW FIFO Controllers (DW_fifoctl_s1_df)
//                             DW RAMs             (DW_ram_r_w_s_dff)
//                           Modem Control Sync    (DW_apb_uart_mc_sync)
//                           Sync Block            (DW_apb_uart_sync)
//                             Level Sync          (DW_apb_uart_bcm21)
//                             Data Sync           (DW_apb_uart_bcm25)
//                             Async Reset Gen     (DW_apb_async_rst_gen)
//                           Baud Clock Gen        (DW_apb_uart_bclk_gen)
//                           Timeout Detector      (DW_apb_uart_to_det)
//                             Async Reset Gen     (DW_apb_async_rst_gen)
//                           Serial TX Block       (DW_apb_uart_tx)
//                           Serial RX Block       (DW_apb_uart_rx)
//
// Please refer to the databook for full details on the signals.
//
// These are found in the "Signal Description" section of the "Signals" chapter.
// There are details on the following
//   Any False Paths
//   Any Multicycle Paths
//   Any Asynchronous Signals
//

module i_uart_DW_apb_uart
  (
   // Inputs
   pclk,
   presetn,
   penable,
   pwrite,
   pwdata,
   paddr,
   psel,
   scan_mode,
   cts_n,
   dsr_n,
   dcd_n,
   ri_n,
   sin,
   // Outputs
   prdata,
   dtr_n,
   rts_n,
   out2_n,
   out1_n,
   dma_tx_req,
   dma_rx_req,
   txrdy_n,
   rxrdy_n,
   sout,
   intr
   );
   input                              pclk;                   // APB Clock
   input                              presetn;                // APB active low
                                                              // async reset
   input                              penable;                // strobe signal
   input                              pwrite;                 // write enable
   input  [`APB_DATA_WIDTH-1:0]       pwdata;                 // write data bus
// paddr[1:0] is used to select byte enable signal.
// IN APB_DATA_WIDTH=32 configuration, all four bytes of a 32 bit
// register is enabled. Hence the LSB two bits are not used in this configuration.
// paddr[0] is used to select lower byte of the 16-bit data word register.
// IN APB_DATA_WIDTH=16 configuration, always 16-bit words are selected and
// hence LSB bit of the paadr is not used in this configuration.

   input  [`UART_ADDR_SLICE_LHS-1:0]  paddr;                  // address bus

   input                              psel;                   // APB peripheral
                                                              // select
                                                              // low async reset
   input                              scan_mode;              // scan mode signal
                                                              // RAM
                                                              // RAM
   input                              cts_n;                  // clear to send,
                                                              // active low
   input                              dsr_n;                  // data set ready,
                                                              // active low
   input                              dcd_n;                  // data carrier detect,
                                                              // active low
   input                              ri_n;                   // ring indicator,
                                                              // active low
                                                              // active high
                                                              // active low
                                                              // active high
                                                              // active low
   input                              sin;                    // serial in

   output [`APB_DATA_WIDTH-1:0]       prdata;                 // read data bus

                                                              // RAM

                                                              // for TX FIFO RAM

                                                              // for TX FIFO RAM

                                                              // TX FIFO RAM,
                                                              // active low

                                                              // TX FIFO RAM,
                                                              // active low

                                                              // chip enable for
                                                              // external ram,
                                                              // active low

                                                              // RAM

                                                              // for RX FIFO RAM

                                                              // for RX FIFO RAM

                                                              // RX FIFO RAM,
                                                              // active low

                                                              // RX FIFO RAM,
                                                              // active low

                                                              // chip enable for
                                                              // external ram,
                                                              // active low

   output                             dtr_n;                  // data terminal ready,
                                                              // active low

   output                             rts_n;                  // request to send,
                                                              // active low

   output                             out2_n;                 // programmable output2,
                                                              // active low

   output                             out1_n;                 // programmable output1,
                                                              // active low

   output                             dma_tx_req;             // TX buffer ready,
                                                              // active high

                                                              // active low

                                                              // active high

                                                              // active low

   output                             dma_rx_req;             // RX buffer ready,
                                                              // active high

                                                              // active low

                                                              // active high

                                                              // active low

   output                             txrdy_n;                // legacy DMA TX
                                                              // buffer ready,
                                                              // active low

   output                             rxrdy_n;                // legacy DMA rx
                                                              // buffer ready,
                                                              // active low

   output                             sout;                   // serial out

                                                              // active low



                                                              // active low


   output                             intr;                   // interrupt




   wire                               wr_en;                  // write enable
   wire                               wr_enx;                 // write enable extra
   wire                               rd_en;                  // read enable
   wire                               dtr_n;                  // data terminal ready,
                                                              // active low
   wire                               rts_n;                  // request to send,
                                                              // active low
   wire                               out2_n;                 // programmable output2,
                                                              // active low
   wire                               out1_n;                 // programmable output1,
                                                              // low async reset
   wire                               new_presetn;            // generated presetn,
                                                              // may include SW reset
   wire                               new_s_rst_n;            // generated s_rst_n,
                                                              // may include SW reset
   wire                               sync_cts_n;             // synd'ed clear to send,
                                                              // active low
   wire                               sync_dsr_n;             // synd'ed data set ready,
                                                              // active low
   wire                               sync_dcd_n;             // synd'ed data carrier detect,
                                                              // active low
   wire                               sync_ri_n;              // synd'ed ring indicator,
                                                              // active low
   wire                               dma_tx_req;             // TX buffer ready,
                                                              // active high
   wire                               dma_rx_req;             // RX buffer ready,
                                                              // active high
   wire                               dma_tx_req_n;           // TX buffer ready,
                                                              // active low
   wire                               dma_rx_req_n;           // RX buffer ready,
                                                              // active low
   wire                               ser_out_lb;             // serial tx data out
                                                              // for loopback
   wire                               sout;                   // serial out
   wire                               tx_start;               // start serial
                                                              // transmission
   wire                               tx_finish;              // serial transmission
                                                              // of current character
                                                              // finished
   wire                               lb_en;                  // loopback enable
   wire                               xbreak;                  // break control
   wire                               divsr_wd;               // baud clock divisor
                                                              // write detect
   wire                               bclk;                   // baud clock
   wire                               rx_in_prog;             // serial reception
                                                              // in progress
   wire                               rx_finish;              // serial reception of
                                                              // current character
                                                              // finished
   wire                               tx_push;                // tx fifo pop
   wire                               tx_pop;                 // tx fifo pop
   wire                               rx_push;                // rx fifo push
   wire                               rx_pop;                 // rx fifo pop
   wire                               tx_fifo_rst;            // tx fifo reset
   wire                               rx_fifo_rst;            // rx fifo reset
   wire   [7:0]                       tx_push_data;           // data to the tx fifo
   wire   [9:0]                       rx_push_data;           // data to the tx fifo

   wire                               tx_full;                // tx fifo full status
   wire                               tx_empty;               // tx fifo empty status

   wire                               rx_full;                // rx fifo full status
   wire                               rx_empty;               // rx fifo empty status
   wire                               rx_overflow;            // rx fifo overflow status
   wire                               char_to;                // character timeout
   wire                               txrdy_n;                // legacy DMA tx
                                                              // buffer ready,
                                                              // active low
   wire                               rxrdy_n;                // legacy DMA rx
                                                              // buffer ready,
                                                              // active low
   wire   [3:0]                       byte_en;                // active byte lane
   wire   [`UART_ADDR_SLICE_LHS-3:0]  reg_addr;               // register offset
                                                              // address
   // Only a maximum of 10bits of ipwdata are being used in the DW_apb_uart_regfile
   // and rest is unused. So only the required bits are transferred to regfile using
   // ipwdata_int signal.So the remaining bits of ipwdata will not be driving any signal in 
   // APB_DATA_WIDTH!=8 configuration.
   wire   [`APB_DATA_WIDTH-1:0]       ipwdata;                // internal pwdata bus
   wire   [`WR_DATA_WIDTH-1:0]        ipwdata_int;            // internal signal to supress warning of unused port
                                                              // in DW_apb_uart_regfile
   wire   [`MAX_APB_DATA_WIDTH-1:0]   iprdata;                // internal prdata bus
   wire   [7:0]                       tx_data;                // data to be
                                                              // transmitted
   wire   [9:0]                       rx_data;                // received data
   wire   [15:0]                      divsr;                  // baud clock divisor
   // aaraujo @ 17/05/2011 : CRM_9000431453
   // Updated width of *char_info signals to include
   // stick parity feature
   wire   [5:0]                       char_info;              // serial character
   wire   [7:0]                       tx_pop_data;            // data from the tx fifo
   wire   [9:0]                       rx_pop_data;            // data from the rx fifo
   // This is an on-chip debug signal used for debugging. The debug output is enabled
   // only if debugging mode is selected.So the debug signal will be non driving if 
   // DEBUG is 0.
   wire   [31:0]                      debug;                  // on-chip debug
   wire   [`TO_DET_CNT_ENS_WIDTH-1:0] to_det_cnt_ens;         // timeout detect
                                                              // count enables




   wire   [15:0]                      int_divsr;
   wire                               int_divsr_wd;   

   wire                              int_clk;
   wire                              int_uart_lp_req;
   wire [`TO_DET_CNT_ENS_WIDTH-1:0]  int_to_det_cnt_ens;    
   wire [3:0]                        int_char_info;

      assign int_clk             = pclk;
      assign int_divsr           = divsr;
      assign int_divsr_wd        = divsr_wd;
      assign int_to_det_cnt_ens  = to_det_cnt_ens; 
      assign int_char_info       = char_info[3:0];

// when CLK_GATE_EN=0, uart_lp_req is tied to zero.
      assign int_uart_lp_req     = 1'b0;

  wire alr_unconn, bn_unconn, bclk_unconnected;


   // APB Interface
  // byte_en is a strobe signal to enable bytes.When APB_DATA_WIDTH is 32, all the 4 bytes
  // are enabled. Hence byte_en will tied to supply. i.e. 1111.
   i_uart_DW_apb_uart_biu
    #(
    .ADDR_SLICE_LHS (`UART_ADDR_SLICE_LHS)
    ) U_DW_apb_uart_biu
     (
      // Inputs
      .pclk              (pclk),
      .presetn           (new_presetn),
      .psel              (psel),
      .penable           (penable),
      .pwrite            (pwrite),
      .paddr             (paddr),
      .pwdata            (pwdata),
      .prdata            (prdata),

      // Outputs
      .wr_en             (wr_en),
      .wr_enx            (wr_enx),
      .rd_en             (rd_en),
      .byte_en           (byte_en),
      .reg_addr          (reg_addr),
      .ipwdata           (ipwdata),
      .iprdata           (iprdata)
      );

   // UART Reset Block
   i_uart_DW_apb_uart_rst
    U_DW_apb_uart_rst
     (
     // Inputs
      .presetn(presetn),
      .scan_mode(scan_mode),
      // Outputs
      .new_presetn(new_presetn),
      .new_s_rst_n(new_s_rst_n)
      );

   // UART Register Block
   // debug[31:14] signal are intentionally tied to supply.debug is an on-chip signal
   // used for debugging.Some of the bits are not used or reserved for future. So it 
   // is tied to supply.
   i_uart_DW_apb_uart_regfile
    U_DW_apb_uart_regfile
     (
      // Inputs
      .pclk(pclk),
      .presetn(new_presetn),
      .scan_mode(scan_mode),
      .wr_en(wr_en),
      .wr_enx(wr_enx),
      .rd_en(rd_en),
      .byte_en(byte_en),
      .reg_addr(reg_addr),
      .ipwdata(ipwdata_int),
      .tx_full(tx_full),
      .tx_empty(tx_empty),
      .rx_full(rx_full),
      .rx_empty(rx_empty),
      .rx_overflow(rx_overflow),
      .tx_pop_data(tx_pop_data),
      .rx_pop_data(rx_pop_data),
      .tx_finish(tx_finish),
      .rx_finish(rx_finish),
      .rx_data(rx_data),
      .char_to(char_to),
      .rx_in_prog(rx_in_prog),

      .cts_n(sync_cts_n),
      .dsr_n(sync_dsr_n),
      .dcd_n(sync_dcd_n),
      .ri_n(sync_ri_n),
      // Outputs
      .iprdata(iprdata),
      .tx_push(tx_push),
      .tx_pop(tx_pop),
      .rx_push(rx_push),
      .rx_pop(rx_pop),
      .tx_fifo_rst(tx_fifo_rst),
      .rx_fifo_rst(rx_fifo_rst),
      .tx_push_data(tx_push_data),
      .rx_push_data(rx_push_data),
      .tx_start(tx_start),
      .tx_data(tx_data),
      .lb_en_o(lb_en),
      .xbreak_o(xbreak),
      .to_det_cnt_ens(to_det_cnt_ens),
      // jduarte 20110309 end
      .divsr(divsr),
      .divsr_wd(divsr_wd),
      .char_info(char_info),
      .dtr_n(dtr_n),
      .rts_n(rts_n),
      .out1_n(out1_n),
      .out2_n(out2_n),
      .dma_tx_req(dma_tx_req),
      .dma_rx_req(dma_rx_req),
      .dma_tx_req_n(dma_tx_req_n),
      .dma_rx_req_n(dma_rx_req_n),
      .debug(debug),
      .intr(intr)
      );

   i_uart_DW_apb_uart_fifo
    U_DW_apb_uart_fifo
     (
      .pclk(pclk),
      .presetn(new_presetn),
      .tx_push(tx_push),
      .tx_pop(tx_pop),
      .rx_push(rx_push),
      .rx_pop(rx_pop),
      .tx_fifo_rst(tx_fifo_rst),
      .rx_fifo_rst(rx_fifo_rst),
      .tx_push_data(tx_push_data),
      .rx_push_data(rx_push_data),
      .tx_full(tx_full),
      .tx_empty(tx_empty),
      .rx_full(rx_full),
      .rx_empty(rx_empty),
      .rx_overflow(rx_overflow),
      .tx_pop_data(tx_pop_data),
      .rx_pop_data(rx_pop_data)
      );




   // Modem Control Synchronization
   i_uart_DW_apb_uart_mc_sync
    U_DW_apb_uart_mc_sync
     (
      .clk                 (pclk),
      .resetn              (new_presetn),
      .cts_n               (cts_n),
      .dsr_n               (dsr_n),
      .dcd_n               (dcd_n),
      .ri_n                (ri_n),
      .sync_cts_n          (sync_cts_n),
      .sync_dsr_n          (sync_dsr_n),
      .sync_dcd_n          (sync_dcd_n),
      .sync_ri_n           (sync_ri_n)
      );

   // Baud Clock Generator
   i_uart_DW_apb_uart_bclk_gen
    U_DW_apb_uart_bclk_gen
     (
      // Inputs
      .s_rst_n(new_s_rst_n),
      .sclk(int_clk),
      .divisor_wd(int_divsr_wd),
      .divisor(int_divsr),
      .uart_lp_req(int_uart_lp_req),
      .bclk(bclk)
      );



   // Serial Transmitter
   i_uart_DW_apb_uart_tx
    U_DW_apb_uart_tx
     (
      // Inputs
      .sclk(pclk),
      .s_rst_n(new_s_rst_n),
      .bclk(bclk),
      .tx_start(tx_start),
      .lb_en(lb_en),
      .xbreak(xbreak),
      .tx_data(tx_data),
      .char_info(char_info),
      .sir_en(1'b0),

      // Outputs
      .tx_finish(tx_finish),
      .ser_out_lb(ser_out_lb),
      .sout(sout)
      );

   // Serial Receiver
   i_uart_DW_apb_uart_rx
    U_DW_apb_uart_rx
     (
      // Inputs
      .sclk(pclk),
      .s_rst_n(new_s_rst_n),
      .bclk(bclk),
      .sin(sin),
      .sir_in(1'b0),
      .lb_en(lb_en),
      .divisor(divsr),
      .char_info(char_info),
      .sir_en(1'b0),

      .ser_out_lb(ser_out_lb),
      // Outputs
      .rx_in_prog(rx_in_prog),
      .rx_finish(rx_finish),
      .rx_data(rx_data)
      );

   i_uart_DW_apb_uart_to_det
    U_DW_apb_uart_to_det
     (
      // Inputs
      .sclk(int_clk),
      .s_rst_n(new_s_rst_n),
      .sync_cts_n(sync_cts_n),
      .sync_dsr_n(sync_dsr_n),
      .sync_dcd_n(sync_dcd_n),
      .sync_ri_n(sync_ri_n),
      .to_det_cnt_ens(int_to_det_cnt_ens),
      .char_info(int_char_info[3:0]),
      // jduarte 20110309 begin
      // CRM_9000445419 && CRM_9000445469
      // jduarte 20110309 end
      // jduarte 20110311 begin
      // CRM_9000452270
      .rx_finish(rx_finish),
      .char_to(char_to),
      .bclk(bclk)
      );


// When these signal are not driven by their respective output module,they are driven externally. 


   assign ipwdata_int        = ipwdata[`WR_DATA_WIDTH-1:0];


   // jduarte 20110309 begin
   // CRM_9000445419 && CRM_9000445469
   // jduarte 20110309 end
   // low power request selection


   // DMA signaling - polarity selection
   assign txrdy_n            = dma_tx_req_n;
   assign rxrdy_n            = dma_rx_req_n;


endmodule // DW_apb_uart

