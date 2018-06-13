// ---------------------------------------------------------------------
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
// File Version     :        $Revision: #13 $ 
// Revision: $Id: //dwh/DW_ocb/DW_apb_uart/amba_dev/src/DW_apb_uart_tx.v#13 $ 
//
// File :                       DW_apb_uart_tx.v
// Author:                      Marc Wall
//
//
// Date :                       $Date: 2016/08/26 $
// Abstract     :               Serial transmitter module for the
//                              DW_apb_uart macro-cell
//
//
// ---------------------------------------------------------------------
// ---------------------------------------------------------------------

module i_uart_DW_apb_uart_tx
  (
   // Inputs
   sclk,
   s_rst_n,
   bclk,
   tx_start,
   tx_data,
   char_info,
   xbreak,
   lb_en,
   sir_en,
   // Outputs
   tx_finish,
   ser_out_lb,
   sout
   );

   input                             sclk;          // APB Clock
   input                             s_rst_n;       // APB active low
                                                    // async reset
   input                             bclk;          // baud clock
   input                             tx_start;      // start serial
                                                    // transmission
   input  [`TXFIFO_RW-1:0]           tx_data;       // data to be
                                                    // transmitted

   input  [5:0]                      char_info;     // serial character
                                                    // information
   input                             xbreak;         // break control
   input                             lb_en;         // loopback enable
   input                             sir_en;        // serial infrared
                                                    // enable

//   input [7:0]                       tx_addr_reg      ; // Transmit address register value
//   input                             tx_mode          ; // Transmit modes, send addr from data buffer or tx_addr_reg
//   input                             tx_send_addr     ; // Trigger signal for sending address if from tx_addr_reg
//   output                            addr_sent        ; // Ack signal for send address. This is used to clear tx_send_addr
//   output                            tx_fsm_busy       ; // Indicating that tx can't go into low power mode

   output                            tx_finish;     // serial transmission
                                                    // of current character
                                                    // finished
   output                            ser_out_lb;    // serial tx data out
                                                    // for loopback
   output                            sout;          // serial out
                                                    // active low

                                                     // bclk generation with tx start

   reg                               ext_tx_start;  // extended tx_start
   reg                               sout;          // serial out
   reg                               ser_tx;        // serial tx data
   reg                               parity_gen;    // generated tx
                                                    // parity
   reg                               int_sir_out_n; // internal sir_out_n
   reg                               sir_break_ext; // serial infrared
                                                    // mode break extension
   reg                               break_ed_reg;  // break edge detect
                                                    // register
   reg    [3:0]                      tx_bclk_cnt;   // transmitter baud
                                                    // clock counter
   reg    [3:0]                      c_state;       // current state fsm
                                                    // state reg
   reg    [3:0]                      n_state;       // next state fsm
                                                    // state reg
   reg    [`TXFIFO_RW-1:0]           tx_shift_reg;  // tx shift register   
      


   wire                              cnt16;         // 16 baud clock count
   wire                              cnt8;          // 8 baud clock count
   wire                              start_tx;      // tx fsm start
   wire                              set_ext;       // set extension
   wire                              clear_ext;     // clear extension
   wire                              drive_low;     // drive low indicator
   wire                              drive_high;    // drive high indicator
   wire                              shift_en;      // tx shift reg shift
                                                    // enable
   wire                              drive_parity;  // drive parity
                                                    // indicator
   wire                              tx_finish;     // serial transmission
                                                    // of current character
                                                    // finished
   wire                              sir_win;       // serial infrared
                                                    // pulse window
   wire                              int_sout;      // internal sout
   wire                              break_ed;      // break edge detect

   wire                              stick_parity;  // Stick Parity indicator
   wire [3:0]                        int_char_info; // Internal signal used for FSM 
   wire                              tx_shift_reg_lsb;//lsb of tx shift register
                                                      //used to avoid lint violation
