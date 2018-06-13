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
// File Version     :        $Revision: #9 $ 
// Revision: $Id: //dwh/DW_ocb/DW_apb/amba_dev/src/DW_apb_mux.v#9 $ 
*/
//-----------------------------------------------------------------------------
// Description : Output multiplexor.
//-----------------------------------------------------------------------------
module i_apb_DW_apb_mux (
  // Inputs
  psel_int, 
















  // Outputs
  pready, 
  pslverr
  );

  //
  //localparam INACTIVE_SLAVES = 16-`NUM_APB_SLAVES;


  input [`NUM_APB_SLAVES-1:0]  psel_int;

















  output wire                  pready;
  output wire                  pslverr;

  //reg [15:0]                   psel;

  reg                          pready_s;
  reg                          pslverr_s;
//This wire contains max number of bits and the signal is used only in the case of the APB slave being APB3.
//Hence the corresponsing bits will not be used in the configurations where either the slave is absent or is not APB3.
  reg [15:0]                   r_psel_int;

  assign                       pready  = pready_s;
  assign                       pslverr = pslverr_s;

  always @(*)
  begin : r_psel_maxbus_PROC
  //If APB3 slaves are not present then the following signals will be a constant and hence they are tied to default values as they are unused.
    r_psel_int = 16'b0;
    r_psel_int[`NUM_APB_SLAVES-1:0] = psel_int[`NUM_APB_SLAVES-1:0];
  end
  
  always @(*)
     begin : pready_PROC
     case(r_psel_int)
     default: 
                 pready_s = 1'b1;
     endcase
     end

  always @(*)
     begin : pslverr_PROC
     case(r_psel_int)
     default: 
                 pslverr_s = 1'b0;
     endcase
     end


endmodule // DW_apb_mux
