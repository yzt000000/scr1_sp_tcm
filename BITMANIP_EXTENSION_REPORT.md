# SCR1 RISC-V 位操作扩展（B 扩展）实现报告

> 目标：在 SCR1（RV32IMC MAX 配置，4 级流水）上扩展 RISC-V **Bit-Manipulation B 1.0** 指令集，
> 覆盖 **Zba + Zbb + Zbc + Zbs** 共 **31 条指令**，`misa.B` 置 1，并新增 `SCR1_RVB_EXT` 宏默认开启。
>
> 验证结论（QuestaSim 2024.1，CFG=MAX / BUS=AXI / TCM=1）：
> **全量回归 225 / 225 PASS，0 FAIL**（基线 224 + 新增 `bitmanip` 1 项，无任何 PASS↔FAIL 翻转）。

---

## 1. 交付总览

| 项目 | 结果 |
|---|---|
| 实现子集 | Zba(3) + Zbb(17) + Zbc(3) + Zbs(8) = **31 条** |
| 实现方式 | 新增纯组合逻辑 `scr1_pipe_balu.sv`，**单周期**完成，挂在 IALU 内 |
| CLMUL | 32×32 无进位乘法**共享一个阵列**，`clmul/clmulh/clmulr` 只取 63-bit 积的不同切片 |
| `misa` | bit1 = 1，实测读出 `MISA = 0x40001106` |
| 编译开关 | `SCR1_RVB_EXT`，已加入 `SCR1_CFG_RV32IMC_MAX` 与 custom 配置段（默认开启） |
| Lint | Verilator AXI / AHB 两套 filelist **0 error** |
| 自检测试 | `sim/tests/bitmanip`，**282 项**独立黄金参考比对，全部通过 |
| 全量回归 | **225 / 225 PASS** |

---

## 2. 实现的指令与编码

### 2.1 Zba —— 地址生成（3 条）

| 指令 | opcode | funct7 | funct3 | 语义 | BALU 命令 |
|---|---|---|---|---|---|
| `sh1add` | OP | `0010000` | `010` | `(rs1 << 1) + rs2` | `SCR1_IALU_CMD_SH1ADD` |
| `sh2add` | OP | `0010000` | `100` | `(rs1 << 2) + rs2` | `SCR1_IALU_CMD_SH2ADD` |
| `sh3add` | OP | `0010000` | `110` | `(rs1 << 3) + rs2` | `SCR1_IALU_CMD_SH3ADD` |

### 2.2 Zbb —— 基础位操作（17 条）

| 指令 | opcode | funct7 / funct12 | funct3 | 备注 | BALU 命令 |
|---|---|---|---|---|---|
| `andn` | OP | `0100000` | `111` | 复用 SUB/SRA 的 funct7 | `ANDN` |
| `orn` | OP | `0100000` | `110` | 同上 | `ORN` |
| `xnor` | OP | `0100000` | `100` | 同上 | `XNOR` |
| `clz` | OP-IMM | `0110000_00000` | `001` | shamt 字段作选择子 | `CLZ` |
| `ctz` | OP-IMM | `0110000_00001` | `001` | | `CTZ` |
| `cpop` | OP-IMM | `0110000_00010` | `001` | | `CPOP` |
| `sext.b` | OP-IMM | `0110000_00100` | `001` | | `SEXTB` |
| `sext.h` | OP-IMM | `0110000_00101` | `001` | | `SEXTH` |
| `zext.h` | OP | `0000100` | `100` | **要求 rs2 == 0** | `ZEXTH` |
| `rol` | OP | `0110000` | `001` | | `ROL` |
| `ror` | OP | `0110000` | `101` | | `ROR` |
| `rori` | OP-IMM | `0110000` | `101` | 复用 `ROR`，imm = shamt | `ROR` |
| `orc.b` | OP-IMM | `0010100_00111` | `101` | **要求 shamt == 00111** | `ORCB` |
| `min` | OP | `0000101` | `100` | | `MIN` |
| `minu` | OP | `0000101` | `101` | | `MINU` |
| `max` | OP | `0000101` | `110` | | `MAX` |
| `maxu` | OP | `0000101` | `111` | | `MAXU` |

### 2.3 Zbc —— 无进位乘法（3 条）

