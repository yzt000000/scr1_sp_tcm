/*
------------------------------------------------------------------------
--
//  ------------------------------------------------------------------------
//
//                    (C) COPYRIGHT 2013 - 2016 SYNOPSYS, INC.
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
// Release version :  2.12a
// File Version     :        $Revision: #14 $ 
// Revision: $Id: //dwh/DW_ocb/DW_apb_gpio/amba_dev/src/DW_apb_gpio_apbif.v#14 $ 
--
-- File :                       DW_apb_gpio_apbif.v
//
//
-- Date :                       $Date: 2016/08/26 $
-- Abstract     :               APB Slave Interface and Register File
--                              block for DW_apb_gpio
--
-- Modification History:
-- Date                 By      Version Change  Description
-- =====================================================================
-- See CVS log
-- =====================================================================
*/

`define GPIO_SWPORTA_DR_OFFSET    5'b00000
`define GPIO_SWPORTA_DDR_OFFSET   5'b00001
`define GPIO_INTEN_OFFSET         5'b01100
`define GPIO_INTMASK_OFFSET       5'b01101
`define GPIO_INTTYPE_LEVEL_OFFSET 5'b01110
`define GPIO_INTSTATUS_OFFSET     5'b10000
`define GPIO_RAW_INTSTATUS_OFFSET 5'b10001
`define GPIO_INT_POLARITY_OFFSET  5'b01111
`define GPIO_PORTA_EOI_OFFSET     5'b10011
`define GPIO_LS_SYNC_OFFSET       5'b11000
`define GPIO_EXT_PORTA_OFFSET     5'b10100
`define GPIO_ID_CODE_OFFSET       5'b11001
`define GPIO_VER_ID_CODE_OFFSET   5'b11011
`define GPIO_CONFIGID_REG2_OFFSET 5'b11100
`define GPIO_CONFIGID_REG1_OFFSET 5'b11101

module i_gpio_DW_apb_gpio_apbif (
   pclk,                 // APB Clock
                          presetn,              // APB Reset
                          penable,              // APB Enable
                          pwrite,               // APB Write Enable
                          pwdata,               // APB Write Data Bus
                          paddr,                // APB Address Bus
                          psel,
                          gpio_swporta_dr,      // Port A data
                          gpio_swporta_ddr,     // Port A data direction
                          gpio_ext_porta_rb,    // Port A external port readback data
                          gpio_inten,           // Interrupt Enable
                          gpio_intmask,         // Interrupt Mask
                          gpio_inttype_level,   // Interrupt Level
                          gpio_intstatus,       // Port A interrupt status
                          gpio_raw_intstatus,   // Raw Port A interrupt status (premasking)
                          gpio_porta_eoi,       // Port A interrupt clear
                          gpio_ls_sync,         // Level sensitive synchronisation enable
                          gpio_int_polarity,    // Interrupt Polarity
                          prdata// APB readback data
                          
                          ); 

   parameter [`GPIO_PWIDTH_A-1:0]   SWPORTA_RESET =  `GPIO_SWPORTA_RESET ;
   parameter                        PWIDTHA_BLANE = (`GPIO_PWIDTH_A-1)>>3;
   parameter [`GPIO_ID_WIDTH-1:0]   ID_NUM        = `GPIO_ID_NUM;
   parameter                [0:0]   INT_BOTH_EDGE = `GPIO_INT_BOTH_EDGE;

   output [`APB_DATA_WIDTH-1:0]     prdata;
   output [`GPIO_PWIDTH_A-1:0]      gpio_swporta_dr;
   output [`GPIO_PWIDTH_A-1:0]      gpio_swporta_ddr;
   output [`GPIO_PWIDTH_A-1:0]      gpio_inten;
   output [`GPIO_PWIDTH_A-1:0]      gpio_intmask;
   output [`GPIO_PWIDTH_A-1:0]      gpio_inttype_level;
   output [`GPIO_PWIDTH_A-1:0]      gpio_porta_eoi;
   output                           gpio_ls_sync;
   output [`GPIO_PWIDTH_A-1:0]      gpio_int_polarity;

   input  [`GPIO_PWIDTH_A-1:0]      gpio_intstatus;
   input  [`GPIO_PWIDTH_A-1:0]      gpio_raw_intstatus;
   input  [`GPIO_PWIDTH_A-1:0]      gpio_ext_porta_rb;
   input                         pclk;
   input                         presetn;
   input                         penable;
   input                         pwrite;
   input  [`APB_DATA_WIDTH-1:0]  pwdata;
   input                         psel;
   input  [`GPIO_ADDR_SLICE_LHS:`GPIO_ADDR_SLICE_RHS]     paddr;


   wire [`GPIO_PWIDTH_A-1:0] gpio_ext_porta_rb;
   wire [`GPIO_PWIDTH_A-1:0] gpio_intstatus;
   wire [`GPIO_PWIDTH_A-1:0] gpio_raw_intstatus;
   reg                       gpio_ls_sync;
   wire [31:0]               gpio_vid;

   reg         [`GPIO_PWIDTH_A-1:0] gpio_swporta_dr;
   reg         [ PWIDTHA_BLANE  :0] gpio_swporta_dr_wen;
   reg         [`GPIO_PWIDTH_A-1:0] gpio_swporta_ddr;
   reg         [ PWIDTHA_BLANE  :0] gpio_swporta_ddr_wen;
   reg         [`GPIO_PWIDTH_A-1:0] gpio_inten;
   reg         [ PWIDTHA_BLANE  :0] gpio_inten_wen;
   reg         [`GPIO_PWIDTH_A-1:0] gpio_intmask;
   reg         [ PWIDTHA_BLANE  :0] gpio_intmask_wen;
   reg         [`GPIO_PWIDTH_A-1:0] gpio_inttype_level;
   reg         [ PWIDTHA_BLANE  :0] gpio_inttype_level_wen;
   reg         [`GPIO_PWIDTH_A-1:0] gpio_int_polarity;
   reg         [ PWIDTHA_BLANE  :0] gpio_int_polarity_wen;
   reg         [`GPIO_PWIDTH_A-1:0] gpio_porta_eoi;
   reg         [ PWIDTHA_BLANE  :0] gpio_porta_eoi_wen;
   reg                              gpio_ls_sync_wen;

   reg    [`APB_DATA_WIDTH-1:0]     prdata;
   reg    [`APB_DATA_WIDTH-1:0]     iprdata;

   wire   [`MAX_APB_DATA_WIDTH-1:0] gpio_configid_reg2;
   wire   [`MAX_APB_DATA_WIDTH-1:0] gpio_configid_reg1;
// Certain MSB bits in pwdata_int signal may go unused according to a range of parameters icluding GPIO_PWIDTH_A(B/C/D)
// Configuring the signal considering all of these parameters would inhibit code readability.
   reg    [`MAX_APB_DATA_WIDTH-1:0] pwdata_int;
   wire   [`GPIO_ID_WIDTH-1:0] gpio_id_code;


// The below config-ID registers contain predifined configuration parameters
   assign gpio_vid                  = `GPIO_VERSION_ID;
   assign gpio_configid_reg1[31:22] =  10'b0;
   assign gpio_configid_reg2[31:20] =  12'b0;
   assign gpio_configid_reg1[21]    =  INT_BOTH_EDGE          ;
   assign gpio_configid_reg1[20:16] = `GPIO_ENCODED_ID_WIDTH  ;
   assign gpio_configid_reg1[15]    = `GPIO_ID                ;
   assign gpio_configid_reg1[14]    = `GPIO_ADD_ENCODED_PARAMS;
   assign gpio_configid_reg1[13]    = `GPIO_DEBOUNCE          ;
   assign gpio_configid_reg1[12]    = `GPIO_PORTA_INTR        ;
   assign gpio_configid_reg1[11]    = `GPIO_HW_PORTD          ;
   assign gpio_configid_reg1[10]    = `GPIO_HW_PORTC          ;
   assign gpio_configid_reg1[9]     = `GPIO_HW_PORTB          ;
   assign gpio_configid_reg1[8]     = `GPIO_HW_PORTA          ;
   assign gpio_configid_reg1[7]     = `GPIO_PORTD_SINGLE_CTL  ;
   assign gpio_configid_reg1[6]     = `GPIO_PORTC_SINGLE_CTL  ;
   assign gpio_configid_reg1[5]     = `GPIO_PORTB_SINGLE_CTL  ;
   assign gpio_configid_reg1[4]     = `GPIO_PORTA_SINGLE_CTL  ;
   assign gpio_configid_reg1[3:2]   = `GPIO_ENCODED_NUM_PORTS ;
   assign gpio_configid_reg1[1:0]   = `GPIO_ENCODED_APB_WIDTH ;
   assign gpio_configid_reg2[19:15] = `GPIO_ENCODED_PWIDTH_D  ;
   assign gpio_configid_reg2[14:10] = `GPIO_ENCODED_PWIDTH_C  ;
   assign gpio_configid_reg2[9:5]   = `GPIO_ENCODED_PWIDTH_B  ;
   assign gpio_configid_reg2[4:0]   = `GPIO_ENCODED_PWIDTH_A  ;
   assign gpio_id_code              =  ID_NUM;

// Since the port width is unique for all the four ports, the pwdata is kept to the maximum width.
  always @(pwdata)
  begin : pwdata_int_PROC
    pwdata_int = {`MAX_APB_DATA_WIDTH{1'b0}};
    pwdata_int[`APB_DATA_WIDTH-1:0] = pwdata;
  end

// Write enable generated for each of 4 byte lane's for each register.
// Control logic synthesis's out Write Enable if corresponding
// byte lane does not exist due to the fact that either the register size
// does not require the byte lane Write Enable. If register not required
// for selected configuration then all byte lane write enables synthesised out
// for that register.


// Generate Write Enable bus for gpio_swporta_dr register.

  always @(paddr or psel or penable or pwrite)
  begin : gpio_swporta_dr_wen_PROC
    gpio_swporta_dr_wen = {(PWIDTHA_BLANE+1){1'b0}};

    if ((psel == 1'b1) && (penable == 1'b1) && (pwrite == 1'b1)) begin
        if (paddr[`GPIO_ADDR_SLICE_LHS:`GPIO_ADDR_SLICE_RHS] == `GPIO_SWPORTA_DR_OFFSET ) begin
                        gpio_swporta_dr_wen = {(PWIDTHA_BLANE+1){1'b1}};
        end
        end
      end

// Generate Write Enable bus for gpio_swporta_ddr register.


  always @(paddr or psel or penable or pwrite)
  begin : gpio_swporta_ddr_wen_PROC
    gpio_swporta_ddr_wen = {(PWIDTHA_BLANE+1){1'b0}};

    if ((psel == 1'b1) && (penable == 1'b1) && (pwrite == 1'b1)) begin
        if (paddr[`GPIO_ADDR_SLICE_LHS:`GPIO_ADDR_SLICE_RHS] == `GPIO_SWPORTA_DDR_OFFSET ) begin
                        gpio_swporta_ddr_wen = {(PWIDTHA_BLANE+1){1'b1}};
        end
    end
  end


// Generate Write Enable bus for gpio_swporta_ctl register.




// Generate Write Enable bus for gpio_inten register.

 always @(paddr or psel or penable or pwrite)
  begin : gpio_inten_wen_PROC
    gpio_inten_wen = {(PWIDTHA_BLANE+1){1'b0}};

    if ((psel == 1'b1) && (penable == 1'b1) && (pwrite == 1'b1)) begin
        if (paddr[`GPIO_ADDR_SLICE_LHS:`GPIO_ADDR_SLICE_RHS] == `GPIO_INTEN_OFFSET ) begin
                        gpio_inten_wen = {(PWIDTHA_BLANE+1){1'b1}};
        end
    end
  end

// Generate Write Enable bus for gpio_intmask register.

 always @(paddr or psel or penable or pwrite)
  begin : gpio_intmask_wen_PROC
    gpio_intmask_wen = {(PWIDTHA_BLANE+1){1'b0}};

    if ((psel == 1'b1) && (penable == 1'b1) && (pwrite == 1'b1)) begin
        if (paddr[`GPIO_ADDR_SLICE_LHS:`GPIO_ADDR_SLICE_RHS] == `GPIO_INTMASK_OFFSET ) begin
                        gpio_intmask_wen = {(PWIDTHA_BLANE+1){1'b1}};
        end
    end
  end

// Generate Write Enable bus for gpio_inttype_level register.

   always @(paddr or psel or penable or pwrite)
  begin : gpio_inttype_level_wen_PROC
    gpio_inttype_level_wen = {(PWIDTHA_BLANE+1){1'b0}};

    if ((psel == 1'b1) && (penable == 1'b1) && (pwrite == 1'b1)) begin
        if (paddr[`GPIO_ADDR_SLICE_LHS:`GPIO_ADDR_SLICE_RHS] == `GPIO_INTTYPE_LEVEL_OFFSET ) begin
                        gpio_inttype_level_wen = {(PWIDTHA_BLANE+1){1'b1}};
        end
    end
  end

// ----------------------------------------------------------------------------- //
// ----------------------------------------------------------------------------- //

// Generate Write Enable bus for gpio_int_polarity register.

 always @(paddr or psel or penable or pwrite)
  begin : gpio_int_polarity_wen_PROC
    gpio_int_polarity_wen = {(PWIDTHA_BLANE+1){1'b0}};

    if ((psel == 1'b1) && (penable == 1'b1) && (pwrite == 1'b1)) begin
        if (paddr[`GPIO_ADDR_SLICE_LHS:`GPIO_ADDR_SLICE_RHS] == `GPIO_INT_POLARITY_OFFSET ) begin
                        gpio_int_polarity_wen = {(PWIDTHA_BLANE+1){1'b1}};
        end
    end
  end
 
// ----------------------------------------------------------------------------- //
// ----------------------------------------------------------------------------- //

// Generate Write Enable bus for gpio_ls_sync register.

 always @(paddr or psel or penable or pwrite)
  begin : int_gpio_ls_sync_wen_PROC
    gpio_ls_sync_wen = 1'b0;

    if ((psel == 1'b1) && (penable == 1'b1) && (pwrite == 1'b1)) begin
          if (paddr[`GPIO_ADDR_SLICE_LHS:`GPIO_ADDR_SLICE_RHS] ==
             `GPIO_LS_SYNC_OFFSET ) begin
            gpio_ls_sync_wen = 1'b1;
          end
    end
  end


 always @(paddr or psel or penable or pwrite)
  begin : int_gpio_porta_eoi_wen_PROC
    gpio_porta_eoi_wen = {(PWIDTHA_BLANE+1){1'b0}};

    if ((psel == 1'b1) && (penable == 1'b1) && (pwrite == 1'b1)) begin
        if (paddr[`GPIO_ADDR_SLICE_LHS:`GPIO_ADDR_SLICE_RHS] == `GPIO_PORTA_EOI_OFFSET ) begin
                        gpio_porta_eoi_wen = {(PWIDTHA_BLANE+1){1'b1}};
        end
    end
  end


// Register used to store Software Port A Data register

  always@(posedge pclk or negedge presetn)
  begin : gpio_swporta_dr_PROC
    if (presetn == 1'b0) begin
        gpio_swporta_dr <= SWPORTA_RESET;
    end else begin
      if (gpio_swporta_dr_wen[0] == 1'b1) begin
        gpio_swporta_dr[`GPIO_PWIDTH_A-1:0] <= pwdata_int[`GPIO_PWIDTH_A-1:0];
      end
    end
  end

// Register used to store Software Port A Data Direction register

  always@(posedge pclk or negedge presetn)
  begin : gpio_swporta_ddr_PROC
    if (presetn == 1'b0) begin
        gpio_swporta_ddr <= {`GPIO_PWIDTH_A{1'b0}};
    end else begin
      if (gpio_swporta_ddr_wen[0] == 1'b1) begin
        gpio_swporta_ddr[`GPIO_PWIDTH_A-1:0] <= pwdata_int[`GPIO_PWIDTH_A-1:0];
      end
    end
  end

// Register used to store Software Port A mode control register



// Register used to store Software Port B Data register
// ------------------------------------------------------------------------ //
// ------------------------------------------------------------------------ //

  always@(posedge pclk or negedge presetn)
  begin : gpio_inten_PROC
    if (presetn == 1'b0) begin
        gpio_inten <= {`GPIO_PWIDTH_A{1'b0}};
    end else begin
      if (gpio_inten_wen[0] == 1'b1) begin
        gpio_inten[`GPIO_PWIDTH_A-1:0] <= pwdata_int[`GPIO_PWIDTH_A-1:0];
      end
    end
  end

// Register used to store Interrupt mask for each bit of Port A


  always@(posedge pclk or negedge presetn)
  begin : gpio_intmask_PROC
    if (presetn == 1'b0) begin
        gpio_intmask <= {`GPIO_PWIDTH_A{1'b0}};
    end else begin
      if (gpio_intmask_wen[0] == 1'b1) begin
        gpio_intmask[`GPIO_PWIDTH_A-1:0] <= pwdata_int[`GPIO_PWIDTH_A-1:0];
      end
    end
  end

// Register used to store Interrupt type, level or edge,  for each bit of Port A


  always@(posedge pclk or negedge presetn)
  begin : gpio_inttype_level_PROC
    if (presetn == 1'b0) begin
        gpio_inttype_level <= {`GPIO_PWIDTH_A{1'b0}};
    end else begin
      if (gpio_inttype_level_wen[0] == 1'b1) begin
        gpio_inttype_level[`GPIO_PWIDTH_A-1:0] <= pwdata_int[`GPIO_PWIDTH_A-1:0];
      end
    end
  end

// ------------------------------------------------------------------------ //
// ------------------------------------------------------------------------ //
// Register used to store Interrupt polarity for each bit of Port A


  always@(posedge pclk or negedge presetn)
  begin : gpio_int_polarity_PROC
    if (presetn == 1'b0) begin
        gpio_int_polarity <= {`GPIO_PWIDTH_A{1'b0}};
    end else begin
      if (gpio_int_polarity_wen[0] == 1'b1) begin
        gpio_int_polarity[`GPIO_PWIDTH_A-1:0] <= pwdata_int[`GPIO_PWIDTH_A-1:0];
      end
    end
  end


// ----------------------------------------------------------------------------- //

// ------------------------------------------------------------------------ //
// ------------------------------------------------------------------------ //


// Register used to store level sensitive interrupt synchronization


  always@(posedge pclk or negedge presetn)
  begin : int_gpio_ls_sync_PROC
    if (presetn == 1'b0) begin
        gpio_ls_sync <= 1'b0;
    end else begin
      if (gpio_ls_sync_wen == 1'b1) begin
        gpio_ls_sync <= pwdata_int[0];
      end
    end
  end

// A write to Interrupt clear address generates pulse
// to control logic to clear interrupt.
// No memory  location.

  always@(*)
  begin : gpio_porta_eoi_PROC
        gpio_porta_eoi = {`GPIO_PWIDTH_A{1'b0}};
      if (gpio_porta_eoi_wen[0] == 1'b1) begin
        gpio_porta_eoi[`GPIO_PWIDTH_A-1:0] = pwdata_int[`GPIO_PWIDTH_A-1:0];
      end
    end


// Output of Read back data mux registered and driven onto
// prdata bus.
always @(posedge pclk or negedge presetn)
  begin : prdata_PROC
    if (presetn == 1'b0) begin
      iprdata <= {`APB_DATA_WIDTH{1'b0}};
    end else begin
      if ((pwrite == 1'b0) && (psel == 1'b1) && (penable == 1'b0)) begin
            case (paddr[`GPIO_ADDR_SLICE_LHS:`GPIO_ADDR_SLICE_RHS])
              `GPIO_EXT_PORTA_OFFSET     : iprdata <= { {(32-`GPIO_PWIDTH_A){1'b0}} , gpio_ext_porta_rb  [`GPIO_PWIDTH_A-1:0]};
              `GPIO_SWPORTA_DR_OFFSET    : iprdata <= { {(32-`GPIO_PWIDTH_A){1'b0}} , gpio_swporta_dr    [`GPIO_PWIDTH_A-1:0]};
              `GPIO_SWPORTA_DDR_OFFSET   : iprdata <= { {(32-`GPIO_PWIDTH_A){1'b0}} , gpio_swporta_ddr   [`GPIO_PWIDTH_A-1:0]};
              `GPIO_INTEN_OFFSET         : iprdata <= { {(32-`GPIO_PWIDTH_A){1'b0}} , gpio_inten         [`GPIO_PWIDTH_A-1:0]};
              `GPIO_INTMASK_OFFSET       : iprdata <= { {(32-`GPIO_PWIDTH_A){1'b0}} , gpio_intmask       [`GPIO_PWIDTH_A-1:0]};
              `GPIO_INTTYPE_LEVEL_OFFSET : iprdata <= { {(32-`GPIO_PWIDTH_A){1'b0}} , gpio_inttype_level [`GPIO_PWIDTH_A-1:0]};
              `GPIO_INTSTATUS_OFFSET     : iprdata <= { {(32-`GPIO_PWIDTH_A){1'b0}} , gpio_intstatus     [`GPIO_PWIDTH_A-1:0]};
              `GPIO_RAW_INTSTATUS_OFFSET : iprdata <= { {(32-`GPIO_PWIDTH_A){1'b0}} , gpio_raw_intstatus [`GPIO_PWIDTH_A-1:0]};
              `GPIO_INT_POLARITY_OFFSET  : iprdata <= { {(32-`GPIO_PWIDTH_A){1'b0}} , gpio_int_polarity  [`GPIO_PWIDTH_A-1:0]};

              `GPIO_LS_SYNC_OFFSET       : iprdata <= { {(31){1'b0}} , gpio_ls_sync};
              `GPIO_ID_CODE_OFFSET       : iprdata <= gpio_id_code       [`GPIO_ID_WIDTH-1:0];
              `GPIO_VER_ID_CODE_OFFSET   : iprdata <= gpio_vid;
              `GPIO_CONFIGID_REG2_OFFSET : iprdata <= gpio_configid_reg2;
              `GPIO_CONFIGID_REG1_OFFSET : iprdata <= gpio_configid_reg1;
              default : iprdata <= {`APB_DATA_WIDTH{1'b0}};
            endcase
      end
    end
  end


  always @(iprdata) begin : iprdata_PROC
    prdata = {`APB_DATA_WIDTH{1'b0}};
    prdata[`GPIO_RDATA_WIDTH-1:0] = iprdata[`GPIO_RDATA_WIDTH-1:0];
  end


endmodule
