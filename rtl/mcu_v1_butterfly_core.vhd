library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mcu_v1_butterfly_core is
    port (
        clk          : in  std_logic;
        rst          : in  std_logic;
        start        : in  std_logic;
        twiddle_mode : in  std_logic_vector(1 downto 0);
        a_in         : in  std_logic_vector(31 downto 0);
        b_in         : in  std_logic_vector(31 downto 0);
        even_out     : out std_logic_vector(31 downto 0);
        odd_out      : out std_logic_vector(31 downto 0);
        done         : out std_logic;
        busy         : out std_logic
    );
end entity mcu_v1_butterfly_core;

architecture rtl of mcu_v1_butterfly_core is
    type state_t is (
        S_IDLE,
        S_TWIDDLE_RE,
        S_TWIDDLE_IM,
        S_TWIDDLE_PACK,
        S_BUTTERFLY
    );

    constant MODE_W0 : std_logic_vector(1 downto 0) := "00";
    constant MODE_W1 : std_logic_vector(1 downto 0) := "01";
    constant MODE_W2 : std_logic_vector(1 downto 0) := "10";
    constant MODE_W3 : std_logic_vector(1 downto 0) := "11";

    constant PACK_91      : std_logic_vector(31 downto 0) := x"005B005B";
    constant PACK_NEG_91  : std_logic_vector(31 downto 0) := x"FFA5FFA5";
    constant PACK_ZERO    : std_logic_vector(31 downto 0) := (others => '0');

    signal state_reg : state_t := S_IDLE;
    signal mode_reg  : std_logic_vector(1 downto 0) := MODE_W0;
    signal a_reg     : std_logic_vector(31 downto 0) := (others => '0');
    signal b_reg     : std_logic_vector(31 downto 0) := (others => '0');
    signal t_reg     : std_logic_vector(31 downto 0) := (others => '0');
    signal tmp_re    : std_logic_vector(31 downto 0) := (others => '0');
    signal tmp_im    : std_logic_vector(31 downto 0) := (others => '0');
    signal even_reg  : std_logic_vector(31 downto 0) := (others => '0');
    signal odd_reg   : std_logic_vector(31 downto 0) := (others => '0');
    signal done_reg  : std_logic := '0';

    function sadd16(a : std_logic_vector(31 downto 0); b : std_logic_vector(31 downto 0))
        return std_logic_vector is
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

    function ssub16(a : std_logic_vector(31 downto 0); b : std_logic_vector(31 downto 0))
        return std_logic_vector is
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

    function ssax(a : std_logic_vector(31 downto 0); b : std_logic_vector(31 downto 0))
        return std_logic_vector is
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

    function smuad(a : std_logic_vector(31 downto 0); b : std_logic_vector(31 downto 0))
        return std_logic_vector is
        variable prod_lo : signed(31 downto 0);
        variable prod_hi : signed(31 downto 0);
        variable sum32   : signed(31 downto 0);
    begin
        prod_lo := signed(a(15 downto 0)) * signed(b(15 downto 0));
        prod_hi := signed(a(31 downto 16)) * signed(b(31 downto 16));
        sum32 := prod_lo + prod_hi;
        return std_logic_vector(sum32);
    end function;

    function smusd(a : std_logic_vector(31 downto 0); b : std_logic_vector(31 downto 0))
        return std_logic_vector is
        variable prod_lo : signed(31 downto 0);
        variable prod_hi : signed(31 downto 0);
        variable sum32   : signed(31 downto 0);
    begin
        prod_lo := signed(a(15 downto 0)) * signed(b(15 downto 0));
        prod_hi := signed(a(31 downto 16)) * signed(b(31 downto 16));
        sum32 := prod_lo - prod_hi;
        return std_logic_vector(sum32);
    end function;

    function asr32(value : std_logic_vector(31 downto 0); amount : natural)
        return std_logic_vector is
    begin
        return std_logic_vector(shift_right(signed(value), amount));
    end function;

    function pkhbt_shift(
        low_value  : std_logic_vector(31 downto 0);
        high_value : std_logic_vector(31 downto 0);
        amount     : natural
    ) return std_logic_vector is
        variable shifted_high : unsigned(31 downto 0);
    begin
        shifted_high := shift_left(unsigned(high_value), amount);
        return std_logic_vector(shifted_high(31 downto 16)) & low_value(15 downto 0);
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
                                tmp_re <= smuad(b_reg, PACK_91);
                                state_reg <= S_TWIDDLE_IM;
                            when others =>
                                tmp_re <= smusd(b_reg, PACK_NEG_91);
                                state_reg <= S_TWIDDLE_IM;
                        end case;

                    when S_TWIDDLE_IM =>
                        if mode_reg = MODE_W1 then
                            tmp_im <= smusd(b_reg, PACK_NEG_91);
                        else
                            tmp_im <= smuad(b_reg, PACK_NEG_91);
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
