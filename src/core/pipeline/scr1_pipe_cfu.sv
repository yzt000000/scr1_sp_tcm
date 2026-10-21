/// Copyright by Syntaccore LLC (c) 2016-2021. See LICENSE for details
/// @file       <scr1_pipe_cfu.sv>
/// @brief      SCR1 CV-X-IF Custom Function Unit (CFU) reference implementation
///
/// Supports three modes via MAX_LATENCY parameter:
///   MAX_LATENCY = 0 : stub mode (all custom instructions trigger illegal exception)
///   MAX_LATENCY = 1 : single-cycle combinational CFU
///   MAX_LATENCY > 1 : multi-cycle CFU with internal state machine
///

`include "scr1_arch_description.svh"
`include "scr1_arch_types.svh"
`include "scr1_riscv_isa_decoding.svh"

`ifdef SCR1_RVX_EXT
module scr1_pipe_cfu #(
    parameter int unsigned MAX_LATENCY = 1
) (
    input  logic                   clk,
    input  logic                   rst_n,
    input  type_scr1_cvxif_req_s   cvxif_req_i,
    output type_scr1_cvxif_resp_s  cvxif_resp_o
);

//------------------------------------------------------------------------------
// Local signals
//------------------------------------------------------------------------------

// Instruction field extraction
logic [6:2]  cfu_opcode;
logic [2:0]  cfu_funct3;
logic [6:0]  cfu_funct7;

assign cfu_opcode = cvxif_req_i.req_instr[6:2];
assign cfu_funct3 = cvxif_req_i.req_instr[14:12];
assign cfu_funct7 = cvxif_req_i.req_instr[31:25];

// CFU computation result and legality flag
logic [`SCR1_XLEN-1:0] cfu_result;
logic                   cfu_legal;

//------------------------------------------------------------------------------
// Example custom instruction decode (custom-0 space, funct7=0)
//   funct3=0: cfu_add  rd, rs1, rs2 -> rd = rs1 + rs2
//   funct3=1: cfu_xor  rd, rs1, rs2 -> rd = rs1 ^ rs2
//   funct3=2: cfu_sub  rd, rs1, rs2 -> rd = rs1 - rs2
//   funct3=3: cfu_and  rd, rs1, rs2 -> rd = rs1 & rs2
//   funct3=4: cfu_or   rd, rs1, rs2 -> rd = rs1 | rs2
//   funct3=5: cfu_sll  rd, rs1, rs2 -> rd = rs1 << rs2[4:0]
//   funct3=6: cfu_srl  rd, rs1, rs2 -> rd = rs1 >> rs2[4:0]
//   funct3=7: cfu_mul  rd, rs1, rs2 -> rd = (rs1 * rs2)[31:0]
// All other encodings: illegal instruction
//------------------------------------------------------------------------------

always_comb begin
    cfu_result = '0;
    cfu_legal  = 1'b0;
    if (cfu_opcode == SCR1_OPCODE_CUSTOM_0 && cfu_funct7 == 7'b0) begin
        cfu_legal = 1'b1;
        case (cfu_funct3)
            3'b000:  cfu_result = cvxif_req_i.req_rs1 + cvxif_req_i.req_rs2;
            3'b001:  cfu_result = cvxif_req_i.req_rs1 ^ cvxif_req_i.req_rs2;
            3'b010:  cfu_result = cvxif_req_i.req_rs1 - cvxif_req_i.req_rs2;
            3'b011:  cfu_result = cvxif_req_i.req_rs1 & cvxif_req_i.req_rs2;
            3'b100:  cfu_result = cvxif_req_i.req_rs1 | cvxif_req_i.req_rs2;
            3'b101:  cfu_result = cvxif_req_i.req_rs1 << cvxif_req_i.req_rs2[4:0];
            3'b110:  cfu_result = cvxif_req_i.req_rs1 >> cvxif_req_i.req_rs2[4:0];
            3'b111:  cfu_result = cvxif_req_i.req_rs1 * cvxif_req_i.req_rs2;
            default: cfu_legal  = 1'b0;
        endcase
    end
end

//------------------------------------------------------------------------------
// CFU mode selection via generate
//------------------------------------------------------------------------------

generate

if (MAX_LATENCY == 0) begin : gen_stub
    // Stub mode: all custom instructions trigger illegal instruction exception
    assign cvxif_resp_o.resp_valid    = cvxif_req_i.req_valid;
    assign cvxif_resp_o.cfu_ready     = 1'b1;
    assign cvxif_resp_o.resp_result   = '0;
    assign cvxif_resp_o.resp_exc      = 1'b1;
    assign cvxif_resp_o.resp_exc_code = SCR1_EXC_CODE_ILLEGAL_INSTR;
    assign cvxif_resp_o.cfu_ready     = 1'b1;

end else if (MAX_LATENCY == 1) begin : gen_single_cycle
    // Single-cycle combinational CFU
    assign cvxif_resp_o.resp_valid    = cvxif_req_i.req_valid;
    assign cvxif_resp_o.cfu_ready     = 1'b1;
    assign cvxif_resp_o.resp_result   = cfu_result;
    assign cvxif_resp_o.resp_exc      = ~cfu_legal;
    assign cvxif_resp_o.resp_exc_code = SCR1_EXC_CODE_ILLEGAL_INSTR;

end else begin : gen_multi_cycle
    // Multi-cycle CFU with internal state machine
    typedef enum logic [1:0] {
        CFU_IDLE,
        CFU_COMPUTE,
        CFU_RESP
    } cfu_state_e;

    cfu_state_e             cfu_state;
    logic [`SCR1_XLEN-1:0] cfu_result_ff;
    logic                   cfu_legal_ff;
    logic [15:0]            lat_cnt;
    logic                   resp_valid;

    assign resp_valid = (cfu_state == CFU_RESP);

    always_ff @(posedge clk, negedge rst_n) begin
        if (~rst_n) begin
            cfu_state     <= CFU_IDLE;
            cfu_result_ff <= '0;
            cfu_legal_ff  <= 1'b0;
            lat_cnt       <= '0;
        end else begin
            case (cfu_state)
                CFU_IDLE : begin
                    if (cvxif_req_i.req_valid) begin
                        cfu_result_ff <= cfu_result;
                        cfu_legal_ff  <= cfu_legal;
                        cfu_state     <= CFU_COMPUTE;
                        lat_cnt       <= '0;
                    end
                end
                CFU_COMPUTE : begin
                    if (lat_cnt >= (MAX_LATENCY - 2)) begin
                        cfu_state <= CFU_RESP;
                    end else begin
                        lat_cnt <= lat_cnt + 1'b1;
                    end
                end
                CFU_RESP : begin
                    if (resp_valid) begin
                        cfu_state <= CFU_IDLE;
                        lat_cnt   <= '0;
                    end
                end
                default : cfu_state <= CFU_IDLE;
            endcase
        end
    end

    assign cvxif_resp_o.cfu_ready     = (cfu_state == CFU_IDLE);
    assign cvxif_resp_o.resp_valid    = resp_valid;
    assign cvxif_resp_o.resp_result   = cfu_result_ff;
    assign cvxif_resp_o.resp_exc      = resp_valid & ~cfu_legal_ff;
    assign cvxif_resp_o.resp_exc_code = SCR1_EXC_CODE_ILLEGAL_INSTR;


end // gen_multi_cycle

endgenerate

endmodule : scr1_pipe_cfu
`endif // SCR1_RVX_EXT