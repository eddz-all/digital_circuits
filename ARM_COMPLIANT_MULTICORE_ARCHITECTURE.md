# ARM-Compliant Four-Core MCU Architecture Plan

本文档描述下一版更符合老师要求的四核多周期 MCU 架构。核心思想是：

```text
不再使用 butterfly 黑盒加速器；
改为四个并行 ARM 指令执行核；
FFT butterfly 由 ARM/ARM DSP 指令序列组合完成。
```

## 1. 约束与设计目标

根据老师反馈，需要满足：

- 外部 `test_ROM` 到 MCU 内部内存、MCU 内部结果到 `verify_RAM`，可以由测试平台/外层控制器完成，不需要指令逐条搬运。
- `cnt` 从指令存储器第一条指令读取开始，到指令存储器最后一条指令执行完成结束。
- 硬件加速器可以更复杂，但必须是 ARM 指令集支持范围内的执行单元。
- 因此，`MUL/MLA/SMLAD/SMLSD/SADD16/SSUB16/SSAX/PKHBT/SSAT` 等 ARM 支持的执行单元可以做；一次性完成 FFT butterfly 的黑盒不合适。

最终目标：

```text
四核并行 + 多周期高频 + ARM 指令集内执行 + 明确可解释的内存结构。
```

## 2. 顶层数据流

外层系统仍负责适配实验平台：

```text
test_ROM[128..143]
  -> 外层输入控制器
  -> MCU 内部工作内存 buf_a/buf_b
  -> 四个 ARM worker core 执行 FFT 指令序列
  -> MCU 内部工作内存 buf_b
  -> 外层输出控制器
  -> verify_RAM[0..15]
```

输入加载和结果输出不计入 `cnt`。`cnt` 只统计指令执行阶段。

## 3. 整体架构

推荐架构：

```text
                 +-------------------------+
                 |   instruction ROM       |
                 |  logical one program    |
                 +-----------+-------------+
                             |
             +---------------+---------------+
             |               |               |
        +----v----+     +----v----+     +----v----+     +----v----+
        | core 0  |     | core 1  |     | core 2  |     | core 3  |
        +----+----+     +----+----+     +----+----+     +----+----+
             |               |               |               |
             +---------------+---------------+---------------+
                             |
                 +-----------v-------------+
                 | multi-port work memory |
                 |      buf_a / buf_b     |
                 +-------------------------+
```

四个 core 是真正执行 ARM 指令的小核，而不是 butterfly 计算黑盒。

## 4. 每个 Core 的基本部件

每个 worker core 包含：

```text
PC
IR 指令寄存器
decoder 译码器
register file，r0-r15
ALU
DSP/乘法执行单元
load/store 单元
flag/status
多周期控制 FSM
```

支持的指令至少包括：

```text
ADD, SUB, AND, ORR, MOV, CMP
LDR, STR
B, BL, MOV pc, lr
```

为了 FFT 性能，建议再支持 ARM/ARM DSP 范围内的指令：

```text
MUL / MLA
SMLAD / SMLSD
SADD16 / SSUB16 / SSAX
PKHBT / ASR / SSAT
```

这些指令可以是多周期执行。例如乘法类指令拆成乘法寄存、加减、写回若干周期，以换取更高频率。

## 5. 指令存储器与多核关系

建议口径：

```text
逻辑上一份 instruction ROM；
硬件上为了四核同时取指，可以复制成四份只读 ROM，或实现为多读口 ROM。
```

每个 core 有自己的 `PC`，可以从 ROM 的不同入口取指。程序布局可以是：

```text
core0_stage0_entry
core1_stage0_entry
core2_stage0_entry
core3_stage0_entry

core0_stage1_entry
...
```

也可以四个 core 使用相似程序模板，但推荐先采用 lane-specific 程序入口，减少运行时地址计算，性能更高，解释也简单。

## 6. 数据内存设计

不再保留单独且几乎不用的传统 `data_mem`。MCU 的 FFT 数据内存定义为：

