# FFT8 V4 ARM-Strict Exact Plan

更新时间：2026-06-03

本文档是 V4 的独立执行计划。即使不读取 `docs/session_memory_mcu_fft.md`，也应能从本文恢复目标、约束、实现步骤和验收标准。

## 1. 目标与硬约束

V4 名称：

```text
V4-arm-strict-exact
```

目标：

```text
在 V3 ARM-safe architecture DSP 版基础上，把 timed_steps 从 88 降到 78。
V4 必须精确匹配当前 packed DSP fixed model，不接受 77 cycles 那类 ±1 舍入差异版本。
```

硬约束：

```text
1. 汇编 mnemonic 必须是 ARM 真实存在的指令。
2. 不使用 FFT8 / CMULQ15 / ROTMJ / LDCPLX / STCPLX 等自创 mnemonic。
3. 保持单核、单发射、单周期；一条指令仍计一个 cnt。
4. 不能做输入直接接 FFT 电路、输出直接写 verify_RAM 的硬连方案。
5. 不修改 V1/V2/V3 文件；V4 全部新增，公共 RTL 只 additive 支持新 ARM-real 指令。
6. 继续使用当前 packed complex 格式：low16 = real, high16 = imag。
```

当前基线：

```text
branch: dsp
baseline tag: v3-arm-safe-arch-dsp
V3 program: asm/fft8_v3_arch_dsp.s
V3 timed_steps: 88
```

V4 预期：

| 版本 | 指令数 | DONE 前执行指令数 | timed_steps | 150 MHz 估算速率 |
|---|---:|---:|---:|---:|
| V3 | 98 | 97 | 88 | 170.45 万次/秒 |
| V4 exact target | 88 | 87 | 78 | 192.31 万次/秒 |

速率公式：

```text
speed = clock_frequency / timed_steps
150 MHz / 78 = 1,923,076.92 次/秒 = 192.31 万次/秒
```

## 2. 指令与语义

V4 只新增两条 ARM SIMD/DSP 风格真实指令：

```text
SSAX
SSUB16
```

建议编码：

```text
op[27:26] = 11
funct[25:21]

01000 = SSAX
01001 = SSUB16
```

建议 ALU 控制码：

```text
ALU_SSAX   = "1101"
ALU_SSUB16 = "1110"
```

`SSAX Rd, Rn, Rm` 语义：

```text
lo = signed16(Rn.low16)  + signed16(Rm.high16)
hi = signed16(Rn.high16) - signed16(Rm.low16)
Rd.low16  = lo[15:0]
Rd.high16 = hi[15:0]
```

在 V4 中用于 `-j` 旋转：

```asm
SSAX Rx, R13, Rx
```

其中 `R13 = 0`，所以：

```text
low16  = imag
high16 = -real
```

这精确等价于 V3 的 4 条模板：

```asm
SXTH R8, Rx
ASR  R9, Rx, #16
SUB  R8, R13, R8
PKHBT Rx, R9, R8, LSL #16
```

`SSUB16 Rd, Rn, Rm` 语义：

```text
lo = signed16(Rn.low16)  - signed16(Rm.low16)
hi = signed16(Rn.high16) - signed16(Rm.high16)
Rd.low16  = lo[15:0]
Rd.high16 = hi[15:0]
```

在 V4 中用于构造负 twiddle：

```asm
SSUB16 R14, R13, R12
```

其中：

```text
R13 = {0,0}
R12 = {+23170,+23170}
R14 = {-23170,-23170}
```

实现注意：

```text
SSAX / SSUB16 不是饱和指令。
结果按 16-bit lane 截断/回绕，匹配当前 packed DSP lane 语义。
不需要实现 APSR.GE 标志；当前 MCU 不使用这些标志。
```

参考语义来源：

```text
ARM/CMSIS SIMD intrinsics:
https://arm-software.github.io/CMSIS_6/main/Core/group__intrinsic__SIMD__gr.html
```

## 3. 汇编替换方案

以 `asm/fft8_v3_arch_dsp.s` 为模板新增：

```text
asm/fft8_v4_arm_strict.s
asm/fft8_v4_arm_strict.mem
asm/fft8_v4_arm_strict.lst
```

不要修改 V3 源文件。

### 3.1 初始化阶段新增负 twiddle

V3 当前初始化和输入阶段：

```asm
MOV R14, #0
MOV R13, #0
MOV R12, #4095
ADD R12, R12, #4095
ADD R12, R12, #4095
ADD R12, R12, #4095
ADD R12, R12, #4095
ADD R12, R12, #2695
PKHBT R12, R12, R12, LSL #16

LDMIA R14!, {R0-R7}
...
LDMIA R14!, {R4-R11}
...
PKHBT R7, R10, R11, LSL #16
MOV R10, #512
```