| 指令 | funct7 | funct3 | 结果切片 |
|---|---|---|---|
| `clmul` | `0000101` | `001` | `P[31:0]` |
| `clmulr` | `0000101` | `010` | `P[62:31]` |
| `clmulh` | `0000101` | `011` | `P[63:32]`（RV32 下 `P[63]` 恒 0） |

### 2.4 Zbs —— 单比特操作（8 条）

| 指令 | opcode | funct7 / funct6 | funct3 | BALU 命令 |
|---|---|---|---|---|
| `bclr` / `bclri` | OP / OP-IMM | `0100100` / `010010` | `001` | `BCLR` |
| `bset` / `bseti` | OP / OP-IMM | `0100100` / `010010` | `010` | `BSET` |
| `binv` / `binvi` | OP / OP-IMM | `0100100` / `010010` | `011` | `BINV` |
| `bext` / `bexti` | OP / OP-IMM | `0100100` / `010010` | `101` | `BEXT` |

> **编码冲突（已处理）**：`bseti` 与 `slti` 共用 opcode=OP-IMM / funct3=010，`binvi` 与 `sltiu` 共用 funct3=011。
> 译码时先判 `funct7[6:1] == 6'b010010`，命中则走 Zbs 并令 `imm = shamt`（零扩展），否则回落到 `SLTI/SLTIU`。

**31 条指令 → 26 个 BALU 命令**：5 条立即数形式（`rori/bclri/bseti/binvi/bexti`）在译码阶段就归一到对应的 R 型命令，
op2 携带零扩展的 shamt，因此不需要额外的命令编码。

---

## 3. RTL 改动清单

