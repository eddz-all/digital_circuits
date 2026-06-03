# FFT8 V5 ARM-Strict 59 Plan

更新时间：2026-06-03

本文档是 V5 的独立执行计划。V5 已在 `dsp` 分支实现并推送；实施完成后的结果文档见 `docs/fft8_v5_arm_strict_59.md`，接力状态见 `docs/session_memory_mcu_fft.md`。本文后续章节保留原计划内容，用于追溯目标、约束、候选汇编、RTL/assembler/testbench 改动和验收标准。

当前状态：

```text
V5 已落仓库实现，代码实现提交为 644d857。
当前 dsp / origin/dsp HEAD 为 f16aba0，其中包含 V5 push 后的 session memory 修正。
最终实现结果：78 instructions, 77 before DONE, 59 timed_steps。
最终交付前完整 V1-V5 回归已通过；后续若无共享 RTL 修改，不要一开始反复跑 V1/V2/V3/V4 checker。
```

## 1. 目标与硬约束

V5 名称建议：

```text
V5-arm-strict-59
```

目标：

```text
在 V4 ARM-strict exact 版基础上，把 timed_steps 从 78 降到 59。
V5 必须精确匹配当前 packed DSP fixed model。
```

硬约束：

```text
1. 汇编 mnemonic 必须是 ARM 真实存在的指令。
2. 不使用 FFT8 / CMULQ15 / ROTMJ / LDCPLX / STCPLX 等自创 mnemonic。
3. 保持单核、单发射、单周期；一条指令仍计一个 cnt。
4. 不能做输入直接接 FFT 电路、输出直接写 verify_RAM 的硬连旁路。
5. 不能采用 77 cycles risky 近似方案；所有结果必须 exact。
6. 不修改 V1/V2/V3/V4 汇编、`.mem`、`.lst`；V5 新增文件，公共 RTL/工具只做 additive 扩展。
7. 继续使用当前 packed complex 格式：low16 = real, high16 = imag。
```

基线：

```text
branch: dsp
V4 program: asm/fft8_v4_arm_strict.s
V4 timed_steps: 78
V4 DONE PC: 0x015C
```

V5 预期：

| 版本 | 指令数 | DONE 前执行指令数 | timed_steps | 50 MHz 估算速率 |
|---|---:|---:|---:|---:|
| V4 | 88 | 87 | 78 | 64.10 万次/秒 |
| V5 target | 78 | 77 | 59 | 84.75 万次/秒 |

速率公式：

```text
speed = clock_frequency / timed_steps
50 MHz / 59 = 847,457.63 次/秒 = 84.75 万次/秒
相对 V1: 276 / 59 = 4.68x
```

预计 DONE：

```text
DONE PC expected: 0x0134
DONE word remains: 0xE8FFFFFE
```

实际实现后必须以 assembler 输出为准更新文档和 testbench 断言。

## 2. 优化来源

V5 不是专用 FFT 硬件，也不是自定义 FFT 指令。它只做三件事：

```text
1. 寄存器重命名，消掉 V4 里 12 条 butterfly 后的 MOV。
2. 使用 ARM-real SMLAD + 32767 bias，把 W3 的 ASR 后取负 exact 压短 1 条。
3. 使用 ARM-real STMIA，把 8 条 STRD 输出压成 2 条批量存储。
```

已排除项：

```text
77 cycles risky:
  错误原因是把 W3 的负号提前到 ASR 前，改变负数算术右移舍入顺序。

FFT/complex/fixed-twiddle 自定义指令:
  违反 ARM-real mnemonic 和题目口径。

硬连 FFT 旁路:
  违反 MCU 按指令执行程序并由 cnt 统计时间的要求。
```

## 3. 新增 ARM-real 指令

V5 在 V4 的 `SSAX/SSUB16` 基础上新增两条 ARM 真实指令：

```text
SMLAD
STMIA
```

建议扩展类编码：

