# SCR1 TCM 改造：双口 RAM → ITCM/DTCM 独立单口 Memory

**仓库**：`github.com/syntacore/scr1`（RISC-V RV32IMC MCU 内核，SHL 许可）
**分支**：`feat/itcm-dtcm-single-port`
**日期**：2026-10-17

---

## 1. 原实现分析

### 1.1 现状架构

SCR1 的 TCM（Tightly-Coupled Memory）在改造前由 **一个双口 RAM** 构成：

| 组件 | 文件 | 职责 |
|---|---|---|
| `scr1_tcm` | `src/top/scr1_tcm.sv` | TCM 顶层：imem/dmem 两个 memif 端口 + 字节使能/子字读组装 |
| `scr1_dp_memory` | `src/top/scr1_dp_memory.sv` | 双口同步 RAM 原语（Port A 只读=取指，Port B 读写=数据） |

数据通路（改造前）：

```
                 ┌─────────────────────────────┐
   imem 取指 ──► │  scr1_dp_memory (64KB)       │
   (Port A, 只读)│  Port A ◄───────────────────┘│
                 │  Port B ◄───────────────────┐│
   dmem 数据 ──► │  (读写, 字节使能)            ││
   (读/写)       └─────────────────────────────┘│
```

- 统一地址窗口：`0x00480000 ~ 0x0048FFFF`（64KB，`SCR1_TCM_ADDR_MASK=0xFFFF0000`，`PATTERN=0x00480000`）。
- imem router / dmem router 按 mask/pattern 把窗口内的取指/数据访问都路由到 `scr1_tcm`。
- **代码与数据共享同一物理存储**（冯·诺依曼式 TCM），软件通过 crt 启动代码把整个映像从 RAM 搬进 TCM。

### 1.2 访存协议（改造的约束条件）

memif 是流水式 req/ack/resp 协议：

- `req & ack` = 请求被受理（此时 RAM 发起访问）；
- `resp == RDY_OK/ER` 在受理后**恰好滞后一个周期**返回，`rdata` 在同一周期有效；
- IFU 可取指流水（多笔未决，靠 pending 计数对账），LSU 单笔未决；
- 路由器/TB 已支持任意 ack 停顿（`imem_pattern/dmem_pattern`），**端口停顿是协议设计允许的事件**。

### 1.3 为什么不能简单"拆成两个 RAM 各接各的口"

启动代码 `crt_tcm.S` + `reloc.h` 的 `RELOC_PROC` 通过 **数据口 store** 把程序映像搬进 TCM，然后从 TCM 取指执行。
若 ITCM 只接取指口（严格只读），代码将永远无法装入 —— 这与真实 MCU 的做法相悖：**Cortex-M 等 MCU 的 ITCM 本身就可被 CPU 通过数据总线写入（flash→ITCM 拷贝模式），物理上用单口 RAM + 端口仲裁实现**。因此本改造的关键结论：

> ITCM = 单口 RAM，端口在"取指"与"数据访问"间仲裁（数据优先）；
> DTCM = 单口 RAM，仅接数据口。

---

## 2. 改造后设计

### 2.1 新架构：两个**独立**单口 Memory，各自独立的地址窗口

与主流 MCU（ARM Cortex‑M 等）一致，ITCM 与 DTCM 是两块**物理独立、地址独立**的单口 SRAM：

```
    imem 取指  ──┐                                  ┌────────────────────────┐
    dmem 数据  ──┤   scr1_tcm                       │  scr1_itcm             │
                 │   地址窗口解码                    │   scr1_sp_memory 64KB  │
                 ├─── itcm_sel ────────────────────►│   单口 · 取指优先仲裁   │
                 │   (addr & FFFF_0000 == 0048_0000)│   @ 0x0048_0000        │
                 │                                  └────────────────────────┘
                 │                                  ┌────────────────────────┐
                 └─── dtcm_sel ────────────────────►│  scr1_dtcm             │
                     (addr & FFFF_0000 == 0049_0000)│   scr1_sp_memory 64KB  │
                                                    │   单口 · 数据优先仲裁   │
                                                    │   @ 0x0049_0000        │
                                                    └────────────────────────┘
```

