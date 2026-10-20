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
// File Version     :        $Revision: #17 $ 
// Revision: $Id: //dwh/DW_ocb/DW_apb/amba_dev/src/DW_apb.v#17 $ 
--
-- File :                       DW_apb.v
-- Author:                      Chris Gilbert
-- Date :                       $Date: 2016/08/26 $
-- Abstract     :               Top level for DW_apb
--                              This module maps the apb submodules
--                              together.
--
--          DW_ocb_amba_constants.v      // generic amba definitions
--          DW_apb_constants.v           // definitions for Bridge
--          DW_apb_cc_constants.v        // coreConsultant Parameters
--          DW_apb_ahbsif.v              // AHB slave interface
--          DW_apb_dcdr.v                // APB address decoder
--          DW_apb_slcr.v                // APB write data slicer
--          DW_apb_deslcr.v              // APB read data deslicer
--          DW_apb_prdmux.v              // PRDATA mux from slaves
--          DW_apb_psel.v
--
-- The module is structured as shown:-
--
--                                  ______
--                                 |      |
--                                 | slcr |-----------> pwdata
--                           ----->|      |
-- hrdata <---------------  |      |______|
--                        | |          |        prdmux
--            __________  | |   -------           /|
-- haddr  -->|          |---   |    ________     / |<-- prdata_s0
-- htrans -->|          | |    |   |        |   |  |       .
--           |  ahbsif  |  --------| deslcr |<--|  |       .
--           |          |      |   |________|   |  |       .
-- hwrite -->|          |------|       |         \ |<-- prdata_s15
-- hwdata -->|          |      |       |          \|
--           |__________|      |----------------------> paddr
--            | |     |        |
-- pclk_en ---  |     |        |    ------
--              |     |         -->| dcdr |
--              |     |            |      |
--              |     |             ------
--              |     |                |
--              |     |             ______     -------> psel_s0
--              |     |            |      |   /            .
--              |      ----------->| psel |---             .
--              |                  |______|   \            .
--              |                              -------> psel_s15
--              |
--               -------------------------------------> penable
--                                          \ 
--                                            --------> pwrite
--
--
//
// Please refer to the databook for full details on the signals.
//
// These are found in the "Signal Description" section of the "Signals" chapter.
// There are details on the following
//   % Input Delays
//   % Output Delays
//   Any False Paths
//   Any Multicycle Paths
//   Any Asynchronous Signals
//
-- =====================================================================
*/

module i_apb_DW_apb (         // system clock and reset
                        hclk, 
               hresetn,
               // AHB control signals - i/p to DW_apb
               haddr, 
               hready, 
               hsel,
               htrans, 
               hwrite,
               hsize, 
               hburst, 
               // DW_apb control response signals to AHB
               hresp, 
               hready_resp,
               // AHB write data, read data
               hwdata, 
               hrdata,
               // clock enable signal for DW_apb
               // indicates a PCLK rising edge.
               pclk_en,
               // APB control signals output by DW_apb
               paddr, 
               penable, 
               pwrite, 
               psel_s1, 
               prdata_s1, 
               psel_s0, 
               prdata_s0, 
               // APB write data (to all slaves)
               pwdata
               );
//-----------------
// IO declarations
//-----------------
input                         hclk;
// AHB system clock
input                         hresetn;
// AHB system reset

// Only the lower 32 bits are used to decode the APB slave selects (psel_sX).
// Hence only the lower 32 bits are passed to the APB bus.

input [`HADDR_WIDTH-1:0]      haddr;
// AHB address bus

input                         hready;
// AHB ready signal
input                         hsel;
// AHB APB select line
input [`HTRANS_WIDTH-1:0]     htrans;
// AHB transfer type bus
input                         hwrite;
// AHB write signal

//The AHB bursts are processed on a cycle-by-cycle basis. 
//Since there is no burst on the APB interface the hburst signal is not used/sampled in the core.
//The APB interface always uses the definite data width and does not have any narrow transfers.
//Hence the hsize signal is not used/sampled in the core.
//These signals are kept for interface compliance.

input [`HSIZE_WIDTH-1:0]      hsize;
// AHB transfer type bus
input [`HBURST_WIDTH-1:0]     hburst;
// AHB transfer type bus

