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
// File Version     :        $Revision: #11 $ 
// Revision: $Id: //dwh/DW_ocb/DW_apb_uart/amba_dev/src/DW_apb_uart_bclk_gen.v#11 $ 
//
// File :                       DW_apb_uart_bclk_gen.v
// Author:                      Marc Wall
//
//
// Date :                       $Date: 2016/08/26 $
// Abstract     :               UART baud clock generator
//
// ---------------------------------------------------------------------
// ---------------------------------------------------------------------

// -----------------------------------------------------------
// -- UART Divisor Width Macro
// -----------------------------------------------------------
`define   UART_DIV_WIDTH    16

module i_uart_DW_apb_uart_bclk_gen
  (
   // Inputs
   sclk,
   s_rst_n,
   divisor,
   divisor_wd,
   uart_lp_req,
   bclk
   );

   input                         sclk;          // clock
   input                         s_rst_n;       // active low async reset
   input  [`UART_DIV_WIDTH-1:0]  divisor;       // clock divisor
   input                         divisor_wd;    // divisor change indicator
   input                         uart_lp_req;   // uart low power request
                                                // clock clear indicator

   output                        bclk;          // baud clock

   reg                           next_bclk;     // Next bclk
   reg                           bclk;          // baud clock
   reg    [`UART_DIV_WIDTH-1:0]  cnt;           // clock counter reg

   wire                          clear;         // counter and generated
                                                // clock clear indicator
   wire                          int_divisor_wd;// internal divisor_wd



   // Counts the number of sclk cycles that have passed,
   // up to the divisor value minus one. When this value
   // is reached OR a clear occurs the counter wraps to
   // zero.
   // Used in the generation of the baud clock signals
   //
   // clear is the highest precedence as the divisor could be changed 
   // to be lower than the cnt value and we would have lockout.
   always @ (posedge sclk or negedge s_rst_n)
     begin : cnt_PROC
       if(s_rst_n == 1'b0)
         begin
           cnt     <= {`UART_DIV_WIDTH{1'b0}};
         end
       else
         begin
           if(clear) begin
             cnt <= {`UART_DIV_WIDTH{1'b0}};
           end else begin
             if(divisor != {`UART_DIV_WIDTH{1'b0}})
             begin
               if(cnt == (divisor -{{(`UART_DIV_WIDTH-1){1'b0}},{1'b1}}))
                 begin
                   cnt <= {`UART_DIV_WIDTH{1'b0}};
                 end
               else
                 begin
                   cnt <= cnt + {{(`UART_DIV_WIDTH-1){1'b0}},{1'b1}};
                 end
             end
           end
          end
     end // block: cnt_PROC

   // The clear signal gets asserted when the divisor is zero or
   // whenever the divisor value is going to be changed as indicated
   // by the assertion of divisor_wd signal
   assign clear = ((divisor == {`UART_DIV_WIDTH{1'b0}}) || int_divisor_wd 
   ) ? 1 : 0;

   // Internal divisor_wd, is asserted when the divisor_wd edge detect
   // signal is asserted when the DW_apb_uart is configured to have two
   // clocks, else it is asserted when the divisor_wd signal is asserted
   assign int_divisor_wd = divisor_wd;


   // Baud clock generator
   // When clear is asserted the baud clock signal is set to
   // its inactive state, the assertion of the baud clock signal
   // is determined by the current value of the clock counter.
   // some examples of baud clock assertion for differing
   // divisors are as follows:
   //
   //          _   _   _   _   _   _   _
   //  sclk  _| |_| |_| |_| |_| |_| |_| |_
   //        _____
   //  clear      |_______________________
   //
   //  Divisor of 2
   //        _________ ___ ___ ___ ___ ___
   //  cnt   ___0_____X_1_X_0_X_1_X_0_X_1_X
   //                  ___     ___     ___
   //  bclk  _________|   |___|   |___|   |
   //
   //  Divisor of 3
   //        _________ ___ ___ ___ ___ ___
   //  cnt   ___0_____X_1_X_2_X_0_X_1_X_2_X
   //                  ___         ___
   //  bclk  _________|   |_______|   |___
   //
   //  Divisor of 5
   //        _________ ___ ___ ___ ___ ___
   //  cnt   ___0_____X_1_X_2_X_3_X_4_X_0_X
   //                  ___
   //  bclk  _________|   |_______________|
   //
   always @ (posedge sclk or negedge s_rst_n)
     begin : bclk_PROC
     if (s_rst_n == 1'b0)
       bclk <= 1'b0;
     else
       bclk <= next_bclk;
   end

   // Next bclk
   always @(uart_lp_req or clear or divisor or bclk or cnt)
     begin : next_bclk_PROC
       if(clear)
         next_bclk = 1'b0;
       else if(divisor == 16'b10)
         if (uart_lp_req == 1) next_bclk = bclk;
         else                  next_bclk = ~bclk;
       else if(cnt == {`UART_DIV_WIDTH{1'b0}})
         next_bclk = 1'b1;
       else
         next_bclk = 1'b0;
     end



                   


//-----------------------------------------------------------------------------
//--         FRACTIONAL BAUD RATE enhancements below                         --
//--                                                                         --
//-----------------------------------------------------------------------------

endmodule
