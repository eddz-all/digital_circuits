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
    signal dmem_waddr : word_t := (others => '0');
    signal dmem_wdata : word_t := (others => '0');
    signal dmem_raddr : word_t := (others => '0');
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
            dmem_waddr    => dmem_waddr,
            dmem_wdata    => dmem_wdata,
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
        procedure check_addr(
            constant addr : in natural;
            constant expected : in word_t;
            constant label_text : in string
        ) is
        begin
            dmem_raddr <= dmem_word_addr(DMEM_REGION_A_BASE_WORD + addr);
            wait for 1 ns;
            assert dmem_rdata = expected
                report "single-core minimum ARM program " & label_text & " mismatch"
                severity failure;
        end procedure;

        procedure wait_cycles(count : natural) is
        begin
            for i in 1 to count loop
                wait until rising_edge(clk);
            end loop;
        end procedure;
    begin
        wait_cycles(2);
        dmem_waddr <= dmem_word_addr(DMEM_REGION_A_BASE_WORD);
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

        check_addr(1, x"00000007", "address 0x44");
        check_addr(2, x"0000000A", "address 0x48");
        check_addr(3, x"00000007", "address 0x4C");
        check_addr(4, x"00000002", "address 0x50");
        check_addr(5, x"00000003", "address 0x54");
        check_addr(6, x"00000005", "address 0x58");
        check_addr(7, x"0000000F", "address 0x5C");

        report "mcu4_multicycle_core_min_arm_tb passed" severity note;
        finish;
    end process;
end architecture sim;
