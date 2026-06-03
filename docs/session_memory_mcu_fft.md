# MCU FFT 项目接力记忆

更新时间：2026-06-03

本文档用于在后续会话中快速恢复上下文，继续完成数字电路课程设计中的 8 点 FFT 速度榜任务。

## 下一会话先读这里

当前仓库工作目录：

```text
/Users/eddz/work/Digital_Circuits
```

当前工作分支：

```text
dsp
```

当前最重要状态：

```text
V1 scalar baseline 已完成，用于基础要求和 32-bit fixed reference。
V2 packed DSP 已完成，用于拓展加速要求。
V3 ARM-safe architecture DSP 已完成，用于架构优化 + cycles 优化展示。
V3 没有实现 FFT8 / fixed twiddle / custom complex load-store 这类专用 FFT 指令。
V3 已经保存为 git 回退点：tag `v3-arm-safe-arch-dsp`，commit `6519911`。
V4 ARM-strict exact 已完成：只新增 ARM 真实存在的 SSAX/SSUB16，达到 78 timed_steps。
V4 没有实现 FFT8 / fixed twiddle / custom complex load-store 这类专用 FFT 指令，也没有采用 77 cycles 近似方案。
V4 独立完成文档：docs/fft8_v4_arm_strict.md。
V4 原计划文档仍保留：docs/fft8_v4_arm_strict_plan.md。
用户明确要求：下一个 session 不要一开始反复跑 V1/V2/V3/V4 checker；旧版本已通过，只有在准备最终交付、commit/tag，或怀疑共享 RTL 破坏旧版本时才做完整回归。
用户明确要求：后续全量/最终汇报默认按 50 MHz 计算速率，不要再默认用 150 MHz。
```

必须牢记的 PPT 口径：

```text
不能绕开汇编/机器码程序，直接用电路硬连出 FFT 结果。
课程要求的核心是 MCU 按指令执行 FFT 程序，并用 cnt 统计程序执行时间。
优化可以改进 ISA / datapath / memory path，但结果必须来自一条条指令执行。
因此不要把最终设计讲成“专用 FFT 硬件直接算完”，要讲成“FFT-friendly MCU 架构优化”。
```

进一步约束：

```text
硬约束：对外展示/答辩使用的汇编 mnemonic 必须是 ARM 真实存在的指令，不能自己创造新 mnemonic。
如果答辩/评分要求“使用的汇编指令必须是 ARM 中真实存在的指令”，则不要再提出自定义融合指令作为主方案。
不建议使用 FFT8 / CMULQ15 / ROTMJ / LDCPLX / STCPLX 这类 ARM 中不存在的 mnemonic。
V2 的 SHADD16 / SHSUB16 / SMUAD / SMUSD / SXTH / PKHBT 属于 ARM/ARM-DSP 风格真实指令口径。
V3 的 LDMIA / STRD 也属于 ARM 中真实存在的访存指令口径。
当前实现使用简化 MCU 编码，但对外 mnemonic 和语义应尽量保持 ARM-safe。
```

完整实验数据汇总文档：

```text
docs/fft8_experiment_results.md
```

当前速度结果：

| 版本 | 说明 | 指令数 | DONE 前执行指令数 | timed_steps / cnt_test | 按 50 MHz 估算速率 | 相对 V1 加速 |
|---|---|---:|---:|---:|---:|---:|
| V1 | scalar baseline | 286 | 285 | 276 | 18.12 万次/秒 | 1.00x |
| V2 | packed DSP | 120 | 119 | 109 | 45.87 万次/秒 | 2.53x |
| V3 | ARM-safe architecture DSP, LDMIA/STRD | 98 | 97 | 88 | 56.82 万次/秒 | 3.14x |
| V4 | ARM-strict exact DSP, SSAX/SSUB16 | 88 | 87 | 78 | 64.10 万次/秒 | 3.54x |

```text
V1 已达到基础要求，作为 32-bit fixed reference。
V2 已达到原目标 timed_steps <= 130。
V3 已达到目标 timed_steps <= 90。
V4 已达到 exact 目标 timed_steps <= 78，当前为 78。
速率公式：速率 = 时钟频率 / timed_steps。
```

当前 GHDL core 仿真数据：

```text
Testbench:
  tb/mcu_v1_core_tb.vhd

V1 scalar FFT:
  MEM_FILE = asm/fft8_v1_mcu32_basic.mem
  x0 impulse 输入:
    x0.real = 32760
    其余 real/imag = 0
  x0 impulse 输出:
    X0..X7 全部 real = 4095, imag = 0

  x1 impulse 输入:
    x1.real = 32760
    其余 real/imag = 0
  x1 impulse 输出槽位:
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
  PC:
    0x00000474
  halted_debug:
    1
  illegal_debug:
    0

V2 packed DSP FFT, x0 impulse:
  MEM_FILE = asm/fft8_v2_packed_dsp.mem
  输入:
    x0.real = 32760
    其余 real/imag = 0
  输出:
    X0..X7 全部 real = 4095, imag = 0
  PC:
    0x000001DC
  halted_debug:
    1
  illegal_debug:
    0

V2 packed DSP FFT, x1 impulse:
  输入:
    x1.real = 32760
    其余 real/imag = 0
  输出槽位:
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
  PC:
    0x000001DC
  halted_debug:
    1
  illegal_debug:
    0

V3 arch DSP FFT, x0 impulse:
  MEM_FILE = asm/fft8_v3_arch_dsp.mem
  输入:
    x0.real = 32760
    其余 real/imag = 0
  输出:
    X0..X7 全部 real = 4095, imag = 0
  PC:
    0x00000184
  halted_debug:
    1
  illegal_debug:
    0

V3 arch DSP FFT, x1 impulse:
  输入:
    x1.real = 32760
    其余 real/imag = 0
  输出槽位:
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
  PC:
    0x00000184
  halted_debug:
    1
  illegal_debug:
    0

V4 ARM-strict exact FFT, x0 impulse:
  MEM_FILE = asm/fft8_v4_arm_strict.mem
  输入:
    x0.real = 32760
    其余 real/imag = 0
  输出:
    X0..X7 全部 real = 4095, imag = 0
  PC:
    0x0000015C
  halted_debug:
    1
  illegal_debug:
    0

V4 ARM-strict exact FFT, x1 impulse:
  输入:
    x1.real = 32760
    其余 real/imag = 0
  输出槽位:
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
  PC:
    0x0000015C
  halted_debug:
    1
  illegal_debug:
    0
```

注意速度单位：

```text
脚本里的 timed_steps/cnt_test 不是 PPT 表格里的 万次/秒。
速度 = 时钟频率 / cnt_test
当前按 50 MHz 估算：
  V1 = 50 MHz / 276 = 18.12 万次/秒。
  V2 = 50 MHz / 109 = 45.87 万次/秒。
  V3 = 50 MHz / 88  = 56.82 万次/秒。
  V4 = 50 MHz / 78  = 64.10 万次/秒。
后续全量/最终汇报按 50 MHz 口径，不再默认使用早期 150 MHz 估算。
```

当前架构判断：

```text
V1/V2/V3/V4 都不是双核。
V1/V2/V3/V4 都是单核、单周期、单发射 MCU。
tb/mcu_v1_core_tb.vhd 里的 basic_core / fft_core / fast_core / v3_core / v4_core 五个实例只是为了 GHDL 同时验证五个程序，不代表最终设计是多核。
```

