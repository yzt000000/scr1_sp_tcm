# SCR1 CV-X-IF CFU 指令编码定义

## 概述

本文档定义了 SCR1 CV-X-IF 参考实现（`scr1_pipe_cfu.sv`）中支持的 custom 指令编码。

所有指令使用 RISC-V custom-0 opcode 空间（bits[6:2] = `00010`，bits[1:0] = `11`，完整 opcode = `0x0b`）。

## 指令格式

所有参考 CFU 指令均为 R-type 格式：

```
 31     25 24   20 19   15 14  12 11    7 6     2 1  0
+---------+-------+-------+------+-------+-------+----+
| funct7  |  rs2  |  rs1  |funct3|  rd   |opcode | 11 |
+---------+-------+-------+------+-------+-------+----+
```

- opcode = `0001011` (0x0b, custom-0)
- funct7 = `0000000` (0x00)
- funct3 选择具体操作

## 指令列表

| 助记符 | funct3 | 语义 | 汇编编码 |
|--------|--------|------|---------|
| cfu_add | 000 | rd = rs1 + rs2 | `.insn r 0x0b, 0x0, 0x0, rd, rs1, rs2` |
| cfu_xor | 001 | rd = rs1 ^ rs2 | `.insn r 0x0b, 0x1, 0x0, rd, rs1, rs2` |
| cfu_sub | 010 | rd = rs1 - rs2 | `.insn r 0x0b, 0x2, 0x0, rd, rs1, rs2` |
| cfu_and | 011 | rd = rs1 & rs2 | `.insn r 0x0b, 0x3, 0x0, rd, rs1, rs2` |
| cfu_or  | 100 | rd = rs1 \| rs2 | `.insn r 0x0b, 0x4, 0x0, rd, rs1, rs2` |
| cfu_sll | 101 | rd = rs1 << rs2[4:0] | `.insn r 0x0b, 0x5, 0x0, rd, rs1, rs2` |
| cfu_srl | 110 | rd = rs1 >> rs2[4:0] | `.insn r 0x0b, 0x6, 0x0, rd, rs1, rs2` |
| cfu_mul | 111 | rd = (rs1 * rs2)[31:0] | `.insn r 0x0b, 0x7, 0x0, rd, rs1, rs2` |

## 非法指令

以下编码触发非法指令异常（mcause=2）：
- custom-1/2/3 opcode 空间的任何编码
- custom-0 空间中 funct7 != 0 的任何编码
- custom-0 空间中 funct3 > 7 的任何编码（不可能，funct3 为 3 位）

## C 内联汇编示例

```c
static inline int cfu_add(int a, int b) {
    int result;
    asm volatile(".insn r 0x0b, 0x0, 0x0, %0, %1, %2"
                 : "=r"(result) : "r"(a), "r"(b));
    return result;
}

static inline int cfu_xor(int a, int b) {
    int result;
    asm volatile(".insn r 0x0b, 0x1, 0x0, %0, %1, %2"
                 : "=r"(result) : "r"(a), "r"(b));
    return result;
}
```

## 工具链配置

编译时需使用 `-march=rv32imc_xcustom` 选项。shim 会自动追加 `_zicsr_zifencei`。

## CFU 替换流程

集成者可替换 `scr1_pipe_cfu.sv` 为自定义 CFU 实现：
1. 保持模块端口接口不变（`type_scr1_cvxif_req_s` / `type_scr1_cvxif_resp_s`）
2. 在 `scr1_core_top` 实例化处替换 CFU 模块
3. 核心 RTL 无需修改（零侵入保证）
4. 更新本文档以反映新的指令编码定义

## CFU 模式选择

通过 `MAX_LATENCY` 参数选择 CFU 模式：
- `MAX_LATENCY = 0`：stub 模式，所有 custom 指令触发非法异常
- `MAX_LATENCY = 1`：单周期组合逻辑 CFU
- `MAX_LATENCY > 1`：多周期 CFU，占用 N 个周期完成计算
---

