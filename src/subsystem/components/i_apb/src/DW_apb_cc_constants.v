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
// File Version     :        $Revision: #21 $ 
// Revision: $Id: //dwh/DW_ocb/DW_apb/amba_dev/src/DW_apb_cc_constants.v#21 $ 
--
-- File :                       DW_apb_cc_constants.v
-- Author:                      Chris Gilbert
-- Date :                       $Date: 2016/08/26 $
-- Abstract     :               This module contains definitions that
--                              are configured by coreConsultant
--
-- Modification History:        Refer to CVS log
-- =====================================================================
*/


// Name:         HADDR_WIDTH
// Default:      32
// Values:       32 64
// 
// The address width of the AHB system.
`define HADDR_WIDTH 32


// Name:         PADDR_WIDTH
// Default:      32
// Values:       32 64
// 
// The address width of the APB system.
`define PADDR_WIDTH 32


// Name:         AHB_DATA_WIDTH
// Default:      32
// Values:       32 64 128 256
// 
// The data width of the AHB bus.
`define AHB_DATA_WIDTH 32


// Name:         BIG_ENDIAN
// Default:      Little-Endian
// Values:       Little-Endian (0), Big-Endian (1)
// 
// The endianness of the AHB system. The APB subsystem is always little-endian.
`define BIG_ENDIAN 0



// Name:         APB_ENH_THROUGHPUT_EN
// Default:      No
// Values:       No (0), Yes (1)
// 
// If configured in this mode, DW_apb performs back-to-back transfers on the APB bus, if AHB master is providing 
// back-to-back transfers. This increases the overall throughput.
`define APB_ENH_THROUGHPUT_EN 0


// Name:         APB_DATA_WIDTH
// Default:      32
// Values:       8 16 32
// 
// The data width of the APB bus.
`define APB_DATA_WIDTH 32

//Internal Define for APB Data Width 8

// `define APB_DATA_WIDTH_8

//Internal Define for APB Data Width 16 

// `define APB_DATA_WIDTH_16

//Internal Define for APB Data Width 32 

`define APB_DATA_WIDTH_32


// Name:         NUM_APB_SLAVES
// Default:      4
// Values:       1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16
// 
// The number of APB slave ports.
`define NUM_APB_SLAVES 2


// Name:         START_PADDR_0
// Default:      0x00000400
// Values:       0x00000000, ..., 0xfffffc00
// Enabled:      [<functionof> APB_HAS_XDCDR]
// 
// The Start Address for APB Slave x. This is an absolute address value.
`define START_PADDR_0 32'h00003000


// Name:         START_PADDR_1
// Default:      0x00000800
// Values:       0x00000000, ..., 0xfffffc00
// Enabled:      NUM_APB_SLAVES>1 && [<functionof> APB_HAS_XDCDR]
// 
// Start Address for APB Slave #1. 
// This is an absolute address value. 
//  
// Dependencies: The decoder must be configured as internal 
// (when APB_HAS_XDCDR = 0).
`define START_PADDR_1 32'h00004000


// Name:         START_PADDR_2
// Default:      0x00000c00
// Values:       0x00000000, ..., 0xfffffc00
// Enabled:      NUM_APB_SLAVES>2 && [<functionof> APB_HAS_XDCDR]
// 
// Start Address for APB Slave #2. 
// This is an absolute address value. 
//  
// Dependencies: The decoder must be configured as internal 
// (when APB_HAS_XDCDR = 0).
`define START_PADDR_2 32'h00000c00


// Name:         START_PADDR_3
// Default:      0x00001000
// Values:       0x00000000, ..., 0xfffffc00
// Enabled:      NUM_APB_SLAVES>3 && [<functionof> APB_HAS_XDCDR]
// 
// Start Address for APB Slave #3. 
// This is an absolute address value. 
//  
// Dependencies: The decoder must be configured as internal 
// (when APB_HAS_XDCDR = 0).
`define START_PADDR_3 32'h00001000


// Name:         START_PADDR_4
// Default:      0x00001400
// Values:       0x00000000, ..., 0xfffffc00
// Enabled:      NUM_APB_SLAVES>4 && [<functionof> APB_HAS_XDCDR]
// 
// Start Address for APB Slave #4. 
// This is an absolute address value. 
//  
// Dependencies: The decoder must be configured as internal 
// (when APB_HAS_XDCDR = 0).
`define START_PADDR_4 32'h00001400


// Name:         START_PADDR_5
// Default:      0x00001800
// Values:       0x00000000, ..., 0xfffffc00
// Enabled:      NUM_APB_SLAVES>5 && [<functionof> APB_HAS_XDCDR]
// 
// Start Address for APB Slave #5. 
// This is an absolute address value. 
//  
// Dependencies: The decoder must be configured as internal 
// (when APB_HAS_XDCDR = 0).
`define START_PADDR_5 32'h00001800


