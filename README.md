# SCR1-SP-TCM

基于 [Syntacore SCR1](https://github.com/syntacore/scr1) RISC-V 内核的个人增强 fork。

上游原始 README 见 [README_upstream_scr1.md](./README_upstream_scr1.md)。

---

# 本 Fork 的更新内容

## 更新总览

| # | 更新 | 类型 | 详细文档 |
|---|------|------|---------|
| 1 | ITCM/DTCM 单口 SRAM 重构 | 微架构 | [ITCM_DTCM_REPORT.md](./ITCM_DTCM_REPORT.md) |
| 2 | 取指流水线 bug 修复（dhrystone21 挂死） | Bug 修复 | 本 README §2 |
| 3 | RISC-V B 扩展（Zba/Zbb/Zbc/Zbs，31 条指令） | ISA 扩展 | [BITMANIP_EXTENSION_REPORT.md](./BITMANIP_EXTENSION_REPORT.md) |
| 4 | CV-X-IF 自定义指令扩展接口 | 总线接口 | [docs/cvxif_cfu_isa.md](./docs/cvxif_cfu_isa.md) |
| 5 | MTX 4×4 块矩阵乘加速器（CFU + DMA） | 加速器 | [docs/cvxif_cfu_isa.md](./docs/cvxif_cfu_isa.md) §Custom-1 |
| 6 | 工具链适配（GCC 15.x / newlib-nano） | 构建 | 本 README §6 |

各项均可独立开关，默认配置下与上游行为完全一致（零回归）。

---

## 1. ITCM/DTCM 单口重构

原版 ITCM/DTCM 共享一个双口 TCM。本 fork 拆分为两块物理独立的**单口 SRAM**：

- `src/top/scr1_itcm.sv` / `src/top/scr1_dtcm.sv` — 独立单口 RAM 模块
- `src/top/scr1_sp_memory.sv` — 单口存储原语（替代 `scr1_dp_memory.sv`）
- 独立地址窗口，符合主流 MCU（Cortex-M 风格）实践
- `src/top/scr1_imem_router.sv` — 新增取指路由器（锁存 outstanding 地址 + 持续驱动旧端口直至响应返回）

**收益**：单口 SRAM 面积/功耗约省 30-40%（同容量双口对比），便于 ASIC/FPGA 映射。
基准测试对比见 [BENCHMARK_RESULTS.md](./BENCHMARK_RESULTS.md)。

## 2. 取指流水线 Bug 修复

修复两个上游 bug（dhrystone21 在 TCM/RAM 跨界取指时挂死）：

1. **IFU discard 计数错误**（`scr1_pipe_ifu.sv`）：`SCR1_NEW_PC_REG` 分支的 `discard_cnt` 多计 1，新取指响应被误丢弃 → auipc 被跳过
2. **imem_router 端口撤回死锁**：`fsm=DATA && port_sel != port_sel_r` 时路由器停止驱动旧端口，outstanding 响应永远不返回

修复后全回归 **140/141 通过**（唯一失败 shamt.hex 为预存问题，与本次修改无关）。

## 3. B 扩展（SCR1_RVB_EXT）

新增单周期位操作单元 `src/core/pipeline/scr1_pipe_balu.sv`：

- **Zba**：sh1add/sh2add/sh3add
- **Zbb**：andn/orn/xnor/clz/ctz/cpop/max/min/rol/ror/rev8 等
- **Zbc**：clmul/clmulh/clmulr（复用 MDU radix-2 迭代数据通路）
- **Zbs**：bset/bclr/binv/bext 及立即数变体

MAX 配置默认开启。测试：`sim/tests/bitmanip/`。

## 4. CV-X-IF 自定义指令接口（SCR1_RVX_EXT）

按 [CORE-V eXtension Interface v1.0.0](https://github.com/openhwgroup/cv-x-if) 规范外接 CFU（Custom Function Unit）：

```
IDU 译码 custom-0..3 opcode ──▶ CV-X-IF 请求通道 ──▶ 外部 CFU
                              ◀── CV-X-IF 响应通道 ──┘
```

- 核心侧改造全部由 `SCR1_RVX_EXT` 宏包裹，IALU/MDU/LSU **零修改**
- 支持单周期/多周期 CFU，带超时保护（`SCR1_CVXIF_CFU_MAX_LAT`）
- `misa.X` 位自动置位
- 参考 CFU（`scr1_pipe_cfu.sv`）：custom-0 空间 8 条 ALU 指令（add/xor/sub/and/or/sll/srl/mul）
- 协议监控器 `scr1_cvxif_monitor.sv`
- 测试 `sim/tests/cvxif/`：14 用例全 PASS（GAS `.insn` 伪指令编码，无需改 GCC）

## 5. MTX 矩阵乘加速器（SCR1_MTX_EXT，需同时开 RVX）

在 CV-X-IF 基础上增加 **4×4 块矩阵乘加速**，CFU 具备独立 dmem master，可自主访问 DTCM 与外部存储：

```
LSU ──┐
      ├── scr1_dmem_arbiter（轮转仲裁+事务锁）──▶ dmem_router ──▶ DTCM / AXI/AHB
CFU ──┘
```

- **指令集**（custom-1，opcode=0x2b）：
  - `cfu.matmul4/4h/4b` — 4×4 int32/int16/int8 块乘 C=A×B（rs1/rs2=A/B 基地址）
  - `cfu.mcfg_stride/msk/cbase` — 行步长/符号模式/C 基地址配置
  - `cfu.stc` — **posted write**：结果整块入队后台写回，核不阻塞
  - `cfu.xwait` — **fence**：排空写队列，返回状态字（错误计数+粘滞位）
- **CFU 内部**：DMA 引擎（地址生成按 stride）+ MAC 阵列 + FSM（IDLE→LD_A→LD_B→COMP→DONE）
- **错误契约**：访存错误置粘滞标志，后续指令拒绝执行直至 xwait 清除
- 测试 `sim/tests/mtx/`：AHB/AXI 双总线 PASS，与 LSU 混合访问验证仲裁公平性

## 6. 工具链适配

- `sim/tests/common/common.mk`：链接顺序修复（`-lgcc` 先于 `-lc`，加 `-lnosys`）适配 GCC 15.x + newlib-nano
- `tools/`：WSL xpack 工具链 shim（路径转换、`_zicsr_zifencei` 注入、symlink 脚本）
- 测试 Makefile 对齐现代工具链

---

# 快速上手

## 环境

- 仿真器：QuestaSim / ModelSim（Verilator v5 未在本 fork 验证）
- 工具链：xpack riscv-none-elf-gcc ≥ 14（Windows 侧经 WSL shim，见 `tools/`）
- make + Git bash（Windows）

## 编译与仿真

```bash
# 默认配置回归（零侵入验证）
make run_modelsim TARGETS=hello BUS=AHB CFG=MAX

# B 扩展测试
make run_modelsim TARGETS=bitmanip BUS=AHB CFG=MAX

# CV-X-IF 测试（custom-0 ALU 指令）
make run_modelsim TARGETS=cvxif BUS=AHB CFG=MAX \
     SIM_BUILD_OPTS="+define+SCR1_RVX_EXT"

# MTX 矩阵乘测试（完整链路：DMA+MAC+posted write+fence）
make run_modelsim TARGETS=mtx BUS=AHB CFG=MAX \
     SIM_BUILD_OPTS="+define+SCR1_RVX_EXT +define+SCR1_MTX_EXT"
```

## 扩展开关

| 宏 | 默认 | 说明 |
|----|------|------|
| `SCR1_RVB_EXT` | MAX 配置开启 | B 扩展 |
| `SCR1_RVX_EXT` | 关 | CV-X-IF 接口 + 参考 CFU |
| `SCR1_MTX_EXT` | 关 | 矩阵乘加速（依赖 RVX） |

均定义于 `src/includes/scr1_arch_description.svh`，关闭时行为与上游一致。

---

# 目录结构（新增部分）

```
src/core/pipeline/scr1_pipe_balu.sv      # B 扩展单元
src/core/pipeline/scr1_pipe_cfu.sv       # CV-X-IF 参考 CFU
src/core/pipeline/scr1_pipe_cfu_mtx.sv   # 矩阵乘 CFU（DMA+MAC+posted write）
src/core/pipeline/scr1_cvxif_monitor.sv  # CV-X-IF 协议监控器
src/top/scr1_itcm.sv / scr1_dtcm.sv      # 单口 ITCM/DTCM
src/top/scr1_sp_memory.sv                # 单口存储原语
src/top/scr1_dmem_arbiter.sv             # LSU/CFU 仲裁器
sim/tests/{bitmanip,cvxif,mtx,tcm_cross}/  # 测试
tools/                                   # 工具链脚本
docs/cvxif_cfu_isa.md                    # 自定义指令 ISA 文档
```

# 许可

继承上游 SHL 许可（见 [LICENSE](./LICENSE)），允许 unrestricted 商用。