```text
buf_a[0..7]
buf_b[0..7]
```

每个元素是一个 32-bit 复数：

```text
word[15:0]   = real
word[31:16]  = imag
```

这个内存有两个访问身份：

```text
对 MCU 指令：
  LDR/STR 可以单口访问某一个 word。

对四个 core/worker：
  多端口并行访问，支持同一个 stage 内四个 butterfly 同时读写。
```

推荐地址映射：

```text
0x0000..0x003F  控制/同步寄存器
0x0040..0x005C  buf_a[0..7]
0x0080..0x009C  buf_b[0..7]
```

示例：

```asm
LDR r2, [r0, #64]     ; read buf_a[0]
STR r3, [r0, #128]    ; write buf_b[0]
```

这里 `buf_a/buf_b` 不是隐藏缓存，而是 MCU 的工作数据内存。它用寄存器阵列实现，因此可以提供多读多写带宽。

## 7. 同步机制

每个 FFT stage 需要保证四个 core 都完成后再进入下一 stage。推荐用 ARM `LDR/STR` 访问同步寄存器：

```text
barrier_done_mask
barrier_clear
```

示意指令：

```asm
STR r_core_bit, [sync_base, #done]   ; 标记本 core 完成
wait:
LDR r5, [sync_base, #mask]           ; 读取四核完成状态
CMP r5, #15
BNE wait
```

这样同步过程仍然由 ARM 指令完成，而不是隐藏硬件自动跳 stage。

## 8. FFT 算法拆分

输入是 8 点复数 FFT：

```text
16 个 16-bit 输入 = 8 个 real + 8 个 imag
外层输入控制器打包成 8 个 32-bit complex word
并按 bit-reversal 顺序写入 buf_a
```

使用 radix-2 DIT FFT，三层 stage：

```text
stage0: (0,1), (2,3), (4,5), (6,7), W0
stage1: (0,2), (1,3), (4,6), (5,7), W0/W2
stage2: (0,4), (1,5), (2,6), (3,7), W0/W1/W2/W3
```

ping-pong 工作内存：

```text
stage0: buf_a -> buf_b
stage1: buf_b -> buf_a
stage2: buf_a -> buf_b
```

最终 `buf_b` 中保存 FFT 输出，外层控制器再写入 `verify_RAM`。

## 9. Butterfly 的 ARM 指令拆法

### W0 Butterfly

W0 不需要乘法：

```asm
LDR    r2, [mem, #a]
LDR    r3, [mem, #b]
SADD16 r4, r2, r3       ; even = a + b
SSUB16 r5, r2, r3       ; odd  = a - b
STR    r4, [mem, #even]
STR    r5, [mem, #odd]
```

### W2 Butterfly

W2 可用半字交换加减实现乘以 `-j`：

```asm
LDR    r2, [mem, #a]
LDR    r3, [mem, #b]
SSAX   r4, r_zero, r3   ; t = -j * b
SADD16 r5, r2, r4
SSUB16 r6, r2, r4
STR    r5, [mem, #even]
STR    r6, [mem, #odd]
```

### W1/W3 Butterfly

W1/W3 需要复数乘法，可以用 ARM DSP 类指令组合：

```text
t_real = (b_real * w_real - b_imag * w_imag) >> scale
t_imag = (b_real * w_imag + b_imag * w_real) >> scale
```

可使用：

```text
SMLAD / SMLSD  计算双 16-bit 乘加/乘减
ASR            缩放
PKHBT          打包 real/imag
SADD16         even = a + t
SSUB16         odd  = a - t
STR            写回
```

这样 butterfly 是由多条 ARM 指令完成，不是由非 ARM 的 butterfly 指令或黑盒完成。

## 10. 多周期执行

架构继续采用多周期，而不是单周期：

```text
取指       1 cycle
译码/读寄存器 1 cycle
简单 ALU    1 cycle
LDR/STR     1 cycle 或 2 cycle
DSP 乘法类   多 cycle
写回       1 cycle
```

