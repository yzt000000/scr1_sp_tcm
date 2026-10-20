/*
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

// Revision: $Id: //dwh/DW_ocb/DW_apb_gpio/amba_dev/sim/c_header_file/DW_apb_gpio_defs.h#5 $

*/


#define i_gpio_DW_APB_GPIO_BASE 0x00003000
#define i_gpio_GPIO_SWPORTA_DR_OFFSET    0x00
#define i_gpio_GPIO_SWPORTA_DDR_OFFSET   0x04
#define i_gpio_GPIO_SWPORTA_CTL_OFFSET   0x08
#define i_gpio_GPIO_SWPORTB_DR_OFFSET    0x0C
#define i_gpio_GPIO_SWPORTB_DDR_OFFSET   0x10
#define i_gpio_GPIO_SWPORTB_CTL_OFFSET   0x14
#define i_gpio_GPIO_SWPORTC_DR_OFFSET    0x18
#define i_gpio_GPIO_SWPORTC_DDR_OFFSET   0x1C
#define i_gpio_GPIO_SWPORTC_CTL_OFFSET   0x20
#define i_gpio_GPIO_SWPORTD_DR_OFFSET    0x24
#define i_gpio_GPIO_SWPORTD_DDR_OFFSET   0x28
#define i_gpio_GPIO_SWPORTD_CTL_OFFSET   0x2C
#define i_gpio_GPIO_INTEN_OFFSET         0x30
#define i_gpio_GPIO_INTMASK_OFFSET       0x34
#define i_gpio_GPIO_INTTYPE_LEVEL_OFFSET 0x38
#define i_gpio_GPIO_INT_POLARITY_OFFSET  0x3C
#define i_gpio_GPIO_INTSTATUS_OFFSET     0x40
#define i_gpio_GPIO_RAW_INTSTATUS_OFFSET 0x44
#define i_gpio_GPIO_DEBOUNCE_OFFSET      0x48
#define i_gpio_GPIO_PORTA_EOI_OFFSET     0x4C
#define i_gpio_GPIO_EXT_PORTA_OFFSET     0x50
#define i_gpio_GPIO_EXT_PORTB_OFFSET     0x54
#define i_gpio_GPIO_EXT_PORTC_OFFSET     0x58
#define i_gpio_GPIO_EXT_PORTD_OFFSET     0x5C
#define i_gpio_GPIO_LS_SYNC_OFFSET       0x60
#define i_gpio_GPIO_ID_CODE_OFFSET       0x64
#define i_gpio_GPIO_VER_ID_CODE_OFFSET   0x6C

#define i_gpio_GPIO_CONFIGID_REG2_OFFSET 0x70

#define i_gpio_GPIO_CONFIGID_REG1_OFFSET 0x74

#define i_gpio_GPIO_SWPORTA_DR       (i_gpio_DW_APB_GPIO_BASE  + i_gpio_GPIO_SWPORTA_DR_OFFSET)
#define i_gpio_GPIO_SWPORTA_DDR      (i_gpio_DW_APB_GPIO_BASE  + i_gpio_GPIO_SWPORTA_DDR_OFFSET)
#define i_gpio_GPIO_SWPORTA_CTL      (i_gpio_DW_APB_GPIO_BASE  + i_gpio_GPIO_SWPORTA_CTL_OFFSET)
#define i_gpio_GPIO_SWPORTB_DR       (i_gpio_DW_APB_GPIO_BASE  + i_gpio_GPIO_SWPORTB_DR_OFFSET)
#define i_gpio_GPIO_SWPORTB_DDR      (i_gpio_DW_APB_GPIO_BASE  + i_gpio_GPIO_SWPORTB_DDR_OFFSET)
#define i_gpio_GPIO_SWPORTB_CTL      (i_gpio_DW_APB_GPIO_BASE  + i_gpio_GPIO_SWPORTB_CTL_OFFSET)
#define i_gpio_GPIO_SWPORTC_DR       (i_gpio_DW_APB_GPIO_BASE  + i_gpio_GPIO_SWPORTC_DR_OFFSET)
#define i_gpio_GPIO_SWPORTC_DDR      (i_gpio_DW_APB_GPIO_BASE  + i_gpio_GPIO_SWPORTC_DDR_OFFSET)
#define i_gpio_GPIO_SWPORTC_CTL      (i_gpio_DW_APB_GPIO_BASE  + i_gpio_GPIO_SWPORTC_CTL_OFFSET)
#define i_gpio_GPIO_SWPORTD_DR       (i_gpio_DW_APB_GPIO_BASE  + i_gpio_GPIO_SWPORTD_DR_OFFSET)
#define i_gpio_GPIO_SWPORTD_DDR      (i_gpio_DW_APB_GPIO_BASE  + i_gpio_GPIO_SWPORTD_DDR_OFFSET)
#define i_gpio_GPIO_SWPORTD_CTL      (i_gpio_DW_APB_GPIO_BASE  + i_gpio_GPIO_SWPORTD_CTL_OFFSET)
#define i_gpio_GPIO_INTEN            (i_gpio_DW_APB_GPIO_BASE  + i_gpio_GPIO_INTEN_OFFSET)
#define i_gpio_GPIO_INTMASK          (i_gpio_DW_APB_GPIO_BASE  + i_gpio_GPIO_INTMASK_OFFSET)
#define i_gpio_GPIO_INTTYPE_LEVEL    (i_gpio_DW_APB_GPIO_BASE  + i_gpio_GPIO_INTTYPE_LEVEL_OFFSET)
#define i_gpio_GPIO_INT_POLARITY     (i_gpio_DW_APB_GPIO_BASE  + i_gpio_GPIO_INT_POLARITY_OFFSET)
#define i_gpio_GPIO_INTSTATUS        (i_gpio_DW_APB_GPIO_BASE  + i_gpio_GPIO_INTSTATUS_OFFSET)
#define i_gpio_GPIO_RAW_INTSTATUS    (i_gpio_DW_APB_GPIO_BASE  + i_gpio_GPIO_RAW_INTSTATUS_OFFSET)
#define i_gpio_GPIO_DEBOUNCE         (i_gpio_DW_APB_GPIO_BASE  + i_gpio_GPIO_DEBOUNCE_OFFSET)
#define i_gpio_GPIO_PORTA_EOI        (i_gpio_DW_APB_GPIO_BASE  + i_gpio_GPIO_PORTA_EOI_OFFSET)
#define i_gpio_GPIO_EXT_PORTA        (i_gpio_DW_APB_GPIO_BASE  + i_gpio_GPIO_EXT_PORTA_OFFSET)
#define i_gpio_GPIO_EXT_PORTB        (i_gpio_DW_APB_GPIO_BASE  + i_gpio_GPIO_EXT_PORTB_OFFSET)
#define i_gpio_GPIO_EXT_PORTC        (i_gpio_DW_APB_GPIO_BASE  + i_gpio_GPIO_EXT_PORTC_OFFSET)
#define i_gpio_GPIO_EXT_PORTD        (i_gpio_DW_APB_GPIO_BASE  + i_gpio_GPIO_EXT_PORTD_OFFSET)
#define i_gpio_GPIO_LS_SYNC          (i_gpio_DW_APB_GPIO_BASE  + i_gpio_GPIO_LS_SYNC_OFFSET)
#define i_gpio_GPIO_ID_CODE          (i_gpio_DW_APB_GPIO_BASE  + i_gpio_GPIO_ID_CODE_OFFSET)
#define i_gpio_GPIO_VER_ID_CODE      (i_gpio_DW_APB_GPIO_BASE  + i_gpio_GPIO_VER_ID_CODE_OFFSET)

