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
// Revision: $Id: //dwh/DW_ocb/DW_apb/amba_dev/src/DW_apb_slcr.v#7 $ 
--
-- File :                       DW_apb_slcr
-- Author:                      Chris Gilbert
-- Date :                       $Date: 2015/05/14 $
-- Abstract     :               Slices AHB into APB sized chunks
--
-- This module consists of 1 mux connected via a 32 bit internal bus.
--
-- This internal 32 bit data bus is then connected as the input to 
-- a mux, which slices this internal 32 bit bus into APB data
-- bus sized slices.
--
-- APB_DATA_WIDTH ==  32: No paddr bits req'd to generate 32 bit APB
-- APB_DATA_WIDTH ==  16: paddr[1]   required to generate 16 bit APB
-- APB_DATA_WIDTH ==   8: paddr[1:0] required to generate  8 bit APB
--
-- Modification History:        Refer to CVS log.
-- =====================================================================
*/

module i_apb_DW_apb_slcr (
                    big_endian_sel, 
                    pwdata_int, 
                    pwdata_apb
                    );

//=================
// IO declarations 
//=================

// big/little endian control
input                            big_endian_sel;
input [`HWDATA32_WIDTH-1:0]      pwdata_int;  // write data from AHB 

output [`APB_DATA_WIDTH-1:0] pwdata_apb;  // write data to APB 

//================
// wires and regs 
//================

reg [`APB_DATA_WIDTH-1:0] pwdata_apb;   // write data to APB 

//================================================
// map out the APB write data from the AHB slices 
// assumes default APB width is 32 bits           
//================================================
    always @(*)
      begin : pwdata_apb_32bit_PROC
        if (big_endian_sel == 1'b1)
          begin
            pwdata_apb = { pwdata_int[7:0], pwdata_int[15:8],
                           pwdata_int[23:16], pwdata_int[31:24] };
          end
        else // little endian
          begin
            pwdata_apb = pwdata_int;
          end
      end // always block

endmodule

