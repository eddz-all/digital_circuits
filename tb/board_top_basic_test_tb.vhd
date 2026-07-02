library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ila_basic is
    port (
        clk    : in std_logic;
        probe0 : in std_logic_vector(0 downto 0)
    );
end entity ila_basic;

architecture sim of ila_basic is
begin
end architecture sim;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;

entity board_top_basic_test_tb is
end entity board_top_basic_test_tb;

architecture sim of board_top_basic_test_tb is
    signal clk_in1 : std_logic := '0';
    signal rst_btn : std_logic := '1';
    signal test    : std_logic;
begin
    clk_in1 <= not clk_in1 after 10 ns;

    dut : entity work.board_top_basic_test
        port map (
            clk_in1 => clk_in1,
            rst_btn => rst_btn,
            test    => test
        );

    monitor : process(clk_in1)
    begin
        if rising_edge(clk_in1) then
            if rst_btn = '0' then
                assert test = '1'
                    report "board_top_basic_test dropped test signal"
                    severity failure;
            end if;
        end if;
    end process;

    stim : process
    begin
        wait for 100 ns;
        rst_btn <= '0';
        wait for 3 us;
        assert test = '1'
            report "board_top_basic_test final test signal mismatch"
            severity failure;
        report "board_top_basic_test_tb passed" severity note;
        finish;
    end process;
end architecture sim;
