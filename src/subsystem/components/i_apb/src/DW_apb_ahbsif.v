//------------------------------------------------------------------------
//--
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
// File Version     :        $Revision: #20 $ 
// Revision: $Id: //dwh/DW_ocb/DW_apb/amba_dev/src/DW_apb_ahbsif.v#20 $ 
//--
//-- File :                       DW_apb_ahbsif
//-- Author:                      Chris Gilbert, Peter Gillen
//-- Date :                       $Date: 2016/10/06 $
//-- Abstract     :               AHB Slave interface state machine.
//----------------------------------------------------------------------

module i_apb_DW_apb_ahbsif (
                        hclk, 
                      hresetn, 
                      pclk_en,
                      haddr, 
                      hready, 
                      hsel,
                      htrans, 
                      hwrite, 
                      hwdata_max,
                      hready_resp, 
                      hresp,
                      paddr,
                      penable, 
                      psel_en,
                      pwdata_int, 
                      pwrite
                      );


  input [`HADDR_WIDTH_INT-1:0]  haddr;      // AHB address
  input                         hclk;       // AHB system clock
  input                         hresetn;    // AHB system reset
  input                         hready;     // AHB handshake signal
  input                         hsel;       // AHB slave select signal
  input [`HTRANS_WIDTH-1:0]     htrans;     // AHB transfer control
  input [`AHB_DATA_WIDTH-1:0] hwdata_max; // AHB read data
  input                         hwrite;     // AHB write/not read signal
  input                         pclk_en;    // pclk enable strobe



  output                        hready_resp; // AHB handshake
  output [`HRESP_WIDTH-1:0]     hresp;      // AHB slave response
  output [`PADDR_WIDTH-1:0]     paddr;      // APB address bus
  output                        penable;    // APB penable signal
  output                        psel_en;    // APB frame strobe
  output [`HWDATA32_WIDTH-1:0]  pwdata_int; // 32 bit APB write data
  output                        pwrite;     // APB write signal


  // aaraujo @ 05/05/2010 CRM_9000464282

//
// output registers
//

  reg                           hready_resp;
  reg [`PADDR_WIDTH-1:0]        paddr;
  reg                           penable;
  reg                           psel_en;
  reg [`HWDATA32_WIDTH-1:0]     pwdata_int;
  reg                           pwrite;

//
// output wires
//

  wire [`HRESP_WIDTH-1:0]       hresp;

  wire [`HRESP_WIDTH-1:0]       hresp_temp;
  reg  [`HRESP_WIDTH-1:0]       hresp_reg_s1;
  reg  [`HRESP_WIDTH-1:0]       hresp_reg_s2;

//
// Internal wires
//

  wire                          ahb_activity;
  wire                          ahb_owner;
  wire                          ahb_valid;


  wire [`PADDR_WIDTH-1:0]       paddr_c;
  wire                          pwrite_c;
  wire                          piped_ahb_trans_ver_c;
  wire [`HWDATA32_WIDTH-1:0]    pwdata_int_c;
  wire                          use_saved_c;
  wire                          piped_hwrite_c;
  wire [`HWDATA32_WIDTH-1:0]    saved_hwdata32_c;
  wire                          pipeline_c;
  wire [`HADDR_WIDTH_INT-1:0]   piped_haddr_c;
  wire [`HADDR_WIDTH_INT-1:0]   saved_haddr_c;
//
// Internal registers
//

  reg [`HWDATA32_WIDTH-1:0]     hwdata32;
  reg [`HADDR_WIDTH_INT-1:0]    piped_haddr;
  reg                           pipeline;
  reg [`HADDR_WIDTH_INT-1:0]    saved_haddr;
  reg                           use_saved;