// Name:         START_PADDR_6
// Default:      0x00001c00
// Values:       0x00000000, ..., 0xfffffc00
// Enabled:      NUM_APB_SLAVES>6 && [<functionof> APB_HAS_XDCDR]
// 
// Start Address for APB Slave #6. 
// This is an absolute address value. 
//  
// Dependencies: The decoder must be configured as internal 
// (when APB_HAS_XDCDR = 0).
`define START_PADDR_6 32'h00001c00

//
//Dependencies: The decoder must be configured as internal
//(when APB_HAS_XDCDR = 0).

// Name:         START_PADDR_7
// Default:      0x00002000
// Values:       0x00000000, ..., 0xfffffc00
// Enabled:      NUM_APB_SLAVES>7 && [<functionof> APB_HAS_XDCDR]
// 
// Start Address for APB Slave #7. 
// This is an absolute address value.
`define START_PADDR_7 32'h00002000


// Name:         START_PADDR_8
// Default:      0x00002400
// Values:       0x00000000, ..., 0xfffffc00
// Enabled:      NUM_APB_SLAVES>8 && [<functionof> APB_HAS_XDCDR]
// 
// Start Address for APB Slave #8. 
// This is an absolute address value. 
//  
// Dependencies: The decoder must be configured as internal 
// (when APB_HAS_XDCDR = 0).
`define START_PADDR_8 32'h00002400


// Name:         START_PADDR_9
// Default:      0x00002800
// Values:       0x00000000, ..., 0xfffffc00
// Enabled:      NUM_APB_SLAVES>9 && [<functionof> APB_HAS_XDCDR]
// 
// Start Address for APB Slave #9. 
// This is an absolute address value. 
//  
// Dependencies: The decoder must be configured as internal 
// (when APB_HAS_XDCDR = 0).
`define START_PADDR_9 32'h00002800


// Name:         START_PADDR_10
// Default:      0x00002c00
// Values:       0x00000000, ..., 0xfffffc00
// Enabled:      NUM_APB_SLAVES>10 && [<functionof> APB_HAS_XDCDR]
// 
// Start Address for APB Slave #10. 
// This is an absolute address value. 
//  
// Dependencies: The decoder must be configured as internal 
// (when APB_HAS_XDCDR = 0).
`define START_PADDR_10 32'h00002c00


// Name:         START_PADDR_11
// Default:      0x00003000
// Values:       0x00000000, ..., 0xfffffc00
// Enabled:      NUM_APB_SLAVES>11 && [<functionof> APB_HAS_XDCDR]
// 
// Start Address for APB Slave #11. 
// This is an absolute address value. 
//  
// Dependencies: The decoder must be configured as internal 
// (when APB_HAS_XDCDR = 0).
`define START_PADDR_11 32'h00003000


// Name:         START_PADDR_12
// Default:      0x00003400
// Values:       0x00000000, ..., 0xfffffc00
// Enabled:      NUM_APB_SLAVES>12 && [<functionof> APB_HAS_XDCDR]
// 
// Start Address for APB Slave #12. 
// This is an absolute address value. 
//  
// Dependencies: The decoder must be configured as internal 
// (when APB_HAS_XDCDR = 0).
`define START_PADDR_12 32'h00003400


// Name:         START_PADDR_13
// Default:      0x00003800
// Values:       0x00000000, ..., 0xfffffc00
// Enabled:      NUM_APB_SLAVES>13 && [<functionof> APB_HAS_XDCDR]
// 
// Start Address for APB Slave #13. 
// This is an absolute address value. 
//  
// Dependencies: The decoder must be configured as internal 
// (when APB_HAS_XDCDR = 0).
`define START_PADDR_13 32'h00003800