```text
EXT_SMLAD = 01010
EXT_STMIA = 01011
```

建议 ALU 控制码：

```text
ALU_SMLAD = 1111
```

当前 `ALU_SSAX = 1101`、`ALU_SSUB16 = 1110`，所以 `1111` 是自然剩余编码。

### 3.1 SMLAD

语法：

```asm
SMLAD Rd, Rn, Rm, Ra
```

语义：

```text
Rd = signed16(Rn.low16)  * signed16(Rm.low16)
   + signed16(Rn.high16) * signed16(Rm.high16)
   + Ra
```

实现口径：

```text
32-bit signed result, low 32-bit wrap/s32。
不更新 flags。
不实现 APSR.GE / Q flags。
```

V5 用法：

```asm
SMLAD R2, R7, R14, R11
```

其中：

```text
R7  = W3 输入 packed complex
R14 = negative twiddle {-23170,-23170}
R11 = 32767 bias
```

关键恒等式：

```text
-ASR(x, 15) = ASR(-x + 32767, 15)
```

因此 W3 中：

```asm
SMUAD R2, R7, R12
ASR R2, R2, #15
SUB R2, R13, R2
```

可以 exact 替换为：

```asm
SMLAD R2, R7, R14, R11
ASR R2, R2, #15
```

这不是 77-cycle 近似；它保持 ASR 后取负的 exact 数值。

### 3.2 STMIA

语法：

```asm
STMIA Rn!, {reglist}
```

语义：

```text
addr = Rn
for reg in reglist ascending:
  MEM[addr] = R[reg]
  addr += 4
Rn = addr
```

当前 MCU 实现口径：

```text
STMIA 仍是一条指令、一个 cnt。
寄存器列表按编号升序写出。
writeback 必须启用。
R15 不支持。
base register 不能出现在 reglist 中。
输出区 bulk store 与 STR/STRD 一样，只保存每个写入 word 的 low16 到 verify_RAM。
```

V5 用法：

```asm
STMIA R10!, {R0-R5,R11-R12}
STMIA R10!, {R0-R5,R11-R12}
```

每条写 8 个输出槽位。两条合计写完 16 个 real/imag 槽位。

这不是 custom complex store，因为：

```text
STMIA 不理解 complex。
STMIA 只是按普通 ARM store-multiple 顺序写多个 32-bit 寄存器。
imag 仍由普通 ASR 指令提前放到寄存器 low16。
verify_RAM 仍按当前 output_mem 规则保存 low16。
```

## 4. V5 候选汇编

新增文件建议：

```text
asm/fft8_v5_arm_strict_59.s
asm/fft8_v5_arm_strict_59.mem
asm/fft8_v5_arm_strict_59.lst
```

候选源代码如下。实现时可直接以此为起点：

