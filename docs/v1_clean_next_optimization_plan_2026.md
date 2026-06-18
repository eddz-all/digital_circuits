# V1 Clean Next Optimization Plan 2026

更新时间：2026-06-18

本文档给下一次 Codex 会话使用。目标是在 `codex/v1-clean` 分支上，继续研究并实现
ARM 合法指令约束下的下一步指令数和 `cnt_cycles` 压缩。

## 1. 不变约束

下一会话开始时必须先确认：

```bash
git status --short --branch
git branch --show-current
```

目标分支必须是：

```text
codex/v1-clean
```

禁止事项：

```text
不要切到 master。
不要 merge。
不要 commit。
不要 push。
不要运行 Vivado/xsim/综合/实现/bitstream/板卡/JTAG/XDC。
不要删除 测试数据样例-2026/。
不要改变老师 I/O 合约。
不要改变输出顺序。
不要把 timed_steps、cycles_to_halt、cnt_cycles 混成同一个指标。
```

ISA 边界：

```text
只能使用真实 ARM 或 ARM DSP/Thumb-2 风格中已有、可解释为 ARM-like 的指令。
不要发明 PACKQ、STMIAH、FFT 专用指令或任何无法对应 ARM 语义的自定义指令。
FFT 仍必须由 MCU 指令序列执行，不能用专用 FFT 硬件绕过指令执行。
```

建议使用的 skill：

```text
mac-asm-algorithm
mac-vhdl-rtl
mac-ghdl-verification
```

## 2. 当前基线

当前已验证口径：

```text
static instructions = 106
instructions before DONE self-loop = 105
host timed_steps = 100

single-cycle system:
mcu_fft_system_tb cnt_cycles = 138

pipe5 independent core:
mcu_v1_core_pipe5_tb cycles_to_halt = 108

pipe5 system wrapper:
mcu_fft_system_pipe5_tb cnt_cycles = 124
```

当前 pipe5 system 统计：

```text
core_cycles = 108
issued = 106
load_use_stalls = 0
bulk_load_stalls = 0
flag_stalls = 0
branch_flushes = 0
halt_events = 1
fixed_fill_drain_cycles = 1
dump_write_cycles = 16
wrapper_transition_cycles = 0
overlapped_input_load_cycles = 16
```

当前 segment 统计：

```text
prologue = 5
input_load_scale = 40
stage1 = 12
stage2 = 14
stage3_butterfly = 13
twiddle_multiply = 10
output_store = 11
done_halt = 1
```

当前输入打包模式：

```asm
LDR real, [R8 + real_addr]
LDR imag, [R8 + imag_addr]
LSL real, real, #7
LSL imag, imag, #7
PKHBT packed, real, imag, LSL #16
```

当前 twiddle repack 模式：

```asm
SMUAD/SMUSD tmp_real, value, coeff
SMUSD/SMUAD tmp_imag, value, coeff
ASR tmp_real, tmp_real, #7
ASR tmp_imag, tmp_imag, #7
PKHBT value, tmp_real, tmp_imag, LSL #16
```

## 3. 上一轮审计结论

不建议实现：

```text
PKHTB:
  真实 ARM 指令，但在当前输出路径中只能 1 条替代 1 条 ASR #16，
  不能减少指令数。

STRH:
  真实 ARM 指令，但当前 output_mem 是 32-bit slot、地址步长 +4，
  且已经用 STMIA 一条写 8 个 output slot。STRH 会退化成多条 store；
  如果改成 halfword 连续地址，会改变当前 memory/address 口径。

LDMIA:
  真实 ARM 指令，但 2026 输入是 real window / imag window 分离，
  不是 interleaved complex。ARM reglist 又按寄存器编号升序 load，
  不能直接表达当前 bit-reversed 复数加载顺序。实现 multi-register load
  还会引入多写口或 bulk-load 写回风险。
```

建议优先实现：

```text
扩展现有 PKHBT 到真实 ARM 语义：
PKHBT Rd, Rn, Rm, LSL #imm
```

理由：

