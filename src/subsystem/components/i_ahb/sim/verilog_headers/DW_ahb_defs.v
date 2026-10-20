/*
 ------------------------------------------------------------------------
--
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
// Release version :  2.13a
// File Version     :        $Revision: #4 $ 
// Revision: $Id: //dwh/DW_ocb/DW_ahb/amba_dev/sim/verilog_header_file/DW_ahb_defs.v#4 $ 
*/

//
// Header file for the DW_ahb block.
//

`define i_ahb_AHB_VERSION_ID         32'h3231332a

`define i_ahb_AHB_PL1_OFFSET         8'h00
`define i_ahb_AHB_PL2_OFFSET         8'h04
`define i_ahb_AHB_PL3_OFFSET         8'h08
`define i_ahb_AHB_PL4_OFFSET         8'h0c
`define i_ahb_AHB_PL5_OFFSET         8'h10
`define i_ahb_AHB_PL6_OFFSET         8'h14
`define i_ahb_AHB_PL7_OFFSET         8'h18
`define i_ahb_AHB_PL8_OFFSET         8'h1c
`define i_ahb_AHB_PL9_OFFSET         8'h20
`define i_ahb_AHB_PL10_OFFSET        8'h24
`define i_ahb_AHB_PL11_OFFSET        8'h28
`define i_ahb_AHB_PL12_OFFSET        8'h2c
`define i_ahb_AHB_PL13_OFFSET        8'h30
`define i_ahb_AHB_PL14_OFFSET        8'h34
`define i_ahb_AHB_PL15_OFFSET        8'h38
`define i_ahb_AHB_EBTCOUNT_OFFSET    8'h3c
`define i_ahb_AHB_EBT_EN_OFFSET      8'h40
`define i_ahb_AHB_EBT_OFFSET         8'h44
`define i_ahb_AHB_DFLT_MASTER_OFFSET 8'h48
`define i_ahb_AHB_WTEN_OFFSET        8'h4c
`define i_ahb_AHB_TCL_OFFSET         8'h50
`define i_ahb_AHB_CCLM1_OFFSET       8'h54
`define i_ahb_AHB_CCLM2_OFFSET       8'h58
`define i_ahb_AHB_CCLM3_OFFSET       8'h5c
`define i_ahb_AHB_CCLM4_OFFSET       8'h60
`define i_ahb_AHB_CCLM5_OFFSET       8'h64
`define i_ahb_AHB_CCLM6_OFFSET       8'h68
`define i_ahb_AHB_CCLM7_OFFSET       8'h6c
`define i_ahb_AHB_CCLM8_OFFSET       8'h70
`define i_ahb_AHB_CCLM9_OFFSET       8'h74
`define i_ahb_AHB_CCLM10_OFFSET      8'h78
`define i_ahb_AHB_CCLM11_OFFSET      8'h7c
`define i_ahb_AHB_CCLM12_OFFSET      8'h80
`define i_ahb_AHB_CCLM13_OFFSET      8'h84
`define i_ahb_AHB_CCLM14_OFFSET      8'h88
`define i_ahb_AHB_CCLM15_OFFSET      8'h8c
`define i_ahb_AHB_VERSION_ID_OFFSET  8'h90

`define i_ahb_DW_AHB_BASE_NORMAL 32'h1000000
`define i_ahb_DW_AHB_BASE_REMAP  32'h26000000

