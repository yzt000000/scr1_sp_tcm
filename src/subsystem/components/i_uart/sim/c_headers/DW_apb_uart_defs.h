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

// Revision: $Id: //dwh/DW_ocb/DW_apb_uart/amba_dev/sim/c_header_file/DW_apb_uart_defs.h#5 $


#define i_uart_DW_APB_UART_BASE 0x00004000

#define i_uart_UARTReceiveBufferReg_Offset               0x00
#define i_uart_UARTTransmitHoldingReg_Offset             0x00
#define i_uart_UARTDivisorLatchLow_Offset                0x00
#define i_uart_UARTInterruptEnableReg_Offset             0x04
#define i_uart_UARTDivisorLatchHigh_Offset               0x04
#define i_uart_UARTInterruptIdentificationReg_Offset     0x08
#define i_uart_UARTFIFOControlReg_Offset                 0x08
#define i_uart_UARTLineControlReg_Offset                 0x0C
#define i_uart_UARTModemControlReg_Offset                0x10
#define i_uart_UARTLineStatusReg_Offset                  0x14
#define i_uart_UARTModemStatusReg_Offset                 0x18

#define i_uart_UARTScratchpadReg_Offset                  0x1C

#define i_uart_UARTLowPowerDivisorLatchLow_Offset        0x20

#define i_uart_UARTLowPowerDivisorLatchHigh_Offset       0x24

#define i_uart_UARTShadowReceiveBufferRegLow_Offset      0x30

#define i_uart_UARTShadowReceiveBufferRegHigh_Offset     0x6C

#define i_uart_UARTShadowTransmitHoldingRegLow_Offset    0x30

#define i_uart_UARTShadowTransmitHoldingRegHigh_Offset   0x6C

#define i_uart_UARTFIFOAccessReg_Offset                  0x70

#define i_uart_UARTTransmitFIFOReadReg_Offset            0x74

#define i_uart_UARTReceiveFIFOWriteReg_Offset            0x78

#define i_uart_UARTUARTStatusReg_Offset                  0x7C

#define i_uart_UARTTransmitFIFOLevelReg_Offset           0x80

#define i_uart_UARTReceiveFIFOLevelReg_Offset            0x84

#define i_uart_UARTSoftwareResetReg_Offset               0x88

#define i_uart_UARTShadowRequestToSendReg_Offset         0x8C

#define i_uart_UARTShadowBreakControlReg_Offset          0x90

#define i_uart_UARTShadowDMAModeReg_Offset               0x94

#define i_uart_UARTShadowFIFOEnableReg_Offset            0x98

#define i_uart_UARTShadowRCVRTriggerReg_Offset           0x9C

#define i_uart_UARTShadowTXEmptyTriggerReg_Offset        0xA0

#define i_uart_UARTHaltTXReg_Offset                      0xA4

#define i_uart_UARTDMASAReg_Offset                       0xA8

#define i_uart_UARTCIDReg_Offset                         0xF4

#define i_uart_UARTCVReg_Offset                          0xF8

#define i_uart_UARTPIDReg_Offset                         0xFC

