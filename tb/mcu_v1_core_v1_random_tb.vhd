library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

entity mcu_v1_core_v1_random_tb is
end entity mcu_v1_core_v1_random_tb;

architecture sim of mcu_v1_core_v1_random_tb is
    constant CASE_COUNT : natural := 100;
    constant SLOT_COUNT : natural := 16;
    constant MAX_RUN_CYCLES : natural := 360;

    type int_vec16_t is array (0 to SLOT_COUNT - 1) of integer;

    signal clk : std_logic := '0';
    signal sim_done : std_logic := '0';

    signal rst          : std_logic := '1';
    signal input_we     : std_logic := '0';
    signal input_waddr  : std_logic_vector(5 downto 0) := (others => '0');
    signal input_wdata  : std_logic_vector(15 downto 0) := (others => '0');
    signal output_raddr : std_logic_vector(5 downto 0) := (others => '0');
    signal output_rdata : std_logic_vector(15 downto 0);
    signal pc           : std_logic_vector(31 downto 0);
    signal instr        : std_logic_vector(31 downto 0);
    signal halted       : std_logic;
    signal illegal      : std_logic;
    signal flag_z       : std_logic;
    signal flag_n       : std_logic;

    function slv16(value : integer) return std_logic_vector is
    begin
        return std_logic_vector(to_signed(value, 16));
    end function;
begin
    clk <= not clk after 5 ns when sim_done = '0' else '0';

    dut : entity work.mcu_v1_core
        generic map (
            MEM_FILE  => "asm/fft8_v1_mcu32_basic.mem",
            ROM_DEPTH => 1024
        )
        port map (
            clk           => clk,
            rst           => rst,
            input_we      => input_we,
            input_waddr   => input_waddr,
            input_wdata   => input_wdata,
            output_raddr  => output_raddr,
            output_rdata  => output_rdata,
            pc_debug      => pc,
            instr_debug   => instr,
            halted_debug  => halted,
            illegal_debug => illegal,
            flag_z_debug  => flag_z,
            flag_n_debug  => flag_n
        );

    stim : process
        file vectors_file : text open read_mode is "tb/fft8_v1_random_vectors.txt";
        variable row : line;
        variable inputs : int_vec16_t;
        variable expected : int_vec16_t;

        procedure wait_cycles(count : natural) is
        begin
            for i in 1 to count loop
                wait until rising_edge(clk);
            end loop;
        end procedure;

        procedure write_input(slot : natural; value : integer) is
        begin
            input_waddr <= std_logic_vector(to_unsigned(slot, 6));
            input_wdata <= slv16(value);
            input_we <= '1';
            wait until rising_edge(clk);
            wait for 1 ns;
            input_we <= '0';
        end procedure;

        procedure wait_until_halted(case_index : natural) is
        begin
            for cycle_i in 1 to MAX_RUN_CYCLES loop
                wait until rising_edge(clk);
                wait for 1 ns;
                if halted = '1' then
                    return;
                end if;
            end loop;
            assert false
                report "V1 random case " & integer'image(case_index)
                    & " did not halt within max cycles"
                severity failure;
        end procedure;

        procedure expect_output(case_index : natural; slot : natural; value : integer) is
        begin
            output_raddr <= std_logic_vector(to_unsigned(slot, 6));
            wait for 1 ns;
            assert output_rdata = slv16(value)
                report "V1 random case " & integer'image(case_index)
                    & " output slot " & integer'image(slot)
                    & " expected " & integer'image(value)
                    & " got " & integer'image(to_integer(signed(output_rdata)))
                severity failure;
        end procedure;
    begin
        wait_cycles(2);

        for case_i in 0 to CASE_COUNT - 1 loop
            assert not endfile(vectors_file)
                report "V1 random vector file ended early"
                severity failure;
            readline(vectors_file, row);
            for slot_i in 0 to SLOT_COUNT - 1 loop
                read(row, inputs(slot_i));
            end loop;
            for slot_i in 0 to SLOT_COUNT - 1 loop
                read(row, expected(slot_i));
            end loop;

            rst <= '1';
            input_we <= '0';
            wait_cycles(2);
            for slot_i in 0 to SLOT_COUNT - 1 loop
                write_input(slot_i, inputs(slot_i));
            end loop;

            rst <= '0';
            wait_until_halted(case_i);

            assert illegal = '0'
                report "V1 random case " & integer'image(case_i)
                    & " hit illegal instruction"
                severity failure;
            assert pc = x"00000474"
                report "V1 random case " & integer'image(case_i)
                    & " PC should be at DONE"
                severity failure;

            for slot_i in 0 to SLOT_COUNT - 1 loop
                expect_output(case_i, slot_i, expected(slot_i));
            end loop;
        end loop;

        assert endfile(vectors_file)
            report "V1 random vector file has extra cases"
            severity failure;

        report "mcu_v1_core_v1_random_tb passed 100 random cases" severity note;
        sim_done <= '1';
        wait;
    end process;
end architecture sim;
