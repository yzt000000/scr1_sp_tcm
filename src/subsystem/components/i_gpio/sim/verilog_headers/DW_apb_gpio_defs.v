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
// File Version     :        $Revision: #5 $ 
// Revision: $Id: //dwh/DW_ocb/DW_apb_gpio/amba_dev/sim/verilog_header_file/DW_apb_gpio_defs.v#5 $ 
--
-- File :                       DW_apb_gpio_defs.v
-- Author:                      Frank Kavanagh
--
--
-- Modification History:
-- Date                 By      Version Change  Description
-- =====================================================================
-- See CVS log
-- =====================================================================
*/


`define i_gpio_DW_APB_GPIO_BASE 32'h00003000

`define i_gpio_GPIO_SWPORTA_DR_OFFSET    8'h00
`define i_gpio_GPIO_SWPORTA_DDR_OFFSET   8'h04
`define i_gpio_GPIO_SWPORTA_CTL_OFFSET   8'h08
`define i_gpio_GPIO_SWPORTB_DR_OFFSET    8'h0C
`define i_gpio_GPIO_SWPORTB_DDR_OFFSET   8'h10
`define i_gpio_GPIO_SWPORTB_CTL_OFFSET   8'h14
`define i_gpio_GPIO_SWPORTC_DR_OFFSET    8'h18
`define i_gpio_GPIO_SWPORTC_DDR_OFFSET   8'h1C
`define i_gpio_GPIO_SWPORTC_CTL_OFFSET   8'h20
`define i_gpio_GPIO_SWPORTD_DR_OFFSET    8'h24
`define i_gpio_GPIO_SWPORTD_DDR_OFFSET   8'h28
`define i_gpio_GPIO_SWPORTD_CTL_OFFSET   8'h2C
`define i_gpio_GPIO_INTEN_OFFSET         8'h30
`define i_gpio_GPIO_INTMASK_OFFSET       8'h34
`define i_gpio_GPIO_INTTYPE_LEVEL_OFFSET 8'h38
`define i_gpio_GPIO_INT_POLARITY_OFFSET  8'h3C
`define i_gpio_GPIO_INTSTATUS_OFFSET     8'h40
`define i_gpio_GPIO_RAW_INTSTATUS_OFFSET 8'h44
`define i_gpio_GPIO_DEBOUNCE_OFFSET      8'h48
`define i_gpio_GPIO_PORTA_EOI_OFFSET     8'h4C
`define i_gpio_GPIO_EXT_PORTA_OFFSET     8'h50
`define i_gpio_GPIO_EXT_PORTB_OFFSET     8'h54
`define i_gpio_GPIO_EXT_PORTC_OFFSET     8'h58
`define i_gpio_GPIO_EXT_PORTD_OFFSET     8'h5C
`define i_gpio_GPIO_LS_SYNC_OFFSET       8'h60
`define i_gpio_GPIO_ID_CODE_OFFSET       8'h64
`define i_gpio_GPIO_VER_ID_CODE_OFFSET   8'h6C

`define i_gpio_GPIO_CONFIGID_REG2_OFFSET 8'h70

`define i_gpio_GPIO_CONFIGID_REG1_OFFSET 8'h74

