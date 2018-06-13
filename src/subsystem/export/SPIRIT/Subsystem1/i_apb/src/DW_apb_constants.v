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
// File Version     :        $Revision: #7 $ 
// Revision: $Id: //dwh/DW_ocb/DW_apb/amba_dev/src/DW_apb_constants.v#7 $ 
--
-- File :                       DW_apb_constants.v
-- Author:                      Chris Gilbert
-- Date :                       $Date: 2015/05/14 $
-- Abstract     :               This module contains definitions that 
--                              are used by the DW_apb_ahbsif module.
--
--                              These definitions are included as a
--                              separate module as this is the easiest
--                              way of packaging them, since the actual
--                              values of these constants depends on the
--                              configuration of the APB system.
--
-- Modification History:        Refer to CVS log
-- =====================================================================
*/


// Name:         MAX_APB_SLAVES
// Default:      16
// Values:       -2147483648, ..., 2147483647
// 
// Maximum number of slaves in subsystem
`define MAX_APB_SLAVES 16


// Name:         MAX_AHB_DATA_WIDTH
// Default:      256
// Values:       -2147483648, ..., 2147483647
// 
// Maximum AHB Data Width
`define MAX_AHB_DATA_WIDTH 256


// Name:         MAX_APB_DATA_WIDTH
// Default:      32
// Values:       -2147483648, ..., 2147483647
// 
// Maximum APB Data Width
`define MAX_APB_DATA_WIDTH 32

//
// Not defined as a reuse pragma so macro will not be resolved.
// For testbench purposes
//
`define PRDATABUS_WIDTH `APB_DATA_WIDTH*`NUM_APB_SLAVES


// Name:         MAX_PRDATABUS_WIDTH
// Default:      512 (MAX_APB_DATA_WIDTH*MAX_APB_SLAVES)
// Values:       -2147483648, ..., 2147483647
// 
// Maximum width of bussed prdata bus
`define MAX_PRDATABUS_WIDTH 512


// Name:         HWDATA32_WIDTH
// Default:      32
// Values:       -2147483648, ..., 2147483647
// 
// Maximum width of data to store
`define HWDATA32_WIDTH 32

