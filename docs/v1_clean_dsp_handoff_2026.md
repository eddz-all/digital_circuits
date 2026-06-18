# V1 Clean DSP Handoff 2026

更新时间：2026-06-18

本文档用于让后续 Codex 会话或同学快速接手当前 `codex/v1-clean`
分支上的 2026 老师样例适配和 DSP 指令优化工作。

## 1. 当前状态

当前工作目录：

```text
/Users/eddz/work/Digital_Circuits
```

当前分支和基线：

```text
branch: codex/v1-clean
HEAD: 9d69361
remote tracking: origin/codex/v1-clean
```

当前工作树有未提交改动。不要默认提交或推送，除非用户明确要求。

当前未跟踪目录：

```text
测试数据样例-2026/
```

该目录是老师样例数据来源，后续会话不要删除或清理。

## 2. 任务边界

当前路线只使用本地 macOS 上的：

```text
VHDL
asm
Python host checker
GHDL
```

不要在这个流程里默认运行：

```text
Vivado
xsim
综合
实现
bitstream
板卡
JTAG
XDC
```

如需继续代码工作，建议按这些 skill 的工作方式走：

```text
mac-asm-algorithm
mac-vhdl-rtl
mac-ghdl-verification
```

## 3. 老师样例 I/O 合约

当前实现最终以 `测试数据样例-2026` 为准，旧接口说明中的输入顺序只能当历史假设。

`FFT_input.coe` 有 144 个 16-bit signed 槽：

```text
slot 0..63     DFT 矩阵实部，8x8，Q7
slot 64..127   DFT 矩阵虚部，8x8，Q7
slot 128..135  输入信号实部，8 个，Q5
slot 136..143  输入信号虚部，8 个，Q5
```

`FFT_output.coe` 有 16 个 16-bit signed 槽：

```text
slot 0..7      输出实部，Q12，自然序
slot 8..15     输出虚部，Q12，自然序
```

当前程序视角地址按 32-bit 槽位访问，步长是 `+4`：

```text
signal_real[n] = input_mem[128 + n] -> byte address (128 + n) * 4
signal_imag[n] = input_mem[136 + n] -> byte address (136 + n) * 4
output_real[k] -> byte address 0x800 + 4*k
output_imag[k] -> byte address 0x820 + 4*k
```

## 4. 当前算法实现

当前不是旧 radix-2 DIF `FFT/8`，也不是从 `FFT_input.coe` 前 128 行运行时读取矩阵。

当前已切到 bit-reversed input 的 radix-2 DIT packed FFT butterfly 路线。它仍然等价计算老师
`dftmtx(8)` Q7 矩阵对应的 8 点 DFT：

```text
real[k] = sum_n xr[n] * wr[k,n] - xi[n] * wi[k,n]
imag[k] = sum_n xr[n] * wi[k,n] + xi[n] * wr[k,n]
```

程序先把 Q5 输入乘以 128 放大为 Q12 packed complex lane，然后用 3 级 radix-2
butterfly 计算。W8^1 / W8^3 使用 Q7 常数 91 和 -91，并在乘法后 `ASR #7`
回到 Q12；W8^2 用 packed `SSAX` 做 `-j` 旋转。最终输出仍是自然序 Q12：
real0..real7, imag0..imag7。

矩阵系数写死在汇编/机器码里，只用到这些 Q7 常数：

```text
0, 128, -128, 91, -91
```

这样做不算绕过 MCU：计算仍然由 MCU 指令执行，只是不再运行时加载固定矩阵。

## 5. DSP 指令扩展

当前 V1 clean DSP 版 RTL 接入了这些 ARM 风格 packed DSP 指令：

```text
PKHBT Rd, Rn, Rm, LSL #16
SADD16 Rd, Rn, Rm
SSUB16 Rd, Rn, Rm
SSAX Rd, Rn, Rm
SMUAD Rd, Rn, Rm
SMUSD Rd, Rn, Rm
SMLAD Rd, Rn, Rm, Ra
STMIA Rn!, {register list}
```

RTL 语义：

```text
PKHBT:  Rd = {Rm[15:0], Rn[15:0]}
SADD16: lane-wise signed 16-bit add, low/high lanes kept separately
SSUB16: lane-wise signed 16-bit subtract, low/high lanes kept separately
SSAX:   Rd.low16 = Rn.low16 + Rm.high16
        Rd.high16 = Rn.high16 - Rm.low16
SMUAD:  Rd = Rn.low16*Rm.low16 + Rn.high16*Rm.high16
SMUSD:  Rd = Rn.low16*Rm.low16 - Rn.high16*Rm.high16
SMLAD: Rd = signed(Rn[15:0]) * signed(Rm[15:0])
          + signed(Rn[31:16]) * signed(Rm[31:16])
          + signed(Ra)
STMIA: ARM-style store-multiple increment-after with writeback.
       Registers are stored in ascending register-number order.
```

