/// Copyright by Syntacore LLC � 2016-2021. See LICENSE for details
/// @file       <scr1_riscv_isa_decoding.svh>
/// @brief      RISC-V ISA definitions file
///

`ifndef SCR1_RISCV_ISA_DECODING_SVH
`define SCR1_RISCV_ISA_DECODING_SVH

`include "scr1_arch_description.svh"
`include "scr1_arch_types.svh"
`include "scr1_memif.svh"

//-------------------------------------------------------------------------------
// Instruction types
//-------------------------------------------------------------------------------
typedef enum logic [1:0] {
    SCR1_INSTR_RVC0     = 2'b00,
    SCR1_INSTR_RVC1     = 2'b01,
    SCR1_INSTR_RVC2     = 2'b10,
    SCR1_INSTR_RVI      = 2'b11
} type_scr1_instr_type_e;

//-------------------------------------------------------------------------------
// RV32I opcodes (bits 6:2)
//-------------------------------------------------------------------------------
typedef enum logic [6:2] {
    SCR1_OPCODE_LOAD        = 5'b00000,
    SCR1_OPCODE_MISC_MEM    = 5'b00011,
    SCR1_OPCODE_OP_IMM      = 5'b00100,
    SCR1_OPCODE_AUIPC       = 5'b00101,
    SCR1_OPCODE_STORE       = 5'b01000,
    SCR1_OPCODE_OP          = 5'b01100,
    SCR1_OPCODE_LUI         = 5'b01101,
    SCR1_OPCODE_BRANCH      = 5'b11000,
    SCR1_OPCODE_JALR        = 5'b11001,
    SCR1_OPCODE_JAL         = 5'b11011,
    SCR1_OPCODE_SYSTEM      = 5'b11100
`ifdef SCR1_RVX_EXT
    ,
    SCR1_OPCODE_CUSTOM_0    = 5'b00010,    // custom-0 (bits[6:2])
    SCR1_OPCODE_CUSTOM_1    = 5'b01010,    // custom-1
    SCR1_OPCODE_CUSTOM_2    = 5'b10110,    // custom-2
    SCR1_OPCODE_CUSTOM_3    = 5'b11110     // custom-3
`endif // SCR1_RVX_EXT
} type_scr1_rvi_opcode_e;


//-------------------------------------------------------------------------------
// IALU main operands
//-------------------------------------------------------------------------------
localparam SCR1_IALU_OP_ALL_NUM_E = 2;
localparam SCR1_IALU_OP_WIDTH_E   = $clog2(SCR1_IALU_OP_ALL_NUM_E);
typedef enum logic [SCR1_IALU_OP_WIDTH_E-1:0] {
    SCR1_IALU_OP_REG_IMM,          // op1 = rs1; op2 = imm
    SCR1_IALU_OP_REG_REG           // op1 = rs1; op2 = rs2
} type_scr1_ialu_op_sel_e;

//-------------------------------------------------------------------------------
// IALU main commands
//-------------------------------------------------------------------------------
`ifdef SCR1_RVM_EXT
  `ifdef SCR1_RVB_EXT
localparam SCR1_IALU_CMD_ALL_NUM_E    = 49;   // RV32I + M + B (Zba+Zbb+Zbc+Zbs)
  `else // ~SCR1_RVB_EXT
localparam SCR1_IALU_CMD_ALL_NUM_E    = 23;
  `endif // ~SCR1_RVB_EXT
`else // ~SCR1_RVM_EXT
  `ifdef SCR1_RVB_EXT
localparam SCR1_IALU_CMD_ALL_NUM_E    = 41;   // RV32I + B
  `else // ~SCR1_RVB_EXT
