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
// File Version     :        $Revision: #17 $ 
// Revision: $Id: //dwh/DW_ocb/DW_apb_gpio/amba_dev/src/DW_apb_gpio_ctrl.v#17 $ 
--
-- File :                       DW_apb_gpio_ctrl.v
//
//
-- Abstract     :               Control block for DW_apb_gpio
--
--
------------------------------------------------------------------------
*/

// This module consists of pclk (APB CLOCK) and pclk_intr(APB INTERRUPT CLOCK) and dbclk (Debounce clock)
// based on the configuration and it is design intent.
// This module consists of presetn (APB Reset) and dbclk_res (Debounce reset)
// based on the configuration and it is design intent.

module i_gpio_DW_apb_gpio_ctrl (
   gpio_swporta_dr// Port A data
                         
                         ,gpio_swporta_ddr// Port A data direction
                         
                         ,gpio_porta_dr// Output data
                         
                         ,gpio_porta_ddr// Data direction control
                         
                         ,gpio_ext_porta// Input data
                         
                         ,gpio_ext_porta_rb// Input data internal readback
                         
                         ,pclk// APB Clock
                         
                         ,presetn// APB Reset
                         
                         ,pclk_intr// APB Clock used for interrupt detection
                         
                         ,gpio_inten// Interrupt Enable
                         
                         ,gpio_intmask// Interrupt Mask
                         
                         ,gpio_inttype_level// Interrupt Level
                         
                         ,gpio_porta_eoi// Port A interrupt clear
                         
                         ,gpio_ls_sync// Level sensitive synchronisation enable
                         
                         ,gpio_int_polarity// Interrupt Polarity
                         
                         ,gpio_intr_n// Active low inter bus
                         
                         ,gpio_intr_int// Interrupt status
                         
                         ,gpio_raw_intstatus// Unmasked interrupt status
                         
                         ,gpio_intrclk_en// Indicates pclk must run to detect interrupts
                         
                         );

   input  pclk;
   input  presetn;
   input  pclk_intr;
   input [`GPIO_PWIDTH_A-1:0] gpio_inten;
   input [`GPIO_PWIDTH_A-1:0] gpio_intmask;
   input [`GPIO_PWIDTH_A-1:0] gpio_inttype_level;
   input [`GPIO_PWIDTH_A-1:0] gpio_porta_eoi;
   input                      gpio_ls_sync;
   input [`GPIO_PWIDTH_A-1:0] gpio_ext_porta;
   input [`GPIO_PWIDTH_A-1:0] gpio_swporta_dr;
   input [`GPIO_PWIDTH_A-1:0] gpio_swporta_ddr;
   input [`GPIO_PWIDTH_A-1:0] gpio_int_polarity;
   output [`GPIO_PWIDTH_A-1:0] gpio_intr_int;
   output [`GPIO_PWIDTH_A-1:0] gpio_raw_intstatus;
   output                      gpio_intrclk_en;
   output [`GPIO_PWIDTH_A-1:0] gpio_intr_n;                                
   output [`GPIO_PWIDTH_A-1:0] gpio_porta_dr;
   output [`GPIO_PWIDTH_A-1:0] gpio_porta_ddr;
   output [`GPIO_PWIDTH_A-1:0] gpio_ext_porta_rb;

   reg   [`GPIO_PWIDTH_A-1:0] gpio_ext_porta_int;
   reg   [`GPIO_PWIDTH_A-1:0] int_sy_in;
   reg   [`GPIO_PWIDTH_A-1:0] ls_int_in;
   reg   [`GPIO_PWIDTH_A-1:0] gpio_intr_ed_pm;
   reg   [`GPIO_PWIDTH_A-1:0] int_gpio_raw_intstatus;
   wire  [`GPIO_PWIDTH_A-1:0] gpio_intr_int;
   wire  [`GPIO_PWIDTH_A-1:0] gpio_raw_intstatus;
   wire                       gpio_intrclk_en_int;
   reg                        gpio_intrclk_en;
   reg   [`GPIO_PWIDTH_A-1:0] intrclk_en;
   wire  [`GPIO_PWIDTH_A-1:0] gpio_intr_n;                                 
   reg   [`GPIO_PWIDTH_A-1:0] ed_out;
   wire  [`GPIO_PWIDTH_A-1:0] ed_rf;
   reg   [`GPIO_PWIDTH_A-1:0] ed_int_d1;
   wire  [`GPIO_PWIDTH_A-1:0] int_in;
   wire  [`GPIO_PWIDTH_A-1:0] int_pre_in;





   wire [`GPIO_PWIDTH_A-1:0] gpio_porta_dr;
   wire [`GPIO_PWIDTH_A-1:0] gpio_porta_ddr;
   wire [`GPIO_PWIDTH_A-1:0] gpio_ext_porta_s;

   reg  [`GPIO_PWIDTH_A-1:0] gpio_ext_porta_rb;



   integer int_k ;


  always @(gpio_ext_porta_int) 
  begin : int_sy_in_DEB0_PROC
  integer i;
    int_sy_in = {`GPIO_PWIDTH_A{1'b0}};
    int_sy_in = gpio_ext_porta_int;
  end // always




// Input is inverted for falling edge or active low 
// sensitive interrupts.Allows same de-bounce and edge detect
// circuitry to be used regardless of polarity. 

  always @(gpio_ext_porta or gpio_int_polarity) 
  begin : gpio_ext_porta_int_PROC
  integer i;
    gpio_ext_porta_int = {`GPIO_PWIDTH_A{1'b0}};

    for ( i = 0 ; i < `GPIO_PWIDTH_A ; i=i+1 ) begin
      if(gpio_int_polarity[i] == 1'b0)
        gpio_ext_porta_int[i] =  ~gpio_ext_porta[i] ;
      else
        gpio_ext_porta_int[i] =  gpio_ext_porta[i] ;
    end // for
  end // always 

  
  
   wire  [`GPIO_PWIDTH_A-1:0] db2pil_int_sy_in;
   wire  [`GPIO_PWIDTH_A-1:0] sdb2pil_int_pre_in;

// Meta-stabilty registers. Synchronize to pclk_intr. 
  i_gpio_DW_apb_gpio_bcm21
   #(.WIDTH(`GPIO_PWIDTH_A)) U_DW_apb_gpio_bcm21_db2pil_int_sy_in_pisyzr
      (
         .clk_d               (pclk_intr)
        ,.rst_d_n             (presetn)
        ,.init_d_n            (1'b1)
        ,.test                (1'b0)
        ,.data_s              (db2pil_int_sy_in)
        ,.data_d              (sdb2pil_int_pre_in)
      );

   assign db2pil_int_sy_in = int_sy_in;
   assign int_pre_in = sdb2pil_int_pre_in;

// ---------------------------------------------------------------------------- //
// ---------------------------------------------------------------------------- //


  assign int_in = int_pre_in;

//  edge detect circuitry. 

  always @(posedge pclk_intr or negedge presetn)
  begin : ed_int_d1_PROC
    if(presetn == 1'b0)
      ed_int_d1 <= {`GPIO_PWIDTH_A{1'b0}};
    else
      ed_int_d1 <= int_in;
  end

  assign ed_rf = int_in ^ ed_int_d1;

// Rising edge detect 

  always @(ed_rf or int_in) 
  begin : ed_out_PROC
  integer j;
  ed_out = {`GPIO_PWIDTH_A{1'b0}};

    for ( j = 0 ; j < `GPIO_PWIDTH_A ; j=j+1 ) begin
      ed_out[j] =  ed_rf[j] & int_in[j] ; 
    end // for
  end // always


// gpio_intrclk_en output asserted if any bit of port a is enabled for 
// edge sensitive interrupts or any bit of port a is enabled for 
// level sensitive interrupts and level sensitive synchronisation is required. 

always @(gpio_inttype_level or gpio_ls_sync or gpio_inten
)
  begin : intrclk_en_PROC
  integer i;
    for ( i = 0 ; i < `GPIO_PWIDTH_A ; i=i+1 ) begin
      if(gpio_inten[i] == 1'b1)
        if((gpio_inttype_level[i] == 1'b1)
          )
          intrclk_en[i] =  1'b1 ;
        else
          intrclk_en[i] = gpio_ls_sync;
      else
        intrclk_en[i] =  1'b0 ;
    end // for
  end // always 

   assign gpio_intrclk_en_int = | intrclk_en;

  always @(posedge pclk or negedge presetn)
  begin : gpio_intrclk_en_PROC
    if(presetn == 1'b0)
      gpio_intrclk_en <= 1'b0;
    else
      gpio_intrclk_en <= gpio_intrclk_en_int;
  end


always @(posedge pclk_intr or negedge presetn)
  begin : gpio_intr_ed_pm_PROC
      if(presetn == 1'b0)
        gpio_intr_ed_pm  <= {`GPIO_PWIDTH_A{1'b0}};
      else
        for ( int_k = 0 ; int_k < `GPIO_PWIDTH_A ; int_k=int_k+1 ) begin
          if(gpio_inten[int_k] == 1'b0)
            gpio_intr_ed_pm[int_k] <= 1'b0;
          else begin
            if ( (ed_out[int_k] == 1'b1) &&
               (gpio_inten[int_k] == 1'b1) && 
               (gpio_swporta_ddr[int_k] == 1'b0) 
               )
            gpio_intr_ed_pm[int_k] <= 1'b1;
          else
            if (gpio_porta_eoi[int_k] == 1'b1)
              gpio_intr_ed_pm[int_k] <= 1'b0;
        end
      end // for
  end // always 
 

// Level senistive interrupts may pass through synchronization 
// and debounce logic. Under S/W control.
// Interrupts can only be set when direction is input and in
// software mode. 


  always @(int_in or int_sy_in or gpio_ls_sync 
           or gpio_swporta_ddr) 
  begin : ls_int_in_PROC
  integer k;
  ls_int_in = {`GPIO_PWIDTH_A{1'b0}};
    for ( k = 0 ; k < `GPIO_PWIDTH_A ; k=k+1 ) begin
      if(((gpio_swporta_ddr[k]) == 1'b1) 
        )
        ls_int_in[k] = {1'b0};
      else
        if(gpio_ls_sync == 1'b1)
          ls_int_in[k] = int_in[k];
        else
          ls_int_in[k] = int_sy_in[k];
     end // for
  end // always
  

 
  
// Level or edge sensitive interrupts 

  always @(gpio_inttype_level or ls_int_in or gpio_intr_ed_pm 
          or gpio_inten ) 
  begin : int_gpio_raw_intstatus_PROC
  integer l;
  int_gpio_raw_intstatus = {`GPIO_PWIDTH_A{1'b0}};
    for ( l = 0 ; l < `GPIO_PWIDTH_A ; l=l+1 ) begin
       if(gpio_inten[l] == 1'b0)
          int_gpio_raw_intstatus[l] = 1'b0 ;
       else begin
         if(gpio_inttype_level[l] == 1'b1)
             int_gpio_raw_intstatus[l] = gpio_intr_ed_pm[l] ;
        else
           int_gpio_raw_intstatus[l] = ls_int_in[l] ;
      end  // else
    end  // for
  end  // always 


  assign gpio_raw_intstatus = int_gpio_raw_intstatus;

  assign gpio_intr_int      = gpio_raw_intstatus & (~gpio_intmask); 
  assign gpio_intr_n        = ~gpio_intr_int;

// End of Interrupt generation logic


// ------------------------------------------------------------------------- //
// PORT-A PROCEDURES
// ------------------------------------------------------------------------- //

// aux port in generation : Sychronisation of aux_portx_in data to pclk is under S/W control.
// aux_portx_in data is masked with gpio_swportx_ctl register
 
  assign gpio_porta_dr  = gpio_swporta_dr ;
  assign gpio_porta_ddr = gpio_swporta_ddr;


// Meta - stability registers when reading back external ports in software
// Synchronisation of readback data under software control



   assign gpio_ext_porta_s = gpio_ext_porta;

// -------------------------------------------------------------------------- //










// ------------------------------------------------------------------------- //

      
// Read back data for gpio_ext_port register. When Port is output 
// then readback data equal to gpio_swport_dr. When port is input 
// then it is the data input on the external ports. 



  always @(gpio_ext_porta_s)
  begin : gpio_ext_porta_rb_mux0_PROC
  integer i;
  gpio_ext_porta_rb = {`GPIO_PWIDTH_A{1'b0}};
    for ( i = 0 ; i < `GPIO_PWIDTH_A ; i=i+1 ) begin
      gpio_ext_porta_rb[i] = gpio_ext_porta_s[i];
    end // for
  end  // always    


// ------------------------------------------------------------------------- //
// ------------------------------------------------------------------------- //
      

endmodule 

// reuse-pragma endSub   CTRL_WAVIER 

