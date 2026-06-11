library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity clk_wiz_0 is
    port (
        clk_out1 : out std_logic;
        reset    : in  std_logic;
        locked   : out std_logic;
        clk_in1  : in  std_logic
    );
end entity clk_wiz_0;

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
        addra : in  std_logic_vector(5 downto 0);
        dina  : in  std_logic_vector(15 downto 0);
        douta : out std_logic_vector(15 downto 0)
    );
end entity test_ROM;

architecture sim of test_ROM is
    type rom_t is array (0 to 63) of std_logic_vector(15 downto 0);
    type sample_array_t is array (0 to 15) of integer;
    constant EXPECTED_INPUT : sample_array_t := (
        0, 0, 32760, 0,
        0, 0, 0, 0,
        0, 0, 0, 0,
        0, 0, 0, 0
    );
    constant ROM : rom_t := (
        0 => std_logic_vector(to_signed(0, 16)),
        1 => std_logic_vector(to_signed(0, 16)),
        2 => std_logic_vector(to_signed(32760, 16)),
        3 => std_logic_vector(to_signed(0, 16)),
        others => (others => '0')
    );
begin
    process(clka)
        variable read_count : natural := 0;
        variable addr : integer;
    begin
        if rising_edge(clka) then
            if ena = '1' then
                addr := to_integer(unsigned(addra));
                douta <= ROM(addr);

                if read_count < 16 then
                    assert addr = read_count
                        report "test_ROM read address expected "
                            & integer'image(read_count)
                            & ", got " & integer'image(addr)
                        severity failure;

                    assert ROM(addr) = std_logic_vector(to_signed(EXPECTED_INPUT(read_count), 16))
                        report "test_ROM data mismatch at address "
                            & integer'image(addr)
                        severity failure;

                    read_count := read_count + 1;
                    if read_count = 16 then
                        report "test_ROM input sequence checks passed" severity note;
                    end if;
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

architecture sim of verify_RAM is
    type ram_t is array (0 to 63) of std_logic_vector(15 downto 0);
    signal ram : ram_t := (others => (others => '0'));
begin
    process(clka)
        variable addr : integer;
    begin
        if rising_edge(clka) then
            if ena = '1' then
                addr := to_integer(unsigned(addra));
                if wea(0) = '1' then
                    ram(addr) <= dina;
                end if;
                douta <= ram(addr);
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
        probe5 : in std_logic_vector(0 downto 0);
        probe6 : in std_logic_vector(0 downto 0);
        probe7 : in std_logic_vector(0 downto 0)
    );
end entity ila_0;

architecture sim of ila_0 is
    type sample_array_t is array (0 to 15) of integer;
    constant EXPECTED : sample_array_t := (
        4095, 0, -4095, 0,
        0, -4095, 0, 4095,
        2895, -2896, -2896, 2896,
        -2896, -2896, 2896, 2895
    );

    function slv16(value : integer) return std_logic_vector is
    begin
        return std_logic_vector(to_signed(value, 16));
    end function;
begin
    process(clk)
        variable addr : integer;
        variable capture_count : natural := 0;
        variable done_seen : boolean := false;
        variable cycles_after_done : natural := 0;
        variable final_checked : boolean := false;
    begin
        if rising_edge(clk) then
            if probe6(0) = '1' then
                done_seen := true;
            end if;

            if probe4(0) = '1' then
                addr := to_integer(unsigned(probe2));
                assert addr >= 0 and addr <= 15
                    report "readback address out of range"
                    severity failure;

                assert probe3 = slv16(EXPECTED(addr))
                    report "verify_RAM[" & integer'image(addr)
                        & "] expected " & integer'image(EXPECTED(addr))
                    severity failure;

                capture_count := capture_count + 1;
            end if;

            if done_seen and not final_checked then
                cycles_after_done := cycles_after_done + 1;
                if cycles_after_done = 128 then
                    assert capture_count = 16
                        report "expected 16 verify_RAM readback captures, got "
                            & integer'image(capture_count)
                        severity failure;
                    final_checked := true;
                    report "verify_RAM readback checks passed" severity note;
                end if;
            end if;
        end if;
    end process;
end architecture sim;
