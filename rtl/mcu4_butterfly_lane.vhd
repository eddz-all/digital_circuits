library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.mcu4_multi_pkg.all;

entity mcu4_butterfly_lane is
    port (
        clk          : in  std_logic;
        rst          : in  std_logic;
        start        : in  std_logic;
        twiddle_mode : in  lane_mode_t;
        a_in         : in  word_t;
        b_in         : in  word_t;
        even_out     : out word_t;
        odd_out      : out word_t;
        done         : out std_logic;
        busy         : out std_logic
    );
end entity mcu4_butterfly_lane;

architecture rtl of mcu4_butterfly_lane is
    type state_t is (
        S_IDLE,
        S_TWIDDLE_RE,
        S_TWIDDLE_RE_SUM,
        S_TWIDDLE_IM_MUL,
        S_TWIDDLE_IM,
        S_TWIDDLE_PACK,
        S_BUTTERFLY
    );

    constant PACK_91      : word_t := x"005B005B";
    constant PACK_NEG_91  : word_t := x"FFA5FFA5";
    constant PACK_ZERO    : word_t := (others => '0');

    signal state_reg : state_t := S_IDLE;
    signal mode_reg  : lane_mode_t := MODE_W0;
    signal a_reg     : word_t := (others => '0');
    signal b_reg     : word_t := (others => '0');
    signal t_reg     : word_t := (others => '0');
    signal tmp_re    : word_t := (others => '0');
    signal tmp_im    : word_t := (others => '0');
    signal prod_lo_reg : signed(31 downto 0) := (others => '0');
    signal prod_hi_reg : signed(31 downto 0) := (others => '0');
    signal prod_sub_reg : std_logic := '0';
    signal even_reg  : word_t := (others => '0');
    signal odd_reg   : word_t := (others => '0');
    signal done_reg  : std_logic := '0';

    attribute use_dsp : string;
    attribute use_dsp of prod_lo_reg : signal is "yes";
    attribute use_dsp of prod_hi_reg : signal is "yes";

    function sadd16(a : word_t; b : word_t) return word_t is
        variable a_lo17 : signed(16 downto 0);
        variable a_hi17 : signed(16 downto 0);
        variable b_lo17 : signed(16 downto 0);
        variable b_hi17 : signed(16 downto 0);
        variable lo17   : signed(16 downto 0);
        variable hi17   : signed(16 downto 0);
    begin
        a_lo17 := resize(signed(a(15 downto 0)), 17);
        a_hi17 := resize(signed(a(31 downto 16)), 17);
        b_lo17 := resize(signed(b(15 downto 0)), 17);
        b_hi17 := resize(signed(b(31 downto 16)), 17);
        lo17 := a_lo17 + b_lo17;
        hi17 := a_hi17 + b_hi17;
        return std_logic_vector(hi17(15 downto 0)) & std_logic_vector(lo17(15 downto 0));
    end function;

    function ssub16(a : word_t; b : word_t) return word_t is
        variable a_lo17 : signed(16 downto 0);
        variable a_hi17 : signed(16 downto 0);
        variable b_lo17 : signed(16 downto 0);
        variable b_hi17 : signed(16 downto 0);
        variable lo17   : signed(16 downto 0);
        variable hi17   : signed(16 downto 0);
    begin
        a_lo17 := resize(signed(a(15 downto 0)), 17);
        a_hi17 := resize(signed(a(31 downto 16)), 17);
        b_lo17 := resize(signed(b(15 downto 0)), 17);
        b_hi17 := resize(signed(b(31 downto 16)), 17);
        lo17 := a_lo17 - b_lo17;
        hi17 := a_hi17 - b_hi17;
        return std_logic_vector(hi17(15 downto 0)) & std_logic_vector(lo17(15 downto 0));
    end function;

    function ssax(a : word_t; b : word_t) return word_t is
        variable a_lo17 : signed(16 downto 0);
        variable a_hi17 : signed(16 downto 0);
        variable b_lo17 : signed(16 downto 0);
        variable b_hi17 : signed(16 downto 0);
        variable lo17   : signed(16 downto 0);
        variable hi17   : signed(16 downto 0);
    begin
        a_lo17 := resize(signed(a(15 downto 0)), 17);
        a_hi17 := resize(signed(a(31 downto 16)), 17);
        b_lo17 := resize(signed(b(15 downto 0)), 17);
        b_hi17 := resize(signed(b(31 downto 16)), 17);
        lo17 := a_lo17 + b_hi17;
        hi17 := a_hi17 - b_lo17;
        return std_logic_vector(hi17(15 downto 0)) & std_logic_vector(lo17(15 downto 0));
    end function;

    function smuad(a : word_t; b : word_t) return word_t is
        variable prod_lo : signed(31 downto 0);
        variable prod_hi : signed(31 downto 0);
        variable sum32   : signed(31 downto 0);
    begin
        prod_lo := signed(a(15 downto 0)) * signed(b(15 downto 0));
        prod_hi := signed(a(31 downto 16)) * signed(b(31 downto 16));
        sum32 := prod_lo + prod_hi;
        return std_logic_vector(sum32);
    end function;

    function smusd(a : word_t; b : word_t) return word_t is
        variable prod_lo : signed(31 downto 0);
        variable prod_hi : signed(31 downto 0);
        variable sum32   : signed(31 downto 0);
    begin
        prod_lo := signed(a(15 downto 0)) * signed(b(15 downto 0));
        prod_hi := signed(a(31 downto 16)) * signed(b(31 downto 16));
        sum32 := prod_lo - prod_hi;
        return std_logic_vector(sum32);
    end function;

    function asr32(value : word_t; amount : natural) return word_t is
    begin
        return std_logic_vector(shift_right(signed(value), amount));
    end function;
