# FFT8 V4 ARM-Strict Exact

更新时间：2026-06-03

本文记录 V4-arm-strict-exact 的实现结果。V4 基于 V3 `88 timed_steps`，只新增 ARM 真实存在的 SIMD/DSP 风格指令 `SSAX` 和 `SSUB16`，将 FFT8 packed DSP 程序压到 `78 timed_steps`。

## 1. 目标与约束

V4 保持以下口径：

```text
单核、单发射、单周期 MCU。
一条指令仍计一个 cnt。
程序仍由汇编/机器码逐条执行，不硬连 FFT 旁路。
不新增 FFT8、CMULQ15、fixed twiddle 或 complex load-store 自定义指令。
输出必须精确匹配当前 packed DSP fixed model。
```

V4 指标：

```text
program: asm/fft8_v4_arm_strict.s
mem:     asm/fft8_v4_arm_strict.mem
lst:     asm/fft8_v4_arm_strict.lst

instructions before labels/comments: 88
instructions executed before DONE self-loop: 87
timed_steps from first input read through last output write: 78
DONE PC: 0x015C
DONE word: 0xE8FFFFFE
```

按 `50 MHz` 估算：

```text
50 MHz / 78 = 64.10 万次/秒
```

## 2. 新增指令

V4 在 `op[27:26] = 11` 扩展类中新增：

```text
EXT_SSAX   = 01000
EXT_SSUB16 = 01001

ALU_SSAX   = 1101
ALU_SSUB16 = 1110
```

`SSAX Rd, Rn, Rm`：

```text
lo = signed16(Rn.low16)  + signed16(Rm.high16)
hi = signed16(Rn.high16) - signed16(Rm.low16)
Rd.low16  = lo[15:0]
Rd.high16 = hi[15:0]
```

`SSUB16 Rd, Rn, Rm`：

```text
lo = signed16(Rn.low16)  - signed16(Rm.low16)
hi = signed16(Rn.high16) - signed16(Rm.high16)
Rd.low16  = lo[15:0]
Rd.high16 = hi[15:0]
```

实现口径：

```text
lane 结果按 16-bit 截断/回绕。
不做饱和。
不实现 APSR.GE flags。
不改变当前 flags 行为。
```

## 3. 汇编替换点

V4 以 `asm/fft8_v3_arch_dsp.s` 为模板新增，不修改 V3 文件。

第二条 `LDMIA` 和全部输入打包完成后，`R14` 不再作为输入指针使用，因此生成负 twiddle：

```asm
SSUB16 R14, R13, R12
MOV R10, #512
```

W1 复乘使用负 twiddle 去掉一条取负：

```asm
SMUAD R8, R5, R12
SMUSD R9, R5, R14
ASR R8, R8, #15
ASR R9, R9, #15
PKHBT R5, R8, R9, LSL #16
```

三处 `-j` 旋转从 4 条指令替换为 1 条：

```asm
SSAX R6, R13, R6
SSAX R3, R13, R3
SSAX R7, R13, R7
```

W3 只替换 `SMUSD` 的 twiddle，不提前改变 `SMUAD` 符号：

```asm
SMUAD R8, R7, R12
SMUSD R9, R7, R14
ASR R9, R9, #15
ASR R8, R8, #15
SUB R8, R13, R8
PKHBT R7, R9, R8, LSL #16
```

这里保留 `ASR` 后再取负，是为了精确匹配 packed DSP fixed model。将取负提前到 `ASR` 前的 77-cycle 近似方案会改变负数算术右移的舍入方向，随机 packed 输入会出现 `+/-1` 差异，因此不采用。

## 4. Cycle 预算

```text
V3 timed_steps = 88

SSAX 替换 3 处 -j:
  3 * (4 - 1) = 9 cycles saved

负 twiddle 优化:
  W1 省 1
  W3 省 1
  SSUB16 生成 R14 多 1
  net saved = 1

V4 timed_steps = 88 - 9 - 1 = 78
```

## 5. 验证结果

Assembler：

```bash
python3 tools/assemble_mcu_v1.py asm/fft8_v4_arm_strict.s \
  --mem-out asm/fft8_v4_arm_strict.mem \
  --lst-out asm/fft8_v4_arm_strict.lst
```

结果：

```text
encoded 88 instructions from asm/fft8_v4_arm_strict.s
DONE at PC 0x015C, word 0xE8FFFFFE
```

Python checker：

```bash
python3 tools/test_fft8_v4_arm_strict.py
```

结果：

```text
7 edge-case tests passed.
1000 random moderate-amplitude tests passed.
5000 random full-range packed-semantics tests passed.
V4 target timed_steps <= 78 passed.
```

GHDL 回归：

```text
--std=08:
  mcu_v1_alu_tb passed @10ns
  mcu_v1_decoder_tb passed @29ns
  mcu_v1_core_tb passed @15881ns

--std=93 -fsynopsys:
  mcu_v1_alu_tb passed @10ns
  mcu_v1_decoder_tb passed @29ns
  mcu_v1_core_tb passed @15881ns
```

Core testbench：

```text
v4_core MEM_FILE = asm/fft8_v4_arm_strict.mem

x0 impulse:
  x0.real = 32760
  others = 0
  X0..X7 全部 real = 4095, imag = 0
  PC = 0x0000015C
  halted_debug = 1
  illegal_debug = 0

x1 impulse:
  x1.real = 32760
  others = 0
  输出匹配 V1/V2/V3 当前 bit-reversal 槽位结果
  PC = 0x0000015C
  halted_debug = 1
  illegal_debug = 0
```

## 6. 修改文件

新增：

```text
asm/fft8_v4_arm_strict.s
asm/fft8_v4_arm_strict.mem
asm/fft8_v4_arm_strict.lst
tools/test_fft8_v4_arm_strict.py
docs/fft8_v4_arm_strict.md
```

Additive 扩展：

```text
tools/assemble_mcu_v1.py
rtl/00_mcu_v1_pkg.vhd
rtl/mcu_v1_decoder.vhd
rtl/mcu_v1_alu.vhd
tb/mcu_v1_alu_tb.vhd
tb/mcu_v1_decoder_tb.vhd
tb/mcu_v1_core_tb.vhd
docs/fft8_experiment_results.md
docs/session_memory_mcu_fft.md
docs/mcu_v1_decoder_vhdl.md
docs/mcu_v1_single_cycle_core.md
docs/member2_mcu_isa_plan.md
```