```text
ARM PKHBT 本身支持 LSL #shift。
当前 MCU 子集只实现了 PKHBT ... LSL #16。
把 #16 放宽为 #imm 是扩展现有真实 ARM 指令语义，不是发明新指令。
```

## 4. 核心优化思路

### 4.1 输入 imag 缩放合并进 PKHBT

当前每个输入复数：

```asm
LDR R0, [R8 + 512]
LDR R14, [R8 + 544]
LSL R0, R0, #7
LSL R14, R14, #7
PKHBT R0, R0, R14, LSL #16
```

可改成：

```asm
LDR R0, [R8 + 512]
LDR R14, [R8 + 544]
LSL R0, R0, #7
PKHBT R0, R0, R14, LSL #23
```

正确性依据：

```text
LDR 读入的 Q5 input 是 sign-extended 32-bit。
PKHBT 的 high halfword 来自 (Rm << shift)[31:16]。
当 shift = 23 时，high halfword 等于原 imag Q5 左移 7 后的 low16。
Q5 输入范围约为 [-32, 31]，左移 7 后仍在 16-bit Q12 范围内。
```

收益：

```text
每个复数删 1 条 LSL imag。
8 个复数共删 8 条指令。
```

### 4.2 twiddle imag ASR 合并进 PKHBT

当前 W8^1 / W8^3 repack：

```asm
SMUAD R14, R5, R12
SMUSD R15, R5, R13
ASR R14, R14, #7
ASR R15, R15, #7
PKHBT R5, R14, R15, LSL #16
```

可改成：

```asm
SMUAD R14, R5, R12
SMUSD R15, R5, R13
ASR R14, R14, #7
PKHBT R5, R14, R15, LSL #9
```

第二处 W8^3 同理：

```asm
SMUSD R14, R7, R13
SMUAD R15, R7, R13
ASR R14, R14, #7
PKHBT R7, R14, R15, LSL #9
```

正确性依据：

```text
当前 imag 路径需要 low16(ASR(R15, 7)) 放进 packed high16。
PKHBT high halfword = (R15 << 9)[31:16]。
这等价于取 R15 原值 bits[22:7]，也就是 ASR #7 结果的 low16。
对 two's-complement 负数也成立，因为最终只取 ASR 后的 low16。
```

收益：

```text
两处 twiddle repack 各删 1 条 ASR imag。
共删 2 条指令。
```

### 4.3 预期总收益

预期静态变化：

```text
static instructions: 106 -> 96
instructions before DONE: 105 -> 95
```

预期 host 变化：

```text
timed_steps: 100 -> 90
```

预期 GHDL cycle 变化：

```text
single-cycle system cnt_cycles: 138 -> 约 128
pipe5 independent cycles_to_halt: 108 -> 约 98
pipe5 system cnt_cycles: 124 -> 约 114
```

这些数字是实现前估算，必须以 GHDL 和 checker 实测为准。

预期 pipe5 segment 变化：

```text
prologue = 5
input_load_scale = 32
stage1 = 12
stage2 = 14
stage3_butterfly = 13
twiddle_multiply = 8
output_store = 11
done_halt = 1
total issued = 96
```

## 5. 实现计划

### Phase 0: 重新确认基线

先运行：

```bash
git status --short --branch
git branch --show-current
python3 tools/assemble_mcu_v1.py asm/fft8_v1_mcu32_basic.s
python3 tools/test_fft8_v1_mcu32_basic.py
```

确认：

```text
branch = codex/v1-clean
worktree 状态先记录，不要覆盖用户改动
assembler 当前输出 106 instructions, DONE at PC 0x01A4
checker 当前 teacher sample passed, 100 random passed, timed_steps = 100
```

### Phase 1: 扩展 assembler/checker

修改：

```text
tools/assemble_mcu_v1.py
tools/test_fft8_v1_mcu32_basic.py
```

assembler 计划：

```text
1. PKHBT 继续要求第 4 个 operand 是 LSL #imm。
2. 允许 imm = 0..31，而不是只接受 #16。
3. 在当前 OP_EXT 编码里把 shift 放入 instr(11 downto 7)。
4. 保持 instr(6 downto 4) = "000"，Rm 仍放 instr(3 downto 0)。
5. 现有 PKHBT #16 会重新编码，但语义不变。
```