```asm
; 8-point forward complex FFT, V5 ARM-strict 59 candidate.
;
; Constraints:
;   ARM-real mnemonic only.
;   single-core, single-issue, single-cycle.
;   exact packed DSP fixed model.
;
; Internal packed format:
;   low16 = real, high16 = imag.

START:
    MOV R14, #0
    MOV R13, #0

; twiddle +23170 packed in R12.
    MOV R12, #4095
    ADD R12, R12, #4095
    ADD R12, R12, #4095
    ADD R12, R12, #4095
    ADD R12, R12, #4095
    ADD R12, R12, #2695
    PKHBT R12, R12, R12, LSL #16

; bias 32767 in R11 for exact SMLAD W3 sign handling.
    MOV R11, #4095
    ADD R11, R11, #4095
    ADD R11, R11, #4095
    ADD R11, R11, #4095
    ADD R11, R11, #4095
    ADD R11, R11, #4095
    ADD R11, R11, #4095
    ADD R11, R11, #4095
    ADD R11, R11, #7

; Load and pack external real/imag slots into packed complex registers.
; The split preserves R11 bias and leaves enough temporary registers.
    LDMIA R14!, {R0-R10}
    PKHBT R0, R0, R1, LSL #16
    PKHBT R1, R2, R3, LSL #16
    PKHBT R2, R4, R5, LSL #16
    PKHBT R3, R6, R7, LSL #16
    PKHBT R4, R8, R9, LSL #16
    LDMIA R14!, {R5-R9}
    PKHBT R5, R10, R5, LSL #16
    PKHBT R6, R6, R7, LSL #16
    PKHBT R7, R8, R9, LSL #16
    SSUB16 R14, R13, R12

; Stage 1, butterfly (0,4), W8^0.
    SHADD16 R8, R0, R4
    SHSUB16 R4, R0, R4

; Stage 1, butterfly (1,5), W8^1.
    SHADD16 R9, R1, R5
    SHSUB16 R5, R1, R5
    SMUAD R0, R5, R12
    SMUSD R10, R5, R14
    ASR R0, R0, #15
    ASR R10, R10, #15
    PKHBT R5, R0, R10, LSL #16

; Stage 1, butterfly (2,6), W8^2 = -j.
    SHADD16 R0, R2, R6
    SHSUB16 R6, R2, R6
    SSAX R6, R13, R6

; Stage 1, butterfly (3,7), W8^3.
    SHADD16 R1, R3, R7
    SHSUB16 R7, R3, R7
    SMLAD R2, R7, R14, R11
    SMUSD R10, R7, R14
    ASR R10, R10, #15
    ASR R2, R2, #15
    PKHBT R7, R10, R2, LSL #16

; Stage 2.
    SHADD16 R2, R8, R0
    SHSUB16 R0, R8, R0

    SHADD16 R3, R9, R1
    SHSUB16 R1, R9, R1
    SSAX R1, R13, R1

    SHADD16 R8, R4, R6
    SHSUB16 R6, R4, R6

    SHADD16 R9, R5, R7
    SHSUB16 R7, R5, R7
    SSAX R7, R13, R7

; Output base. This remains timed because R10 is used as a temporary above.
    MOV R10, #512

; Final butterflies and first 8 output slots.
; Order after first STMIA:
;   R0 real0, R1 imag0, R2 real1, R3 imag1,
;   R4 real2, R5 imag2, R11 real3, R12 imag3
    SHADD16 R4, R0, R1
    SHSUB16 R11, R0, R1
    ASR R5, R4, #16
    ASR R12, R11, #16

    SHADD16 R0, R2, R3
    SHSUB16 R2, R2, R3
    ASR R1, R0, #16
    ASR R3, R2, #16

    STMIA R10!, {R0-R5,R11-R12}

; Final butterflies and last 8 output slots.
    SHADD16 R0, R8, R9
    SHSUB16 R2, R8, R9
    ASR R1, R0, #16
    ASR R3, R2, #16

    SHADD16 R4, R6, R7
    SHSUB16 R11, R6, R7
    ASR R5, R4, #16
    ASR R12, R11, #16

    STMIA R10!, {R0-R5,R11-R12}

DONE:
    B DONE
```

## 5. Cycle 预算

临时模型验证的 V5 预算：

```text
instructions before labels/comments: 78
instructions executed before DONE self-loop: 77
timed_steps from first input read through last output write: 59
```

拆分：

```text
输入/打包/负 twiddle:
  LDMIA x2
  PKHBT x8
  SSUB16 x1
  = 11 timed_steps

Stage 1 + Stage 2:
  butterfly SHADD16/SHSUB16 x8 pairs = 16
  W1 complex multiply = 5
  W3 complex multiply with SMLAD bias = 5
  -j rotations SSAX x3 = 3
  = 29 timed_steps

final butterflies + output:
  final butterfly SHADD16/SHSUB16 x4 pairs = 8
  ASR imag extraction x8 = 8
  STMIA x2 = 2
  MOV R10,#512 = 1
  = 19 timed_steps

total = 11 + 29 + 19 = 59
```

