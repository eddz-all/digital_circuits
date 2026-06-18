library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package mcu_8core_dsp_pkg is
    subtype word_t is std_logic_vector(31 downto 0);
    subtype half_t is std_logic_vector(15 downto 0);

    type reg_file_t is array (0 to 15) of word_t;
    type input_mem_t is array (0 to 15) of half_t;
    type output_pair_t is array (0 to 1) of half_t;
    type word_array_t is array (natural range <>) of word_t;
    type half_array_t is array (natural range <>) of half_t;

    constant CORE_COUNT       : natural := 8;
    constant INPUT_COUNT_DSP  : natural := 16;
    constant OUTPUT_COUNT_DSP : natural := 16;

    constant INPUT_BASE : natural := 16#000#;
    constant COEFF_BASE : natural := 16#100#;
    constant OUTPUT_BASE : natural := 16#200#;

    constant REG_ACC_RE : natural := 0;
    constant REG_ACC_IM : natural := 1;
    constant REG_X      : natural := 2;
    constant REG_W      : natural := 3;
    constant REG_OUT_RE : natural := 4;
    constant REG_OUT_IM : natural := 5;
    constant REG_IN_BASE : natural := 10;
    constant REG_COEFF_BASE : natural := 11;
    constant REG_OUT_BASE : natural := 12;

    constant OP_NOP    : std_logic_vector(3 downto 0) := x"0";
    constant OP_MOVI   : std_logic_vector(3 downto 0) := x"1";
    constant OP_LDR    : std_logic_vector(3 downto 0) := x"2";
    constant OP_STR    : std_logic_vector(3 downto 0) := x"3";
    constant OP_MUL    : std_logic_vector(3 downto 0) := x"4";
    constant OP_MLA    : std_logic_vector(3 downto 0) := x"5";
    constant OP_SMLSD  : std_logic_vector(3 downto 0) := x"6";
    constant OP_SMLADX : std_logic_vector(3 downto 0) := x"7";
    constant OP_SSAT   : std_logic_vector(3 downto 0) := x"8";
    constant OP_B      : std_logic_vector(3 downto 0) := x"9";

    constant WORKER_PROGRAM : word_array_t(0 to 63) := (
        0  => x"10000000", -- MOVI   r0, #0
        1  => x"11000000", -- MOVI   r1, #0
        2  => x"1A000000", -- MOVI   r10, #INPUT_BASE
        3  => x"1B000100", -- MOVI   r11, #COEFF_BASE
        4  => x"22A00000", -- LDR    r2, [r10, #0]
        5  => x"23B00000", -- LDR    r3, [r11, #0]
        6  => x"60230000", -- SMLSD  r0, r2, r3, r0
        7  => x"71231000", -- SMLADX r1, r2, r3, r1
        8  => x"22A00004", -- LDR    r2, [r10, #4]
        9  => x"23B00004", -- LDR    r3, [r11, #4]
        10 => x"60230000", -- SMLSD  r0, r2, r3, r0
        11 => x"71231000", -- SMLADX r1, r2, r3, r1
        12 => x"22A00008", -- LDR    r2, [r10, #8]
        13 => x"23B00008", -- LDR    r3, [r11, #8]
        14 => x"60230000", -- SMLSD  r0, r2, r3, r0
        15 => x"71231000", -- SMLADX r1, r2, r3, r1
        16 => x"22A0000C", -- LDR    r2, [r10, #12]
        17 => x"23B0000C", -- LDR    r3, [r11, #12]
        18 => x"60230000", -- SMLSD  r0, r2, r3, r0
        19 => x"71231000", -- SMLADX r1, r2, r3, r1
        20 => x"22A00010", -- LDR    r2, [r10, #16]
        21 => x"23B00010", -- LDR    r3, [r11, #16]
        22 => x"60230000", -- SMLSD  r0, r2, r3, r0
        23 => x"71231000", -- SMLADX r1, r2, r3, r1
        24 => x"22A00014", -- LDR    r2, [r10, #20]
        25 => x"23B00014", -- LDR    r3, [r11, #20]
        26 => x"60230000", -- SMLSD  r0, r2, r3, r0
        27 => x"71231000", -- SMLADX r1, r2, r3, r1
        28 => x"22A00018", -- LDR    r2, [r10, #24]
        29 => x"23B00018", -- LDR    r3, [r11, #24]
        30 => x"60230000", -- SMLSD  r0, r2, r3, r0
        31 => x"71231000", -- SMLADX r1, r2, r3, r1
        32 => x"22A0001C", -- LDR    r2, [r10, #28]
        33 => x"23B0001C", -- LDR    r3, [r11, #28]
        34 => x"60230000", -- SMLSD  r0, r2, r3, r0
        35 => x"71231000", -- SMLADX r1, r2, r3, r1
        36 => x"1C000200", -- MOVI   r12, #OUTPUT_BASE
        37 => x"84001000", -- SSAT   r4, r0, #16
        38 => x"85101000", -- SSAT   r5, r1, #16
        39 => x"34C00000", -- STR    r4, [r12, #0]
        40 => x"35C00004", -- STR    r5, [r12, #4]
        41 => x"90000000", -- B      .
        others => x"00000000"
    );

    function pack_complex(real_part : half_t; imag_part : half_t) return word_t;
    function coeff_word(core_id : natural; sample_idx : natural) return word_t;
    function input_word(input_mem : input_mem_t; sample_idx : natural) return word_t;
    function smlsd_result(a : word_t; b : word_t; acc : word_t) return word_t;
    function smladx_result(a : word_t; b : word_t; acc : word_t) return word_t;
    function mul_result(a : word_t; b : word_t) return word_t;
    function mla_result(a : word_t; b : word_t; acc : word_t) return word_t;
    function ssat_result(value : word_t; bits : natural) return word_t;
end package mcu_8core_dsp_pkg;

package body mcu_8core_dsp_pkg is
    type coeff_matrix_t is array (0 to 7, 0 to 7) of integer;

    constant DFT_WR : coeff_matrix_t := (
        0 => (128, 128, 128, 128, 128, 128, 128, 128),
        1 => (128, 91, 0, -91, -128, -91, 0, 91),
        2 => (128, 0, -128, 0, 128, 0, -128, 0),
        3 => (128, -91, 0, 91, -128, 91, 0, -91),
        4 => (128, -128, 128, -128, 128, -128, 128, -128),
        5 => (128, -91, 0, 91, -128, 91, 0, -91),
        6 => (128, 0, -128, 0, 128, 0, -128, 0),
        7 => (128, 91, 0, -91, -128, -91, 0, 91)
    );

    constant DFT_WI : coeff_matrix_t := (
        0 => (0, 0, 0, 0, 0, 0, 0, 0),
        1 => (0, -91, -128, -91, 0, 91, 128, 91),
        2 => (0, -128, 0, 128, 0, -128, 0, 128),
        3 => (0, -91, 128, -91, 0, 91, -128, 91),
        4 => (0, 0, 0, 0, 0, 0, 0, 0),
        5 => (0, 91, -128, 91, 0, -91, 128, -91),
        6 => (0, 128, 0, -128, 0, 128, 0, -128),
        7 => (0, 91, 128, 91, 0, -91, -128, -91)
    );

    function pack_complex(real_part : half_t; imag_part : half_t) return word_t is
        variable result : word_t := (others => '0');
    begin
        result(15 downto 0) := real_part;
        result(31 downto 16) := imag_part;
        return result;
    end function;

    function coeff_word(core_id : natural; sample_idx : natural) return word_t is
        variable wr : half_t;
        variable wi : half_t;
        variable c : natural := core_id;
        variable s : natural := sample_idx;
    begin
        if c > 7 then
            c := 0;
        end if;
        if s > 7 then
            s := 0;
        end if;
        wr := std_logic_vector(to_signed(DFT_WR(c, s), 16));
        wi := std_logic_vector(to_signed(DFT_WI(c, s), 16));
        return pack_complex(wr, wi);
    end function;

    function input_word(input_mem : input_mem_t; sample_idx : natural) return word_t is
        variable s : natural := sample_idx;
    begin
        if s > 7 then
            s := 0;
        end if;
        return pack_complex(input_mem(s), input_mem(s + 8));
    end function;

    function smlsd_result(a : word_t; b : word_t; acc : word_t) return word_t is
        variable ar : signed(15 downto 0);
        variable ai : signed(15 downto 0);
        variable br : signed(15 downto 0);
        variable bi : signed(15 downto 0);
        variable p0 : signed(31 downto 0);
        variable p1 : signed(31 downto 0);
        variable result : signed(31 downto 0);
    begin
        ar := signed(a(15 downto 0));
        ai := signed(a(31 downto 16));
        br := signed(b(15 downto 0));
        bi := signed(b(31 downto 16));
        p0 := ar * br;
        p1 := ai * bi;
        result := signed(acc) + p0 - p1;
        return std_logic_vector(result);
    end function;

    function smladx_result(a : word_t; b : word_t; acc : word_t) return word_t is
        variable ar : signed(15 downto 0);
        variable ai : signed(15 downto 0);
        variable br : signed(15 downto 0);
        variable bi : signed(15 downto 0);
        variable p0 : signed(31 downto 0);
        variable p1 : signed(31 downto 0);
        variable result : signed(31 downto 0);
    begin
        ar := signed(a(15 downto 0));
        ai := signed(a(31 downto 16));
        br := signed(b(15 downto 0));
        bi := signed(b(31 downto 16));
        p0 := ar * bi;
        p1 := ai * br;
        result := signed(acc) + p0 + p1;
        return std_logic_vector(result);
    end function;

    function mul_result(a : word_t; b : word_t) return word_t is
        variable product : signed(63 downto 0);
    begin
        product := signed(a) * signed(b);
        return std_logic_vector(product(31 downto 0));
    end function;

    function mla_result(a : word_t; b : word_t; acc : word_t) return word_t is
        variable product : signed(63 downto 0);
        variable result : signed(31 downto 0);
    begin
        product := signed(a) * signed(b);
        result := product(31 downto 0) + signed(acc);
        return std_logic_vector(result);
    end function;

    function ssat_result(value : word_t; bits : natural) return word_t is
        variable value_s : signed(31 downto 0);
        variable max_s : signed(31 downto 0);
        variable min_s : signed(31 downto 0);
        variable result : signed(31 downto 0);
        variable b : natural := bits;
    begin
        if b < 1 then
            b := 1;
        elsif b > 31 then
            b := 31;
        end if;

        value_s := signed(value);
        max_s := to_signed((2 ** (b - 1)) - 1, 32);
        min_s := to_signed(-(2 ** (b - 1)), 32);

        if value_s > max_s then
            result := max_s;
        elsif value_s < min_s then
            result := min_s;
        else
            result := value_s;
        end if;
        return std_logic_vector(result);
    end function;
end package body mcu_8core_dsp_pkg;