checker 计划：

```text
1. pkhbt(low_value, high_value, shift)。
2. 语义：
   result.low16 = low_value[15:0]
   result.high16 = (high_value << shift)[31:16]
3. 解析 PKHBT 的 LSL #imm。
4. 增加内部或后续 TB 覆盖 #9/#16/#23。
```

Phase 1 完成后先跑：

```bash
python3 tools/assemble_mcu_v1.py asm/fft8_v1_mcu32_basic.s
python3 tools/test_fft8_v1_mcu32_basic.py
```

此时 asm 还没改，预期结果仍应保持 106 / 105 / 100。

### Phase 2: 扩展 RTL 解码和 ALU

修改：

```text
rtl/mcu_v1_decoder.vhd
rtl/mcu_v1_alu.vhd
rtl/mcu_v1_core.vhd
rtl/mcu_v1_core_pipe5.vhd
tb/mcu_v1_decoder_tb.vhd
```

decoder 计划：

```text
1. EXT_PKHBT 不再要求 instr(11 downto 4) = x"00"。
2. 改为要求 instr(6 downto 4) = "000"。
3. shift_imm = instr(11 downto 7)。
4. imm_ext 输出 shift_imm zero-extend 到 32-bit。
5. PKHBT 仍读 ra1=Rn、ra2=Rm，不读 ra3。
```

ALU 计划：

```text
1. ALU_PKHBT 使用 c(4 downto 0) 作为 shift amount。
2. 语义：
   result <= shifted_b(31 downto 16) & a(15 downto 0)
   where shifted_b = shift_left(unsigned(b), to_integer(unsigned(c(4 downto 0))))
3. 对 #16 应完全兼容当前行为。
```

single-cycle core 计划：

```text
1. 增加 alu_c mux。
2. 当 alu_control = ALU_PKHBT 时，alu_c <= imm_ext。
3. 其他指令保持 alu_c <= reg_rd3，保证 SMLAD 仍用第三源寄存器。
```

pipe5 core 计划：

```text
1. ID/EX 阶段保存 PKHBT shift immediate 到 id_ex_op3。
2. 当 dec_alu_control = ALU_PKHBT 时，id_ex_op3 <= dec_imm_ext。
3. 其他指令 id_ex_op3 仍来自 reg_rd3，并保留现有 forwarding。
4. dec_read_ra3 对 PKHBT 继续为 0。
```

decoder TB 计划：

```text
1. 保留现有 PKHBT #16 测试。
2. 增加 PKHBT #23 或 #9 测试：
   - illegal_instr = 0
   - alu_control = ALU_PKHBT
   - ra1/ra2/wa 正确
   - imm_ext = 23 或 9
```

Phase 2 完成后跑：

```bash
rm -rf /tmp/digital_circuits_ghdl_pkhbt_shift
mkdir -p /tmp/digital_circuits_ghdl_pkhbt_shift

ghdl -a --std=08 --workdir=/tmp/digital_circuits_ghdl_pkhbt_shift \
  rtl/mcu_v1_alu.vhd \
  rtl/mcu_v1_decoder.vhd \
  rtl/mcu_v1_data_mem.vhd \
  rtl/mcu_v1_regfile.vhd \
  rtl/mcu_v1_instr_rom.vhd \
  rtl/mcu_v1_core.vhd \
  tb/mcu_v1_decoder_tb.vhd \
  tb/mcu_v1_core_tb.vhd

ghdl -e --std=08 --workdir=/tmp/digital_circuits_ghdl_pkhbt_shift mcu_v1_decoder_tb
ghdl -r --std=08 --workdir=/tmp/digital_circuits_ghdl_pkhbt_shift mcu_v1_decoder_tb --assert-level=error
```

### Phase 3: 修改 asm 并重新生成 ROM

修改：

```text
asm/fft8_v1_mcu32_basic.s
asm/fft8_v1_mcu32_basic.mem
asm/fft8_v1_mcu32_basic.lst
rtl/mcu_v1_instr_rom.vhd
```