下一步如果用户说“继续加速”：

```text
不要优先做双核或单核多发射。
V3 已选择 ARM-safe 口径并完成：LDMIA/STRD + packed DSP。
V4 已在 ARM 真实 mnemonic 约束下完成：SSAX/SSUB16 + packed DSP。
如果还要继续追 PPT 更高档位，需要明确讨论是否接受更专用的 FFT/fixed-twiddle 指令或架构并行化；当前 V4 故意没有做这些。
如果硬约束仍是“ARM 里真实存在的指令”，继续可挖空间已经很小，不要自创融合 mnemonic。
```

当前 V3 additive 方案：

```text
新增 asm/fft8_v3_arch_dsp.s，不替换 V1/V2。

新增 ARM 风格：
  LDMIA Rn!, {reglist}
  STRD Rd, Rm, [Rn + imm]

目标和结果：
  把 V2 的 109 timed_steps 压到 <= 90。
  当前 V3 = 88 timed_steps。
```

当前 V4 additive 方案：

```text
新增 asm/fft8_v4_arm_strict.s，不替换 V1/V2/V3。

新增 ARM SIMD/DSP 风格：
  SSAX
  SSUB16

目标和结果：
  把 V3 的 88 timed_steps 压到 78。
  当前 V4 = 78 timed_steps。
  仍精确匹配 packed DSP fixed model，不采用 77 cycles risky 近似方案。
```

下一会话建议执行顺序：

```text
1. 先看本节，再看 0.10 / 0.7 / 0.6。
2. 不要切分支，继续在 dsp 分支。
3. V1/V2/V3 tags 都已保留为回退点；V4 也应保存为回退点。
4. 默认不要跑 V1/V2/V3/V4 Python checker；它们已通过且汇编不改。
5. 完整 V1-V4 Python/GHDL 回归只在最终验收、准备 commit/tag，或怀疑共享 RTL 影响旧程序时跑一次。
6. 不要把 77 cycles risky 近似方案混入 exact 主线；不要引入 FFT 硬件旁路或自创 FFT/complex/fixed-twiddle 指令。
```

## 0. 2026-06-02 最新接口覆盖说明

2026-06-02 用户补充两份最新要求：

```text
/Users/eddz/Library/Containers/com.tencent.qq/Data/Downloads/第一版MCU指令格式说明.md
/Users/eddz/Library/Containers/com.tencent.qq/Data/Downloads/第一版MCU对成员A接口说明.md
```

这些要求覆盖本文档中旧的 `0x1000 / 0x2000` 基址和输入/输出 `+2` 步长口径。

最新第一版接口应以以下内容为准：

```text
INPUT_BASE   = 0x00000000
WORK_BASE    = 0x00000100
OUTPUT_BASE  = 0x00000200
```

程序员视角下：

```text
输入区、工作区、输出区统一按 32-bit 槽位访问
三个区域相邻槽位地址步长统一为 +4
输入区 LDR：底层 16-bit signed -> 寄存器 32-bit signed
输出区 STR：寄存器 32-bit -> 外部 16-bit verify_RAM
```

最新指令格式还规定数据处理和访存立即数为 `imm12`，所以单条立即数不能超过 `4095`。因此 `23170` 不能再写成：

```asm
MOV R12, #23170
```

当前应使用多条 `imm12` 安全指令构造：

```asm
MOV R12, #4095
ADD R12, R12, #4095
ADD R12, R12, #4095
ADD R12, R12, #4095
ADD R12, R12, #4095
ADD R12, R12, #2695
```

最新代码文件：

```text
/Users/eddz/work/Digital_Circuits/asm/fft8_v1_mcu32_basic.s
/Users/eddz/work/Digital_Circuits/asm/fft8_v1_mcu32_basic.mem
/Users/eddz/work/Digital_Circuits/asm/fft8_v1_mcu32_basic.lst
/Users/eddz/work/Digital_Circuits/tools/test_fft8_v1_mcu32_basic.py
/Users/eddz/work/Digital_Circuits/tools/assemble_mcu_v1.py
/Users/eddz/work/Digital_Circuits/docs/fft8_v1_mcu32_check_rules.md
/Users/eddz/work/Digital_Circuits/rtl/00_mcu_v1_pkg.vhd
/Users/eddz/work/Digital_Circuits/rtl/mcu_v1_decoder.vhd
/Users/eddz/work/Digital_Circuits/rtl/mcu_v1_alu.vhd
/Users/eddz/work/Digital_Circuits/rtl/mcu_v1_regfile.vhd
/Users/eddz/work/Digital_Circuits/rtl/mcu_v1_instr_rom.vhd
/Users/eddz/work/Digital_Circuits/rtl/mcu_v1_input_mem.vhd
/Users/eddz/work/Digital_Circuits/rtl/mcu_v1_work_ram.vhd
/Users/eddz/work/Digital_Circuits/rtl/mcu_v1_output_mem.vhd
/Users/eddz/work/Digital_Circuits/rtl/z90_mcu_v1_data_mem.vhd
/Users/eddz/work/Digital_Circuits/rtl/mcu_v1_pc_unit.vhd
/Users/eddz/work/Digital_Circuits/rtl/z99_mcu_v1_core.vhd
/Users/eddz/work/Digital_Circuits/tb/mcu_v1_decoder_tb.vhd
/Users/eddz/work/Digital_Circuits/tb/mcu_v1_core_tb.vhd
/Users/eddz/work/Digital_Circuits/docs/mcu_v1_decoder_vhdl.md
/Users/eddz/work/Digital_Circuits/docs/mcu_v1_single_cycle_core.md
/Users/eddz/work/Digital_Circuits/asm/test_mcu_v1_basic.s
/Users/eddz/work/Digital_Circuits/asm/test_mcu_v1_basic.mem
/Users/eddz/work/Digital_Circuits/asm/test_mcu_v1_basic.lst
/Users/eddz/work/Digital_Circuits/asm/fft8_v2_packed_dsp.s
/Users/eddz/work/Digital_Circuits/asm/fft8_v2_packed_dsp.mem
/Users/eddz/work/Digital_Circuits/asm/fft8_v2_packed_dsp.lst
/Users/eddz/work/Digital_Circuits/tools/test_fft8_v2_packed_dsp.py
/Users/eddz/work/Digital_Circuits/asm/fft8_v3_arch_dsp.s
/Users/eddz/work/Digital_Circuits/asm/fft8_v3_arch_dsp.mem
/Users/eddz/work/Digital_Circuits/asm/fft8_v3_arch_dsp.lst
/Users/eddz/work/Digital_Circuits/tools/test_fft8_v3_arch_dsp.py
/Users/eddz/work/Digital_Circuits/asm/fft8_v4_arm_strict.s
/Users/eddz/work/Digital_Circuits/asm/fft8_v4_arm_strict.mem
/Users/eddz/work/Digital_Circuits/asm/fft8_v4_arm_strict.lst
/Users/eddz/work/Digital_Circuits/tools/test_fft8_v4_arm_strict.py
/Users/eddz/work/Digital_Circuits/tb/mcu_v1_alu_tb.vhd
/Users/eddz/work/Digital_Circuits/docs/fft8_v2_packed_dsp.md
/Users/eddz/work/Digital_Circuits/docs/fft8_v3_arch_dsp.md
/Users/eddz/work/Digital_Circuits/docs/fft8_v4_arm_strict.md
/Users/eddz/work/Digital_Circuits/docs/fft8_v4_arm_strict_plan.md
/Users/eddz/work/Digital_Circuits/docs/fft8_experiment_results.md
```

