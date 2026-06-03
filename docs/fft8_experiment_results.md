# FFT8 实验数据汇总

本文档集中记录当前 `dsp` 分支下 V1 scalar baseline、V2 packed DSP 加速版、V3 ARM-safe architecture DSP 优化版和 V4 ARM-strict exact 优化版的实验数据。当前阶段只做设计与 GHDL 仿真验证，不包含上板或 Vivado timing 数据。

## 1. 版本与口径

```text
branch: dsp

V1 scalar:
  program: asm/fft8_v1_mcu32_basic.s
  mem:     asm/fft8_v1_mcu32_basic.mem
  model:   32-bit scalar fixed-point FFT/8

V2 packed DSP:
  program: asm/fft8_v2_packed_dsp.s
  mem:     asm/fft8_v2_packed_dsp.mem
  model:   packed complex Q15 FFT/8

V3 arch DSP:
  program: asm/fft8_v3_arch_dsp.s
  mem:     asm/fft8_v3_arch_dsp.mem
  model:   packed complex Q15 FFT/8
  note:    ARM-safe LDMIA/STRD architecture optimization

V4 ARM-strict exact:
  program: asm/fft8_v4_arm_strict.s
  mem:     asm/fft8_v4_arm_strict.mem
  model:   packed complex Q15 FFT/8
  note:    ARM-real SSAX/SSUB16 exact cycle optimization
```

速度换算口径：

```text
脚本输出的是 timed_steps / cnt_test，不是 PPT 里的 万次/秒。
速度 = 时钟频率 / cnt_test
```

如果按 `50 MHz` 估算：

```text
V1: 50 MHz / 276 = 18.12 万次/秒
V2: 50 MHz / 109 = 45.87 万次/秒
V3: 50 MHz / 88  = 56.82 万次/秒
V4: 50 MHz / 78  = 64.10 万次/秒
```

## 2. 指令数与 timed steps

```text
V1 scalar:
  instructions before labels/comments: 286
  instructions executed before DONE self-loop: 285
  timed_steps from first input read through last output write: 276
  DONE PC: 0x0474
  DONE word: 0xE8FFFFFE

V2 packed DSP:
  instructions before labels/comments: 120
  instructions executed before DONE self-loop: 119
  timed_steps from first input read through last output write: 109
  DONE PC: 0x01DC
  DONE word: 0xE8FFFFFE

V3 arch DSP:
  instructions before labels/comments: 98
  instructions executed before DONE self-loop: 97
  timed_steps from first input read through last output write: 88
  DONE PC: 0x0184
  DONE word: 0xE8FFFFFE

V4 ARM-strict exact:
  instructions before labels/comments: 88
  instructions executed before DONE self-loop: 87
  timed_steps from first input read through last output write: 78
  DONE PC: 0x015C
  DONE word: 0xE8FFFFFE
```

## 3. Assembler 实验数据

运行：

```bash
python3 tools/assemble_mcu_v1.py asm/fft8_v1_mcu32_basic.s --mem-out asm/fft8_v1_mcu32_basic.mem --lst-out asm/fft8_v1_mcu32_basic.lst
python3 tools/assemble_mcu_v1.py asm/test_mcu_v1_basic.s --mem-out asm/test_mcu_v1_basic.mem --lst-out asm/test_mcu_v1_basic.lst
python3 tools/assemble_mcu_v1.py asm/fft8_v2_packed_dsp.s --mem-out asm/fft8_v2_packed_dsp.mem --lst-out asm/fft8_v2_packed_dsp.lst
python3 tools/assemble_mcu_v1.py asm/fft8_v3_arch_dsp.s --mem-out asm/fft8_v3_arch_dsp.mem --lst-out asm/fft8_v3_arch_dsp.lst
python3 tools/assemble_mcu_v1.py asm/fft8_v4_arm_strict.s --mem-out asm/fft8_v4_arm_strict.mem --lst-out asm/fft8_v4_arm_strict.lst
```

结果：

```text
encoded 286 instructions from asm/fft8_v1_mcu32_basic.s
DONE at PC 0x0474, word 0xE8FFFFFE

encoded 36 instructions from asm/test_mcu_v1_basic.s
DONE at PC 0x008C, word 0xE8FFFFFE

encoded 120 instructions from asm/fft8_v2_packed_dsp.s
DONE at PC 0x01DC, word 0xE8FFFFFE

encoded 98 instructions from asm/fft8_v3_arch_dsp.s
DONE at PC 0x0184, word 0xE8FFFFFE

encoded 88 instructions from asm/fft8_v4_arm_strict.s
DONE at PC 0x015C, word 0xE8FFFFFE
```