localparam SCR1_IALU_CMD_ALL_NUM_E    = 15;
  `endif // ~SCR1_RVB_EXT
`endif // ~SCR1_RVM_EXT
localparam SCR1_IALU_CMD_WIDTH_E      = $clog2(SCR1_IALU_CMD_ALL_NUM_E);
typedef enum logic [SCR1_IALU_CMD_WIDTH_E-1:0] {
    SCR1_IALU_CMD_NONE  = '0,   // IALU disable
    SCR1_IALU_CMD_AND,          // op1 & op2
    SCR1_IALU_CMD_OR,           // op1 | op2
    SCR1_IALU_CMD_XOR,          // op1 ^ op2
    SCR1_IALU_CMD_ADD,          // op1 + op2
    SCR1_IALU_CMD_SUB,          // op1 - op2
    SCR1_IALU_CMD_SUB_LT,       // op1 < op2
    SCR1_IALU_CMD_SUB_LTU,      // op1 u< op2
    SCR1_IALU_CMD_SUB_EQ,       // op1 = op2
    SCR1_IALU_CMD_SUB_NE,       // op1 != op2
    SCR1_IALU_CMD_SUB_GE,       // op1 >= op2
    SCR1_IALU_CMD_SUB_GEU,      // op1 u>= op2
    SCR1_IALU_CMD_SLL,          // op1 << op2
    SCR1_IALU_CMD_SRL,          // op1 >> op2
    SCR1_IALU_CMD_SRA           // op1 >>> op2
`ifdef SCR1_RVM_EXT
    ,
    SCR1_IALU_CMD_MUL,          // low(unsig(op1) * unsig(op2))
    SCR1_IALU_CMD_MULHU,        // high(unsig(op1) * unsig(op2))
    SCR1_IALU_CMD_MULHSU,       // high(op1 * unsig(op2))
    SCR1_IALU_CMD_MULH,         // high(op1 * op2)
    SCR1_IALU_CMD_DIV,          // op1 / op2
    SCR1_IALU_CMD_DIVU,         // op1 u/ op2
    SCR1_IALU_CMD_REM,          // op1 % op2
    SCR1_IALU_CMD_REMU          // op1 u% op2
`endif  // SCR1_RVM_EXT
`ifdef SCR1_RVB_EXT
    ,
// Zba: address generation
    SCR1_IALU_CMD_SH1ADD,       // (op1 << 1) + op2
    SCR1_IALU_CMD_SH2ADD,       // (op1 << 2) + op2
    SCR1_IALU_CMD_SH3ADD,       // (op1 << 3) + op2
// Zbb: basic bit manipulation
    SCR1_IALU_CMD_ANDN,         // op1 & ~op2
    SCR1_IALU_CMD_ORN,          // op1 | ~op2
    SCR1_IALU_CMD_XNOR,         // ~(op1 ^ op2)
    SCR1_IALU_CMD_CLZ,          // count leading zeros
    SCR1_IALU_CMD_CTZ,          // count trailing zeros
    SCR1_IALU_CMD_CPOP,         // count set bits
    SCR1_IALU_CMD_MAX,          // signed max(op1, op2)
    SCR1_IALU_CMD_MAXU,         // unsigned max(op1, op2)
    SCR1_IALU_CMD_MIN,          // signed min(op1, op2)
    SCR1_IALU_CMD_MINU,         // unsigned min(op1, op2)
    SCR1_IALU_CMD_SEXTB,        // sign-extend byte
    SCR1_IALU_CMD_SEXTH,        // sign-extend halfword
    SCR1_IALU_CMD_ZEXTH,        // zero-extend halfword
    SCR1_IALU_CMD_ROL,          // rotate left  by op2[4:0]
    SCR1_IALU_CMD_ROR,          // rotate right by op2[4:0] (RORI reuses this with op2 = zero-extended shamt)
    SCR1_IALU_CMD_ORCB,         // bitwise-or-combine of every byte
// Zbc: carry-less multiplication
    SCR1_IALU_CMD_CLMUL,        // clmul  = P[31:0]
    SCR1_IALU_CMD_CLMULH,       // clmulh = P[63:32]
    SCR1_IALU_CMD_CLMULR,       // clmulr = P[62:31]
// Zbs: single-bit instructions
    SCR1_IALU_CMD_BCLR,         // op1 & ~(1 << op2[4:0])
    SCR1_IALU_CMD_BEXT,         // (op1 >> op2[4:0]) & 1
    SCR1_IALU_CMD_BINV,         // op1 ^ (1 << op2[4:0])
    SCR1_IALU_CMD_BSET          // op1 | (1 << op2[4:0])
`endif  // SCR1_RVB_EXT
} type_scr1_ialu_cmd_sel_e;

