# MCU Core 接入说明

本文档定义未来新版 MCU core 接入当前上板验证框架时必须遵守的接口约定。

目标是：以后不管新的 MCU 是单周期、多周期，还是流水线，只要它满足本文档的接口和行为要求，就可以直接接入现有的 `mcu_fft_system` 和 `board_top`，尽量不再修改板级壳子、`test_ROM`、`verify_RAM`、ILA 和计数器逻辑。

## 当前上板整体流程

当前已经验证过的 FFT 上板流程如下：

```
test_ROM -> test_vector_in -> mcu_fft_system -> mcu_core.input_mem
         -> MCU 执行汇编程序
         -> mcu_core.output_mem -> mcu_fft_system -> verify_RAM
         -> board_top 回读 -> ILA
```

`board_top` 负责外部板级 IP：

```
clk_wiz_0
test_ROM
verify_RAM
ila_0
```

`mcu_fft_system` 负责 MCU core 周围的控制协议：

```
1. 从 test_ROM 读取 16 个 16-bit 输入数据。
2. 把这些数据写入 mcu_core 的 input_mem。
3. 释放 core 复位，让 MCU 开始执行汇编程序。
4. 等待 core 进入完成状态，或者发现非法指令。
5. 从 core 的 output_mem 读取 16 个输出数据。
6. 把输出数据一次性写入 verify_RAM。
7. 写完最后一个输出后停止 cnt_test。
8. 再从 verify_RAM 读回内容，送给 ILA 观察。
```

## 必须提供的 Core 顶层接口

未来替换用的 MCU core 应该提供和下面兼容的实体接口：

```vhdl
entity mcu_v1_core is
    generic (
        MEM_FILE  : string := "asm/fft8_v1_mcu32_basic.mem";
        ROM_DEPTH : positive := 1024
    );
    port (
        clk : in std_logic;
        rst : in std_logic;

        input_we    : in  std_logic;
        input_waddr : in  std_logic_vector(5 downto 0);
        input_wdata : in  std_logic_vector(15 downto 0);

        output_raddr : in  std_logic_vector(5 downto 0);
        output_rdata : out std_logic_vector(15 downto 0);

        pc_debug      : out std_logic_vector(31 downto 0);
        instr_debug   : out std_logic_vector(31 downto 0);
        halted_debug  : out std_logic;
        illegal_debug : out std_logic;
        flag_z_debug  : out std_logic;
        flag_n_debug  : out std_logic
    );
end entity;
```

如果新版 MCU 内部天然不是这个接口，建议额外写一层适配器，比如：

```
mcu_v2_core_adapter.vhd
```

适配器对外保持上面的接口不变，对内再连接新版 core 自己的真实端口。这样可以保护已经验证过的 `board_top` 和 `mcu_fft_system`。

## 端口含义

`clk`

MCU 主时钟。它来自 `clk_wiz_0.clk_out1`，由 `board_top` 传入 `mcu_fft_system`，再传给 core。

`rst`

高电平有效复位。当前系统按同步复位来使用。`rst = '1'` 时，core 不应该执行用户程序，PC 和寄存器等架构状态应该回到确定状态。

注意：当前上板壳子会在加载输入数据期间保持 core 复位。因此 core 必须支持“复位期间写入 input_mem”，否则输入数据会加载不进去。

`input_we`

外部输入存储器写使能。它由 `mcu_fft_system` 控制，不是 MCU 汇编程序自己产生的信号。

当某个上升沿满足：

```
input_we = 1
```

core 必须执行：

```
input_mem[input_waddr] <= input_wdata
```

这个通道用于在 MCU 开始运行前，把 `test_ROM` 里的测试向量预加载到 core 的 `input_mem`。

`input_waddr[5:0]`

输入样本下标。当前 FFT 测试使用 `0..15`，对应 8 个复数点：

```
input_mem[0]  = real0
input_mem[1]  = imag0
input_mem[2]  = real1
input_mem[3]  = imag1
...
input_mem[14] = real7
input_mem[15] = imag7
```

`input_wdata[15:0]`

输入样本数据。格式是 16-bit 有符号定点数。

`output_raddr[5:0]`

