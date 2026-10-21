/// @file       <mdu_latency.S>
/// @brief      Latency probe for the MDU / BALU instructions
///
/// Method
/// ------
/// Each instruction is repeated ITER times with CONSTANT, non-zero operands and
/// no data dependency between iterations:
///
///     li      t1, <non-zero>
///     li      t2, <non-zero>
///     csrr    t3, CSR_MCYCLE
///     .rept   ITER
///     insn    t0, t1, t2
///     .endr
///     csrr    t4, CSR_MCYCLE
///
/// Two properties make this the honest measurement:
///
///   * independence  - the core pipelines one instruction per cycle when the
///     functional unit is free, so cycles/op collapses to the occupancy of the
///     unit itself (the MDU has a single iteration FSM and cannot overlap);
///   * non-zero operands - the MDU short-circuits when either operand is zero,
///     so any sigma-reduction chain ending in zero would silently report 1 cycle.
///     Constant operands keep every iteration on the slow path.
///
/// latency_base() runs the same harness with ADD:
///
///     latency_xxx() - latency_base() == ITER * (latency - 1)
///
/// A delta of ~0     => single cycle
/// A delta of ~31000 => 32 iterations (radix-2 loop)
///
/// CSR_MCYCLE (0xB00) is used because it is always readable in M-mode, unlike
/// the cycle shadow which is gated by the custom MCOUNTEN CSR.
///
/// Every function clobbers t0/t1/t2/t3/t4 only (caller saved) and returns the
/// raw cycle count in a0.

#include "riscv_csr_encoding.h"

#define ITER 1000

// Operands are both odd: an odd * odd product keeps bit 0 set, so a repeated
// multiply chain could never short-circuit to zero even if it were dependent.
#define OP1 0x00030003
#define OP2 0x12345679

    .text

//------------------------------------------------------------------------------
// Harness baseline : ADD, single cycle
//------------------------------------------------------------------------------
    .globl  latency_base
latency_base:
    li      t1, OP1
    li      t2, OP2
    csrr    t3, CSR_MCYCLE
    .rept   ITER
    add     t0, t1, t2
    .endr
    csrr    t4, CSR_MCYCLE
    sub     a0, t4, t3
    ret

//------------------------------------------------------------------------------
// Zbb : single cycle reference (expected delta == 0)
//------------------------------------------------------------------------------
    .globl  latency_andn
latency_andn:
    li      t1, OP1
    li      t2, OP2
    csrr    t3, CSR_MCYCLE
    .rept   ITER
    andn    t0, t1, t2
    .endr
    csrr    t4, CSR_MCYCLE
    sub     a0, t4, t3
    ret

//------------------------------------------------------------------------------
// M extension : MUL - 1 cycle with SCR1_FAST_MUL, otherwise 32 iterations
//------------------------------------------------------------------------------
    .globl  latency_mul
latency_mul:
    li      t1, OP1
    li      t2, OP2
    csrr    t3, CSR_MCYCLE
    .rept   ITER
    mul     t0, t1, t2
    .endr
    csrr    t4, CSR_MCYCLE
    sub     a0, t4, t3
    ret

    .globl  latency_mulh
latency_mulh:
    li      t1, OP1
    li      t2, OP2
    csrr    t3, CSR_MCYCLE
    .rept   ITER
    mulh    t0, t1, t2
    .endr
    csrr    t4, CSR_MCYCLE
    sub     a0, t4, t3
    ret

//------------------------------------------------------------------------------
// M extension : DIV - always iterative, the "32 iteration" reference
//------------------------------------------------------------------------------
    .globl  latency_div
latency_div:
    li      t1, OP1
    li      t2, OP2
    csrr    t3, CSR_MCYCLE
    .rept   ITER
    div     t0, t1, t2
    .endr
    csrr    t4, CSR_MCYCLE
    sub     a0, t4, t3
    ret

//------------------------------------------------------------------------------
// Zbc : carry-less multiplication
//------------------------------------------------------------------------------
    .globl  latency_clmul
latency_clmul:
    li      t1, OP1
    li      t2, OP2
    csrr    t3, CSR_MCYCLE
    .rept   ITER
    clmul   t0, t1, t2
    .endr
    csrr    t4, CSR_MCYCLE
    sub     a0, t4, t3
    ret

    .globl  latency_clmulh
latency_clmulh:
    li      t1, OP1
    li      t2, OP2
    csrr    t3, CSR_MCYCLE
    .rept   ITER
    clmulh  t0, t1, t2
    .endr
    csrr    t4, CSR_MCYCLE
    sub     a0, t4, t3
    ret

    .globl  latency_clmulr
latency_clmulr:
    li      t1, OP1
    li      t2, OP2
    csrr    t3, CSR_MCYCLE
    .rept   ITER
    clmulr  t0, t1, t2
    .endr
    csrr    t4, CSR_MCYCLE
    sub     a0, t4, t3
    ret