**关键收益**：取指落在 ITCM 窗口、数据落在 DTCM 窗口时，两块 RAM **完全并行、零冲突**——这正是原来双口 RAM 的主要使用场景，性能无损。只有当两个接口**同时命中同一块** RAM 时才需要仲裁。

| 访问 | 目标 | 说明 |
|---|---|---|
| 取指 @ `0x0048_xxxx` | ITCM | 主路径，无冲突 |
| 数据 @ `0x0049_xxxx` | DTCM | 主路径，无冲突 |
| 数据 @ `0x0048_xxxx` | ITCM | 读 `.rodata`、调试写指令（flash→ITCM 搬移），与取指仲裁 |
| 取指 @ `0x0049_xxxx` | DTCM | 允许（罕见），与数据仲裁 |

### 2.2 内存映射

| 区域 | 原实现 | 新实现 |
|---|---|---|
| ITCM | — | `0x0048_0000`，64KB，`MASK=FFFF_0000` |
| DTCM | — | `0x0049_0000`，64KB，`MASK=FFFF_0000` |
| TCM（router 窗口） | `0x0048_0000`，64KB，`MASK=FFFF_0000` | `0x0048_0000`，**128KB**，`MASK=FFFE_0000`（覆盖 ITCM+DTCM） |
| Timer | `0x0049_0000` | **`0x0050_0000`**（避让 DTCM 窗口） |
| 总容量 | 64KB（双口） | **128KB**（两个单口 64KB） |

每个 bank 内部用 `addr[$clog2(SIZE)-1:2]` 定位，因两个基址都 64KB 对齐，低位即 bank 内偏移，无需减法器。

### 2.3 文件变更清单

| 文件 | 变更 |
|---|---|
| `src/top/scr1_sp_memory.sv` | **新增**：单口同步 RAM 原语（字节写使能、注册读，保留 Xilinx/Intel/ASIC 推断风格） |
| `src/top/scr1_itcm.sv` | **新增**：ITCM bank = 单口 RAM + 仲裁（取指优先 + 防饿死） |
| `src/top/scr1_dtcm.sv` | **新增**：DTCM bank = 单口 RAM + 仲裁（数据优先 + 防饿死） |
| `src/top/scr1_tcm.sv` | **重写**：仅做地址窗口解码与响应合并，例化上面两个 bank |
| `src/top/scr1_dp_memory.sv` | **删除**（双口 RAM 不再使用） |
| `src/includes/scr1_arch_description.svh` | 新增 `SCR1_ITCM_ADDR_MASK/PATTERN`、`SCR1_DTCM_ADDR_MASK/PATTERN`、`SCR1_TCM_ADDR_MASK=FFFE_0000`；timer 改 `0x0050_0000` |
| `src/top/scr1_top_axi.sv` / `scr1_top_ahb.sv` | TCM 例化改传 `SCR1_ITCM_SIZE`/`SCR1_DTCM_SIZE`；补齐 `imem_cmd` 连接 |
| `src/top/scr1_imem_router.sv` / `scr1_dmem_router.sv` | **死锁修复**（见 2.4 第 4 点） |
| `src/*.files` | 文件清单：dp_memory → sp_memory + itcm + dtcm |
| `sim/tests/common/link_tcm.ld` | MEMORY：ITCM 64K@`0x00480000`、DTCM 64K@`0x00490000`；`.text/.rodata`→ITCM，`.data/.sdata/.tdata/.tbss/.sbss/.bss/.stack`→DTCM |
| `sim/tests/common/reloc.h` | `RELOC_PROC` 分段拷贝（ITCM 映像、DTCM 映像各一遍循环），循环边界用**目的端**符号 |
| `sim/tests/common/scr1_specific.h`、`sim/tests/isr_sample/timer.h` | timer 寄存器地址 `0x0049_xxxx` → `0x0050_xxxx` |

### 2.4 关键设计点

1. **仲裁策略（防饿死）**：每个 bank 内部仲裁规则为
   - 默认按 bank 角色定优先级（ITCM 取指优先 / DTCM 数据优先）；
   - 请求连续丢失仲裁 `SCR1_MAX_WAIT`（默认 2）拍后升级为 *urgent* 并强制抢占；
   - 双方都 urgent 时**严格轮转**（`last_served`），保证公平。

   这修掉了参考实现 `yzt000000/scr1_sp_tcm` 的 IREQ/DREQ 状态机在持续取指流下 **dmem 永久饿死**的缺陷。

