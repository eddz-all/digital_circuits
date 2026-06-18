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
        set_instr(rom, 1, x"E3A0A05B");
        set_instr(rom, 2, x"E048B00A");
        set_instr(rom, 3, x"ECAAC00A");
        set_instr(rom, 4, x"ECABD00B");
        set_instr(rom, 5, x"E7080200");
        set_instr(rom, 6, x"E708E220");
        set_instr(rom, 7, x"E1A00380");
        set_instr(rom, 8, x"E1A0E38E");
        set_instr(rom, 9, x"ECA0000E");
        set_instr(rom, 10, x"E7081210");
        set_instr(rom, 11, x"E708E230");
        set_instr(rom, 12, x"E1A01381");
        set_instr(rom, 13, x"E1A0E38E");
        set_instr(rom, 14, x"ECA1100E");
        set_instr(rom, 15, x"E7082208");
        set_instr(rom, 16, x"E708E228");
        set_instr(rom, 17, x"E1A02382");
        set_instr(rom, 18, x"E1A0E38E");
        set_instr(rom, 19, x"ECA2200E");
        set_instr(rom, 20, x"E7083218");
        set_instr(rom, 21, x"E708E238");
        set_instr(rom, 22, x"E1A03383");
        set_instr(rom, 23, x"E1A0E38E");
        set_instr(rom, 24, x"ECA3300E");
        set_instr(rom, 25, x"E7084204");
        set_instr(rom, 26, x"E708E224");
        set_instr(rom, 27, x"E1A04384");
        set_instr(rom, 28, x"E1A0E38E");
        set_instr(rom, 29, x"ECA4400E");
        set_instr(rom, 30, x"E7085214");
        set_instr(rom, 31, x"E708E234");
        set_instr(rom, 32, x"E1A05385");
        set_instr(rom, 33, x"E1A0E38E");
        set_instr(rom, 34, x"ECA5500E");
        set_instr(rom, 35, x"E708620C");
        set_instr(rom, 36, x"E708E22C");
        set_instr(rom, 37, x"E1A06386");
        set_instr(rom, 38, x"E1A0E38E");
        set_instr(rom, 39, x"ECA6600E");
        set_instr(rom, 40, x"E708721C");
        set_instr(rom, 41, x"E708E23C");
        set_instr(rom, 42, x"E1A07387");
        set_instr(rom, 43, x"E1A0E38E");
        set_instr(rom, 44, x"ECA7700E");
        set_instr(rom, 45, x"ED20E001");
        set_instr(rom, 46, x"ED800001");
        set_instr(rom, 47, x"E1A0100E");
        set_instr(rom, 48, x"ED22E003");
        set_instr(rom, 49, x"ED822003");
        set_instr(rom, 50, x"E1A0300E");
        set_instr(rom, 51, x"ED24E005");
        set_instr(rom, 52, x"ED844005");
        set_instr(rom, 53, x"E1A0500E");
        set_instr(rom, 54, x"ED26E007");
        set_instr(rom, 55, x"ED866007");
        set_instr(rom, 56, x"E1A0700E");
        set_instr(rom, 57, x"ED20E002");
        set_instr(rom, 58, x"ED800002");
        set_instr(rom, 59, x"E1A0200E");
        set_instr(rom, 60, x"ED083003");
        set_instr(rom, 61, x"ED21E003");
        set_instr(rom, 62, x"ED811003");
        set_instr(rom, 63, x"E1A0300E");
        set_instr(rom, 64, x"ED24E006");
        set_instr(rom, 65, x"ED844006");
        set_instr(rom, 66, x"E1A0600E");
        set_instr(rom, 67, x"ED087007");
        set_instr(rom, 68, x"ED25E007");
        set_instr(rom, 69, x"ED855007");
        set_instr(rom, 70, x"E1A0700E");
        set_instr(rom, 71, x"ED20E004");
        set_instr(rom, 72, x"ED800004");
        set_instr(rom, 73, x"E1A0400E");
        set_instr(rom, 74, x"EC45E00C");
        set_instr(rom, 75, x"EC65F00D");
        set_instr(rom, 76, x"E3EEE007");
        set_instr(rom, 77, x"E3EFF007");
        set_instr(rom, 78, x"ECAE500F");
        set_instr(rom, 79, x"ED21E005");
        set_instr(rom, 80, x"ED811005");
        set_instr(rom, 81, x"E1A0500E");
        set_instr(rom, 82, x"ED086006");
        set_instr(rom, 83, x"ED22E006");
        set_instr(rom, 84, x"ED822006");
        set_instr(rom, 85, x"E1A0600E");
        set_instr(rom, 86, x"EC67E00D");
        set_instr(rom, 87, x"EC47F00D");
        set_instr(rom, 88, x"E3EEE007");
        set_instr(rom, 89, x"E3EFF007");
        set_instr(rom, 90, x"ECAE700F");
        set_instr(rom, 91, x"ED23E007");
        set_instr(rom, 92, x"ED833007");
        set_instr(rom, 93, x"E1A0700E");
        set_instr(rom, 94, x"E3A0A800");
        set_instr(rom, 95, x"ED7A00FF");
        set_instr(rom, 96, x"E3E00010");
        set_instr(rom, 97, x"E3E11010");
        set_instr(rom, 98, x"E3E22010");
        set_instr(rom, 99, x"E3E33010");
        set_instr(rom, 100, x"E3E44010");
        set_instr(rom, 101, x"E3E55010");
        set_instr(rom, 102, x"E3E66010");
        set_instr(rom, 103, x"E3E77010");
        set_instr(rom, 104, x"ED7A00FF");
        set_instr(rom, 105, x"E8FFFFFE");
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