input [`AHB_DATA_WIDTH-1:0]   hwdata;
// AHB write data bus
output [`AHB_DATA_WIDTH-1:0]  hrdata;
// AHB read data bus

output                        hready_resp;
// hready output
output [`HRESP_WIDTH-1:0]     hresp;
// AHB response bus

input                         pclk_en;
// enable strobe for PCLK

output [`PADDR_WIDTH-1:0]     paddr;
// APB address
output                        penable;
// APB penable strobe


// Slave Selects for the APB slaves.
output                        psel_s0;
output                        psel_s1;

output [`APB_DATA_WIDTH-1:0]  pwdata;
// APB write data
output                        pwrite;
// APB write strobe

// read data busses from APB slaves
input [`APB_DATA_WIDTH-1:0]   prdata_s0;
input [`APB_DATA_WIDTH-1:0]   prdata_s1;






//---------------------------
// wire and reg declarations
//---------------------------

wire [`HRESP_WIDTH-1:0]        hresp;
wire [`PADDR_WIDTH-1:0]        paddr;
wire [`AHB_DATA_WIDTH-1:0]     hwdata;
wire [`HSIZE_WIDTH-1:0]        hsize;
wire [`APB_DATA_WIDTH-1:0]     pwdata;
wire                           penable;
wire                           pwrite;
wire                           hready_resp;

wire                           psel_s0;
wire  [`APB_DATA_WIDTH-1:0]    prdata_s0;

wire                           psel_s1;
wire  [`APB_DATA_WIDTH-1:0]    prdata_s1;































// Bussed version of the prdata bus from each slave
wire [`PRDATABUS_WIDTH-1:0]     prdatabus;

wire [`PRDATABUS_WIDTH-1:0] max_prdatabus;

// Big or Little Endian System
wire                           big_endian_sel;
// output from prdmux
wire [`APB_DATA_WIDTH-1:0]     prdata_int;

// interconnect between ahbsif and slcr - 32 bits wide
wire [`HWDATA32_WIDTH-1:0]    pwdata_int;
// prdmux to deslcr, prevents port width mismatches
reg  [`APB_DATA_WIDTH-1:0] prdata_apb;
// deslcr output to ahbsif, maximally configured to remove pkging
wire [`AHB_DATA_WIDTH-1:0] hrdata_max;