## 0.7 2026-06-02 V3 ARM-safe architecture DSP 完成记录

用户最终选择的 V3 口径：

```text
V3 = 架构优化 + cycles 优化。
继续基于 dsp 分支和 v2-packed-dsp。
对外展示保持 ARM / ARM-DSP 风格。
不做 FFT8 单指令，不做 fixed-twiddle 自定义融合指令，不做自定义 complex load-store。
```

新增 V3 文件：

```text
asm/fft8_v3_arch_dsp.s
asm/fft8_v3_arch_dsp.mem
asm/fft8_v3_arch_dsp.lst
tools/test_fft8_v3_arch_dsp.py
docs/fft8_v3_arch_dsp.md
```

新增 ARM 风格访存：

```text
LDMIA Rn!, {reglist}
  op[27:26] = 11
  funct[25:21] = 00110
  W[20] = 1
  Rn[19:16] = base register
  regmask[15:0] = register list

STRD Rd, Rm, [Rn + imm]
  op[27:26] = 11
  funct[25:21] = 00111
  Rn[19:16] = base register
  Rd[15:12] = first source register
  imm8[11:4] = byte offset, must be multiple of 4
  Rm[3:0] = second source register
```

V3 指标：

```text
98 instructions before labels/comments
97 instructions executed before DONE self-loop
88 timed_steps from first input read through last output write
DONE PC = 0x0184
DONE word = 0xE8FFFFFE
```

V3 RTL 增强：

```text
decoder:
  新增 LDMIA / STRD decode、bulk_load、store_double、bulk_writeback、ra3、bulk_regmask。

regfile:
  新增第三个组合读端口。
  新增 bulk write，用于 LDMIA 一周期写多个寄存器。
  LDMIA writeback 同周期写 Rn = Rn + 4 * popcount(regmask)。

data_mem/input/work/output:
  新增连续 bulk read。
  work/output 新增 double write。
  输出区仍只保存 write_data[15:0]，匹配 verify_RAM 16-bit 口径。

core:
  保持单核、单周期、单发射。
  LDMIA/STRD 仍各算一条指令、一个 cnt_test cycle。
```

V3 验证：

```text
tools/test_fft8_v3_arch_dsp.py:
  7 edge-case tests passed.
  1000 random moderate-amplitude tests passed.
  5000 random full-range packed-semantics tests passed.
  V3 target timed_steps <= 90 passed.

tb/mcu_v1_decoder_tb.vhd:
  覆盖 LDMIA R14!, {R0-R7}
  覆盖 STRD R0, R8, [R10 + 0]
  覆盖非法 LDMIA base-in-reglist

tb/mcu_v1_core_tb.vhd:
  新增 v3_core 加载 asm/fft8_v3_arch_dsp.mem
  x0 impulse 输出全 real=4095 imag=0
  x1 impulse 输出匹配 V1/V2 当前 bit-reversal 结果
  PC 停在 0x00000184
  illegal_debug = 0
  halted_debug = 1
```

Git 回退点：

```text
v1-scalar-baseline      -> 7f6b62e
v2-packed-dsp           -> 665a680
v3-arm-safe-arch-dsp    -> 6519911
```

当前 V3 提交信息：

```text
commit: 6519911
message: add v3 arm-safe fft architecture optimization
branch: dsp
tag: v3-arm-safe-arch-dsp
```

V4 方向提醒：

```text
用户已经明确：写出来的汇编指令 ARM 里必须真实存在，不能自己创造。
因此 V4 没有走 FFT8 / CMULQ15 / ROTMJ / LDCPLX / STCPLX 这类自定义融合指令路线。
V4 命名为 V4-arm-strict-exact，只新增 ARM 真实 DSP/SIMD 风格 SSAX/SSUB16。
当前结果已经达到单核、单发射、单周期、ARM 真实 mnemonic 约束下的 78 timed_steps。
```

## 0.10 2026-06-03 V4-arm-strict-exact 完成记录

V4 完成文档：

```text
docs/fft8_v4_arm_strict.md
```

V4 原执行计划仍保留：

```text
docs/fft8_v4_arm_strict_plan.md
```

V4 当前结果：

```text
名称：V4-arm-strict-exact
基线：V3 ARM-safe architecture DSP
V3 timed_steps = 88
V4 timed_steps = 78
按 50 MHz 估算：50 MHz / 78 = 64.10 万次/秒
```

生成物：

```text
asm/fft8_v4_arm_strict.s
asm/fft8_v4_arm_strict.mem
asm/fft8_v4_arm_strict.lst
tools/test_fft8_v4_arm_strict.py
docs/fft8_v4_arm_strict.md
```

计数：

```text
88 instructions before labels/comments
87 instructions executed before DONE self-loop
78 timed_steps from first input read through last output write
DONE PC = 0x015C
DONE word = 0xE8FFFFFE
```

硬约束仍然不变：

```text
ARM 真实存在的 mnemonic。
单核、单发射、单周期。
一条指令计一个 cnt。
不做 FFT 专用硬件旁路。
不自创 FFT / complex load-store / fixed-twiddle 指令。
必须精确匹配当前 packed DSP fixed model。
```

V4 只新增两条 ARM SIMD/DSP 风格真实指令：

```text
SSAX
SSUB16
```

新增编码和控制码：

```text
EXT_SSAX   = 01000
EXT_SSUB16 = 01001
ALU_SSAX   = 1101
ALU_SSUB16 = 1110
```

V4 替换点：

```text
SSUB16 R14, R13, R12
  生成 packed negative twiddle {-23170,-23170}。

SMUSD R9, R5, R14
  W1 复乘省去 ASR 前的取负模板。

SSAX R6, R13, R6
SSAX R3, R13, R3
SSAX R7, R13, R7
  三处 -j 旋转从 4 条压到 1 条。

SMUSD R9, R7, R14
  W3 只替换 SMUSD 的 twiddle，仍保留 ASR 后 SUB R8,R13,R8。
```

重要结论：

```text
77 cycles 不是正确主方案。
77 需要把 W3 的一个负号提前到 ASR 前，导致 ASR 舍入顺序变化。
随机 packed 输入会出现 +/-1 差异，不能通过 exact 对拍。
不要把 77 risky 版本混入 V4 主线。
```

验证：

```text
python3 tools/test_fft8_v1_mcu32_basic.py
python3 tools/test_fft8_v2_packed_dsp.py
python3 tools/test_fft8_v3_arch_dsp.py
python3 tools/test_fft8_v4_arm_strict.py

V4 checker:
  7 edge-case tests passed.
  1000 random moderate-amplitude tests passed.
  5000 random full-range packed-semantics tests passed.
  V4 target timed_steps <= 78 passed.

GHDL --std=08:
  mcu_v1_alu_tb passed @10ns
  mcu_v1_decoder_tb passed @29ns
  mcu_v1_core_tb passed @15881ns

GHDL --std=93 -fsynopsys:
  mcu_v1_alu_tb passed @10ns
  mcu_v1_decoder_tb passed @29ns
  mcu_v1_core_tb passed @15881ns
```

