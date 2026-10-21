/// Copyright by Syntacore LLC © 2016-2021. See LICENSE for details
/// @file       <scr1_pipe_cfu_mtx.sv>
/// @brief      SCR1 CFU with Matrix Multiply extension (v2)
///
/// @details    Combined CFU handling custom-0 ALU (single-cycle) and custom-1
///             matrix multiply with posted-write + fence + error contract.
///
///             Custom-0 (opcode 0x0b, funct7=0):
///               funct3=0..7 -> cfu_add/xor/sub/and/or/sll/srl/mul
///
///             Custom-1 (opcode 0x2b):
///               funct7=0,  funct3=0/1/2 -> matmul4/4h/4b (LD_A->LD_B->COMP->DONE)
///               funct7=1,  funct3=0     -> mcfg_stride rs1
///               funct7=2,  funct3=0     -> mcfg_msk   rs1
///               funct7=3,  funct3=0     -> mcfg_cbase rs1
///               funct7=0x15,funct3=0    -> xwait  (fence: drain post queue, rd=status)
///               funct7=0x16,funct3=0    -> stc    (posted write acc[0..15] to rs1)
///
///             matmul4 computes C=A*B into internal acc, does NOT write memory.
///             stc enqueues acc for background write (posted, non-blocking).
///             xwait drains the queue and returns {hw[15:0], err_cnt[7:0], err_sticky}.
///
///             Error contract: any DMEM error sets err_sticky+err_cnt.  While
///             err_sticky is set, every non-xwait instruction is rejected
///             (illegal exception).  xwait clears err_sticky.

`include "scr1_arch_description.svh"
`include "scr1_arch_types.svh"
`include "scr1_memif.svh"
`include "scr1_riscv_isa_decoding.svh"

`ifdef SCR1_RVX_EXT
module scr1_pipe_cfu_mtx #(
    parameter int unsigned MAX_LATENCY     = 256,
    parameter int unsigned MAX_OUTSTANDING = 4,
    parameter int unsigned MAC_PARALLEL    = 1,
    parameter int unsigned POST_DEPTH      = 2
) (
    input   logic                   clk,
    input   logic                   rst_n,
    input   type_scr1_cvxif_req_s   cvxif_req_i,
    output  type_scr1_cvxif_resp_s  cvxif_resp_o
`ifdef SCR1_MTX_EXT
    ,
    output  type_scr1_cfu_dmem_req_s   cfu_dmem_req_o,
    input   type_scr1_cfu_dmem_resp_s  cfu_dmem_resp_i
`endif // SCR1_MTX_EXT
);

//------------------------------------------------------------------------------
// Instruction field extraction
//------------------------------------------------------------------------------
logic [6:2]  cfu_opcode;
logic [2:0]  cfu_funct3;
logic [6:0]  cfu_funct7;

assign cfu_opcode = cvxif_req_i.req_instr[6:2];
assign cfu_funct3 = cvxif_req_i.req_instr[14:12];
assign cfu_funct7 = cvxif_req_i.req_instr[31:25];

logic is_custom0;
logic is_custom1;
assign is_custom0 = (cfu_opcode == SCR1_OPCODE_CUSTOM_0);
assign is_custom1 = (cfu_opcode == SCR1_OPCODE_CUSTOM_1);

//------------------------------------------------------------------------------
// Custom-0 ALU path (single-cycle, combinational)
//------------------------------------------------------------------------------
logic [`SCR1_XLEN-1:0] alu_result;
logic                   alu_legal;

