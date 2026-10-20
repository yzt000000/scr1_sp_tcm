// -------------------------------------------------------------------
//
//
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
// Release version :  4.01a
// File Version     :        $Revision: #8 $ 
// Revision: $Id: //dwh/DW_ocb/DW_apb_uart/amba_dev/src/DW_apb_uart_biu.v#8 $ 
//
//
//
//
// File    : DW_apb_uart_biu.v
// Author  : Joe Mc Cann & edited by Marc Wall
// Created : Thu Jun 13 13:32:20 2002
//
// Abstract: Apb bus interface module.
//           This module is intended for use with APB slave
//           macro-cells.  The module generates output signals
//           from the APB bus interface that are intended for use in
//           the register block of the macro-cell.
//
//        1: Generates the write enable (wr_en) and read
//           enable (rd_en) for register accesses to the macro-cell.
//
//        2: Decodes the address bus (paddr) to generate the active
//           byte lane signal (byte_en).
//
//        3: Strips the APB address bus (paddr) to generate the
//           register offset address output (reg_addr).
//
//        4: Registers APB read data (prdata) onto the APB data bus.
//           The read data is routed to the correct byte lane in this
//           module.
//
// -------------------------------------------------------------------
// -------------------------------------------------------------------


module i_uart_DW_apb_uart_biu
(
 // APB bus bus interface
 pclk,
 presetn,
 psel,
 penable,
 pwrite, 
 paddr,
 pwdata,
 prdata,

 // regfile interface
 wr_en,
 wr_enx,
 rd_en,
 byte_en,
 reg_addr,
 ipwdata,
 iprdata
 );

   // The number of address bits required to access the UART memory map
   // (register map) is 10
   parameter ADDR_SLICE_LHS = 10;

   // -------------------------------------
   // -- APB bus signals
   // -------------------------------------
   input                            pclk;      // APB clock
   input                            presetn;   // APB reset
   input                            psel;      // APB slave select
//leda NTL_CON37 off
//LMD: Signal/Net must read from the input port in module
//LJ : paddr[1:0] is used to select byte enable signal when APB_DATA_WIDTH is 8.Only
//     1 bit (paddr[1]) is needed to select byte enable signal when APB_DATA_WIDTH 
//     is 16 and no bits are required for it  when APB_DATA_WIDTH is 32. So based on 
//     the configuration signal may or may not read from input port.
//leda NTL_CON13C off
//LMD: non driving port
//LJ:  paddr[1:0] is used to select the byte enable signal. When APB_DATA_WIDTH is 32,
//     byte enable signal is not significant since all bytes are selected. So paddr[1:0]
//     can be non driving port depending on the configuration.
   input       [ADDR_SLICE_LHS-1:0] paddr;     // APB address
//leda NTL_CON13C on
//leda NTL_CON37 on
   input                            pwrite;    // APB write/read
   input                            penable;   // APB enable
   input      [`APB_DATA_WIDTH-1:0] pwdata;    // APB write data bus
   
   output     [`APB_DATA_WIDTH-1:0] prdata;    // APB read data bus

   // -------------------------------------
   // -- Register block interface signals
   // -------------------------------------
   input  [`MAX_APB_DATA_WIDTH-1:0] iprdata;   // Internal read data bus

   output                           wr_en;     // Write enable signal
   output                           wr_enx;    // Write enable extra signal
   output                           rd_en;     // Read enable signal
   output                     [3:0] byte_en;   // Active byte lane signal
   output      [ADDR_SLICE_LHS-3:0] reg_addr;  // Register address offset
   output     [`APB_DATA_WIDTH-1:0] ipwdata;   // Internal write data bus

   // -------------------------------------
   // -- Local registers & wires
   // -------------------------------------
   reg        [`APB_DATA_WIDTH-1:0] prdata;    // Registered prdata output
   reg        [`APB_DATA_WIDTH-1:0] ipwdata;   // Internal pwdata bus
   wire                       [3:0] byte_en;   // Registered byte_en output
  


   
   // --------------------------------------------
   // -- write/read enable
   //
   // -- Generate write/read enable signals from
   // -- psel, penable and pwrite inputs
   // --------------------------------------------
   assign wr_en  = psel &  penable &  pwrite;
   assign rd_en  = psel & (!penable) & (!pwrite);

   // Used to perform writes on the previous cycle
   assign wr_enx = psel & (!penable) &  pwrite;

   
   // --------------------------------------------
   // -- Register address
   //
   // -- Strips register offset address from the
   // -- APB address bus
   // --------------------------------------------
   assign reg_addr = paddr[ADDR_SLICE_LHS-1:2];

   
   // --------------------------------------------
   // -- APB write data
   //
   // -- ipwdata is zero padded before being
   //    passed through this block
   // --------------------------------------------
   always @(pwdata) begin : IPWDATA_PROC
      ipwdata = { `APB_DATA_WIDTH{1'b0} };
      ipwdata[`APB_DATA_WIDTH-1:0] = pwdata[`APB_DATA_WIDTH-1:0];
   end
   
   // --------------------------------------------
   // -- Set active byte lane
   //
   // -- This bit vector is used to set the active
   // -- byte lanes for write/read accesses to the
   // -- registers
   // --------------------------------------------

   



  //leda NTL_CON16 off
  //LMD: Nets or cell pins should not be tied to logic 0 / logic 1.
  //LJ : byte_en is strobe signal used to select active byte lane.When APB
  //     Data Width is 32, All byte lanes are active and thus byte_en is
  //     tied to logic1 (i.e 1111).
   assign   byte_en = 4'b1111;
  //leda NTL_CON16 on

   // --------------------------------------------
   // -- APB read data.
   //
   // -- Register data enters this block on a
   // -- 32-bit bus (iprdata). The upper unused
   // -- bit have been zero padded before entering
   // -- this block.  The process below strips the
   // -- active byte lane(s) from the 32-bit bus
   // -- and registers the data out to the APB
   // -- read data bus (prdata).
   // --------------------------------------------
   always @(posedge pclk or negedge presetn) begin : PRDATA_PROC
      if(presetn == 1'b0) begin
         prdata <= { `APB_DATA_WIDTH{1'b0} };
      end else begin
         if(rd_en) begin
                 prdata <= iprdata;
            end
         end
      end
   
   
endmodule // DW_apb_biu