外部读取输出存储器的地址。MCU 程序执行完成后，`mcu_fft_system` 会驱动这个地址，从 core 的 `output_mem` 读出结果，再写入 `verify_RAM`。

`output_rdata[15:0]`

`output_mem[output_raddr]` 对应的 16-bit 有符号输出数据。

重要约定：当前 `mcu_fft_system` 假设 `output_rdata` 是组合读出，也就是地址变化后数据可以在同一拍组合稳定。当前 `mcu_v1_data_mem` 的写法类似：

```vhdl
output_rdata <= output_mem(to_integer(unsigned(output_raddr)));
```

如果未来 core 的 `output_mem` 是同步读 RAM，也就是给地址后一拍才出数据，那么有两种处理方式：

```
方案 1：修改 mcu_fft_system，增加一个等待状态。
方案 2：在 adapter 里把新版 core 的同步读接口转换成当前组合读接口。
```

如果选择方案 1，输出状态机应从：

```
S_DUMP_ADDR -> S_DUMP_WRITE
```

改成：

```
S_DUMP_ADDR -> S_DUMP_WAIT -> S_DUMP_WRITE
```

`pc_debug[31:0]`

当前 PC，用于 ILA 或仿真调试。不参与板级控制，但应该真实反映当前指令流。

`instr_debug[31:0]`

当前指令，用于调试。它应该和 `pc_debug` 对应。

`halted_debug`

程序完成标志。当前 core 把“跳转到自身”视为程序结束：

```
DONE:
    B DONE
```

`mcu_fft_system` 检测到下面条件后，会认为 MCU 执行阶段结束，并开始导出 output_mem：

```vhdl
core_halted = '1' or core_illegal = '1'
```

正常情况应该是：

```
halted_debug = 1
illegal_debug = 0
```

`illegal_debug`

非法指令标志。如果 decoder 遇到不支持或格式错误的指令，就置 1。FFT 程序和 basic 指令测试程序运行时，这个信号必须保持 0。

`flag_z_debug`, `flag_n_debug`

零标志和负标志的调试输出。它们主要用于检查 `CMP`、`BEQ`、`BNE` 等条件执行逻辑。

## Core 内部存储器要求

当前软件和板级壳子默认 core 内部有三个逻辑存储区：

```
input_mem   输入区
work_mem    中间计算区
output_mem  输出区
```

这三个区域不一定非要做成三个独立 RAM，也可以是统一 RAM 加地址译码。但从软件和外部接口看，行为必须等价。

## input_mem 输入区

```
名称：      input_mem
宽度：      16 bit
深度：      至少 16 项，推荐 64 项
外部写入：  input_we / input_waddr / input_wdata
程序读取：  通过 INPUT_BASE 地址区读取
```

当前地址映射：

```
INPUT_BASE = 0x000
```

程序访存地址译码建议：

```
region = addr[9:8]
slot   = addr[7:2]
```

所以程序读取第 `i` 个输入样本时，地址是：

```
addr = 0x000 + 4*i
```

由于 MCU 寄存器是 32 bit，而输入数据是 16 bit，所以读入寄存器时必须做符号扩展：

```
read_data = sign_extend(input_mem[i])
```

例子：

```
input_mem[i] = 0xfe0c
read_data    = 0xfffffe0c
```

## work_mem 工作区

```
名称：      work_mem
宽度：      32 bit
深度：      推荐 64 项
程序访问：  通过 WORK_BASE 地址区读写
```

当前地址映射：

```
WORK_BASE = 0x100
```

程序访问第 `i` 个工作区数据时，地址是：

```
addr = 0x100 + 4*i
```

这个区域用于保存 FFT 中间计算值。因为乘法、加减法和移位都可能产生 32-bit 中间结果，所以 `work_mem` 推荐保持 32 bit。

## output_mem 输出区

```
名称：      output_mem
宽度：      16 bit
深度：      至少 16 项，推荐 64 项
程序写入：  通过 OUTPUT_BASE 地址区写入
外部读取：  output_raddr / output_rdata
```

当前地址映射：

```
OUTPUT_BASE = 0x200
```

