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
// File Version     :        $Revision: #8 $ 
// Revision: $Id: //dwh/DW_ocb/DW_apb_uart/amba_dev/src/DW_apb_async_rst_gen.v#8 $ 
//
// File :                       DW_apb_async_rst_gen.v
// Author:                      Marc Wall
//
//
// Date :                       $DateTime: 2016/08/26 00:52:40 $
// Abstract     :               Level Synchronization module
//
//
// ---------------------------------------------------------------------
// ---------------------------------------------------------------------

module i_uart_DW_apb_async_rst_gen
  (
   // Inputs
   clk,
   async_rst1,
   async_rst2,
   scan_mode,
                  
   // Outputs
   new_async_rst_n
   );

   // -----------------------------------------------------------
   // -- Asynchronous reset polarity parameters
   // -----------------------------------------------------------

   input                         clk;                 // clock
   input                         async_rst1;          // async reset 1
   input                         async_rst2;          // async reset 2
   input                         scan_mode;           // scan mode signal
   
   output                        new_async_rst_n;     // new async active
                                                      // low reset

   wire                          new_async_rst_n;     // new async active
                                                      // low reset
   wire                          async_rst_n;         // async active
                                                      // low reset
   wire                          int_async_rst1;      // internal async_rst1
   wire                          int_async_rst2;      // internal async_rst2
   wire                          int_new_async_rst_n; // internal
                                                      // new_async_rst_n

   reg                           pre_new_async_rst_n; // asynchronous reset
   wire                          pre_new_async_rst_n_int; // asynchronous reset

   // New asynchronous active low reset
   assign new_async_rst_n = scan_mode ? int_async_rst1 : int_new_async_rst_n;
   
   // When the async_rst_n signal is asserted (low) the register will
   // be reset and the active low new asynchronous reset signal will
   // get asserted (asynchronously) and will be removed synchronously
   // in relation to the specified clock on the next rising edge.
   // As this reset is driven by the output of a register it must have
   // the ability to be controlled, this is done using the scan mode 
   // signal

   always @(posedge clk or negedge async_rst_n)
     begin : int_new_async_rst_PROC
       if(async_rst_n == 1'b0)
         begin
           pre_new_async_rst_n <= 1'b0;
         end
       else
         begin
           if(scan_mode)
             begin
               pre_new_async_rst_n <= pre_new_async_rst_n_int;
             end
           else
             begin
               pre_new_async_rst_n <= 1'b1;
             end
         end
     end // block: int_new_async_rst_n_PROC

   assign int_new_async_rst_n = pre_new_async_rst_n;
   assign pre_new_async_rst_n_int = pre_new_async_rst_n;

   // The active low asynchronous reset for the reset register
   // is asserted (low) when the internal async_rst1 signal
   // or internal async_rst2 signal is asserted (low)
   assign async_rst_n = scan_mode ? int_async_rst1 : int_async_rst1 & int_async_rst2;

   // Polarity assignment for asynchronous reset inputs
   assign int_async_rst1 = async_rst1;
   assign int_async_rst2 = (~async_rst2);


endmodule // DW_apb_async_rst_gen