// Name:         START_PADDR_14
// Default:      0x00003c00
// Values:       0x00000000, ..., 0xfffffc00
// Enabled:      NUM_APB_SLAVES>14 && [<functionof> APB_HAS_XDCDR]
// 
// Start Address for APB Slave #14. 
// This is an absolute address value. 
//  
// Dependencies: The decoder must be configured as internal 
// (when APB_HAS_XDCDR = 0).
`define START_PADDR_14 32'h00003c00


// Name:         START_PADDR_15
// Default:      0x00004000
// Values:       0x00000000, ..., 0xfffffc00
// Enabled:      NUM_APB_SLAVES>15 && [<functionof> APB_HAS_XDCDR]
// 
// Start Address for APB Slave #15. 
// This is an absolute address value. 
//  
// Dependencies: The decoder must be configured as internal 
// (when APB_HAS_XDCDR = 0).
`define START_PADDR_15 32'h00004000


// Name:         END_PADDR_0
// Default:      0x000007ff
// Values:       0x000003ff, ..., 0xffffffff
// Enabled:      [<functionof> APB_HAS_XDCDR]
// 
// The End Address for APB Slave x. This is an absolute address value.
`define END_PADDR_0 32'h00003fff


// Name:         END_PADDR_1
// Default:      0x00000bff
// Values:       0x000003ff, ..., 0xffffffff
// Enabled:      NUM_APB_SLAVES>1 && [<functionof> APB_HAS_XDCDR]
// 
// End Address for APB Slave #1 
// This is an absolute address value. 
//  
// Dependencies: The decoder must be configured as internal 
// (when APB_HAS_XDCDR = 0).
`define END_PADDR_1 32'h00004fff


// Name:         END_PADDR_2
// Default:      0x00000fff
// Values:       0x000003ff, ..., 0xffffffff
// Enabled:      NUM_APB_SLAVES>2 && [<functionof> APB_HAS_XDCDR]
// 
// End Address for APB Slave #2 
// This is an absolute address value. 
//  
// Dependencies: The decoder must be configured as internal 
// (when APB_HAS_XDCDR = 0).
`define END_PADDR_2 32'h00000fff


// Name:         END_PADDR_3
// Default:      0x000013ff
// Values:       0x000003ff, ..., 0xffffffff
// Enabled:      NUM_APB_SLAVES>3 && [<functionof> APB_HAS_XDCDR]
// 
// End Address for APB Slave #3 
// This is an absolute address value. 
//  
// Dependencies: The decoder must be configured as internal 
// (when APB_HAS_XDCDR = 0).
`define END_PADDR_3 32'h000013ff


// Name:         END_PADDR_4
// Default:      0x000017ff
// Values:       0x000003ff, ..., 0xffffffff
// Enabled:      NUM_APB_SLAVES>4 && [<functionof> APB_HAS_XDCDR]
// 
// End Address for APB Slave #4 
// This is an absolute address value. 
//  
// Dependencies: The decoder must be configured as internal 
// (when APB_HAS_XDCDR = 0).
`define END_PADDR_4 32'h000017ff


// Name:         END_PADDR_5
// Default:      0x00001bff
// Values:       0x000003ff, ..., 0xffffffff
// Enabled:      NUM_APB_SLAVES>5 && [<functionof> APB_HAS_XDCDR]
// 
// End Address for APB Slave #5 
// This is an absolute address value. 
//  
// Dependencies: The decoder must be configured as internal 
// (when APB_HAS_XDCDR = 0).
`define END_PADDR_5 32'h00001bff


// Name:         END_PADDR_6
// Default:      0x00001fff
// Values:       0x000003ff, ..., 0xffffffff
// Enabled:      NUM_APB_SLAVES>6 && [<functionof> APB_HAS_XDCDR]
// 
// End Address for APB Slave #6 
// This is an absolute address value. 
//  
// Dependencies: The decoder must be configured as internal 
// (when APB_HAS_XDCDR = 0).
`define END_PADDR_6 32'h00001fff


// Name:         END_PADDR_7
// Default:      0x000023ff
// Values:       0x000003ff, ..., 0xffffffff
// Enabled:      NUM_APB_SLAVES>7 && [<functionof> APB_HAS_XDCDR]
// 
// End Address for APB Slave #7 
// This is an absolute address value. 
//  
// Dependencies: The decoder must be configured as internal 
// (when APB_HAS_XDCDR = 0).
`define END_PADDR_7 32'h000023ff