当前 radix-2 程序实际使用 `PKHBT/SADD16/SSUB16/SSAX/SMUAD/SMUSD/STMIA`；
`SMLAD` 仍保留在 RTL/assembler/checker 中，供旧 direct DFT 版或后续变体使用。

当前程序把 8 个复数样本打包成 8 个 32-bit complex 寄存器：

```text
low16 = real Q12
high16 = imag Q12
```

输入加载顺序是 bit-reversed：

```text
x0, x4, x2, x6, x1, x5, x3, x7
```

这样 3 级 radix-2 DIT butterfly 后直接得到自然序输出。

注意：当前 `R15` 在这个软 MCU 里被当作普通通用寄存器使用。PC 是 `mcu_v1_core`
内部独立寄存器，不依赖 R15。因此当前 regfile 已允许写 R15；radix-2 程序里
R15 用作 W8^1/W8^3 复乘的临时寄存器。

## 6. 关键文件

根 RTL：

```text
rtl/mcu_v1_alu.vhd          -- 4-bit alu_control，packed DSP ALU ops
rtl/mcu_v1_decoder.vhd      -- OP_EXT 解码，ra3 第三读口，STMIA regmask
rtl/mcu_v1_regfile.vhd      -- ra3/rd3，允许写 R15，bulk_rd for STMIA
rtl/mcu_v1_core.vhd         -- 接入 ra3/rd3、ALU c 输入和 STMIA bulk store
rtl/mcu_v1_instr_rom.vhd    -- hardcoded 107-word radix-2 packed FFT ROM
rtl/mcu_fft_system.vhd      -- 2026 样例 board-style wrapper，连续输入流 + 输出流水 dump
```

汇编和机器码：

```text
asm/fft8_v1_mcu32_basic.s
asm/fft8_v1_mcu32_basic.mem
asm/fft8_v1_mcu32_basic.lst
```

工具和测试：

```text
tools/assemble_mcu_v1.py
tools/test_fft8_v1_mcu32_basic.py
tb/mcu_v1_decoder_tb.vhd
tb/mcu_v1_core_tb.vhd
tb/mcu_fft_system_tb.vhd
```

board 工程副本已同步：

```text
BOARD_TOP/BOARD_TOP.srcs/sources_1/new/
BOARD_TOP/asm/
BOARD_BASIC_TEST/BOARD_BASIC_TEST.srcs/sources_1/new/
BOARD_BASIC_TEST/asm/
```

## 7. 当前实测结果

Python host checker：

```text
teacher sample output matched exactly
100 random Q5 signal tests passed against the fixed DFT matrix
107 instructions before labels/comments
106 instructions executed before DONE self-loop
100 instructions from first input read through last output write
```

GHDL system testbench：

```text
mcu_v1_decoder_tb passed
mcu_v1_core_tb passed
mcu_fft_system_tb passed
mcu_fft_system_tb cnt_cycles 139
```

计数口径不要混用：

```text
host timed_steps = 100
GHDL/system cnt_cycles = 139
```

`cnt_cycles = 139` 是更接近板级 `cnt_test` 的口径，因为它包含系统 wrapper 的输入装载、
运行和输出 dump。`timed_steps = 100` 只是 host checker 中从首个输入读到最后输出写的
MCU 指令口径。

当前 wrapper 已做两处系统级压缩：

```text
1. 输入装载改成同步 ROM 连续流，首地址等待后每拍写一个 signal slot。
2. 输出 dump 从 S_DUMP_ADDR + S_DUMP_WRITE 两拍/槽改成一拍/槽。
```

当前汇编输出段使用 `STMIA R10!, {R0-R7}` 批量写 real0..real7，再把 R0..R7
算术右移 16 位后用第二条 `STMIA` 批量写 imag0..imag7。

对比前两版 fast path：

```text
标量固定矩阵版 cnt_cycles = 445
SMLAD direct DFT 版 cnt_cycles = 350
radix-2 packed FFT 版，未优化 dump 前 cnt_cycles = 198
radix-2 packed FFT + 流水 dump 版 cnt_cycles = 182
当前 radix-2 packed FFT + STMIA 输出 + 连续输入流版 cnt_cycles = 139
相对 direct DFT 版减少 211 cycle，约 60%
相对标量固定矩阵版减少 306 cycle，约 69%
```

