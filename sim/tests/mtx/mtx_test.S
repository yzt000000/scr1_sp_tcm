/// @file       <mtx_test.S>
/// @brief      Matrix Multiply extension assembly test (v2: posted write)
///
/// mtx_run(a_base, b_base, c_base): a0/a1/a2 carry the matrix bases.
/// Configures CFU, invokes cfu.matmul4 (compute only), then stc (posted
/// write) and xwait (fence).  Returns a0 = error bits of the xwait status
/// (err_cnt | err_sticky; 0 = success).

.section .text
.align 2
.global mtx_run

# int mtx_run(int a_base, int b_base, int c_base)
mtx_run:
    # Set stride = 4 (compact 4x4)
    li      t0, 4
    .insn   r 0x2b, 0x0, 0x1, x0, t0, x0      # cfu.mcfg_stride t0

    # Set msk = 1 (signed)
    li      t0, 1
    .insn   r 0x2b, 0x0, 0x2, x0, t0, x0      # cfu.mcfg_msk t0

    # Set C base address (a2)
    .insn   r 0x2b, 0x0, 0x3, x0, a2, x0      # cfu.mcfg_cbase a2

    # Execute matmul4: acc = A * B (compute only, no memory write)
    .insn   r 0x2b, 0x0, 0x0, t2, a0, a1      # cfu.matmul4 t2, a0, a1

    # Posted store acc to C (non-blocking)
    .insn   r 0x2b, 0x0, 0x16, x0, a2, x0     # cfu.stc a2

    # Wait for posted write to complete, t2 = status word
    .insn   r 0x2b, 0x0, 0x15, t2, x0, x0     # cfu.xwait t2

    # t2 = status word ([31:16] hw, [15:8] err_cnt, [0] err_sticky)
    # Error bits: err_cnt (bits 15:8) | err_sticky (bit 0)
    li      t3, 0xFF01
    and     a0, t2, t3
    ret