## 6. Assembler 修改计划

文件：

```text
tools/assemble_mcu_v1.py
```

增加：

```text
EXT_FUNCT["SMLAD"] = 0b01010
EXT_FUNCT["STMIA"] = 0b01011
```

`SMLAD` 编码建议：

```text
cond[31:28] = 1110
op[27:26] = 11
funct[25:21] = EXT_SMLAD
reserved[20] = 0
Rn[19:16]
Rd[15:12]
Ra[11:8]
reserved[7:4] = 0000
Rm[3:0]
```

Assembler 语法：

```asm
SMLAD Rd, Rn, Rm, Ra
```

格式检查：

```text
4 operands exactly.
all operands registers.
R15 unsupported as ordinary data register.
```

`STMIA` 编码建议：

```text
cond[31:28] = 1110
op[27:26] = 11
funct[25:21] = EXT_STMIA
W[20] = 1
Rn[19:16] = base register
regmask[15:0] = register list
```

Assembler 语法：

```asm
STMIA Rn!, {reglist}
```

格式检查：

```text
writeback required: Rn!
reglist non-empty.
R15 not supported.
base register cannot be in reglist.
```

## 7. Python Checker 修改计划

新增：

```text
tools/test_fft8_v5_arm_strict_59.py
```

建议从 `tools/test_fft8_v4_arm_strict.py` 派生。

白名单新增：

```text
SMLAD
STMIA
```

新增语义：

```python
def smlad(a, b, acc):
    return s32(lo16(a) * lo16(b) + hi16(a) * hi16(b) + acc)
```

`STMIA`：

```text
parse "STMIA Rn!, {reglist}"。
按 reglist 升序写连续 32-bit slots。
如果写 output region，只保存每个写入寄存器的 low16。
写完后 Rn += 4 * len(reglist)。
第一次写 output region 时仍计入 timed_steps。
```

V5 checker 必须断言：

```text
instructions before labels/comments = 78
executed before DONE = 77
timed_steps <= 59
```

同时继续保留：

```text
7 edge-case tests
1000 random moderate-amplitude tests
5000 random full-range packed-semantics tests
```

## 8. RTL 修改计划

### 8.1 Package

文件：

```text
rtl/00_mcu_v1_pkg.vhd
```

新增：

```text
ALU_SMLAD = "1111"
EXT_SMLAD = "01010"
EXT_STMIA = "01011"
```

### 8.2 Decoder

文件：

```text
rtl/mcu_v1_decoder.vhd
```

新增 decode：

```text
EXT_SMLAD:
  reg_write = cond_ok
  alu_control = ALU_SMLAD
  alu_src_imm = 0
  ra1 = Rn
  ra2 = Rm
  ra3 = Ra
  wa = Rd
  illegal if instr(20) != 0 or instr(7 downto 4) != x"0"

EXT_STMIA:
  mem_write = cond_ok
  bulk_store = cond_ok
  bulk_writeback = cond_ok
  reg_write = cond_ok
  ra1 = Rn
  wa = Rn
  bulk_regmask = regmask
  illegal if W != 1, reglist empty, R15 in reglist, or base in reglist
```

需要给 decoder 新增输出：

```text
bulk_store : out std_logic
```

`bulk_writeback` 可以复用给 `LDMIA/STMIA` 的 base writeback。

### 8.3 Regfile

文件：

```text
rtl/mcu_v1_regfile.vhd
```

SMLAD 需要 3 个源寄存器，当前 regfile 已有：

```text
ra1, ra2, ra3
rd1, rd2, rd3
```

STMIA 需要单周期读取 reglist 中最多 15 个寄存器。建议新增 bulk read 输出：

```text
bulk_rd : out std_logic_vector(511 downto 0)
```

语义：

```text
bulk_rd(32*i+31 downto 32*i) = regs(i)
```

