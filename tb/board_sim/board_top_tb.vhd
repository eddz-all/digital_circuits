library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library std;
use std.env.all;

entity board_top_tb is
end entity board_top_tb;

architecture sim of board_top_tb is
    signal clk_in1 : std_logic := '0';
    signal rst_btn : std_logic := '1';

    procedure wait_cycles(signal clk : in std_logic; count : natural) is
    begin
        for i in 1 to count loop
            wait until rising_edge(clk);
        end loop;
    end procedure;
begin
    clk_in1 <= not clk_in1 after 10 ns;

    dut : entity work.board_top
        port map (
            clk_in1 => clk_in1,
            rst_btn => rst_btn
        );

    stim : process
    begin
        wait_cycles(clk_in1, 8);
        rst_btn <= '0';

        wait_cycles(clk_in1, 900);
        report "board_top_tb completed" severity note;
        stop;
    end process;
end architecture sim;
