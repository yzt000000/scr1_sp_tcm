/// TCM Cross-Access Stress Test
///
/// Exercises imem_router and dmem_router port switching across:
///   - ITCM (0x00480000) instruction fetch  <-> RAM (0x0) instruction fetch
///   - DTCM (0x00490000) data access       <-> RAM (0x0) data access
///
/// Build: TCM=1 → code in ITCM, data in DTCM, load image in RAM.
/// Functions placed in .text.init stay in RAM and execute from there.
/// Functions in .text are copied to ITCM by RELOC_PROC and execute from there.
///
/// NOTE: jal has only ±1MB range. ITCM (0x00480000) to RAM (0x100) is ~4.7MB,
/// so cross-boundary calls use `call` (auipc+jalr, full 32-bit reach).
/// Same-section calls (ITCM→ITCM) keep `jal`.
///
/// Every non-leaf function must save/restore ra because jal/jalr/call
/// clobber ra.  fail uses `tail sc_exit` instead of ret.

#include "riscv_csr_encoding.h"
#include "sc_test.h"

#define TESTNUM gp

#define PASS_VAL 0
#define FAIL_VAL 1

#define RAM_DATA_BASE 0x1000

    .globl main

    .text

main:
    addi sp, sp, -16
    sw   ra, 0(sp)
    li   TESTNUM, 0

    jal  tc1_itcm_to_ram_call
    jal  tc2_ram_to_itcm_call
    jal  tc3_rapid_switching
    jal  tc4_itcm_access_dtcm
    jal  tc5_itcm_access_ram
    jal  tc6_ram_access_dtcm
    jal  tc7_nested_cross_calls
    jal  tc8_dmem_during_imem_switch
    jal  tc9_jalr_across_boundary
    jal  tc10_itcm_boundary_jump

    li   a0, PASS_VAL
    lw   ra, 0(sp)
    addi sp, sp, 16
    ret

fail:
    li   a0, FAIL_VAL
    tail sc_exit

    .balign 32

tc1_itcm_to_ram_call:
    addi sp, sp, -16
    sw   ra, 0(sp)
    li   TESTNUM, 1
    li   t0, 0x1111
    call ram_func_inc
    li   t1, 0x1112
    bne  t0, t1, fail
    lw   ra, 0(sp)
    addi sp, sp, 16
    ret

    .balign 32

tc2_ram_to_itcm_call:
    addi sp, sp, -16
    sw   ra, 0(sp)
    li   TESTNUM, 2
    li   t0, 0x2222
    call ram_caller_to_itcm
    li   t1, 0x2223
    bne  t0, t1, fail
    lw   ra, 0(sp)
    addi sp, sp, 16
    ret

    .balign 32

tc3_rapid_switching:
    addi sp, sp, -16
    sw   ra, 0(sp)
    li   TESTNUM, 3
    li   t0, 0
    li   t2, 20
tc3_loop:
    call ram_func_inc
    jal  itcm_func_inc
    addi t2, t2, -1
    bnez t2, tc3_loop
    li   t1, 40
    bne  t0, t1, fail
    lw   ra, 0(sp)
    addi sp, sp, 16
    ret

    .balign 32

tc4_itcm_access_dtcm:
    li   TESTNUM, 4
    la   t0, dtcm_var
    li   t1, 0x4321
    sw   t1, 0(t0)
    lw   t2, 0(t0)
    bne  t1, t2, fail
    li   t1, 0x1234
    sw   t1, 4(t0)
    lw   t2, 4(t0)
    bne  t1, t2, fail
    ret

    .balign 32

tc5_itcm_access_ram:
    li   TESTNUM, 5
    li   t0, RAM_DATA_BASE
    li   t1, 0xAAAA
    sw   t1, 0(t0)
    lw   t2, 0(t0)
    bne  t1, t2, fail
    li   t1, 0xBBBB
    sw   t1, 4(t0)
    lw   t2, 4(t0)
    bne  t1, t2, fail
    ret

    .balign 32