# Custom-1 空间：矩阵乘法加速指令（MTX 扩展）

> 需要 `SCR1_RVX_EXT` + `SCR1_MTX_EXT` 宏同时开启。CFU 实现为 `scr1_pipe_cfu_mtx`。

## 概述

MTX 扩展在 custom-1 opcode 空间（opcode = `0101011` = 0x2b）定义 4×4 块矩阵乘法指令，配合 CFU 内部 DMA 引擎与 MAC 阵列，实现 C = A × B 的一次性加速计算。A/B/C 均驻留于数据存储器（DTCM 或外部 memory），CFU 通过 dmem master 接口（经 `scr1_dmem_arbiter` 仲裁）自主搬运数据。

## 指令列表

所有指令为 R-type，opcode = 0x2b：

| 助记符 | funct7 | funct3 | 语义 | 汇编编码 |
|--------|--------|--------|------|---------|
| cfu.matmul4  | 0000000 | 000 | C=A×B, 4×4 int32 | `.insn r 0x2b, 0x0, 0x0, rd, rs1, rs2` |
| cfu.matmul4h | 0000000 | 001 | 4×4 int16, 累加32位 | `.insn r 0x2b, 0x1, 0x0, rd, rs1, rs2` |
| cfu.matmul4b | 0000000 | 010 | 4×4 int8, 累加32位 | `.insn r 0x2b, 0x2, 0x0, rd, rs1, rs2` |
| cfu.mcfg_stride | 0000001 | 000 | stride ← rs1 | `.insn r 0x2b, 0x0, 0x1, x0, rs1, x0` |
| cfu.mcfg_msk    | 0000010 | 000 | 符号模式 ← rs1[0] | `.insn r 0x2b, 0x0, 0x2, x0, rs1, x0` |
| cfu.mcfg_cbase  | 0000011 | 000 | C 基地址 ← rs1 | `.insn r 0x2b, 0x0, 0x3, x0, rs1, x0` |

## 操作数

- `cfu.matmul4 rd, rs1, rs2`：rs1 = A 矩阵基地址，rs2 = B 矩阵基地址，rd = 状态码（0=成功，非0=错误），C 基地址由 `cfu.mcfg_cbase` 预先配置
- `cfu.mcfg_stride rs1`：设置行步长（元素为单位，紧凑排列 stride=4），rs1 范围 1~255（256 及以上被拒绝：rs1[31:8] != 0 即非法）
- `cfu.mcfg_msk rs1`：rs1[0]=符号位（0=无符号, 1=有符号）；rs1[1] 为保留编码，必须为 0（无饱和模式）
- `cfu.mcfg_cbase rs1`：设置后续 stc 写回的 C 矩阵基地址（posted 写队列的基址取自该配置；`cfu.stc` 的 rs1 操作数被忽略）

## 地址序列

对于 4×4 矩阵 M，基地址 `base`，行步长 `stride`，元素宽度 `esz`（字节）：

```
M[i][j] 地址 = base + (i * stride + j) * esz,   i,j ∈ [0,3]
```

- int32: esz=4, int16: esz=2, int8: esz=1
- 结果 C 始终以 word（32位）写回

## 非法指令

- custom-1 空间中未定义的 funct7/funct3 组合
- `cfu.mcfg_stride` 中 rs1 = 0 或 rs1 > 255
- `cfu.mcfg_msk` 中 rs1[1] = 1（保留编码）

## CFU 内部架构

- **DMA 引擎**：地址生成器 + dmem master 接口 + 读数据缓冲，串行单 outstanding
- **MAC 阵列**：16 个累加器，串行计算 C[i][j] = Σ_k A[i][k]·B[k][j]
- **控制 FSM**：IDLE → LD_A → LD_B → COMP → ST_C → DONE

## DMEM 仲裁器

`scr1_dmem_arbiter` 在 LSU（m0）与 CFU（m1）之间轮转公平仲裁，输出单一 dmem master 接口至 `scr1_dmem_router`。未开启 `SCR1_MTX_EXT` 时退化为 LSU 直连。