## 4. Python 模型对拍实验数据

运行：

```bash
python3 tools/test_fft8_v1_mcu32_basic.py
python3 tools/test_fft8_v2_packed_dsp.py
python3 tools/test_fft8_v3_arch_dsp.py
python3 tools/test_fft8_v4_arm_strict.py
```

V1 scalar `x0` impulse：

```text
input:
  x0.real = 32760
  others = 0

output:
  [0] real=   4095, imag=      0
  [1] real=   4095, imag=      0
  [2] real=   4095, imag=      0
  [3] real=   4095, imag=      0
  [4] real=   4095, imag=      0
  [5] real=   4095, imag=      0
  [6] real=   4095, imag=      0
  [7] real=   4095, imag=      0
```

V1 scalar `x1` impulse：

```text
input:
  x1.real = 32760
  others = 0

output:
  [0] real=   4095, imag=      0
  [1] real=  -4095, imag=      0
  [2] real=      0, imag=  -4095
  [3] real=      0, imag=   4095
  [4] real=   2895, imag=  -2896
  [5] real=  -2896, imag=   2896
  [6] real=  -2896, imag=  -2896
  [7] real=   2896, imag=   2895
```

V1 scalar 随机与边界测试：

```text
7 edge-case tests passed.
1000 random moderate-amplitude tests passed.
5000 random full-range tests passed.
```

V2 packed DSP `x0` impulse：

```text
input:
  x0.real = 32760
  others = 0

output:
  [0] real=   4095, imag=      0
  [1] real=   4095, imag=      0
  [2] real=   4095, imag=      0
  [3] real=   4095, imag=      0
  [4] real=   4095, imag=      0
  [5] real=   4095, imag=      0
  [6] real=   4095, imag=      0
  [7] real=   4095, imag=      0
```

V2 packed DSP `x1` impulse：

```text
input:
  x1.real = 32760
  others = 0

output:
  [0] real=   4095, imag=      0
  [1] real=  -4095, imag=      0
  [2] real=      0, imag=  -4095
  [3] real=      0, imag=   4095
  [4] real=   2895, imag=  -2896
  [5] real=  -2896, imag=   2896
  [6] real=  -2896, imag=  -2896
  [7] real=   2896, imag=   2895
```

V2 packed DSP 随机与边界测试：

```text
7 edge-case tests passed.
1000 random moderate-amplitude tests passed.
5000 random full-range packed-semantics tests passed.
fast target timed_steps <= 130 passed.
```

V3 arch DSP `x0` impulse：

```text
input:
  x0.real = 32760
  others = 0

output:
  [0] real=   4095, imag=      0
  [1] real=   4095, imag=      0
  [2] real=   4095, imag=      0
  [3] real=   4095, imag=      0
  [4] real=   4095, imag=      0
  [5] real=   4095, imag=      0
  [6] real=   4095, imag=      0
  [7] real=   4095, imag=      0
```

V3 arch DSP `x1` impulse：

```text
input:
  x1.real = 32760
  others = 0

output:
  [0] real=   4095, imag=      0
  [1] real=  -4095, imag=      0
  [2] real=      0, imag=  -4095
  [3] real=      0, imag=   4095
  [4] real=   2895, imag=  -2896
  [5] real=  -2896, imag=   2896
  [6] real=  -2896, imag=  -2896
  [7] real=   2896, imag=   2895
```

V3 arch DSP 随机与边界测试：

```text
7 edge-case tests passed.
1000 random moderate-amplitude tests passed.
5000 random full-range packed-semantics tests passed.
V3 target timed_steps <= 90 passed.
```

V4 ARM-strict exact `x0` impulse：

```text
input:
  x0.real = 32760
  others = 0

output:
  [0] real=   4095, imag=      0
  [1] real=   4095, imag=      0
  [2] real=   4095, imag=      0
  [3] real=   4095, imag=      0
  [4] real=   4095, imag=      0
  [5] real=   4095, imag=      0
  [6] real=   4095, imag=      0
  [7] real=   4095, imag=      0
```

V4 ARM-strict exact `x1` impulse：