//-------------------------------------------------------------------------------
// IALU SUM2 operands (result is JUMP/BRANCH target, LOAD/STORE address)
//-------------------------------------------------------------------------------
localparam SCR1_SUM2_OP_ALL_NUM_E    = 2;
localparam SCR1_SUM2_OP_WIDTH_E      = $clog2(SCR1_SUM2_OP_ALL_NUM_E);
typedef enum logic [SCR1_SUM2_OP_WIDTH_E-1:0] {
    SCR1_SUM2_OP_PC_IMM,        // op1 = curr_pc; op2 = imm (AUIPC, target new_pc for JAL and branches)
    SCR1_SUM2_OP_REG_IMM        // op1 = rs1; op2 = imm (target new_pc for JALR, LOAD/STORE address)
`ifdef SCR1_XPROP_EN
    ,
    SCR1_SUM2_OP_ERROR = 'x
`endif // SCR1_XPROP_EN
} type_scr1_ialu_sum2_op_sel_e;

//-------------------------------------------------------------------------------
// LSU commands
//-------------------------------------------------------------------------------
localparam SCR1_LSU_CMD_ALL_NUM_E   = 9;
localparam SCR1_LSU_CMD_WIDTH_E     = $clog2(SCR1_LSU_CMD_ALL_NUM_E);
typedef enum logic [SCR1_LSU_CMD_WIDTH_E-1:0] {
    SCR1_LSU_CMD_NONE = '0,
    SCR1_LSU_CMD_LB,
    SCR1_LSU_CMD_LH,
    SCR1_LSU_CMD_LW,
    SCR1_LSU_CMD_LBU,
    SCR1_LSU_CMD_LHU,
    SCR1_LSU_CMD_SB,
    SCR1_LSU_CMD_SH,
    SCR1_LSU_CMD_SW
} type_scr1_lsu_cmd_sel_e;

//-------------------------------------------------------------------------------
// CSR operands
//-------------------------------------------------------------------------------
localparam SCR1_CSR_OP_ALL_NUM_E   = 2;
localparam SCR1_CSR_OP_WIDTH_E     = $clog2(SCR1_CSR_OP_ALL_NUM_E);
typedef enum logic [SCR1_CSR_OP_WIDTH_E-1:0] {
    SCR1_CSR_OP_IMM,
    SCR1_CSR_OP_REG
} type_scr1_csr_op_sel_e;

//-------------------------------------------------------------------------------
// CSR commands
//-------------------------------------------------------------------------------
localparam SCR1_CSR_CMD_ALL_NUM_E   = 4;
localparam SCR1_CSR_CMD_WIDTH_E     = $clog2(SCR1_CSR_CMD_ALL_NUM_E);
typedef enum logic [SCR1_CSR_CMD_WIDTH_E-1:0] {
    SCR1_CSR_CMD_NONE = '0,
    SCR1_CSR_CMD_WRITE,
    SCR1_CSR_CMD_SET,
    SCR1_CSR_CMD_CLEAR
} type_scr1_csr_cmd_sel_e;

