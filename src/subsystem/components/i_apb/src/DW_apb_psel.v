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
// Revision: $Id: //dwh/DW_ocb/DW_apb/amba_dev/src/DW_apb_psel.v#4 $ 
--
-- File :                       DW_apb_psel
-- Author:                      Chris Gilbert
-- Date :                       $Date: 2012/12/07 $
-- Abstract     :               PSEL enabling module
--
-- This module takes as input the internally registered psel_int signals
-- and gates them with the psel_en signal from the DW_apb_ahbsif.
-- This is to ensure that the PSEL lines remain enabled for only the
-- duration of the current transfer.
--
-- refer to DW_ocb_apb_tech_spec.doc for details.
--
--
-- Modification History:        Refer to CVS log
-- =====================================================================
*/

module i_apb_DW_apb_psel (psel_en, psel_int, psel_apb);


//=================
// IO declarations
//=================

// access enable signal from DW_apb_ahbsif
input                        psel_en;  

// input PSEL bus[`NUM_APB_SLAVES] from DW_apb_ahbsif
input [`NUM_APB_SLAVES-1:0]  psel_int;

// enabled psel bus to top level
output [`NUM_APB_SLAVES-1:0] psel_apb;

//================
// wires and regs
//================

reg    [`NUM_APB_SLAVES-1:0]  psel_apb;


//======================================================================
// Ensure that psel signals are only valid for the duration of a single
// APB access, i.e. whilst psel_en is high
//======================================================================
always @(psel_int or psel_en)
begin : psel_PROC

       if (psel_en == 1'b1)
         begin
           psel_apb = psel_int;
         end
       else
         begin
           psel_apb = {`NUM_APB_SLAVES{1'b0}};
         end
end   // psel_PROC always @(psel_int or psel_en)

endmodule

