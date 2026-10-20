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
// Revision: $Id: //dwh/DW_ocb/DW_apb_uart/amba_dev/src/DW_apb_uart_to_det.v#16 $ 
//
// File :                       DW_apb_uart_to_det.v
//
//
// Author:                      Marc Wall
// Date :                       $Date: 2016/08/26 $
// Abstract     :               Timeout Detection module for the
//                              DW_apb_uart macro-cell
//
// ---------------------------------------------------------------------
// ---------------------------------------------------------------------

module i_uart_DW_apb_uart_to_det
  (
   // Inputs
   sclk,
   s_rst_n,
   bclk,
   // jduarte 20110311 begin
   // CRM_9000452270
   rx_finish,          
   sync_cts_n,
   sync_dsr_n,
   sync_dcd_n,
   sync_ri_n,
   char_to,
   // 20100816 jduarte end
   char_info,
   to_det_cnt_ens
   );

   input                              sclk;                // serial I/F clock
   input                              s_rst_n;             // serial I/F active
                                                           // low async reset
   input                              bclk;                // baud clock
                                                           // power request from
                                                           // the pclk domain
                                                           // receiver
                                                           // active low
                                                           // active low
                                                           // active low
                                                           // active low
   input  [3:0]                       char_info;           // serial character
                                                           // information
   
   input  [`TO_DET_CNT_ENS_WIDTH-1:0] to_det_cnt_ens;      // timeout detect
                                                           // count enables
   
   // jduarte 20110311 begin
   // CRM_9000452270
   input                              rx_finish;           
   // jduarte 20110311 end
                                                           // change the timeouts accordingly
   input                              sync_cts_n;
   input                              sync_dsr_n;
   input                              sync_dcd_n;
   input                              sync_ri_n;
      
                                                           // power request from
                                                           // the sclk domain
                                                           // request
   output                             char_to;             // character timeout
                                                           // toggle signal
   // 20100816 jduarte begin
   // Additional pins for STAR 9000405367 fix
   // 20100816 jduarte end
   
   wire                               char_to_ed;          // character timeout
                                                           // edge detect
   wire                               char_to;             // character timeout
                                                           // toggle signal
   wire                               cto_cnt_en;          // character timeout
                                                           // count enable
   wire                               rbr_empty;           // RBR empty
   // fifo_en will be driving only if FIFO_MODE>0.So in some configuration fifo_en 
   // may be non driving.
   wire                               fifo_en;             // fifo enable
   // After CRM_9000452270 modification, rx_pop was moved into cto_cnt process. So it is
   // not used in the modified code. 
   wire                               rx_pop;              // rx fifo pop
             
   reg  [`TO_DET_CNT_ENS_WIDTH-1:0]  internal_to_det_cnt_ens;// internal
                                                           // to_det_cnt_ens
   
   reg                                int_char_to;         // internal character
                                                           // timeout toggle signal
   reg                                dly_char_to;         // delayed char_to
   // 20100816 jduarte begin
   // Additional signal for STAR 9000405367 fix
   reg                                dly_rx_pop_ack;      // delayed rx_pop_en
   // 20100816 jduarte end
   reg    [9:0]                       cto_cnt;             // character timeout
                                                           // counter
   reg    [9:0]                       timeout_val;         // character timeout
                                                           // value

   // 20100816 jduarte begin
   //
   // Additional logic for STAR 9000405367 fix
   // The rx_pop_ack signal is a "handshake" signal to
   // indicate to DW_apb_uart_reg_file that the rx_pop
   // signal has been received


   // 20100816 jduarte end

   // Character timeout counter
   always @(posedge sclk or negedge s_rst_n)
     begin : cto_cnt_PROC
       if(s_rst_n == 1'b0)
         begin
           cto_cnt <= 10'b0;
         end
       // jduarte 20110308 begin
       // CRM_9000452270
       // else if(cto_cnt_en == 1'b0 || rx_change || char_to_ed)
       else if(cto_cnt_en == 1'b0 
           || rx_finish || char_to_ed)
       // jduarte 20110308 end
         begin
           cto_cnt <= 10'b0;
         end
       else if(bclk == 1'b1)
         begin
           cto_cnt <= cto_cnt + 1;
         end
     end // block: cto_cnt_PROC

   // If FIFO's are enabled then the character timeout counter enable
   // signal is asserted when the RX FIFO is not empty and the RX FIFO
   // is not being read
   
   // jduarte 20110308 begin
   // CRM_9000452270
   // rx_pop was moved into the cto_cnt process
   // This was not required and functionality is intended to remain unchanged, it was done
   // just for a different organization of the code
   //assign cto_cnt_en = (`FIFO_MODE != 0) ? (fifo_en ? ((~rbr_empty) & (~rx_pop)) : 1'b0) : 1'b0;
   assign cto_cnt_en = fifo_en ? (~rbr_empty) : 1'b0;
   // jduarte 20110308 end

   // Assignment of counter enable bits
   assign rbr_empty  = internal_to_det_cnt_ens[2];
   assign fifo_en    = internal_to_det_cnt_ens[1];
   assign rx_pop     = internal_to_det_cnt_ens[0];

   // The width of to_det_cnt_ens can vary in width from 3 bits to 8 bits
   // By assigning to an 8-bit internal version we can reference from this bus rather than the input
   // This internal bus is further broken down to eliminate any logic if CLK_GATE_EN is true
   always @(to_det_cnt_ens)
     begin : internal_to_det_cnt_ens_PROC
      internal_to_det_cnt_ens = {(`TO_DET_CNT_ENS_WIDTH){1'b0}};
      internal_to_det_cnt_ens[`TO_DET_CNT_ENS_WIDTH-1:0] = to_det_cnt_ens[`TO_DET_CNT_ENS_WIDTH-1:0];
     end // block: internal_to_det_cnt_ens_PROC
   
   // If the counter reaches the timeout value then the character timeout
   // signal will be toggled to indicate that a timeout has occurred
   always @(posedge sclk or negedge s_rst_n)
     begin : int_char_to_PROC
       if(s_rst_n == 1'b0)
         begin
           int_char_to <= 1'b0;
         end
       else if(cto_cnt == timeout_val && (~char_to_ed))
         begin
           int_char_to <= (~char_to);
         end
     end // block: int_char_to_PROC
   assign char_to = int_char_to;

   // Delayed character timeout
   always @(posedge sclk or negedge s_rst_n)
     begin : dly_char_to_PROC
       if(s_rst_n == 1'b0)
         begin
           dly_char_to <= 1'b0;
         end
       else
         begin
           dly_char_to <= char_to;
         end
     end // block: dly_char_to_PROC

   // Character timeout edge detect, required to clear counter back to
   // zero to prevent the char_to signal toggling multiple times for a
   // single timeout when the baud clock is slow
   assign char_to_ed = char_to ^ dly_char_to;

   // The character timeout value is equal to 4 character times and since
   // a character time (or duration) can vary depending on the character
   // information that has been set, the character timeout value is
   // calculated as follows:
   // 
   // num. of bits in char * 4 * 16 (num. of bclks in a bit time)
   // 
   
   // 20100815 jduarte begin
   //
   // always @(char_info)
   //   begin : timeout_val_PROC
   //      case(char_info)
   //   
   //        4'b0001 : timeout_val = 512;
   //        4'b0010 : timeout_val = 576;
   //        4'b0011 : timeout_val = 640;
   //        4'b0100 : timeout_val = 480;
   //        4'b0101 : timeout_val = 576;
   //        4'b0110 : timeout_val = 640;
   //        4'b0111 : timeout_val = 704;
   //        4'b1000 : timeout_val = 512;
   //        4'b1001 : timeout_val = 576;
   //        4'b1010 : timeout_val = 640;
   //        4'b1011 : timeout_val = 704;
   //        4'b1100 : timeout_val = 544;
   //        4'b1101 : timeout_val = 640;
   //        4'b1110 : timeout_val = 704;
   //        4'b1111 : timeout_val = 768;
   //
   //        default : timeout_val = 448;
   //
   //      endcase
   //   end // block: timeout_val_PROC

   always @(char_info 
       )
     begin : timeout_val_PROC
        case(char_info)
     
          4'b0001 : begin
                  timeout_val = 10'd512;
      end
          4'b0010 : begin
                  timeout_val = 10'd576;
      end   
          4'b0011 : begin
                  timeout_val = 10'd640;
      end
          4'b0100 : begin
                  timeout_val = 10'd480;
      end
          4'b0101 : begin
                  timeout_val = 10'd576;
      end
          4'b0110 : begin
                  timeout_val = 10'd640;
      end
          4'b0111 : begin
                  timeout_val = 10'd704;
      end
          4'b1000 : begin
                  timeout_val = 10'd512;
      end
          4'b1001 : begin
                  timeout_val = 10'd576;
      end
          4'b1010 : begin
                  timeout_val = 10'd640;
      end
          4'b1011 : begin
                  timeout_val = 10'd704;
      end
          4'b1100 : begin
                  timeout_val = 10'd544;
      end
          4'b1101 : begin
                  timeout_val = 10'd640;
      end
          4'b1110 : begin
                  timeout_val = 10'd704;
      end
          4'b1111 : begin
                  timeout_val = 10'd768;
      end
          default : begin
                  timeout_val = 10'd448;
      end
   
        endcase
     end // block: timeout_val_PROC



   // Asynchronous reset generator for UART low power request



   // Modem Control Synchronization



endmodule // DW_apb_uart_to_det