```text
input:
  x1.real = 32760
  others = 0

output:
  [0] real=   4095, imag=      0
  [1] real=  -4095, imag=      0
  [2] real=      0, imag=  -4095
  [3] real=      0, imag=   4095
  [4] real=   2895, imag=  -2896
  [5] real=  -2896, imag=   2896
  [6] real=  -2896, imag=  -2896
  [7] real=   2896, imag=   2895
```

V4 ARM-strict exact 随机与边界测试：

```text
7 edge-case tests passed.
1000 random moderate-amplitude tests passed.
5000 random full-range packed-semantics tests passed.
V4 target timed_steps <= 78 passed.
```

说明：

```text
V2/V3/V4 对常见边界样例和 1000 组中等幅度随机输入精确匹配 V1 scalar fixed model。
完整 16-bit 随机输入按 packed DSP fixed model 对拍，因为 halfword lane 中间值可能按 16-bit 语义截断。
V3 与 V2 的 FFT 计算主体一致，优化点只在 LDMIA 输入搬运和 STRD 输出写回。
V4 继续保持 packed FFT exact 语义，只用 SSAX/SSUB16 缩短 -j 旋转和负 twiddle 模板。
```

## 5. GHDL 回归实验数据

运行：

```bash
ghdl -a --std=08 rtl/*.vhd tb/*.vhd
ghdl -e --std=08 mcu_v1_alu_tb && ghdl -r --std=08 mcu_v1_alu_tb
ghdl -e --std=08 mcu_v1_decoder_tb && ghdl -r --std=08 mcu_v1_decoder_tb
ghdl -e --std=08 mcu_v1_core_tb && ghdl -r --std=08 mcu_v1_core_tb
```

Testbench 通过结果：

```text
mcu_v1_alu_tb passed @10ns
mcu_v1_decoder_tb passed @29ns
mcu_v1_core_tb passed @15881ns
```

GHDL core 仿真 0ms 处会打印若干 `NUMERIC_STD.TO_INTEGER: metavalue detected` warning，这是组合 RAM 初始 delta-cycle 中地址信号尚未稳定导致的提示；没有 assertion failure，最终 testbench 通过。

## 6. GHDL basic 小程序数据

```text
MEM_FILE = asm/test_mcu_v1_basic.mem

input:
  slot 0 = 1000
  slot 1 = -500

output:
  slot 0 = 500
  slot 1 = 1500
  slot 2 = 707
  slot 3 = 123
  slot 4 = 8
  slot 5 = 11
  slot 6 = 0x0074
  slot 7 = 0

PC = 0x0000008C
halted_debug = 1
illegal_debug = 0
```

## 7. GHDL V1 scalar FFT 数据

```text
MEM_FILE = asm/fft8_v1_mcu32_basic.mem
```

`x0` impulse：

```text
input:
  x0.real = 32760
  others = 0

output slots:
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

PC = 0x00000474
halted_debug = 1
illegal_debug = 0
```

`x1` impulse：

```text
input:
  x1.real = 32760
  others = 0

output slots:
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

PC = 0x00000474
halted_debug = 1
illegal_debug = 0
```

## 8. GHDL V2 packed DSP FFT 数据

```text
MEM_FILE = asm/fft8_v2_packed_dsp.mem
```

`x0` impulse：

```text
input:
  x0.real = 32760
  others = 0

output slots:
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

PC = 0x000001DC
halted_debug = 1
illegal_debug = 0
```

`x1` impulse：

```text
input:
  x1.real = 32760
  others = 0

output slots:
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

PC = 0x000001DC
halted_debug = 1
illegal_debug = 0
```

## 9. GHDL V3 arch DSP FFT 数据

```text
MEM_FILE = asm/fft8_v3_arch_dsp.mem
```

`x0` impulse：

```text
input:
  x0.real = 32760
  others = 0

output slots:
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

PC = 0x00000184
halted_debug = 1
illegal_debug = 0
```

## 10. GHDL V4 ARM-strict exact FFT 数据

```text
MEM_FILE = asm/fft8_v4_arm_strict.mem
```

`x0` impulse：

```text
input:
  x0.real = 32760
  others = 0

output slots:
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

PC = 0x0000015C
halted_debug = 1
illegal_debug = 0
```

`x1` impulse：

```text
input:
  x1.real = 32760
  others = 0

output slots:
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

PC = 0x0000015C
halted_debug = 1
illegal_debug = 0
```

`x1` impulse：

```text
input:
  x1.real = 32760
  others = 0

output slots:
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

PC = 0x00000184
halted_debug = 1
illegal_debug = 0
```
