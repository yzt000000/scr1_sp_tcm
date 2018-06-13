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
// Release version :  4.01a
// File Version     :        $Revision: #5 $ 
// Revision: $Id: //dwh/DW_ocb/DW_apb_uart/amba_dev/sim/verilog_header_file/DW_apb_uart_defs.v#5 $ 
*/




`define i_uart_DW_APB_UART_BASE 32'h00004000

`define i_uart_UARTReceiveBufferReg_Offset               8'h00
`define i_uart_UARTTransmitHoldingReg_Offset             8'h00
`define i_uart_UARTDivisorLatchLow_Offset                8'h00
`define i_uart_UARTInterruptEnableReg_Offset             8'h04
`define i_uart_UARTDivisorLatchHigh_Offset               8'h04
`define i_uart_UARTInterruptIdentificationReg_Offset     8'h08
`define i_uart_UARTFIFOControlReg_Offset                 8'h08
`define i_uart_UARTLineControlReg_Offset                 8'h0C
`define i_uart_UARTModemControlReg_Offset                8'h10
`define i_uart_UARTLineStatusReg_Offset                  8'h14
`define i_uart_UARTModemStatusReg_Offset                 8'h18

`define i_uart_UARTScratchpadReg_Offset                  8'h1C

`define i_uart_UARTLowPowerDivisorLatchLow_Offset        8'h20

`define i_uart_UARTLowPowerDivisorLatchHigh_Offset       8'h24

`define i_uart_UARTShadowReceiveBufferRegLow_Offset      8'h30

`define i_uart_UARTShadowReceiveBufferRegHigh_Offset     8'h6C

`define i_uart_UARTShadowTransmitHoldingRegLow_Offset    8'h30

`define i_uart_UARTShadowTransmitHoldingRegHigh_Offset   8'h6C

`define i_uart_UARTFIFOAccessReg_Offset                  8'h70

`define i_uart_UARTTransmitFIFOReadReg_Offset            8'h74

`define i_uart_UARTReceiveFIFOWriteReg_Offset            8'h78

`define i_uart_UARTUARTStatusReg_Offset                  8'h7C

`define i_uart_UARTTransmitFIFOLevelReg_Offset           8'h80

`define i_uart_UARTReceiveFIFOLevelReg_Offset            8'h84

`define i_uart_UARTSoftwareResetReg_Offset               8'h88

`define i_uart_UARTShadowRequestToSendReg_Offset         8'h8C

`define i_uart_UARTShadowBreakControlReg_Offset          8'h90

`define i_uart_UARTShadowDMAModeReg_Offset               8'h94

`define i_uart_UARTShadowFIFOEnableReg_Offset            8'h98

`define i_uart_UARTShadowRCVRTriggerReg_Offset           8'h9C

`define i_uart_UARTShadowTXEmptyTriggerReg_Offset        8'hA0

`define i_uart_UARTHaltTXReg_Offset                      8'hA4

`define i_uart_UARTDMASAReg_Offset                       8'hA8

`define i_uart_UARTCIDReg_Offset                         8'hF4

`define i_uart_UARTCVReg_Offset                          8'hF8