// Name:         END_PADDR_8
// Default:      0x000027ff
// Values:       0x000003ff, ..., 0xffffffff
// Enabled:      NUM_APB_SLAVES>8 && [<functionof> APB_HAS_XDCDR]
// 
// End Address for APB Slave #8 
// This is an absolute address value. 
//  
// Dependencies: The decoder must be configured as internal 
// (when APB_HAS_XDCDR = 0).
`define END_PADDR_8 32'h000027ff


// Name:         END_PADDR_9
// Default:      0x00002bff
// Values:       0x000003ff, ..., 0xffffffff
// Enabled:      NUM_APB_SLAVES>9 && [<functionof> APB_HAS_XDCDR]
// 
// End Address for APB Slave #9 
// This is an absolute address value. 
//  
// Dependencies: The decoder must be configured as internal 
// (when APB_HAS_XDCDR = 0).
`define END_PADDR_9 32'h00002bff


// Name:         END_PADDR_10
// Default:      0x00002fff
// Values:       0x000003ff, ..., 0xffffffff
// Enabled:      NUM_APB_SLAVES>10 && [<functionof> APB_HAS_XDCDR]
// 
// End Address for APB Slave #10 
// This is an absolute address value. 
//  
// Dependencies: The decoder must be configured as internal 
// (when APB_HAS_XDCDR = 0).
`define END_PADDR_10 32'h00002fff


// Name:         END_PADDR_11
// Default:      0x000033ff
// Values:       0x000003ff, ..., 0xffffffff
// Enabled:      NUM_APB_SLAVES>11 && [<functionof> APB_HAS_XDCDR]
// 
// End Address for APB Slave #11 
// This is an absolute address value. 
//  
// Dependencies: The decoder must be configured as internal 
// (when APB_HAS_XDCDR = 0).
`define END_PADDR_11 32'h000033ff


// Name:         END_PADDR_12
// Default:      0x000037ff
// Values:       0x000003ff, ..., 0xffffffff
// Enabled:      NUM_APB_SLAVES>12 && [<functionof> APB_HAS_XDCDR]
// 
// End Address for APB Slave #12 
// This is an absolute address value. 
//  
// Dependencies: The decoder must be configured as internal 
// (when APB_HAS_XDCDR = 0).
`define END_PADDR_12 32'h000037ff


// Name:         END_PADDR_13
// Default:      0x00003bff
// Values:       0x000003ff, ..., 0xffffffff
// Enabled:      NUM_APB_SLAVES>13 && [<functionof> APB_HAS_XDCDR]
// 
// End Address for APB Slave #13 
// This is an absolute address value. 
//  
// Dependencies: The decoder must be configured as internal 
// (when APB_HAS_XDCDR = 0).
`define END_PADDR_13 32'h00003bff


// Name:         END_PADDR_14
// Default:      0x00003fff
// Values:       0x000003ff, ..., 0xffffffff
// Enabled:      NUM_APB_SLAVES>14 && [<functionof> APB_HAS_XDCDR]
// 
// End Address for APB Slave #14 
// This is an absolute address value. 
//  
// Dependencies: The decoder must be configured as internal 
// (when APB_HAS_XDCDR = 0).
`define END_PADDR_14 32'h00003fff


// Name:         END_PADDR_15
// Default:      0x000043ff
// Values:       0x000003ff, ..., 0xffffffff
// Enabled:      NUM_APB_SLAVES>15 && [<functionof> APB_HAS_XDCDR]
// 
// End Address for APB Slave #15 
// This is an absolute address value. 
//  
// Dependencies: The decoder must be configured as internal 
// (when APB_HAS_XDCDR = 0).
`define END_PADDR_15 32'h000043ff


`define R0_APB_SA 32'h3000


`define R0_APB_EA 32'h4fff


`define APB_IS_APB3_0 0


// Name:         APB_INTERFACE_TYPE_SLAVE_0
// Default:      APB2 (APB_IS_APB3_0)
// Values:       APB2 (0), APB3 (1), APB4 (2)
// Enabled:      [<functionof> APB_HAS_XDCDR]
// 
// Select between AMBA 4 APB slave (APB4), AMBA 3 APB slave (APB3), and AMBA 2 APB slave (APB2) for Slave x. If AMBA 3 APB 
// Slave is selected, the additional ports PREADY and PSLVERR are included. If AMBA 4 APB Slave is selected, the additional 
// ports PSTRB and PPROT are included.
`define APB_INTERFACE_TYPE_SLAVE_0 0


// `define APB_APB3_0


// `define APB_APB4_0


