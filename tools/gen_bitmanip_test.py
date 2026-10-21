#!/usr/bin/env python3
"""
Generate an assembly-level self-checking test for the SCR1 B (bit manipulation)
extension.

The reference model is implemented here in Python, independently of the RTL, so
the generated expectations are a genuine golden reference rather than a
restatement of the hardware description.

Output: sim/tests/bitmanip/bitmanip_test.S

  int bm_run(void);   // returns the number of mismatches (0 == all good)

Encoding notes (B 1.0, RV32):
  Zba  shNadd   : funct7=0010000, funct3=010/100/110
  Zbb  andn/orn/xnor : funct7=0100000, funct3=111/110/100
  Zbb  clz/ctz/cpop/sext.b/sext.h : funct12=0110000_00xxx, funct3=001  (OP-IMM)
  Zbb  zext.h   : funct7=0000100, funct3=100, rs2=0        (OP)
  Zbb  rol/ror  : funct7=0110000, funct3=001/101           (OP)
  Zbb  rori     : funct7=0110000, funct3=101               (OP-IMM)
  Zbb  orc.b    : funct12=0010100_00111, funct3=101        (OP-IMM)
  Zbc  clmul/h/r: funct7=0000101, funct3=001/011/010       (OP)
  Zbs  bclr/bset/binv/bext : funct7=0100100, funct3=001/010/011/101 (OP)
  Zbs  *_i forms: funct6=010010, funct3=001/010/011/101    (OP-IMM)
"""

MASK = 0xFFFFFFFF
XLEN = 32

T0, T1, T2 = 5, 6, 7      # t0/t1/t2 -- free caller-saved registers


def r_type(funct7, rs2, rs1, funct3, rd, opcode=0x33):
    return ((funct7 & 0x7F) << 25) | ((rs2 & 0x1F) << 20) | ((rs1 & 0x1F) << 15) \
         | ((funct3 & 0x7) << 12) | ((rd & 0x1F) << 7) | (opcode & 0x7F)


def i_type(imm12, rs1, funct3, rd, opcode=0x13):
    return ((imm12 & 0xFFF) << 20) | ((rs1 & 0x1F) << 15) | ((funct3 & 0x7) << 12) \
         | ((rd & 0x1F) << 7) | (opcode & 0x7F)


# ---------------------------------------------------------------------------
# Golden reference model
# ---------------------------------------------------------------------------
def s32(v):
    v &= MASK
    return v - (1 << XLEN) if v & 0x80000000 else v


def u32(v):
    return v & MASK


def f_shnadd(n):
    return lambda a, b: u32((a << n) + b)


def f_andn(a, b):
    return u32(a & ~b)


def f_orn(a, b):
    return u32(a | ~b)


def f_xnor(a, b):
    return u32(~(a ^ b))


def f_clz(a):
    return 32 if a == 0 else 31 - a.bit_length() + 1


def f_ctz(a):
    return 32 if a == 0 else (a & -a).bit_length() - 1


def f_cpop(a):
    return bin(a).count('1')


def f_max(a, b):
    return a if s32(a) > s32(b) else b


def f_maxu(a, b):
    return a if a > b else b


def f_min(a, b):
    return a if s32(a) < s32(b) else b


def f_minu(a, b):
    return a if a < b else b


def f_sextb(a):
    v = a & 0xFF
    return u32(v | 0xFFFFFF00 if v & 0x80 else v)


def f_sexth(a):
    v = a & 0xFFFF
    return u32(v | 0xFFFF0000 if v & 0x8000 else v)


def f_zexth(a):
    return a & 0xFFFF


def f_rol(a, b):
    s = b & 31
    return u32((a << s) | (a >> (32 - s))) if s else u32(a)


def f_ror(a, b):
    s = b & 31
    return u32((a >> s) | (a << (32 - s))) if s else u32(a)


