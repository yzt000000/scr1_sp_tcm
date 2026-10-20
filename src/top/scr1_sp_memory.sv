/// Copyright by Syntacore LLC © 2016-2021. See LICENSE for details
/// @file       <scr1_sp_memory.sv>
/// @brief      Single-port synchronous memory with byte enable inputs
///
/// @details    Generic single-port RAM primitive used to build the TCM
///             sub-memories (ITCM/DTCM). One access (read or write) per clock.
///             Byte write enables are supported; read data is registered.
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
    // Port
    input   logic                           wen,
    input   logic [SCR1_NBYTES-1:0]         webb,
    input   logic                           ren,
    input   logic [$clog2(SCR1_SIZE)-1:2]   addr,
    input   logic [SCR1_WIDTH-1:0]          datain,
    output  logic [SCR1_WIDTH-1:0]          q
);

`ifdef SCR1_TRGT_FPGA_INTEL
//-------------------------------------------------------------------------------
// Local signal declaration
//-------------------------------------------------------------------------------
 `ifdef SCR1_TRGT_FPGA_INTEL_MAX10
(* ramstyle = "M9K" *)    logic [SCR1_NBYTES-1:0][7:0]  memory_array  [0:(SCR1_SIZE/SCR1_NBYTES)-1];
 `elsif SCR1_TRGT_FPGA_INTEL_ARRIAV
(* ramstyle = "M10K" *)   logic [SCR1_NBYTES-1:0][7:0]  memory_array  [0:(SCR1_SIZE/SCR1_NBYTES)-1];
 `endif
logic [3:0] wenb;
//-------------------------------------------------------------------------------
// Memory behavioral description
//-------------------------------------------------------------------------------
assign wenb = {4{wen}} & webb;
always_ff @(posedge clk) begin
    if (wen) begin
        if (wenb[0]) begin
            memory_array[addr][0] <= datain[0+:8];
        end
        if (wenb[1]) begin
            memory_array[addr][1] <= datain[8+:8];
        end
        if (wenb[2]) begin
            memory_array[addr][2] <= datain[16+:8];
        end
        if (wenb[3]) begin
            memory_array[addr][3] <= datain[24+:8];
        end
    end
    if (ren) begin
        q <= memory_array[addr];
    end
end

`else // SCR1_TRGT_FPGA_INTEL

// CASE: OTHERS - SCR1_TRGT_FPGA_XILINX, SIMULATION, ASIC etc

localparam int unsigned RAM_SIZE_WORDS = SCR1_SIZE/SCR1_NBYTES;

//-------------------------------------------------------------------------------
// Local signal declaration
//-------------------------------------------------------------------------------
 `ifdef SCR1_TRGT_FPGA_XILINX
(* ram_style = "block" *)  logic  [SCR1_WIDTH-1:0]  ram_block  [RAM_SIZE_WORDS-1:0];
 `else  // ASIC or SIMULATION
logic  [SCR1_WIDTH-1:0]  ram_block  [RAM_SIZE_WORDS-1:0];
 `endif
//-------------------------------------------------------------------------------
// Memory behavioral description
//-------------------------------------------------------------------------------
always_ff @(posedge clk) begin
    if (wen) begin
        for (int i=0; i<SCR1_NBYTES; i++) begin
            if (webb[i]) begin
                ram_block[addr][i*8 +: 8] <= datain[i*8 +: 8];
            end
        end
    end
    if (ren) begin
        q <= ram_block[addr];
    end
end

`endif // SCR1_TRGT_FPGA_INTEL

endmodule : scr1_sp_memory

`endif // SCR1_TCM_EN