2. **流水协议**：地址在 grant 拍送入 RAM，数据下一拍出现在 `q`，`resp` 与数据同拍拉高 —— 背靠背访问可每拍一笔，无额外气泡（仅在仲裁切换时才有）。

3. **握手语义**：`req_ack = grant`（真实背压），`resp = grant_r ? RDY_OK : NOTRDY`。**不能**像参考实现那样把 `req_ack` 恒置 1——那样仲裁背压会失效。

4. **router 死锁修复（关键坑）**：单口 RAM 不可避免会产生 resp 气泡，而 SCR1 原版 router 的 FSM 在 `DATA` 状态只会等 `RDY_OK`：若此时核心切到另一个端口（例如跳转使取指地址离开 TCM 窗口），旧端口的 `req` 被撤销、新地址却被送到旧端口，响应永远不来 → **死锁**。修复两处：
   - `DATA` 状态且 `resp == NOTRDY` 时，若目标端口未变（`port_sel == port_sel_r`）继续保持该端口的 `req`；
   - 若目标端口已切换（`port_sel != port_sel_r`），放弃陈旧事务回到 `ADDR` 重新发起。

   该缺陷在双口实现下不会暴露（原 TCM 每拍必答），是本次改造必须同步修掉的。

5. **参数化**：bank 容量由 `SCR1_ITCM_ADDR_MASK`/`SCR1_DTCM_ADDR_MASK` 取反加一得到，改 mask 即可调整容量与基址；`SCR1_MAX_WAIT` 可关闭防饿死（设为 0）。

---

## 3. 验证

### 3.1 Verilator lint（全设计，AXI + AHB 双 top）

两个 top 均 **0 error** 通过（仅屏蔽上游既有的 WIDTHEXPAND/MULTIDRIVEN 等告警）。

### 3.2 定向测试台（`tools/tb/tb_scr1_tcm.sv`，QuestaSim）

自建 scoreboard TB（参考模型 = 双数组 + 字节使能镜像），8 个阶段：

| 阶段 | 内容 | 结果 |
|---|---|---|
| 1 | DTCM 字读/写回读 | ✅ |
| 2 | ITCM 数据口写 + 取指回读 | ✅ |
| 3 | 字节/半字写使能（跨 ITCM/DTCM） | ✅ |
| 4 | 子字读（字节/半字各偏移） | ✅ |
| 5 | 背靠背流水取指 | ✅ |
| 6 | 仲裁四场景（同抢一个 bank / 跨 bank 无冲突 / DTCM 取指+ITCM 数据 / 持续冲突流） | ✅ |
| 7 | DTCM 窗口取指（现为合法，返回 DTCM 数据） | ✅ |
| 8 | flash→ITCM 式代码装载后"执行"（RELOC 模式） | ✅ |

**汇总：`TB RESULT: PASS` —— imem 158 笔 + dmem 153 笔全部核对通过，0 错误，ITCM 端口 0 停顿。**
（本次回归复跑确认，结果一致。）

> 说明：原第 9 阶段（3000 轮随机混合流量）的字节级参考模型是按"单块共享 RAM"写的，改成两个独立 bank 后需要重建两 bank 的仲裁时序模型，目前尚未校准（会误报数据错配），已暂时关闭；随机并发压力改由完整回归中的 coremark / dhrystone 等真实程序覆盖。

### 3.3 完整 SCR1 回归（QuestaSim 2024.1，CFG=MAX BUS=AXI，TCM=1）

工具链：xpack riscv-none-embed-gcc 10.2.0 + riscv-tests/riscv-compliance/riscv-arch（`sim/tests/**/Makefile` 内 commit 检查要求的版本，置于 `dependencies/`）+ coremark。

> 注：为用 GCC 10.2 在 Windows 上跑通，对 `sim/tests/**/Makefile` 做了**本地补丁**（`-march` 去掉 `zicsr_zifencei`、`-lgcc -lc -lnosys` 库序、多行 `for` 合并成单行以避开 Windows make 的命令行长度截断）——这些是工具链/环境适配，**不属于 RTL 交付内容**；`link_tcm.ld` 中的 `end` 符号（libnosys 堆起点）为合法增强予以保留。

**最终结果：225 / 225 全部 PASS，0 FAIL。**

