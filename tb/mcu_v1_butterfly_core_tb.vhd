library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;

entity mcu_v1_butterfly_core_tb is
end entity mcu_v1_butterfly_core_tb;

architecture sim of mcu_v1_butterfly_core_tb is
    signal clk : std_logic := '0';
    signal rst : std_logic := '1';
    signal start : std_logic := '0';
    signal twiddle_mode : std_logic_vector(1 downto 0) := (others => '0');
    signal a_in : std_logic_vector(31 downto 0) := (others => '0');
    signal b_in : std_logic_vector(31 downto 0) := (others => '0');
    signal even_out : std_logic_vector(31 downto 0);
    signal odd_out : std_logic_vector(31 downto 0);
    signal done : std_logic;
    signal busy : std_logic;

    function pack_complex(real_value : integer; imag_value : integer) return std_logic_vector is
    begin
        return std_logic_vector(to_signed(imag_value, 16))
            & std_logic_vector(to_signed(real_value, 16));
    end function;

    function lane_real(value : std_logic_vector(31 downto 0)) return integer is
    begin
        return to_integer(signed(value(15 downto 0)));
    end function;

    function lane_imag(value : std_logic_vector(31 downto 0)) return integer is
    begin
        return to_integer(signed(value(31 downto 16)));
    end function;

    function wrap16(value : integer) return integer is
        variable tmp : integer;
    begin
        tmp := value mod 65536;
        if tmp < 0 then
            tmp := tmp + 65536;
        end if;
        if tmp >= 32768 then
            tmp := tmp - 65536;
        end if;
        return tmp;
    end function;

    function smuad_model(value : std_logic_vector(31 downto 0); coeff : std_logic_vector(31 downto 0))
        return integer is
    begin
        return lane_real(value) * lane_real(coeff) + lane_imag(value) * lane_imag(coeff);
    end function;

    function smusd_model(value : std_logic_vector(31 downto 0); coeff : std_logic_vector(31 downto 0))
        return integer is
    begin
        return lane_real(value) * lane_real(coeff) - lane_imag(value) * lane_imag(coeff);
    end function;

    function pkhbt_shift_model(low_value : integer; high_value : integer; amount : natural)
        return std_logic_vector is
        variable low_bits : unsigned(31 downto 0);
        variable high_bits : unsigned(31 downto 0);
        variable shifted_high : unsigned(31 downto 0);
    begin
        low_bits := unsigned(std_logic_vector(to_signed(low_value, 32)));
        high_bits := unsigned(std_logic_vector(to_signed(high_value, 32)));
        shifted_high := shift_left(high_bits, amount);
        return std_logic_vector(shifted_high(31 downto 16)) & std_logic_vector(low_bits(15 downto 0));
    end function;

    function asr_int(value : integer; amount : natural) return integer is
        variable scale : integer := 1;
    begin
        for i in 1 to amount loop
            scale := scale * 2;
        end loop;

        if value >= 0 then
            return value / scale;
        end if;
        return -((-value + scale - 1) / scale);
    end function;

    function twiddle_model(value : std_logic_vector(31 downto 0); mode : std_logic_vector(1 downto 0))
        return std_logic_vector is
        constant coeff_pos : std_logic_vector(31 downto 0) := pack_complex(91, 91);
        constant coeff_neg : std_logic_vector(31 downto 0) := pack_complex(-91, -91);
        variable tmp_re : integer;
        variable tmp_im : integer;
    begin
        if mode = "00" then
            return value;
        elsif mode = "10" then
            return pack_complex(wrap16(lane_imag(value)), wrap16(-lane_real(value)));
        elsif mode = "01" then
            tmp_re := smuad_model(value, coeff_pos);
            tmp_im := smusd_model(value, coeff_neg);
            return pkhbt_shift_model(asr_int(tmp_re, 7), tmp_im, 9);
        else
            tmp_re := smusd_model(value, coeff_neg);
            tmp_im := smuad_model(value, coeff_neg);
            return pkhbt_shift_model(asr_int(tmp_re, 7), tmp_im, 9);
        end if;
    end function;

    function sadd16_model(a : std_logic_vector(31 downto 0); b : std_logic_vector(31 downto 0))
        return std_logic_vector is
    begin
        return pack_complex(
            wrap16(lane_real(a) + lane_real(b)),
            wrap16(lane_imag(a) + lane_imag(b))
        );
    end function;

    function ssub16_model(a : std_logic_vector(31 downto 0); b : std_logic_vector(31 downto 0))
        return std_logic_vector is
    begin
        return pack_complex(
            wrap16(lane_real(a) - lane_real(b)),
            wrap16(lane_imag(a) - lane_imag(b))
        );
    end function;
begin
    clk <= not clk after 5 ns;

    dut : entity work.mcu_v1_butterfly_core
        port map (
            clk => clk,
            rst => rst,
            start => start,
            twiddle_mode => twiddle_mode,
            a_in => a_in,
            b_in => b_in,
            even_out => even_out,
            odd_out => odd_out,
            done => done,
            busy => busy
        );

    stim : process
        variable expected_twiddle : std_logic_vector(31 downto 0);
        variable expected_even : std_logic_vector(31 downto 0);
        variable expected_odd : std_logic_vector(31 downto 0);

        procedure wait_cycles(count : natural) is
        begin
            for i in 1 to count loop
                wait until rising_edge(clk);
            end loop;
        end procedure;

        procedure run_case(
            constant label_text : string;
            constant a_real : integer;
            constant a_imag : integer;
            constant b_real : integer;
            constant b_imag : integer;
            constant mode : std_logic_vector(1 downto 0)
        ) is
            variable wait_count : natural;
        begin
            a_in <= pack_complex(a_real, a_imag);
            b_in <= pack_complex(b_real, b_imag);
            twiddle_mode <= mode;
            expected_twiddle := twiddle_model(pack_complex(b_real, b_imag), mode);
            expected_even := sadd16_model(pack_complex(a_real, a_imag), expected_twiddle);
            expected_odd := ssub16_model(pack_complex(a_real, a_imag), expected_twiddle);

            start <= '1';
            wait until rising_edge(clk);
            wait for 1 ns;
            start <= '0';

            wait_count := 0;
            while done = '0' and wait_count < 20 loop
                wait until rising_edge(clk);
                wait for 1 ns;
                wait_count := wait_count + 1;
            end loop;

            assert done = '1'
                report label_text & " did not assert done"
                severity failure;
            assert even_out = expected_even
                report label_text & " even mismatch"
                severity failure;
            assert odd_out = expected_odd
                report label_text & " odd mismatch"
                severity failure;
        end procedure;
    begin
        wait_cycles(2);
        rst <= '0';
        wait_cycles(1);

        run_case("W0", 1664, -3456, -1152, 0, "00");
        run_case("W2", -2048, 3584, 768, -2688, "10");
        run_case("W1", 2304, -1152, -1792, 896, "01");
        run_case("W3", -384, 1408, 2560, -3200, "11");
        run_case("mixed negative W1", -6134, 12668, 5878, 3204, "01");
        run_case("mixed negative W3", 6784, 11264, -1442, -10124, "11");

        report "mcu_v1_butterfly_core_tb passed" severity note;
        finish;
    end process;
end architecture sim;
