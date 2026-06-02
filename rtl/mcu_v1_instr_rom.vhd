library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use ieee.std_logic_textio.all;

entity mcu_v1_instr_rom is
    generic (
        MEM_FILE : string := "asm/fft8_v1_mcu32_basic.mem";
        DEPTH    : positive := 1024
    );
    port (
        pc    : in  std_logic_vector(31 downto 0);
        instr : out std_logic_vector(31 downto 0)
    );
end entity mcu_v1_instr_rom;

architecture rtl of mcu_v1_instr_rom is
    type rom_t is array (0 to DEPTH - 1) of std_logic_vector(31 downto 0);

    impure function init_rom(file_name : string) return rom_t is
        file f       : text open read_mode is file_name;
        variable l   : line;
        variable rom : rom_t := (others => (others => '0'));
        variable w   : std_logic_vector(31 downto 0);
        variable i   : natural := 0;
    begin
        while not endfile(f) loop
            readline(f, l);
            if l'length > 0 then
                hread(l, w);
                if i < DEPTH then
                    rom(i) := w;
                end if;
                i := i + 1;
            end if;
        end loop;
        return rom;
    end function;

    signal rom : rom_t := init_rom(MEM_FILE);
    signal idx : natural range 0 to DEPTH - 1;
begin
    idx <= to_integer(unsigned(pc(31 downto 2))) when unsigned(pc(31 downto 2)) < DEPTH else 0;
    instr <= rom(idx);
end architecture rtl;
