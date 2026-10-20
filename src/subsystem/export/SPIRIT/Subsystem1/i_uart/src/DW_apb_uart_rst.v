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
// Revision: $Id: //dwh/DW_ocb/DW_apb_uart/amba_dev/src/DW_apb_uart_rst.v#10 $ 
//
// File :                       DW_apb_uart_rst.v
// Author:                      Marc Wall
//
//
// Date :                       $DateTime: 2016/08/26 00:52:40 $
// Abstract     :               Reset module for the DW_apb_uart
//                              macro-cell.
//
//
// ---------------------------------------------------------------------
// ---------------------------------------------------------------------

module i_uart_DW_apb_uart_rst
  (
   // Inputs
   presetn,
   scan_mode,
   // Outputs
   new_presetn,
   new_s_rst_n
   );

   input                             presetn;            // APB async reset
                                                         // low async reset
   input                             scan_mode;          // scan mode signal
   
   output                            new_presetn;        // generated presetn,
                                                         // may include SW reset
   output                            new_s_rst_n;        // generated s_rst_n,
                                                         // may include SW reset
   wire                              new_presetn;        // generated presetn,
                                                         // may include SW reset
   wire                              new_s_rst_n;        // generated s_rst_n,
                                                         // may include SW reset
   wire                              int_new_s_rst_n;    // internal new_s_rst_n

   // ------------------------------------------------------
   // UR (UART reset) related functionality
   // ------------------------------------------------------
   
   // This signal is used as the pclk domain reset for all other modules
   // in the UART thus it must always be assigned a practical value. That
   // is, if the UART has been configured to have the SRR then it is asserted
   // when either presetn is asserted (low) or sw_rst_n is asserted (low),
   // else it is asserted when presetn (only) is asserted.
   // Under certain configurations this reset maybe driven by the output
   // of a register and hence must have the ability to be controlled, this
   // is done using the scan mode signal
   assign new_presetn = presetn;

   // Under certain configurations this reset maybe driven by the output
   // of a register and hence must have the ability to be controlled, this
   // is done using the scan mode signal
   assign new_s_rst_n = scan_mode ? new_presetn : int_new_s_rst_n;

   // This signal is used as the sclk domain reset for all other modules
   // in the UART thus it must always be assigned a practical value. That
   // is, if the UART has been configured to have two clocks, then if it
   // has been configured to have the SRR then it is asserted when either
   // s_rst_n is asserted (low) or sclk_sync2 is asserted (low), else
   // it is asserted when s_rst_n (only) is asserted. If the UART is
   // configured to have one clock (plck only) then it will assert when
   // new_presetn is asserted, i.e. in this case new_s_rst_n and 
   // new_presetn are identical
   assign int_new_s_rst_n = new_presetn;



endmodule // DW_apb_uart_rst