保存点状态：

```text
本轮未自动 commit/tag/push。
如后续需要保存回退点，可在确认 git diff 后提交并打 tag：
  git commit -m "add v4 arm strict exact fft optimization"
  git tag v4-arm-strict-exact
```

## 0.9 2026-06-02 Vivado VHDL 兼容性清理

Vivado 仿真/上板同学提出：

```text
process(all) 是 VHDL-2008 语法。
use std.env.all 和 finish 也依赖较新的 VHDL 标准。
如果 Vivado 工程没有明确设为 VHDL-2008，容易报标准兼容性错误。
```

已按更保守口径清理：

```text
RTL / testbench 中不再使用 process(all)，全部改为显式敏感列表。
testbench 中不再使用 use std.env.all。
testbench 中不再使用 finish。
mcu_v1_alu_tb / mcu_v1_decoder_tb 结尾改为 report passed 后 wait。
mcu_v1_core_tb 增加 sim_done，passed 后关闭 clock，再 wait，使 Run All 不会因为时钟一直跳而挂住。
```

已验证：

```text
rg 未再找到 process(all) / std.env / finish。
ghdl --std=08 完整回归通过。
ghdl --std=93 -fsynopsys 完整回归通过。
```

注意：

```text
GHDL 的 --std=93 下 rtl/mcu_v1_instr_rom.vhd 使用 ieee.std_logic_textio 需要 -fsynopsys。
Vivado 通常可接受 std_logic_textio；若后续仍遇到 ROM init 兼容性问题，再单独处理 .mem 读取方式。
0ms numeric_std metavalue warning 仍存在，来源是组合读地址初始未稳定；testbench 无 assertion failure。
```

## 0.8 V4-arm-strict 计划

V4 定义：

```text
名称：V4-arm-strict
基线：从 `v3-arm-safe-arch-dsp` / commit `6519911` 往后做。
目标：在不自创指令的约束下，尽可能降低 V3 的 88 timed_steps。
口径：仍然是 MCU 逐条执行 FFT 汇编程序，不是 FFT 硬件旁路。
```

硬约束：

```text
1. 汇编 mnemonic 必须是 ARM 中真实存在的指令。
2. 不使用 FFT8 / CMULQ15 / ROTMJ / LDCPLX / STCPLX 等自创 mnemonic。
3. 保持单核、单发射、单周期；一条指令仍计一个 cnt。
4. 不做输入直接接 FFT 电路、输出直接写 verify_RAM 的硬连方案。
5. V1/V2/V3 不改；V4 新增文件和测试，失败时可回退到 V3 tag。
```

V4 目标值：

```text
V3 当前分解：
  input load/pack = 11
  compute         = 61
  output store    = 16
  total           = 88

V4 主攻 compute 的 61 cycles。
保守目标：timed_steps < 88。
实际目标：timed_steps <= 84。
挑战目标：timed_steps <= 80。
不要承诺 50-60；在 ARM-real 指令约束下，50-60 很可能需要更专用的自定义融合或多发射。
```

候选 ARM 真实指令方向：

```text
1. 复乘模板优化：
   候选：SMUADX / SMUSDX / SMLSD / SMLSDX。
   目的：尝试减少 W1/W3 复乘中的 SUB / ASR / PKHBT 周边开销。
   注意：实施前必须逐条确认 ARM mnemonic 和语义，不能凭名字猜。

2. packed butterfly 优化：
   候选：QADD16 / QSUB16 / QASX / QSAX / SHASX / SHSAX。
   目的：检查能否替代部分 SHADD16 / SHSUB16 和交换半字操作。
   注意：V2/V3 使用的是每级 ASR #1 风格，饱和类 Q 指令可能改变语义，必须严查。

3. pack/unpack 优化：
   候选：PKHTB / SXTB16 / UXTB16 / SXTAH / REV16。
   目的：尝试减少 SXTH / ASR / PKHBT 的组合开销。

4. 访存和输出优化：
   候选：LDRD / STRD / LDMIA。
   目的：V3 已用 LDMIA / STRD；继续确认是否有更好寄存器布局减少输出 ASR。
```

实施步骤：

```text
1. 从 V3 回退点确认基线：
   git log --oneline --decorate -3
   python3 tools/test_fft8_v3_arch_dsp.py
   ghdl -a --std=08 rtl/*.vhd tb/*.vhd
   ghdl -e/r 三个 testbench

2. 新增审计文档：
   docs/fft8_v4_arm_strict_plan.md
   把 V3 的 88 timed_steps 按 input / compute / output 拆成可替换模板。

3. 写局部模板搜索/对拍脚本：
   tools/test_fft8_v4_arm_strict.py
   或先写 tools/analyze_fft8_v3_templates.py。
   每个候选替换都必须对拍 V1 scalar model 和 packed DSP model。

4. 只在确认收益后新增 V4 汇编：
   asm/fft8_v4_arm_strict.s
   asm/fft8_v4_arm_strict.mem
   asm/fft8_v4_arm_strict.lst

5. 如果 V4 需要 ARM-real 新指令：
   只新增这些真实 ARM mnemonic 的 assembler decode / RTL decode / ALU 实现。
   不新增任何自创 mnemonic。

6. 更新 testbench：
   decoder 覆盖每条新增 ARM-real 指令。
   alu 覆盖每条新增 ARM-real 指令的边界语义。
   core 新增 v4_core，加载 asm/fft8_v4_arm_strict.mem。

7. 更新文档和记忆：
   docs/fft8_experiment_results.md 加 V4 表格。
   docs/session_memory_mcu_fft.md 加 V4 完成状态和回退 tag。
```

V4 验收标准：

```text
V1/V2/V3 回归不退化。
V4 checker 通过：
  7 edge-case tests
  1000 random moderate-amplitude tests
  5000 random full-range packed-semantics tests
V4 timed_steps 必须 < 88，否则不值得作为 V4。
若能 <= 84，算达成主目标。
若能 <= 80，算挑战目标达成。
GHDL 无 assertion failure。
```

V4 风险和答辩口径：

```text
风险 1：ARM 真实指令语义不一定刚好省 cycles，可能只能小幅优化。
风险 2：QADD/QSUB 等饱和指令可能改变 FFT 数值语义，不能为省 cnt 乱用。
风险 3：更多 datapath 组合逻辑可能降低最高频率，所以最终真实速率还要看 timing。

答辩口径：
V4 不是自定义 FFT 指令，也不是硬件直接算 FFT。
V4 是在 ARM 真实 DSP 指令范围内继续优化 MCU 执行的 FFT 汇编程序。
```

## 0.6 2026-06-02 最新讨论与下一会话入口

当前工作分支：

```text
dsp
```

当前状态：

```text
V1 scalar baseline 已完成，保留为基础要求/reference。
V2 packed DSP 加速版已完成，作为拓展要求。
V3 ARM-safe architecture DSP 版已完成，作为架构优化 + cycles 优化版本。
V4 ARM-strict exact 版已完成，作为 ARM 真实 mnemonic 约束下的精确 cycles 优化版本。
```

