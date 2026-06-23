library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package mcu4_multi_pkg is
    subtype half_t is std_logic_vector(15 downto 0);
    subtype word_t is std_logic_vector(31 downto 0);
    subtype reg_addr_t is std_logic_vector(3 downto 0);

    type sample16_array_t is array (0 to 15) of half_t;
    type complex8_array_t is array (0 to 7) of word_t;
    type lane4_word_array_t is array (0 to 3) of word_t;
    type reg_file_t is array (0 to 15) of word_t;
    type program_rom_t is array (0 to 63) of word_t;

    type index8_array_t is array (0 to 7) of natural range 0 to 7;
    constant BITREV_ORDER : index8_array_t := (0, 4, 2, 6, 1, 5, 3, 7);

    type worker_op_t is (
        WOP_NOP,
        WOP_MOV_IMM,
        WOP_MOV_REG,
        WOP_ADD,
        WOP_SUB,
        WOP_AND,
        WOP_ORR,
        WOP_PKHBT,
        WOP_LDR_A,
        WOP_LDR_B,
        WOP_STR_A,
        WOP_STR_B,
        WOP_SADD16,
        WOP_SSUB16,
        WOP_SSAX,
        WOP_SMUAD,
        WOP_SMUSD,
        WOP_ASR,
        WOP_B,
        WOP_BL,
        WOP_HALT
    );

    constant REG_ZERO    : natural := 0;
    constant REG_POS91   : natural := 1;
    constant REG_PACK91  : natural := 3;
    constant REG_PACKN91 : natural := 4;
    constant REG_A       : natural := 5;
    constant REG_B       : natural := 6;
    constant REG_TMP_RE  : natural := 7;
    constant REG_TMP_IM  : natural := 8;
    constant REG_T       : natural := 9;
    constant REG_EVEN    : natural := 10;
    constant REG_ODD     : natural := 11;
    constant REG_LR      : natural := 14;
    constant REG_PC      : natural := 15;

    constant WORK_BUF_A_BASE_WORD : natural := 16;
    constant WORK_BUF_B_BASE_WORD : natural := 32;
    constant WORK_BUF_WORDS       : natural := 8;

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
