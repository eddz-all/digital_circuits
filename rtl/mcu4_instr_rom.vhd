library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.mcu4_multi_pkg.all;

entity mcu4_instr_rom is
    port (
        pc_index : in  std_logic_vector(5 downto 0);
        instr    : out word_t
    );
end entity mcu4_instr_rom;

architecture rtl of mcu4_instr_rom is
    function rom_index(addr : std_logic_vector(5 downto 0)) return natural is
        variable idx : natural range 0 to 63 := 0;
    begin
        for bit_pos in 0 to 5 loop
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
        5  => x"EB000000", -- BL   fft_kernel
        6  => x"EAFFFFFE", -- B    halt

        -- fft_kernel: standard ARM instructions control the four-lane MMIO unit.
        7  => x"E5800000", -- STR  r0, [r0, #0]   ; start stage0
        8  => x"E5905004", -- LDR  r5, [r0, #4]   ; done mask
        9  => x"E355000F", -- CMP  r5, #15
        10 => x"1AFFFFFC", -- BNE  stage0_wait
        11 => x"E5800010", -- STR  r0, [r0, #16]  ; commit stage0

        12 => x"E5800008", -- STR  r0, [r0, #8]   ; start stage1
        13 => x"E5905004", -- LDR  r5, [r0, #4]
        14 => x"E355000F", -- CMP  r5, #15
        15 => x"1AFFFFFC", -- BNE  stage1_wait
        16 => x"E5800014", -- STR  r0, [r0, #20]  ; commit stage1

        17 => x"E580000C", -- STR  r0, [r0, #12]  ; start stage2
        18 => x"E5905004", -- LDR  r5, [r0, #4]
        19 => x"E355000F", -- CMP  r5, #15
        20 => x"1AFFFFFC", -- BNE  stage2_wait
        21 => x"E5800018", -- STR  r0, [r0, #24]  ; commit stage2
        22 => x"E1A0F00E", -- MOV  pc, lr

        -- Concrete work-memory LDR/STR examples kept in ROM for reports.
        23 => x"E5906040", -- LDR  r6, [r0, #64]   ; buf_a[0]
        24 => x"E5806080", -- STR  r6, [r0, #128]  ; buf_b[0]
        others => x"E1A00000" -- MOV r0, r0 (NOP)
    );
begin
    instr <= PROGRAM(rom_index(pc_index));
end architecture rtl;