#define i_uart_UARTReceiveBufferReg             (i_uart_DW_APB_UART_BASE + i_uart_UARTReceiveBufferReg_Offset            )
#define i_uart_UARTTransmitHoldingReg           (i_uart_DW_APB_UART_BASE + i_uart_UARTTransmitHoldingReg_Offset          )
#define i_uart_UARTDivisorLatchLow              (i_uart_DW_APB_UART_BASE + i_uart_UARTDivisorLatchLow_Offset             )
#define i_uart_UARTInterruptEnableReg           (i_uart_DW_APB_UART_BASE + i_uart_UARTInterruptEnableReg_Offset          )
#define i_uart_UARTDivisorLatchHigh             (i_uart_DW_APB_UART_BASE + i_uart_UARTDivisorLatchHigh_Offset            )
#define i_uart_UARTInterruptIdentificationReg   (i_uart_DW_APB_UART_BASE + i_uart_UARTInterruptIdentificationReg_Offset  )
#define i_uart_UARTFIFOControlReg               (i_uart_DW_APB_UART_BASE + i_uart_UARTFIFOControlReg_Offset              )
#define i_uart_UARTLineControlReg               (i_uart_DW_APB_UART_BASE + i_uart_UARTLineControlReg_Offset              )
#define i_uart_UARTModemControlReg              (i_uart_DW_APB_UART_BASE + i_uart_UARTModemControlReg_Offset             )
#define i_uart_UARTLineStatusReg                (i_uart_DW_APB_UART_BASE + i_uart_UARTLineStatusReg_Offset               )
#define i_uart_UARTModemStatusReg               (i_uart_DW_APB_UART_BASE + i_uart_UARTModemStatusReg_Offset              )
#define i_uart_UARTScratchpadReg                (i_uart_DW_APB_UART_BASE + i_uart_UARTScratchpadReg_Offset               )
#define i_uart_UARTLowPowerDivisorLatchLowReg   (i_uart_DW_APB_UART_BASE + i_uart_UARTLowPowerDivisorLatchLow_Offset     )
#define i_uart_UARTLowPowerDivisorLatchHighReg  (i_uart_DW_APB_UART_BASE + i_uart_UARTLowPowerDivisorLatchHigh_Offset    )
#define i_uart_UARTShadowReceiveBufferRegLow    (i_uart_DW_APB_UART_BASE + i_uart_UARTShadowReceiveBufferRegLow_Offset   )
#define i_uart_UARTShadowReceiveBufferRegHigh   (i_uart_DW_APB_UART_BASE + i_uart_UARTShadowReceiveBufferRegHigh_Offset  )
#define i_uart_UARTShadowTransmitHoldingRegLow  (i_uart_DW_APB_UART_BASE + i_uart_UARTShadowTransmitHoldingRegLow_Offset )
#define i_uart_UARTShadowTransmitHoldingRegHigh (i_uart_DW_APB_UART_BASE + i_uart_UARTShadowTransmitHoldingRegHigh_Offset)
#define i_uart_UARTFIFOAccessReg                (i_uart_DW_APB_UART_BASE + i_uart_UARTFIFOAccessReg_Offset               )
#define i_uart_UARTTransmitFIFOReadReg          (i_uart_DW_APB_UART_BASE + i_uart_UARTTransmitFIFOReadReg_Offset         )
#define i_uart_UARTReceiveFIFOWriteReg          (i_uart_DW_APB_UART_BASE + i_uart_UARTReceiveFIFOWriteReg_Offset         )
#define i_uart_UARTUARTStatusReg                (i_uart_DW_APB_UART_BASE + i_uart_UARTUARTStatusReg_Offset               )
#define i_uart_UARTTransmitFIFOLevelReg         (i_uart_DW_APB_UART_BASE + i_uart_UARTTransmitFIFOLevelReg_Offset        )
#define i_uart_UARTReceiveFIFOLevelReg          (i_uart_DW_APB_UART_BASE + i_uart_UARTReceiveFIFOLevelReg_Offset         )
#define i_uart_UARTSoftwareResetReg             (i_uart_DW_APB_UART_BASE + i_uart_UARTSoftwareResetReg_Offset            )
#define i_uart_UARTShadowRequestToSendReg       (i_uart_DW_APB_UART_BASE + i_uart_UARTShadowRequestToSendReg_Offset      )
#define i_uart_UARTShadowBreakControlReg        (i_uart_DW_APB_UART_BASE + i_uart_UARTShadowBreakControlReg_Offset       )
#define i_uart_UARTShadowDMAModeReg             (i_uart_DW_APB_UART_BASE + i_uart_UARTShadowDMAModeReg_Offset            )
#define i_uart_UARTShadowFIFOEnableReg          (i_uart_DW_APB_UART_BASE + i_uart_UARTShadowFIFOEnableReg_Offset         )
#define i_uart_UARTShadowRCVRTriggerReg         (i_uart_DW_APB_UART_BASE + i_uart_UARTShadowRCVRTriggerReg_Offset        )
#define i_uart_UARTShadowTXEmptyTriggerReg      (i_uart_DW_APB_UART_BASE + i_uart_UARTShadowTXEmptyTriggerReg_Offset     )
#define i_uart_UARTHaltTXReg                    (i_uart_DW_APB_UART_BASE + i_uart_UARTHaltTXReg_Offset                   )
#define i_uart_UARTDMASAReg                     (i_uart_DW_APB_UART_BASE + i_uart_UARTDMASAReg_Offset                    )
#define i_uart_UARTCIDReg                       (i_uart_DW_APB_UART_BASE + i_uart_UARTCIDReg_Offset                      )
#define i_uart_UARTCVReg                        (i_uart_DW_APB_UART_BASE + i_uart_UARTCVReg_Offset                       )
#define i_uart_UARTPIDReg                       (i_uart_DW_APB_UART_BASE + i_uart_UARTPIDReg_Offset                      )

