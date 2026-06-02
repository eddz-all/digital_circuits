# MCU V1 单周期 Core 说明

本文档对应当前最小可运行 MCU baseline，以及 `dsp` 分支新增的 packed DSP 加速验证。

## 1. 文件列表

RTL：

```text
rtl/mcu_v1_pkg.vhd
rtl/mcu_v1_alu.vhd
rtl/mcu_v1_regfile.vhd
rtl/mcu_v1_instr_rom.vhd
rtl/mcu_v1_input_mem.vhd
rtl/mcu_v1_work_ram.vhd
rtl/mcu_v1_output_mem.vhd
rtl/mcu_v1_data_mem.vhd
rtl/mcu_v1_pc_unit.vhd
rtl/mcu_v1_decoder.vhd
rtl/mcu_v1_core.vhd
```

Testbench：

```text
tb/mcu_v1_alu_tb.vhd
tb/mcu_v1_decoder_tb.vhd
tb/mcu_v1_core_tb.vhd
```

测试程序：

```text
asm/test_mcu_v1_basic.s
asm/test_mcu_v1_basic.mem
asm/test_mcu_v1_basic.lst
asm/fft8_v1_mcu32_basic.mem
asm/fft8_v2_packed_dsp.s
asm/fft8_v2_packed_dsp.mem
asm/fft8_v2_packed_dsp.lst
tools/test_fft8_v2_packed_dsp.py
docs/fft8_experiment_results.md
```

## 2. 当前 Core 结构

当前 `mcu_v1_core.vhd` 是最小单周期 baseline：

```text
PC register
  -> instr_rom, 组合读
  -> decoder
  -> regfile, 组合读、同步写
  -> ALU
  -> data_mem, 组合读、同步写
  -> writeback mux
  -> pc_unit
```

一条指令在一个时钟周期内完成：

```text
取指 -> 译码 -> 读寄存器 -> ALU -> 访存/写回 -> PC 更新
```

## 2.1 模块划分

为便于讲解，当前 RTL 按功能拆成以下模块：

```text
mcu_v1_pkg        公共常量：ALU 控制码、opcode、条件码、地址区域码
mcu_v1_decoder    指令译码和控制信号
mcu_v1_regfile    16 个 32-bit 寄存器，组合读、同步写
mcu_v1_alu        AND / ORR / ADD / SUB / MUL / ASR / MOV，以及 packed DSP 操作
mcu_v1_instr_rom  指令 ROM，按 PC[31:2] 组合读 .mem
mcu_v1_pc_unit    顺序 PC+4、分支 PC+8+offset、自循环 halt 检测
mcu_v1_data_mem   数据地址区路由器
mcu_v1_input_mem  输入区，模拟 test_ROM，16-bit signed 读出符号扩展
mcu_v1_work_ram   工作区，内部 32-bit RAM
mcu_v1_output_mem 输出区，模拟 verify_RAM，保存 16-bit 结果
mcu_v1_core       顶层，把以上模块连接成单周期 MCU
```

讲解时可以按这条主线：

```text
指令怎么来 -> decoder 怎么切字段 -> regfile/ALU 怎么执行
-> data_mem 怎么按地址选输入/工作/输出区 -> pc_unit 怎么更新 PC
```

## 3. 支持能力

支持第一版要求的指令：

```text
MOV
ADD
SUB
AND
ORR
CMP
LDR
STR
B
BL
BEQ
BNE
MUL
ASR
```

`dsp` 分支额外支持 packed DSP 扩展指令：

```text
SHADD16
SHSUB16
SMUAD
SMUSD
SXTH
PKHBT
```

地址空间：

```text
INPUT_BASE   = 0x000
WORK_BASE    = 0x100
OUTPUT_BASE  = 0x200
```

程序视角：

```text
输入区、工作区、输出区统一按 32-bit 槽位访问
槽位步长统一 +4
```

数据存储器行为：

```text
输入区 LDR：16-bit signed -> 32-bit signed
工作区 LDR/STR：32-bit
输出区 STR：保存 write_data[15:0]，模拟外部 16-bit verify_RAM
```

## 4. 分支与停机

分支按最新版格式：

```text
pc_next = branch_taken ? PC + 8 + branch_offset : PC + 4
branch_offset = sign_extend(imm24) << 2
```

当前没有真正 halt 指令。程序用：

```asm
DONE:
    B DONE
```

`BL` 用于满足 PPT 最低指令集仿真要求。当前语义：

```text
pc_next = PC + 8 + branch_offset
R14     = PC + 4
```

当前没有 `BX`，所以 `BL` 只验证 link register 写入和分支行为，不作为函数调用/返回机制使用。

core 输出：

```text
halted_debug = 1
```

条件是：

```text
branch_taken = 1 且 pc_next = pc_reg
```

当前 FFT 程序的 `DONE`：

```text
PC = 0x0474
instr = 0xE8FFFFFE
branch_offset = -8
PC + 8 - 8 = PC
```

## 5. 本地仿真

运行：

```bash
ghdl -a --std=08 \
  rtl/mcu_v1_pkg.vhd \
  rtl/mcu_v1_decoder.vhd \
  rtl/mcu_v1_alu.vhd \
  rtl/mcu_v1_regfile.vhd \
  rtl/mcu_v1_instr_rom.vhd \
  rtl/mcu_v1_input_mem.vhd \
  rtl/mcu_v1_work_ram.vhd \
  rtl/mcu_v1_output_mem.vhd \
  rtl/mcu_v1_data_mem.vhd \
  rtl/mcu_v1_pc_unit.vhd \
  rtl/mcu_v1_core.vhd \
  tb/mcu_v1_alu_tb.vhd \
  tb/mcu_v1_decoder_tb.vhd \
  tb/mcu_v1_core_tb.vhd

ghdl -e --std=08 mcu_v1_alu_tb
ghdl -r --std=08 mcu_v1_alu_tb

ghdl -e --std=08 mcu_v1_decoder_tb
ghdl -r --std=08 mcu_v1_decoder_tb

ghdl -e --std=08 mcu_v1_core_tb
ghdl -r --std=08 mcu_v1_core_tb
```

