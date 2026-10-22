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
| 6 | TCM AHB Subordinate 端口（外部 master 加载 ITCM/DTCM） | 总线接口 | 本 README §6 |
| 7 | 外部 halt/resume 控制输入 | 调试控制 | 本 README §7 |
| 8 | IPIC 128 线中断 + 分段优先编码器 | 中断系统 | 本 README §8 |
| 9 | 协议正确性修复包（bank 归属锁存 / MTX 缺陷修正） | Bug 修复 | 本 README §9 |
| 10 | 工具链适配（GCC 15.x / newlib-nano） | 构建 | 本 README §10 |

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

## 6. TCM AHB Subordinate 端口（SCR1_TCM_EN）

外部总线 master（宿主 CPU / DMA / 调试器）可经专用 **AHB-Lite slave 端口**直接读写 ITCM/DTCM——加载程序、读回校验、运行时 mailbox 通信：

```
外部 master ──tcm_sbr_h*──▶ scr1_tcm_ahb_sbr ──▶ scr1_tcm.sbr_* ──▶ ITCM/DTCM bank 内 3 路仲裁
                                (AHB→memif)        (bank 归属锁存)     (imem/dmem/slv, slv 最低优先+反饿死)
```

- **直连 bank 结构**：不占用核心 dmem_router/arbiter 资源；slv 参与各 bank 仲裁（最低优先 + `SCR1_SLV_MAX_WAIT=8` 拍反饿死轮转），复位期（核心无请求）天然独占
- **复位域 `rst_n_sync`**：CPU 复位保持期间即可加载（`cpu_rst_n` 由 tb 在加载完成后释放）
- 真实地址映射（`0x0048_xxxx`/`0x0049_xxxx`），SINGLE + burst（NONSEQ/SEQ 流水），非对齐传输按 AHB 规范报两拍 ERROR
- 集成 BFM（`src/tb/scr1_tcm_sbr_bfm.sv`）：复位写 + 读回校验 + INCR burst + 非对齐 + 运行时 mailbox（核心轮询中写入）；`+tcm_sbr_load=<image.hex>` 复位期整镜像加载模式（测试名含 `tcm_sbr` 时自动启用，其余测试零干扰）
- 独立协议压测台 `tools/tb/tb_scr1_tcm.sv`：**311 事务 0 错误**（`tools/run_tcm_tb_msim.sh`）
- 测试 `sim/tests/tcm_sbr/`：AXI 总线回归 PASS

## 7. 外部 halt/resume 控制（SCR1_DBG_EN）

新增 `ext_halt_req` / `ext_resume_req` 电平输入（异步，HDU 内 **2FF 同步**到 core clk）：

- 注入 `hart_halt_req` / `dm_run_req` / `hart_resume_req` 三点；halt FSM 不受 `clk_en`（DM active）门控——**无需 debug 会话即可 halt**
- halt 窗口核心零总线访问 → 与 §6 的 TCM 加载天然配合：halt → 加载 → `cpu_rst_n` 脉冲重启（`+ext_halt_test` 场景验证 PASS，核心从复位向量正常重跑）
- 已知限制：无 DM 会话的 **resume 路径不工作**（原 EXU 恢复握手假设 DM active，深挖记录见提交历史）——推荐 halt+cpu_rst 流程

## 8. IPIC 128 线中断

`SCR1_IRQ_VECT_NUM = 128`（原 16，必须 2 的幂，全位宽参数化）：

- 新增 `scr1_search_one_vect` 分段优先编码器：128 线按 16 线/段复用原 4 级树，**低段优先**保持低线号高优先级语义（原实现只支持 16 线，直接扩参会导致 16..127 线永远选不上）
- 修复结构体字段宽度拼接坑：`seg.idx[3:0]` 显式切片（否则段号被宽度转换截断，编码器只返回段内索引）
- IPR 读/写清除按 `min(VECT_NUM, XLEN)` localparam 归一（静态安全，无越界切片）
- 定向验证（force 注入）：bit100/127 前级 IPR 置位 ✓、编码器输出 100/127/40/多线取最低 ✓；isr_sample 回归 PASS
- **接口注意**：`irq_lines` 端口现为 128 位，按 16 路连接的既有 SoC 需同步改接线

## 9. 协议正确性修复包（2026-10-22/23）

经外部 lint 审查逐条验证（全部属实）后修复：

| 修复 | 内容 |
|---|---|
| TCM bank 归属锁存 | `scr1_tcm.sv` 在 `req & req_ack` 拍锁存六路 `_sel_r`，merge 全用锁存值；两个 router 删除 NOTRDY **restart 重驱动**（对已 ack 请求的握手违规，换有状态从机即多出一笔事务） |
| `mcfg_cbase` 死配置 | `post_base <= cbase_ff`——C 基址真正由配置指令生效（原写不读，实际取自 stc 操作数） |
| MTX 错误码 | 后台 posted 写错误报 `ST_ACCESS_FAULT`（原统一报 LD） |
| EXU CFU 异常路径 | `cfu_rdy = ~resp_exc & (resp_valid \| cfu_timeout)`——异常不再被超时强放丢弃 |
| msk 保留编码 | 仅接受 `rs1[1]==0`（原 `2'b10` 被静默接受且无功能） |
| 装饰参数 | 删除从未引用的 `MAX_OUTSTANDING` / `MAC_PARALLEL` |
| monitor | 新增 `p_forward_progress`（2048 拍响应窗口，捕获 CFU 死锁） |

## 10. 工具链适配

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
src/top/scr1_tcm_ahb_sbr.sv              # TCM AHB subordinate 桥
src/tb/scr1_tcm_sbr_bfm.sv               # 外部 master BFM（集成场景）
src/tb/scr1_ext_halt_tb.sv               # halt/resume 场景
sim/tests/{bitmanip,cvxif,mtx,tcm_sbr}/  # 测试
tools/                                   # 工具链脚本
docs/cvxif_cfu_isa.md                    # 自定义指令 ISA 文档
docs/DIFF_REPORT_vs_rtl_2026-10-22.html  # 与 rtl 参考实现的交互式差异报告
```

# 当前验证状态与已知限制

**已验证（QuestaSim 2024.1）**：AXI 总线回归 hello / bitmanip / isr_sample(128 线) / tcm_sbr 全 PASS；TCM 协议压测台 311 事务 0 错误；`+tcm_sbr_load` 镜像加载模式 PASS；`+ext_halt_test` halt→重启流程 PASS；IPIC 高线号 force 注入定向验证通过；双总线双配置编译 0 错误。

**已知限制**（均与上述新功能无关的既有问题，详见 `docs/DIFF_REPORT_vs_rtl_2026-10-22.html`）：

1. AHB 总线 testbench 存在预存 X 传播问题（上游基线 hello 即 TIMEOUT；AHB 顶层 RTL 本身编译 0 错误）——AHB 场景建议先修 tb
2. cvxif / mtx 测试在 AXI 配置存在既有 IFU 取指错位（`mepc` 落在 32 位指令中间）：与旧版 PASS 记录的 hex **MD5 相同**、纯净基线可复现，属上游/历史遗留，待专项修复
3. 无 DM 会话的外部 resume 不工作（见 §7），推荐 halt + `cpu_rst_n` 重启流程

# 许可

继承上游 SHL 许可（见 [LICENSE](./LICENSE)），允许 unrestricted 商用。