V4 在第二条 `LDMIA` 和输入打包完成后，`R14` 不再需要作为输入指针。此时生成负 twiddle：

```asm
SSUB16 R14, R13, R12
MOV R10, #512
```

不要在第二条 `LDMIA` 之前覆盖 `R14`。

### 3.2 W1 复乘省 1 条

V3 W1 模板：

```asm
SMUAD R8, R5, R12
SMUSD R9, R5, R12
SUB R9, R13, R9
ASR R8, R8, #15
ASR R9, R9, #15
PKHBT R5, R8, R9, LSL #16
```

V4 替换为：

```asm
SMUAD R8, R5, R12
SMUSD R9, R5, R14
ASR R8, R8, #15
ASR R9, R9, #15
PKHBT R5, R8, R9, LSL #16
```

收益：

```text
6 -> 5，省 1 条。
```

### 3.3 W2 / W4 的 -j 旋转省 9 条

V3 有 3 处 `-j` 旋转模板，分别作用于 `R6`、`R3`、`R7`。

每处从：

```asm
SXTH R8, Rx
ASR R9, Rx, #16
SUB R8, R13, R8
PKHBT Rx, R9, R8, LSL #16
```

替换为：

```asm
SSAX Rx, R13, Rx
```

具体替换：

```asm
SSAX R6, R13, R6
SSAX R3, R13, R3
SSAX R7, R13, R7
```

收益：

```text
每处 4 -> 1，省 3 条。
3 处共省 9 条。
```

### 3.4 W3 复乘只省 real 分量取负

V3 W3 模板：

```asm
SMUAD R8, R7, R12
SMUSD R9, R7, R12
SUB R9, R13, R9
ASR R9, R9, #15
ASR R8, R8, #15
SUB R8, R13, R8
PKHBT R7, R9, R8, LSL #16
```

V4 替换为：

```asm
SMUAD R8, R7, R12
SMUSD R9, R7, R14
ASR R9, R9, #15
ASR R8, R8, #15
SUB R8, R13, R8
PKHBT R7, R9, R8, LSL #16
```

收益：

```text
7 -> 6，省 1 条。
```

不要把 `SMUAD R8, R7, R12` 改成负 twiddle 版本来删除后面的 `SUB R8, R13, R8`。

原因：

```text
V3 语义是 ASR(product, 15) 后再取负。
若改成先取负 product 再 ASR(product, 15)，负数算术右移的舍入方向不同，会出现 ±1 差异。
该 77 cycles 版本不符合 exact 对拍口径，不采用。
```

### 3.5 Cycle 预算

```text
V3 timed_steps = 88

SSAX 替换 3 处 -j:
  3 * (4 - 1) = 9 cycles saved

负 twiddle 优化:
  W1 省 1
  W3 省 1
  SSUB16 生成 R14 多 1
  net saved = 1

V4 exact timed_steps = 88 - 9 - 1 = 78
```

V4 预期 instruction count：

```text
V3 instructions before labels/comments = 98
V4 instructions before labels/comments = 88
V4 instructions executed before DONE self-loop = 87
V4 timed_steps from first input read through last output write = 78
DONE word remains 0xE8FFFFFE
DONE PC will change because program is shorter; assemble 后记录实际 PC。
```

## 4. RTL / assembler / checker 修改

新增 V4 时修改公共工具和 RTL，但保持 additive。

Assembler：

```text
tools/assemble_mcu_v1.py
  EXT_FUNCT 增加 SSAX=01000, SSUB16=01001
  SUPPORTED_OPS 自动包含两者
  encode_ext 对二元/三元寄存器格式复用普通 DSP 三寄存器编码
```

RTL：

```text
rtl/00_mcu_v1_pkg.vhd
  增加 ALU_SSAX / ALU_SSUB16
  增加 EXT_SSAX / EXT_SSUB16

rtl/mcu_v1_decoder.vhd
  decode EXT_SSAX / EXT_SSUB16
  格式约束同 SHADD16/SHSUB16：instr(20)=0 且 instr(11 downto 4)=x"00"

rtl/mcu_v1_alu.vhd
  实现 SSAX / SSUB16
  signed 16-bit lane 运算，结果截断到 16-bit lane
```

Python checker：

```text
tools/test_fft8_v4_arm_strict.py
  以 V3 checker 为基线复制新增
  WHITELIST 增加 SSAX / SSUB16
  execute loop 增加 SSAX / SSUB16 语义
  target timed_steps <= 78
```

