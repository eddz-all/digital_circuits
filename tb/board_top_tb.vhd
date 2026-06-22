library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;

entity clk_wiz_0 is
    port (
        clk_out1 : out std_logic;
        reset    : in  std_logic;
        locked   : out std_logic;
        clk_in1  : in  std_logic
    );
end entity clk_wiz_0;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

architecture sim of clk_wiz_0 is
begin
    clk_out1 <= clk_in1;
    locked <= not reset;
end architecture sim;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity test_ROM is
    port (
        clka  : in  std_logic;
        ena   : in  std_logic;
        wea   : in  std_logic_vector(0 downto 0);
        addra : in  std_logic_vector(7 downto 0);
        dina  : in  std_logic_vector(15 downto 0);
        douta : out std_logic_vector(15 downto 0)
    );
end entity test_ROM;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

architecture sim of test_ROM is
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

    function slv16(value : integer) return std_logic_vector is
    begin
        return std_logic_vector(to_signed(value, 16));
    end function;

    function safe_index(addr : std_logic_vector(7 downto 0)) return natural is
        variable idx : natural range 0 to 255 := 0;
    begin
        for bit_pos in 0 to 7 loop
            if addr(bit_pos) = '1' then
                idx := idx + (2 ** bit_pos);
            end if;
        end loop;
        return idx;
    end function;
begin
    process(clka)
        variable addr : natural;
    begin
        if rising_edge(clka) then
            if ena = '1' then
                addr := safe_index(addra);
                if addr < FFT_SAMPLE_INPUT'length then
                    douta <= slv16(FFT_SAMPLE_INPUT(addr));
                else
                    douta <= (others => '0');
                end if;
            end if;
        end if;
    end process;
end architecture sim;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity verify_RAM is
    port (
        clka  : in  std_logic;
        ena   : in  std_logic;
        wea   : in  std_logic_vector(0 downto 0);
        addra : in  std_logic_vector(5 downto 0);
        dina  : in  std_logic_vector(15 downto 0);
        douta : out std_logic_vector(15 downto 0)
    );
end entity verify_RAM;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

architecture sim of verify_RAM is
    type ram_t is array (0 to 63) of std_logic_vector(15 downto 0);
    type int_array_t is array (natural range <>) of integer;
    signal ram : ram_t := (others => (others => '0'));
    constant FFT_EXPECTED_OUTPUT : int_array_t(0 to 15) := (
        -3456, -6134, 6784, -350, -8064, 5878, -6528, -1442,
        -5888, 12668, 11264, 8076, 2816, 3204, 5632, -10124
    );

    function slv16(value : integer) return std_logic_vector is
    begin
        return std_logic_vector(to_signed(value, 16));
    end function;

    function safe_index(addr : std_logic_vector(5 downto 0)) return natural is
        variable idx : natural range 0 to 63 := 0;
    begin
        for bit_pos in 0 to 5 loop
            if addr(bit_pos) = '1' then
                idx := idx + (2 ** bit_pos);
            end if;
        end loop;
        return idx;
    end function;
begin
    process(clka)
        variable addr : natural;
    begin
        if rising_edge(clka) then
            if ena = '1' then
                addr := safe_index(addra);
                douta <= ram(addr);
                if wea(0) = '1' then
                    ram(addr) <= dina;
                    if addr < FFT_EXPECTED_OUTPUT'length then
                        assert dina = slv16(FFT_EXPECTED_OUTPUT(addr))
                            report "board_top verify_RAM addr " & integer'image(addr)
                                & " expected " & integer'image(FFT_EXPECTED_OUTPUT(addr))
                                & " got " & integer'image(to_integer(signed(dina)))
                            severity failure;
                    end if;
                end if;
            end if;
        end if;
    end process;
end architecture sim;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ila_0 is
    port (
        clk    : in std_logic;
        probe0 : in std_logic_vector(15 downto 0);
        probe1 : in std_logic_vector(19 downto 0);
        probe2 : in std_logic_vector(5 downto 0);
        probe3 : in std_logic_vector(15 downto 0);
        probe4 : in std_logic_vector(0 downto 0);
        probe5 : in std_logic_vector(0 downto 0)
    );
end entity ila_0;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

architecture sim of ila_0 is
begin
end architecture sim;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;

entity board_top_tb is
end entity board_top_tb;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;

architecture sim of board_top_tb is
    signal clk_in1 : std_logic := '0';
    signal rst_btn : std_logic := '1';
begin
    clk_in1 <= not clk_in1 after 10 ns;

    dut : entity work.board_top
        port map (
            clk_in1 => clk_in1,
            rst_btn => rst_btn
        );

    stim : process
    begin
        wait for 100 ns;
        rst_btn <= '0';
        wait for 3 us;
        report "board_top_tb passed" severity note;
        finish;
    end process;
end architecture sim;