always_comb begin
    alu_result = '0;
    alu_legal  = 1'b0;
    if (is_custom0 && cfu_funct7 == 7'b0) begin
        alu_legal = 1'b1;
        case (cfu_funct3)
            3'b000:  alu_result = cvxif_req_i.req_rs1 + cvxif_req_i.req_rs2;
            3'b001:  alu_result = cvxif_req_i.req_rs1 ^ cvxif_req_i.req_rs2;
            3'b010:  alu_result = cvxif_req_i.req_rs1 - cvxif_req_i.req_rs2;
            3'b011:  alu_result = cvxif_req_i.req_rs1 & cvxif_req_i.req_rs2;
            3'b100:  alu_result = cvxif_req_i.req_rs1 | cvxif_req_i.req_rs2;
            3'b101:  alu_result = cvxif_req_i.req_rs1 << cvxif_req_i.req_rs2[4:0];
            3'b110:  alu_result = cvxif_req_i.req_rs1 >> cvxif_req_i.req_rs2[4:0];
            3'b111:  alu_result = cvxif_req_i.req_rs1 * cvxif_req_i.req_rs2;
            default: alu_legal  = 1'b0;
        endcase
    end
end

`ifdef SCR1_MTX_EXT
//------------------------------------------------------------------------------
// Custom-1 Matrix Multiply path
//------------------------------------------------------------------------------

// Instruction classification
logic is_matmul;
logic is_mcfg_stride;
logic is_mcfg_msk;
logic is_mcfg_cbase;
logic is_stc;
logic is_xwait;
logic is_mcfg;
logic is_mtx_single;
logic is_mtx_multi;

assign is_matmul      = is_custom1 && (cfu_funct7 == 7'b0000000) && (cfu_funct3 inside {3'b000, 3'b001, 3'b010});
assign is_mcfg_stride = is_custom1 && (cfu_funct7 == 7'b0000001) && (cfu_funct3 == 3'b000);
assign is_mcfg_msk    = is_custom1 && (cfu_funct7 == 7'b0000010) && (cfu_funct3 == 3'b000);
assign is_mcfg_cbase  = is_custom1 && (cfu_funct7 == 7'b0000011) && (cfu_funct3 == 3'b000);
assign is_xwait       = is_custom1 && (cfu_funct7 == 7'b0010101) && (cfu_funct3 == 3'b000);
assign is_stc         = is_custom1 && (cfu_funct7 == 7'b0010110) && (cfu_funct3 == 3'b000);
assign is_mcfg        = is_mcfg_stride | is_mcfg_msk | is_mcfg_cbase;
assign is_mtx_single  = is_mcfg | is_stc;
assign is_mtx_multi   = is_matmul | is_xwait;

// Legality checks
logic mtx_single_legal;
logic stride_illegal;

assign stride_illegal   = (cvxif_req_i.req_rs1 == 0) || (cvxif_req_i.req_rs1[31:8] != 0);
assign mtx_single_legal = is_mcfg_msk    ? (cvxif_req_i.req_rs1[1:0] != 2'b11)
                        : is_mcfg_stride ? ~stride_illegal
                        : is_mcfg_cbase  ? 1'b1
                        : is_stc         ? 1'b1
                        : 1'b0;

// Element size log2: matmul4=2, matmul4h=1, matmul4b=0
logic [1:0] esz_log2;
always_comb begin
    case (cfu_funct3)
        3'b000:  esz_log2 = 2'd2;
        3'b001:  esz_log2 = 2'd1;
        3'b010:  esz_log2 = 2'd0;
        default: esz_log2 = 2'd2;
    endcase
end

type_scr1_mem_width_e esz_width;
always_comb begin
    case (esz_log2)
        2'd2:    esz_width = SCR1_MEM_WIDTH_WORD;
        2'd1:    esz_width = SCR1_MEM_WIDTH_HWORD;
        default: esz_width = SCR1_MEM_WIDTH_BYTE;
endcase
end

//------------------------------------------------------------------------------
// Configuration registers
//------------------------------------------------------------------------------
logic [7:0]             stride_ff;
logic [1:0]             msk_ff;
logic [`SCR1_XLEN-1:0]  cbase_ff;

//------------------------------------------------------------------------------
// Error contract
//------------------------------------------------------------------------------
logic       err_sticky;
logic [7:0] err_cnt;
logic       fg_mem_err;   // foreground single-cycle pulse
logic       bg_mem_err;   // background single-cycle pulse
logic       mem_err;      // combined (combinational)