`define APB_IS_APB3_1 0


// Name:         APB_INTERFACE_TYPE_SLAVE_1
// Default:      APB2 (APB_IS_APB3_1)
// Values:       APB2 (0), APB3 (1), APB4 (2)
// Enabled:      NUM_APB_SLAVES>1 && [<functionof> APB_HAS_XDCDR]
// 
// Select between AMBA 4 APB and AMBA 3 APB and AMBA 2 APB for Slave 1. 
// If AMBA 3 APB Slave is selected the additional ports 
// PREADY and PSLVERR are included. 
// If AMBA 4 APB Slave is selected the additional ports 
// PSTRB and PPROT are included. 
//  
// Dependencies: The decoder must be configured as internal 
// (when APB_HAS_XDCDR = 0).
`define APB_INTERFACE_TYPE_SLAVE_1 0


// `define APB_APB3_1


// `define APB_APB4_1


`define APB_IS_APB3_2 0


// Name:         APB_INTERFACE_TYPE_SLAVE_2
// Default:      APB2 (APB_IS_APB3_2)
// Values:       APB2 (0), APB3 (1), APB4 (2)
// Enabled:      NUM_APB_SLAVES>2 && [<functionof> APB_HAS_XDCDR]
// 
// Select between AMBA 4 APB and AMBA 3 APB and AMBA 2 APB for Slave 2. 
// If AMBA 3 APB Slave is selected the additional ports 
// PREADY and PSLVERR are included. 
// If AMBA 4 APB Slave is selected the additional ports 
// PSTRB and PPROT are included. 
//  
// Dependencies: The decoder must be configured as internal 
// (when APB_HAS_XDCDR = 0).
`define APB_INTERFACE_TYPE_SLAVE_2 0


// `define APB_APB3_2


// `define APB_APB4_2


`define APB_IS_APB3_3 0


// Name:         APB_INTERFACE_TYPE_SLAVE_3
// Default:      APB2 (APB_IS_APB3_3)
// Values:       APB2 (0), APB3 (1), APB4 (2)
// Enabled:      NUM_APB_SLAVES>3 && [<functionof> APB_HAS_XDCDR]
// 
// Select between AMBA 4 APB and AMBA 3 APB and AMBA 2 APB for Slave 3. 
// If AMBA 3 APB Slave is selected the additional ports 
// PREADY and PSLVERR are included. 
// If AMBA 4 APB Slave is selected the additional ports 
// PSTRB and PPROT are included. 
//  
// Dependencies: The decoder must be configured as internal 
// (when APB_HAS_XDCDR = 0).
`define APB_INTERFACE_TYPE_SLAVE_3 0


// `define APB_APB3_3


// `define APB_APB4_3


`define APB_IS_APB3_4 0


// Name:         APB_INTERFACE_TYPE_SLAVE_4
// Default:      APB2 (APB_IS_APB3_4)
// Values:       APB2 (0), APB3 (1), APB4 (2)
// Enabled:      NUM_APB_SLAVES>4 && [<functionof> APB_HAS_XDCDR]
// 
// Select between AMBA 4 APB and AMBA 3 APB and AMBA 2 APB for Slave 4. 
// If AMBA 3 APB Slave is selected the additional ports 
// PREADY and PSLVERR are included. 
// If AMBA 4 APB Slave is selected the additional ports 
// PSTRB and PPROT are included. 
//  
// Dependencies: The decoder must be configured as internal 
// (when APB_HAS_XDCDR = 0).
`define APB_INTERFACE_TYPE_SLAVE_4 0


// `define APB_APB3_4


// `define APB_APB4_4


`define APB_IS_APB3_5 0


// Name:         APB_INTERFACE_TYPE_SLAVE_5
// Default:      APB2 (APB_IS_APB3_5)
// Values:       APB2 (0), APB3 (1), APB4 (2)
// Enabled:      NUM_APB_SLAVES>5 && [<functionof> APB_HAS_XDCDR]
// 
// Select between AMBA 4 APB and AMBA 3 APB and AMBA 2 APB for Slave 5. 
// If AMBA 3 APB Slave is selected the additional ports 
// PREADY and PSLVERR are included. 
// If AMBA 4 APB Slave is selected the additional ports 
// PSTRB and PPROT are included. 
//  
// Dependencies: The decoder must be configured as internal 
// (when APB_HAS_XDCDR = 0).
`define APB_INTERFACE_TYPE_SLAVE_5 0


// `define APB_APB3_5


// `define APB_APB4_5