程序写入第 `i` 个输出样本时，地址是：

```
addr = 0x200 + 4*i
```

当程序把一个 32-bit 寄存器写入输出区时，只保存低 16 bit：

```
output_mem[i] = write_data[15:0]
```

如果程序再从 output_mem 读回数据，应该符号扩展到 32 bit。外部接口 `output_rdata` 只需要输出 16 bit。

## 复位和输入加载时序

当前 `mcu_fft_system` 在加载输入期间会保持 core 复位：

```
S_LOAD_REQ
S_LOAD_WAIT
S_LOAD_WRITE
...
S_RUN
```

加载期间：

```
core_rst = 1
input_we 每个输入样本拉高一次
```

因此 core 必须做到：

```
rst = 1 时，仍然允许 input_we 写入 input_mem。
rst = 1 时，可以清空 PC、寄存器、work_mem、output_mem。
rst = 1 时，不要清空刚刚写入的 input_mem。
```

当前 `mcu_v1_data_mem` 的意图是：

```vhdl
if input_we = '1' then
    input_mem(to_integer(unsigned(input_waddr))) <= input_wdata;
end if;

if rst = '1' then
    work_mem <= zeros;
    output_mem <= zeros;
end if;
```

也就是说，复位可以清空工作区和输出区，但不能把预加载好的输入数据抹掉。

## 与 mcu_fft_system 的拍数约定

## 输入侧

`test_ROM` 是 Vivado Block Memory Generator，同步读。给地址后一拍才得到对应数据。

因此当前 shell 对每个输入样本使用三步：

```
S_LOAD_REQ    给出 test_rom_addr
S_LOAD_WAIT   保持地址，等待 test_vector_in 稳定
S_LOAD_WRITE  把 test_vector_in 写入 input_mem
```

core 本身只需要看到最后一步：

```
input_we/input_waddr/input_wdata
```

它不需要知道外部 `test_ROM` 的读延迟。

## 输出侧

当前输出侧假设 core 的 `output_mem` 是组合读：

```
S_DUMP_ADDR   给出 output_raddr
S_DUMP_WRITE  给出 verify_RAM 地址、数据、写使能
```

`verify_RAM` 是同步写 RAM，因此真正写入发生在 `verify_ram_we`、`verify_ram_addr` 和 `verify_vector_out` 稳定后的下一个上升沿。

所以从系统角度看：

```
core 输出读：当前假设组合读
verify_RAM 写：同步写
verify_RAM 回读：同步读，需要看 valid 对齐
```

## 必须支持的指令

为了满足 basic 指令正确性验证，至少应该支持下面这些指令：

```
ADD
SUB
AND
ORR
MOV
LDR
STR
B
```

其中 `ORR` 是 ARM 风格命名，也就是普通按位或 OR。

当前工程额外使用或验证的指令还有：

```
CMP
BEQ
BNE
MUL
ASR
```

当前 decoder 使用的 opcode 约定如下：

```
AND = 0000
SUB = 0010
ADD = 0100
CMP = 1010
ORR = 1100
MOV = 1101
MUL = 1001
ASR = 1111
```

其中 `MUL` 和 `ASR` 是本项目里的简化数据处理格式，不一定完全等同标准 ARM 编码。

当前使用的条件码：

```
EQ = 0000
NE = 0001
AL = 1110
```

立即数和访存偏移目前按 12-bit 无符号立即数 `imm12` 处理。如果需要构造更大的常数，需要用多条指令完成。

## Basic 指令验证程序

`board_top_basic_test` 不使用 `test_ROM`。它直接向 core 输入区写入两个测试数据：

```
input_mem[0] = 1000
input_mem[1] = -500
```

然后运行：

```
MEM_FILE = "asm/test_mcu_v1_basic.mem"
```

期望输出：

```
output_mem[0] = 500      -- ADD: 1000 + (-500)
output_mem[1] = 1500     -- SUB: 1000 - (-500)
output_mem[2] = 707      -- MUL + ASR
output_mem[3] = 520      -- AND
output_mem[4] = -20      -- ORR
output_mem[5] = 123      -- CMP/BEQ/B 路径
output_mem[6..15] = 0
```