用户后续问过“为什么速度还没有截图里的 PPT 排行榜高”。需要记住：截图单位是 `万次/秒`，而当前脚本报告的是 `timed_steps / cnt_test`。二者换算需要乘上时钟频率：

```text
速度 = 时钟频率 / cnt_test
```

历史讨论曾按 `150 MHz` 估算：

```text
V1: 150 MHz / 276 = 54.35 万次/秒
V2: 150 MHz / 109 = 137.61 万次/秒
V3: 150 MHz / 88  = 170.45 万次/秒
V4: 150 MHz / 78  = 192.31 万次/秒
```

当前用户已要求全量/最终汇报默认按 `50 MHz` 计算，不再默认使用这里的 `150 MHz` 历史估算。若要按 50 MHz 达到：

```text
277.78 万次/秒 -> cnt 约 54
652.27 万次/秒 -> cnt 约 23
```

这意味着下一轮如果还要追更高档位，需要讨论是否接受比 V4 更专用的 FFT/fixed-twiddle 指令或架构并行化。

重要架构解释：

```text
当前 V1/V2/V3/V4 不是双核。
当前是单核、单周期、单发射 MCU。
tb/mcu_v1_core_tb.vhd 里 basic_core / fft_core / fast_core / v3_core / v4_core 五个实例只是为了 GHDL 同时验证不同程序，不是最终设计中的多核。
```

术语解释：

```text
单核单发射：
  一个 core，每个周期最多发射/执行一条指令。
  当前 V1/V2/V3/V4 属于这个类型。

单核多发射：
  一个 core，每个周期可以同时发射多条不冲突的指令。
  理论上能减少 cycles，但需要双取指、双译码、多端口 regfile、多 ALU、访存冲突和数据相关处理。
  对本课设来说复杂度高，不建议优先做。
```

下一步推荐方向：

```text
V4 已完成，不要再按旧 fused 指令方案开工。
当前推荐保留 ARM-real exact 口径：LDMIA/STRD + packed DSP + SSAX/SSUB16。
如果用户明确要继续冲更高速度，再讨论是否允许 FFT/fixed-twiddle 专用指令或并行架构。
```

已实现 V3 指令方向：

```text
LDMIA Rn!, {reglist}
  从连续 32-bit 程序槽位读取多个寄存器。
  当前用于 V3 输入搬运：两条 LDMIA 读完 16 个输入槽位。

STRD Rd, Rm, [Rn + imm]
  向连续两个 32-bit 程序槽位写两个源寄存器。
  当前用于 V3 输出写回：ASR 拆 imag 后用 STRD 同周期写 real/imag 槽位。
```

实际收益：

```text
V2 输入打包：16 LDR + 8 PKHBT = 24 条
V3 输入打包：2 LDMIA + 8 PKHBT + 1 MOV = 11 条
省 13 cycles

V2 输出拆包：8 STR + 8 ASR + 8 STR = 24 条
V3 输出拆包：8 ASR + 8 STRD = 16 条
省 8 cycles

V2/V3 计算主体都为 61 cycles
```

因此 V3 已经从：

```text
V2: 109 timed_steps
```

压到：

```text
V3: 88 timed_steps
```

这是一版更容易解释为 ARM / ARM-DSP 风格架构优化的安全方案。

实现提醒：

```text
LDMIA / STRD 保持单周期，需要扩展 regfile / data_mem 的 bulk read、bulk write 和 double write 能力。
这不等于多发射，仍然是一条指令一个周期，只是这条指令内部做了更宽的 memory 操作。
V3 是 additive：新增 asm/fft8_v3_arch_dsp.s，不替换或删除 V1/V2。
```

下一会话如果用户说“继续做 V3/V4”，建议先做：

```text
1. 先确认当前工作区是否已经完成回归。
2. 确认是否需要给 V4 打 tag 或 commit。
3. 如果要继续提速，先明确是保持 ARM-real exact，还是允许专用 FFT 指令或并行架构。
```

## 0.5 2026-06-02 DSP 分支 packed FFT 加速进展

用户要求不要直接改基础版电路，而是在 `dsp` 分支实现拓展加速版。当前已在 `dsp` 分支新增 packed DSP 扩展，V1 scalar baseline 仍保留。

新增指令类：

```text
op[27:26] = 11
funct[25:21]
reserved[20] = 0

00000 = SHADD16
00001 = SHSUB16
00010 = SMUAD
00011 = SMUSD
00100 = SXTH
00101 = PKHBT
```

新增 fast FFT：

```text
asm/fft8_v2_packed_dsp.s
asm/fft8_v2_packed_dsp.mem
asm/fft8_v2_packed_dsp.lst
tools/test_fft8_v2_packed_dsp.py
docs/fft8_v2_packed_dsp.md
```

当前 V2 指标：

```text
120 条指令
119 条执行指令 before DONE self-loop
109 条 timed steps
目标 timed_steps <= 130 已达到
V1 baseline timed_steps = 276
```

数值验证口径：

```text
常见边界样例 + 1000 组中等幅度随机输入：精确匹配 V1 scalar fixed model
5000 组完整 16-bit 随机输入：精确匹配 packed DSP fixed model
```

完整 16-bit 随机输入不强制匹配 V1 scalar，是因为 packed halfword 旋转中间值可能超过 signed 16-bit lane，V2 会按 halfword lane 语义截断；V1 scalar baseline 会保留 32-bit 中间值。答辩时建议把 V1 作为准确 reference，把 V2 作为 packed DSP 加速拓展展示。

当前新增 GHDL 覆盖：

```text
tb/mcu_v1_alu_tb.vhd
  SHADD16 / SHSUB16 / SMUAD / SMUSD / SXTH / PKHBT

tb/mcu_v1_decoder_tb.vhd
  新增 DSP opcode decode 与非法扩展格式检查

tb/mcu_v1_core_tb.vhd
  fast_core 加载 asm/fft8_v2_packed_dsp.mem
  x0 impulse -> 全部 real=4095, imag=0
  x1 impulse -> bit-reversal spectrum
```

当前 GHDL core 仿真数据：

```text
V1 scalar FFT:
  asm/fft8_v1_mcu32_basic.mem
  input:  x0.real=32760, others=0
  output: X0..X7 all real=4095, imag=0
  x1 impulse output slots:
    0:  4095
    1:     0
    2: -4095
    3:     0
    4:     0
    5: -4095
    6:     0
    7:  4095
    8:  2895
    9: -2896
   10: -2896
   11:  2896
   12: -2896
   13: -2896
   14:  2896
   15:  2895
  pc_debug=0x00000474
  halted_debug=1
  illegal_debug=0

V2 packed DSP FFT:
  asm/fft8_v2_packed_dsp.mem
  x0 impulse output: X0..X7 all real=4095, imag=0
  x0 pc_debug=0x000001DC, halted_debug=1, illegal_debug=0

  x1 impulse output slots:
    0:  4095
    1:     0
    2: -4095
    3:     0
    4:     0
    5: -4095
    6:     0
    7:  4095
    8:  2895
    9: -2896
   10: -2896
   11:  2896
   12: -2896
   13: -2896
   14:  2896
   15:  2895
  x1 pc_debug=0x000001DC, halted_debug=1, illegal_debug=0
```

## 0.4 2026-06-02 VHDL 模块化进展

为便于讲解，当前 RTL 已进一步模块化。

新增：

