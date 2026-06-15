library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library std;
use std.env.all;

entity test_rom_only_tb is
end entity test_rom_only_tb;

architecture sim of test_rom_only_tb is
    signal clk   : std_logic := '0';
    signal ena   : std_logic := '0';
    signal wea   : std_logic_vector(0 downto 0) := "0";
    signal addra : std_logic_vector(7 downto 0) := (others => '0');
    signal dina  : std_logic_vector(15 downto 0) := (others => '0');
    signal douta : std_logic_vector(15 downto 0);

    type sample_array_t is array (0 to 15) of std_logic_vector(15 downto 0);
    constant EXPECTED : sample_array_t := (
        x"fff3", x"ffe3", x"ffe3", x"0000",
        x"fff7", x"001b", x"0006", x"0014",
        x"001b", x"fff7", x"ffee", x"ffe9",
        x"0000", x"0012", x"ffeb", x"ffec"
    );

    function hex_char(value : natural) return character is
    begin
        case value is
            when 0 => return '0';
            when 1 => return '1';
            when 2 => return '2';
            when 3 => return '3';
            when 4 => return '4';
            when 5 => return '5';
            when 6 => return '6';
            when 7 => return '7';
            when 8 => return '8';
            when 9 => return '9';
            when 10 => return 'a';
            when 11 => return 'b';
            when 12 => return 'c';
            when 13 => return 'd';
            when 14 => return 'e';
            when others => return 'f';
        end case;
    end function;

    function to_hex16(value : std_logic_vector(15 downto 0)) return string is
        variable result : string(1 to 4);
        variable nibble : natural;
    begin
        for i in 0 to 3 loop
            nibble := to_integer(unsigned(value(15 - i * 4 downto 12 - i * 4)));
            result(i + 1) := hex_char(nibble);
        end loop;
        return result;
    end function;
begin
    clk <= not clk after 10 ns;

    dut : entity work.test_ROM
        port map (
            clka  => clk,
            ena   => ena,
            wea   => wea,
            addra => addra,
            dina  => dina,
            douta => douta
        );

    stim : process
    begin
        wait until rising_edge(clk);
        ena <= '1';

        for i in 0 to 15 loop
            addra <= std_logic_vector(to_unsigned(128 + i, 8));
            wait until rising_edge(clk);
            wait until rising_edge(clk);

            report "test_ROM[" & integer'image(128 + i)
                & "] got hex 0x" & to_hex16(douta)
                & ", signed " & integer'image(to_integer(signed(douta)))
                & "; expected hex 0x" & to_hex16(EXPECTED(i))
                & ", signed " & integer'image(to_integer(signed(EXPECTED(i))))
                severity note;
        end loop;

        report "test_ROM standalone print completed" severity note;
        stop;
    end process;
end architecture sim;
