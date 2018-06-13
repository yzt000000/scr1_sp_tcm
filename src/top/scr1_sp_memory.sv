/// Copyright by Syntacore LLC © 2016-2018. See LICENSE for details
/// @file       <scr1_dp_memory.sv>
/// @brief      Dual-port synchronous memory with byte enable inputs
///

`include "scr1_arch_description.svh"

`ifdef SCR1_TCM_EN
module scr1_sp_memory
#(
    parameter SCR1_WIDTH    = 32,
    parameter SCR1_SIZE     = `SCR1_IMEM_AWIDTH'h00010000,
    parameter SCR1_NBYTES   = SCR1_WIDTH / 8
)
(
    input   logic                           clk,
    // Port A
    input   logic                           rena,
    input   logic                           wena,
    input   logic [SCR1_NBYTES-1:0]         weba,
    input   logic [$clog2(SCR1_SIZE)-1:2]   addra,
    input   logic [SCR1_WIDTH-1:0]          dataa,
    output  logic [SCR1_WIDTH-1:0]          qa
);

`ifdef SCR1_TARGET_FPGA_INTEL
//-------------------------------------------------------------------------------
// Local signal declaration
//-------------------------------------------------------------------------------
logic [SCR1_NBYTES-1:0][7:0] memory_array [0:(SCR1_SIZE/SCR1_NBYTES)-1];
logic [3:0] wenab;
//-------------------------------------------------------------------------------
// Port B memory behavioral description
//-------------------------------------------------------------------------------
assign wenab = {4{wena}} & weba;
always_ff @(posedge clk) begin
    if (wena) begin
        if (wenab[0]) begin
            memory_array[addra][0] <= dataa[0+:8];
        end
        if (wenab[1]) begin
            memory_array[addra][1] <= dataa[8+:8];
        end
        if (wenab[2]) begin
            memory_array[addra][2] <= dataa[16+:8];
        end
        if (wenab[3]) begin
            memory_array[addra][3] <= dataa[24+:8];
        end
    end
    if (rena) begin
        qa <= memory_array[addra];
    end
end

`else // SCR1_TARGET_FPGA_INTEL

// CASE: OTHERS - SCR1_TARGET_FPGA_XILINX, SIMULATION, ASIC etc

localparam int unsigned RAM_SIZE_WORDS = SCR1_SIZE/SCR1_NBYTES;

//-------------------------------------------------------------------------------
// Local signal declaration
//-------------------------------------------------------------------------------
logic [SCR1_WIDTH-1:0]                  ram_block [RAM_SIZE_WORDS-1:0];


//-------------------------------------------------------------------------------
// Port A memory behavioral description
//-------------------------------------------------------------------------------
always @(posedge clk) begin
    if (wena) begin
        for (int i=0; i<SCR1_NBYTES; i++) begin
            if (weba[i]) begin
                ram_block[addra][i*8 +: 8] <= dataa[i*8 +: 8];
            end
        end
    end
    if (rena) begin
        qa <= ram_block[addra];
    end
end

`endif // SCR1_TARGET_FPGA_INTEL

endmodule : scr1_sp_memory

`endif // SCR1_TCM_EN