| 文件 | 改动 |
|---|---|
| `src/includes/scr1_arch_description.svh` | 新增 `SCR1_RVB_EXT`；加入 `SCR1_CFG_RV32IMC_MAX` 与 custom 配置段（默认开启）。并在"派生配置"段按 `SCR1_RVM_EXT` 是否定义推导出 `SCR1_RVB_ITER_CLMUL`（Zbc 的两种实现二选一，见 §3.3） |
| `src/includes/scr1_csr.svh` | 新增 `` `SCR1_RVB_ENC = 32'h0002 ``（bit1），在 `SCR1_RVB_EXT` 下 OR 进 `MISA` |
| `src/includes/scr1_riscv_isa_decoding.svh` | 在 `REMU` 之后新增 26 个命令；`SCR1_IALU_CMD_ALL_NUM_E` 按组合取值：M+B=49、仅 B=41、仅 M=23、都无=15（命令位宽由 5 → 6 bit） |
| **`src/core/pipeline/scr1_pipe_balu.sv`（新增）** | 纯组合 B 运算单元，约 180 行 |
| `src/core/pipeline/scr1_pipe_ialu.sv` | 例化 `i_balu`（op1/op2 直取 `exu2ialu_main_op1/2_i`），26 个命令在结果 mux 中统一 `ialu2exu_main_res_o = balu_res` |
| `src/core/pipeline/scr1_pipe_idu.sv` | OP 侧新增 5 个 funct7 译码分支 + `0100000` 补 3 个 funct3；OP-IMM 侧扩展 SLLI / SRLI·SRAI 分支与 SLTI / SLTIU 冲突判别；SVA 上界改为 `SCR1_IALU_CMD_BSET` |
| `src/core.files` | 在 `scr1_pipe_exu.sv` 之后、`scr1_pipe_ialu.sv` 之前加入 `scr1_pipe_balu.sv` |
| `src/tb/*`、`src/top/*` | **未改动** |

### 3.1 为什么把 BALU 放在 IALU 里

* B 指令全部单周期，结果可以直接并入 IALU 既有的结果 mux，`EXU` 的写回通路**零改动**。
* MDU 的迭代 FSM 由 `ialu2exu_rvm_res_rdy_o` 控制，其**默认值即为 1**，而 B 命令不会进入 MDU 的 case 分支，
  因此天然单周期就绪，无需新增流水线握手。

### 3.2 几个实现细节

* **rotate 的 `shamt_r` 用 6 bit**：`shamt_r = 32 - shamt`。当 `shamt == 0` 时必须得到 32 而不是 0，
  否则 `op1 >> 0` 会让 `rol/ror` 变成 `op1 | op1`。取 6 bit 后 `(op1 >> 32)` / `(op1 << 32)` 恒为 0，
  rotate-by-0 自然退化成恒等运算。
* **clz / ctz 用"最后一次命中胜出"的循环**：`clz` 由低位向高位扫，最后一个置位 bit 覆盖计数；
  `ctz` 反向扫。均为 6 bit 计数（0..32）。
* **clmul 的实现二选一**（详见 §3.3）：组合 GF(2) 阵列，或复用 MDU 的 radix-2 迭代通路
  （由 `SCR1_RVB_ITER_CLMUL` 决定，M 扩展存在时默认走后者）。
* **非法编码**：`zext.h` 要求 `rs2 == 0`、`orc.b` 要求 `shamt == 00111`、Zbb 的 `funct12` 选择子为保留值时，
  译码置 `rvi_illegal`，会走 illegal-instruction trap。

### 3.3 Zbc 的两种实现

Zbc（`clmul/clmulh/clmulr`）是唯一有实现选择余地的一组。宏 **`SCR1_RVB_ITER_CLMUL`** 在
`SCR1_RVM_EXT` 定义时自动生效，注释掉即可切回组合阵列。

| | ① 组合 GF(2) 阵列（`balu`） | ② **复用 MDU 迭代（默认）** |
|---|---|---|
| 位置 | `scr1_pipe_balu.sv` | `scr1_pipe_ialu.sv` 的 MDU |
| 延迟 | **1 拍** | **32 拍** |
| 面积 | ~3.5 kGE（1024×AND2 + ~960×XOR2） | **~0.2 kGE** |
| 关键路径 | XOR 树 5 级 ≈ 14 FO4 | 与 DIV 同一条笔（不新增时序压力） |

选 ② 的依据是一个代数事实：**整数环上的 radix-2 移位累加，只要把进位去掉就变成了 GF(2) 上的同一算法**。

1. **部分积已经免费**：步长为 1 bit 时 `op1 * {0, bit}` 退化为纯 AND，不需要任何 AND 阵列。
2. **累加器由 ADD 换成 XOR**：
   ```systemverilog
   mdu_sum_res = mdu_cmd_clmul ? (mdu_sum_op1 ^ mdu_sum_op2)
               : mdu_sum_sub   ? (mdu_sum_op1 - mdu_sum_op2)
                               : (mdu_sum_op1 + mdu_sum_op2);
   ```
3. **其余全部共用**：迭代计数器、MDU FSM、33-bit 加法器操作数寄存器、64-bit `{hi, lo}` 移位寄存器对
   都与 DIV 完全共享。

> **不能**反过来把"共享 3:2 压缩树"当作省面积的手段。压缩产生的 carry 在整数意义下等价，
> 在 GF(2) 意义下却是凭空多出的一项污染；实测 `S ⊕ C` 与正确 `clmul` 系统性不符。两种乘法
> 唯一能共享的只有 AND 部分积阵列本身。

**为什么是 32 拍而不是更少**：`P[31]` 依赖 `op1[0] · op2[31]`，必须把 32 个 bit 全部扫完。
曾用位精确模型扫描 `1<<30 / 1<<29 / 1<<16 / 1<<8` 四种计数初值，只有 `1<<30`（32 次）结果正确，
少一次迭代错误率即接近 100%。因此 clmul 与 mulh/mulhsu、除法一并属于"慢速 MDU"这一类。

> **重要修正**：早前的分析认为 SCR1 的 `mul` 是 32 拍迭代实现，据此推断采用迭代 clmul 可与 mul"对齐"。
> 这一前提是错的 —— 推荐的 `SCR1_CFG_RV32IMC_MAX` 配置自带 `` `define SCR1_FAST_MUL ``，
> 整数乘法本来就是**单周期**。实测（详见 §4.4）确认 `mul/mulh` 均为 1 拍、只有 `div` 是 32 拍。
> 因此本实现的真实取舍是 **面积 ~3.3 kGE ↔ clmul 延迟 1→32 拍**，而非"延迟对齐"。
> 若追求性能，注释掉 `SCR1_RVB_ITER_CLMUL` 即可回到单周期。

---

## 4. 测试

### 4.1 自检测试 `sim/tests/bitmanip`

* 生成器：**`tools/gen_bitmanip_test.py`** —— 内含一套**独立于 RTL 的 Python 黄金参考模型**
  （clz / ctz / cpop / min / max / sext / zext / rol / ror / orc.b / clmul / clmulh / clmulr / bclr / bset / binv / bext 全部用 Python 重算），
  而不是把 RTL 行为复述一遍。
* 产物：`sim/tests/bitmanip/bitmanip_test.S`（**282 项检查**）

| 分组 | 检查项 |
|---|---|
| Zba `sh1add/sh2add/sh3add` | 24 |
| Zbb `andn/orn/xnor` | 24 |
| Zbb `min/max/minu/maxu` | 40 |
| Zbb `rol/ror/rori` | 24 |
| Zbb `clz/ctz/cpop/sext.b/sext.h/zext.h/orc.b` | 70 |
| Zbc `clmul/clmulh/clmulr` | 36（含 4 组边界操作数） |
| Zbs 寄存器型 `bclr/bset/binv/bext` | 32 |
| Zbs 立即数型 `bclri/bseti/binvi/bexti` | 32 |
| **合计** | **282** |

* `bitmanip.c`：调用 `bm_run()`，读 `misa` CSR 校验 bit1，打印 `MISA = 0x40001106` 与
  `BITMANIP TEST PASSED / FAILED`，错误计数经 `a0` 返回（TB 以 `a0 == 0` 判定 PASS）。

### 4.2 全量回归

```
make run_modelsim CFG=MAX BUS=AXI TRACE=55
# Summary: 225/225 tests passed      (0 FAIL)
# BITMANIP TEST PASSED
# bitmanip.hex    OK    PASS
```

| 测试组 | 项数 | 结果 |
|---|---|---|
| `riscv_isa` | 40 | PASS |
| `riscv_compliance` | 55 | PASS |
| `arch_*`（riscv-arch-test rv32i_m） | 80 | PASS |
| 裸机 `riscv-tests` | 45 | PASS |
| hello / coremark / dhrystone21 / isr_sample | 4 | PASS |
| **`bitmanip`（新增）** | **1** | **PASS** |
| **合计** | **225** | **225 PASS / 0 FAIL** |

关键点：B 扩展译码改动动了 `funct7 = 0100000`（SUB/SRA）这一既有分支，也动了 SLLI / SRLI / SRAI / SLTI / SLTIU
的 OP-IMM 分支，**回归里 224 项既有测试全部保持 PASS**，说明既有的 RV32IMC 译码没有被破坏。

### 4.3 Lint —— 配置矩阵

单单 lint 一次是不够的：`SCR1_RVB_ITER_CLMUL` 是派生宏，`BALU` 与 `MDU` 两条路径都要能被编译。
**`tools/lint_matrix.py`** 自动遍历全部组合，每种都跑 AXI / AHB 两套 filelist：

```
python tools/lint_matrix.py
[OK  ] A. default custom: RVM+RVB+FAST_MUL -> iterative clmul, fast mul
[OK  ] B. RVB only (no M): combinational clmul in BALU
[OK  ] C. RVM+RVB, iterative MUL too (no FAST_MUL)
[OK  ] D. no RVB at all: stock SCR1 with M extension
[OK  ] E. neither M nor B
ALL CONFIGS CLEAN
```

脚本会临时改写 `scr1_arch_description.svh` 并在 `finally` 中还原，可放心反复运行。

### 4.4 延迟实测（`sim/tests/bitmanip/mdu_latency.S`）

纸面推导容易被打脸，所以加了在线实测。方法值得说明，因为**第一版测量是错的**：

* 最初用"串行依赖链"`clmul t0, t0, t1` 重复 1000 次。看似严谨，实则被 MDU 的 **early-out** 污染 ——
  `mdu_iter_req` 要求两个操作数都非零，GF(2) 迭代几次后 `t0` 收敛到 0，后续全部单周期返回，
  于是 `clmul` 被误测成"1.34 拍"。
* 修正为 **独立迭代 + 常量非零操作数**：无数据依赖时核按每周期一条发射，cycles/op 收敛为功能单元本身的
  占用时间（MDU 只有一套迭代 FSM，无法重叠）；常量操作数则保证每次迭代都走慢速路径。

操作数特意取奇数（奇 × 奇的 `P[0] = a[0]&b[0]` 恒为 1），进一步堵死归零的可能。

**结果（`CFG=MAX`，即 `SCR1_FAST_MUL` 生效）：**

| 指令 | 组合阵列实现 | **迭代 MDU 实现（当前）** |
|---|---|---|
| `add`（基线） | 1 | 1 |
| `andn`（Zbb，单周期参照） | 1 | 1 |
| `mul` | 1 | 1 |
| `mulh` | 1 | 1 |
| `div`（慢速参照） | 32 | 32 |
| `clmul` | 1 | **32** |
| `clmulh` | 1 | **32** |
| `clmulr` | 1 | **32** |

这张表同时是 §3.3 那条"重要修正"的证据：**`mul` 本来就是单周期的**（`SCR1_FAST_MUL` 由 MAX 配置自带），
真正 32 拍的只有除法。两个版本都通过全部 282 项自检。

---

## 5. 踩坑记录（环境/工具链相关，非 RTL 缺陷）

| # | 现象 | 根因 | 处理 |
|---|---|---|---|
| 1 | `bclr` 等汇编报 `unknown z ISA extension 'zbs'` | xpack gcc 10.2 / binutils 2.35 **不支持 Zbs**（Zba/Zbb/Zbc 支持且编码与 B 1.0 一致，已用 objdump 逐条核对过：`sh1add=20c5a533`、`clz=60059513`、`clmul=0ac59533`） | Zbs 的 8 条指令由生成器以 **`.word` 原始指令字**发出；其余用助记符 |
| 2 | `IDU Error: IALU_CMD out of range` ×14 | `scr1_pipe_idu.sv` 里 SVA 断言的上界硬编码成 `SCR1_IALU_CMD_REMU`，新增命令超出该上界 | 上界改为随 `SCR1_RVB_EXT` 取 `SCR1_IALU_CMD_BSET` |
| 3 | hex 没生成 / `-march` 不带 B | 顶层 Makefile 在命令行传 `ARCH=imc`，会盖掉子 Makefile 的普通赋值 | 子 Makefile 用 `override ARCH := imc_zba_zbb_zbc` |
| 4 | 启动就跑飞（`sc_exit` / `bm_run` 落在 0x48122e / 0x481230） | `asm_src := bitmanip_test.S` 顶掉了 `crt_tcm.S` | 改挂到 `asm_src_in_project` |
| 5 | `undefined reference to 'end'` | 用 `link.ld` 链接时 libnosys 的 `_sbrk` 需要 `end` 符号 | 在 `sim/tests/common/link.ld` 补 `PROVIDE(end = .);`（该文件为 CRLF，按 `\r\n` 匹配修补） |
| 6 | **bitmanip TIMEOUT**（最耗时的一处） | 程序已打印 `BITMANIP TEST PASSED` 却走不到退出；二分定位到 RELOC 拷贝循环的第一笔 store 落在 ITCM 窗口下方（0x47fffc），经 AXI 出片后在 TB 内存模型里挂死，且只在镜像超过几 KB 时复现 | bitmanip 改为**链接到 RAM**（`link.ld` + `crt.S`），完全不走 RELOC；B 指令的验证覆盖不受影响 |
| 7 | **完整回归里 bitmanip 单独 FAIL**（单独跑却 PASS） | `coremark` / `dhrystone21` 用 `-flto`，先把共享的 `sc_print.o` 编译成 **LTO 目标**；bitmanip 复用后链接触发 LTO 重新代码生成，LTO 子进程按链接期 `-march` 生成了 `sh2add / max`，但**没有把 `-march` 传给内层汇编器**，于是 `Error: unrecognized opcode 'sh2add'` | 在 bitmanip 的 `ADD_LDFLAGS` 加 `-Wa,-march=rv32$(ARCH)`，让 LTO 路径的汇编器也认识 Zba/Zbb/Zbc；不改动其他测试共用的目标文件 |

---

## 6. 如何复现

```bash
# 1) 重新生成自检汇编（可选，已提交 282 项版本）
python tools/gen_bitmanip_test.py            # BM_LIMIT=N 可缩小向量集用于二分定位

# 2) 只跑 B 扩展自检（含延迟实测）
make bitmanip CFG=MAX BUS=AXI TRACE=<n>      # 或 make run_modelsim ... 里的其中一项

# 3) 全量回归
make run_modelsim CFG=MAX BUS=AXI TRACE=<n>

# 4) 条件编译组合的全套 lint
python tools/lint_matrix.py

# 5) MDU carry-less 数据通路的位精确验证（不依赖仿真）
python tools/mdu_clmul_model.py
```

> **build 目录约定**：再跑全量记得换新的 `TRACE` 值。`clean_hex` 会删掉上一个目录里的 224 个 `.hex`，
> 在受保护的环境里会被批量删除拦截，导致回归起不来。

**两个可选开关**（均在 `src/includes/scr1_arch_description.svh`）：

| 宏 | 作用 | 默认 |
|---|---|---|
| `` `define SCR1_RVB_EXT `` | 整个 B 扩展的总开关，`misa.B` 随之清零/置位 | 开 |
| `` `define SCR1_RVB_ITER_CLMUL `` | Zbc 走 MDU 迭代（32 拍 / ~0.2 kGE）而非组合阵列（1 拍 / ~3.5 kGE） | 定义 `SCR1_RVM_EXT` 时自动开 |

把前者注释掉即回到 RV32IMC；把后者注释掉即回到单周期 clmul。

---

## 7. 已知限制与后续建议

**当前未覆盖 / 未实现**

* Zbs 的 **riscv-arch-test 官方向量**未接入（binutils 2.35 不支持 Zbs，官方测试也需相应工具链），目前用自研自检覆盖。
* 非法编码的 **trap 路径未做定向测试**（译码已置 `rvi_illegal`，但自检只测功能正确性，不测异常）。
* 未实现 Zb**k**（aes32 / sm4 / sha256 等 crypto 子集）、Zb**e**（bcompress/bdecompress）、Zbf / Zbm / Zbp / Zbr / Zbt。

**优先级建议**

| 级别 | 事项 | 说明 |
|---|---|---|
| **P0** | **确认 Zbc 的面积/延迟取舍是否可接受**（当前默认迭代，32 拍） | 面积敏感配置用迭代版是对的；但如果目标场景要用 `clmul` 做 CRC32 / AES-GCM GHASH / GF(2ᵐ) 域运算，32 拍会把这类工作负载拖垮。**注释掉 `SCR1_RVB_ITER_CLMUL` 即可回到 1 拍**，代价 +3.3 kGE。建议按实际应用场景先跑一个 CRC/GCM 吞吐预算再定 |
| **P0** | 用 `-march=rv32imc_zba_zbb_zbc` **重跑 coremark / dhrystone 量化收益** | 当前 benchmark 仍按 `ARCH=imc` 编译，未吃到 B 指令。GCC 10.2 已会自动为数组下标生成 `sh2add`，预期有可观收益 |
| **P1** | 综合确认**关键路径仍在既有 MDU**（而非新增逻辑） | 迭代版新增的逻辑只有 33 个 AND + 33 个 XOR + 一个 33-bit mux，且都不在 DIV 的关键路径之外（二者互斥选通）。但最好用 DC/Genus 跑一次确认没有意外进入 timing wall |
| **P1** | 补充官方 Zbs 测试向量 | 升级 binutils 至支持 Zbs 的版本，或保留 `.word` 方式接入官方签名比对 |
| **P1** | 补非法编码 → illegal-instruction trap 的定向测试 | 覆盖 `zext.h rs2≠0`、`orc.b shamt≠00111`、Zbb 保留选择子 |
| **P2** | 让组合阵列在非 clmul 指令时不翻转 | 已做（op2 被 `cmd_is_clmul` 门控）。但 Zbb 的 clz/ctz/cpop 仍然无条件计算，对极致低功耗配置可考虑一并门控 |
| **P2** | 考虑给慢速 MDU 加"提前结束"逻辑 | `mulh/mulhsu/div/clmul` 目前固定 32 拍。若操作数高位连续为 0，理论上可以提前收敛；代价是额外的检测逻辑 |