#define i_uart_UART_RBR             	       (i_uart_DW_APB_UART_BASE + i_uart_UARTReceiveBufferReg_Offset            )
#define i_uart_UART_THR             	       (i_uart_DW_APB_UART_BASE + i_uart_UARTTransmitHoldingReg_Offset          )
#define i_uart_UART_DLL             	       (i_uart_DW_APB_UART_BASE + i_uart_UARTDivisorLatchLow_Offset             )
#define i_uart_UART_IER             	       (i_uart_DW_APB_UART_BASE + i_uart_UARTInterruptEnableReg_Offset          )
#define i_uart_UART_DLH             	       (i_uart_DW_APB_UART_BASE + i_uart_UARTDivisorLatchHigh_Offset            )
#define i_uart_UART_IIR             	       (i_uart_DW_APB_UART_BASE + i_uart_UARTInterruptIdentificationReg_Offset  )
#define i_uart_UART_FCR             	       (i_uart_DW_APB_UART_BASE + i_uart_UARTFIFOControlReg_Offset              )
#define i_uart_UART_LCR             	       (i_uart_DW_APB_UART_BASE + i_uart_UARTLineControlReg_Offset              )
#define i_uart_UART_MCR             	       (i_uart_DW_APB_UART_BASE + i_uart_UARTModemControlReg_Offset             )
#define i_uart_UART_LSR             	       (i_uart_DW_APB_UART_BASE + i_uart_UARTLineStatusReg_Offset               )
#define i_uart_UART_MSR             	       (i_uart_DW_APB_UART_BASE + i_uart_UARTModemStatusReg_Offset              )
#define i_uart_UART_SCR             	       (i_uart_DW_APB_UART_BASE + i_uart_UARTScratchpadReg_Offset               )
#define i_uart_UART_LPDLL           	       (i_uart_DW_APB_UART_BASE + i_uart_UARTLowPowerDivisorLatchLow_Offset     )
#define i_uart_UART_LPDLH           	       (i_uart_DW_APB_UART_BASE + i_uart_UARTLowPowerDivisorLatchHigh_Offset    )
#define UARTi_uart_PING_1BIT_WR (i_uart_UART_LCR)
#define i_uart_CC_UART_APB_DATA_WIDTH        32
#define i_uart_CC_UART_MAX_APB_DATA_WIDTH    32
#define i_uart_CC_UART_FIFO_MODE             16
#define i_uart_CC_UART_MEM_SELECT            1
#define i_uart_CC_UART_MEM_MODE              0
#define i_uart_CC_UART_CLOCK_MODE            1
#define i_uart_CC_UART_AFCE_MODE             0x0
#define i_uart_CC_UART_THRE_MODE             0x0
#define i_uart_CC_UART_SIR_MODE              0x0
#define i_uart_CC_UART_CLK_GATE_EN           0
#define i_uart_CC_UART_FIFO_ACCESS           0x0
#define i_uart_CC_UART_DMA_EXTRA             0x0
#define i_uart_CC_UART_DMA_POL               0
#define i_uart_CC_UART_SIR_LP_MODE           0x0
#define i_uart_CC_UART_DEBUG                 0
#define i_uart_CC_UART_BAUD_CLK              0
#define i_uart_CC_UART_ADDITIONAL_FEATURES   0x0
#define i_uart_CC_UART_FIFO_STAT             0x0
#define i_uart_CC_UART_SHADOW                0x0
#define i_uart_CC_UART_ADD_ENCODED_PARAMS    0x0
#define i_uart_CC_UART_LATCH_MODE            0
#define i_uart_CC_UART_ADDR_SLICE_LHS        8
#define i_uart_CC_UART_COMP_VERSION          0x3430312a