```text
rtl/00_mcu_v1_pkg.vhd
rtl/mcu_v1_input_mem.vhd
rtl/mcu_v1_work_ram.vhd
rtl/mcu_v1_output_mem.vhd
rtl/mcu_v1_pc_unit.vhd
```

当前模块职责：

```text
mcu_v1_pkg        公共常量：ALU 控制码、opcode、条件码、地址区域码
mcu_v1_decoder    指令译码和控制信号
mcu_v1_regfile    16 个 32-bit 寄存器
mcu_v1_alu        AND / ORR / ADD / SUB / MUL / ASR / MOV；dsp 分支还支持 packed DSP 操作
mcu_v1_instr_rom  指令 ROM，读取 .mem
mcu_v1_pc_unit    PC+4、PC+8+branch_offset、自循环 halted 检测
mcu_v1_data_mem   数据地址区路由
mcu_v1_input_mem  输入区，模拟 test_ROM，16-bit signed -> 32-bit signed
mcu_v1_work_ram   工作区，32-bit RAM
mcu_v1_output_mem 输出区，模拟 verify_RAM，写入低 16-bit
mcu_v1_core       顶层连线
```

新的 GHDL 编译顺序：

```text
ghdl -a --std=08 \
  rtl/00_mcu_v1_pkg.vhd \
  rtl/mcu_v1_decoder.vhd \
  rtl/mcu_v1_alu.vhd \
  rtl/mcu_v1_regfile.vhd \
  rtl/mcu_v1_instr_rom.vhd \
  rtl/mcu_v1_input_mem.vhd \
  rtl/mcu_v1_work_ram.vhd \
  rtl/mcu_v1_output_mem.vhd \
  rtl/z90_mcu_v1_data_mem.vhd \
  rtl/mcu_v1_pc_unit.vhd \
  rtl/z99_mcu_v1_core.vhd \
  tb/mcu_v1_alu_tb.vhd \
  tb/mcu_v1_decoder_tb.vhd \
  tb/mcu_v1_core_tb.vhd
```

## 0.3 2026-06-02 指令集完善进展

根据 `数字电路实验_MCU.pptx` 第 3 页最低要求，MCU 至少需要支持：

```text
ADD / SUB / AND / OR / MOV / LDR / STR / B/BL
```

当前 GHDL baseline 已补齐：

```text
AND
ORR   ; PPT 写 OR，ARM mnemonic 使用 ORR；汇编器同时接受 OR 作为别名
BL
```

当前正式支持指令变为：

```text
MOV / ADD / SUB / AND / ORR / CMP / LDR / STR / B / BL / BEQ / BNE / MUL / ASR
```

BL 编码沿用当前分支类格式：

```text
op[27:26] = 10
bit25     = 0
bit24     = L
L = 0: B / BEQ / BNE
L = 1: BL
branch target = PC + 8 + (sign_extend(imm24) << 2)
BL link write = R14 = PC + 4
```

已修改：

```text
tools/assemble_mcu_v1.py
rtl/mcu_v1_decoder.vhd
rtl/z99_mcu_v1_core.vhd
tb/mcu_v1_decoder_tb.vhd
tb/mcu_v1_core_tb.vhd
asm/test_mcu_v1_basic.s
asm/test_mcu_v1_basic.mem
asm/test_mcu_v1_basic.lst
docs/member2_mcu_isa_plan.md
docs/mcu_v1_decoder_vhdl.md
docs/mcu_v1_single_cycle_core.md
```

新增基础程序检查：

```text
AND R6, R6, R7   ; 10 AND 12 = 8
ORR R7, R6, #3   ; 8 OR 3 = 11
BL AFTER_BL      ; R14 = 0x0074
```

最新验证：

```text
python3 tools/test_fft8_v1_mcu32_basic.py
python3 tools/assemble_mcu_v1.py asm/fft8_v1_mcu32_basic.s
python3 tools/assemble_mcu_v1.py asm/test_mcu_v1_basic.s
ghdl -a/e/r mcu_v1_decoder_tb
ghdl -a/e/r mcu_v1_core_tb
```

结果：

```text
FFT 对拍通过
fft8_v1_mcu32_basic.s: 286 instructions, DONE PC 0x0474
test_mcu_v1_basic.s:   36 instructions, DONE PC 0x008C
mcu_v1_decoder_tb passed
mcu_v1_core_tb passed
```

## 1. 当前任务

用户是三人小组中的成员 1，负责：

```text
FFT 算法与汇编优化
```

核心目标：

```text
在自研 MCU 上，用汇编程序完成 8 点复数 FFT，并尽可能减少 cnt_test 周期。
```

当前优先级：

```text
1. 先写第一版 MCU 可执行的 FFT 汇编
2. 保证符合成员 2 当前承诺的第一版 MCU 接口
3. 先正确跑通，再逐步优化速度
```

## 2. 板卡、芯片与“内核”结论

课程使用的不是现成 ARM Cortex-M MCU。

实际平台是：

```text
K7EDA-EVAL FPGA 开发板
Xilinx Kintex-7 FPGA
芯片：XC7K160T-2FFG676-I
Vivado part：xc7k160tffg676-2
```

重要结论：

```text
这块板没有硬 ARM Cortex 内核。
需要在 Kintex-7 FPGA 上自己设计一个 ARM-like 软 MCU。
```

因此：

```text
指令快慢不由 Cortex-M3/M4/M7 决定，
而由成员 2 设计的 MCU 微架构决定。
```

课程要求中提到：

```text
MCU 只能执行 ARM 指令集范围内的指令，不允许额外扩展指令。
MCU 微架构不限，可流水、并行、单指令多操作等优化。
```

但第一版先不追复杂优化。

## 3. 课程 FFT 任务要求

来自 `数字电路实验_MCU.pptx` 第 10-12 页。

FFT 任务要求：

```text
设计一个程序，在所设计 MCU 上完成 8 点 FFT 变换。
全部设计必须以 MCU 指令形式完成，不能做专用硬件芯片。
最后要求展示对应汇编指令。
```

输入输出：

```text
输入来自外部 test_ROM
输入线路名：test_vector_in
输入包含 8 个采样点，每个采样点包含实部和虚部
输入数据：16-bit 定点数

输出写入外部 verify_RAM
输出线路名：verify_vector_out
输出数据：16-bit 定点数
```

计时：

```text
从第一个数据读入开始，cnt_test 开始计数。
最后一个数据输出完成后停止计数。
最后时间 = cnt_test 计数 × 时钟周期。
```

验收：

```text
以上板结果为准，不以 simulation 结果为准。
Timing report 必须无 violation，WNS 必须为正。
```

## 4. 当前最新 MCU 接口

最新接口来自：

```text
/Users/eddz/Documents/Obsidian Vault/第一版MCU对成员A接口说明.md
```

当前第一版 MCU 约定如下。

### 4.1 总体宽度

```text
指令宽度：32-bit
地址宽度：32-bit
内部通用寄存器数量：16
内部通用寄存器宽度：32-bit
内部计算宽度：32-bit
寻址方式：统一字节寻址
```

注意：

```text
外部输入数据仍然是 16-bit signed
外部输出数据仍然是 16-bit signed
但 MCU 程序看到和处理的数据按 32-bit signed 理解
```

也就是：

