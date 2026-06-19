library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mcu_fft_system_multicore4 is
    generic (
        INPUT_COUNT    : positive := 16;
        INPUT_ROM_BASE : natural := 128;
        OUTPUT_COUNT   : positive := 16
    );
    port (
        clk : in std_logic;
        rst : in std_logic;

        test_rom_addr  : out std_logic_vector(7 downto 0);
        test_rom_en    : out std_logic;
        test_vector_in : in  std_logic_vector(15 downto 0);

        verify_ram_addr   : out std_logic_vector(5 downto 0);
        verify_ram_we     : out std_logic;
        verify_vector_out : out std_logic_vector(15 downto 0);

        cnt_start : out std_logic;
        cnt_stop  : out std_logic;

        done        : out std_logic;
        illegal     : out std_logic;
        pc_debug    : out std_logic_vector(31 downto 0);
        instr_debug : out std_logic_vector(31 downto 0)
    );
end entity mcu_fft_system_multicore4;

architecture rtl of mcu_fft_system_multicore4 is
    type state_t is (
        S_LOAD_REQ,
        S_LOAD_WAIT,
        S_LOAD_STREAM,
        S_STAGE_DISPATCH,
        S_WAIT_CORES,
        S_DUMP_OUTPUT,
        S_DONE
    );

    type sample_array_t is array (0 to 15) of std_logic_vector(15 downto 0);
    type complex_buffer_t is array (0 to 7) of std_logic_vector(31 downto 0);
    type lane_data_t is array (0 to 3) of std_logic_vector(31 downto 0);
    type lane_mode_t is array (0 to 3) of std_logic_vector(1 downto 0);
    type index_map_t is array (0 to 7) of natural range 0 to 7;

    constant BITREV_ORDER : index_map_t := (0, 4, 2, 6, 1, 5, 3, 7);

    signal state : state_t := S_LOAD_REQ;
    signal load_idx : integer range 0 to INPUT_COUNT - 1 := 0;
    signal stage_idx : integer range 0 to 2 := 0;
    signal dump_idx : integer range 0 to OUTPUT_COUNT - 1 := 0;

    signal input_samples : sample_array_t := (others => (others => '0'));
    signal buf_a : complex_buffer_t := (others => (others => '0'));
    signal buf_b : complex_buffer_t := (others => (others => '0'));

    signal lane_start : std_logic_vector(3 downto 0) := (others => '0');
    signal lane_done : std_logic_vector(3 downto 0);
    signal lane_busy : std_logic_vector(3 downto 0);
    signal lane_done_seen : std_logic_vector(3 downto 0) := (others => '0');
    signal lane_a : lane_data_t := (others => (others => '0'));
    signal lane_b : lane_data_t := (others => (others => '0'));
    signal lane_even : lane_data_t;
    signal lane_odd : lane_data_t;
    signal lane_mode : lane_mode_t := (others => (others => '0'));

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

    function pack_q5_to_q12(real_q5 : std_logic_vector(15 downto 0); imag_q5 : std_logic_vector(15 downto 0))
        return std_logic_vector is
        variable real32 : std_logic_vector(31 downto 0);
        variable imag32 : std_logic_vector(31 downto 0);
    begin
        real32 := std_logic_vector(shift_left(resize(signed(real_q5), 32), 7));
        imag32 := std_logic_vector(resize(signed(imag_q5), 32));
        return pkhbt_shift(real32, imag32, 23);
    end function;