在 ILA 的 16-bit 十六进制读回中，应该看到：

```
addr 00 -> 01f4
addr 01 -> 05dc
addr 02 -> 02c3
addr 03 -> 0208
addr 04 -> ffec
addr 05 -> 007b
addr 06 -> 0000
...
addr 0f -> 0000
```

同时必须满足：

```
illegal_debug = 0
halted_debug  = 1
```

## FFT 程序要求

FFT 上板测试使用：

```
MEM_FILE = "asm/fft8_v1_mcu32_basic.mem"
SAMPLE_COUNT = 16
```

输入格式是 16 个 16-bit 有符号定点数：

```
real0, imag0, real1, imag1, ..., real7, imag7
```

也就是 8 点复数 FFT，每个点包含实部和虚部。

输出格式相同：

```
real0, imag0, real1, imag1, ..., real7, imag7
```

FFT 汇编程序应该把 16 个输出样本写入：

```
OUTPUT_BASE + 4*i
```

写完后进入：

```
DONE:
    B DONE
```

这样 core 的 `halted_debug` 才能变成 1，`mcu_fft_system` 才会开始导出结果到 `verify_RAM`。

## ILA 调试信号约定

FFT 版本 `board_top` 当前 ILA probes：

```
probe0 = test_vector_in[15:0]
probe1 = cnt_test[19:0]
probe2 = verify_ila_addr[5:0]
probe3 = verify_readback_data[15:0]
probe4 = ila_readback_valid[0]
probe5 = ila_verify_ram_we[0]
probe6 = ila_done[0]
probe7 = ila_illegal[0]
```

basic 指令测试版本 `board_top_basic_test` 中，`probe0` 改成：

```
probe0 = core_input_wdata[15:0]
```

其他 probes 位宽保持一致：

```
16, 20, 6, 16, 1, 1, 1, 1
```

看最终 `verify_RAM` 回读结果时，只能在下面信号为 1 的时候相信地址和数据是对齐的：

```
ila_readback_valid = 1
```

也就是说，判断最终 RAM 内容时应该看：

```
verify_ila_addr
verify_readback_data
ila_readback_valid
```

不要只看某个时刻裸露的 `verify_readback_data`，否则可能看到的是 RAM 同步读延迟导致的未对齐数据。

## 新 Core 接入检查表

新版 MCU core 如果想直接接入当前板级框架，需要满足：

```
[ ] 顶层端口和本文档要求一致，或者有 adapter 转换成一致接口。
[ ] rst = 1 时，input_we 仍然可以写 input_mem。
[ ] input_mem 保存 16-bit 有符号输入样本。
[ ] 程序读取 INPUT_BASE + 4*i 时，能得到符号扩展后的输入数据。
[ ] work_mem 支持 32-bit 中间数据读写。
[ ] 程序写 OUTPUT_BASE + 4*i 时，能产生 16-bit 输出样本。
[ ] output_rdata 能返回 output_mem[output_raddr]。
[ ] 如果 output_rdata 是同步读，必须在 shell 或 adapter 中补等待拍。
[ ] 合法程序结束后 halted_debug = 1。
[ ] 合法程序运行时 illegal_debug = 0。
[ ] pc_debug 和 instr_debug 对调试有意义。
[ ] 至少支持 ADD、SUB、AND、ORR、MOV、LDR、STR、B。
[ ] 如果继续使用当前 basic/FFT 程序，还要支持 CMP、BEQ、BNE、MUL、ASR。
```

## 推荐开发流程

建议未来开发新版 MCU core 时按下面顺序推进：

```
1. 先实现 core 或 adapter，使它满足本文档接口。
2. 先跑 core 级 basic 指令仿真。
3. 检查 basic 输出：500, 1500, 707, 520, -20, 123。
4. 再跑 board_top_basic_test。
5. 再跑 FFT 版本 board_top。
6. 仿真通过后再综合、实现、生成 bitstream、上板抓 ILA。
```

尽量保持 `board_top` 和 `mcu_fft_system` 稳定。新的 core 如果内部时序不同，优先写 adapter 解决，不要轻易改已经上板验证过的板级壳子。    
