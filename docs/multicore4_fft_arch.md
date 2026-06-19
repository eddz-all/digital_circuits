# Multicore4 non-pipelined FFT architecture

更新时间：2026-06-19

本文档记录 `codex/multicore4-nonpipeline` 分支的 4-lane radix-2 FFT
prototype 方案。目标是在不新增非 ARM 指令、不改变老师 COE I/O 合约、不做专用 FFT
accelerator 的前提下，验证 8 点 FFT 的 butterfly-level parallelism。

## 1. Current baseline

当前 `codex/v1-clean` 基线已验证：

```text
host timed_steps = 90
single-cycle system cnt_cycles = 128
pipe5 system cnt_cycles = 114
```

这些指标口径不同：

```text
timed_steps:
  host checker 中从第一条输入读到最后一次输出写的 MCU 指令数口径。

cnt_cycles:
  system wrapper 中从第一个 signal slot 写入开始，到最后一个 verify slot 写出结束的
  端到端 cycle 口径，更接近板级 cnt_test。

cycles_to_halt:
  独立 core TB 从释放 reset 到 DONE self-loop 的本地 core 口径，不能和 cnt_cycles 混用。
```

## 2. Design boundary

本 prototype 不复制 4 个完整 `mcu_v1_core`，也不写完整 FFT 硬连线输出。

采用：

```text
controller + ping-pong buffers + 4 lightweight butterfly lanes
```

每个 lane 复用当前 ARM-like packed DSP 语义：

```text
LSL
PKHBT
SADD16
SSUB16
SSAX
SMUAD
SMUSD
ASR
```

`twiddle_mode` 只在 lane 内选择已有 micro-op 组合，不是软件可见 ISA 指令。
对外仍然是一个 MCU/RTL 微架构实验，不是直接绕过指令语义的 FFT accelerator。

## 3. I/O contract

保持老师 2026 COE 合约：

```text
FFT_input.coe[0..63]     DFT matrix real Q7
FFT_input.coe[64..127]   DFT matrix imag Q7
FFT_input.coe[128..135]  signal real Q5
FFT_input.coe[136..143]  signal imag Q5

FFT_output.coe[0..7]     output real Q12, natural order
FFT_output.coe[8..15]    output imag Q12, natural order
```

内部 complex packed format：

```text
low16  = real Q12
high16 = imag Q12
```

## 4. Stage mapping

输入按 bit-reversed DIT order 装入 `buf_a`：

```text
A[0] = x0
A[1] = x4
A[2] = x2
A[3] = x6
A[4] = x1
A[5] = x5
A[6] = x3
A[7] = x7
```

Stage 1:

```text
lane0: A[0], A[1] -> B[0], B[1], W0
lane1: A[2], A[3] -> B[2], B[3], W0
lane2: A[4], A[5] -> B[4], B[5], W0
lane3: A[6], A[7] -> B[6], B[7], W0
```

Stage 2:

```text
lane0: B[0], B[2] -> A[0], A[2], W0
lane1: B[1], B[3] -> A[1], A[3], W2
lane2: B[4], B[6] -> A[4], A[6], W0
lane3: B[5], B[7] -> A[5], A[7], W2
```

Stage 3:

```text
lane0: A[0], A[4] -> B[0], B[4], W0
lane1: A[1], A[5] -> B[1], B[5], W1
lane2: A[2], A[6] -> B[2], B[6], W2
lane3: A[3], A[7] -> B[3], B[7], W3
```

Final:

```text
B[0..7] = X0..X7 natural order
```

## 5. Twiddle modes

```text
00 = W0 = 1
01 = W1 =  91/128 - j*91/128
10 = W2 = -j
11 = W3 = -91/128 - j*91/128
```

Lane semantic steps:

```text
W0:
  t = b

W2:
  t = SSAX(0, b)
  t.real = b.imag
  t.imag = -b.real

W1:
  tmp_re = SMUAD(b, pack(91, 91))
  tmp_im = SMUSD(b, pack(-91, -91))
  t = PKHBT(ASR(tmp_re, 7), tmp_im, LSL #9)

W3:
  tmp_re = SMUSD(b, pack(-91, -91))
  tmp_im = SMUAD(b, pack(-91, -91))
  t = PKHBT(ASR(tmp_re, 7), tmp_im, LSL #9)

butterfly:
  even = SADD16(a, t)
  odd  = SSUB16(a, t)
```

该方向与当前 direct DFT checker 的模型一致：

```text
real += xr * wr - xi * wi
imag += xr * wi + xi * wr
```

## 6. Top-level FSM

`rtl/mcu_fft_system_multicore4.vhd` 使用这些状态：

```text
S_LOAD_REQ
S_LOAD_WAIT
S_LOAD_STREAM
S_STAGE_DISPATCH
S_WAIT_CORES
S_DUMP_OUTPUT
S_DONE
```

行为：

```text
S_LOAD_*:
  从 test_ROM 连续读取 FFT_input[128..143]。
  cnt_start 在第一个 signal slot 写入时拉高。
  signal real slot 到达时暂存 real。
  signal imag slot 到达时同步完成 Q5->Q12 pack，并按 bit-reversed order 写入 buf_a。

S_STAGE_DISPATCH:
  给 4 个 lane 分配 operand 和 twiddle_mode。
  core_start 拉高一个周期。

S_WAIT_CORES:
  latch 每个 lane 的 done pulse。
  等 4 个 lane 都 done 后形成 stage barrier。
  在 barrier 完成的同一拍把 4 个 lane 的 even/odd 写回目标 ping-pong buffer。
  stage 0: A -> B
  stage 1: B -> A
  stage 2: A -> B

S_DUMP_OUTPUT:
  写出 B[0..7].real，然后 B[0..7].imag。
  cnt_stop 在最后一个 verify slot 写出时拉高。
```

## 7. Verification plan

当前新增验证路径：

```text
tools/test_multicore4_fft_model.py
tb/mcu_v1_butterfly_core_tb.vhd
tb/mcu_fft_system_multicore4_tb.vhd
```

验证顺序：

```text
1. Python model 对 teacher sample 和 100 组 random Q5 signal 通过。
2. butterfly core TB 覆盖 W0/W1/W2/W3。
3. multicore4 system TB 逐槽匹配 FFT_output.coe。
4. 报告 multicore4 system cnt_cycles，并和 128 / 114 比较。
```

## 8. Expected result

该 prototype 的目标是先证明功能正确和端到端 `cnt_cycles` 明显下降。

实现前预期：

```text
multicore4 system cnt_cycles ~= 55..70
```

当前本地 GHDL 实测：

```text
tools/test_multicore4_fft_model.py passed
mcu_v1_butterfly_core_tb passed
mcu_fft_system_multicore4_tb passed
mcu_fft_system_multicore4_tb cnt_cycles = 49
```

对比当前基线：

```text
single-cycle system cnt_cycles = 128
pipe5 system cnt_cycles = 114
multicore4 non-pipelined system cnt_cycles = 49
```

2026-06-19 更新借鉴了 pipeline prototype 的 wrapper-level overlap 思路，但没有把
`mcu_v1_core_pipe5` 放进 4 个 lane。具体变化是：

```text
1. Q5->Q12 pack 从独立 S_PACK_INPUT 阶段移动到 imag input slot 到达时完成。
2. stage writeback 从独立 S_WRITEBACK/S_NEXT_STAGE 阶段移动到 S_WAIT_CORES barrier 完成拍完成。
```

该优化减少 controller 空拍，不改变 4-lane butterfly core、twiddle mode、输出顺序或老师
COE I/O 合约。

这些结果只说明本地功能仿真和 system-level counter 口径成立。当前 Mac/GHDL
工作流不能证明 Vivado Fmax、资源或上板表现。
