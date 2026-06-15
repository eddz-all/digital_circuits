# MCU V1 单周期 Core 说明

本文档对应当前最小可运行 MCU baseline。

## 1. 文件列表

RTL：

```text
rtl/mcu_v1_alu.vhd
rtl/mcu_v1_regfile.vhd
rtl/mcu_v1_instr_rom.vhd
rtl/mcu_v1_data_mem.vhd
rtl/mcu_v1_decoder.vhd
rtl/mcu_v1_core.vhd
rtl/mcu_fft_system.vhd
```

Testbench：

```text
tb/mcu_v1_decoder_tb.vhd
tb/mcu_v1_core_tb.vhd
tb/mcu_fft_system_tb.vhd
```

测试程序：

```text
asm/test_mcu_v1_basic.s
asm/test_mcu_v1_basic.mem
asm/test_mcu_v1_basic.lst
asm/fft8_v1_mcu32_basic.mem
```

## 2. 当前 Core 结构

当前 `mcu_v1_core.vhd` 是最小单周期 baseline：

```text
PC
  -> instr_rom, 组合读
  -> decoder
  -> regfile, 组合读、同步写
  -> ALU
  -> data_mem, 组合读、同步写
  -> writeback mux
  -> PC update
```

一条指令在一个时钟周期内完成：

```text
取指 -> 译码 -> 读寄存器 -> ALU -> 访存/写回 -> PC 更新
```

## 3. 支持能力

支持第一版要求的指令：

```text
MOV
ADD
SUB
CMP
LDR
STR
B
BEQ
BNE
MUL
ASR
```

地址空间：

```text
输入区        = 0x000..0x23f, 对应老师 FFT_input.coe slot 0..143
WORK_BASE    = 0x400
OUTPUT_BASE  = 0x800, 对应老师 FFT_output.coe slot 0..15
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

core 外部装载接口：

```text
input_we    : reset 期间允许写 input_mem
input_waddr : 8-bit，可覆盖老师样例 144 个输入槽
input_wdata : 16-bit signed
output_raddr/output_rdata : 6-bit 地址读回最多 64 个 16-bit 输出槽
```

`rtl/mcu_fft_system.vhd` 仿照板级 `mcu_fft_system` 的 test_ROM/verify_RAM
握手形式，但把旧的 16 个输入修正为老师 2026 样例需要的 144 个输入。

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
PC = 0x0090
instr = 0xE8FFFFFE
branch_offset = -8
PC + 8 - 8 = PC
```

## 5. 本地仿真

运行：

```bash
ghdl -a --std=08 \
  rtl/mcu_v1_decoder.vhd \
  rtl/mcu_v1_alu.vhd \
  rtl/mcu_v1_regfile.vhd \
  rtl/mcu_v1_instr_rom.vhd \
  rtl/mcu_v1_data_mem.vhd \
  rtl/mcu_v1_core.vhd \
  rtl/mcu_fft_system.vhd \
  tb/mcu_v1_decoder_tb.vhd \
  tb/mcu_v1_core_tb.vhd \
  tb/mcu_fft_system_tb.vhd

ghdl -e --std=08 mcu_v1_decoder_tb
ghdl -r --std=08 mcu_v1_decoder_tb

ghdl -e --std=08 mcu_v1_core_tb
ghdl -r --std=08 mcu_v1_core_tb

ghdl -e --std=08 mcu_fft_system_tb
ghdl -r --std=08 mcu_fft_system_tb
```

当前通过结果：

```text
mcu_v1_decoder_tb passed
mcu_v1_core_tb passed
mcu_fft_system_tb passed
```

GHDL 在 core 仿真 0ns 处可能打印少量 `NUMERIC_STD.TO_INTEGER: metavalue detected` warning，这是初始 delta-cycle 中组合信号尚未稳定造成的提示；后续断言和最终结果均通过。

## 6. Core Testbench 覆盖

`tb/mcu_v1_core_tb.vhd` 包含两个 core 实例。

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
```

覆盖：

```text
MOV / ADD / SUB / LDR / STR / MUL / ASR / CMP / BEQ / B
```

### 6.2 FFT 老师样例程序

加载：

```text
asm/fft8_v1_mcu32_basic.mem
```

输入：

```text
加载老师 测试数据样例-2026/FFT_input.coe 的 144 个输入槽：
0..63     DFT 矩阵实部 Q7
64..127   DFT 矩阵虚部 Q7
128..135  信号实部 Q5
136..143  信号虚部 Q5
```

检查输出：

```text
输出槽 0..15 等于老师 FFT_output.coe：
F280 E80A 1A80 FEA2 E080 16F6 E680 FA5E
E900 317C 2C00 1F8C 0B00 0C84 1600 D874
```

并检查：

```text
PC 停在 0x0090
halted_debug = 1
illegal_debug = 0
```

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
