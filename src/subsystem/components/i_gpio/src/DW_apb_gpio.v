/*
------------------------------------------------------------------------
--
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
// Release version :  2.12a
// File Version     :        $Revision: #11 $ 
// Revision: $Id: //dwh/DW_ocb/DW_apb_gpio/amba_dev/src/DW_apb_gpio.v#11 $ 
--
-- File :                       DW_apb_gpio.v
//
//
-- Abstract     :               Top level DW_apb_gpio
--                              This APB Slave is a
--                              General Purpose Input/Output
--                              peripheral
--
//
// Please refer to the databook for full details on the signals.
//
// These are found in the "Signal Description" section of the "Signals" chapter.
// There are details on the following
//   % Input Delays
//   % Output Delays
//   Any False Paths
//   Any Multicycle Paths
//   Any Asynchronous Signals
//
------------------------------------------------------------------------
*/

module i_gpio_DW_apb_gpio(



   pclk,             // APB Clock     
                   pclk_intr,        // APB Clock used in detection
                   // of edge-sensitive interrupts and
                   // in synchronisation of level-sensitive
                   // interrupts.
                   presetn,          // APB Reset signal (active-low)
                   penable,          // APB Enable Control signal
                   pwrite,           // APB Write Control signal
                   pwdata,           // APB Write Data Bus
                   paddr,            // APB Address Bus
                   psel,             // APB Peripheral Select
                   gpio_ext_porta,   // Input data
                   gpio_porta_dr,    // Output Data
                   gpio_porta_ddr,   // Data Direction Control
                   gpio_intr_n,      // Interrupt Status Bus (active low)
                   gpio_intrclk_en,  // Indicates that pclk_intr must be running
                   // to detect interrupts 
                   prdata// APB Read Data Bus
                   
                   ); 
   input                               pclk;
   input                               pclk_intr;
   input                               presetn;
   input                               penable;
   input                               pwrite;
   input  [`APB_DATA_WIDTH-1:0]        pwdata;
// Least significant 2 bits of paddr are not required in code as registers
// are aligned to 32bit address and hence last two bits are always zero.
// Hence, the bits are ignored and non-driving as part of design.
   input  [`GPIO_ADDR_SLICE_LHS:0]     paddr;
   input                               psel;
   input  [`GPIO_PWIDTH_A-1:0]         gpio_ext_porta;

   output [`GPIO_PWIDTH_A-1:0]         gpio_porta_dr;
   output [`GPIO_PWIDTH_A-1:0]         gpio_porta_ddr;
   output                              gpio_intrclk_en;
   output [`GPIO_PWIDTH_A-1:0]         gpio_intr_n;
   output [`APB_DATA_WIDTH-1:0]        prdata;


   wire                             pclk_intr;
   wire [`APB_DATA_WIDTH-1:0]       prdata;
   wire [`GPIO_PWIDTH_A-1:0]        gpio_int_polarity;
   wire [`GPIO_PWIDTH_A-1:0]        gpio_inten;
   wire [`GPIO_PWIDTH_A-1:0]        gpio_intmask;
   wire [`GPIO_PWIDTH_A-1:0]        gpio_inttype_level;
   wire [`GPIO_PWIDTH_A-1:0]        gpio_intstatus;
   wire [`GPIO_PWIDTH_A-1:0]        gpio_raw_intstatus;
   wire [`GPIO_PWIDTH_A-1:0]        gpio_porta_eoi;
   wire                             gpio_ls_sync;
   wire [`GPIO_PWIDTH_A-1:0]        gpio_intr_n;
   wire [`GPIO_PWIDTH_A-1:0]        gpio_swporta_dr;
   wire [`GPIO_PWIDTH_A-1:0]        gpio_swporta_ddr;
   wire [`GPIO_PWIDTH_A-1:0]        gpio_porta_dr;
   wire [`GPIO_PWIDTH_A-1:0]        gpio_porta_ddr;
   wire [`GPIO_PWIDTH_A-1:0]        gpio_ext_porta;
   wire [`GPIO_PWIDTH_A-1:0]        gpio_ext_porta_rb;


 i_gpio_DW_apb_gpio_apbif
  U_apb_gpio_apbif(
  .pclk(pclk),
                                    .presetn(presetn),
                                    .penable(penable),
                                    .pwrite(pwrite),
                                    .pwdata(pwdata),
                                    .paddr(paddr[`GPIO_ADDR_SLICE_LHS:`GPIO_ADDR_SLICE_RHS]),
                                    .psel(psel),
                                    .gpio_swporta_dr(gpio_swporta_dr),
                                    .gpio_swporta_ddr(gpio_swporta_ddr),
                                    .gpio_ext_porta_rb(gpio_ext_porta_rb),
                                    .gpio_inten(gpio_inten),
                                    .gpio_intmask(gpio_intmask),
                                    .gpio_inttype_level(gpio_inttype_level),
                                    .gpio_intstatus(gpio_intstatus),
                                    .gpio_raw_intstatus(gpio_raw_intstatus),
                                    .gpio_porta_eoi(gpio_porta_eoi),
                                    .gpio_ls_sync(gpio_ls_sync),
                                    .gpio_int_polarity(gpio_int_polarity),
                                    .prdata(prdata)
                                    );



i_gpio_DW_apb_gpio_ctrl
 U_apb_gpio_ctrl  (
                                   .pclk(pclk),
                                   .presetn(presetn),
                                   .pclk_intr(pclk_intr),
                                   .gpio_inten(gpio_inten),
                                   .gpio_intmask(gpio_intmask),
                                   .gpio_inttype_level(gpio_inttype_level),
                                   .gpio_porta_eoi(gpio_porta_eoi),
                                   .gpio_ls_sync(gpio_ls_sync),
                                   .gpio_intr_n(gpio_intr_n),
                                   .gpio_intr_int(gpio_intstatus),
                                   .gpio_raw_intstatus(gpio_raw_intstatus),
                                   .gpio_intrclk_en(gpio_intrclk_en),
                                   .gpio_int_polarity(gpio_int_polarity),
                                   .gpio_swporta_dr(gpio_swporta_dr),
                                   .gpio_swporta_ddr(gpio_swporta_ddr),
                                   .gpio_porta_dr(gpio_porta_dr),
                                   .gpio_porta_ddr(gpio_porta_ddr),
                                   .gpio_ext_porta(gpio_ext_porta),
                                   .gpio_ext_porta_rb(gpio_ext_porta_rb)
                                   );




endmodule
