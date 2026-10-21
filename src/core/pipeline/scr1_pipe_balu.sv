/// Copyright by Syntacore LLC © 2016-2021. See LICENSE for details
/// @file       <scr1_pipe_balu.sv>
/// @brief      Bit manipulation extension ALU
///
/// @brief      Implements the RISC-V Bit-Manipulation ISA extension for RV32:
///             - Zba : address generation        (sh1add, sh2add, sh3add)
///             - Zbb : basic bit manipulation    (andn, orn, xnor, clz, ctz, cpop,
///                                                max, maxu, min, minu, sext.b, sext.h,
///                                                zext.h, rol, ror, rori, orc.b)
///             - Zbc : carry-less multiplication (clmul, clmulh, clmulr)
///             - Zbs : single-bit instructions   (bclr, bext, binv, bset + immediate forms)
///
/// @note       Depending on SCR1_RVB_ITER_CLMUL the Zbc instructions are either
///             implemented here as a combinational GF(2) array, or handed over to
///             the iterative radix-2 MDU of the "M" extension (see
///             scr1_pipe_ialu.sv).  In the latter case nothing Zbc related is
///             instantiated in this module.
/// @note       Immediate forms (rori, bclri, bexti, binvi, bseti) are decoded to the
///             corresponding register-register command with op2 carrying the
///             zero-extended shamt, so they need no separate command encoding.
/// @note       The combinational clmul / clmulh / clmulr share one 32x32
///             carry-less multiplier array and only differ in which slice of the
///             63-bit product is selected:
///                 clmul  = P[31:0]
///                 clmulh = P[63:32]   (P[63] is always 0 for RV32)
///                 clmulr = P[62:31]
///

`include "scr1_arch_description.svh"
`include "scr1_riscv_isa_decoding.svh"

module scr1_pipe_balu (
    input  logic [`SCR1_XLEN-1:0]       op1_i,      // operand 1 (rs1)
    input  logic [`SCR1_XLEN-1:0]       op2_i,      // operand 2 (rs2 or zero-extended shamt)
    input  type_scr1_ialu_cmd_sel_e     cmd_i,      // BALU command
    output logic [`SCR1_XLEN-1:0]       res_o       // BALU result
);

//-------------------------------------------------------------------------------
// Local parameters
//-------------------------------------------------------------------------------
localparam int unsigned SCR1_BALU_SHAMT_WIDTH = 5;                  // log2(XLEN)
localparam int unsigned SCR1_BALU_CNT_WIDTH   = SCR1_BALU_SHAMT_WIDTH + 1;  // 0..XLEN

//-------------------------------------------------------------------------------
// Local signals
//-------------------------------------------------------------------------------
logic [SCR1_BALU_SHAMT_WIDTH-1:0]   shamt;          // shift/rotate/bit amount
logic [SCR1_BALU_CNT_WIDTH-1:0]     shamt_r;        // XLEN - shamt, range 0..XLEN (6 bit!)
logic [`SCR1_XLEN-1:0]              bit_sel;        // 1 << shamt

logic [`SCR1_XLEN-1:0]              sh_op;          // op1 << N for shNadd
logic [`SCR1_XLEN-1:0]              shnadd_res;     // (op1 << N) + op2

`ifndef SCR1_RVB_ITER_CLMUL
localparam int unsigned SCR1_BALU_CLMUL_LVL = SCR1_BALU_SHAMT_WIDTH;   // log2(XLEN) stages
logic [(2*`SCR1_XLEN)-1:0]      clmul_lvl0 [0:`SCR1_XLEN-1];           // partial products
logic [(2*`SCR1_XLEN)-1:0]      clmul_lvl1 [0:`SCR1_XLEN/2-1];
logic [(2*`SCR1_XLEN)-1:0]      clmul_lvl2 [0:`SCR1_XLEN/4-1];
logic [(2*`SCR1_XLEN)-1:0]      clmul_lvl3 [0:`SCR1_XLEN/8-1];
logic [(2*`SCR1_XLEN)-1:0]      clmul_lvl4 [0:`SCR1_XLEN/16-1];
logic [(2*`SCR1_XLEN)-1:0]      clmul_full;     // full 63-bit carry-less product
`endif // ~SCR1_RVB_ITER_CLMUL
logic [SCR1_BALU_CNT_WIDTH-1:0] clz_cnt;        // count leading zeros
logic [SCR1_BALU_CNT_WIDTH-1:0]     ctz_cnt;        // count trailing zeros
logic [SCR1_BALU_CNT_WIDTH-1:0]     cpop_cnt;       // count set bits
logic [`SCR1_XLEN-1:0]              orcb_res;       // or-combine result

