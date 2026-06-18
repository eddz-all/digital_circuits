# V1 Clean DSP Next Session Prompt

下面这段可以作为下个 Codex 会话的第一条提示词使用。

```text
请使用 mac-asm-algorithm、mac-vhdl-rtl、mac-ghdl-verification 这三个 skill。

工作目录是 /Users/eddz/work/Digital_Circuits。先确认当前分支和工作树：

git status --short --branch

当前目标分支应是 codex/v1-clean。2026 老师样例适配和 packed radix-2 FFT butterfly
DSP fast path 基线已经提交并推送：

commit 9776851 Implement teacher-sample radix2 packed FFT fast path

后续可能有本地流水线实验改动；是否未提交以 git status 为准。不要默认提交、不要默认推送，
除非我明确要求。

先读这些文档恢复上下文：

1. docs/v1_clean_next_optimization_plan_2026.md
2. docs/v1_clean_dsp_handoff_2026.md
3. docs/session_memory_mcu_fft.md
4. docs/fft8_v1_mcu32_check_rules.md
5. FFT_ALGORITHM_NOTES.md
6. 上板注意事项.md

当前实现口径：

- 以老师 测试数据样例-2026 为最终真值。
- FFT_input.coe 是 144 槽：0..63 矩阵实部 Q7，64..127 矩阵虚部 Q7，
  128..135 信号实部 Q5，136..143 信号虚部 Q5。
- FFT_output.coe 是 16 槽：0..7 输出实部 Q12，8..15 输出虚部 Q12。
- 当前程序运行时只读取 input_mem[128..143] 的 16 个信号槽。
- 当前程序按 bit-reversed 顺序加载 x0, x4, x2, x6, x1, x5, x3, x7，
  每个复数打包为 low16=real Q12, high16=imag Q12。
- DFT 矩阵 dftmtx(8) 的 Q7 系数已经等价分解进 radix-2 butterfly，只用到
  0, 128, -128, 91, -91。
- 当前 DSP/shift 快路径使用 LSL/PKHBT/SADD16/SSUB16/SSAX/SMUAD/SMUSD/STMIA。
- 当前 wrapper 输入装载已改为同步 ROM 连续流，输出用两条 STMIA 批量写回。
- 当前不是旧 dsp 分支的 V5 59-step packed FFT；它是 2026 teacher-sample non-interleaved
  合约下的 radix-2 packed FFT 版本。
- 当前已验证结果是 host timed_steps = 100，GHDL/single-cycle system cnt_cycles = 138，
  GHDL/pipe5 system cnt_cycles = 124。
- 上板相关 cnt 优先看 cnt_cycles / cnt_test 口径，不要和 host timed_steps 混用。
- P1 registered-fetch 实验 core 是 rtl/mcu_v1_core_pipe2.vhd，独立 TB 是
  tb/mcu_v1_core_pipe2_tb.vhd；它目前不替换 rtl/mcu_fft_system.vhd 默认实例化的
  单周期 mcu_v1_core。
- 5-stage pipeline 实验 core 是 rtl/mcu_v1_core_pipe5.vhd，独立 TB 是
  tb/mcu_v1_core_pipe5_tb.vhd；它是 IF/ID/EX/MEM/WB 原型，普通 RAW forwarding，
  LDR load-use stall，STMIA bulk-store 数据旁路，load 到 bulk-store 保守 stall。
  当前汇编输入装载使用 LDR/LDR/LSL/LSL/PKHBT，删除旧的 MOV R9,#128 缩放常量；
  pipe5 独立 TB cycles_to_halt = 108。pipe5 system 变体是 rtl/mcu_fft_system_pipe5.vhd
  和 tb/mcu_fft_system_pipe5_tb.vhd，已把输入装载和 core 运行重叠，同口径 cnt_cycles = 124。
  目前默认 mcu_fft_system 仍实例化单周期 core。

工具边界：

- 只用本地 macOS、VHDL、asm、Python checker、GHDL。
- 不要运行 Vivado/xsim/综合/实现/bitstream/板卡/JTAG/XDC，除非我明确要求。

开始工作前，先跑：

python3 tools/test_fft8_v1_mcu32_basic.py

如果要改 RTL 或汇编，改完必须至少跑：

rm -rf /tmp/digital_circuits_ghdl_dsp
mkdir -p /tmp/digital_circuits_ghdl_dsp

ghdl -a --std=08 --workdir=/tmp/digital_circuits_ghdl_dsp \
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

ghdl -e --std=08 --workdir=/tmp/digital_circuits_ghdl_dsp mcu_v1_decoder_tb
ghdl -r --std=08 --workdir=/tmp/digital_circuits_ghdl_dsp mcu_v1_decoder_tb --assert-level=error

ghdl -e --std=08 --workdir=/tmp/digital_circuits_ghdl_dsp mcu_v1_core_tb
ghdl -r --std=08 --workdir=/tmp/digital_circuits_ghdl_dsp mcu_v1_core_tb --assert-level=error

ghdl -e --std=08 --workdir=/tmp/digital_circuits_ghdl_dsp mcu_fft_system_tb
ghdl -r --std=08 --workdir=/tmp/digital_circuits_ghdl_dsp mcu_fft_system_tb --assert-level=error

如果继续 P1 pipe2 实验，额外跑：

rm -rf /tmp/digital_circuits_ghdl_pipe2
mkdir -p /tmp/digital_circuits_ghdl_pipe2

ghdl -a --std=08 --workdir=/tmp/digital_circuits_ghdl_pipe2 \
  rtl/mcu_v1_alu.vhd \
  rtl/mcu_v1_decoder.vhd \
  rtl/mcu_v1_data_mem.vhd \
  rtl/mcu_v1_regfile.vhd \
  rtl/mcu_v1_instr_rom.vhd \
  rtl/mcu_v1_core_pipe2.vhd \
  tb/mcu_v1_core_pipe2_tb.vhd

ghdl -e --std=08 --workdir=/tmp/digital_circuits_ghdl_pipe2 \
  -o /tmp/digital_circuits_ghdl_pipe2/mcu_v1_core_pipe2_tb \
  mcu_v1_core_pipe2_tb

/tmp/digital_circuits_ghdl_pipe2/mcu_v1_core_pipe2_tb --assert-level=error

如果继续 5-stage pipe5 实验，额外跑：

rm -rf /tmp/digital_circuits_ghdl_pipe5
mkdir -p /tmp/digital_circuits_ghdl_pipe5

ghdl -a --std=08 --workdir=/tmp/digital_circuits_ghdl_pipe5 \
  rtl/mcu_v1_alu.vhd \
  rtl/mcu_v1_decoder.vhd \
  rtl/mcu_v1_data_mem.vhd \
  rtl/mcu_v1_regfile.vhd \
  rtl/mcu_v1_instr_rom.vhd \
  rtl/mcu_v1_core_pipe5.vhd \
  tb/mcu_v1_core_pipe5_tb.vhd

ghdl -e --std=08 --workdir=/tmp/digital_circuits_ghdl_pipe5 \
  -o /tmp/digital_circuits_ghdl_pipe5/mcu_v1_core_pipe5_tb \
  mcu_v1_core_pipe5_tb

/tmp/digital_circuits_ghdl_pipe5/mcu_v1_core_pipe5_tb --assert-level=error

注意事项：

- 不要按旧的 16 输入交错格式处理数据。
- 不要把旧接口说明当最终真值，最终以老师样例为准。
- 不要删 测试数据样例-2026/。
- 不要只改根 rtl/asm，忘记同步 BOARD_TOP 和 BOARD_BASIC_TEST 的副本。
- 如果讨论继续优化，优先考虑 STMIA / LDMIA 变体、packed lane shift、输入装载/输出拆分
  压缩等指令路线；但不能绕过 MCU 指令直接用硬件输出 FFT 结果。

请先总结你读到的当前状态、已验证证据、风险点和下一步方案，再开始实现。
```