`define APB_IS_APB3_6 0


// Name:         APB_INTERFACE_TYPE_SLAVE_6
// Default:      APB2 (APB_IS_APB3_6)
// Values:       APB2 (0), APB3 (1), APB4 (2)
// Enabled:      NUM_APB_SLAVES>6 && [<functionof> APB_HAS_XDCDR]
// 
// Select between AMBA 4 APB and AMBA 3 APB and AMBA 2 APB for Slave 6. 
// If AMBA 3 APB Slave is selected the additional ports 
// PREADY and PSLVERR are included. 
// If AMBA 4 APB Slave is selected the additional ports 
// PSTRB and PPROT are included. 
//  
// Dependencies: The decoder must be configured as internal 
// (when APB_HAS_XDCDR = 0).
`define APB_INTERFACE_TYPE_SLAVE_6 0


// `define APB_APB3_6


// `define APB_APB4_6


`define APB_IS_APB3_7 0


// Name:         APB_INTERFACE_TYPE_SLAVE_7
// Default:      APB2 (APB_IS_APB3_7)
// Values:       APB2 (0), APB3 (1), APB4 (2)
// Enabled:      NUM_APB_SLAVES>7 && [<functionof> APB_HAS_XDCDR]
// 
// Select between AMBA 4 APB and AMBA 3 APB and AMBA 2 APB for Slave 7. 
// If AMBA 3 APB Slave is selected the additional ports 
// PREADY and PSLVERR are included. 
// If AMBA 4 APB Slave is selected the additional ports 
// PSTRB and PPROT are included. 
//  
// Dependencies: The decoder must be configured as internal 
// (when APB_HAS_XDCDR = 0).
`define APB_INTERFACE_TYPE_SLAVE_7 0


// `define APB_APB3_7


// `define APB_APB4_7


`define APB_IS_APB3_8 0


// Name:         APB_INTERFACE_TYPE_SLAVE_8
// Default:      APB2 (APB_IS_APB3_8)
// Values:       APB2 (0), APB3 (1), APB4 (2)
// Enabled:      NUM_APB_SLAVES>8 && [<functionof> APB_HAS_XDCDR]
// 
// Select between AMBA 4 APB and AMBA 3 APB and AMBA 2 APB for Slave 8. 
// If AMBA 3 APB Slave is selected the additional ports 
// PREADY and PSLVERR are included. 
// If AMBA 4 APB Slave is selected the additional ports 
// PSTRB and PPROT are included. 
//  
// Dependencies: The decoder must be configured as internal 
// (when APB_HAS_XDCDR = 0).
`define APB_INTERFACE_TYPE_SLAVE_8 0


// `define APB_APB3_8


// `define APB_APB4_8


`define APB_IS_APB3_9 0


// Name:         APB_INTERFACE_TYPE_SLAVE_9
// Default:      APB2 (APB_IS_APB3_9)
// Values:       APB2 (0), APB3 (1), APB4 (2)
// Enabled:      NUM_APB_SLAVES>9 && [<functionof> APB_HAS_XDCDR]
// 
// Select between AMBA 4 APB and AMBA 3 APB and AMBA 2 APB for Slave 9. 
// If AMBA 3 APB Slave is selected the additional ports 
// PREADY and PSLVERR are included. 
// If AMBA 4 APB Slave is selected the additional ports 
// PSTRB and PPROT are included. 
//  
// Dependencies: The decoder must be configured as internal 
// (when APB_HAS_XDCDR = 0).
`define APB_INTERFACE_TYPE_SLAVE_9 0


// `define APB_APB3_9


// `define APB_APB4_9


`define APB_IS_APB3_10 0


// Name:         APB_INTERFACE_TYPE_SLAVE_10
// Default:      APB2 (APB_IS_APB3_10)
// Values:       APB2 (0), APB3 (1), APB4 (2)
// Enabled:      NUM_APB_SLAVES>10 && [<functionof> APB_HAS_XDCDR]
// 
// Select between AMBA 4 APB and AMBA 3 APB and AMBA 2 APB for Slave 10. 
// If AMBA 3 APB Slave is selected the additional ports 
// PREADY and PSLVERR are included. 
// If AMBA 4 APB Slave is selected the additional ports 
// PSTRB and PPROT are included. 
//  
// Dependencies: The decoder must be configured as internal 
// (when APB_HAS_XDCDR = 0).
`define APB_INTERFACE_TYPE_SLAVE_10 0


// `define APB_APB3_10


// `define APB_APB4_10