当前通过结果：

```text
mcu_v1_alu_tb passed
mcu_v1_decoder_tb passed
mcu_v1_core_tb passed
```

GHDL 在 core 仿真 0ns 处可能打印少量 `NUMERIC_STD.TO_INTEGER: metavalue detected` warning，这是初始 delta-cycle 中组合信号尚未稳定造成的提示；后续断言和最终结果均通过。

## 6. Core Testbench 覆盖

`tb/mcu_v1_core_tb.vhd` 包含三个 core 实例：

```text
basic_core  加载基础指令小程序
fft_core    加载 V1 scalar FFT
fast_core   加载 V2 packed DSP FFT
```

### 6.1 基础小程序

加载：

```text
asm/test_mcu_v1_basic.mem
```

输入：

```text
slot 0 = 1000
slot 1 = -500
```

检查输出：

```text
slot 0 = 500
slot 1 = 1500
slot 2 = 707
slot 3 = 123
slot 4 = 8
slot 5 = 11
slot 6 = 0x0074
slot 7 = 0
```

覆盖：

```text
MOV / ADD / SUB / AND / ORR / LDR / STR / MUL / ASR / CMP / BEQ / B / BL
```

### 6.2 V1 scalar FFT 冲激程序

加载：

```text
asm/fft8_v1_mcu32_basic.mem
```

输入：

```text
x0.real = 32760
其余 real/imag = 0
```

检查输出：

```text
8 个复数输出均为 real = 4095, imag = 0
```

并检查：

```text
PC 停在 0x0474
halted_debug = 1
illegal_debug = 0
```

GHDL 仿真数据按输出槽位展开：

```text
x0 impulse:
PC = 0x0474
halted_debug = 1
illegal_debug = 0
slot  0 = 4095
slot  1 = 0
slot  2 = 4095
slot  3 = 0
slot  4 = 4095
slot  5 = 0
slot  6 = 4095
slot  7 = 0
slot  8 = 4095
slot  9 = 0
slot 10 = 4095
slot 11 = 0
slot 12 = 4095
slot 13 = 0
slot 14 = 4095
slot 15 = 0

x1 impulse:
PC = 0x0474
halted_debug = 1
illegal_debug = 0
slot  0 =  4095
slot  1 =     0
slot  2 = -4095
slot  3 =     0
slot  4 =     0
slot  5 = -4095
slot  6 =     0
slot  7 =  4095
slot  8 =  2895
slot  9 = -2896
slot 10 = -2896
slot 11 =  2896
slot 12 = -2896
slot 13 = -2896
slot 14 =  2896
slot 15 =  2895
```

### 6.3 V2 packed DSP 加速程序

加载：

```text
asm/fft8_v2_packed_dsp.mem
```

当前规模：

```text
120 条指令
109 条 timed steps
DONE PC = 0x01DC
```

覆盖：

```text
SHADD16 / SHSUB16 / SMUAD / SMUSD / SXTH / PKHBT
```

GHDL core test 当前检查两组输入：

```text
x0.real = 32760，其余为 0
  -> 8 个输出均为 real = 4095, imag = 0

x1.real = 32760，其余为 0
  -> bit-reversal 输出顺序 X0, X4, X2, X6, X1, X5, X3, X7
```

V2 GHDL 仿真数据：

```text
x0 impulse:
  PC = 0x01DC
  halted_debug = 1
  illegal_debug = 0
  slot  0 = 4095
  slot  1 = 0
  slot  2 = 4095
  slot  3 = 0
  slot  4 = 4095
  slot  5 = 0
  slot  6 = 4095
  slot  7 = 0
  slot  8 = 4095
  slot  9 = 0
  slot 10 = 4095
  slot 11 = 0
  slot 12 = 4095
  slot 13 = 0
  slot 14 = 4095
  slot 15 = 0

x1 impulse:
  PC = 0x01DC
  halted_debug = 1
  illegal_debug = 0
  slot  0 =  4095
  slot  1 =     0
  slot  2 = -4095
  slot  3 =     0
  slot  4 =     0
  slot  5 = -4095
  slot  6 =     0
  slot  7 =  4095
  slot  8 =  2895
  slot  9 = -2896
  slot 10 = -2896
  slot 11 =  2896
  slot 12 = -2896
  slot 13 = -2896
  slot 14 =  2896
  slot 15 =  2895
```

Python host checker 还会补充更完整的数值验证：

```bash
python3 tools/test_fft8_v2_packed_dsp.py
```

验证口径：

```text
中等幅度随机输入：V2 精确匹配 V1 scalar fixed model
完整 16-bit 随机输入：V2 精确匹配 packed DSP fixed model
```

完整 16-bit 情况采用 packed DSP model，是因为 halfword lane 中间值会按 16-bit 加速语义截断；V1 scalar baseline 仍保留为全 32-bit reference。

## 7. Vivado 注意事项

当前 baseline 使用组合读 `instr_rom` 和组合读 `data_mem`，适合先做功能仿真和小规模 distributed memory 综合。

如果 Vivado 把 ROM/RAM 推成同步 block RAM，则取指或 `LDR` 会天然多一拍，严格单周期结构需要调整为：

```text
多周期 MCU
或
显式 distributed ROM/RAM
或
提前取指/同步读适配
```

课程第一版建议先保留当前 baseline，先证明指令语义和 FFT 数据流正确，再根据综合/timing 结果决定是否改存储器结构。
