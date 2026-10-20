# SCR1 Benchmark 分数与对标分析

配置：`CFG=MAX BUS=AXI TCM=1`（RV32IMC + IPIC + TCM），QuestaSim 2024.1，
xpack riscv-none-embed-gcc 10.2，TCM 零等待、imem/dmem pattern = `FFFFFFFF`（无附加延迟）。
频率归一化到 **1 MHz**，便于和 MCU 厂商口径直接对比。

---

## 1. 分数（ITCM/DTCM 新版）

### 1.1 推荐口径：`-O3` 不开 LTO（可和厂商数字直接比）

| Benchmark | 实测周期 | 归一化分数 |
|---|---|---|
| CoreMark 1.0（1 iteration, 2K performance run） | 457,561 cycles | **2.19 CoreMark/MHz** |
| Dhrystone 2.1（500 runs） | 242,071 cycles（484 cycles/run） | 2,065 Dhrystones/s/MHz → **1.18 DMIPS/MHz** |

> 换算成绝对分：100 MHz 时 ≈ **219 CoreMark / 118 DMIPS**；50 MHz 时 ≈ 109 CoreMark / 59 DMIPS。

### 1.2 仓库默认口径：`-O3 -flto`（会虚高，仅供自比）

| Benchmark | 实测周期 | 归一化分数 |
|---|---|---|
| CoreMark 1.0 | 482,325 cycles | 2.07 CoreMark/MHz |
| Dhrystone 2.1 | 123,065 cycles（246 cycles/run） | 4,063 Dhrystones/s/MHz → **2.31 DMIPS/MHz** |

**为什么 Dhrystone 差了 2 倍？** 用 `minstret` 插桩实测：
开 LTO 时一个 Dhrystone run 只执行 **145 条指令**（IPC 0.60），
GCC 的 `-O3 -flto` 把大量字符串常量比较/拷贝常数折叠掉了。
厂商引用的 DMIPS 基本都是"不开 inline / 不开 multi-file 编译"或至少不开 LTO 的口径，
所以 **2.31 DMIPS/MHz 不能拿来和 Cortex-M 的 1.25 直接比**；
**1.18 DMIPS/MHz 才是可对标值**。CoreMark 抗优化能力强，两种口径只差 5%。

---

## 2. 改造前 / 改造后对比（同编译器、同构建）

### 非 LTO 口径

| | 原版双口 TCM | 新版 ITCM+DTCM | 差异 |
|---|---|---|---|
| CoreMark cycles | 458,871 | 457,561 | −0.29 % |
| CoreMark/MHz | 2.179 | 2.185 | +0.3 % |
| Dhrystone cycles | 239,571 | 242,071 | +1.04 % |
| DMIPS/MHz | 1.188 | 1.175 | −1.0 % |

### LTO 口径

| | 原版双口 TCM | 新版 ITCM+DTCM | 差异 |
|---|---|---|---|
| CoreMark cycles | 482,325 | 482,325 | **0.00 %** |
| Dhrystone cycles | 126,565 | 123,065 | −2.77 % |

**结论：性能差异在 ±1 % 以内，属于链接布局噪声，拆分 ITCM/DTCM 没有引入退化。**
（Dhrystone 那 1~3 % 是 `__global_pointer$` 从 `.rodata` 挪到 DTCM 段后，
热全局变量能用 1 条 gp 相对指令寻址带来的代码生成差异，不是存储架构收益。）

---

## 3. 对标 MCU 是什么水平

### 3.1 ARM Cortex-M（ARM 官方口径，ARM compiler）

| 内核 | DMIPS/MHz | CoreMark/MHz | SCR1 相对 CoreMark | SCR1 相对 DMIPS |
|---|---|---|---|---|
| Cortex-M0 | 0.87 | 2.33 | 94 % | 136 % |
| Cortex-M0+ | 0.95 | 2.42 | 90 % | 124 % |
| Cortex-M23 | 0.98 | 2.64 | 83 % | 120 % |
| Cortex-M3 | 1.25 | 3.34 | 65 % | 94 % |
| Cortex-M4 | 1.25 | 3.42 | 64 % | 94 % |
| Cortex-M33 | 1.50 | 4.02 | 54 % | 79 % |
| Cortex-M7 | 2.14 | 5.01 | 44 % | 55 % |
| **SCR1（本测）** | **1.18** | **2.19** | — | — |

（ARM 另有"full optimization"Dhrystone 口径：M0 1.21 / M0+ 1.31 / M3 1.89 / M4 1.95 / M7 2.55，
我们的非 LTO 构建大致对应这个档位。）

### 3.2 RISC-V 同行（GCC 口径，与我们的构建可比性最好）

| 核 | DMIPS/MHz | CoreMark/MHz | SCR1 相对 CoreMark |
|---|---|---|---|
| SiFive E20 | 1.07 ~ 1.47 | 2.5 | 88 % |
| SiFive E21 | 1.38 | 3.1 | 71 % |
| SiFive E31 | 1.61 | 3.01 | 73 % |
| 兆易 GD32VF103（芯来 Bumblebee） | — | 3.12 | 70 % |
| Cortex-M0+（GCC 测） | — | 1.8 | 122 % |
| Cortex-M3/M4（GCC 测） | — | 2.76 | 79 % |
| **SCR1（本测）** | **1.18** | **2.19** | — |

### 3.3 定位

- **CoreMark：Cortex-M0/M0+ 档，约 Cortex-M3 的 65~79 %。**
- **DMIPS：介于 Cortex-M0+（0.95）和 Cortex-M3（1.25）之间，约 M3 的 94 %。**
- 综合一句话：**M0+/M23 ~ M3 之间，脚踩在 M3 门槛下沿**；
  在 RISC-V 同行里低于 SiFive E2/E3 系列和芯来 Bumblebee（它们的 CoreMark/MHz 在 2.5~3.1）。