好处：

- 更容易跑高频，例如 200 MHz 左右。
- 复杂 DSP 指令不会拖慢所有简单指令。
- 与老师要求的 ARM 指令执行粒度更一致。

## 11. 计数方式

按照老师要求：

```text
cnt_start:
  第一个 core 从 instruction ROM 读取第一条指令时。

cnt_stop:
  最后一条指令执行完成时。
```

外层输入加载和外层输出写 `verify_RAM` 不计入 `cnt`。

如果四个 core 并行执行，推荐：

```text
cnt_start = release_cores_fetch_first_instruction
cnt_stop  = all_cores_halted
```

## 12. 预期性能方向

旧版 butterfly 黑盒计数很低，但不符合老师对 ARM 指令粒度的要求。当前版本已改为四个 worker core 并行执行 ARM/ARM-DSP 风格指令序列，避免一次性完成 butterfly 的专用硬件路径。

性能关键点：

- stage 内四个 butterfly 并行。
- W0/W2 用少量 packed DSP 指令完成。
- W1/W3 用 ARM DSP 指令组合完成，不用完整 butterfly 黑盒。
- 工作内存多端口，避免单口 RAM 卡住四核并行。

当前 GHDL 结果：

```text
mcu_fft_system_tb cnt_cycles = 22
```

该版本给 worker 加入取指/译码寄存，并把 `SMUAD/SMUSD` 拆成多周期 DSP 执行。独立连续 DSP 指令使用局部 pair pipeline，后续常见 `ASR` 可以和第二个 DSP 写回同拍退休，并且该 `ASR` 结果会提前一拍预计算后寄存。安全相邻的 `MOV/MOV`、`LDR/LDR`、`STR/STR` 和 `SADD16/SSUB16` 也可以局部双发射同拍退休。`STR/STR` 第二写口的数据来自译码级操作数寄存器，而不是直接来自寄存器堆组合读路径；局部双发射资格也提前寄存为 pair-kind 控制位，减少执行周期内的比较逻辑。若能保持 216 MHz 以上频率，最终 `cnt × period` 仍有竞争力，并且合规性明显强于 butterfly 加速器版本。

## 13. 当前实现状态

当前实现已经完成以下重构：

1. 保留 `board_top` 和 `mcu_fft_system` 的输入输出框架。
2. `mcu4_multicycle_core` 保持对外接口不变，内部改为四个 worker core 并行。
3. 新建 worker 指令 ROM、decoder 和 core 模块：

```text
rtl/mcu4_worker_instr_rom.vhd
rtl/mcu4_worker_decoder.vhd
rtl/mcu4_worker_core.vhd
```

4. 共享 `buf_a/buf_b` 多端口工作内存在 `mcu4_multicycle_core` 内保留。
5. 每个 worker 从自己的 lane-specific 32-bit 指令 ROM 取指，经 decoder 译码后执行 FFT stage。
6. `cnt_stop` 由 `all_workers_halted` 产生，不等待输出 dump。
7. Worker core 已补足课程最低 ARM 风格操作：`ADD/SUB/AND/ORR/MOV/LDR/STR/B/BL`。
8. GHDL 已验证最低指令自测、FFT 输出和计数。

## 14. 答辩口径

推荐表述：

> 我们采用四核多周期 ARM 指令执行结构。每个 core 都有 PC、32 位指令 ROM、译码器、寄存器组、ALU 和 ARM DSP 指令执行单元。FFT 数据存储在多端口工作内存 `buf_a/buf_b` 中，普通 ARM `LDR/STR` 可以单口访问该内存，四个 core 也可以并行访问。FFT butterfly 不是由硬件黑盒一次完成，而是由 ARM 指令集支持的 `SADD16/SSUB16/SMLAD/SMLSD/PKHBT` 等指令序列完成。多核并行体现在四个 core 同时执行不同 butterfly 的 ARM 指令序列。