def f_orcb(a):
    out = 0
    for i in range(4):
        byte = (a >> (8 * i)) & 0xFF
        if byte:
            out |= 0xFF << (8 * i)
    return out


def clmul_full(a, b):
    """63-bit carry-less product"""
    p = 0
    for i in range(XLEN):
        if (b >> i) & 1:
            p ^= a << i
    return p & ((1 << 63) - 1)


def f_clmul(a, b):
    return clmul_full(a, b) & MASK


def f_clmulh(a, b):
    return (clmul_full(a, b) >> 32) & MASK


def f_clmulr(a, b):
    return (clmul_full(a, b) >> 31) & MASK


def f_bclr(a, b):
    return u32(a & ~(1 << (b & 31)))


def f_bext(a, b):
    return (a >> (b & 31)) & 1


def f_binv(a, b):
    return u32(a ^ (1 << (b & 31)))


def f_bset(a, b):
    return u32(a | (1 << (b & 31)))


# ---------------------------------------------------------------------------
# Test vectors
# ---------------------------------------------------------------------------
VALS = [0x00000000, 0x00000001, 0xFFFFFFFF, 0x80000000,
        0x7FFFFFFF, 0xAAAAAAAA, 0x55555555, 0xDEADBEEF]

PAIRS = [(0x00000000, 0x00000000),
         (0x00000001, 0xFFFFFFFF),
         (0xAAAAAAAA, 0x55555555),
         (0x80000000, 0x00000001),
         (0x7FFFFFFF, 0x00000001),
         (0xDEADBEEF, 0x12345678),
         (0xFF00FF00, 0x00FF00FF),
         (0xFFFFFFFF, 0xFFFFFFFF)]

ZBC_CORNER = [(0xFFFFFFFF, 0xFFFFFFFF), (0x00000000, 0xFFFFFFFF),
              (0x80000000, 0x00000001), (0x00000001, 0x80000000)]

SHAMT_CASES = [(0x00000000, 0), (0x00000001, 0), (0xFFFFFFFF, 1), (0x80000000, 31),
               (0xAAAAAAAA, 1), (0x55555555, 7), (0x12345678, 15), (0xDEADBEEF, 31)]

SINGLE_VALS = [0x00000000, 0x00000001, 0xFFFFFFFF, 0x80000000,
               0x7FFFFFFF, 0x000000FF, 0x0000FFFF, 0x00FF00FF,
               0xFF00FF00, 0xAAAAAAAA]


# ---------------------------------------------------------------------------
# Emitter
# ---------------------------------------------------------------------------
class Emitter:
    def __init__(self):
        self.lines = []

    def emit(self, s=""):
        self.lines.append(s)

    def comment(self, s):
        self.emit(f"// {s}")

    def chk2(self, insn, op1, op2, exp, enc=None):
        """register-register (or .word encoded) form: rd=t2, rs1=t0, rs2=t1"""
        if enc is None:
            self.emit(f"    CHK2 {insn}, 0x{op1:08x}, 0x{op2:08x}, 0x{exp:08x}")
        else:
            self.emit(f"    CHK2W 0x{enc:08x}, 0x{op1:08x}, 0x{op2:08x}, 0x{exp:08x}")

    def chk1(self, insn, op1, exp, enc=None):
        """single source register form: rd=t2, rs1=t0"""
        if enc is None:
            self.emit(f"    CHK1 {insn}, 0x{op1:08x}, 0x{exp:08x}")
        else:
            self.emit(f"    CHK1W 0x{enc:08x}, 0x{op1:08x}, 0x{exp:08x}")

    def chk1i(self, insn, op1, imm, exp, enc=None):
        """immediate form: rd=t2, rs1=t0, imm/shamt"""
        if enc is None:
            self.emit(f"    CHK1I {insn}, 0x{op1:08x}, {imm}, 0x{exp:08x}")
        else:
            self.emit(f"    CHK1IW 0x{enc:08x}, 0x{op1:08x}, 0x{exp:08x}")