```text
外部世界：16-bit
MCU 内部程序世界：32-bit
```

### 4.2 地址空间

第一版程序统一使用三个基址：

```text
INPUT_BASE   = 0x00000000
WORK_BASE    = 0x00000100
OUTPUT_BASE  = 0x00000200
```

含义：

```text
INPUT_BASE   对应外部 test_ROM
WORK_BASE    对应 MCU 内部工作 RAM
OUTPUT_BASE  对应外部 verify_RAM
```

成员 1 写程序时只需要按这三个基址写，不需要关心底层如何连接外部存储器。

### 4.3 数据访问规则

输入区：

```text
外部是 16-bit signed
程序视角输入槽位步长：+4
LDR 从输入区读到寄存器后，值已经是 32-bit signed
```

例子：

```asm
LDR R0, [R8 + 0]
LDR R1, [R8 + 4]
LDR R2, [R8 + 8]
```

工作区：

```text
内部工作 RAM 是 32-bit
工作区地址步长：+4
LDR/STR 读写 32-bit 数据
```

例子：

```asm
STR R0, [R9 + 0]
STR R1, [R9 + 4]
LDR R2, [R9 + 0]
```

输出区：

```text
外部 verify_RAM 按 16-bit 样本组织
程序视角输出槽位步长：+4
程序用 STR 写出 32-bit 结果
底层负责转换成外部需要的 16-bit
```

例子：

```asm
STR R0, [R10 + 0]
STR R1, [R10 + 4]
```

### 4.4 当前正式支持指令

第一版正式支持：

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

第一版不要依赖：

```text
BX
函数调用
栈
MLA
packed DSP 指令
批量访存
```

因此第一版 FFT 程序应写成：

```text
直线展开代码
少量或不用循环
不用函数调用
不用栈
不用 DSP packed 指令
```

### 4.5 推荐寄存器用途

```text
R0 ~ R7    当前运算数据与中间变量
R8         输入区基址或输入指针
R9         工作区基址或工作指针
R10        输出区基址或输出指针
R11        循环计数器或偏移
R12        常量寄存器，例如 23170
R13        预留
R14        BL 链接寄存器
R15        不作为普通寄存器使用
```

## 5. 当前算法决策

第一版 FFT 建议：

```text
8 点复数正向 FFT
radix-2 DIF
完全展开
real/imag 分开
内部 32-bit signed 计算
每级蝶形后除以 2
最终输出 = FFT(input) / 8
```

为什么每级除以 2：

```text
虽然内部是 32-bit，但 MUL 只返回 32-bit。
如果完全不缩放，旋转因子乘法前的中间值可能增大，存在溢出风险。
每级 ASR #1 缩放能保证安全，也便于输出到 16-bit。
```

旋转因子：

```text
W8^0 = 1
W8^1 =  0.7071 - j0.7071
W8^2 = -j
W8^3 = -0.7071 - j0.7071
```

Q15 常数：

```text
0.70710678 -> 23170
```

乘 0.7071 的写法。注意最新版指令格式是 `imm12`，不能单条 `MOV #23170`：

```asm
MOV R12, #4095
ADD R12, R12, #4095
ADD R12, R12, #4095
ADD R12, R12, #4095
ADD R12, R12, #4095
ADD R12, R12, #2695
MUL R4, R0, R12
ASR R4, R4, #15
```

含义：

```text
R4 = R0 * 23170 / 32768
   ≈ R0 * 0.70710678
```

输出顺序：

```text
DIF 最快自然输出是 bit-reversal：
X0, X4, X2, X6, X1, X5, X3, X7
```

如果验收要求自然序，只需调整最后写 OUTPUT_BASE 的顺序。

## 6. 已经创建的项目文件

项目目录：

```text
/Users/eddz/work/Digital_Circuits
```

已经创建的重要文件：

```text
/Users/eddz/work/Digital_Circuits/docs/member2_mcu_isa_plan.md
```

说明：

```text
给成员 2 的第一版 MCU 指令集方案。
已按 2026-06-02 最新接口修订：
基址 0x000 / 0x100 / 0x200，三个区域程序视角统一 +4 槽位步长，立即数遵守 imm12。
```

```text
/Users/eddz/work/Digital_Circuits/docs/fft8_arm_assembly_explained.md
```

说明：

```text
解释之前 ARMv7E-M DSP packed 版本的文档。
目前只作为第二版优化参考，不适合作为第一版 MCU 程序。
```

```text
/Users/eddz/work/Digital_Circuits/asm/fft8_dif_q15_armv7em.s
```

说明：

```text
高速 ARMv7E-M DSP 指令版。
使用 SHADD16/SHSUB16/SMUAD/SMUSD/PKHBT 等。
第一版 MCU 不能直接跑，只作为后续优化参考。
```

```text
/Users/eddz/work/Digital_Circuits/asm/fft8_basic_scalar_arm_pseudo.s
```

说明：

```text
早期基础标量草案。
它不完全匹配当前最新接口，也依赖宏和旧写法。
当前第一版应使用 fft8_v1_mcu32_basic.s。
```

```text
/Users/eddz/work/Digital_Circuits/tools/test_fft8_dif_q15.py
```

说明：

```text
用于验证旧 packed DSP 版本算法。
旧 packed DSP 版本对拍脚本。
当前第一版 MCU32 标量版本应使用 tools/test_fft8_v1_mcu32_basic.py。
```

## 7. 下一步详细计划

### 第一步：修订成员 2 指令集文档

文件：

```text
/Users/eddz/work/Digital_Circuits/docs/member2_mcu_isa_plan.md
```

状态：

```text
已完成。
已按最新接口修订为：
INPUT_BASE / WORK_BASE / OUTPUT_BASE = 0x000 / 0x100 / 0x200
输入区、工作区、输出区程序视角统一 +4
不依赖 BX / MLA
正式支持 MOV/ADD/SUB/AND/ORR/CMP/LDR/STR/B/BL/BEQ/BNE/MUL/ASR
```

### 第二步：编写第一版真正兼容接口的 FFT 汇编

文件：

```text
/Users/eddz/work/Digital_Circuits/asm/fft8_v1_mcu32_basic.s
```

要求：

```text
只使用 MOV/ADD/SUB/CMP/LDR/STR/B/BEQ/BNE/MUL/ASR
不使用 BX
不使用 BL（MCU 已支持 BL，但 FFT 主程序不需要函数调用）
不使用 MLA
不使用 LDM/STM
不使用 SHADD16/SHSUB16/SMUAD/SMUSD
```

数据格式：

```text
输入区：
  base + 0   x0.real  16-bit signed，LDR 后为 32-bit signed
  base + 4   x0.imag
  base + 8   x1.real
  base + 12  x1.imag
  ...

工作区：
  base + 0   临时 32-bit 数据
  base + 4   临时 32-bit 数据
  ...

输出区：
  base + 0   输出第 1 个 16-bit signed
  base + 4   输出第 2 个 16-bit signed
  ...
```

程序形态：

```text
完全展开 8 点 DIF FFT
每级用 ADD/SUB 后 ASR #1
乘 0.7071 用 MUL + ASR #15
最终写出 bit-reversal 顺序，或根据验收要求改自然序
```

状态：

```text
已完成。
当前版本使用最新基址和 +4 槽位步长。
23170 已拆成多条 imm12 安全指令构造。
```