`define APB_IS_APB3_11 0


// Name:         APB_INTERFACE_TYPE_SLAVE_11
// Default:      APB2 (APB_IS_APB3_11)
// Values:       APB2 (0), APB3 (1), APB4 (2)
// Enabled:      NUM_APB_SLAVES>11 && [<functionof> APB_HAS_XDCDR]
// 
// Select between AMBA 4 APB and AMBA 3 APB and AMBA 2 APB for Slave 11. 
// If AMBA 3 APB Slave is selected the additional ports 
// PREADY and PSLVERR are included. 
// If AMBA 4 APB Slave is selected the additional ports 
// PSTRB and PPROT are included. 
//  
// Dependencies: The decoder must be configured as internal 
// (when APB_HAS_XDCDR = 0).
`define APB_INTERFACE_TYPE_SLAVE_11 0


// `define APB_APB3_11


// `define APB_APB4_11


`define APB_IS_APB3_12 0


// Name:         APB_INTERFACE_TYPE_SLAVE_12
// Default:      APB2 (APB_IS_APB3_12)
// Values:       APB2 (0), APB3 (1), APB4 (2)
// Enabled:      NUM_APB_SLAVES>12 && [<functionof> APB_HAS_XDCDR]
// 
// Select between AMBA 4 APB and AMBA 3 APB and AMBA 2 APB for Slave 12. 
// If AMBA 3 APB Slave is selected the additional ports 
// PREADY and PSLVERR are included. 
// If AMBA 4 APB Slave is selected the additional ports 
// PSTRB and PPROT are included. 
//  
// Dependencies: The decoder must be configured as internal 
// (when APB_HAS_XDCDR = 0).
`define APB_INTERFACE_TYPE_SLAVE_12 0


// `define APB_APB3_12


// `define APB_APB4_12


`define APB_IS_APB3_13 0


// Name:         APB_INTERFACE_TYPE_SLAVE_13
// Default:      APB2 (APB_IS_APB3_13)
// Values:       APB2 (0), APB3 (1), APB4 (2)
// Enabled:      NUM_APB_SLAVES>13 && [<functionof> APB_HAS_XDCDR]
// 
// Select between AMBA 4 APB and AMBA 3 APB and AMBA 2 APB for Slave 13. 
// If AMBA 3 APB Slave is selected the additional ports 
// PREADY and PSLVERR are included. 
// If AMBA 4 APB Slave is selected the additional ports 
// PSTRB and PPROT are included. 
//  
// Dependencies: The decoder must be configured as internal 
// (when APB_HAS_XDCDR = 0).
`define APB_INTERFACE_TYPE_SLAVE_13 0


// `define APB_APB3_13


// `define APB_APB4_13


`define APB_IS_APB3_14 0


// Name:         APB_INTERFACE_TYPE_SLAVE_14
// Default:      APB2 (APB_IS_APB3_14)
// Values:       APB2 (0), APB3 (1), APB4 (2)
// Enabled:      NUM_APB_SLAVES>14 && [<functionof> APB_HAS_XDCDR]
// 
// Select between AMBA 4 APB and AMBA 3 APB and AMBA 2 APB for Slave 14. 
// If AMBA 3 APB Slave is selected the additional ports 
// PREADY and PSLVERR are included. 
// If AMBA 4 APB Slave is selected the additional ports 
// PSTRB and PPROT are included. 
//  
// Dependencies: The decoder must be configured as internal 
// (when APB_HAS_XDCDR = 0).
`define APB_INTERFACE_TYPE_SLAVE_14 0


// `define APB_APB3_14


// `define APB_APB4_14


`define APB_IS_APB3_15 0


// Name:         APB_INTERFACE_TYPE_SLAVE_15
// Default:      APB2 (APB_IS_APB3_15)
// Values:       APB2 (0), APB3 (1), APB4 (2)
// Enabled:      NUM_APB_SLAVES>15 && [<functionof> APB_HAS_XDCDR]
// 
// Select between AMBA 4 APB and AMBA 3 APB and AMBA 2 APB for Slave 15. 
// If AMBA 3 APB Slave is selected the additional ports 
// PREADY and PSLVERR are included. 
// If AMBA 4 APB Slave is selected the additional ports 
// PSTRB and PPROT are included. 
//  
// Dependencies: The decoder must be configured as internal 
// (when APB_HAS_XDCDR = 0).
`define APB_INTERFACE_TYPE_SLAVE_15 0


// `define APB_APB3_15


// `define APB_APB4_15