## 8. 复现命令

重新生成机器码：

```bash
python3 tools/assemble_mcu_v1.py asm/fft8_v1_mcu32_basic.s \
  --mem-out asm/fft8_v1_mcu32_basic.mem \
  --lst-out asm/fft8_v1_mcu32_basic.lst
```

运行 host checker：

```bash
python3 tools/test_fft8_v1_mcu32_basic.py
```

推荐的 GHDL 回归命令：

```bash
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
```

GHDL 可能在 `0ms` 打出 `NUMERIC_STD.TO_INTEGER: metavalue detected` warning。当前这些 warning
没有导致失败，判断结果以 testbench 是否 passed 和 assertion 是否失败为准。

检查 board 副本是否和根文件一致：

```bash
diff -q rtl/mcu_v1_alu.vhd BOARD_TOP/BOARD_TOP.srcs/sources_1/new/alu.vhd
diff -q rtl/mcu_v1_decoder.vhd BOARD_TOP/BOARD_TOP.srcs/sources_1/new/decoder.vhd
diff -q rtl/mcu_v1_regfile.vhd BOARD_TOP/BOARD_TOP.srcs/sources_1/new/regfile.vhd
diff -q rtl/mcu_v1_core.vhd BOARD_TOP/BOARD_TOP.srcs/sources_1/new/mcu_core.vhd
diff -q rtl/mcu_v1_instr_rom.vhd BOARD_TOP/BOARD_TOP.srcs/sources_1/new/instr_rom.vhd
diff -q asm/fft8_v1_mcu32_basic.s BOARD_TOP/asm/fft8_v1_mcu32_basic.s
diff -q asm/fft8_v1_mcu32_basic.mem BOARD_TOP/asm/fft8_v1_mcu32_basic.mem
diff -q asm/fft8_v1_mcu32_basic.lst BOARD_TOP/asm/fft8_v1_mcu32_basic.lst
```

同样需要检查 `BOARD_BASIC_TEST` 对应副本。

## 9. 常见坑

1. 不要再按旧 16 输入交错格式读取：

```text
real_i = input_mem[2*i]
imag_i = input_mem[2*i + 1]
```

当前必须读取：

```text
real_i = input_mem[128 + i]
imag_i = input_mem[136 + i]
```

2. 不要把 `FFT_input.coe` 前 128 个矩阵槽加载进 MCU 输入内存后再运行时读取。
当前 fast path 只加载 signal window `128..143`，矩阵常数写在机器码里。

3. 不要把 `cnt_cycles` 和 `timed_steps` 写成同一个指标。上板相关讨论优先看
`cnt_cycles` / `cnt_test` 口径。

4. 不要只改根 RTL 后忘记同步 board 副本。当前 board 目录里有直接复制的 `alu.vhd`、
`decoder.vhd`、`regfile.vhd`、`mcu_core.vhd`、`instr_rom.vhd` 和 asm 文件。

5. 当前已经是 packed radix-2 FFT butterfly 路线，但还不是旧 `dsp` 分支的 V5 59-step
版本。主要差距在 2026 non-interleaved 输入加载和 Q5->Q12 放大；输出逐槽写回已用
`STMIA` 压掉。

## 10. 后续优化建议

当前 139 cycle 还没到几十级，主要固定开销来自：

```text
1. 8 个复数输入需要分别从 real window 和 imag window 加载，并乘 128 放大到 Q12。
2. 当前没有 packed lane 左移指令，所以 Q5->Q12 放大用 16 条 MUL。
3. 当前没有 LDMIA 输入路径，因为 2026 输入是 real window / imag window 分离，不是 V5 旧 packed 连续格式。
4. 每一步都必须继续保持老师样例输出自然序：real0..real7, imag0..imag7。
5. 后续可考虑 LDMIA 变体、packed lane shift、或更激进但仍由 MCU 指令驱动的流水线/Fmax 路线。
```

注意：任何更激进的优化都不能绕过 MCU 指令直接硬件得出 FFT 结果。

## 11. 下个会话启动顺序

下个会话建议先读：

```text
docs/v1_clean_next_session_prompt_2026.md
docs/v1_clean_dsp_handoff_2026.md
FFT_ALGORITHM_NOTES.md
上板注意事项.md
docs/fft8_v1_mcu32_check_rules.md
```

然后执行：

```bash
git status --short --branch
python3 tools/test_fft8_v1_mcu32_basic.py
```

如果要改 RTL 或汇编，再跑第 8 节的 GHDL 回归命令。
