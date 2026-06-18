library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;

entity mcu_v1_core_tb is
end entity mcu_v1_core_tb;

architecture sim of mcu_v1_core_tb is
    signal clk : std_logic := '0';

    signal basic_rst          : std_logic := '1';
    signal basic_input_we     : std_logic := '0';
    signal basic_input_waddr  : std_logic_vector(7 downto 0) := (others => '0');
    signal basic_input_wdata  : std_logic_vector(15 downto 0) := (others => '0');
    signal basic_output_raddr : std_logic_vector(5 downto 0) := (others => '0');
    signal basic_output_rdata : std_logic_vector(15 downto 0);
    signal basic_pc           : std_logic_vector(31 downto 0);
    signal basic_instr        : std_logic_vector(31 downto 0);
    signal basic_halted       : std_logic;
    signal basic_illegal      : std_logic;
    signal basic_z            : std_logic;
    signal basic_n            : std_logic;

    signal fft_rst          : std_logic := '1';
    signal fft_input_we     : std_logic := '0';
    signal fft_input_waddr  : std_logic_vector(7 downto 0) := (others => '0');
    signal fft_input_wdata  : std_logic_vector(15 downto 0) := (others => '0');
    signal fft_output_raddr : std_logic_vector(5 downto 0) := (others => '0');
    signal fft_output_rdata : std_logic_vector(15 downto 0);
    signal fft_pc           : std_logic_vector(31 downto 0);
    signal fft_instr        : std_logic_vector(31 downto 0);
    signal fft_halted       : std_logic;
    signal fft_illegal      : std_logic;
    signal fft_z            : std_logic;
    signal fft_n            : std_logic;

    function slv16(value : integer) return std_logic_vector is
    begin
        return std_logic_vector(to_signed(value, 16));
    end function;

    type int_array_t is array (natural range <>) of integer;

    constant FFT_SAMPLE_INPUT : int_array_t(0 to 143) := (
        128, 128, 128, 128, 128, 128, 128, 128,
        128, 91, 0, -91, -128, -91, 0, 91,
        128, 0, -128, 0, 128, 0, -128, 0,
        128, -91, 0, 91, -128, 91, 0, -91,
        128, -128, 128, -128, 128, -128, 128, -128,
        128, -91, 0, 91, -128, 91, 0, -91,
        128, 0, -128, 0, 128, 0, -128, 0,
        128, 91, 0, -91, -128, -91, 0, 91,
        0, 0, 0, 0, 0, 0, 0, 0,
        0, -91, -128, -91, 0, 91, 128, 91,
        0, -128, 0, 128, 0, -128, 0, 128,
        0, -91, 128, -91, 0, 91, -128, 91,
        0, 0, 0, 0, 0, 0, 0, 0,
        0, 91, -128, 91, 0, -91, 128, -91,
        0, 128, 0, -128, 0, 128, 0, -128,
        0, 91, 128, 91, 0, -91, -128, -91,
        -13, -29, -29, 0, -9, 27, 6, 20,
        27, -9, -18, -23, 0, 18, -21, -20
    );

    constant FFT_EXPECTED_OUTPUT : int_array_t(0 to 15) := (
        -3456, -6134, 6784, -350, -8064, 5878, -6528, -1442,
        -5888, 12668, 11264, 8076, 2816, 3204, 5632, -10124
    );
begin
    clk <= not clk after 5 ns;

    basic_core : entity work.mcu_v1_core
        generic map (
            MEM_FILE  => "asm/test_mcu_v1_basic.mem",
            ROM_DEPTH => 256
        )
        port map (
            clk          => clk,
            rst          => basic_rst,
            input_we     => basic_input_we,
            input_waddr  => basic_input_waddr,
            input_wdata  => basic_input_wdata,
            output_raddr => basic_output_raddr,
            output_rdata => basic_output_rdata,
            pc_debug     => basic_pc,
            instr_debug  => basic_instr,
            halted_debug => basic_halted,
            illegal_debug => basic_illegal,
            flag_z_debug => basic_z,
            flag_n_debug => basic_n
        );

    fft_core : entity work.mcu_v1_core
        generic map (
            MEM_FILE  => "asm/fft8_v1_mcu32_basic.mem",
            ROM_DEPTH => 1024
        )
        port map (
            clk          => clk,
            rst          => fft_rst,
            input_we     => fft_input_we,
            input_waddr  => fft_input_waddr,
            input_wdata  => fft_input_wdata,
            output_raddr => fft_output_raddr,
            output_rdata => fft_output_rdata,
            pc_debug     => fft_pc,
            instr_debug  => fft_instr,
            halted_debug => fft_halted,
            illegal_debug => fft_illegal,
            flag_z_debug => fft_z,
            flag_n_debug => fft_n
        );

    stim : process
        procedure wait_cycles(count : natural) is
        begin
            for i in 1 to count loop
                wait until rising_edge(clk);
            end loop;
        end procedure;

        procedure write_basic_input(slot : natural; value : integer) is
        begin
            basic_input_waddr <= std_logic_vector(to_unsigned(slot, 8));
            basic_input_wdata <= slv16(value);
            basic_input_we <= '1';
            wait until rising_edge(clk);
            wait for 1 ns;
            basic_input_we <= '0';
        end procedure;

        procedure write_fft_input(slot : natural; value : integer) is
        begin
            fft_input_waddr <= std_logic_vector(to_unsigned(slot, 8));
            fft_input_wdata <= slv16(value);
            fft_input_we <= '1';
            wait until rising_edge(clk);
            wait for 1 ns;
            fft_input_we <= '0';
        end procedure;

        procedure expect_basic_output(slot : natural; value : integer) is
        begin
            basic_output_raddr <= std_logic_vector(to_unsigned(slot, 6));
            wait for 1 ns;
            assert basic_output_rdata = slv16(value)
                report "basic output slot " & integer'image(slot)
                    & " expected " & integer'image(value)
                severity failure;
        end procedure;

        procedure expect_fft_output(slot : natural; value : integer) is
        begin
            fft_output_raddr <= std_logic_vector(to_unsigned(slot, 6));
            wait for 1 ns;
            assert fft_output_rdata = slv16(value)
                report "fft output slot " & integer'image(slot)
                    & " expected " & integer'image(value)
                severity failure;
        end procedure;
    begin
        wait_cycles(2);

        write_basic_input(0, 1000);
        write_basic_input(1, -500);
        basic_rst <= '0';
        wait_cycles(40);

        assert basic_illegal = '0' report "basic program hit illegal instruction" severity failure;
        assert basic_halted = '1' report "basic program did not reach DONE self-loop" severity failure;
        assert basic_pc = x"00000064" report "basic PC should be at DONE" severity failure;
        expect_basic_output(0, 500);
        expect_basic_output(1, 1500);
        expect_basic_output(2, 707);
        expect_basic_output(3, 123);

        for slot in 128 to 143 loop
            write_fft_input(slot, FFT_SAMPLE_INPUT(slot));
        end loop;
        fft_rst <= '0';
        wait_cycles(600);

        assert fft_illegal = '0' report "FFT program hit illegal instruction" severity failure;
        assert fft_halted = '1' report "FFT program did not reach DONE self-loop" severity failure;

        for slot in FFT_EXPECTED_OUTPUT'range loop
            expect_fft_output(slot, FFT_EXPECTED_OUTPUT(slot));
        end loop;

        report "mcu_v1_core_tb passed" severity note;
        finish;
    end process;
end architecture sim;