asm 修改：

```text
1. 删除 8 条 input imag LSL：
   LSL R14, R14, #7

2. 对应 8 条 input PKHBT 改为：
   PKHBT Rx, Rx, R14, LSL #23

3. 删除两条 twiddle imag ASR：
   ASR R15, R15, #7

4. 对应 twiddle PKHBT 改为：
   PKHBT R5, R14, R15, LSL #9
   PKHBT R7, R14, R15, LSL #9
```

重新生成：

```bash
python3 tools/assemble_mcu_v1.py asm/fft8_v1_mcu32_basic.s \
  --mem-out asm/fft8_v1_mcu32_basic.mem \
  --lst-out asm/fft8_v1_mcu32_basic.lst
```

预期：

```text
encoded 96 instructions
DONE PC 会前移 40 bytes，预计从 0x01A4 到 0x017C
```

然后用 `.mem` 机械更新：

```text
rtl/mcu_v1_instr_rom.vhd 的 init_fft_rom
```

不要忘记同步 board-facing 副本：

```text
BOARD_TOP/asm/fft8_v1_mcu32_basic.s
BOARD_TOP/asm/fft8_v1_mcu32_basic.mem
BOARD_TOP/asm/fft8_v1_mcu32_basic.lst
BOARD_TOP/BOARD_TOP.srcs/sources_1/new/instr_rom.vhd
BOARD_TOP/BOARD_TOP.srcs/sources_1/new/alu.vhd
BOARD_TOP/BOARD_TOP.srcs/sources_1/new/decoder.vhd
BOARD_TOP/BOARD_TOP.srcs/sources_1/new/mcu_core.vhd

BOARD_BASIC_TEST/asm/fft8_v1_mcu32_basic.s
BOARD_BASIC_TEST/asm/fft8_v1_mcu32_basic.mem
BOARD_BASIC_TEST/asm/fft8_v1_mcu32_basic.lst
BOARD_BASIC_TEST/BOARD_BASIC_TEST.srcs/sources_1/new/instr_rom.vhd
BOARD_BASIC_TEST/BOARD_BASIC_TEST.srcs/sources_1/new/alu.vhd
BOARD_BASIC_TEST/BOARD_BASIC_TEST.srcs/sources_1/new/decoder.vhd
BOARD_BASIC_TEST/BOARD_BASIC_TEST.srcs/sources_1/new/mcu_core.vhd
```

### Phase 4: 更新 pipe5 PC 分段统计

修改：

```text
rtl/mcu_v1_core_pipe5.vhd
tb/mcu_v1_core_pipe5_tb.vhd
```

要求：

```text
1. 不要凭旧 PC 直接猜。
2. 先查看新的 asm/fft8_v1_mcu32_basic.lst。
3. 用新的 PC 范围更新 segment_stats 分类。
4. tb/mcu_v1_core_pipe5_tb.vhd 中 DONE PC 也要跟新 .lst 对齐。
```

预期 segment count：

```text
prologue = 5
input_load_scale = 32
stage1 = 12
stage2 = 14
stage3_butterfly = 13
twiddle_multiply = 8
output_store = 11
done_halt = 1
```

### Phase 5: 必跑验证

host：

```bash
python3 tools/test_fft8_v1_mcu32_basic.py
```

必须看到：

```text
teacher sample passed
100 random Q5 signal tests passed
96 instructions before labels/comments
95 instructions executed before DONE self-loop
90 instructions from first input read through last output write
```

single-cycle GHDL：

