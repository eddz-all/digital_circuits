library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.mcu4_multi_pkg.all;

entity mcu4_instr_rom is
    port (
        pc_index : in  std_logic_vector(4 downto 0);
        instr    : out word_t
    );
end entity mcu4_instr_rom;

architecture rtl of mcu4_instr_rom is
    function rom_index(addr : std_logic_vector(4 downto 0)) return natural is
        variable idx : natural range 0 to 31 := 0;
    begin
        for bit_pos in 0 to 4 loop
            if addr(bit_pos) = '1' then
                idx := idx + (2 ** bit_pos);
            end if;
        end loop;
        return idx;
    end function;

    constant PROGRAM : program_rom_t := (
        -- 32-bit ARM-style instruction words used by the visible MCU program.
        0  => x"E3A00000", -- MOV  r0, #0
        1  => x"E2801001", -- ADD  r1, r0, #1
        2  => x"E0414001", -- SUB  r4, r1, r1
        3  => x"E201200F", -- AND  r2, r1, #15
        4  => x"E1823000", -- ORR  r3, r2, r0
        5  => x"EB000002", -- BL   fft_stage0_kernel
        6  => x"EB000007", -- BL   fft_stage1_kernel
        7  => x"EB00000C", -- BL   fft_stage2_kernel
        8  => x"EAFFFFFE", -- B    halt

        -- fft_stage0_kernel: four visible DSP dispatch instructions, wait, return.
        9  => x"ED800000", -- DSP_BFLY_START stage0 lane0, W0
        10 => x"ED820000", -- DSP_BFLY_START stage0 lane1, W0
        11 => x"ED840000", -- DSP_BFLY_START stage0 lane2, W0
        12 => x"ED860000", -- DSP_BFLY_START stage0 lane3, W0
        13 => x"ED600000", -- DSP_BFLY_WAIT  stage0, commit results
        14 => x"E1A0F00E", -- MOV  pc, lr

        -- fft_stage1_kernel.
        15 => x"ED880000", -- DSP_BFLY_START stage1 lane0, W0
        16 => x"ED8A0000", -- DSP_BFLY_START stage1 lane1, W2
        17 => x"ED8C0000", -- DSP_BFLY_START stage1 lane2, W0
        18 => x"ED8E0000", -- DSP_BFLY_START stage1 lane3, W2
        19 => x"ED680000", -- DSP_BFLY_WAIT  stage1, commit results
        20 => x"E1A0F00E", -- MOV  pc, lr

        -- fft_stage2_kernel.
        21 => x"ED900000", -- DSP_BFLY_START stage2 lane0, W0
        22 => x"ED920000", -- DSP_BFLY_START stage2 lane1, W1
        23 => x"ED940000", -- DSP_BFLY_START stage2 lane2, W2
        24 => x"ED960000", -- DSP_BFLY_START stage2 lane3, W3
        25 => x"ED700000", -- DSP_BFLY_WAIT  stage2, commit results
        26 => x"E1A0F00E", -- MOV  pc, lr

        -- Concrete baseline-memory and DSP examples kept in ROM for reports.
        27 => x"E5915000", -- LDR  r5, [r1, #0]
        28 => x"E5815000", -- STR  r5, [r1, #0]
        29 => x"ED800001", -- DSP_BFLY_START example slot
        30 => x"ED600000", -- DSP_BFLY_WAIT example slot
        31 => x"E1A00000", -- MOV  r0, r0 (NOP)
        others => x"E1A00000" -- MOV r0, r0 (NOP)
    );
begin
    instr <= PROGRAM(rom_index(pc_index));
end architecture rtl;
