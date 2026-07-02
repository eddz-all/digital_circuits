library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;

use work.mcu4_multi_pkg.all;

entity mcu4_multicycle_core_min_arm_tb is
end entity mcu4_multicycle_core_min_arm_tb;

architecture sim of mcu4_multicycle_core_min_arm_tb is
    signal clk : std_logic := '0';
    signal rst : std_logic := '1';
    signal dmem_we : std_logic := '0';
    signal dmem_wbank : std_logic := '0';
    signal dmem_waddr : std_logic_vector(2 downto 0) := (others => '0');
    signal dmem_wdata : word_t := (others => '0');
    signal dmem_rbank : std_logic := '0';
    signal dmem_raddr : std_logic_vector(2 downto 0) := (others => '0');
    signal dmem_rdata : word_t;
    signal pc_debug : std_logic_vector(31 downto 0);
    signal instr_debug : std_logic_vector(31 downto 0);
    signal halted_debug : std_logic;
    signal illegal_debug : std_logic;
    signal flag_z_debug : std_logic;
    signal flag_n_debug : std_logic;
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
            dmem_we       => dmem_we,
            dmem_wbank    => dmem_wbank,
            dmem_waddr    => dmem_waddr,
            dmem_wdata    => dmem_wdata,
            dmem_rbank    => dmem_rbank,
            dmem_raddr    => dmem_raddr,
            dmem_rdata    => dmem_rdata,
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
        dmem_wbank <= '0';
        dmem_waddr <= std_logic_vector(to_unsigned(0, 3));
        dmem_wdata <= x"00000005";
        dmem_we <= '1';
        wait until rising_edge(clk);
        dmem_we <= '0';
        wait until rising_edge(clk);
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

        dmem_rbank <= '0';
        dmem_raddr <= std_logic_vector(to_unsigned(1, 3));
        wait for 1 ns;
        assert dmem_rdata = x"00000008"
            report "single-core minimum ARM program dmem_bank0[1] mismatch"
            severity failure;

        dmem_raddr <= std_logic_vector(to_unsigned(2, 3));
        wait for 1 ns;
        assert dmem_rdata = x"00000007"
            report "single-core minimum ARM program dmem_bank0[2] mismatch"
            severity failure;

        dmem_raddr <= std_logic_vector(to_unsigned(3, 3));
        wait for 1 ns;
        assert dmem_rdata = x"0000000F"
            report "single-core minimum ARM program dmem_bank0[3] mismatch"
            severity failure;

        report "mcu4_multicycle_core_min_arm_tb passed" severity note;
        finish;
    end process;
end architecture sim;
