# ALU 设计

## ALU 在哪里

当前没有单独的 `alu.vhd`。

ALU 逻辑写在：

```text
rtl/mcu4_worker_core.vhd
```

主要位置：

```text
S_RUN 状态
```

## ALU 输入

| 信号 | 含义 |
| --- | --- |
| `exec_op` | 当前要执行的操作 |
| `exec_rd` | 目的寄存器编号 |
| `exec_rn_data` | `rn` 的值 |
| `exec_rm_data` | `rm` 的值 |
| `exec_rd_data` | `rd` 的旧值，主要给 `STR` 用 |
| `exec_imm` | 立即数 |

## ALU 输出

| 信号 | 含义 |
| --- | --- |
| `wb_valid` | 是否写回寄存器 |
| `wb_rd` | 写回哪个寄存器 |
| `wb_data` | 写回数据 |
| `branch_taken` | 是否跳转 |
| `branch_target` | 跳转目标 |
| `dmem_*` | 访存写口控制 |
| `start_dsp` | 是否进入 DSP 多周期路径 |

## 普通整数运算

| 指令 | 运算 |
| --- | --- |
| `MOV_IMM` | `rd = imm` |
| `MOV_REG` | `rd = rm` |
| `ADD` | `rd = rn + rm` |
| `SUB` | `rd = rn - rm` |
| `AND` | `rd = rn and rm` |
| `ORR` | `rd = rn or rm` |
| `ASR` | `rd = signed(rn) >>> imm` |

## 访存指令

| 指令 | ALU 做什么 |
| --- | --- |
| `LDR_BANK0` | 选择 bank0 读数据，写回 `rd` |
| `LDR_BANK1` | 选择 bank1 读数据，写回 `rd` |
| `STR_BANK0` | 输出 bank0 写使能、写地址、写数据 |
| `STR_BANK1` | 输出 bank1 写使能、写地址、写数据 |

地址不是在 ALU 里动态加出来的。

地址在译码阶段已经变成：

```text
bank + idx
```

## SIMD 运算

| 指令 | 运算对象 | 效果 |
| --- | --- | --- |
| `SADD16` | 两个 16-bit lane | 两路同时加 |
| `SSUB16` | 两个 16-bit lane | 两路同时减 |
| `SSAX` | 两个 16-bit lane | 一路加，一路减 |
| `PKHBT` | 两个 halfword | 拼成一个 32-bit word |

## DSP 运算

| 指令 | 路径 |
| --- | --- |
| `SMUAD` | 进入 DSP 多周期路径，两个 16-bit 乘积相加 |
| `SMUSD` | 进入 DSP 多周期路径，两个 16-bit 乘积相减 |

v3 版本中，两个 16-bit 乘法不是直接写成 `signed(a) * signed(b)`。

乘法被拆成：

```text
mul_s16_stage1：生成部分积，并用 CSA 压缩
mul_s16_stage2：继续压缩，得到 32-bit signed 乘积
```

DSP 相关状态：

```text
S_DSP_MUL
S_DSP_ACC
S_DSP_WB
S_DSP_PAIR_MUL_ACC
S_DSP_PAIR_WB_ACC
S_DSP_PAIR_WB
```

## 分支运算

| 指令 | 效果 |
| --- | --- |
| `B` | `pc = branch_target` |
| `BL` | `lr = (pc + 1) * 4`，然后跳转 |
| `MOV pc, lr` | 返回到 `lr` 指向的位置 |

## 标志位

当前没有实现真正的条件标志。

```text
flag_z_debug = 0
flag_n_debug = 0
```

所以当前也没有：

```text
BEQ
BNE
BMI
BPL
```

## 一句话答辩说法

```text
本设计没有把 ALU 拆成独立文件，而是把普通整数 ALU、SIMD ALU、访存控制、分支控制和 SMUAD/SMUSD 的两级乘法执行路径集中写在 worker 里。
```