//    wire                              tx_finish_int ;            


   // state variables
   parameter          IDLE      = 4'b0000;
   parameter          START     = 4'b0001;
   parameter          DATA0     = 4'b0010;
   parameter          DATA1     = 4'b0011;
   parameter          DATA2     = 4'b0100;
   parameter          DATA3     = 4'b0101;
   parameter          DATA4     = 4'b0110;
   parameter          DATA5     = 4'b0111;
   parameter          DATA6     = 4'b1000;
   parameter          DATA7     = 4'b1001;
   parameter          PARITY    = 4'b1010;
   parameter          STOP1     = 4'b1011;
   parameter          STOP2     = 4'b1100;
   parameter          HALF_STOP = 4'b1101;

   // ------------------------------------------------------
   // Transmitter baud clock counter, this is used to keep
   // track of the number of baud clocks that have occurred
   // so that each bit is transmitted for the correct
   // duration
   // ------------------------------------------------------
   always @(posedge sclk or negedge s_rst_n)
     begin : tx_bclk_cnt_PROC
       if(s_rst_n == 1'b0)
         begin
           tx_bclk_cnt <= 4'b0000;
         end
       else if((tx_start == 1'b1 && c_state == IDLE) || (start_tx == 1'b1 && n_state == START) || (break_ed && sir_en))
         begin
           tx_bclk_cnt <= 4'b0000;
         end
       else if(bclk == 1'b1)
         begin
           if(tx_bclk_cnt == `UART_NUM_SAMPLES-1) begin // www.joe : March 2010 : Reduced Sample rate change
               tx_bclk_cnt <= 4'b0000;
           end else begin
             tx_bclk_cnt <= tx_bclk_cnt + {{(3){1'b0}},{1'b1}};
           end
         end
     end // block: tx_bclk_cnt_PROC

   // The count 16 signal is asserted when the transmitter baud clock
   // counter reaches 15 (0-15 therefore count of 16) and the baud clock
   // signal is asserted. This is used to indicate to the FSM that the
   // current character bit has been transmitted for 16 baud clocks
   //assign cnt16 = (tx_bclk_cnt == 4'b1111 && bclk == 1'b1) ? 1'b1 : 1'b0;

   // www.joe : March 2010 : Reduced Sample rate change
   // replaced line above with this line below.
   assign cnt16 = (tx_bclk_cnt == `UART_NUM_SAMPLES-1 && bclk == 1'b1) ? 1'b1 : 1'b0;

   // The count 8 signal is asserted when the transmitter baud clock
   // counter reaches 7 (0-7 therefore count of 8) and the baud clock
   // signal is asserted. this is used to indicate to the FSM that the
   // current character bit has been transmitted for 8 baud clocks
   //assign cnt8  = (tx_bclk_cnt == 4'b0111 && bclk == 1'b1) ? 1'b1 : 1'b0;

   // www.joe : March 2010 : Reduced Sample rate change
   // replaced line above with this line below.
   assign cnt8  = ((tx_bclk_cnt == (`UART_NUM_SAMPLES/2)-1) && bclk == 1'b1) ? 1'b1 : 1'b0;

   // ------------------------------------------------------
   // The start TX signal tells the TX FSM to start
   // transmitting the current character.
   // The start TX signal is asserted when either the TX
   // start signal is asserted or the extended TX start
   // signal is asserted.
   // ------------------------------------------------------
   assign start_tx = tx_start | ext_tx_start;

   // The extended TX start signal is asserted when a TX start
   // occurs and the current transmission is not completed or when a TX
   // start occurs when the relevant count signal (cnt8 or cnt16) is not
   // asserted , so that the start is not missed. It is de-asserted when
   // the relevant count signals (cnt16 or cnt8) are asserted
   always @(posedge sclk or negedge s_rst_n)
     begin : ext_tx_start_PROC
       if(s_rst_n == 1'b0)
         begin
           ext_tx_start <= 1'b0;
         end
       else if(set_ext)
         begin
           ext_tx_start <= 1'b1;
         end
       else if(clear_ext)
         begin
           ext_tx_start <= 1'b0;
         end
     end // block: ext_tx_start_PROC

   // The set extension signal is asserted when a TX start occurs and the
   // relevant count signal (cnt8 or cnt16) is not asserted
   assign set_ext = tx_start & (~((c_state == HALF_STOP) ? cnt8 : cnt16));
   // The clear extension signal is asserted when the relevant count
   // signal (cnt8 or cnt16) is asserted
   assign clear_ext = (c_state == HALF_STOP) ? cnt8 : cnt16;

   // ------------------------------------------------------
   // Rising edge detect for break control signal, used to
   // set the baud clock counter to zero when in SIR mode to
   // ensure that the pulse duration of the first pulse is
   // correct
   // ------------------------------------------------------
   assign break_ed = xbreak & (~break_ed_reg);

   // Break control edge detect register
   always @(posedge sclk or negedge s_rst_n)
     begin : break_ed_reg_PROC
       if(s_rst_n == 1'b0)
         begin
           break_ed_reg <= 1'b0;
         end
       else
         begin
           break_ed_reg <= xbreak;
         end
     end // block: break_ed_reg_PROC

   // ------------------------------------------------------
   // State assignment
   // ------------------------------------------------------
   always @(posedge sclk or negedge s_rst_n)
     begin : TX_FSM_SEQ_PROC
       if(s_rst_n == 1'b0)
         begin
           c_state <= IDLE;
         end
       else
         begin
           c_state <= n_state;
         end
      end // block: TX_FSM_SEQ_PROC

   // ------------------------------------------------------
   // Next state logic
   // ------------------------------------------------------
   assign int_char_info = char_info[3:0];
   
   always @(c_state or start_tx or cnt16 or
            cnt8    or int_char_info
            )
     begin : TX_FSM_PROC

       case(c_state)

         IDLE :
           if(start_tx && cnt16
              )
             n_state = START;
           else
             n_state = IDLE;

         START :
           if(cnt16)
             n_state = DATA0;
           else
             n_state = START;

         DATA0 :
           if(cnt16)
             n_state = DATA1;
           else
             n_state = DATA0;

         DATA1 :
           if(cnt16)
             n_state = DATA2;
           else
             n_state = DATA1;

         DATA2 :
           if(cnt16)
             n_state = DATA3;
           else
             n_state = DATA2;

         DATA3 :
           if(cnt16)
             n_state = DATA4;
           else
             n_state = DATA3;

         DATA4 :
           if(cnt16)
             begin
               if(int_char_info[1:0] == 2'b00)
                 if(int_char_info[3])
                   n_state = PARITY;
                 else
                   n_state = STOP1;
               else
                 n_state = DATA5;
             end
           else
             n_state = DATA4;

         DATA5 :
           if(cnt16)
             begin
               if(int_char_info[1:0] == 2'b01)
                 if(int_char_info[3])
                   n_state = PARITY;
                 else
                   n_state = STOP1;
               else
                 n_state = DATA6;
             end
           else
             n_state = DATA5;

         DATA6 :
           if(cnt16)
             begin
               if(int_char_info[1:0] == 2'b10)
                 if(int_char_info[3])
                   n_state = PARITY;
                 else
                   n_state = STOP1;
               else
                 n_state = DATA7;
             end
           else
             n_state = DATA6;

         DATA7 :
           if(cnt16)
             begin
               if(int_char_info[3])
                 n_state = PARITY;
               else
                 n_state = STOP1;
             end
           else
             n_state = DATA7;


         PARITY :
           if(cnt16)
             n_state = STOP1;
           else
             n_state = PARITY;

         STOP1 :
           if(cnt16)
             if(int_char_info[2])
               if(int_char_info[1:0] == 2'b00)
                 n_state = HALF_STOP;
               else
                 n_state = STOP2;
             else
               if(start_tx)
                 n_state = START;
               else
                 n_state = IDLE;
           else
             n_state = STOP1;

         STOP2 :
           if(cnt16)
             if(start_tx)
               n_state = START;
             else
               n_state = IDLE;
           else
             n_state = STOP2;

         HALF_STOP :
           if(cnt8)
             if(start_tx)
               n_state = START;
             else
               n_state = IDLE;
           else
             n_state = HALF_STOP;

         default :
           n_state = IDLE;

       endcase
     end // block: TX_FSM_PROC

   // ------------------------------------------------------
   // Drive low, the assertion of this signal causes the
   // serial output to be driven low
   // ------------------------------------------------------
   assign drive_low    = (c_state==START);

   // ------------------------------------------------------
   // Drive high, the assertion of this signal causes the
   // serial output to be driven high
   // ------------------------------------------------------
   assign drive_high   = (c_state==IDLE)  || (c_state==STOP1) ||
                         (c_state==STOP2) || (c_state==HALF_STOP);

   // ------------------------------------------------------
   // Shift enable, the assertion of this signal causes the
   // TX shift register to shift
   // ------------------------------------------------------
   assign shift_en     = (c_state==DATA0 && cnt16) || (c_state==DATA1 && cnt16) ||
                         (c_state==DATA2 && cnt16) || (c_state==DATA3 && cnt16) ||
                         (c_state==DATA4 && cnt16 && char_info[1:0] != 2'b00)   ||
                         (c_state==DATA5 && cnt16 && char_info[1:0] != 2'b01)   ||
                         (c_state==DATA6 && cnt16 && char_info[1:0] != 2'b10);
                                                                               
                                                                               
   // ------------------------------------------------------
   // Drive parity, the assertion of this signal causes the
   // serial output to be driven with the generated parity
   // value
   // ------------------------------------------------------
   assign drive_parity = (c_state==PARITY);

   // ------------------------------------------------------
   // TX finished, is asserted when the the current
   // character has been transmitted
   // ------------------------------------------------------
   //assign tx_finish    = (c_state==STOP1 && ~char_info[2] && (tx_bclk_cnt == 4'b1110 && bclk == 1'b1)) ||
   //                      (c_state==STOP2 && (tx_bclk_cnt == 4'b1110 && bclk == 1'b1))                  ||
   //                      (c_state==HALF_STOP && (tx_bclk_cnt == 4'b0110 && bclk == 1'b1));

   // www.joe : March 2010 : Reduced Sample rate change
   // Changed assign statement above to one below.
   // bit period not always 16 samples with nw change so conunter compare
   // logic is update to reflect this.
   assign tx_finish = (c_state==STOP1 && (~char_info[2]) && (tx_bclk_cnt == `UART_NUM_SAMPLES-2 && bclk == 1'b1)) ||
                         (c_state==STOP2 && (tx_bclk_cnt == `UART_NUM_SAMPLES-2 && bclk == 1'b1))                  ||
                         (c_state==HALF_STOP && (tx_bclk_cnt == ((`UART_NUM_SAMPLES/2)-2) && bclk == 1'b1));

   // ------------------------------------------------------
   // The serial data out signal is driven high if the UART
   // is in loopback mode or serial infrared mode, otherwise
   // it is assigned to the current bit of the character that
   // is being transmitted (i.e. serial TX signal)
   // ------------------------------------------------------
   always @(posedge sclk or negedge s_rst_n)
     begin : sout_PROC
       if(s_rst_n == 1'b0)
         begin
           sout <= 1'b1;
         end
       else if(lb_en)
         begin
           sout <= 1'b1;
         end
       else
         begin
           sout <= int_sout;
         end
     end // block: sout_PROC

   // Internal sout, required so that the internal sout signal may be used
   // for loopback mode
   assign int_sout = sir_en ? 1'b1 : ser_tx;

   // The serial TX signal is driven low if a break occurs or the SIR break
   // extend signal is asserted while the break edge detect signal is
   // de-asserted or the drive low signal is asserted, it is driven high
   // when the drive high signal is asserted. If the drive parity signal
   // is asserted it is equal to the generated parity for the current
   // data, else it is equal to the LSB of the TX shift register
   assign tx_shift_reg_lsb = tx_shift_reg[0];       //used in the always block
                                                    //instead of tx_shift_reg[0]
          
   
   always @(xbreak         or drive_low     or
            drive_high    or drive_parity  or
            parity_gen    or tx_shift_reg_lsb  or
            sir_break_ext or break_ed
            )
     begin : ser_tx_PROC
       if(((xbreak || sir_break_ext) && (~break_ed)) || drive_low)
         begin
           ser_tx = 1'b0;
         end
       else if(drive_high)
         begin
           ser_tx = 1'b1;
         end
       else if(drive_parity)
         begin
           ser_tx = parity_gen;
         end
       else
         begin
           ser_tx = tx_shift_reg_lsb;
         end
     end // block: ser_tx_PROC

   // If break is asserted while an SIR pulse is being transmitted the
   // SIR break signal will get asserted until the pulse is complete,
   // thus extending the break. This is done so that the pulse duration
   // will always be 3 baud clocks (3/16 of a bit time) during a break
   // condition
   always @(posedge sclk or negedge s_rst_n)
     begin : sir_break_ext_PROC
       if(s_rst_n == 1'b0)
         begin
           sir_break_ext <= 1'b0;
         end
       else if(xbreak && int_sir_out_n)
         begin
           sir_break_ext <= 1'b1;
         end
       else if((~xbreak) && (~int_sir_out_n))
         begin
           sir_break_ext <= 1'b0;
         end
     end // block: sir_break_ext_PROC


   // Internal sir_out_n, required so that the internal sir_out_n signal
   // may be used for loopback mode
   always @(sir_en or ser_tx or
            sir_win
            )
     begin : int_sir_out_n_PROC
       if(~sir_en)
         begin
           int_sir_out_n = 1'b0;
         end
       else if(ser_tx == 1'b0 && sir_win)
         begin
           int_sir_out_n = 1'b1;
         end
       else
         begin
           int_sir_out_n = 1'b0;
         end
     end // block: int_sir_out_n_PROC

   // The serial infrared pulse window signal is asserted for 3 baud
   // clocks (3/16 of a bit time) and occurs at approx. the mid point of
   // a bit period (time), this allows the serial infrared data out
   // signal to go high for the correct duration (3/16 of a bit time)
   // when the current bit of the character that is being transmitted
   // is zero, see the example timing diagrams below:
   //
   //                 _   _   _   _   _   _   _   _   _   _
   //  sclk         _| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_
   //                 ___     ___     ___     ___     ___
   //  bclk         _|   |___|   |___|   |___|   |___|   |___
   //               _____________ _______ _______ _______ ___
   //  tx_bclk_cnt  __6__X___7___X___8___X___9___X__10___X_11
   //                     _______________________
   //  sir_win      _____|                       |___________
   //
   //  ser_tx       _________________________________________
   //                     _______________________
   //  sir_out_n    _____|                       |___________
   //

   // jduarte 20100427 begin
   //assign sir_win = (tx_bclk_cnt == 4'b0111 || tx_bclk_cnt == 4'b1000 ||
   //                  tx_bclk_cnt == 4'b1001) ? 1'b1 : 1'b0;

   assign sir_win = (tx_bclk_cnt == (`UART_NUM_SAMPLES/2-1) || tx_bclk_cnt == (`UART_NUM_SAMPLES/2) ||
                     tx_bclk_cnt == (`UART_NUM_SAMPLES/2+1)) ? 1'b1 : 1'b0;

   // jduarte 20100427 end


   // ------------------------------------------------------
   // When in loopback mode the serial output for loopback
   // signal is assigned the output of the serial TX block,
   // that is int_sout (in UART mode) and the inverse of
   // int_sir_out_n (in IR mode)
   // ------------------------------------------------------
   assign ser_out_lb = sir_en ? ~int_sir_out_n : int_sout;


   assign stick_parity = char_info[5];

   // ------------------------------------------------------
   // Parity generator
   // When the TX start signal is asserted bit[0] of the
   // data to be transmitted is XOR'ed with the even parity
   // select bit (char_info[4]), then at each shift enable
   // assertion the result is XOR'ed with bit[1] of the TX
   // shift register to give the generated parity bit for
   // the current data to be transmitted
   // ------------------------------------------------------
   always @(posedge sclk or negedge s_rst_n)
     begin : parity_gen_PROC
       if(s_rst_n == 1'b0)
         begin
           parity_gen <= 1'b0;
         end
       //
       // aaraujo @ 17/05/2011 : CRM_9000431453
       // Include Stick Parity feature LCR[5]
       //
       else if(stick_parity)
         begin
           parity_gen <= ~char_info[4];
         end
       // aaraujo: END
       else if(tx_start)
         begin
           parity_gen <= tx_data[0] ^ (~char_info[4]);
         end
       else if(shift_en)
         begin
           parity_gen <= parity_gen ^ tx_shift_reg[1];
         end
     end // block: parity_gen_PROC

   // ------------------------------------------------------
   // TX shift register, gets loaded with the data to be
   // transmitted when the TX start signal is asserted. The
   // data is shifted on each consecutive rising edge of the
   // serial clock when the shift enable signal is asserted
   // ------------------------------------------------------
   always @(posedge sclk or negedge s_rst_n)
     begin : tx_shift_reg_PROC
       if(s_rst_n == 1'b0)
         begin
           tx_shift_reg <= {8{1'b0}};
         end
       else if(tx_start)
         begin
           tx_shift_reg <= tx_data;
         end
       else if(shift_en)
         begin
           tx_shift_reg <= {1'b0, tx_shift_reg[7:1]};
         end
     end // block: tx_shift_reg_PROC


endmodule // DW_apb_uart_tx