#define i_gpio_GPIO_CONFIGID_REG2    (i_gpio_DW_APB_GPIO_BASE  + i_gpio_GPIO_CONFIGID_REG2_OFFSET)

#define i_gpio_GPIO_CONFIGID_REG1    (i_gpio_DW_APB_GPIO_BASE  + i_gpio_GPIO_CONFIGID_REG1_OFFSET)

#define GPIOi_gpio_PING_1BIT_WR      (i_gpio_GPIO_SWPORTA_DR)

#define i_gpio_CC_GPIO_ADD_ENCODED_PARAM            0x1
#define i_gpio_CC_GPIO_APB_DATA_WIDTH               32
#define i_gpio_CC_GPIO_NUM_PORTS                    1
#define i_gpio_CC_GPIO_ID                           0x1
#define i_gpio_CC_GPIO_DEBOUNCE                     0x0
#define i_gpio_CC_GPIO_ID_WIDTH                     32
#define i_gpio_CC_GPIO_ID_NUM                       0x0
#define i_gpio_CC_GPIO_REV_ID                       0
#define i_gpio_CC_GPIO_REV_ID_WIDTH                 32
#define i_gpio_CC_GPIO_REV_ID_NUM                   0x0
#define i_gpio_CC_GPIO_PWIDTH_A                     8
#define i_gpio_CC_GPIO_PORTA_SINGLE_CTL             0x1
#define i_gpio_CC_GPIO_SWPORTA_RESET                0x0
#define i_gpio_CC_GPIO_HW_PORTA                     0x0
#define i_gpio_CC_GPIO_DFLT_DIR_A                   0
#define i_gpio_CC_GPIO_DFLT_SRC_A                   0
#define i_gpio_CC_GPIO_PORTA_INTR                   0x1
#define i_gpio_CC_GPIO_INT_POL                      0
#define i_gpio_CC_GPIO_INTR_IO                      0
#define i_gpio_CC_GPIO_PA_SYNC_EXT_DATA             0
#define i_gpio_CC_GPIO_PA_SYNC_INTERRUPTS           1
#define i_gpio_CC_GPIO_PWIDTH_B                     8
#define i_gpio_CC_GPIO_PORTB_SINGLE_CTL             0x1
#define i_gpio_CC_GPIO_SWPORTB_RESET                0x0
#define i_gpio_CC_GPIO_HW_PORTB                     0x0
#define i_gpio_CC_GPIO_DFLT_DIR_B                   0
#define i_gpio_CC_GPIO_DFLT_SRC_B                   0
#define i_gpio_CC_GPIO_PB_SYNC_EXT_DATA             0
#define i_gpio_CC_GPIO_PWIDTH_C                     8
#define i_gpio_CC_GPIO_PORTC_SINGLE_CTL             0x1
#define i_gpio_CC_GPIO_SWPORTC_RESET                0x0
#define i_gpio_CC_GPIO_HW_PORTC                     0x0
#define i_gpio_CC_GPIO_DFLT_DIR_C                   0
#define i_gpio_CC_GPIO_DFLT_SRC_C                   0
#define i_gpio_CC_GPIO_PC_SYNC_EXT_DATA             0
#define i_gpio_CC_GPIO_PWIDTH_D                     8
#define i_gpio_CC_GPIO_PORTD_SINGLE_CTL             0x1
#define i_gpio_CC_GPIO_SWPORTD_RESET                0x0
#define i_gpio_CC_GPIO_HW_PORTD                     0x0
#define i_gpio_CC_GPIO_DFLT_DIR_D                   0
#define i_gpio_CC_GPIO_DFLT_SRC_D                   0
#define i_gpio_CC_GPIO_PD_SYNC_EXT_DATA             0


