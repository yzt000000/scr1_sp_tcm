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
// Revision: $Id: //dwh/DW_ocb/DW_apb/amba_dev/src/DW_apb_prdmux.v#6 $ 
--
-- File :                       DW_apb_prdmux
-- Author:                      Chris Gilbert
-- Date :                       $Date: 2015/05/14 $
-- Abstract     :               One hot Mux for APB read data bus muxing
--                              refer to DW_ocb_apb_tech_spec.doc
--                              for details.
--
-- Modification History:        Refer to CVS log.
-- =====================================================================
*/

module i_apb_DW_apb_prdmux (
                      psel_int,
                      prdatabus,
                      prdata_int
                      );
// IO declarations 

input  [`NUM_APB_SLAVES-2:0]  psel_int;   // Slave select bus from dcdr

input  [`PRDATABUS_WIDTH-1:0] prdatabus;  // input data from slaves

output [`APB_DATA_WIDTH-1:0]  prdata_int; // output data

// wire and reg declarations 

reg    [`APB_DATA_WIDTH-1:0]     prdata_int;

//-----------------------------------
// declare loop counter for for loop 
//-----------------------------------
integer                          i,j;

//-----------------------------------------------------------
// implement the one hot mux as a for loop to ensure that no 
// packaging is required for different sub system            
// configurations i.e. different numbers of slaves           
// default output is slave 0, which must be always present.
//-----------------------------------------------------------


always @(*)
  begin : one_hot_mux_PROC
      prdata_int = prdatabus[`APB_DATA_WIDTH-1:0];
      for (i=1;i<`NUM_APB_SLAVES;i=i+1) begin
        if (psel_int[i-1]==1'b1)
          begin
            for (j=0; j<`APB_DATA_WIDTH; j=j+1) begin
              prdata_int[j] = prdatabus[(i*`APB_DATA_WIDTH)+j];
            end
          end
      end // for
  end  // one_hot_mux_PROC

endmodule