`define i_ahb_AHB_PL1_NORMAL         (`i_ahb_DW_AHB_BASE_NORMAL + `i_ahb_AHB_PL1_OFFSET)
`define i_ahb_AHB_PL2_NORMAL         (`i_ahb_DW_AHB_BASE_NORMAL + `i_ahb_AHB_PL2_OFFSET)
`define i_ahb_AHB_PL3_NORMAL         (`i_ahb_DW_AHB_BASE_NORMAL + `i_ahb_AHB_PL3_OFFSET)
`define i_ahb_AHB_PL4_NORMAL         (`i_ahb_DW_AHB_BASE_NORMAL + `i_ahb_AHB_PL4_OFFSET)
`define i_ahb_AHB_PL5_NORMAL         (`i_ahb_DW_AHB_BASE_NORMAL + `i_ahb_AHB_PL5_OFFSET)
`define i_ahb_AHB_PL6_NORMAL         (`i_ahb_DW_AHB_BASE_NORMAL + `i_ahb_AHB_PL6_OFFSET)
`define i_ahb_AHB_PL7_NORMAL         (`i_ahb_DW_AHB_BASE_NORMAL + `i_ahb_AHB_PL7_OFFSET)
`define i_ahb_AHB_PL8_NORMAL         (`i_ahb_DW_AHB_BASE_NORMAL + `i_ahb_AHB_PL8_OFFSET)
`define i_ahb_AHB_PL9_NORMAL         (`i_ahb_DW_AHB_BASE_NORMAL + `i_ahb_AHB_PL9_OFFSET)
`define i_ahb_AHB_PL10_NORMAL        (`i_ahb_DW_AHB_BASE_NORMAL + `i_ahb_AHB_PL10_OFFSET)
`define i_ahb_AHB_PL11_NORMAL        (`i_ahb_DW_AHB_BASE_NORMAL + `i_ahb_AHB_PL11_OFFSET)
`define i_ahb_AHB_PL12_NORMAL        (`i_ahb_DW_AHB_BASE_NORMAL + `i_ahb_AHB_PL12_OFFSET)
`define i_ahb_AHB_PL13_NORMAL        (`i_ahb_DW_AHB_BASE_NORMAL + `i_ahb_AHB_PL13_OFFSET)
`define i_ahb_AHB_PL14_NORMAL        (`i_ahb_DW_AHB_BASE_NORMAL + `i_ahb_AHB_PL14_OFFSET)
`define i_ahb_AHB_PL15_NORMAL        (`i_ahb_DW_AHB_BASE_NORMAL + `i_ahb_AHB_PL15_OFFSET)
`define i_ahb_AHB_EBTCOUNT_NORMAL    (`i_ahb_DW_AHB_BASE_NORMAL + `i_ahb_AHB_EBTCOUNT_OFFSET)
`define i_ahb_AHB_EBT_EN_NORMAL      (`i_ahb_DW_AHB_BASE_NORMAL + `i_ahb_AHB_EBT_EN_OFFSET)
`define i_ahb_AHB_EBT_NORMAL         (`i_ahb_DW_AHB_BASE_NORMAL + `i_ahb_AHB_EBT_OFFSET)
`define i_ahb_AHB_DFLT_MASTER_NORMAL (`i_ahb_DW_AHB_BASE_NORMAL + `i_ahb_AHB_DFLT_MASTER_OFFSET)
`define i_ahb_AHB_WTEN_NORMAL        (`i_ahb_DW_AHB_BASE_NORMAL + `i_ahb_AHB_WTEN_OFFSET)
`define i_ahb_AHB_TCL_NORMAL         (`i_ahb_DW_AHB_BASE_NORMAL + `i_ahb_AHB_TCL_OFFSET)
`define i_ahb_AHB_CCLM1_NORMAL       (`i_ahb_DW_AHB_BASE_NORMAL + `i_ahb_AHB_CCLM1_OFFSET)
`define i_ahb_AHB_CCLM2_NORMAL       (`i_ahb_DW_AHB_BASE_NORMAL + `i_ahb_AHB_CCLM2_OFFSET)
`define i_ahb_AHB_CCLM3_NORMAL       (`i_ahb_DW_AHB_BASE_NORMAL + `i_ahb_AHB_CCLM3_OFFSET)
`define i_ahb_AHB_CCLM4_NORMAL       (`i_ahb_DW_AHB_BASE_NORMAL + `i_ahb_AHB_CCLM4_OFFSET)
`define i_ahb_AHB_CCLM5_NORMAL       (`i_ahb_DW_AHB_BASE_NORMAL + `i_ahb_AHB_CCLM5_OFFSET)
`define i_ahb_AHB_CCLM6_NORMAL       (`i_ahb_DW_AHB_BASE_NORMAL + `i_ahb_AHB_CCLM6_OFFSET)
`define i_ahb_AHB_CCLM7_NORMAL       (`i_ahb_DW_AHB_BASE_NORMAL + `i_ahb_AHB_CCLM7_OFFSET)
`define i_ahb_AHB_CCLM8_NORMAL       (`i_ahb_DW_AHB_BASE_NORMAL + `i_ahb_AHB_CCLM8_OFFSET)
`define i_ahb_AHB_CCLM9_NORMAL       (`i_ahb_DW_AHB_BASE_NORMAL + `i_ahb_AHB_CCLM9_OFFSET)
`define i_ahb_AHB_CCLM10_NORMAL      (`i_ahb_DW_AHB_BASE_NORMAL + `i_ahb_AHB_CCLM10_OFFSET)
`define i_ahb_AHB_CCLM11_NORMAL      (`i_ahb_DW_AHB_BASE_NORMAL + `i_ahb_AHB_CCLM11_OFFSET)
`define i_ahb_AHB_CCLM12_NORMAL      (`i_ahb_DW_AHB_BASE_NORMAL + `i_ahb_AHB_CCLM12_OFFSET)
`define i_ahb_AHB_CCLM13_NORMAL      (`i_ahb_DW_AHB_BASE_NORMAL + `i_ahb_AHB_CCLM13_OFFSET)
`define i_ahb_AHB_CCLM14_NORMAL      (`i_ahb_DW_AHB_BASE_NORMAL + `i_ahb_AHB_CCLM14_OFFSET)
`define i_ahb_AHB_CCLM15_NORMAL      (`i_ahb_DW_AHB_BASE_NORMAL + `i_ahb_AHB_CCLM15_OFFSET)
`define i_ahb_AHB_VERSION_ID_NORMAL  (`i_ahb_DW_AHB_BASE_NORMAL + `i_ahb_AHB_VERSION_ID_OFFSET)



