library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package mcu4_multi_pkg is
    subtype half_t is std_logic_vector(15 downto 0);
    subtype word_t is std_logic_vector(31 downto 0);
    subtype reg_addr_t is std_logic_vector(3 downto 0);
    subtype lane_mode_t is std_logic_vector(1 downto 0);

    type sample16_array_t is array (0 to 15) of half_t;
    type complex8_array_t is array (0 to 7) of word_t;
    type lane4_word_array_t is array (0 to 3) of word_t;
    type lane4_mode_array_t is array (0 to 3) of lane_mode_t;
    type reg_file_t is array (0 to 15) of word_t;
    type program_rom_t is array (0 to 31) of word_t;

    type index8_array_t is array (0 to 7) of natural range 0 to 7;
    constant BITREV_ORDER : index8_array_t := (0, 4, 2, 6, 1, 5, 3, 7);

    constant MODE_W0 : lane_mode_t := "00";
    constant MODE_W1 : lane_mode_t := "01";
    constant MODE_W2 : lane_mode_t := "10";
    constant MODE_W3 : lane_mode_t := "11";

    constant COND_AL : std_logic_vector(3 downto 0) := x"E";
    constant COND_EQ : std_logic_vector(3 downto 0) := x"0";
    constant COND_NE : std_logic_vector(3 downto 0) := x"1";

    constant ALU_AND   : std_logic_vector(3 downto 0) := x"0";
    constant ALU_ORR   : std_logic_vector(3 downto 0) := x"1";
    constant ALU_ADD   : std_logic_vector(3 downto 0) := x"2";
    constant ALU_SUB   : std_logic_vector(3 downto 0) := x"3";
    constant ALU_MOV   : std_logic_vector(3 downto 0) := x"4";
    constant ALU_PASS  : std_logic_vector(3 downto 0) := x"5";

    constant FFT_STAGE0_PC : natural := 9;
    constant FFT_STAGE1_PC : natural := 15;
    constant FFT_STAGE2_PC : natural := 21;
    constant HALT_PC       : natural := 8;
    constant FFT_STAGE0_RET_PC : natural := 6;
    constant FFT_STAGE1_RET_PC : natural := 7;
    constant FFT_STAGE2_RET_PC : natural := 8;

    constant EXT_BFLY_START : std_logic_vector(4 downto 0) := "01100";
    constant EXT_BFLY_WAIT  : std_logic_vector(4 downto 0) := "01011";

    function pkhbt_shift(
        low_value  : word_t;
        high_value : word_t;
        amount     : natural
    ) return word_t;

    function pack_q5_to_q12(real_q5 : half_t; imag_q5 : half_t) return word_t;
end package mcu4_multi_pkg;

package body mcu4_multi_pkg is
    function pkhbt_shift(
        low_value  : word_t;
        high_value : word_t;
        amount     : natural
    ) return word_t is
        variable shifted_high : unsigned(31 downto 0);
    begin
        shifted_high := shift_left(unsigned(high_value), amount);
        return std_logic_vector(shifted_high(31 downto 16)) & low_value(15 downto 0);
    end function;

    function pack_q5_to_q12(real_q5 : half_t; imag_q5 : half_t) return word_t is
        variable real32 : word_t;
        variable imag32 : word_t;
    begin
        real32 := std_logic_vector(shift_left(resize(signed(real_q5), 32), 7));
        imag32 := std_logic_vector(resize(signed(imag_q5), 32));
        return pkhbt_shift(real32, imag32, 23);
    end function;
end package body mcu4_multi_pkg;