```bash
rm -rf /tmp/digital_circuits_ghdl_pkhbt_shift
mkdir -p /tmp/digital_circuits_ghdl_pkhbt_shift

ghdl -a --std=08 --workdir=/tmp/digital_circuits_ghdl_pkhbt_shift \
  rtl/mcu_v1_alu.vhd \
  rtl/mcu_v1_decoder.vhd \
  rtl/mcu_v1_data_mem.vhd \
  rtl/mcu_v1_regfile.vhd \
  rtl/mcu_v1_instr_rom.vhd \
  rtl/mcu_v1_core.vhd \
  rtl/mcu_fft_system.vhd \
  tb/mcu_v1_decoder_tb.vhd \
  tb/mcu_v1_core_tb.vhd \
  tb/mcu_fft_system_tb.vhd

ghdl -e --std=08 --workdir=/tmp/digital_circuits_ghdl_pkhbt_shift mcu_v1_decoder_tb
ghdl -r --std=08 --workdir=/tmp/digital_circuits_ghdl_pkhbt_shift mcu_v1_decoder_tb --assert-level=error

ghdl -e --std=08 --workdir=/tmp/digital_circuits_ghdl_pkhbt_shift mcu_v1_core_tb
ghdl -r --std=08 --workdir=/tmp/digital_circuits_ghdl_pkhbt_shift mcu_v1_core_tb --assert-level=error

ghdl -e --std=08 --workdir=/tmp/digital_circuits_ghdl_pkhbt_shift mcu_fft_system_tb
ghdl -r --std=08 --workdir=/tmp/digital_circuits_ghdl_pkhbt_shift mcu_fft_system_tb --assert-level=error
```

pipe5 GHDL：

```bash
ghdl -a --std=08 --workdir=/tmp/digital_circuits_ghdl_pkhbt_shift \
  rtl/mcu_v1_core_pipe5.vhd \
  rtl/mcu_fft_system_pipe5.vhd \
  tb/mcu_v1_core_pipe5_tb.vhd \
  tb/mcu_fft_system_pipe5_tb.vhd

ghdl -e --std=08 --workdir=/tmp/digital_circuits_ghdl_pkhbt_shift mcu_v1_core_pipe5_tb
ghdl -r --std=08 --workdir=/tmp/digital_circuits_ghdl_pkhbt_shift mcu_v1_core_pipe5_tb --assert-level=error

ghdl -e --std=08 --workdir=/tmp/digital_circuits_ghdl_pkhbt_shift mcu_fft_system_pipe5_tb
ghdl -r --std=08 --workdir=/tmp/digital_circuits_ghdl_pkhbt_shift mcu_fft_system_pipe5_tb --assert-level=error
```

预期结果：

```text
mcu_fft_system_tb cnt_cycles ~= 128
mcu_v1_core_pipe5_tb cycles_to_halt ~= 98
mcu_fft_system_pipe5_tb cnt_cycles ~= 114
```

最后跑：

```bash
git diff --check
git status --short --branch
```

## 6. 成功标准

必须全部满足：

```text
1. 新增语义可解释为真实 ARM PKHBT LSL #imm。
2. 没有新增 PACKQ、STMIAH、FFT 专用硬件或 ARM 外自定义指令。
3. teacher sample 逐项匹配。
4. 100 random Q5 signal tests 通过。
5. mcu_v1_decoder_tb 通过。
6. mcu_v1_core_tb 通过。
7. mcu_fft_system_tb 通过。
8. mcu_v1_core_pipe5_tb 通过。
9. mcu_fft_system_pipe5_tb 通过。
10. BOARD_TOP 和 BOARD_BASIC_TEST 副本同步。
11. 不提交、不推送，除非用户明确要求。
```

建议最终报告格式：

```text
changed files:
  ...

current metrics:
  static instructions = ...
  instructions before DONE = ...
  host timed_steps = ...
  single-cycle system cnt_cycles = ...
  pipe5 independent cycles_to_halt = ...
  pipe5 system cnt_cycles = ...

pipe5 stats:
  issued = ...
  load_use_stalls = ...
  bulk_load_stalls = ...
  flag_stalls = ...
  branch_flushes = ...
  halt_events = ...
  fixed_fill_drain_cycles = ...

before/after:
  ...

remaining risk:
  ...
```

## 7. 风险和回滚条件

风险 1：PKHBT shift immediate 接线误伤 SMLAD 的第三源。

规避：

```text
SMLAD 必须继续使用 reg_rd3 / forwarded op3。
只有 ALU_PKHBT 使用 imm_ext 作为 c/shift source。
```

