#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Bit-accurate behavioural model of the SCR1 radix-2 MDU (scr1_pipe_ialu.sv).

Purpose: prove that replacing the MDU adder by a 33-bit XOR (i.e. killing the
carry chain) turns the existing iterative integer multiplier into a correct
iterative carry-less multiplier, reusing the SAME datapath / FSM / counter.

The model mirrors the RTL bit widths exactly:
    SCR1_MUL_WIDTH     = 1
    SCR1_MDU_SUM_WIDTH = XLEN + SCR1_MUL_WIDTH = 33
    SCR1_MUL_CNT_INIT  = 32'b1 << (32/1 - 2)   = 1 << 30
    mul_part_prod      : signed [SCR1_MDU_SUM_WIDTH:0]   (34 bit)
    mdu_sum_op1/op2    : signed [SCR1_MDU_SUM_WIDTH-1:0] (33 bit)
    {mul_res_hi, mul_res_lo} = {mdu_sum_res(33), < idle ? op2 : lo_ff >[31:1](31)}
"""
import random

XLEN = 32
MUL_WIDTH = 1
MDU_SUM_WIDTH = XLEN + MUL_WIDTH          # 33
MUL_CNT_INIT = 1 << 30
MAXT = 400


def trunc(v, w):
    return v & ((1 << w) - 1)


def sgn(v, w):
    v = trunc(v, w)
    return v - (1 << w) if (v >> (w - 1)) & 1 else v


def ref_clmul(a, b):
    """GF(2) polynomial product, 63-bit."""
    p = 0
    for i in range(XLEN):
        if (b >> i) & 1:
            p ^= (a << i)
    return p


def ref_mul_suite(a, b):
    sa, sb = sgn(a, 32), sgn(b, 32)
    full = sa * sb                                   # 64-bit signed
    hi = trunc(full >> 32, 32)
    lo = trunc(full, 32)
    return {'mul': lo, 'mulh': hi, 'mulhsu': trunc((sa * b) >> 32, 32),
            'mulhu': trunc((a * b) >> 32, 32)}


def mdu(a, b, cmd, carry_kill=False, cnt_init=None, verbose=False):
    """Cycle-accurate model of one MDU operation.

    cmd         : mul/mulh/mulhsu/mulhu or clmul/clmulh/clmulr
    carry_kill  : True -> replace the '+' in the MDU adder by '^'
    cnt_init    : override SCR1_MUL_CNT_INIT (iteration count selection)
    """
    a, b = trunc(a, 32), trunc(b, 32)
    clmul = cmd in ('clmul', 'clmulh', 'clmulr')
    cnt_init = MUL_CNT_INIT if cnt_init is None else cnt_init

    if clmul:
        op1_is_sgn = False
        op2_is_sgn = False
        cmd_hi = cmd in ('clmulh', 'clmulr')
    else:
        mc = {'mul': 0b00, 'mulh': 0b01, 'mulhsu': 0b10, 'mulhu': 0b11}[cmd]
        cmd_hi = mc != 0
        op1_is_sgn = mc != 0b11
        op2_is_sgn = not bool(mc & 0b10)

    op1 = sgn((int(op1_is_sgn and bool(a >> 31)) << 32) | a, 33)

    hi_ff, lo_ff, cnt, fsm = 0, 0, 0, 'IDLE'
    main_ops_non_zero = bool(a) and bool(b)

    for t in range(MAXT):
        idle = fsm == 'IDLE'
        iter_req = main_ops_non_zero and idle

        # ---- operand 2 selection (mirrors mul_op2) ----
        if idle:
            op2 = b & 0x1
        else:
            corr = int(bool(cnt & 1) and op2_is_sgn and bool(lo_ff & 1))
            op2 = (corr << 1) | (lo_ff & 1)
        op2 = sgn(op2 & 0b11, 2)

        # ---- partial product : signed 34-bit context ----
        pp = trunc(sgn(op1 * op2, 34), 34)

        # ---- MDU adder operands ----
        if idle:
            sum_op1 = 0
        else:
            ext = int(op1_is_sgn and bool(hi_ff >> 31))
            sum_op1 = trunc(((ext << 32) | trunc(hi_ff, 32)), 33)
        sum_op2 = trunc(pp, 33)

        # ---- THE ONLY CHANGE: '+' -> '^' ----
        if clmul or carry_kill:
            sum_res = trunc(sum_op1 ^ sum_op2, 33)
        else:
            sum_res = trunc(sgn(sum_op1, 33) + sgn(sum_op2, 33), 33)

        # ---- {hi,lo} shift register ----
        tail = (b >> MUL_WIDTH) if idle else (lo_ff >> MUL_WIDTH)
        pair64 = (sum_res << (XLEN - MUL_WIDTH)) | trunc(tail, XLEN - MUL_WIDTH)
        res_hi = trunc(pair64 >> XLEN, 32)
        res_lo = trunc(pair64, 32)

        if verbose:
            print(f"  t={t:2d} fsm={fsm:5s} cnt={cnt:08x} op2={op2:2d} "
                  f"sum={sum_res:09x} hi={res_hi:08x} lo={res_lo:08x}")

        # ---- output / ready (mirrors the result mux) ----
        if idle:
            ready = not iter_req
            if ready:
                return 0, t
            cnt_next = cnt_init
        else:
            it_rdy = bool(cnt & 1)
            ready = it_rdy
            cnt_next = cnt >> 1

        if ready:
            if clmul:
                if cmd == 'clmul':
                    out = trunc(pair64, 32)
                elif cmd == 'clmulh':
                    out = trunc(pair64 >> XLEN, 32)
                else:                               # clmulr = P[62:31]
                    out = trunc(pair64 >> 31, 32)
            else:
                out = res_hi if cmd_hi else res_lo
            return trunc(out, 32), t

        cnt, hi_ff, lo_ff, fsm = cnt_next, res_hi, res_lo, 'ITER'

    return None, MAXT


if __name__ == '__main__':
    print("=" * 72)
    print("1) Sanity: the model must reproduce RV32M for signed/unsigned MUL")
    print("=" * 72)
    ok = True
    cases = [(0x0000_0001, 0x0000_0001), (0xFFFF_FFFF, 0xFFFF_FFFF),
             (0xDEAD_BEEF, 0x1234_5678), (0x7FFF_FFFF, 0x7FFF_FFFF),
             (0x8000_0000, 0x8000_0000), (0x8000_0000, 0x0000_0002)]
    random.seed(7)
    cases += [(random.getrandbits(32), random.getrandbits(32)) for _ in range(300)]
    max_cycles = 0
    for a, b in cases:
        ref = ref_mul_suite(a, b)
        for cmd in ('mul', 'mulh', 'mulhsu', 'mulhu'):
            got, t = mdu(a, b, cmd)
            max_cycles = max(max_cycles, t)
            if got != ref[cmd]:
                ok = False
                print(f"  MISMATCH {cmd} a={a:08x} b={b:08x} got={got:08x} ref={ref[cmd]:08x}")
    print(f"  all RV32M cases match: {ok}   (max cycles observed = {max_cycles})")

    print()
    print("=" * 72)
    print("2) Core claim: MDU datapath with the adder replaced by XOR == clmul")
    print("=" * 72)
    clm_cases = [(0x0, 0x0), (0x1, 0x1), (0x3, 0x3), (0xFFFF_FFFF, 0x1),
                 (0x1, 0xFFFF_FFFF), (0xFFFF_FFFF, 0xFFFF_FFFF),
                 (0xDEAD_BEEF, 0x1234_5678), (0x8000_0000, 0x0000_0001),
                 (0x0000_0001, 0x8000_0000), (0xAAAA_AAAA, 0x5555_5555)]
    clm_cases += [(random.getrandbits(32), random.getrandbits(32)) for _ in range(2000)]
    bad = 0
    max_clm_cycles = 0
    for a, b in clm_cases:
        P = ref_clmul(a, b)                       # 63-bit polynomial product
        ref = {'clmul': trunc(P, 32),
               'clmulh': trunc(P >> 32, 32),
               'clmulr': trunc(P >> 31, 32)}
        for cmd in ('clmul', 'clmulh', 'clmulr'):
            got, t = mdu(a, b, cmd)
            max_clm_cycles = max(max_clm_cycles, t)
            if got != ref[cmd]:
                bad += 1
                if bad <= 6:
                    print(f"  MISMATCH {cmd} a={a:08x} b={b:08x} "
                          f"got={got:08x} ref={ref[cmd]:08x}")
    print(f"  cases={len(clm_cases)} x 3 instr, mismatches = {bad}")
    print(f"  max cycles observed = {max_clm_cycles}")

    print()
    print("=" * 72)
    print("3) How many iterations can we drop? (scan shorter counters)")
    print("=" * 72)
    nz = [(a, b) for a, b in clm_cases if a and b]
    for init_name, init in [("1<<30 (32 iters, same as MUL)", 1 << 30),
                            ("1<<29 (31 iters)", 1 << 29),
                            ("1<<16 (18 iters)", 1 << 16),
                            ("1<<8  (10 iters)", 1 << 8)]:
        badc = {'clmul': 0, 'clmulh': 0, 'clmulr': 0}
        cyc = 0
        for a, b in nz:
            P = ref_clmul(a, b)
            ref = {'clmul': trunc(P, 32), 'clmulh': trunc(P >> 32, 32),
                   'clmulr': trunc(P >> 31, 32)}
            for cmd in badc:
                got, t = mdu(a, b, cmd, cnt_init=init)
                cyc = max(cyc, t)
                if got != ref[cmd]:
                    badc[cmd] += 1
        print(f"  {init_name:32s} -> cycles={cyc:3d}  "
              f"clmul:{badc['clmul']:5d} clmulh:{badc['clmulh']:5d} clmulr:{badc['clmulr']:5d} wrong")