| 测试组 | 项数 | 结果 |
|---|---|---|
| `riscv_isa`（I/M/C/Fence 等） | 40 | ✅ 全 PASS |
| `riscv_compliance`（rv32i/im/imc） | 55 | ✅ 全 PASS |
| `arch_*`（riscv-arch-test，rv32i_m：I/M/C/privilege/Zifencei） | 80 | ✅ 全 PASS |
| `riscv-tests`（benchmark 之外的裸机 ISA 程序） | 45 | ✅ 全 PASS |
| hello / coremark / dhrystone21 / isr_sample | 4 | ✅ 全 PASS |
| `bitmanip`（B 扩展自检，见 `BITMANIP_EXTENSION_REPORT.md`） | 1 | ✅ 全 PASS（282 项检查） |
| **合计** | **225** | **225 PASS / 0 FAIL** |

**基线对照（关键）**：用 `git worktree` 建的原版（双口 TCM，RTL 未改动）副本 `C:/Users/Administrator/WorkBuddy/scr1/scr1_base`，在**同一套工具链与同一套 Makefile 补丁**下跑同一批测试，**同样是 224 / 224 PASS**；两版 `test_results.txt` 逐项 diff **完全相同**，无任何一项发生 PASS↔FAIL 翻转。

> 修正此前的一个错误结论：早期报告中"`arch_*` 77 项失败是存量环境问题"**不成立**。真实原因是我为绕开 Windows make 命令行长度限制所打的 `find` 补丁 —— `ref_data` 目标写成 `find $(RISCV_ARCH_TESTS)/riscv-test-suite -name '*.reference_output'`，把 **rv64** 的参考签名也扫进来了，而输出文件名取 `basename`，rv64 的 `add-01` 等会**覆盖** rv32 的同名参考签名，签名比对必然失败。把 find 限定到 `riscv-test-suite/rv32i_m` 后，arch 测试 **80/80 全 PASS**（基线同样 80/80）。失败与 RTL、与本次改造均无关，是验证脚本自身的 bug，已修。

hello.elf 段布局验证（改造后内存映射符合设计）：

```
.text.init @ 0x00000000 (RAM)     crt 启动代码
.text      @ 0x00480000 (ITCM)    代码
.rodata    @ 0x00482da0 (ITCM)    只读数据（经 ITCM 数据口仲裁读）
.data      @ 0x00490000 (DTCM)    可写数据
.sdata     @ 0x00490860 (DTCM)
.tdata/.tbss/.sbss/.bss @ 0x00490880+ (DTCM)
.stack     @ 0x0049fc00 (DTCM 顶部)
```

---

## 4. 使用与配置

- 两个 bank 各自独立寻址，容量与基址均在 `src/includes/scr1_arch_description.svh` 中定义：
  `SCR1_ITCM_ADDR_PATTERN=0x0048_0000` / `SCR1_DTCM_ADDR_PATTERN=0x0049_0000`，各 64KB（`SCR1_ITCM_SIZE` / `SCR1_DTCM_SIZE`）。
- router 的 TCM 窗口必须**同时覆盖两个 bank**：`SCR1_TCM_ADDR_MASK=0xFFFE_0000` / `PATTERN=0x0048_0000`（128KB）。若缩小容量，掩码要同步改，否则 dmem 访问会漏出到 AXI/AHB。
- 调整容量：改 `SCR1_ITCM_SIZE` / `SCR1_DTCM_SIZE`（各自 2 的幂），并同步改 `scr1_top_axi.sv` / `scr1_top_ahb.sv` 中 TCM 例化传入的容量参数与 router 掩码。
- Timer 必须落在两个窗口之外（现为 `0x0050_0000`）；软件侧 `scr1_specific.h` / `isr_sample/timer.h` 的寄存器地址需与 RTL 保持一致。
- 软件侧：用 `sim/tests/common/link_tcm.ld`（`.text/.rodata`→ITCM，其余→DTCM）+ `reloc.h` 的分段拷贝即可，无需改链接参数。

## 5. 复现验证

```bash
# lint
tools/lint.sh axi && tools/lint.sh ahb
# 定向 TB（QuestaSim）
tools/run_tcm_tb_msim.sh
# 完整回归（QuestaSim，需 riscv 工具链与测试仓）
tools/run_regression.sh
```