// prdata input to dslcr module;
wire [`APB_DATA_WIDTH-1:0] prdata_apb_dslcr;
// write data bus from ahbsif to slcr, max width to remove packaging
reg  [`AHB_DATA_WIDTH-1:0] hwdata_max;
// write data bus to slaves, max width to remove packaging
// pwdata is sliced from this bus
wire [`APB_DATA_WIDTH-1:0] pwdata_apb;
// timing strobe for DW_apb_psel and any other modules that need to know
// when the APB is active, used to gate psel signals to slaves
wire                           psel_en;
// enable for DW_apb_psel
wire [`NUM_APB_SLAVES-1:0]     psel_apb;
// from psel to top level
wire [`NUM_APB_SLAVES-1:0]     psel_int;
// i/p to psel and prdmux


// Internal, 32 bits only, haddr signal.
wire [`HADDR_WIDTH_INT-1:0]        haddr_int;









  // Take the lower 32 bits from haddr.
  assign haddr_int = haddr[`HADDR_WIDTH_INT-1:0];

// Selects the pwdata from pwdata_int, only changes when the address changes.
//--------------------------------------------
// instantiate the AHB Slave interface module
//--------------------------------------------

  i_apb_DW_apb_ahbsif
   U_DW_apb_ahbsif (
                                 .hclk(hclk),
                                 .hresetn(hresetn),
                                 .haddr(haddr_int),
                                 .hready(hready),
                                 .hsel(hsel),
                                 .htrans(htrans),
                                 .hwrite(hwrite),
                                 .hwdata_max(hwdata_max),
                                 .hready_resp(hready_resp),
                                 .hresp(hresp),
                                 .pclk_en(pclk_en),
                                 .penable(penable),
                                 .psel_en(psel_en),
                                 .paddr(paddr),
                                 .pwdata_int(pwdata_int),
                                 .pwrite(pwrite)// aaraujo @ 05/05/2010: CRM_9000464282
                                 
                                 );

//-----------------------------------------
// Instantiate the address decoder circuit
//-----------------------------------------

  i_apb_DW_apb_dcdr
   U_DW_apb_dcdr (
    .paddr    (paddr),        // input address bus
    .psel_int (psel_int)      // PSEL output bus
  );


//
// Build internal busses from master and slave signals, The following
// assign statements are generated by a tcl plugin script.
//


// end of generated "assign" statements



//--------------------------------------------------------------
// Instantiate the slicer and deslicer modules. These slice the
// hwdata bus onto the pwdata bus based on the paddr lsb's and
// map the prdata_int bus to the appropriate hrdata slice.
// For the case where
// `APB_DATA_WIDTH == `AHB_DATA_WIDTH (== 32 AMBA Rev 2.0 spec)
// these modules equate to feedthroughs
//--------------------------------------------------------------

  i_apb_DW_apb_slcr
   U_DW_apb_slcr (
    .big_endian_sel(big_endian_sel),
                             .pwdata_int(pwdata_int), // write data from AHB
                             .pwdata_apb(pwdata_apb)// write data to APB
                             
                             );


   assign prdata_apb_dslcr = prdata_apb; // read data from APB
  //
  // aaraujo @ 05/05/2010: CRM_9000464282
  // Drive prdata_apb_mux to DW_apb_deslcr
  //
  i_apb_DW_apb_deslcr
   U_DW_apb_deslcr (
    .big_endian_sel (big_endian_sel),
    .paddr          (paddr),
    .prdata_apb     (prdata_apb_dslcr), // read data from APB
    .hrdata_max     (hrdata_max)      // read data to AHB
  );

//-------------------------------
// Instantiate the read data mux
//-------------------------------

  i_apb_DW_apb_prdmux
   U_DW_apb_prdmux (
                                 .psel_int(psel_int[`NUM_APB_SLAVES-1:1]),  // Slave select from dcdr
                                 .prdatabus(prdatabus), // data from slave(s)
                                 .prdata_int(prdata_int)// output data
                                 
                                 );


//------------------------------------
// Instantiate the PSEL_enable module
//------------------------------------

  i_apb_DW_apb_psel
   U_DW_apb_psel (
    .psel_en  (psel_en),
    .psel_int (psel_int),
    .psel_apb (psel_apb[`NUM_APB_SLAVES-1:0])
  );

//  assign big_endian_sel = `BIG_ENDIAN;
// endianess is always a constant depending on the BIG_ENDIAN parameter.
      assign big_endian_sel = 1'b0;

  assign pwdata = pwdata_apb[`APB_DATA_WIDTH-1:0];

  always @(hwdata) begin : hwdata_max_PROC
    hwdata_max = {`AHB_DATA_WIDTH{1'b0}};
    hwdata_max[`AHB_DATA_WIDTH-1:0] = hwdata[`AHB_DATA_WIDTH-1:0];
  end

  always @(prdata_int) begin : prdata_apb_PROC
    prdata_apb = {`APB_DATA_WIDTH{1'b0}};
    prdata_apb[`APB_DATA_WIDTH-1:0] = prdata_int;
  end


//------------------------------------
// Instantiate the rdretime module
//------------------------------------
  //
  // aaraujo @ 05/05/2010: CRM_9000464282
  // Decoded hrdata is muxed here and if the transfer
  // targets an APB3 Slave then hrdata will be registered
  // to be aligned with hready_resp.
  //


  assign hrdata[`AHB_DATA_WIDTH-1:0] = hrdata_max[`AHB_DATA_WIDTH-1:0];

  assign max_prdatabus[`APB_DATA_WIDTH-1:0]                         = prdata_s0;
  assign max_prdatabus[(  `APB_DATA_WIDTH*2)-1:(  `APB_DATA_WIDTH)]     = prdata_s1;















  assign prdatabus = max_prdatabus[`PRDATABUS_WIDTH-1:0];

//-----------------------------------------------------------
// split out the psel_apb bus to the individual psel signals
// psel_s0 is always present.
//-----------------------------------------------------------

  assign psel_s0 = psel_apb[0];

  assign psel_s1 = psel_apb[1];
















endmodule

