library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;

entity mcu_v1_core_pipe5_tb is
end entity mcu_v1_core_pipe5_tb;

architecture sim of mcu_v1_core_pipe5_tb is
    signal clk : std_logic := '0';
    signal rst : std_logic := '1';

    signal input_we     : std_logic := '0';
    signal input_waddr  : std_logic_vector(7 downto 0) := (others => '0');
    signal input_wdata  : std_logic_vector(15 downto 0) := (others => '0');
    signal output_raddr : std_logic_vector(5 downto 0) := (others => '0');
    signal output_rdata : std_logic_vector(15 downto 0);
    signal pc_debug     : std_logic_vector(31 downto 0);
    signal instr_debug  : std_logic_vector(31 downto 0);
    signal halted_debug : std_logic;
    signal illegal_debug : std_logic;
    signal flag_z_debug : std_logic;
    signal flag_n_debug : std_logic;

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

    dut : entity work.mcu_v1_core_pipe5
        generic map (
            MEM_FILE  => "asm/fft8_v1_mcu32_basic.mem",
            ROM_DEPTH => 1024
        )
        port map (
            clk          => clk,
            rst          => rst,
            input_we     => input_we,
            input_waddr  => input_waddr,
            input_wdata  => input_wdata,
            output_raddr => output_raddr,
            output_rdata => output_rdata,
            pc_debug     => pc_debug,
            instr_debug  => instr_debug,
            halted_debug => halted_debug,
            illegal_debug => illegal_debug,
            flag_z_debug => flag_z_debug,
            flag_n_debug => flag_n_debug
        );

    stim : process
        variable cycles_to_halt : natural := 0;

        procedure wait_cycles(count : natural) is
        begin
            for i in 1 to count loop
                wait until rising_edge(clk);
            end loop;
        end procedure;

        procedure write_input(slot : natural; value : integer) is
        begin
            input_waddr <= std_logic_vector(to_unsigned(slot, 8));
            input_wdata <= slv16(value);
            input_we <= '1';
            wait until rising_edge(clk);
            wait for 1 ns;
            input_we <= '0';
        end procedure;

        procedure expect_output(slot : natural; value : integer) is
        begin
            output_raddr <= std_logic_vector(to_unsigned(slot, 6));
            wait for 1 ns;
            assert output_rdata = slv16(value)
                report "pipe5 FFT output slot " & integer'image(slot)
                    & " expected " & integer'image(value)
                    & " got " & integer'image(to_integer(signed(output_rdata)))
                severity failure;
        end procedure;
    begin
        wait_cycles(2);

        for slot in 128 to 143 loop
            write_input(slot, FFT_SAMPLE_INPUT(slot));
        end loop;

        rst <= '0';
        cycles_to_halt := 0;
        for i in 1 to 2000 loop
            wait until rising_edge(clk);
            cycles_to_halt := cycles_to_halt + 1;
            exit when halted_debug = '1';
        end loop;

        assert halted_debug = '1' report "pipe5 FFT did not reach DONE self-loop" severity failure;
        assert illegal_debug = '0' report "pipe5 FFT hit illegal instruction" severity failure;
        assert pc_debug = x"000001A8" report "pipe5 FFT PC should be at DONE" severity failure;
        assert instr_debug = x"E8FFFFFE" report "pipe5 FFT DONE instruction mismatch" severity failure;

        for slot in FFT_EXPECTED_OUTPUT'range loop
            expect_output(slot, FFT_EXPECTED_OUTPUT(slot));
        end loop;

        report "mcu_v1_core_pipe5_tb cycles_to_halt " & integer'image(cycles_to_halt) severity note;
        report "mcu_v1_core_pipe5_tb passed" severity note;
        finish;
    end process;
end architecture sim;