`define i_uart_UARTPIDReg_Offset                         8'hFC

`define i_uart_UARTReceiveBufferReg             (`i_uart_DW_APB_UART_BASE + `i_uart_UARTReceiveBufferReg_Offset            )
`define i_uart_UARTTransmitHoldingReg           (`i_uart_DW_APB_UART_BASE + `i_uart_UARTTransmitHoldingReg_Offset          )
`define i_uart_UARTDivisorLatchLow              (`i_uart_DW_APB_UART_BASE + `i_uart_UARTDivisorLatchLow_Offset             )
`define i_uart_UARTInterruptEnableReg           (`i_uart_DW_APB_UART_BASE + `i_uart_UARTInterruptEnableReg_Offset          )
`define i_uart_UARTDivisorLatchHigh             (`i_uart_DW_APB_UART_BASE + `i_uart_UARTDivisorLatchHigh_Offset            )
`define i_uart_UARTInterruptIdentificationReg   (`i_uart_DW_APB_UART_BASE + `i_uart_UARTInterruptIdentificationReg_Offset  )
`define i_uart_UARTFIFOControlReg               (`i_uart_DW_APB_UART_BASE + `i_uart_UARTFIFOControlReg_Offset              )
`define i_uart_UARTLineControlReg               (`i_uart_DW_APB_UART_BASE + `i_uart_UARTLineControlReg_Offset              )
`define i_uart_UARTModemControlReg              (`i_uart_DW_APB_UART_BASE + `i_uart_UARTModemControlReg_Offset             )
`define i_uart_UARTLineStatusReg                (`i_uart_DW_APB_UART_BASE + `i_uart_UARTLineStatusReg_Offset               )
`define i_uart_UARTModemStatusReg               (`i_uart_DW_APB_UART_BASE + `i_uart_UARTModemStatusReg_Offset              )
`define i_uart_UARTScratchpadReg                (`i_uart_DW_APB_UART_BASE + `i_uart_UARTScratchpadReg_Offset               )
`define i_uart_UARTLowPowerDivisorLatchLowReg   (`i_uart_DW_APB_UART_BASE + `i_uart_UARTLowPowerDivisorLatchLow_Offset     )
`define i_uart_UARTLowPowerDivisorLatchHighReg  (`i_uart_DW_APB_UART_BASE + `i_uart_UARTLowPowerDivisorLatchHigh_Offset    )
`define i_uart_UARTShadowReceiveBufferRegLow    (`i_uart_DW_APB_UART_BASE + `i_uart_UARTShadowReceiveBufferRegLow_Offset   )
`define i_uart_UARTShadowReceiveBufferRegHigh   (`i_uart_DW_APB_UART_BASE + `i_uart_UARTShadowReceiveBufferRegHigh_Offset  )
`define i_uart_UARTShadowTransmitHoldingRegLow  (`i_uart_DW_APB_UART_BASE + `i_uart_UARTShadowTransmitHoldingRegLow_Offset )
`define i_uart_UARTShadowTransmitHoldingRegHigh (`i_uart_DW_APB_UART_BASE + `i_uart_UARTShadowTransmitHoldingRegHigh_Offset)
`define i_uart_UARTFIFOAccessReg                (`i_uart_DW_APB_UART_BASE + `i_uart_UARTFIFOAccessReg_Offset               )
`define i_uart_UARTTransmitFIFOReadReg          (`i_uart_DW_APB_UART_BASE + `i_uart_UARTTransmitFIFOReadReg_Offset         )
`define i_uart_UARTReceiveFIFOWriteReg          (`i_uart_DW_APB_UART_BASE + `i_uart_UARTReceiveFIFOWriteReg_Offset         )
`define i_uart_UARTUARTStatusReg                (`i_uart_DW_APB_UART_BASE + `i_uart_UARTUARTStatusReg_Offset               )
`define i_uart_UARTTransmitFIFOLevelReg         (`i_uart_DW_APB_UART_BASE + `i_uart_UARTTransmitFIFOLevelReg_Offset        )
`define i_uart_UARTReceiveFIFOLevelReg          (`i_uart_DW_APB_UART_BASE + `i_uart_UARTReceiveFIFOLevelReg_Offset         )
`define i_uart_UARTSoftwareResetReg             (`i_uart_DW_APB_UART_BASE + `i_uart_UARTSoftwareResetReg_Offset            )
`define i_uart_UARTShadowRequestToSendReg       (`i_uart_DW_APB_UART_BASE + `i_uart_UARTShadowRequestToSendReg_Offset      )
`define i_uart_UARTShadowBreakControlReg        (`i_uart_DW_APB_UART_BASE + `i_uart_UARTShadowBreakControlReg_Offset       )
`define i_uart_UARTShadowDMAModeReg             (`i_uart_DW_APB_UART_BASE + `i_uart_UARTShadowDMAModeReg_Offset            )
`define i_uart_UARTShadowFIFOEnableReg          (`i_uart_DW_APB_UART_BASE + `i_uart_UARTShadowFIFOEnableReg_Offset         )
`define i_uart_UARTShadowRCVRTriggerReg         (`i_uart_DW_APB_UART_BASE + `i_uart_UARTShadowRCVRTriggerReg_Offset        )
`define i_uart_UARTShadowTXEmptyTriggerReg      (`i_uart_DW_APB_UART_BASE + `i_uart_UARTShadowTXEmptyTriggerReg_Offset     )
`define i_uart_UARTHaltTXReg                    (`i_uart_DW_APB_UART_BASE + `i_uart_UARTHaltTXReg_Offset                   )
`define i_uart_UARTDMASAReg                     (`i_uart_DW_APB_UART_BASE + `i_uart_UARTDMASAReg_Offset                    )
`define i_uart_UARTCIDReg                       (`i_uart_DW_APB_UART_BASE + `i_uart_UARTCIDReg_Offset                      )
`define i_uart_UARTCVReg                        (`i_uart_DW_APB_UART_BASE + `i_uart_UARTCVReg_Offset                       )
`define i_uart_UARTPIDReg                       (`i_uart_DW_APB_UART_BASE + `i_uart_UARTPIDReg_Offset                      )

`define i_uart_UART_RBR             	       (`i_uart_DW_APB_UART_BASE + `i_uart_UARTReceiveBufferReg_Offset            )
`define i_uart_UART_THR             	       (`i_uart_DW_APB_UART_BASE + `i_uart_UARTTransmitHoldingReg_Offset          )
`define i_uart_UART_DLL             	       (`i_uart_DW_APB_UART_BASE + `i_uart_UARTDivisorLatchLow_Offset             )
`define i_uart_UART_IER             	       (`i_uart_DW_APB_UART_BASE + `i_uart_UARTInterruptEnableReg_Offset          )
`define i_uart_UART_DLH             	       (`i_uart_DW_APB_UART_BASE + `i_uart_UARTDivisorLatchHigh_Offset            )
`define i_uart_UART_IIR             	       (`i_uart_DW_APB_UART_BASE + `i_uart_UARTInterruptIdentificationReg_Offset  )
`define i_uart_UART_FCR             	       (`i_uart_DW_APB_UART_BASE + `i_uart_UARTFIFOControlReg_Offset              )
`define i_uart_UART_LCR             	       (`i_uart_DW_APB_UART_BASE + `i_uart_UARTLineControlReg_Offset              )
`define i_uart_UART_MCR             	       (`i_uart_DW_APB_UART_BASE + `i_uart_UARTModemControlReg_Offset             )
`define i_uart_UART_LSR             	       (`i_uart_DW_APB_UART_BASE + `i_uart_UARTLineStatusReg_Offset               )
`define i_uart_UART_MSR             	       (`i_uart_DW_APB_UART_BASE + `i_uart_UARTModemStatusReg_Offset              )
`define i_uart_UART_SCR             	       (`i_uart_DW_APB_UART_BASE + `i_uart_UARTScratchpadReg_Offset               )
`define i_uart_UART_LPDLL           	       (`i_uart_DW_APB_UART_BASE + `i_uart_UARTLowPowerDivisorLatchLow_Offset     )
`define i_uart_UART_LPDLH           	       (`i_uart_DW_APB_UART_BASE + `i_uart_UARTLowPowerDivisorLatchHigh_Offset    )
`define UARTi_uart_PING_1BIT_WR (`i_uart_UART_LCR)