这和现有 LDMIA 的 `bulk_wd` 方向相反，便于 core 按 regmask 组装连续 store 数据。

### 8.4 ALU

文件：

```text
rtl/mcu_v1_alu.vhd
```

SMLAD 需要 accumulator。建议 ALU entity 新增第三输入：

```text
c : in std_logic_vector(31 downto 0)
```

core 中连接：

```text
c => reg_rd3
```

所有现有 ALU 操作忽略 `c`。

新增 `ALU_SMLAD`：

```text
lo_prod = signed(a(15 downto 0)) * signed(b(15 downto 0))
hi_prod = signed(a(31 downto 16)) * signed(b(31 downto 16))
acc     = signed(c)
result  = low32(lo_prod + hi_prod + acc)
```

不更新特殊 flags。现有 `flag_z/flag_n` 可继续从 result 推导。

### 8.5 Core

文件：

```text
rtl/z99_mcu_v1_core.vhd
```

新增信号：

```text
bulk_store
reg_bulk_rd
bulk_store_data
```

SMLAD：

```text
ALU c input 接 reg_rd3。
```

STMIA 数据组装：

```text
bulk_store_data <= contiguous selected regs in regmask ascending order.
```

伪逻辑：

```text
data_index := 0
for reg_index in 0 to 15 loop
  if bulk_regmask(reg_index) = '1' then
    bulk_store_data(32*data_index+31 downto 32*data_index) <=
      reg_bulk_rd(32*reg_index+31 downto 32*reg_index)
    data_index := data_index + 1
  end if
end loop
```

Writeback：

```text
ldmia/stmia wb_data = reg_rd1 + 4 * popcount(bulk_regmask)
```

现有 `bulk_writeback` 可继续复用。

### 8.6 Data Memory / Work RAM / Output MEM

文件：

```text
rtl/z90_mcu_v1_data_mem.vhd
rtl/mcu_v1_work_ram.vhd
rtl/mcu_v1_output_mem.vhd
```

新增端口建议：

```text
bulk_store      : in std_logic
bulk_write_data : in std_logic_vector(511 downto 0)
bulk_regmask    : in std_logic_vector(15 downto 0)
```

也可以传 `bulk_count`，但直接传 `bulk_regmask` 并在 memory 内部 popcount 更贴近 decoder。

Work RAM bulk store：

```text
count = popcount(bulk_regmask)
for i in 0 to count-1:
  mem(slot + i) <= bulk_write_data(32*i+31 downto 32*i)
```

Output MEM bulk store：

```text
count = popcount(bulk_regmask)
for i in 0 to count-1:
  mem(slot + i) <= bulk_write_data(32*i+15 downto 32*i)
```

注意：

```text
STMIA 写 output region 仍只保存 low16，和 STR/STRD 一致。
不要让 output_mem 自动拆 high16；否则会变成 custom complex store。
```

## 9. Testbench 修改计划

### 9.1 ALU TB

文件：

```text
tb/mcu_v1_alu_tb.vhd
```

需要更新 ALU 实例，增加 `c` 输入。

新增 SMLAD 测试：

```text
a = pack(3, -4)
b = pack(5,  6)
c = 100
result = 3*5 + (-4)*6 + 100 = 91

边界/回绕:
a = pack(32767, -32768)
b = pack(32767, -32768)
c = 32767
检查 low32 结果。
```

### 9.2 Decoder TB

文件：

```text
tb/mcu_v1_decoder_tb.vhd
```

新增：

```text
SMLAD R2, R7, R14, R11:
  alu_control = ALU_SMLAD
  ra1 = R7
  ra2 = R14
  ra3 = R11
  wa = R2
  reg_write = 1

STMIA R10!, {R0-R5,R11-R12}:
  bulk_store = 1
  bulk_writeback = 1
  mem_write = 1
  reg_write = 1
  ra1 = R10
  wa = R10
  bulk_regmask matches R0-R5,R11-R12
```