风险 2：negative value 的 shift/pack 语义实现错。

规避：

```text
checker 中用 bit-level 语义实现 PKHBT：
high16 = ((value << shift) & 0xFFFF0000) >> 16
不要用有符号除法或 Python 算术右移替代 LSL 语义。
RTL 中对 b 做 unsigned shift_left，再取 shifted_b(31 downto 16)。
```

风险 3：pipe5 segment PC 范围陈旧。

规避：

```text
必须从新的 .lst 重算 PC 范围。
segment total 必须等于 issue_count。
```

风险 4：新增 variable PKHBT shift 可能增加 ALU 组合路径。

判断：

```text
在当前 Mac/GHDL 工作流下只能做功能验证，不能声称 Fmax 改善。
如果用户后续要求 timing，才进入 Vivado/timing 证据流程。
```

回滚条件：

```text
1. checker 输出不匹配 teacher sample。
2. random Q5 出现 mismatch。
3. GHDL 任一必跑 TB 失败且不能快速定位。
4. 为了实现它必须引入非 ARM 指令或专用硬件。
```

如果触发回滚，保留审计结论，但不要强行合入。回退到当前 LSL + PKHBT #16 版本，并把
失败原因记录到 handoff 文档。

## 8. 如果 PKHBT #imm 成功后的下一步

成功后，继续压指令的边际会明显下降。下一步优先级建议：

```text
1. 先更新 handoff / next-session prompt / check rules 中的真实计数。
2. 再评估 pipe5/Fmax 风险，而不是继续盲目加指令。
3. 若仍要压指令，只考虑真实 ARM 指令且一次至少能减少 3 条以上的方案。
4. 不建议继续投入 PKHTB、STRH、LDMIA，除非新的证据显示它们能带来明确 system cnt_cycles 收益。
```

## 9. 下一会话可直接复制的首条提示词

```text
请用中文协作。工作目录：

/Users/eddz/work/Digital_Circuits

只在 codex/v1-clean 分支工作，不要切 master，不要 merge，不要 commit，不要 push。
使用 mac-asm-algorithm、mac-vhdl-rtl、mac-ghdl-verification。

先确认：

git status --short --branch
git branch --show-current

先读：

docs/v1_clean_next_optimization_plan_2026.md
docs/v1_clean_dsp_handoff_2026.md
docs/v1_clean_next_session_prompt_2026.md
docs/fft8_v1_mcu32_check_rules.md
asm/fft8_v1_mcu32_basic.s
tools/assemble_mcu_v1.py
tools/test_fft8_v1_mcu32_basic.py
rtl/mcu_v1_alu.vhd
rtl/mcu_v1_decoder.vhd
rtl/mcu_v1_core.vhd
rtl/mcu_v1_core_pipe5.vhd
rtl/mcu_fft_system.vhd
rtl/mcu_fft_system_pipe5.vhd
tb/mcu_v1_core_tb.vhd
tb/mcu_v1_core_pipe5_tb.vhd
tb/mcu_fft_system_tb.vhd
tb/mcu_fft_system_pipe5_tb.vhd

目标：

实现 ARM 合法的 PKHBT Rd, Rn, Rm, LSL #imm 语义，不新增 PACKQ、STMIAH、
FFT 专用硬件或任何非 ARM 指令。用 PKHBT #23 合并输入 imag 的 LSL #7，
用 PKHBT #9 合并 twiddle imag 的 ASR #7。预期 static 106 -> 96，
timed_steps 100 -> 90，pipe5 system cnt_cycles 124 -> 约 114，但以实测为准。

如需改代码，按 docs/v1_clean_next_optimization_plan_2026.md 的 Phase 1-5 执行。
改 asm 后必须同步 .mem/.lst、rtl/mcu_v1_instr_rom.vhd、BOARD_TOP 和
BOARD_BASIC_TEST 副本。最后至少跑 Python checker、mcu_v1_decoder_tb、
mcu_v1_core_tb、mcu_fft_system_tb、mcu_v1_core_pipe5_tb、mcu_fft_system_pipe5_tb、
git diff --check。
```