### 第三步：新写 host-side 对拍脚本

文件：

```text
/Users/eddz/work/Digital_Circuits/tools/test_fft8_v1_mcu32_basic.py
```

脚本应模拟：

```text
输入外部 16-bit signed
LDR 后变成 32-bit signed
内部 32-bit 计算
每级缩放 /2
输出 FFT/8
输出转换成 16-bit signed
bit-reversal 输出顺序
```

用途：

```text
给成员 3 生成对拍样例
验证汇编算法是否正确
```

状态：

```text
已完成。
脚本会直接解释执行 asm/fft8_v1_mcu32_basic.s，并检查指令白名单、imm12、地址区和定点结果。
```

补充编码级检查：

```text
tools/assemble_mcu_v1.py 会按最新版机器码格式编码 asm/fft8_v1_mcu32_basic.s。
已生成 asm/fft8_v1_mcu32_basic.mem 和 asm/fft8_v1_mcu32_basic.lst。
当前 DONE: B DONE 位于 PC 0x0474，机器码为 0xE8FFFFFE，对应 PC+8 规则下 imm24 = -2。
```

最新验证规模：

```text
python3 tools/test_fft8_v1_mcu32_basic.py
  7 组边界/极值样例通过
  1000 组中等幅度随机样例通过
  5000 组完整 16-bit 范围随机样例通过

python3 tools/assemble_mcu_v1.py asm/fft8_v1_mcu32_basic.s
  286 条指令全部可编码
  DONE 自循环编码为 0xE8FFFFFE
```

## 0.1 2026-06-02 VHDL decoder 进展

已新增第一版 MCU 纯组合译码器：

```text
rtl/mcu_v1_decoder.vhd
```

对应 testbench：

```text
tb/mcu_v1_decoder_tb.vhd
```

说明文档：

```text
docs/mcu_v1_decoder_vhdl.md
```

decoder 支持：

```text
MOV / ADD / SUB / CMP / LDR / STR / B / BEQ / BNE / MUL / ASR
```

关键语义：

```text
cond: AL / EQ / NE
imm12: zero extend
imm24: sign_extend 后左移 2
branch_offset = sign_extend(imm24) << 2
顶层 PC 逻辑需要 pc_next = branch_taken ? PC + 8 + branch_offset : PC + 4
STR 使用 Rd 作为写内存数据源，即 decoder 输出 ra2 = Rd
CMP 只写 flags，不写寄存器
MUL 只支持寄存器型
ASR 只支持立即数型
```

本机已安装 GHDL，并通过仿真：

```text
ghdl -a --std=08 rtl/mcu_v1_decoder.vhd tb/mcu_v1_decoder_tb.vhd
ghdl -e --std=08 mcu_v1_decoder_tb
ghdl -r --std=08 mcu_v1_decoder_tb

结果：
mcu_v1_decoder_tb passed
simulation finished @13ns
```

## 0.2 2026-06-02 单周期 MCU baseline 进展

已新增最小单周期 MCU core：

```text
rtl/mcu_v1_alu.vhd
rtl/mcu_v1_regfile.vhd
rtl/mcu_v1_instr_rom.vhd
rtl/z90_mcu_v1_data_mem.vhd
rtl/z99_mcu_v1_core.vhd
```

对应 testbench：

```text
tb/mcu_v1_core_tb.vhd
```

说明文档：

```text
docs/mcu_v1_single_cycle_core.md
```

基础小测试程序：

```text
asm/test_mcu_v1_basic.s
asm/test_mcu_v1_basic.mem
asm/test_mcu_v1_basic.lst
```

当前 core 结构：

```text
PC -> instr_rom(组合读) -> decoder -> regfile(组合读/同步写)
   -> ALU -> data_mem(组合读/同步写) -> writeback -> PC update
```

支持：

```text
MOV / ADD / SUB / CMP / LDR / STR / B / BEQ / BNE / MUL / ASR
```

本机已通过 GHDL 仿真：

```text
ghdl -a --std=08 rtl/*.vhd tb/*.vhd
ghdl -e --std=08 mcu_v1_decoder_tb
ghdl -r --std=08 mcu_v1_decoder_tb
ghdl -e --std=08 mcu_v1_core_tb
ghdl -r --std=08 mcu_v1_core_tb

结果：
mcu_v1_decoder_tb passed
mcu_v1_core_tb passed
```

`mcu_v1_core_tb` 做了两类验证：

```text
1. 加载 asm/test_mcu_v1_basic.mem：
   输入 slot0=1000, slot1=-500
   输出 slot0=500, slot1=1500, slot2=707, slot3=123

2. 加载 asm/fft8_v1_mcu32_basic.mem：
   输入 x0.real=32760，其余为 0
   输出 8 个复数均为 real=4095, imag=0
   PC 停在 0x0474，halted_debug=1，illegal_debug=0
```

注意：

```text
当前 baseline 使用组合读 instr_rom / data_mem，适合功能仿真和小规模 distributed memory。
如果 Vivado 推成同步 BRAM，则严格单周期取指/LDR 会不成立，需要改多周期或指定 distributed memory。
```

### 第四步：整理给成员 3 的对拍规则

需要说明：

```text
正向 FFT
输出 = FFT/8
输出顺序默认 bit-reversal：X0, X4, X2, X6, X1, X5, X3, X7
输入/输出均按 real, imag, real, imag 排列
外部数据为 16-bit signed
```

状态：

```text
已完成。
见 docs/fft8_v1_mcu32_check_rules.md
```

## 8. 注意事项

1. 当前项目已经是 git 仓库。
2. 当前 baseline 已提交：

```text
commit 7f6b62e
message: baselne
branch: master
```

3. 旧 ARMv7E-M DSP 汇编只是第二版速度优化参考，不是当前第一版 MCU 目标。
4. 第一版 MCU 当前没有 `BX`，所以汇编末尾不要写 `BX LR`。当前程序使用：

```asm
DONE:
    B DONE
```

5. `DONE: B DONE` 在当前机器码中编码为 `0xE8FFFFFE`，对应 `PC + 8` 分支规则下的自循环。
6. `MUL` 必须按 signed 32-bit 乘法理解；`ASR` 必须是算术右移，不能用逻辑右移。
7. 当前单周期 core 是功能仿真 baseline：组合读 `instr_rom` / `data_mem`。Vivado 综合上板前要关注 ROM/RAM 是否被推成同步 BRAM。
8. 第一版不要追求 packed 16-bit，也不要上来用 DSP 指令。先跑通。

## 9. 当前一句话总结

当前状态：

```text
已经完成 first baseline：
1. 最新接口下的 8 点 FFT 汇编与机器码。
2. VHDL decoder。
3. 最小单周期 MCU core。
4. GHDL 功能仿真通过。
5. git commit: 7f6b62e baselne。
```

下一个对话建议从这里继续：

```text
1. 在 Vivado 中创建仿真工程，加入 rtl/*.vhd、tb/*.vhd 和 asm/*.mem。
2. 先跑 mcu_v1_decoder_tb。
3. 再跑 mcu_v1_core_tb。
4. 如果 Vivado 找不到 .mem，处理仿真工作目录或改 MEM_FILE 路径。
5. 仿真通过后，再决定是否做 Vivado-friendly ROM/RAM 或上板综合版本。
```
