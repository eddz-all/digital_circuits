# Board-Level V5 Simulation

This directory contains simulation-only models for the board IP used by
`board_top`:

- `clk_wiz_0`
- `test_ROM`
- `verify_RAM`
- `ila_0`

The models are adapted for the current V5 FFT impulse case. They check the
input sequence and verify the 16 output samples observed through the ILA
readback path.

Use `rtl/mcu_fft_system.vhd` with this simulation. It keeps the board-facing
entity name `mcu_fft_system`, but instantiates `mcu_v5_core` internally.

Do not compile the old copied Vivado source
`vivado/board_top/BOARD_TOP.srcs/sources_1/new/mcu_fft_system.vhd` in the same
simulation library, because it has the same entity name and still instantiates
the old `mcu_v1_core`.

Expected compile order for GHDL from the repository root:

```sh
tb/board_sim/run_ghdl_board_v5.sh
```

The script uses `--std=08 -fsynopsys` by default because the current
`mcu_v5_instr_rom` uses `ieee.std_logic_textio` to load the instruction `.mem`
file during simulation.