非法格式测试：

```text
SMLAD reserved bit instr(20) = 1 -> illegal
SMLAD reserved instr(7 downto 4) != 0 -> illegal
STMIA without writeback -> illegal
STMIA empty reglist -> illegal
STMIA reglist includes R15 -> illegal
STMIA base in reglist -> illegal
```

### 9.3 Core TB

文件：

```text
tb/mcu_v1_core_tb.vhd
```

新增 `v5_core`：

```text
MEM_FILE => "asm/fft8_v5_arm_strict_59.mem"
ROM_DEPTH => 256
```

复用 V4 的两组断言：

```text
x0 impulse:
  x0.real = 32760
  others = 0
  all outputs real=4095 imag=0
  PC = actual DONE PC, expected 0x00000134 if assembler output matches plan
  halted_debug = 1
  illegal_debug = 0

x1 impulse:
  x1.real = 32760
  others = 0
  output slots:
    4095,0,-4095,0,0,-4095,0,4095,
    2895,-2896,-2896,2896,-2896,-2896,2896,2895
```

## 10. Documentation 更新计划

新增：

```text
docs/fft8_v5_arm_strict_59.md
```

更新：

```text
docs/fft8_experiment_results.md
docs/session_memory_mcu_fft.md
docs/mcu_v1_decoder_vhdl.md
docs/mcu_v1_single_cycle_core.md
docs/member2_mcu_isa_plan.md
```

V5 表格行：

```text
V5: 78 instructions, 77 before DONE, 59 timed_steps
50 MHz / 59 = 84.75 万次/秒
relative V1 = 4.68x
```

## 11. 验证策略

用户明确要求：

```text
下一个 session 不要一开始反复跑 V1/V2/V3/V4 checker。
V1/V2/V3/V4 汇编和生成物不改，日常实现 V5 时默认只跑 V5 局部验证。
```

因此 V5 开发时分两档验证。

### 11.1 日常迭代默认验证

Assembler：

```bash
python3 tools/assemble_mcu_v1.py asm/fft8_v5_arm_strict_59.s \
  --mem-out asm/fft8_v5_arm_strict_59.mem \
  --lst-out asm/fft8_v5_arm_strict_59.lst
```

V5 Python 对拍：

```bash
python3 tools/test_fft8_v5_arm_strict_59.py
```

V5 checker 必须通过：

```text
7 edge-case tests
1000 random moderate-amplitude tests
5000 random full-range packed-semantics tests
timed_steps <= 59
```

局部 GHDL：

```text
修改 SMLAD/ALU 时：
  跑 mcu_v1_alu_tb。

修改 decoder 时：
  跑 mcu_v1_decoder_tb。

修改 STMIA/core/data_mem 后：
  跑 mcu_v1_core_tb。
```

命令：

```bash
rm -rf /tmp/digital_circuits_ghdl08_v5
mkdir -p /tmp/digital_circuits_ghdl08_v5
ghdl -a --std=08 --workdir=/tmp/digital_circuits_ghdl08_v5 rtl/*.vhd tb/*.vhd
ghdl -e --std=08 --workdir=/tmp/digital_circuits_ghdl08_v5 -o /tmp/mcu_v1_alu_tb_08_v5 mcu_v1_alu_tb
/tmp/mcu_v1_alu_tb_08_v5
ghdl -e --std=08 --workdir=/tmp/digital_circuits_ghdl08_v5 -o /tmp/mcu_v1_decoder_tb_08_v5 mcu_v1_decoder_tb
/tmp/mcu_v1_decoder_tb_08_v5
ghdl -e --std=08 --workdir=/tmp/digital_circuits_ghdl08_v5 -o /tmp/mcu_v1_core_tb_08_v5 mcu_v1_core_tb
/tmp/mcu_v1_core_tb_08_v5
```

### 11.2 最终交付前回归

只有在以下情况才跑完整 V1-V5 回归：

