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
// Revision: $Id: //dwh/DW_ocb/DW_apb/amba_dev/src/DW_apb_rdretime.v#6 $ 
--
-- File :                       DW_apb_rdretime.v
-- Author:                      Chris Albano Araujo
-- Date :                       $Date: 2016/08/26 $
-- Abstract     :               This module registers decoded prdata and
--                              selects it when APB3 transfers are being
--                              processed. Muxed signal will be used in
--                              deslcr module on hrdata generation to
--                              ensure it is aligned with hready_resp.
--
-- =====================================================================
*/

//
// aaraujo @ 05/05/2010: CRM_9000464282
// If DW_apb_rdrtime module is placed after DW_apb_desclr, hrdata would be
// registered instead of prdata_apb. For configurations having high values
// of AHB_DATA_WIDTH, the number of required Flip-Flops to get hrdata
// registered would increase and consequently a significant area penalty
// would be noticed. Thus, DW_apb_rdrtime was moved in front of DW_apb_desclr
// feeding registered prdata to it.
//
// DW_apb_deslcr module uses paddr[4:0] to un-slice APB data bus bits. This
// would require paddr to be registered as well so that it is aligned with
// pdrata. However, registered prdata will only be driven into DW_apb_desclr
// for one clock cycle after an APB3 transfer has been completed. During
// that time paddr holds the same value as the previous cycle so that the
// alignment requirement is satisfied without registering paddr.
//

module i_apb_DW_apb_rdretime (
                     hclk,
                     hresetn,
                     apb3_rtrans_ready,

                     prdata_apb,
                     prdata_apb_mux
                 );

input                            hclk;                // AHB system clock
input                            hresetn;             // AHB system reset
input                            apb3_rtrans_ready;   // Extend hrdata for APB3 Slaves

input  [`APB_DATA_WIDTH-1:0] prdata_apb;          // Read data from APB

output [`APB_DATA_WIDTH-1:0] prdata_apb_mux;      // Muxed prdata_apb

reg    [`APB_DATA_WIDTH-1:0] prdata_apb_reg;

  always @(posedge hclk or negedge hresetn)
    begin : register_prdata_apb_PROC
      if (hresetn == 1'b0) begin
        prdata_apb_reg <= {`APB_DATA_WIDTH{1'b0}};
      end else begin
        prdata_apb_reg <= prdata_apb;
      end
    end

  assign prdata_apb_mux = (apb3_rtrans_ready) ? prdata_apb_reg : prdata_apb;

endmodule