begin
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                state_reg <= S_IDLE;
                mode_reg <= MODE_W0;
                a_reg <= (others => '0');
                b_reg <= (others => '0');
                t_reg <= (others => '0');
                tmp_re <= (others => '0');
                tmp_im <= (others => '0');
                prod_lo_reg <= (others => '0');
                prod_hi_reg <= (others => '0');
                prod_sub_reg <= '0';
                even_reg <= (others => '0');
                odd_reg <= (others => '0');
                done_reg <= '0';
            else
                done_reg <= '0';

                case state_reg is
                    when S_IDLE =>
                        if start = '1' then
                            a_reg <= a_in;
                            b_reg <= b_in;
                            mode_reg <= twiddle_mode;
                            state_reg <= S_TWIDDLE_RE;
                        end if;

                    when S_TWIDDLE_RE =>
                        case mode_reg is
                            when MODE_W0 =>
                                t_reg <= b_reg;
                                state_reg <= S_BUTTERFLY;
                            when MODE_W2 =>
                                t_reg <= ssax(PACK_ZERO, b_reg);
                                state_reg <= S_BUTTERFLY;
                            when MODE_W1 =>
                                prod_lo_reg <= signed(b_reg(15 downto 0)) * signed(PACK_91(15 downto 0));
                                prod_hi_reg <= signed(b_reg(31 downto 16)) * signed(PACK_91(31 downto 16));
                                prod_sub_reg <= '0';
                                state_reg <= S_TWIDDLE_RE_SUM;
                            when others =>
                                prod_lo_reg <= signed(b_reg(15 downto 0)) * signed(PACK_NEG_91(15 downto 0));
                                prod_hi_reg <= signed(b_reg(31 downto 16)) * signed(PACK_NEG_91(31 downto 16));
                                prod_sub_reg <= '1';
                                state_reg <= S_TWIDDLE_RE_SUM;
                        end case;

                    when S_TWIDDLE_RE_SUM =>
                        if prod_sub_reg = '1' then
                            tmp_re <= std_logic_vector(prod_lo_reg - prod_hi_reg);
                        else
                            tmp_re <= std_logic_vector(prod_lo_reg + prod_hi_reg);
                        end if;
                        state_reg <= S_TWIDDLE_IM_MUL;

                    when S_TWIDDLE_IM_MUL =>
                        prod_lo_reg <= signed(b_reg(15 downto 0)) * signed(PACK_NEG_91(15 downto 0));
                        prod_hi_reg <= signed(b_reg(31 downto 16)) * signed(PACK_NEG_91(31 downto 16));
                        if mode_reg = MODE_W1 then
                            prod_sub_reg <= '1';
                        else
                            prod_sub_reg <= '0';
                        end if;
                        state_reg <= S_TWIDDLE_IM;

                    when S_TWIDDLE_IM =>
                        if prod_sub_reg = '1' then
                            tmp_im <= std_logic_vector(prod_lo_reg - prod_hi_reg);
                        else
                            tmp_im <= std_logic_vector(prod_lo_reg + prod_hi_reg);
                        end if;
                        state_reg <= S_TWIDDLE_PACK;

                    when S_TWIDDLE_PACK =>
                        t_reg <= pkhbt_shift(asr32(tmp_re, 7), tmp_im, 9);
                        state_reg <= S_BUTTERFLY;

                    when S_BUTTERFLY =>
                        even_reg <= sadd16(a_reg, t_reg);
                        odd_reg <= ssub16(a_reg, t_reg);
                        done_reg <= '1';
                        state_reg <= S_IDLE;
                end case;
            end if;
        end if;
    end process;

    even_out <= even_reg;
    odd_out <= odd_reg;
    done <= done_reg;
    busy <= '1' when state_reg /= S_IDLE else '0';
end architecture rtl;