```text
1. V5 已实现完成，准备交付最终结果。
2. 准备 commit/tag。
3. 怀疑共享 RTL 改动破坏了 V1/V2/V3/V4。
4. 用户明确要求完整回归。
```

最终 Python 回归：

```bash
python3 tools/test_fft8_v1_mcu32_basic.py
python3 tools/test_fft8_v2_packed_dsp.py
python3 tools/test_fft8_v3_arch_dsp.py
python3 tools/test_fft8_v4_arm_strict.py
python3 tools/test_fft8_v5_arm_strict_59.py
```

最终 Vivado 兼容口径：

```bash
rm -rf /tmp/digital_circuits_ghdl93
mkdir -p /tmp/digital_circuits_ghdl93
ghdl -a --std=93 -fsynopsys --workdir=/tmp/digital_circuits_ghdl93 rtl/*.vhd tb/*.vhd
ghdl -e --std=93 -fsynopsys --workdir=/tmp/digital_circuits_ghdl93 -o /tmp/mcu_v1_alu_tb_93_v5 mcu_v1_alu_tb
/tmp/mcu_v1_alu_tb_93_v5
ghdl -e --std=93 -fsynopsys --workdir=/tmp/digital_circuits_ghdl93 -o /tmp/mcu_v1_decoder_tb_93_v5 mcu_v1_decoder_tb
/tmp/mcu_v1_decoder_tb_93_v5
ghdl -e --std=93 -fsynopsys --workdir=/tmp/digital_circuits_ghdl93 -o /tmp/mcu_v1_core_tb_93_v5 mcu_v1_core_tb
/tmp/mcu_v1_core_tb_93_v5
```

## 12. 实施顺序建议

建议下一会话按这个顺序实现：

```text
1. 先确认 V4 当前工作区状态，避免误删未提交 V4 文件。
2. 新增 assembler 对 SMLAD/STMIA 的编码支持。
3. 新增 V5 checker，先让候选汇编在 Python 模型里通过。
4. 新增 V5 asm，生成 .mem/.lst，确认 DONE PC。
5. RTL 先做 SMLAD：package -> ALU -> decoder -> tests。
6. RTL 再做 STMIA：decoder -> regfile bulk read -> core bulk_store_data -> data_mem/work/output bulk store -> tests。
7. 更新 core TB 加 v5_core。
8. 跑 Python 和 GHDL 回归。
9. 最后更新 V5 完成文档、实验汇总和 session memory。
```

不要一开始就改 core TB，否则 SMLAD/STMIA decode 和 datapath 未完成时失败面太大。

## 13. 风险与注意事项

关键风险：

```text
SMLAD 是四寄存器指令，当前 ALU 只有 a/b 两个输入；需要新增 c 输入。
STMIA 是 bulk store，当前 data_mem 只有 bulk read 和 double write；需要新增真正的 bulk write path。
STMIA 需要 regfile 单周期 bulk read；当前只有 3 个普通读端口，建议新增 512-bit bulk_rd。
```

保持答辩口径：

```text
V5 仍是 MCU 按 ARM-real 汇编指令逐条执行 FFT。
STMIA 是普通 ARM store-multiple，不理解 FFT 或 complex。
SMLAD 是普通 ARM DSP multiply-accumulate，不是 fixed-twiddle 专用乘法。
输出 imag 仍由 ASR 放到 low16，output_mem 只保存 low16，接口口径不变。
```

当前不建议继续追低于 59：

```text
59 以下需要打破当前几个硬成本：
  12 个 butterfly 的 SHADD16/SHSUB16 下界
  W1/W3 两个 Q15 复乘的 ASR/PKHBT 下界
  8 个 imag ASR + 2 个 STMIA 输出下界

低于 59 大概率需要 custom complex output、fused Q15 complex multiply、
NEON/MVE 向量寄存器、多发射，或 FFT 硬件旁路；这些都不适合当前主线。
```