- 差距的主要来源不是主频而是 **IPC**：实测 SCR1 IPC ≈ **0.60**（Dhrystone，minstret 插桩）。
  SCR1 是 Syntacore 定位的**面积极小核**（卖点是面积/功耗，不是性能），
  单发射顺序、无分支预测/分支目标预取、无写缓冲；
  Cortex-M3 有 3 级流水 + 分支目标预取 + 哈佛总线 + 单周期写缓冲，IPC 明显更高，
  M7 更是双发射 6 级流水 + I/D Cache。

---

## 4. 复现方式

```bash
# 新版，非 LTO（推荐口径）
make run_modelsim CFG=MAX BUS=AXI TCM=1 TRACE=3 \
     TARGETS="coremark dhrystone21" ITERATIONS=1 \
     ADD_FLAGS="" ADD_LDFLAGS="" root_dir="C:/Users/Administrator/WorkBuddy/scr1/scr1"

# 新版，仓库默认 LTO 口径
bash tools/run_bench.sh "C:/Users/Administrator/WorkBuddy/scr1/scr1" 1

# 原版基线（worktree）
bash tools/run_bench.sh "C:/Users/Administrator/WorkBuddy/scr1/scr1_base" 1
```

- `TRACE=2 / TRACE=3` 只是为了让 build 目录独立（`SCR1_TRACE_LOG_DIS` 不变）。
  注意 `clean_hex` 会 `rm -f` 全量回归留下的 224 个 `.hex`，用独立目录可避开。
- **TB watchdog = 2,000,000 cycles**（`src/tb/scr1_top_tb_axi.sv`）。
  非 LTO 的 dhrystone 总周期更长，若和 LTO 的 coremark 混跑会在打印阶段撞上 watchdog
  报 `Error: TIMEOUT`（FAKE FAIL）；**计时数字在 timeout 之前已完整打印，仍然有效**。
  建议同一构建口径放在同一个 build 目录里跑（上面的 TRACE=3 就是 2/2 PASS）。

## 4.5 官方口径 vs 我们的实测口径（重要）

**Syntacore SCR1 Datasheet v2 (2025) 官方数字：**

| 项目 | 官方值 |
|---|---|
| Dhrystone -O2 | **1.55 DMIPS/MHz** |
| Dhrystone best (with LTO) | **3.15 DMIPS/MHz** |
| CoreMark best | **3.05 CoreMark/MHz** |
| 面积 | 10..36 kGates；MAX 配置 0.013 mm²（28HPC），2.29 µW/MHz |
| 最高频率 | MAX 配置 1200+ MHz（28HPC+, 12-track LVT typical） |
| **测试条件** | LLVM-20-sc（Syntacore 定制 LLVM），run from TCM，配置 = **RV32IM / 3-stage / TCM 32KB** |

**SiFive E21 官方数字**：1.38 DMIPS/MHz，3.1 CoreMark/MHz（GCC）；
28nm core-only 0.015 mm²、core complex 0.037 mm²，585 MHz。

**→ 按官方口径，SCR1 并不比 E21 差：**

| | SCR1（官方） | E21（官方） | 比值 |
|---|---|---|---|
| CoreMark/MHz | 3.05 | 3.1 | 98%（打平） |
| DMIPS/MHz | 1.55（-O2） | 1.38 | **112%（SCR1 更高）** |
| 面积（28nm） | 0.013 mm² | 0.015 / 0.037 mm² | 更小 |
| 最高频率 | 1200+ MHz | 585 MHz | 更高 |

**那我们为什么只测到 2.19 / 1.18（官方的 72% / 76%）？** 三个口径差异：

1. **编译器（主因）**——官方用 LLVM-20-sc（`-mcpu=scr1` 专用调度 + `-scr-loop-streaming`
   + `--crc-matcher=true` + 函数/循环对齐 + EEMBC ground rules）；我们用开源 GCC 10.2，
   RISC-V 后端明显更弱。
2. **配置**——官方测的是 RV32IM、**3-stage**、TCM 32KB；我们跑的是
   MAX = RV32**IMC**（带 C 扩展）、**4-stage**（MAX 带 DEC stage）、TCM 64KB+64KB。
3. **LTO 口径**——官方 Dhrystone 的 3.15 明确标了 LTO；我们的 1.18 是非 LTO。
   若都按 LTO 比：我们 2.31 vs 官方 3.15，仍是 73%。

**已排除的一个因素**：我在 GCC 10.2 上补了官方也在用的
`-falign-functions=8 -falign-loops=4 -finline-functions` 重跑，
CoreMark 反而从 2.185 掉到 **2.096**（−4%），Dhrystone 完全没变（242,070 cycles）。
→ 差距不在指令对齐，而在编译器本身的调度/优化能力。

**结论：拿 SCR1 和 E21 做选型对比，应该用官方口径（或至少同编译器、同 ISA 配置）比，
那样是打平、且 SCR1 面积更小；我们这个 2.19 是"GCC 10.2 + MAX 配置"口径下的数字，
只能用于本项目改造前后的自比，不能当核的绝对性能去和厂商数字比。**

---

## 5. 遗留提醒

`.rodata` 放在了 ITCM。若某应用频繁用 load 读 rodata 常量，数据侧会走 dmem → ITCM，
与取指争同一块单口 RAM，会被 ITCM 仲裁器插气泡。本次两个 benchmark 都没触发
（coremark 计时区内几乎无 rodata load）。要彻底规避可把 `.rodata` 也挪进 DTCM。
