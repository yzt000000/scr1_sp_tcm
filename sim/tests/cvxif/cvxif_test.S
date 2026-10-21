/// @file       <cvxif_test.S>
/// @brief      CV-X-IF custom instruction assembly self-check
///
/// Tests all 8 reference CFU instructions (cfu_add/xor/sub/and/or/sll/srl/mul)
/// using .insn pseudo-instruction encoding, plus boundary value tests.
/// Returns error count in a0 (0 = all pass).

.section .text
.align 2
.global cvxif_run

# int cvxif_run(void)
# Returns: a0 = number of errors (0 = all pass)
cvxif_run:
    li      a0, 0               # error counter

    # === Test cfu_add (funct3=0) ===
    li      t0, 0x12345678
    li      t1, 0x9ABCDEF0
    .insn   r 0x0b, 0x0, 0x0, t2, t0, t1
    li      t3, 0xACF13568      # 0x12345678 + 0x9ABCDEF0
    bne     t2, t3, _err_add
    j       _test_xor
_err_add:
    addi    a0, a0, 1

_test_xor:
    # === Test cfu_xor (funct3=1) ===
    li      t0, 0x12345678
    li      t1, 0x9ABCDEF0
    .insn   r 0x0b, 0x1, 0x0, t2, t0, t1
    li      t3, 0x88888888      # 0x12345678 ^ 0x9ABCDEF0
    bne     t2, t3, _err_xor
    j       _test_sub
_err_xor:
    addi    a0, a0, 1

_test_sub:
    # === Test cfu_sub (funct3=2) ===
    li      t0, 0x12345678
    li      t1, 0x9ABCDEF0
    .insn   r 0x0b, 0x2, 0x0, t2, t0, t1
    li      t3, 0x77777788      # 0x12345678 - 0x9ABCDEF0
    bne     t2, t3, _err_sub
    j       _test_and
_err_sub:
    addi    a0, a0, 1

_test_and:
    # === Test cfu_and (funct3=3) ===
    li      t0, 0x12345678
    li      t1, 0x9ABCDEF0
    .insn   r 0x0b, 0x3, 0x0, t2, t0, t1
    li      t3, 0x12345670      # 0x12345678 & 0x9ABCDEF0
    bne     t2, t3, _err_and
    j       _test_or
_err_and:
    addi    a0, a0, 1

_test_or:
    # === Test cfu_or (funct3=4) ===
    li      t0, 0x12345678
    li      t1, 0x9ABCDEF0
    .insn   r 0x0b, 0x4, 0x0, t2, t0, t1
    li      t3, 0x9ABCDEF8      # 0x12345678 | 0x9ABCDEF0
    bne     t2, t3, _err_or
    j       _test_sll
_err_or:
    addi    a0, a0, 1

_test_sll:
    # === Test cfu_sll (funct3=5) ===
    li      t0, 0x12345678
    li      t1, 4
    .insn   r 0x0b, 0x5, 0x0, t2, t0, t1
    li      t3, 0x23456780      # 0x12345678 << 4
    bne     t2, t3, _err_sll
    j       _test_srl
_err_sll:
    addi    a0, a0, 1

_test_srl:
    # === Test cfu_srl (funct3=6) ===
    li      t0, 0x12345678
    li      t1, 4
    .insn   r 0x0b, 0x6, 0x0, t2, t0, t1
    li      t3, 0x01234567      # 0x12345678 >> 4
    bne     t2, t3, _err_srl
    j       _test_mul
_err_srl:
    addi    a0, a0, 1

_test_mul:
    # === Test cfu_mul (funct3=7) ===
    li      t0, 0x12345678
    li      t1, 2
    .insn   r 0x0b, 0x7, 0x0, t2, t0, t1
    li      t3, 0x2468ACF0      # 0x12345678 * 2
    bne     t2, t3, _err_mul
    j       _test_bnd1
_err_mul:
    addi    a0, a0, 1

    # === Boundary value tests ===
_test_bnd1:
    # add(0, 0) = 0
    li      t0, 0
    li      t1, 0
    .insn   r 0x0b, 0x0, 0x0, t2, t0, t1
    bne     t2, zero, _err_bnd1
    j       _test_bnd2
_err_bnd1:
    addi    a0, a0, 1

_test_bnd2:
    # add(0xFFFFFFFF, 1) = 0
    li      t0, -1
    li      t1, 1
    .insn   r 0x0b, 0x0, 0x0, t2, t0, t1
    bne     t2, zero, _err_bnd2
    j       _test_bnd3
_err_bnd2:
    addi    a0, a0, 1

_test_bnd3:
    # xor(0xFFFFFFFF, 0xFFFFFFFF) = 0
    li      t0, -1
    li      t1, -1
    .insn   r 0x0b, 0x1, 0x0, t2, t0, t1
    bne     t2, zero, _err_bnd3
    j       _test_bnd4
_err_bnd3:
    addi    a0, a0, 1

_test_bnd4:
    # sub(0, 1) = 0xFFFFFFFF
    li      t0, 0
    li      t1, 1
    .insn   r 0x0b, 0x2, 0x0, t2, t0, t1
    li      t3, -1
    bne     t2, t3, _err_bnd4
    j       _test_bnd5
_err_bnd4:
    addi    a0, a0, 1

_test_bnd5:
    # and(0xFFFFFFFF, 0) = 0
    li      t0, -1
    li      t1, 0
    .insn   r 0x0b, 0x3, 0x0, t2, t0, t1
    bne     t2, zero, _err_bnd5
    j       _test_bnd6
_err_bnd5:
    addi    a0, a0, 1

_test_bnd6:
    # mul(0x80000000, 2) = 0 (overflow)
    li      t0, 0x80000000
    li      t1, 2
    .insn   r 0x0b, 0x7, 0x0, t2, t0, t1
    bne     t2, zero, _err_bnd6
    j       _done
_err_bnd6:
    addi    a0, a0, 1

_done:
    ret