//------------------------------------------------------------------------------
// Matrix multiply FSM (foreground)
//------------------------------------------------------------------------------
typedef enum logic [2:0] {
    MTX_IDLE,
    MTX_LD_A,
    MTX_LD_B,
    MTX_COMP,
    MTX_DONE
} mtx_state_e;

mtx_state_e mtx_state;

logic [`SCR1_XLEN-1:0] base_a_ff;
logic [`SCR1_XLEN-1:0] base_b_ff;
logic [1:0]             esz_ff;
type_scr1_mem_width_e   esz_width_ff;
logic                   signed_ff;

logic [4:0] elem_idx;
logic       fg_wait_resp;
logic       bg_wait_resp;
logic       dma_wait_resp;
logic       dma_is_fg;
logic [4:0] comp_idx;
logic [1:0] comp_k;

logic [`SCR1_XLEN-1:0] a_buf [0:15];
logic [`SCR1_XLEN-1:0] b_buf [0:15];
logic [`SCR1_XLEN-1:0] acc    [0:15];

//------------------------------------------------------------------------------
// Posted-write queue (depth POST_DEPTH)
//------------------------------------------------------------------------------
localparam int unsigned POST_WORDS = 16;

logic [1:0]               post_cnt;
logic                     post_wptr;
logic                     post_rptr;
logic [`SCR1_XLEN-1:0]    post_base   [0:POST_DEPTH-1];
logic [7:0]               post_stride [0:POST_DEPTH-1];
logic [`SCR1_XLEN-1:0]    post_data   [0:POST_DEPTH-1][0:POST_WORDS-1];

logic                     post_enq;
logic                     post_pop;
logic [1:0]               post_hw;

logic                     queue_full;
assign queue_full = (post_cnt == POST_DEPTH[1:0]);

//------------------------------------------------------------------------------
// Background drain FSM
//------------------------------------------------------------------------------
typedef enum logic [1:0] {
    POST_IDLE,
    POST_REQ,
    POST_WAIT
} post_state_e;

post_state_e post_state;
logic [4:0]  post_idx;

//------------------------------------------------------------------------------
// Address generation
//------------------------------------------------------------------------------
function automatic logic [`SCR1_DMEM_AWIDTH-1:0] gen_elem_addr(
    input logic [`SCR1_XLEN-1:0] base,
    input logic [7:0]             stride,
    input logic [3:0]             idx,
    input logic [1:0]             esz
);
    logic [11:0] offset;
    offset = idx[3:2] * stride + {4'b0, idx[1:0]};
    return base + (offset << esz);
endfunction

//------------------------------------------------------------------------------
// DMA request arbitration (foreground priority)
//------------------------------------------------------------------------------
logic fg_want_req;
logic bg_want_req;
logic [`SCR1_DMEM_AWIDTH-1:0] fg_addr;
logic [`SCR1_DMEM_AWIDTH-1:0] bg_addr;

assign fg_want_req = ((mtx_state == MTX_LD_A) || (mtx_state == MTX_LD_B))
                     && !fg_wait_resp && (elem_idx < 5'd16);

assign bg_want_req = (post_state == POST_REQ)
                     && !bg_wait_resp && !fg_want_req && !fg_wait_resp;

assign fg_addr = gen_elem_addr(
    (mtx_state == MTX_LD_B) ? base_b_ff : base_a_ff,
    stride_ff, elem_idx[3:0], esz_ff);

assign bg_addr = gen_elem_addr(
    post_base[post_rptr],
    post_stride[post_rptr],
    post_idx[3:0],
    2'd2  // results always word
);

logic dma_req;
type_scr1_mem_cmd_e   dma_cmd;
type_scr1_mem_width_e dma_width;
logic [`SCR1_DMEM_DWIDTH-1:0] dma_wdata;

assign dma_req   = fg_want_req | bg_want_req;
assign dma_cmd   = fg_want_req ? SCR1_MEM_CMD_RD : SCR1_MEM_CMD_WR;
assign dma_width = fg_want_req ? esz_width_ff    : SCR1_MEM_WIDTH_WORD;
assign dma_wdata = fg_want_req ? '0              : post_data[post_rptr][post_idx[3:0]];

logic dma_resp_ok;
logic dma_resp_er;
assign dma_resp_ok = (cfu_dmem_resp_i.resp == SCR1_MEM_RESP_RDY_OK);
assign dma_resp_er = (cfu_dmem_resp_i.resp == SCR1_MEM_RESP_RDY_ER);

// Combined signals (combinational - each var driven in only one always_ff)
assign dma_wait_resp = fg_wait_resp | bg_wait_resp;
assign dma_is_fg     = fg_wait_resp;
assign mem_err       = fg_mem_err | bg_mem_err;

//------------------------------------------------------------------------------
// MAC operands
//------------------------------------------------------------------------------
function automatic logic [31:0] extend_elem(
    input logic [31:0] raw,
    input logic [1:0]  esz,
    input logic        signed_mode
);
    case (esz)
        2'd2:    return raw;
        2'd1:    return signed_mode ? {{16{raw[15]}}, raw[15:0]} : {16'b0, raw[15:0]};
        default: return signed_mode ? {{24{raw[7]}},  raw[7:0]}  : {24'b0, raw[7:0]};
    endcase
endfunction

logic [31:0] mac_a_val;
logic [31:0] mac_b_val;
logic [3:0]  mac_a_idx;
logic [3:0]  mac_b_idx;
always_comb begin
    mac_a_idx = {comp_idx[3:2], comp_k};
    mac_b_idx = {comp_k, comp_idx[1:0]};
    mac_a_val = extend_elem(a_buf[mac_a_idx], esz_ff, signed_ff);
    mac_b_val = extend_elem(b_buf[mac_b_idx], esz_ff, signed_ff);
end

//------------------------------------------------------------------------------
// xwait status word
//------------------------------------------------------------------------------
logic [`SCR1_XLEN-1:0] xwait_status;
assign xwait_status = {16'(post_hw), err_cnt, 7'b0, err_sticky};

//------------------------------------------------------------------------------
// Foreground FSM
//------------------------------------------------------------------------------
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        mtx_state     <= MTX_IDLE;
        stride_ff     <= 8'd4;
        msk_ff        <= 2'b01;
        cbase_ff      <= '0;
        base_a_ff     <= '0;
        base_b_ff     <= '0;
        esz_ff        <= 2'd2;
        esz_width_ff  <= SCR1_MEM_WIDTH_WORD;
        signed_ff     <= 1'b1;
        elem_idx      <= '0;
        fg_wait_resp  <= 1'b0;
        fg_mem_err    <= 1'b0;
        comp_idx      <= '0;
        comp_k        <= '0;
        for (int i = 0; i < 16; i++) begin
            a_buf[i] <= '0;
            b_buf[i] <= '0;
            acc[i]   <= '0;
        end
    end else begin
        // Default
        fg_mem_err <= 1'b0;

        case (mtx_state)
            MTX_IDLE: begin
                if (cvxif_req_i.req_valid && is_matmul && cvxif_req_i.core_ready && !err_sticky) begin
                    base_a_ff    <= cvxif_req_i.req_rs1;
                    base_b_ff    <= cvxif_req_i.req_rs2;
                    esz_ff       <= esz_log2;
                    esz_width_ff <= esz_width;
                    signed_ff    <= msk_ff[0];
                    elem_idx     <= '0;
                    fg_wait_resp <= 1'b0;
                    comp_idx     <= '0;
                    comp_k       <= '0;
                    for (int i = 0; i < 16; i++) acc[i] <= '0;
                    mtx_state    <= MTX_LD_A;
                end
                if (cvxif_req_i.req_valid && is_mcfg_stride && cvxif_req_i.core_ready)
                    stride_ff <= cvxif_req_i.req_rs1[7:0];
                if (cvxif_req_i.req_valid && is_mcfg_msk && cvxif_req_i.core_ready)
                    msk_ff <= cvxif_req_i.req_rs1[1:0];
                if (cvxif_req_i.req_valid && is_mcfg_cbase && cvxif_req_i.core_ready)
                    cbase_ff <= cvxif_req_i.req_rs1;
            end

            MTX_LD_A: begin
                if (fg_want_req && !fg_wait_resp) begin
                    if (cfu_dmem_resp_i.req_ack) begin
                        fg_wait_resp <= 1'b1;
                    end
                end else begin
                    if (dma_resp_ok) begin
                        a_buf[elem_idx[3:0]] <= cfu_dmem_resp_i.rdata;
                        elem_idx <= elem_idx + 1'b1;
                        fg_wait_resp <= 1'b0;
                    end else if (dma_resp_er) begin
                        fg_mem_err <= 1'b1;
                        mtx_state <= MTX_DONE;
                    end
                end
                if (elem_idx == 5'd16 && !fg_wait_resp) begin
                    elem_idx  <= '0;
                    mtx_state <= MTX_LD_B;
                end
            end

            MTX_LD_B: begin
                if (fg_want_req && !fg_wait_resp) begin
                    if (cfu_dmem_resp_i.req_ack) begin
                        fg_wait_resp <= 1'b1;
                    end
                end else begin
                    if (dma_resp_ok) begin
                        b_buf[elem_idx[3:0]] <= cfu_dmem_resp_i.rdata;
                        elem_idx <= elem_idx + 1'b1;
                        fg_wait_resp <= 1'b0;
                    end else if (dma_resp_er) begin
                        fg_mem_err <= 1'b1;
                        mtx_state <= MTX_DONE;
                    end
                end
                if (elem_idx == 5'd16 && !fg_wait_resp) begin
                    elem_idx  <= '0;
                    comp_idx  <= '0;
                    comp_k    <= '0;
                    mtx_state <= MTX_COMP;
                end
            end

            MTX_COMP: begin
                acc[comp_idx[3:0]] <= acc[comp_idx[3:0]] + (mac_a_val * mac_b_val);
                if (comp_k == 2'd3) begin
                    comp_k <= '0;
                    if (comp_idx == 5'd15) begin
                        comp_idx <= '0;
                        mtx_state <= MTX_DONE;
                    end else begin
                        comp_idx <= comp_idx + 1'b1;
                    end
                end else begin
                    comp_k <= comp_k + 1'b1;
                end
            end

            MTX_DONE: begin
                if (cvxif_req_i.core_ready)
                    mtx_state <= MTX_IDLE;
            end

            default: mtx_state <= MTX_IDLE;
        endcase
    end
end

// stc enqueue: combinational, snapshot taken in the SAME cycle as the
// instruction (a registered pulse would sample the NEXT instruction's
// rs1 - the classic commit-cycle-snapshot pitfall)
assign post_enq = (mtx_state == MTX_IDLE) && cvxif_req_i.req_valid
                  && is_stc && cvxif_req_i.core_ready
                  && !err_sticky && !queue_full;


//------------------------------------------------------------------------------
// Background drain FSM
//------------------------------------------------------------------------------
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        post_state  <= POST_IDLE;
        post_idx    <= '0;
        post_pop    <= 1'b0;
        bg_wait_resp <= 1'b0;
        bg_mem_err  <= 1'b0;
    end else begin
        post_pop <= 1'b0;
        bg_mem_err <= 1'b0;
        case (post_state)
            POST_IDLE: begin
                // !post_pop guard: in the cycle post_pop is asserted the
                // post_cnt register still holds the OLD value; restarting
                // here would drain an already-empty slot (base 0) and
                // underflow the count into an infinite re-drain loop.
                if ((post_cnt != 2'd0) && !post_pop && !bg_wait_resp) begin
                    post_idx   <= '0;
                    post_state <= POST_REQ;
                end
            end
            POST_REQ: begin
                if (!bg_wait_resp && !fg_want_req && !fg_wait_resp) begin
                    if (cfu_dmem_resp_i.req_ack) begin
                        bg_wait_resp <= 1'b1;
                    end
                end else if (bg_wait_resp) begin
                    if (dma_resp_ok || dma_resp_er) begin
                        if (dma_resp_er) bg_mem_err <= 1'b1;
                        if (post_idx + 5'd1 >= 5'd16) begin
                            post_pop <= 1'b1;
                            post_state <= POST_IDLE;
                        end else begin
                           post_idx <= post_idx + 5'd1;
                        end
                        bg_wait_resp <= 1'b0;
                    end
                end
            end
            default: post_state <= POST_IDLE;
        endcase
    end
end

//------------------------------------------------------------------------------
// Posted-write queue management
//------------------------------------------------------------------------------
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        post_cnt  <= 2'd0;
        post_wptr <= 1'b0;
        post_rptr <= 1'b0;
    end else begin
        case ({post_enq, post_pop})
            2'b10:   begin post_wptr <= ~post_wptr; post_cnt <= post_cnt + 2'd1; end
            2'b01:   begin post_rptr <= ~post_rptr; post_cnt <= post_cnt - 2'd1; end
            2'b11:   begin post_wptr <= ~post_wptr; post_rptr <= ~post_rptr; end
            default: ;
        endcase
    end
end

// Snapshot acc into queue on enqueue
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (int d = 0; d < POST_DEPTH; d++) begin
            post_base[d]   <= '0;
            post_stride[d] <= '0;
            for (int w = 0; w < POST_WORDS; w++) post_data[d][w] <= '0;
        end
    end else if (post_enq) begin
        post_base[post_wptr]   <= cvxif_req_i.req_rs1;
        post_stride[post_wptr] <= stride_ff;
        for (int w = 0; w < 16; w++)
            post_data[post_wptr][w] <= acc[w];
    end
end

// High-water mark
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n)                  post_hw <= '0;
    else if (post_cnt > post_hw) post_hw <= post_cnt;
end

//------------------------------------------------------------------------------
// Error status
//------------------------------------------------------------------------------
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        err_sticky <= 1'b0;
        err_cnt    <= '0;
    end else begin
        if (mem_err) begin
            err_sticky <= 1'b1;
            err_cnt    <= err_cnt + 8'd1;
        end
        // xwait consumes the sticky flag
        if (cvxif_req_i.req_valid && is_xwait && cvxif_req_i.core_ready
            && mtx_state == MTX_IDLE && post_cnt == 2'd0)
            err_sticky <= 1'b0;
    end
end

//------------------------------------------------------------------------------
// DMEM master interface
//------------------------------------------------------------------------------
assign cfu_dmem_req_o.req   = dma_req;
assign cfu_dmem_req_o.cmd   = dma_cmd;
assign cfu_dmem_req_o.width = dma_width;
assign cfu_dmem_req_o.addr  = fg_want_req ? fg_addr : bg_addr;
assign cfu_dmem_req_o.wdata = dma_wdata;

`endif // SCR1_MTX_EXT

//------------------------------------------------------------------------------
// CV-X-IF response channel
//------------------------------------------------------------------------------
logic is_single_cycle;
logic is_multi_cycle;
logic single_legal;
logic [`SCR1_XLEN-1:0] single_result;

always_comb begin
`ifdef SCR1_MTX_EXT
    is_single_cycle = is_custom0 | is_mcfg | is_stc;
    is_multi_cycle  = is_matmul | is_xwait;
    single_legal    = is_custom0 ? alu_legal
                    : is_mcfg ? mtx_single_legal
                    : is_stc  ? 1'b1
                    : 1'b0;
    single_result   = is_custom0 ? alu_result : '0;
`else
    is_single_cycle = 1'b1;
    is_multi_cycle  = 1'b0;
    single_legal    = alu_legal;
    single_result   = alu_result;
`endif
end

always_comb begin
`ifdef SCR1_MTX_EXT
    if (mtx_state == MTX_IDLE) begin
        // Backpressure: stc waits when the post queue is full (write-buffer
        // semantics - the core stalls on the instruction until there is room)
        if (cvxif_req_i.req_valid && is_stc && queue_full && !err_sticky) begin
            cvxif_resp_o.cfu_ready  = 1'b0;
            cvxif_resp_o.resp_valid   = 1'b0;
            cvxif_resp_o.resp_result  = '0;
            cvxif_resp_o.resp_exc     = 1'b0;
            cvxif_resp_o.resp_exc_code = SCR1_EXC_CODE_ILLEGAL_INSTR;
        end
        // Reject all non-xwait instructions when err_sticky is set
        else if (err_sticky && cvxif_req_i.req_valid && !is_xwait && (is_custom0 | is_mcfg | is_stc | is_matmul)) begin
            cvxif_resp_o.cfu_ready  = 1'b1;
            cvxif_resp_o.resp_valid   = cvxif_req_i.req_valid;
            cvxif_resp_o.resp_result  = '0;
            cvxif_resp_o.resp_exc     = 1'b1;
            cvxif_resp_o.resp_exc_code = SCR1_EXC_CODE_ILLEGAL_INSTR;
        end else begin
            cvxif_resp_o.cfu_ready  = 1'b1;
            cvxif_resp_o.resp_valid   = cvxif_req_i.req_valid & is_single_cycle;
            cvxif_resp_o.resp_result  = single_result;
            cvxif_resp_o.resp_exc     = cvxif_req_i.req_valid & is_single_cycle & ~single_legal;
            cvxif_resp_o.resp_exc_code = SCR1_EXC_CODE_ILLEGAL_INSTR;
        end
    end else if (mtx_state == MTX_DONE) begin
        cvxif_resp_o.cfu_ready  = 1'b0;
        cvxif_resp_o.resp_valid   = 1'b1;
        cvxif_resp_o.resp_result  = {31'b0, ~mem_err};
        cvxif_resp_o.resp_exc     = mem_err;
        cvxif_resp_o.resp_exc_code = mem_err ? SCR1_EXC_CODE_LD_ACCESS_FAULT
                                              : SCR1_EXC_CODE_ILLEGAL_INSTR;
    end else begin
        cvxif_resp_o.cfu_ready    = 1'b0;
        cvxif_resp_o.resp_valid   = 1'b0;
        cvxif_resp_o.resp_result  = '0;
        cvxif_resp_o.resp_exc     = 1'b0;
        cvxif_resp_o.resp_exc_code = SCR1_EXC_CODE_ILLEGAL_INSTR;
    end

    // xwait: multi-cycle, waits for queue drain
    if (is_xwait && mtx_state == MTX_IDLE && post_cnt == 2'd0
        && cvxif_req_i.req_valid && cvxif_req_i.core_ready) begin
        cvxif_resp_o.cfu_ready  = 1'b1;
        cvxif_resp_o.resp_valid = 1'b1;
        cvxif_resp_o.resp_result = xwait_status;
        cvxif_resp_o.resp_exc    = 1'b0;
        cvxif_resp_o.resp_exc_code = SCR1_EXC_CODE_ILLEGAL_INSTR;
    end
`else
    cvxif_resp_o.cfu_ready    = 1'b1;
    cvxif_resp_o.resp_valid   = cvxif_req_i.req_valid;
    cvxif_resp_o.resp_result  = alu_result;
    cvxif_resp_o.resp_exc     = cvxif_req_i.req_valid & ~alu_legal;
    cvxif_resp_o.resp_exc_code = SCR1_EXC_CODE_ILLEGAL_INSTR;
`endif
end


endmodule : scr1_pipe_cfu_mtx
`endif // SCR1_RVX_EXT