tc6_ram_access_dtcm:
    addi sp, sp, -16
    sw   ra, 0(sp)
    li   TESTNUM, 6
    call ram_access_dtcm_helper
    bnez t0, fail
    lw   ra, 0(sp)
    addi sp, sp, 16
    ret

    .balign 32

tc7_nested_cross_calls:
    addi sp, sp, -16
    sw   ra, 0(sp)
    li   TESTNUM, 7
    li   t0, 0
    jal  itcm_nest_a
    li   t1, 0x77
    bne  t0, t1, fail
    lw   ra, 0(sp)
    addi sp, sp, 16
    ret

    .balign 32

tc8_dmem_during_imem_switch:
    addi sp, sp, -16
    sw   ra, 0(sp)
    li   TESTNUM, 8
    li   t0, 0
    li   t2, 10
tc8_loop:
    la   t3, dtcm_counter
    sw   t0, 0(t3)
    call ram_func_inc
    la   t3, dtcm_counter
    lw   t4, 0(t3)
    addi t5, t0, -1
    bne  t4, t5, fail
    addi t2, t2, -1
    bnez t2, tc8_loop
    lw   ra, 0(sp)
    addi sp, sp, 16
    ret

    .balign 32

tc9_jalr_across_boundary:
    addi sp, sp, -16
    sw   ra, 0(sp)
    li   TESTNUM, 9
    la   t0, ram_jalr_target
    li   t1, 0x9999
    jalr t0
    li   t1, 0x999A
    bne  t0, t1, fail
    lw   ra, 0(sp)
    addi sp, sp, 16
    ret

    .balign 32

tc10_itcm_boundary_jump:
    addi sp, sp, -16
    sw   ra, 0(sp)
    li   TESTNUM, 10
    jal  itcm_boundary_helper
    bnez t0, fail
    lw   ra, 0(sp)
    addi sp, sp, 16
    ret

    .balign 32

itcm_func_inc:
    addi t0, t0, 1
    ret

    .balign 32

itcm_nest_a:
    addi sp, sp, -16
    sw   ra, 0(sp)
    addi t0, t0, 0x10
    call ram_nest_b
    lw   ra, 0(sp)
    addi sp, sp, 16
    ret

    .balign 32

itcm_nest_c:
    addi sp, sp, -16
    sw   ra, 0(sp)
    addi t0, t0, 0x40
    call ram_nest_d
    lw   ra, 0(sp)
    addi sp, sp, 16
    ret

    .balign 32

itcm_boundary_helper:
    addi sp, sp, -16
    sw   ra, 0(sp)
    la   t0, itcm_boundary_near_end
    jalr t0
    lw   ra, 0(sp)
    addi sp, sp, 16
    ret

    .balign 32
itcm_boundary_near_end:
    li   t0, 0
    ret

    .section .text.init, "ax"

ram_func_inc:
    addi t0, t0, 1
    ret

    .balign 32

ram_caller_to_itcm:
    addi sp, sp, -16
    sw   ra, 0(sp)
    li   t0, 0x2222
    call itcm_func_inc
    lw   ra, 0(sp)
    addi sp, sp, 16
    ret

    .balign 32

ram_access_dtcm_helper:
    la   t0, dtcm_var
    li   t1, 0x6789
    sw   t1, 0(t0)
    lw   t2, 0(t0)
    bne  t1, t2, ram_access_dtcm_fail
    li   t1, 0x9876
    sw   t1, 8(t0)
    lw   t2, 8(t0)
    bne  t1, t2, ram_access_dtcm_fail
    li   t0, 0
    ret
ram_access_dtcm_fail:
    li   t0, 1
    ret

    .balign 32

ram_nest_b:
    addi sp, sp, -16
    sw   ra, 0(sp)
    addi t0, t0, 0x20
    call itcm_nest_c
    lw   ra, 0(sp)
    addi sp, sp, 16
    ret

    .balign 32

ram_nest_d:
    addi t0, t0, 0x07
    ret

    .balign 32

ram_jalr_target:
    addi t0, t1, 1
    ret

    .data
    .balign 4
dtcm_var:
    .word 0
dtcm_counter:
    .word 0
dtcm_array:
    .word 0, 0, 0, 0, 0, 0, 0, 0