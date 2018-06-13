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
// Release version :  2.13a
// File Version     :        $Revision: #8 $ 
// Revision: $Id: //dwh/DW_ocb/DW_ahb/amba_dev/src/DW_ahb_dcdr.v#8 $ 
--
-- File :                       DW_ahb_dcdr.v
-- Author:                      Ray Beechinor, Peter Gillen 
-- Date :                       $Date: 2016/08/26 $ 
-- Abstract     :               
--
-- Implements the AHB decoder from a specified address range for each
-- peripheral. Need to expand the functionality to include the addition
-- of multiple address ranges for a selected peripheral
--
*/

module i_ahb_DW_ahb_dcdr (
  haddr,
                    hsel
                    );

  // physical parameters
  parameter HADDR_WIDTH = `HADDR_WIDTH;       // 32, 64

  // memory map parameters
  parameter [`HADDR_WIDTH-1:0] INT_R1_N_SA_1 = 0;
  parameter [`HADDR_WIDTH-1:0] INT_R1_N_EA_1 = 0;
  parameter [`HADDR_WIDTH-1:0] INT_R1_N_SA_2 = 0;
  parameter [`HADDR_WIDTH-1:0] INT_R1_N_EA_2 = 0;

  input  [`HADDR_WIDTH-1:0]   haddr;
// There are two modes of operation, normal or boot mode and one
// can configure the address map differently for both so that say
// the interrupt service routines are at address 0, etc
  output [`INTERNAL_HSEL-1:0] hsel;

  wire [`NUM_IAHB_SLAVES:0]   hsel_norm;
  wire [`NUM_IAHB_SLAVES:0]   hsel_int; 
 
  reg                         hsel_none;
  integer                     i;

//
// Generate the normal addresses. 
// VISIBLE_x and MR_Nx and MR_Bx are all
// static signals
// Slaves can have two regions of address within the address map
// if they so choose.
//

  assign hsel_norm[0] = 1'b0;

  assign hsel_norm[1] = (
     (((haddr >= INT_R1_N_SA_1) && (haddr <= INT_R1_N_EA_1)) ||
      ((haddr >= `R2_N_SA_1) && (haddr <= `R2_N_EA_1) &&
       (`MR_N1 >= 3'b001)) ||
      ((haddr >= `R3_N_SA_1) && (haddr <= `R3_N_EA_1) &&
       (`MR_N1 >= 3'b010)) ||
      ((haddr >= `R4_N_SA_1) && (haddr <= `R4_N_EA_1) &&
       (`MR_N1 >= 3'b011)) ||
      ((haddr >= `R5_N_SA_1) && (haddr <= `R5_N_EA_1) &&
       (`MR_N1 >= 3'b100)) ||
      ((haddr >= `R6_N_SA_1) && (haddr <= `R6_N_EA_1) &&
       (`MR_N1 >= 3'b101)) ||
      ((haddr >= `R7_N_SA_1) && (haddr <= `R7_N_EA_1) &&
       (`MR_N1 >= 3'b110)) ||
      ((haddr >= `R8_N_SA_1) && (haddr <= `R8_N_EA_1) &&
       (`MR_N1 == 3'b111)) ) &&
     (`VISIBLE_1 != 2'b10));

  assign hsel_norm[2] = (
     (((haddr >= INT_R1_N_SA_2) && (haddr <= INT_R1_N_EA_2)) ||
      ((haddr >= `R2_N_SA_2) && (haddr <= `R2_N_EA_2) &&
       (`MR_N2 == 1'b1))) &&
     (`VISIBLE_2 != 2'b10));

  assign hsel_norm[3] = (
     (((haddr >= `R1_N_SA_3) && (haddr <= `R1_N_EA_3)) ||
      ((haddr >= `R2_N_SA_3) && (haddr <= `R2_N_EA_3) &&
       (`MR_N3 == 1'b1))) &&
     (`VISIBLE_3 != 2'b10));






























//
// extract the active slice from the fully configured bus provided
// one is in normal or remap mode
//
  assign hsel_int = hsel_norm[`NUM_IAHB_SLAVES:0];
// reuse-pragma endSub ARBIF_PROC



//
// Determine hsel_none, provided no other hsel's are active
//
  always @(hsel_int)
  begin : hsel_none_PROC
    hsel_none = 1'b1;
    for (i=0; i<=`NUM_IAHB_SLAVES; i=i+1) begin
      if (hsel_int[i] == 1'b1)
        hsel_none = 1'b0;
    end
  end

  assign hsel[`NUM_IAHB_SLAVES:0] = hsel_int;
  assign hsel[`NUM_IAHB_SLAVES+1] = hsel_none;
   
endmodule 