//-------------------------------------------------------------------------------
// MPRF rd writeback source
//-------------------------------------------------------------------------------
`ifdef SCR1_RVX_EXT
localparam SCR1_RD_WB_ALL_NUM_E = 8;
`else // ~SCR1_RVX_EXT
localparam SCR1_RD_WB_ALL_NUM_E = 7;
`endif // ~SCR1_RVX_EXT
localparam SCR1_RD_WB_WIDTH_E   = $clog2(SCR1_RD_WB_ALL_NUM_E);
typedef enum logic [SCR1_RD_WB_WIDTH_E-1:0] {
    SCR1_RD_WB_NONE = '0,
    SCR1_RD_WB_IALU,            // IALU main result
    SCR1_RD_WB_SUM2,            // IALU SUM2 result (AUIPC)
    SCR1_RD_WB_IMM,             // LUI
    SCR1_RD_WB_INC_PC,          // JAL(R)
    SCR1_RD_WB_LSU,             // Load from DMEM
    SCR1_RD_WB_CSR              // Read CSR
`ifdef SCR1_RVX_EXT
    ,
    SCR1_RD_WB_CFU              // CFU result via CV-X-IF
`endif // SCR1_RVX_EXT
} type_scr1_rd_wb_sel_e;

//-------------------------------------------------------------------------------
// IDU to EXU full command structure
//-------------------------------------------------------------------------------
localparam SCR1_GPR_FIELD_WIDTH = 5;

typedef struct packed {
    logic                               instr_rvc;      // used with a different meaning for IFU access fault exception
    type_scr1_ialu_op_sel_e             ialu_op;
    type_scr1_ialu_cmd_sel_e            ialu_cmd;
    type_scr1_ialu_sum2_op_sel_e        sum2_op;
    type_scr1_lsu_cmd_sel_e             lsu_cmd;
    type_scr1_csr_op_sel_e              csr_op;
    type_scr1_csr_cmd_sel_e             csr_cmd;
    type_scr1_rd_wb_sel_e               rd_wb_sel;
    logic                               jump_req;
    logic                               branch_req;
    logic                               mret_req;
    logic                               fencei_req;
    logic                               wfi_req;
    logic [SCR1_GPR_FIELD_WIDTH-1:0]    rs1_addr;       // also used as zimm for CSRRxI instructions
    logic [SCR1_GPR_FIELD_WIDTH-1:0]    rs2_addr;
    logic [SCR1_GPR_FIELD_WIDTH-1:0]    rd_addr;
    logic [`SCR1_XLEN-1:0]              imm;            // used as {funct3, CSR address} for CSR instructions
                                                        // used as instruction field for illegal instruction exception
    logic                               exc_req;
    type_scr1_exc_code_e                exc_code;
`ifdef SCR1_RVX_EXT
    logic                               cfu_req;       // custom instruction flag (CV-X-IF)
`endif // SCR1_RVX_EXT
} type_scr1_exu_cmd_s;

`ifdef SCR1_RVX_EXT
//-------------------------------------------------------------------------------
// CV-X-IF request channel (Core -> CFU)
//-------------------------------------------------------------------------------
typedef struct packed {
    logic                   req_valid;
    logic [`SCR1_XLEN-1:0]  req_instr;
    logic [`SCR1_XLEN-1:0]  req_rs1;
    logic                   req_rs1_valid;
    logic [`SCR1_XLEN-1:0]  req_rs2;
    logic                   req_rs2_valid;
    logic [1:0]             req_mode;
    logic                   core_ready;
} type_scr1_cvxif_req_s;

//-------------------------------------------------------------------------------
// CV-X-IF response channel (CFU -> Core)
//-------------------------------------------------------------------------------
typedef struct packed {
    logic                   resp_valid;
    logic                   cfu_ready;
    logic [`SCR1_XLEN-1:0]  resp_result;
    logic                   resp_exc;
    type_scr1_exc_code_e    resp_exc_code;
} type_scr1_cvxif_resp_s;
`endif // SCR1_RVX_EXT


`endif // SCR1_RISCV_ISA_DECODING_SVH