Testbench：

```text
tb/mcu_v1_alu_tb.vhd
  增加 SSAX / SSUB16 lane 边界测试

tb/mcu_v1_decoder_tb.vhd
  增加 SSAX / SSUB16 decode 测试

tb/mcu_v1_core_tb.vhd
  新增 v4_core，MEM_FILE = asm/fft8_v4_arm_strict.mem
  复用 x0 impulse 和 x1 impulse 输出断言
```

文档：

```text
docs/fft8_v4_arm_strict.md
  记录目标、指令、替换点、cycle 预算和验证结果

docs/fft8_experiment_results.md
  增加 V4 实验数据

docs/session_memory_mcu_fft.md
  实现完成后更新 V4 状态、commit/tag 和回归结果
```

## 5. 不采用项

以下方向已审查，V4 exact 不采用：

```text
1. 77 cycles risky 版
   原因：需要把 W3 某个负号提前到 ASR 前，会造成 ±1 舍入差异。

2. 其他乘加/乘减类复乘候选
   原因：当前模板里不能消掉关键 ASR / PKHBT，基本只会 1:1 替换 SMUAD/SMUSD。

3. SHASX / SHSAX / QASX / QSAX
   原因：半字交叉公式不能直接合并当前 -j(diff) 目标；Q 类还会引入饱和语义风险。

4. 批量输出 store
   原因：输出 memory 只取每个写入寄存器 low16；packed imag 仍需先 ASR 拆出。
   为批量输出准备 16 个 real/imag 寄存器的成本吃掉 store 收益。

5. 自定义 complex load/store 或 fixed-twiddle 指令
   原因：违反 ARM-real mnemonic / 不自创指令约束。
```

## 6. 验收步骤

实现后必须执行：

```bash
python3 tools/assemble_mcu_v1.py asm/fft8_v4_arm_strict.s --mem-out asm/fft8_v4_arm_strict.mem --lst-out asm/fft8_v4_arm_strict.lst
python3 tools/test_fft8_v1_mcu32_basic.py
python3 tools/test_fft8_v2_packed_dsp.py
python3 tools/test_fft8_v3_arch_dsp.py
python3 tools/test_fft8_v4_arm_strict.py
```

GHDL 回归：

```bash
ghdl -a --std=08 rtl/*.vhd tb/*.vhd
ghdl -e --std=08 mcu_v1_alu_tb && ghdl -r --std=08 mcu_v1_alu_tb
ghdl -e --std=08 mcu_v1_decoder_tb && ghdl -r --std=08 mcu_v1_decoder_tb
ghdl -e --std=08 mcu_v1_core_tb && ghdl -r --std=08 mcu_v1_core_tb
```

Vivado 兼容口径回归：

```bash
rm -rf /tmp/digital_circuits_ghdl93
mkdir -p /tmp/digital_circuits_ghdl93
ghdl -a --std=93 -fsynopsys --workdir=/tmp/digital_circuits_ghdl93 rtl/*.vhd tb/*.vhd
ghdl -e --std=93 -fsynopsys --workdir=/tmp/digital_circuits_ghdl93 mcu_v1_alu_tb
ghdl -r --std=93 -fsynopsys --workdir=/tmp/digital_circuits_ghdl93 mcu_v1_alu_tb
ghdl -e --std=93 -fsynopsys --workdir=/tmp/digital_circuits_ghdl93 mcu_v1_decoder_tb
ghdl -r --std=93 -fsynopsys --workdir=/tmp/digital_circuits_ghdl93 mcu_v1_decoder_tb
ghdl -e --std=93 -fsynopsys --workdir=/tmp/digital_circuits_ghdl93 mcu_v1_core_tb
ghdl -r --std=93 -fsynopsys --workdir=/tmp/digital_circuits_ghdl93 mcu_v1_core_tb
```

V4 checker 必须通过：

```text
7 edge-case tests
1000 random moderate-amplitude tests
5000 random full-range packed-semantics tests
V4 timed_steps <= 78
```

期望输出：

```text
V1 timed_steps = 276
V2 timed_steps = 109
V3 timed_steps = 88
V4 timed_steps = 78
```

## 7. 完成后的保存点

实现通过后：

```bash
git status --short --branch
git add ...
git commit -m "add v4 arm strict exact fft optimization"
git tag v4-arm-strict-exact
git push origin dsp
git push origin v4-arm-strict-exact
```

提交前确认：

```text
V1/V2/V3 无退化。
V4 不包含自创 mnemonic。
V4 不包含 77 cycles risky 近似替换。
docs/session_memory_mcu_fft.md 已更新到 V4 完成状态。
```