HEADER = """/// @file       <bitmanip_test.S>
/// @brief      Self-checking test for the SCR1 bit manipulation extension
///
/// AUTO-GENERATED by tools/gen_bitmanip_test.py -- DO NOT EDIT MANUALLY.
///
/// Golden values are produced by an independent Python reference model.
/// Zbs (bclr/bset/binv/bext and their immediate forms) is emitted as raw
/// instruction words because the installed binutils does not know the Zbs
/// mnemonics.
///
/// int bm_run(void)  ->  number of mismatches, 0 means all checks passed.

    .text
    .globl bm_run
    .type  bm_run, @function

// t0 = x5, t1 = x6, t2 = x7, t3 = x28, s0 = x8 (error counter, callee-saved)

.macro CHK2 insn, op1, op2, exp
    li   t0, \\op1
    li   t1, \\op2
    \\insn t2, t0, t1
    li   t3, \\exp
    beq  t2, t3, 1f
    addi s0, s0, 1
1:
.endm

.macro CHK2W enc, op1, op2, exp
    li   t0, \\op1
    li   t1, \\op2
    .word \\enc
    li   t3, \\exp
    beq  t2, t3, 1f
    addi s0, s0, 1
1:
.endm

.macro CHK1 insn, op1, exp
    li   t0, \\op1
    \\insn t2, t0
    li   t3, \\exp
    beq  t2, t3, 1f
    addi s0, s0, 1
1:
.endm

.macro CHK1W enc, op1, exp
    li   t0, \\op1
    .word \\enc
    li   t3, \\exp
    beq  t2, t3, 1f
    addi s0, s0, 1
1:
.endm

.macro CHK1I insn, op1, imm, exp
    li   t0, \\op1
    \\insn t2, t0, \\imm
    li   t3, \\exp
    beq  t2, t3, 1f
    addi s0, s0, 1
1:
.endm

.macro CHK1IW enc, op1, exp
    li   t0, \\op1
    .word \\enc
    li   t3, \\exp
    beq  t2, t3, 1f
    addi s0, s0, 1
1:
.endm

bm_run:
    addi sp, sp, -16
    sw   s0, 0(sp)
    sw   s1, 4(sp)
    sw   s2, 8(sp)
    li   s0, 0                  // error counter
"""

FOOTER = """    mv   a0, s0                 // return the number of mismatches
    lw   s0, 0(sp)
    lw   s1, 4(sp)
    lw   s2, 8(sp)
    addi sp, sp, 16
    ret

    .size bm_run, .-bm_run
"""


