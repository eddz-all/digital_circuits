# MCU Generality Requirements

本文档给协同开发者说明本工程的设计边界：我们要做的是一个能够执行
ARM/ARM-DSP 风格指令的多核 MCU，当前 ROM 中恰好放入 FFT 程序；不能把
工程继续改回只服务某一套 FFT 指令序列的专用硬件。

## Core Principle

最终口径必须是：

```text
更换 ROM 指令后，core 仍按同一套取指、译码、寄存器堆、执行、访存流程运行。
FFT 是一套程序，不是隐藏在 RTL 里的专用数据通路。
```

当前推荐模式：

```text
PROGRAM_ID = 0, ACTIVE_CORES = 4  -- 四核 FFT 程序
PROGRAM_ID = 1, ACTIVE_CORES = 1  -- 基础指令/PPT 测试程序
```

以后新增排序、矩阵、滤波或其他测试程序时，应新增 ROM 程序模式，而不是在
执行单元里识别某个固定 FFT 流程。

## Required MCU Features

每个 worker core 必须保持通用 MCU 结构：

```text
PC
32-bit instruction ROM
instruction word / decode fields
register file r0-r15
ALU
load/store path
multi-cycle DSP path
halt / illegal state
```

至少保持这些基础指令可用：

```text
MOV, ADD, SUB, AND, ORR, LDR, STR, B, BL, MOV pc, lr
```

FFT 程序可以使用 ARM/ARM-DSP 范围内的指令：

```text
SADD16, SSUB16, SSAX, SMUAD, SMUSD, ASR, PKHBT
```

这些指令可以做多周期、流水、转发和双发射，但语义必须仍然是指令本身的语义。

## Instruction ROM Rules

指令必须显式存储在 ROM 中。当前权威来源是：

```text
rtl/mcu4_worker_instr_rom.vhd
```

其中：

```text
FFT_ROM_W0..FFT_ROM_W3  -- 四个 FFT worker 的 32-bit 指令 ROM
SELFTEST_ROM            -- 基础指令测试 ROM
```

要求：

- ROM 中应能直接看到 32-bit 指令字。
- 可读汇编清单放在 `asm/` 下用于讲解。
- 不要用 RTL 编码函数在综合时“生成”整套程序。
- `PROGRAM_ID` 只负责选择程序，不应该改变指令语义。
- `ACTIVE_CORES` 只负责选择启动几个 worker，不应该改变单个 core 的 ISA。

## Allowed Optimizations

允许做通用微架构优化，只要它们根据指令和依赖关系工作，而不是根据 FFT 的固定位置工作：

```text
fetch/decode/execute pipeline
ROM-local predecode fields
register-file replication
worker-local buffer read replicas
multi-cycle SMUAD/SMUSD
safe local dual issue
operand forwarding
decoded dependency based ASR/DSP overlap
```

例如，安全相邻的 `MOV/MOV`、`LDR/LDR`、`STR/STR`、`SADD16/SSUB16` 可以同拍退休；
但判断依据必须是 opcode、寄存器号、访存端口和依赖关系。

## Forbidden Shortcuts

以下做法会把工程拉回专用硬件，禁止加入：

```text
FFT-specific opcode
butterfly-specific opcode
fixed PC window fusion
按第几条指令识别 FFT stage
把 W0/W1/W2/W3 butterfly 写成隐藏组合逻辑
把 twiddle 常量藏进执行单元
让 LDR/STR 对 FFT 地址有特殊语义
让某几条 FFT 指令自动合并成不可见操作
为了降低 cnt 改变 cnt_start/cnt_stop 边界
```

如果一个优化在换成排序程序、基础指令测试程序或其他非 FFT 程序后会失效，通常就不该放入执行单元。

## Adding A New Program

新增程序建议按这个流程：

1. 在 `mcu4_worker_instr_rom.vhd` 中新增显式 ROM 常量，例如 `SORT_ROM`。
2. 扩展 `PROGRAM_ID` 范围和 ROM 选择逻辑。
3. 若是单核程序，使用 `ACTIVE_CORES=1`，让 core0 执行。
4. 在 `asm/` 下增加可读汇编清单。
5. 增加对应 testbench，验证输出、halt 和 illegal。
6. 保持 `SELFTEST_ROM` 和 FFT testbench 继续通过。

如果新程序需要当前 ISA 尚未支持的能力，例如 `CMP`、条件跳转或更通用地址计算，应扩展 ISA 和 decoder，
而不是为该程序写专用数据通路。

## Review Checklist

提交前至少检查：

```text
rg "ENABLE_FFT_WINDOW_FUSION|scheduled_pair_kind_for_pc|PC-scheduled|fft_.*window" rtl docs
```

这些关键词不应重新出现。还应确认：

- 基础指令模式 `PROGRAM_ID=1, ACTIVE_CORES=1` 仍能运行。
- FFT 模式 `PROGRAM_ID=0, ACTIVE_CORES=4` 仍能得到正确输出。
- `instr_debug` 仍表示真实 32-bit ROM 指令字。
- 文档中没有暗示 butterfly 黑盒或固定 FFT PC 识别。

推荐仿真：

```text
mcu4_worker_core_min_arm_tb
mcu4_multicycle_core_min_arm_tb
mcu4_multicycle_core_tb
mcu_fft_system_tb
board_top_tb
```

一句话总结：性能优化可以大胆做，但必须站在 MCU 微架构层面做；FFT 只能是 ROM 里的程序，不能变成 RTL 里的秘密捷径。