begin
    assert INPUT_COUNT = 16
        report "mcu_fft_system_multicore4 currently expects the 16-slot teacher signal window"
        severity failure;
    assert INPUT_ROM_BASE + INPUT_COUNT <= 256
        report "mcu_fft_system_multicore4 input ROM window must fit test_rom_addr[7:0]"
        severity failure;
    assert OUTPUT_COUNT = 16
        report "mcu_fft_system_multicore4 currently dumps exactly 16 FFT output slots"
        severity failure;

    gen_lanes : for i in 0 to 3 generate
        u_lane : entity work.mcu_v1_butterfly_core
            port map (
                clk => clk,
                rst => rst,
                start => lane_start(i),
                twiddle_mode => lane_mode(i),
                a_in => lane_a(i),
                b_in => lane_b(i),
                even_out => lane_even(i),
                odd_out => lane_odd(i),
                done => lane_done(i),
                busy => lane_busy(i)
            );
    end generate;

    done <= '1' when state = S_DONE else '0';
    illegal <= '0';
    pc_debug <= (others => '0');
    instr_debug <= (others => '0');

    process(clk)
        variable last_input : integer;
        variable next_done_seen : std_logic_vector(3 downto 0);
        variable src_idx : natural range 0 to 7;
    begin
        if rising_edge(clk) then
            last_input := INPUT_COUNT - 1;

            if rst = '1' then
                state <= S_LOAD_REQ;
                load_idx <= 0;
                stage_idx <= 0;
                dump_idx <= 0;
                input_samples <= (others => (others => '0'));
                buf_a <= (others => (others => '0'));
                buf_b <= (others => (others => '0'));
                lane_start <= (others => '0');
                lane_done_seen <= (others => '0');
                lane_a <= (others => (others => '0'));
                lane_b <= (others => (others => '0'));
                lane_mode <= (others => (others => '0'));
                test_rom_addr <= (others => '0');
                test_rom_en <= '0';
                verify_ram_addr <= (others => '0');
                verify_ram_we <= '0';
                verify_vector_out <= (others => '0');
                cnt_start <= '0';
                cnt_stop <= '0';
            else
                lane_start <= (others => '0');
                test_rom_en <= '0';
                verify_ram_we <= '0';
                cnt_start <= '0';
                cnt_stop <= '0';

                case state is
                    when S_LOAD_REQ =>
                        test_rom_en <= '1';
                        test_rom_addr <= std_logic_vector(to_unsigned(INPUT_ROM_BASE + load_idx, 8));
                        state <= S_LOAD_WAIT;

                    when S_LOAD_WAIT =>
                        test_rom_en <= '1';
                        load_idx <= 0;
                        if last_input = 0 then
                            test_rom_addr <= std_logic_vector(to_unsigned(INPUT_ROM_BASE, 8));
                        else
                            test_rom_addr <= std_logic_vector(to_unsigned(INPUT_ROM_BASE + 1, 8));
                        end if;
                        state <= S_LOAD_STREAM;

                    when S_LOAD_STREAM =>
                        if load_idx < 8 then
                            input_samples(load_idx) <= test_vector_in;
                        else
                            src_idx := load_idx - 8;
                            input_samples(load_idx) <= test_vector_in;
                            buf_a(BITREV_ORDER(src_idx)) <= pack_q5_to_q12(input_samples(src_idx), test_vector_in);
                        end if;

                        if load_idx = 0 then
                            cnt_start <= '1';
                        end if;

                        if load_idx = last_input then
                            load_idx <= 0;
                            stage_idx <= 0;
                            state <= S_STAGE_DISPATCH;
                        else
                            if load_idx + 1 < last_input then
                                test_rom_en <= '1';
                                test_rom_addr <= std_logic_vector(to_unsigned(INPUT_ROM_BASE + load_idx + 2, 8));
                            end if;
                            load_idx <= load_idx + 1;
                            state <= S_LOAD_STREAM;
                        end if;

                    when S_STAGE_DISPATCH =>
                        lane_done_seen <= (others => '0');
                        lane_start <= (others => '1');

                        if stage_idx = 0 then
                            lane_a(0) <= buf_a(0);
                            lane_b(0) <= buf_a(1);
                            lane_mode(0) <= "00";
                            lane_a(1) <= buf_a(2);
                            lane_b(1) <= buf_a(3);
                            lane_mode(1) <= "00";
                            lane_a(2) <= buf_a(4);
                            lane_b(2) <= buf_a(5);
                            lane_mode(2) <= "00";
                            lane_a(3) <= buf_a(6);
                            lane_b(3) <= buf_a(7);
                            lane_mode(3) <= "00";
                        elsif stage_idx = 1 then
                            lane_a(0) <= buf_b(0);
                            lane_b(0) <= buf_b(2);
                            lane_mode(0) <= "00";
                            lane_a(1) <= buf_b(1);
                            lane_b(1) <= buf_b(3);
                            lane_mode(1) <= "10";
                            lane_a(2) <= buf_b(4);
                            lane_b(2) <= buf_b(6);
                            lane_mode(2) <= "00";
                            lane_a(3) <= buf_b(5);
                            lane_b(3) <= buf_b(7);
                            lane_mode(3) <= "10";
                        else
                            lane_a(0) <= buf_a(0);
                            lane_b(0) <= buf_a(4);
                            lane_mode(0) <= "00";
                            lane_a(1) <= buf_a(1);
                            lane_b(1) <= buf_a(5);
                            lane_mode(1) <= "01";
                            lane_a(2) <= buf_a(2);
                            lane_b(2) <= buf_a(6);
                            lane_mode(2) <= "10";
                            lane_a(3) <= buf_a(3);
                            lane_b(3) <= buf_a(7);
                            lane_mode(3) <= "11";
                        end if;

                        state <= S_WAIT_CORES;

                    when S_WAIT_CORES =>
                        next_done_seen := lane_done_seen or lane_done;
                        lane_done_seen <= next_done_seen;
                        if next_done_seen = "1111" then
                            if stage_idx = 0 then
                                buf_b(0) <= lane_even(0);
                                buf_b(1) <= lane_odd(0);
                                buf_b(2) <= lane_even(1);
                                buf_b(3) <= lane_odd(1);
                                buf_b(4) <= lane_even(2);
                                buf_b(5) <= lane_odd(2);
                                buf_b(6) <= lane_even(3);
                                buf_b(7) <= lane_odd(3);
                                stage_idx <= 1;
                                state <= S_STAGE_DISPATCH;
                            elsif stage_idx = 1 then
                                buf_a(0) <= lane_even(0);
                                buf_a(2) <= lane_odd(0);
                                buf_a(1) <= lane_even(1);
                                buf_a(3) <= lane_odd(1);
                                buf_a(4) <= lane_even(2);
                                buf_a(6) <= lane_odd(2);
                                buf_a(5) <= lane_even(3);
                                buf_a(7) <= lane_odd(3);
                                stage_idx <= 2;
                                state <= S_STAGE_DISPATCH;
                            else
                                buf_b(0) <= lane_even(0);
                                buf_b(4) <= lane_odd(0);
                                buf_b(1) <= lane_even(1);
                                buf_b(5) <= lane_odd(1);
                                buf_b(2) <= lane_even(2);
                                buf_b(6) <= lane_odd(2);
                                buf_b(3) <= lane_even(3);
                                buf_b(7) <= lane_odd(3);
                                dump_idx <= 0;
                                state <= S_DUMP_OUTPUT;
                            end if;
                        else
                            state <= S_WAIT_CORES;
                        end if;

                    when S_DUMP_OUTPUT =>
                        verify_ram_we <= '1';
                        verify_ram_addr <= std_logic_vector(to_unsigned(dump_idx, 6));
                        if dump_idx < 8 then
                            verify_vector_out <= buf_b(dump_idx)(15 downto 0);
                        else
                            verify_vector_out <= buf_b(dump_idx - 8)(31 downto 16);
                        end if;

                        if dump_idx = OUTPUT_COUNT - 1 then
                            cnt_stop <= '1';
                            state <= S_DONE;
                        else
                            dump_idx <= dump_idx + 1;
                            state <= S_DUMP_OUTPUT;
                        end if;

                    when S_DONE =>
                        null;
                end case;
            end if;
        end if;
    end process;
end architecture rtl;