def main():
    import os
    lim = int(os.environ.get("BM_LIMIT", "0"))     # 0 == full set

    def cut(lst):
        return lst[:lim] if lim > 0 else lst

    global PAIRS, SHAMT_CASES, SINGLE_VALS, ZBC_CORNER
    if lim > 0:
        PAIRS        = PAIRS[:lim]
        SHAMT_CASES  = SHAMT_CASES[:lim]
        SINGLE_VALS  = SINGLE_VALS[:lim]
        ZBC_CORNER   = ZBC_CORNER[:lim]

    e = Emitter()
    n = 0

    # ---- Zba -------------------------------------------------------------
    e.emit(HEADER)
    e.comment("Zba: shift-and-add")
    for insn, fn, nn in (("sh1add", f_shnadd(1), 1),
                         ("sh2add", f_shnadd(2), 2),
                         ("sh3add", f_shnadd(3), 3)):
        e.comment(f"  {insn}")
        for a, b in PAIRS:
            e.chk2(insn, a, b, fn(a, b))
            n += 1

    # ---- Zbb: logic with inverted operand --------------------------------
    e.emit()
    e.comment("Zbb: andn / orn / xnor")
    for insn, fn in (("andn", f_andn), ("orn", f_orn), ("xnor", f_xnor)):
        e.comment(f"  {insn}")
        for a, b in PAIRS:
            e.chk2(insn, a, b, fn(a, b))
            n += 1

    # ---- Zbb: min/max ----------------------------------------------------
    e.emit()
    e.comment("Zbb: min / max")
    for insn, fn in (("min", f_min), ("minu", f_minu), ("max", f_max), ("maxu", f_maxu)):
        e.comment(f"  {insn}")
        extra = [(0xFFFFFFFF, 0x00000001), (0x00000001, 0xFFFFFFFF)]
        for a, b in cut(PAIRS + extra):
            e.chk2(insn, a, b, fn(a, b))
            n += 1

    # ---- Zbb: rotate -----------------------------------------------------
    e.emit()
    e.comment("Zbb: rol / ror (register) and rori (immediate)")
    for insn, fn in (("rol", f_rol), ("ror", f_ror)):
        e.comment(f"  {insn}")
        for a, b in SHAMT_CASES:
            e.chk2(insn, a, b, fn(a, b))
            n += 1
    e.comment("  rori")
    for a, s in SHAMT_CASES:
        e.chk1i("rori", a, s, f_ror(a, s))
        n += 1

    # ---- Zbb: count / extend / orc.b -------------------------------------
    e.emit()
    e.comment("Zbb: clz / ctz / cpop / sext.b / sext.h / zext.h / orc.b")
    for insn, fn in (("clz", f_clz), ("ctz", f_ctz), ("cpop", f_cpop),
                     ("sext.b", f_sextb), ("sext.h", f_sexth),
                     ("zext.h", f_zexth), ("orc.b", f_orcb)):
        e.comment(f"  {insn}")
        for a in SINGLE_VALS:
            e.chk1(insn, a, fn(a))
            n += 1

    # ---- Zbc -------------------------------------------------------------
    e.emit()
    e.comment("Zbc: clmul / clmulh / clmulr")
    for insn, fn in (("clmul", f_clmul), ("clmulh", f_clmulh), ("clmulr", f_clmulr)):
        e.comment(f"  {insn}")
        for a, b in PAIRS:
            e.chk2(insn, a, b, fn(a, b))
            n += 1
    # corner cases for the carry-less multiplier
    for a, b in ZBC_CORNER:
        e.chk2("clmul", a, b, f_clmul(a, b))
        e.chk2("clmulh", a, b, f_clmulh(a, b))
        e.chk2("clmulr", a, b, f_clmulr(a, b))
        n += 3

    # ---- Zbs -------------------------------------------------------------
    e.emit()
    e.comment("Zbs: bclr / bset / binv / bext (register form, raw encoding)")
    for name, funct3, fn in (("bclr", 0b001, f_bclr),
                             ("bset", 0b010, f_bset),
                             ("binv", 0b011, f_binv),
                             ("bext", 0b101, f_bext)):
        e.comment(f"  {name}")
        for a, s in SHAMT_CASES:
            enc = r_type(0b0100100, T1, T0, funct3, T2)
            e.chk2(None, a, s, fn(a, s), enc=enc)
            n += 1

    e.emit()
    e.comment("Zbs: bclri / bseti / binvi / bexti (immediate form, raw encoding)")
    for name, funct3, fn in (("bclri", 0b001, f_bclr),
                             ("bseti", 0b010, f_bset),
                             ("binvi", 0b011, f_binv),
                             ("bexti", 0b101, f_bext)):
        e.comment(f"  {name}")
        for a, s in SHAMT_CASES:
            imm12 = (0b010010 << 6) | (s & 0x1F)
            enc = i_type(imm12, T0, funct3, T2)
            e.chk1i(None, a, s, fn(a, s), enc=enc)
            n += 1

    e.emit(FOOTER)

    out = "\n".join(e.lines) + "\n"
    path = "sim/tests/bitmanip/bitmanip_test.S"
    import os
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", newline="\n") as fh:
        fh.write(out)
    print(f"generated {path}: {n} checks")


if __name__ == "__main__":
    main()
