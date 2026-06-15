library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

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

    procedure set_instr(
        variable rom   : inout rom_t;
        constant idx   : in natural;
        constant value : in std_logic_vector(31 downto 0)
    ) is
    begin
        if idx < DEPTH then
            rom(idx) := value;
        end if;
    end procedure;

    function is_basic_program(file_name : string) return boolean is
    begin
        return file_name = "asm/test_mcu_v1_basic.mem"
            or file_name = "test_mcu_v1_basic.mem";
    end function;

    function is_fft_program(file_name : string) return boolean is
    begin
        return file_name = "asm/fft8_v1_mcu32_basic.mem"
            or file_name = "fft8_v1_mcu32_basic.mem";
    end function;

    function init_basic_rom return rom_t is
        variable rom : rom_t := (others => (others => '0'));
    begin
        set_instr(rom, 0, x"E3A08000");
        set_instr(rom, 1, x"E3A09100");
        set_instr(rom, 2, x"E3A0A200");
        set_instr(rom, 3, x"E7080000");
        set_instr(rom, 4, x"E7081004");
        set_instr(rom, 5, x"E0802001");
        set_instr(rom, 6, x"E50A2000");
        set_instr(rom, 7, x"E0403001");
        set_instr(rom, 8, x"E50A3004");
        set_instr(rom, 9, x"E3A0CFFF");
        set_instr(rom, 10, x"E28CCFFF");
        set_instr(rom, 11, x"E28CCFFF");
        set_instr(rom, 12, x"E28CCFFF");
        set_instr(rom, 13, x"E28CCFFF");
        set_instr(rom, 14, x"E28CCA87");
        set_instr(rom, 15, x"E120400C");
        set_instr(rom, 16, x"E3E4400F");
        set_instr(rom, 17, x"E50A4008");
        set_instr(rom, 18, x"E3520000");
        set_instr(rom, 19, x"08000002");
        set_instr(rom, 20, x"E3A0507B");
        set_instr(rom, 21, x"E50A500C");
        set_instr(rom, 22, x"E8000001");
        set_instr(rom, 23, x"E3A051C8");
        set_instr(rom, 24, x"E50A500C");
        set_instr(rom, 25, x"E8FFFFFE");
        return rom;
    end function;

    function init_fft_rom return rom_t is
        variable rom : rom_t := (others => (others => '0'));
    begin
        set_instr(rom, 0, x"E3A08000");
        set_instr(rom, 1, x"E3A09100");
        set_instr(rom, 2, x"E3A0C800");
        set_instr(rom, 3, x"E3A0D820");
        set_instr(rom, 4, x"E3A0E008");
        set_instr(rom, 5, x"E3A04000");
        set_instr(rom, 6, x"E3A05000");
        set_instr(rom, 7, x"E3A0A200");
        set_instr(rom, 8, x"E3A0B220");
        set_instr(rom, 9, x"E3A06008");
        set_instr(rom, 10, x"E70A0000");
        set_instr(rom, 11, x"E70B1000");
        set_instr(rom, 12, x"E7082000");
        set_instr(rom, 13, x"E7093000");
        set_instr(rom, 14, x"E1207002");
        set_instr(rom, 15, x"E0844007");
        set_instr(rom, 16, x"E1217003");
        set_instr(rom, 17, x"E0444007");
        set_instr(rom, 18, x"E1207003");
        set_instr(rom, 19, x"E0855007");
        set_instr(rom, 20, x"E1217002");
        set_instr(rom, 21, x"E0855007");
        set_instr(rom, 22, x"E2888004");
        set_instr(rom, 23, x"E2899004");
        set_instr(rom, 24, x"E28AA004");
        set_instr(rom, 25, x"E28BB004");
        set_instr(rom, 26, x"E2466001");
        set_instr(rom, 27, x"E3560000");
        set_instr(rom, 28, x"18FFFFEC");
        set_instr(rom, 29, x"E50C4000");
        set_instr(rom, 30, x"E50D5000");
        set_instr(rom, 31, x"E28CC004");
        set_instr(rom, 32, x"E28DD004");
        set_instr(rom, 33, x"E24EE001");
        set_instr(rom, 34, x"E35E0000");
        set_instr(rom, 35, x"18FFFFE0");
        set_instr(rom, 36, x"E8FFFFFE");
        return rom;
    end function;

    function init_rom(file_name : string) return rom_t is
    begin
        if is_basic_program(file_name) then
            return init_basic_rom;
        end if;

        assert is_fft_program(file_name)
            report "unknown mcu_v1_instr_rom MEM_FILE selector; using FFT program"
            severity warning;
        return init_fft_rom;
    end function;

    signal rom : rom_t := init_rom(MEM_FILE);
    signal idx : natural range 0 to DEPTH - 1;
begin
    idx <= to_integer(unsigned(pc(31 downto 2))) when unsigned(pc(31 downto 2)) < DEPTH else 0;
    instr <= rom(idx);
end architecture rtl;