//-------------------------------------------------------------------------------
// Common shift / bit index
//-------------------------------------------------------------------------------
// shamt_r needs one extra bit: for shamt == 0 it must evaluate to 32 so that
// (op1 >> 32) / (op1 << 32) yield 0, which makes rotate-by-0 an identity op.
assign shamt   = op2_i[SCR1_BALU_SHAMT_WIDTH-1:0];
assign shamt_r = SCR1_BALU_CNT_WIDTH'(`SCR1_XLEN) - {1'b0, shamt};
assign bit_sel = `SCR1_XLEN'(1'b1) << shamt;

//-------------------------------------------------------------------------------
// Zba: (rs1 << 1|2|3) + rs2
//-------------------------------------------------------------------------------
always_comb begin
    case (cmd_i)
        SCR1_IALU_CMD_SH1ADD    : sh_op = op1_i << 1;
        SCR1_IALU_CMD_SH2ADD    : sh_op = op1_i << 2;
        default                 : sh_op = op1_i << 3;   // SCR1_IALU_CMD_SH3ADD
    endcase
end

assign shnadd_res = sh_op + op2_i;

//-------------------------------------------------------------------------------
// Zbc: carry-less multiplication (combinational array)
//-------------------------------------------------------------------------------
// P[k] = XOR over all (i, j) with i + j == k of (op1[i] & op2[j])
//
// The reduction is written out as an explicit balanced tree rather than as an
// accumulate loop (`acc = acc ^ (op1 << i)`).  The loop form elaborates to a
// 32-deep chain of XOR2s; synthesis retiming may or may not turn that into a
// tree, and it usually will not when timing is tight.  Five levels of pairwise
// XOR give the log2(32) depth that makes the array worthwhile in the first place.
//
// op2 is additionally gated by cmd_is_clmul so the whole array stays quiet for
// the (many) B instructions that do not use it.
`ifndef SCR1_RVB_ITER_CLMUL
always_comb begin
    logic cmd_is_clmul;

    cmd_is_clmul = (cmd_i == SCR1_IALU_CMD_CLMUL)
                 | (cmd_i == SCR1_IALU_CMD_CLMULH)
                 | (cmd_i == SCR1_IALU_CMD_CLMULR);

    // Stage 0: the 32 partial products
    for (int i = 0; i < `SCR1_XLEN; ++i) begin
        clmul_lvl0[i] = {(2*`SCR1_XLEN){op2_i[i] & cmd_is_clmul}}
                      & ((2*`SCR1_XLEN)'(op1_i) << i);
    end
    // Stages 1..5: balanced pairwise reduction
    for (int i = 0; i < `SCR1_XLEN/2; ++i) begin
        clmul_lvl1[i] = clmul_lvl0[2*i] ^ clmul_lvl0[2*i+1];
    end
    for (int i = 0; i < `SCR1_XLEN/4; ++i) begin
        clmul_lvl2[i] = clmul_lvl1[2*i] ^ clmul_lvl1[2*i+1];
    end
    for (int i = 0; i < `SCR1_XLEN/8; ++i) begin
        clmul_lvl3[i] = clmul_lvl2[2*i] ^ clmul_lvl2[2*i+1];
    end
    for (int i = 0; i < `SCR1_XLEN/16; ++i) begin
        clmul_lvl4[i] = clmul_lvl3[2*i] ^ clmul_lvl3[2*i+1];
    end
    clmul_full = clmul_lvl4[0] ^ clmul_lvl4[1];
end
`endif // ~SCR1_RVB_ITER_CLMUL

//-------------------------------------------------------------------------------
// Zbb: count leading / trailing zeros and set bits
//-------------------------------------------------------------------------------
// clz: the loop runs from LSB to MSB, so the last (highest) set bit wins
always_comb begin
    clz_cnt = SCR1_BALU_CNT_WIDTH'(`SCR1_XLEN);
    for (int i = 0; i < `SCR1_XLEN; ++i) begin
        if (op1_i[i]) begin
            clz_cnt = SCR1_BALU_CNT_WIDTH'(`SCR1_XLEN - 1) - SCR1_BALU_CNT_WIDTH'(i);
        end
    end
end

// ctz: the loop runs from MSB to LSB, so the last (lowest) set bit wins
always_comb begin
    ctz_cnt = SCR1_BALU_CNT_WIDTH'(`SCR1_XLEN);
    for (int i = `SCR1_XLEN - 1; i >= 0; --i) begin
        if (op1_i[i]) begin
            ctz_cnt = SCR1_BALU_CNT_WIDTH'(i);
        end
    end
end

always_comb begin
    cpop_cnt = '0;
    for (int i = 0; i < `SCR1_XLEN; ++i) begin
        cpop_cnt = cpop_cnt + {{SCR1_BALU_CNT_WIDTH-1{1'b0}}, op1_i[i]};
    end
end

//-------------------------------------------------------------------------------
// Zbb: orc.b - every byte becomes 0xFF when non-zero, 0x00 otherwise
//-------------------------------------------------------------------------------
always_comb begin
    for (int i = 0; i < (`SCR1_XLEN / 8); ++i) begin
        orcb_res[(8*i) +: 8] = |op1_i[(8*i) +: 8] ? 8'hFF : 8'h00;
    end
end

//-------------------------------------------------------------------------------
// Result multiplexer
//-------------------------------------------------------------------------------
always_comb begin
    case (cmd_i)
        // Zba
        SCR1_IALU_CMD_SH1ADD,
        SCR1_IALU_CMD_SH2ADD,
        SCR1_IALU_CMD_SH3ADD    : res_o = shnadd_res;

        // Zbb - logic with inverted operand
        SCR1_IALU_CMD_ANDN      : res_o = op1_i & ~op2_i;
        SCR1_IALU_CMD_ORN       : res_o = op1_i | ~op2_i;
        SCR1_IALU_CMD_XNOR      : res_o = ~(op1_i ^ op2_i);

        // Zbb - bit counting
        SCR1_IALU_CMD_CLZ       : res_o = `SCR1_XLEN'(clz_cnt);
        SCR1_IALU_CMD_CTZ       : res_o = `SCR1_XLEN'(ctz_cnt);
        SCR1_IALU_CMD_CPOP      : res_o = `SCR1_XLEN'(cpop_cnt);

        // Zbb - min/max
        SCR1_IALU_CMD_MAX       : res_o = ($signed(op1_i) >  $signed(op2_i)) ? op1_i : op2_i;
        SCR1_IALU_CMD_MAXU      : res_o = (op1_i         >  op2_i)          ? op1_i : op2_i;
        SCR1_IALU_CMD_MIN       : res_o = ($signed(op1_i) <  $signed(op2_i)) ? op1_i : op2_i;
        SCR1_IALU_CMD_MINU      : res_o = (op1_i         <  op2_i)          ? op1_i : op2_i;

        // Zbb - sign/zero extension
        SCR1_IALU_CMD_SEXTB     : res_o = {{`SCR1_XLEN-8{op1_i[7]}},  op1_i[7:0]};
        SCR1_IALU_CMD_SEXTH     : res_o = {{`SCR1_XLEN-16{op1_i[15]}}, op1_i[15:0]};
        SCR1_IALU_CMD_ZEXTH     : res_o = {{`SCR1_XLEN-16{1'b0}},     op1_i[15:0]};

        // Zbb - rotate (shamt_r == 32 when shamt == 0, giving an identity op)
        SCR1_IALU_CMD_ROL       : res_o = (op1_i << shamt) | (op1_i >> shamt_r);
        SCR1_IALU_CMD_ROR       : res_o = (op1_i >> shamt) | (op1_i << shamt_r);

        // Zbb - or-combine
        SCR1_IALU_CMD_ORCB      : res_o = orcb_res;

`ifndef SCR1_RVB_ITER_CLMUL
        // Zbc - combinational array (see SCR1_RVB_ITER_CLMUL for the alternative)
        SCR1_IALU_CMD_CLMUL     : res_o = clmul_full[`SCR1_XLEN-1:0];
        SCR1_IALU_CMD_CLMULH    : res_o = clmul_full[(2*`SCR1_XLEN)-1:`SCR1_XLEN];
        SCR1_IALU_CMD_CLMULR    : res_o = clmul_full[(2*`SCR1_XLEN)-2:`SCR1_XLEN-1];
`endif // ~SCR1_RVB_ITER_CLMUL

        // Zbs
        SCR1_IALU_CMD_BCLR      : res_o = op1_i & ~bit_sel;
        SCR1_IALU_CMD_BEXT      : res_o = `SCR1_XLEN'((op1_i >> shamt) & `SCR1_XLEN'(1'b1));
        SCR1_IALU_CMD_BINV      : res_o = op1_i ^ bit_sel;
        SCR1_IALU_CMD_BSET      : res_o = op1_i | bit_sel;

        default                 : res_o = '0;
    endcase
end

endmodule : scr1_pipe_balu
