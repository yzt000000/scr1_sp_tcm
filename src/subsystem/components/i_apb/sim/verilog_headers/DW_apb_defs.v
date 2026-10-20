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
// Release version :  3.01a
// File Version     :        $Revision: #4 $ 
// Revision: $Id: //dwh/DW_ocb/DW_apb/amba_dev/sim/verilog_header_file/DW_apb_defs.v#4 $ 
--
-- File :                       DW_apb_defs.v
-- Author:                      Peter Gillen
-- Date :                       $DateTime: 2013/04/15 09:30:09 $
--
--
-- Modification History:
-- Date                 By      Version Change  Description
-- =====================================================================
-- See CVS log
-- =====================================================================
*/

//
// Header file for the DW_apb block.
//

//
// APB Slave Address Definitions follow the following naming convention:
// 
// START_PADDR_<slave_number>
// END_PADDR_<slave_number>
//



//
// APB Slave Start and End Addresses
//

`define i_apb_START_PADDR_0 32'h3000
`define i_apb_END_PADDR_0 32'h3fff

`define i_apb_START_PADDR_1 32'h4000
`define i_apb_END_PADDR_1 32'h4fff

`define i_apb_START_PADDR_2 32'hc00
`define i_apb_END_PADDR_2 32'hfff

`define i_apb_START_PADDR_3 32'h1000
`define i_apb_END_PADDR_3 32'h13ff

`define i_apb_START_PADDR_4 32'h1400
`define i_apb_END_PADDR_4 32'h17ff

`define i_apb_START_PADDR_5 32'h1800
`define i_apb_END_PADDR_5 32'h1bff

`define i_apb_START_PADDR_6 32'h1c00
`define i_apb_END_PADDR_6 32'h1fff

`define i_apb_START_PADDR_7 32'h2000
`define i_apb_END_PADDR_7 32'h23ff

`define i_apb_START_PADDR_8 32'h2400
`define i_apb_END_PADDR_8 32'h27ff

`define i_apb_START_PADDR_9 32'h2800
`define i_apb_END_PADDR_9 32'h2bff

`define i_apb_START_PADDR_10 32'h2c00
`define i_apb_END_PADDR_10 32'h2fff

`define i_apb_START_PADDR_11 32'h3000
`define i_apb_END_PADDR_11 32'h33ff

`define i_apb_START_PADDR_12 32'h3400
`define i_apb_END_PADDR_12 32'h37ff

`define i_apb_START_PADDR_13 32'h3800
`define i_apb_END_PADDR_13 32'h3bff

`define i_apb_START_PADDR_14 32'h3c00
`define i_apb_END_PADDR_14 32'h3fff

`define i_apb_START_PADDR_15 32'h4000
`define i_apb_END_PADDR_15 32'h43ff