`define i_gpio_GPIO_SWPORTA_DR       (`i_gpio_DW_APB_GPIO_BASE  + `i_gpio_GPIO_SWPORTA_DR_OFFSET)
`define i_gpio_GPIO_SWPORTA_DDR      (`i_gpio_DW_APB_GPIO_BASE  + `i_gpio_GPIO_SWPORTA_DDR_OFFSET)
`define i_gpio_GPIO_SWPORTA_CTL      (`i_gpio_DW_APB_GPIO_BASE  + `i_gpio_GPIO_SWPORTA_CTL_OFFSET)
`define i_gpio_GPIO_SWPORTB_DR       (`i_gpio_DW_APB_GPIO_BASE  + `i_gpio_GPIO_SWPORTB_DR_OFFSET)
`define i_gpio_GPIO_SWPORTB_DDR      (`i_gpio_DW_APB_GPIO_BASE  + `i_gpio_GPIO_SWPORTB_DDR_OFFSET)
`define i_gpio_GPIO_SWPORTB_CTL      (`i_gpio_DW_APB_GPIO_BASE  + `i_gpio_GPIO_SWPORTB_CTL_OFFSET)
`define i_gpio_GPIO_SWPORTC_DR       (`i_gpio_DW_APB_GPIO_BASE  + `i_gpio_GPIO_SWPORTC_DR_OFFSET)
`define i_gpio_GPIO_SWPORTC_DDR      (`i_gpio_DW_APB_GPIO_BASE  + `i_gpio_GPIO_SWPORTC_DDR_OFFSET)
`define i_gpio_GPIO_SWPORTC_CTL      (`i_gpio_DW_APB_GPIO_BASE  + `i_gpio_GPIO_SWPORTC_CTL_OFFSET)
`define i_gpio_GPIO_SWPORTD_DR       (`i_gpio_DW_APB_GPIO_BASE  + `i_gpio_GPIO_SWPORTD_DR_OFFSET)
`define i_gpio_GPIO_SWPORTD_DDR      (`i_gpio_DW_APB_GPIO_BASE  + `i_gpio_GPIO_SWPORTD_DDR_OFFSET)
`define i_gpio_GPIO_SWPORTD_CTL      (`i_gpio_DW_APB_GPIO_BASE  + `i_gpio_GPIO_SWPORTD_CTL_OFFSET)
`define i_gpio_GPIO_INTEN            (`i_gpio_DW_APB_GPIO_BASE  + `i_gpio_GPIO_INTEN_OFFSET)
`define i_gpio_GPIO_INTMASK          (`i_gpio_DW_APB_GPIO_BASE  + `i_gpio_GPIO_INTMASK_OFFSET)
`define i_gpio_GPIO_INTTYPE_LEVEL    (`i_gpio_DW_APB_GPIO_BASE  + `i_gpio_GPIO_INTTYPE_LEVEL_OFFSET)
`define i_gpio_GPIO_INT_POLARITY     (`i_gpio_DW_APB_GPIO_BASE  + `i_gpio_GPIO_INT_POLARITY_OFFSET)
`define i_gpio_GPIO_INTSTATUS        (`i_gpio_DW_APB_GPIO_BASE  + `i_gpio_GPIO_INTSTATUS_OFFSET)
`define i_gpio_GPIO_RAW_INTSTATUS    (`i_gpio_DW_APB_GPIO_BASE  + `i_gpio_GPIO_RAW_INTSTATUS_OFFSET)
`define i_gpio_GPIO_DEBOUNCE         (`i_gpio_DW_APB_GPIO_BASE  + `i_gpio_GPIO_DEBOUNCE_OFFSET)
`define i_gpio_GPIO_PORTA_EOI        (`i_gpio_DW_APB_GPIO_BASE  + `i_gpio_GPIO_PORTA_EOI_OFFSET)
`define i_gpio_GPIO_EXT_PORTA        (`i_gpio_DW_APB_GPIO_BASE  + `i_gpio_GPIO_EXT_PORTA_OFFSET)
`define i_gpio_GPIO_EXT_PORTB        (`i_gpio_DW_APB_GPIO_BASE  + `i_gpio_GPIO_EXT_PORTB_OFFSET)
`define i_gpio_GPIO_EXT_PORTC        (`i_gpio_DW_APB_GPIO_BASE  + `i_gpio_GPIO_EXT_PORTC_OFFSET)
`define i_gpio_GPIO_EXT_PORTD        (`i_gpio_DW_APB_GPIO_BASE  + `i_gpio_GPIO_EXT_PORTD_OFFSET)
`define i_gpio_GPIO_LS_SYNC          (`i_gpio_DW_APB_GPIO_BASE  + `i_gpio_GPIO_LS_SYNC_OFFSET)
`define i_gpio_GPIO_ID_CODE          (`i_gpio_DW_APB_GPIO_BASE  + `i_gpio_GPIO_ID_CODE_OFFSET)
`define i_gpio_GPIO_VER_ID_CODE      (`i_gpio_DW_APB_GPIO_BASE  + `i_gpio_GPIO_VER_ID_CODE_OFFSET)

`define i_gpio_GPIO_CONFIGID_REG2    (`i_gpio_DW_APB_GPIO_BASE  + `i_gpio_GPIO_CONFIGID_REG2_OFFSET)

`define i_gpio_GPIO_CONFIGID_REG1    (`i_gpio_DW_APB_GPIO_BASE  + `i_gpio_GPIO_CONFIGID_REG1_OFFSET)

`define GPIOi_gpio_PING_1BIT_WR      (`i_gpio_GPIO_SWPORTA_DR)


