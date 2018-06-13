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
// File Version     :        $Revision: #6 $ 
// Revision: $Id: //dwh/DW_ocb/DW_apb/amba_dev/src/DW_apb_deslcr.v#6 $ 
--
-- File :                       DW_apb_deslcr.v
-- Author:                      Chris Gilbert
-- Date :                       $Date: 2015/04/07 $
-- Abstract     :               Data bus "deslicer" for read data
--                              from APB to AHB
--
--
-- By deslicer/deslicing is meant an aggregation of a narrow bus into a 
-- larger bus, where only the elements of the narrow bus contain valid
-- data
--
-- This module consists of 2 demuxes connected via a 32 bit internal
-- bus. The first demux "deslices" the PWDATA_INT data from
-- DW_apb_prdmux into 32 bit sized slices. The address bits
-- used to generate the slices are dependant on the size of
-- the APB data bus,
--
-- The paddr bits (when used) are used to route the narrow data bus
-- into the appropriate slice of the larger data bus
--
-- APB_DATA_WIDTH ==  32: No paddr bits req'd to un-slice 32 bit APB
-- APB_DATA_WIDTH ==  16: paddr[1]   required to un-slice 16 bit APB
-- APB_DATA_WIDTH ==   8: paddr[1:0] required to un-slice  8 bit APB
--
-- This internal 32 bit data bus is then connected as the input to
-- a second mux, which deslices this internal 32 bit bus into the
-- internal AHB data bus. The address bits used to "de-slice" this
-- internal 32 bit bus are dependant on the size of the AHB data bus,
-- 
-- AHB_DATA_WIDTH == 256: paddr[4:2] required to un-slice 32 bit int bus
-- AHB_DATA_WIDTH == 128: paddr[3:2] required to un-slice 32 bit int bus
-- AHB_DATA_WIDTH ==  64: paddr[2]   required to un-slice 32 bit int bus
-- AHB_DATA_WIDTH ==  32: No paddr bits req'd to un-slice 32 bit int bus
--
--
-- Modification History:        Refer to CVS log.
-- =====================================================================
*/

module i_apb_DW_apb_deslcr (
                     big_endian_sel, paddr,
                     prdata_apb, hrdata_max
                 );

input                        big_endian_sel; // big/little endian 
input [`PADDR_WIDTH-1:0]     paddr;          // APB address bus    
input [`APB_DATA_WIDTH-1:0]  prdata_apb; // write data to APB

output [`AHB_DATA_WIDTH-1:0] hrdata_max; // write data from AHB


//----------------
// wires and regs 
//----------------
reg  [31:0]  hrdata32;                     // internal 32 bit data bus 

reg [`AHB_DATA_WIDTH-1:0] hrdata_max;  // write data from AHB 

//-------------------------------------
// map the PRDATA bus to 32 bit slices 
//-------------------------------------
    always @(*)
      begin : hrdata_32bit_PROC
        if (big_endian_sel == 1'b1)
          begin
            hrdata32 = { prdata_apb[7:0], prdata_apb[15:8],
                         prdata_apb[23:16], prdata_apb[31:24] };
          end
        else // little endian system 
          begin
            hrdata32 = prdata_apb;
          end
      end // always block

//----------------------------
// sort out the 32 bit slices 
// Map Internal bus to HRDATA 
//----------------------------
    always @(*)
      begin : hrdata_max_032bit_PROC
        hrdata_max[31:0] = hrdata32;
      end  //always

endmodule

