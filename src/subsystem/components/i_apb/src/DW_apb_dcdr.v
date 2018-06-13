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
// Revision: $Id: //dwh/DW_ocb/DW_apb/amba_dev/src/DW_apb_dcdr.v#7 $ 
--
-- File :                       DW_apb_dcdr
-- Author:                      Chris Gilbert
-- Date :                       $Date: 2015/05/14 $
-- Abstract     :               APB address decoder module.
--
-- This module takes as input the address. It decodes the address and
-- either generates a valid decode or an invalid_addr signal. This
-- information is then relayed back to the DW_apb_ahbsif module for
-- appropriate action to be taken. The decoder is maximally configured
-- - 16 slaves - always, and the required PSEL lines are sliced out of
-- this maximally configured system.
--
-- 
--
--
-- Modification History:        Refer to CVS log
-- =====================================================================
*/

module i_apb_DW_apb_dcdr (
                    paddr,
                    psel_int
                   );

//-----------------
// IO declarations 
//-----------------

input [`PADDR_WIDTH-1:0]       paddr;    // input address bus

output [`NUM_APB_SLAVES-1:0]   psel_int;  // PSEL output bus

//----------------
// wires and regs 
//----------------
wire [`NUM_APB_SLAVES-1:0] psel_int;

//---------------------------
// Internal wires and regs
//---------------------------
//wire [`MAX_APB_SLAVES-1:0] psel_tmp; // max width psel bus
wire [`NUM_APB_SLAVES-1:0] psel_tmp; // max width psel bus

//
// Generate comparator based decoder for a maximally configured
// APB system always
//
assign psel_tmp[0]  = ((paddr >= `START_PADDR_0) && (paddr <= `END_PADDR_0));
assign psel_tmp[1]  = ((paddr >= `START_PADDR_1) && (paddr <= `END_PADDR_1));
 
//
// Extract the active slice from the maximally configured bus
//
assign psel_int[`NUM_APB_SLAVES-1:0] = psel_tmp[`NUM_APB_SLAVES-1:0];

endmodule