// Name:         APB_HAS_APB3
// Default:      0 (APB_INTERFACE_TYPE_SLAVE_0!=0 || APB_INTERFACE_TYPE_SLAVE_1!=0 
//               || APB_INTERFACE_TYPE_SLAVE_2!=0 || APB_INTERFACE_TYPE_SLAVE_3!=0 || 
//               APB_INTERFACE_TYPE_SLAVE_4!=0 || APB_INTERFACE_TYPE_SLAVE_5!=0 || 
//               APB_INTERFACE_TYPE_SLAVE_6!=0 || APB_INTERFACE_TYPE_SLAVE_7!=0 || 
//               APB_INTERFACE_TYPE_SLAVE_8!=0 || APB_INTERFACE_TYPE_SLAVE_9!=0 || 
//               APB_INTERFACE_TYPE_SLAVE_10!=0 || APB_INTERFACE_TYPE_SLAVE_11!=0 || 
//               APB_INTERFACE_TYPE_SLAVE_12!=0 || APB_INTERFACE_TYPE_SLAVE_13!=0 || 
//               APB_INTERFACE_TYPE_SLAVE_14!=0 || APB_INTERFACE_TYPE_SLAVE_15!=0)
// Values:       -2147483648, ..., 2147483647
// 
// IF APB HAS AN APB3 SLAVE
`define APB_HAS_APB3 0


// Name:         APB_HAS_APB4
// Default:      0 (APB_INTERFACE_TYPE_SLAVE_0==2 || APB_INTERFACE_TYPE_SLAVE_1==2 
//               || APB_INTERFACE_TYPE_SLAVE_2==2 || APB_INTERFACE_TYPE_SLAVE_3==2 || 
//               APB_INTERFACE_TYPE_SLAVE_4==2 || APB_INTERFACE_TYPE_SLAVE_5==2 || 
//               APB_INTERFACE_TYPE_SLAVE_6==2 || APB_INTERFACE_TYPE_SLAVE_7==2 || 
//               APB_INTERFACE_TYPE_SLAVE_8==2 || APB_INTERFACE_TYPE_SLAVE_9==2 || 
//               APB_INTERFACE_TYPE_SLAVE_10==2 || APB_INTERFACE_TYPE_SLAVE_11==2 || 
//               APB_INTERFACE_TYPE_SLAVE_12==2 || APB_INTERFACE_TYPE_SLAVE_13==2 || 
//               APB_INTERFACE_TYPE_SLAVE_14==2 || APB_INTERFACE_TYPE_SLAVE_15==2)
// Values:       -2147483648, ..., 2147483647
// 
// IF APB HAS AN APB4 SLAVE
`define APB_HAS_APB4 0


// `define APB_APB3


// `define APB_APB4


// Name:         EXT_PROT_EN
// Default:      0
// Values:       0, 1
// Enabled:      [<functionof> APB_HAS_XDCDR] && APB_HAS_APB4==1
// 
// Enabling this parameter includes the HPROT signal to the AHB interface.
`define EXT_PROT_EN 0


// `define APB_HAS_EXT_PROT


`define APB_HAS_S0


`define APB_HAS_S1


// `define APB_HAS_S2


// `define APB_HAS_S3


// `define APB_HAS_S4


// `define APB_HAS_S5


// `define APB_HAS_S6


// `define APB_HAS_S7


// `define APB_HAS_S8


// `define APB_HAS_S9


// `define APB_HAS_S10


// `define APB_HAS_S11


// `define APB_HAS_S12


// `define APB_HAS_S13


// `define APB_HAS_S14


// `define APB_HAS_S15


// Name:         APB_HAS_XDCDR
// Default:      false
// Values:       false (0), true (1)
// 
// If this parameter is set to True (1), the decoder is external to DW_apb. 
// If False (0), the decoder is internal to DW_apb. For an internal decoder, the 
// addresses needs to be supplied by DW_apb during configuration. An external decoder 
// allows users to connect to any decoder.
`define APB_HAS_XDCDR 0


// `define APB_ENCRYPT

// Internal HADDR_WIDTH, hardcoded to 32.

`define HADDR_WIDTH_INT 32

//Parameter used to compute the bitwidths of signals based on the AHB_DATA_WIDTH (log2 value).

`define HADDR_SEL_WIDTH 0

//Parameter used to compute the bitwidths of signals based on the APB_DATA_WIDTH (log2 value).

`define PADDR_SEL_WIDTH 0


//Continous APB bus transfer define

// `define APB_HAS_CONT_TFR
