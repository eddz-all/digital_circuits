library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;

entity mcu4_multicycle_core_min_arm_tb is
end entity mcu4_multicycle_core_min_arm_tb;

architecture sim of mcu4_multicycle_core_min_arm_tb is
    signal clk : std_logic := '0';
    signal rst : std_logic := '1';
    signal input_we : std_logic := '0';
    signal input_waddr : std_logic_vector(7 downto 0) := (others => '0');
    signal input_wdata : std_logic_vector(15 downto 0) := (others => '0');
    signal output_raddr : std_logic_vector(5 downto 0) := (others => '0');
    signal output_rdata : std_logic_vector(15 downto 0);
    signal pc_debug : std_logic_vector(31 downto 0);
    signal instr_debug : std_logic_vector(31 downto 0);
    signal halted_debug : std_logic;
    signal illegal_debug : std_logic;
    signal flag_z_debug : std_logic;
    signal flag_n_debug : std_logic;

    function slv16(value : integer) return std_logic_vector is
    begin
        return std_logic_vector(to_signed(value, 16));
    end function;
begin
    clk <= not clk after 5 ns;

    dut : entity work.mcu4_multicycle_core
        generic map (
            PROGRAM_ID   => 1,
            ACTIVE_CORES => 1
        )
        port map (
            clk           => clk,
            rst           => rst,
            input_we      => input_we,
            input_waddr   => input_waddr,
            input_wdata   => input_wdata,
            output_raddr  => output_raddr,
            output_rdata  => output_rdata,
            pc_debug      => pc_debug,
            instr_debug   => instr_debug,
            halted_debug  => halted_debug,
            illegal_debug => illegal_debug,
            flag_z_debug  => flag_z_debug,
            flag_n_debug  => flag_n_debug
        );

    stim : process
        procedure wait_cycles(count : natural) is
        begin
            for i in 1 to count loop
                wait until rising_edge(clk);
            end loop;
        end procedure;
    begin
        wait_cycles(2);
        rst <= '0';

        for i in 1 to 100 loop
            wait until rising_edge(clk);
            exit when halted_debug = '1';
        end loop;

        assert halted_debug = '1'
            report "single-core minimum ARM program did not halt"
            severity failure;
        assert illegal_debug = '0'
            report "single-core minimum ARM program hit illegal instruction"
            severity failure;

        output_raddr <= std_logic_vector(to_unsigned(1, 6));
        wait for 1 ns;
        assert output_rdata = slv16(3)
            report "single-core minimum ARM program dmem_bank0[1] mismatch"
            severity failure;

        output_raddr <= std_logic_vector(to_unsigned(2, 6));
        wait for 1 ns;
        assert output_rdata = slv16(7)
            report "single-core minimum ARM program dmem_bank0[2] mismatch"
            severity failure;

        output_raddr <= std_logic_vector(to_unsigned(3, 6));
        wait for 1 ns;
        assert output_rdata = slv16(10)
            report "single-core minimum ARM program dmem_bank0[3] mismatch"
            severity failure;

        report "mcu4_multicycle_core_min_arm_tb passed" severity note;
        finish;
    end process;
end architecture sim;