//
// state registers
//
  reg [2:0]                     nextstate;
  reg [2:0]                     state;
  wire                          ew_and_pl;
  wire                          sw_and_pl;
  reg                           use_saved_data;
  reg                           piped_hwrite;
  reg [`HWDATA32_WIDTH-1:0]     saved_hwdata32;
  reg                           piped_ahb_trans_ver;


  wire [15:0]                   ahb_trans_ver_tmp;
  wire                          ahb_trans_ver;
  // aaraujo @ 05/05/2010: CRM_9000464282



//
// Want to assign states to code names and to numbers.
//
  parameter CS  = 3'b000;  // Check State
  parameter WW  = 3'b001;  // Wait Write
  parameter SW  = 3'b010;  // Setup Write
  parameter EW  = 3'b011;  // Enable Write
  parameter WR  = 3'b100;  // Wait Read
  parameter SR  = 3'b101;  // Setup Read
  parameter ER  = 3'b110;  // Enable Read

//
// Need to know if the transaction on the bus is for APB or not.
// If it is then is there a transfer on the bus. Combined one knows
// if there is valid activity on the bus and one must act on this
//

  assign ahb_owner = hsel & hready;
  assign ahb_activity = ((htrans != `IDLE)   && (htrans != `BUSY));
  assign ahb_valid    = ((ahb_owner == 1'b1) && (ahb_activity == 1'b1));


//
// aaraujo @ 3/12/2010: 9000260778
// ahb_trans_ver asserts when a new a transfer request comes into
// the bus targeting an APB3 Slave. In those cases the bus should
// only process the issued transfer and cannot pipeline any other
// transfer (DW_apb brings hready_resp low). Otherwise the master
// wouldn't be able to keep track pslverr in the correct address.
//

//This wire contains max number of bits and the signal is used only in the case of the APB slave being APB3.
//Hence the corresponsing bits will not be used in the configurations where either the slave is absent or is not APB3.
  assign ahb_trans_ver_tmp[0] = 1'b0;
  assign ahb_trans_ver_tmp[1] = 1'b0;
  assign ahb_trans_ver_tmp[2] = 1'b0;
  assign ahb_trans_ver_tmp[3] = 1'b0;
  assign ahb_trans_ver_tmp[4] = 1'b0;
  assign ahb_trans_ver_tmp[5] = 1'b0;
  assign ahb_trans_ver_tmp[6] = 1'b0;
  assign ahb_trans_ver_tmp[7] = 1'b0;
  assign ahb_trans_ver_tmp[8] = 1'b0;
  assign ahb_trans_ver_tmp[9] = 1'b0;
  assign ahb_trans_ver_tmp[10] = 1'b0;
  assign ahb_trans_ver_tmp[11] = 1'b0;
  assign ahb_trans_ver_tmp[12] = 1'b0;
  assign ahb_trans_ver_tmp[13] = 1'b0;
  assign ahb_trans_ver_tmp[14] = 1'b0;
  assign ahb_trans_ver_tmp[15] = 1'b0;
  assign ahb_trans_ver = ((|ahb_trans_ver_tmp) & ahb_valid);



//
// aaraujo @ 3/12/2010: 9000260778
// Similar to the address, DW_apb needs to keep the control
// signal on whether the transfer is for an APB3 or APB2
//
assign piped_ahb_trans_ver_c = piped_ahb_trans_ver;
  always @(posedge hclk or negedge hresetn)
    begin : piped_ahb_trans_ver_PROC
      if (hresetn == 1'b0) begin
        piped_ahb_trans_ver <= 1'b0;
      end else begin
        case (state)
          WW, SW, EW : if (ahb_valid == 1'b1) begin
                        piped_ahb_trans_ver <= ahb_trans_ver;
                       end
          default    : piped_ahb_trans_ver <= piped_ahb_trans_ver_c;
        endcase
      end
    end  // piped_ahb_trans_ver_PROC

  //Response is always OKAY  for APB2 slave and can be ERROR or OKAY depending on pslverr for APB3 slaves.
  assign hresp_temp = `OKAY;


//
// aaraujo @ 2010/12/03: 9000260778
// ERROR response should last for 2 hclk cycles meaning that
// we can set the hresp signal to OKAY after the second hclk
// cycle regardeless the clock ratio. If hclk=pclk, after the
// the 2nd hclk cycle of an ERROR response we are sure there
// won't be any APB Slave trying to respond.
//
  always @ (posedge hclk or negedge hresetn)
    begin : hresp_PROC
      if (hresetn == 1'b0) begin
        hresp_reg_s1 <= 2'b00;
        hresp_reg_s2 <= 2'b00;
      end else begin
        hresp_reg_s1 <= hresp_temp;
        hresp_reg_s2 <= hresp_reg_s1;
      end
    end

  assign hresp = (hresp_temp | hresp_reg_s1) & (~hresp_reg_s2);


//
// Extract the select lines for the data slicer
//


//
// extract 32 bit slices from the AHB bus
// only 32 bit hwdata registered in the DW_apb
//
  always @(*)
    begin : hwdata_032bit_PROC
      hwdata32=hwdata_max[31:0];
    end // always block

//
// PADDR is only changed on a pclk_en active edge
//
// When generating the PADDR, need to know where one is and where one is
// going to which determines whether a saved address or the current
// address on the address bus, or a pipelined address is taken and sent
// to the APB bus as the peripheral address. If we have a single write
// then  the address comes at least 1 cycle before data and one must
// save the address to align with the data. For the case of consecutive
// writes where they are pipelined, the address is stored within the
// pipeline. One can have up to three writes running within the APB at
// any one time. The address information is streamlined and the saved
// address is recycled for use in this case to avoid unnecessary
// registers. Hence one needs to know when to use saved for its normal
// use which is to align address with data, and for the efficient
// operation of the AHB bus.
//
// The relevant LSBs for paddr is suppresses for writes. This supression
// doesnot affect paddr in APB2/APB3 operation as these bits are already 
// zero due to byte alignment. In APB4 mode, a high on any supressed bits
// indicate write strobing which is taken care of by the pstrb bits. The 
// address should still remain byte aligned in the APB side.
  assign paddr_c = paddr;
  always @ (posedge hclk or negedge hresetn)
    begin : paddr_PROC
      if (hresetn == 1'b0) begin
        paddr <= {`PADDR_WIDTH{1'b0}};
      end else begin
        if (pclk_en == 1'b1) begin
          case (nextstate)
            SW      : begin
                      if (use_saved == 1'b1) begin
                        paddr    <= { saved_haddr[`PADDR_WIDTH-1:`APB_DATA_WIDTH/16] , {(`APB_DATA_WIDTH/16){1'b0}} };
                      end else begin
                        paddr    <= { piped_haddr[`PADDR_WIDTH-1:`APB_DATA_WIDTH/16] , {(`APB_DATA_WIDTH/16){1'b0}} };
                      end
                      end
            SR      : begin
                        case (state)
                          WR      : if (pipeline == 1'b1)
                                      paddr <= piped_haddr;
                                    else
                                      paddr <= saved_haddr;
                          EW      : if (ahb_valid == 1'b1)
                                      paddr <= haddr;
                                    else
                                      paddr <= piped_haddr;
                          default : paddr <= haddr;
                        endcase
                      end
            default : begin
                        paddr    <= paddr_c;
                      end
          endcase
        end
      end
    end // paddr_PROC



//
// PENABLE is only changed on a pclk_en active edge
//
// Only when we are leaving one of the setup states is penable set.
// Principle applies for both read and write
//

  always @ (posedge hclk or negedge hresetn)
    begin : penable_PROC
      if (hresetn == 1'b0) begin
        penable <= 1'b0;
      end else begin
        if (pclk_en == 1'b1) begin
          case (state)
            SW, SR  : penable <= 1'b1;

            //
            // aaraujo @ 2010/12/03: 9000260778
            // On APB3 penable must be extended along with
            // the transfers. While in EW and ER states
            // penable must remain asserted until pready
            // is sampled high
            //
            EW, ER: begin
                         penable <= 1'b0;
                    end

            default : penable <= 1'b0;
          endcase
        end
      end
    end  // penable_PROC

//
// PWRITE is only changed on a pclk_en active edge
//
// Only when we are to enter the setup write state do we set the pwrite.
// It is reset when we are about to enter the setup read state.
// It is held stable at all other times. Retains its last value even
// when there is no activity on the APB bus
//

  assign pwrite_c = pwrite;
  always @ (posedge hclk or negedge hresetn)
    begin : pwrite_PROC
      if (hresetn == 1'b0) begin
        pwrite <= 1'b0;
      end else begin
        if (pclk_en == 1'b1) begin
          case (nextstate)
            SW      : pwrite <= 1'b1;
            SR      : pwrite <= 1'b0;
            default : pwrite <= pwrite_c;
          endcase
        end
      end
    end  // pwrite_PROC

//
// PWDATA_INT is only changed on a pclk_en active edge. If one is
// operating in an environment where the PCLK is slower than the
// hclk, a write instruction can complete inbetween two pclk edges.
// One saves the address to align with the data, plus the data
// needs to be saved to align with the next pclk edge. This data
// is only changed when we are to enter the setup write (SW) state.
// hready may come along while one is waiting for pclk_en and if
// so the data is saved and needs to be used.
//
  
// DC will synthesize this code correctly.
  assign pwdata_int_c = pwdata_int;
  always @ (posedge hclk or negedge hresetn)
    begin : pwdata_PROC
      if (hresetn == 1'b0) begin
        pwdata_int <= {`HWDATA32_WIDTH{1'b0}};
      end else begin
        if (pclk_en == 1'b1) begin
          case (nextstate)
            SW      : if (state == WW)
                        if (use_saved_data == 1'b1)
                          pwdata_int <= saved_hwdata32;
                        else
                          pwdata_int <= hwdata32;
                      else
                        pwdata_int <= hwdata32;
            default : pwdata_int <= pwdata_int_c;
          endcase
        end
      end
    end  // pwdata_PROC

//
// PSEL_EN is only changed on a pclk_en active edge
// Set when one is to enter one of the setup states and
// keep set when one enters one of the enable states.
// Frames the APB transfer
//

  always @ (posedge hclk or negedge hresetn)
    begin : psel_en_PROC
      if (hresetn == 1'b0) begin
        psel_en <= 1'b0;
      end else begin
        if (pclk_en == 1'b1) begin
          case (nextstate)
            SW, EW,
            SR, ER  : psel_en <= 1'b1;
            default : psel_en <= 1'b0;
          endcase
        end
      end
    end  // psel_en_PROC

    

//
// HREADY_RESP can change on a hclk edge.
// Different rules for generation apply for reads and writes, with the
// goal of keeping the AHB running efficiently. Depending on where one
// is and whether there is data in a pipeline and if there is a valid
// address for APB on  the bus the hready_resp is used to control the
// master in its delivery of data or in its receipt of data. Write
// transfers are allowed complete with no delay unless there are of
// course consective writes. While sometimes one waits for activity
// on the bus one also needs to consider when the read data is
// available and not to hold up the bus for too long. Therefore the
// hready_resp is not completely controlled by pclk_en.
//

//
// aaraujo @ 3/12/2010: 9000260778
// The following comments refers to the changes implemented to the
// hready_resp signal generation in order to accomodate transfers
// to APB3 Slaves
//
// CS:
// When AHB sends a new transfer to an APB3 Slave (ahb_trans_ver=1)
// DW_apb must bring hready_resp low immediately
//
// EW:
// EW -> WW transaction occurs when ahb_valid goes high. This
// means that an APB transfer is completing and a new one is
// sent from AHB. If the new transfer sent from AHB targets an
// APB3 Slave (ahb_trans_ver== 1'b1), then hready_resp should
// goes low until the new issued transfer is completed on the
// APB side
//
// EW -> SW
// If a pipelined APB3 transfer is about to be processed
// (apb_trans_ver=1) hready_resp should be blocked from
// asserting. Since hready_resp asserts one hclk cycle after
// EW, if APB2 transfer is issued following by an APB3 transfer
// hready_resp can assert in the time the APB3 Slave is
// processing. In the case of an error condition the AHB
// master won't be able to determine corretly from which
// Slave does the error response refers to.
//
// EW -> EW:
// ER -> ER:
// On APB EW states are extended along with the transfers.
//
// SR:
// On APB2, if state=SR, and pclk_en=1'b1, the nextstate will
// be ER. Then hready_resp should assert so that in the next
// hclk data can be samples on AHB bus. On APB3 ER can last for
// more than one hclk cycle and hready_resp can only assert in
// the last cycle.
//
// On APB2 the read transfers, hready asserts along with the
// the data phase as one knows the transfer in APB side will
// only last for two cycles. On APB3 hready_resp will assert
// while in ER state
//

  always @ (posedge hclk or negedge hresetn)
    begin : hready_resp_PROC
      if (hresetn == 1'b0) begin
        hready_resp <= 1'b1;
      end else begin
        case (state)

          CS      : if ((nextstate == SR) || (nextstate == WR) || (ahb_trans_ver))
                      hready_resp <= 1'b0;
                    else
                      hready_resp <= 1'b1;

          WW        :  if (ahb_valid   == 1'b1) hready_resp <= 1'b0;

          SW         : 
                         if ((ahb_valid == 1'b1))
                            hready_resp <= 1'b0;
                         else if ((nextstate == EW) && (pipeline == 1'b1))
                            hready_resp <= 1'b0;

          EW  : case (nextstate)

                      WW      : if ((pipeline == 1'b1) | (ahb_trans_ver== 1'b1))
                                  hready_resp <= 1'b0;

                      WR, SR  : hready_resp <= 1'b0;

                      SW      : if (piped_ahb_trans_ver == 1'b1) hready_resp <= 1'b0;

                      EW      : hready_resp <= 1'b0;
                      default : hready_resp <= 1'b1;
                    endcase
          ER      : case (nextstate)
                      WR, SR: hready_resp <= 1'b0;

                      WW    : if ((pipeline == 1'b1) | (ahb_trans_ver== 1'b1))
                                 hready_resp <= 1'b0;

                      SW      : if (piped_ahb_trans_ver == 1'b1) hready_resp <= 1'b0;

                      ER      : hready_resp <= 1'b0;

                      default : hready_resp <= 1'b1;
                    endcase
          WR      : hready_resp <= 1'b0;

          SR      : 
              if ((pclk_en == 1'b1))
        hready_resp <= 1'b1;

          default : hready_resp <= 1'b0;
        endcase
      end
    end  // hready_resp_PROC


//
// pipeline is only reset on a pclk_en active edge, unless we have
// no activity on the bus and we are not about to enter wait read (WR)
// pipeline can be set on a hclk edge
// Need to keep track whether there is new command information in the
// pipeline that is being held off until the APB transfer completes.
// Pipeline is flushed and refilled to keep AHB moving. Can have
// three writes running in pipeline.
//

  assign pipeline_c = pipeline;
  always @(posedge hclk or negedge hresetn)
    begin : pipeline_PROC
      if (hresetn == 1'b0) begin
        pipeline <= 1'b0;
      end else begin
        if (pclk_en == 1'b0) begin
          case (state)
            WW, SW  : if (ahb_valid == 1'b1)
                        begin
                          pipeline <= 1'b1;
                        end
            //
            // aaraujo @ 3/12/2010: 9000260778
            // For APB3 transfers the EW state can last for more than one hclk cycle.
            // So, pipeline must remain asserted while the transfer does not complete
            // on the APB bus
            //
            EW      : if ((ahb_valid == 1'b0) && (nextstate != WR) && (nextstate != EW))
                        begin
                          pipeline <= 1'b0;
                        end
                      else if ((ahb_valid == 1'b1) && (nextstate == WR))
                        begin
                          pipeline <= 1'b1;
                        end
            CS      : pipeline <= 1'b0;
            default : pipeline <= pipeline_c;
          endcase
        end else begin
          case (state)
            WW, SW  : if (ahb_valid == 1'b1)
                        pipeline <= 1'b1;
            //
            // aaraujo @ 3/12/2010: 9000260778
            // For APB3 transfers the EW state can last for more than one hclk cycle.
            // So, pipeline must remain asserted while in this state
            //
            EW      : if ((ahb_valid == 1'b0) && (nextstate != EW))
                        pipeline <= 1'b0;
                      else
            //
            // aaraujo @ 3/12/2010: 9000260778
            // Same analysis: pipeline should remain asserted while the transfer does not
            // complete on APB bus. If so the paddr signal of a read transfer (happening
            // right after a write) would be updated with the value on haddr instead of
            // using piped_addr
            //
                        if ((piped_hwrite == 1'b0) && (nextstate != EW))
                          pipeline <= 1'b0;

            //
            // aaraujo @ 3/12/2010: 9000260778
            // On APB2 the EW used to last only one hclk cycle so that if there
            // is no new transfer in the bus (ahb_valid=0), the pipeline should
            // deassert at that stage.
            // On APB3 the FSM can remain in EW for multiple hclk cycles. If a
            // new write transfer arrives into the bus while the APB is still
            // processing (pready=0), pipeline must assert.
            //
                        else if ((ahb_valid == 1'b1) && (nextstate == EW))
                              pipeline <= 1'b1;

            WR,
            CS      : pipeline <= 1'b0;
            default : pipeline <= pipeline_c;
          endcase
        end

      end
    end  // pipeline_PROC
//
// Need to store the current AHB address whenever one is in either
// wait for write (WW) or enable write (EW) if there is valid
// activity on the bus. This is required to keep AHB activity on
// the bus running smoothly.
//

  assign piped_haddr_c = piped_haddr;
  always @(posedge hclk or negedge hresetn)
    begin : piped_haddr_PROC
      if (hresetn == 1'b0) begin
        piped_haddr <= {`HADDR_WIDTH_INT{1'b0}};
      end else begin
        case (state)
          WW,
          SW, EW  : if (ahb_valid == 1'b1)
                      piped_haddr <= haddr;
          default : piped_haddr <= piped_haddr_c;
        endcase
      end
    end  // piped_haddr_PROC

//
// Need to align the address to the data for a APB write. Also
// reuse this register to assist in pipelining of up to 3
// consecutive writes. This along with use_saved controls the
// operation of flushing the pipeline.
//

//
// As the process is clocked an else condition is not required

// DC will synthesize this code correctly
  assign saved_haddr_c = saved_haddr;
  always @(posedge hclk or negedge hresetn)
    begin : saved_haddr_PROC
      if (hresetn == 1'b0) begin
        saved_haddr <= {`HADDR_WIDTH_INT{1'b0}};
      end else begin
        case (nextstate)
          WW : if ((state == CS) || (state == ER))
                 saved_haddr <= haddr;
               else
                 if (state == EW)
                   if (pipeline == 1'b1)
                     saved_haddr <= piped_haddr;
                   else
                     saved_haddr <= haddr;
          WR : if ((state == CS) || (state == ER))
                 saved_haddr <= haddr;
          default : saved_haddr <= saved_haddr_c;
        endcase
      end
    end  // saved_haddr_PROC

//
// As well as the address need to keep the control signal for
// write/read aligned within the pipeline. Updated at the same
// time as the address.
//

  assign piped_hwrite_c = piped_hwrite;
  always @(posedge hclk or negedge hresetn)
    begin : piped_hwrite_PROC
      if (hresetn == 1'b0) begin
        piped_hwrite <= 1'b0;
      end else begin
        case (state)
          WW, SW, EW : if (ahb_valid == 1'b1) begin
                        piped_hwrite <= hwrite;
                       end
          default    : piped_hwrite <= piped_hwrite_c;
        endcase
      end
    end  // piped_hwrite_PROC

//
// Need to keep the AHB write data to have it when we are aligned
// to the pclk edge so that the APB address and data are AMBA
// compliant and both change at the same time when PENABLE is low
// and are kept for entire APB cycle. Need to know that we are
// waiting for the pclk edge by looking at nextstate and state
// If one has stored off the data which happens in the first cycle
// of state == WW and nextstate == WW then do not want to overwrite
// it until it is used.
//
  assign ew_and_pl = (state == EW) && (pipeline == 1'b1);
  assign sw_and_pl = (state == SW) && (pipeline == 1'b1);

  assign saved_hwdata32_c = saved_hwdata32;
  always @(posedge hclk or negedge hresetn)
    begin : saved_hwdata32_PROC
      if (hresetn == 1'b0) begin
        saved_hwdata32 <= {`HWDATA32_WIDTH{1'b0}};
      end else begin
        if (use_saved_data == 1'b1) begin
          saved_hwdata32 <= saved_hwdata32_c;
        end else begin
          case (nextstate)
            WW      : if ((state == WW) || (ew_and_pl == 1'b1))
                        saved_hwdata32 <= hwdata32;
            EW      : if (sw_and_pl == 1'b1)
                        saved_hwdata32 <= hwdata32;
            default : saved_hwdata32 <= saved_hwdata32_c;
          endcase
        end
      end
    end // saved_hwdata32_PROC

//
// use_saved: Controls the use of saved and piped addresses, as we
// can have up to 3 write instructions running at any one time.
// While storing in the pipeline we also have the delayed write
// address available to keep the AHB running efficiently.
//
  assign use_saved_c = use_saved;
  always @(posedge hclk or negedge hresetn)
    begin : use_saved_PROC
      if (hresetn == 1'b0) begin
        use_saved <= 1'b0;
      end else begin
        case (nextstate)
          WW      : if ((state == CS) || (state == EW) || (state == ER))
                      use_saved <= 1'b1;
          SW      : if (state == WW)
                      use_saved <= 1'b0;               
          default : use_saved <= use_saved_c;
        endcase
      end
    end // use_saved_PROC

//
// use_saved_data: One may have the data before the rising edge of pclk
// need to grab the data on the port and then hold it. Only generate
// it if one is saving the address and if the pclk edge is not there
//

  always @(posedge hclk or negedge hresetn)
    begin : use_saved_data_PROC
      if (hresetn == 1'b0) begin
        use_saved_data <= 1'b0;
      end else begin
        if ((use_saved == 1'b1) && (pclk_en == 0))
          use_saved_data <= 1'b1;
        else
          use_saved_data <= 1'b0;
      end
    end

//
// Seperate out the Master and Slave portions of the main state
// machine register.
//

  always @(posedge hclk or negedge hresetn)
    begin : state_PROC
      if (hresetn == 1'b0) begin
        state <= CS;
      end else begin
        state <= nextstate;
      end
    end  // state_PROC

//
// Have 8 possible states within machine
// CS  : Check state
// WW  : Wait for Write
// WR  : Wait for Read
// SW  : Setup Write
// SR  : Setup Read
// ER  : Enable Read
// EW  : Enable Write
// Activity on bus, read or write, pclk edge or something in the
// pipeline that controls the movement between states.
//

  always @(*)
    begin : nextstate_PROC
        nextstate = CS;
        case (state)
//
// Have some activity on the bus need to accept or reject and if one
// accepts then need to decide on read or write. If read need to
// decide if next edge is a pclk edge so one is streamlined. If a
// write need to wait for the data and use next state to align the
// address to the data
//

          CS : begin
            if (ahb_valid == 1'b1) begin
              if (hwrite == 1'b0) begin
                if (pclk_en == 1'b1) begin
                  nextstate = SR;
                end else begin
                  nextstate = WR;
                end
              end else begin
                nextstate = WW;
              end
            end
          end

//
// Waiting for pclk edge to occur, when it does need to move on, else
// just keep on waiting. When it does one starts APB transfer
//

          WW : begin
            if (pclk_en == 1'b1) begin
              nextstate = SW;
            end else begin
              nextstate = WW;
            end
          end

//
// Waiting for pclk edge to occur, when it does need to move on, else
// just keep on waiting. When it does one is half way through an APB
// transfer, can now accept another AHB transfer on bus, will pipeline
// it, if it is there but once current completes then no time will
// be lost in moving on.
//

          SW : begin
            if (pclk_en == 1'b1) begin
              nextstate = EW;
            end else begin
              nextstate = SW;
            end
          end

//
// Allowing the AHB access on the hclk edge not on pclk edge leaves more
// consideration if there is activity on the bus within this state. Move
// from here after 1 cycle. Same condition applies for both read and
// writes as to where we go to.

//
// aaraujo @ 3/12/2010: 9000260778
// The system bus must mremain in either ER or EW until pready asserts
//

          ER, EW : begin
            if (pipeline == 1'b1) begin
                if (piped_hwrite == 1'b1) begin
                  if (pclk_en == 1'b1) begin
                    nextstate = SW;
                  end else begin
                    nextstate = WW;
                  end
                end else begin
                  if (pclk_en == 1'b1) begin
                    nextstate = SR;
                  end else begin
                   nextstate = WR;
                  end
                end
            end else begin
                if (ahb_valid == 1'b1) begin
                  if (hwrite == 1'b0) begin
                    if (pclk_en == 1'b1) begin
                      nextstate = SR;
                    end else begin
                      nextstate = WR;
                    end
                  end else begin
                    nextstate = WW;
                  end
                end else begin
                   nextstate = CS;
                end
            end
          end
//
// Waiting for pclk edge to occur, when it does need to move on, else
// just keep on waiting. When it does one starts APB read transfer
//

          WR : begin
            if (pclk_en == 1'b1) begin
              nextstate = SR;
            end else begin
              nextstate = WR;
            end
          end

//
// Waiting for pclk edge to occur, when it does need to move on, else
// just keep on waiting. When it does one is half way through the
// APB read transfer and now can accept new transfer as data is
// available on next edge.
//

          SR : begin
            if (pclk_en == 1'b1) begin
              nextstate = ER;
            end else begin
              nextstate = SR;
            end
          end

//
// Covers undefined states
//
          default : begin
            nextstate = CS;
          end
        endcase
    end // nextstate_PROC


endmodule
