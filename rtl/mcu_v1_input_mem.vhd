library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mcu_v1_input_mem is
    port (
        clk         : in  std_logic;
        input_we    : in  std_logic;
        input_waddr : in  std_logic_vector(5 downto 0);
        input_wdata : in  std_logic_vector(15 downto 0);
        slot        : in  std_logic_vector(5 downto 0);
        read_data   : out std_logic_vector(31 downto 0);
        bulk_read_data : out std_logic_vector(511 downto 0)
    );
end entity mcu_v1_input_mem;

architecture rtl of mcu_v1_input_mem is
    type input_array_t is array (0 to 63) of std_logic_vector(15 downto 0);
    signal mem : input_array_t := (others => (others => '0'));
begin
    process(clk)
    begin
        if rising_edge(clk) then
            if input_we = '1' then
                mem(to_integer(unsigned(input_waddr))) <= input_wdata;
            end if;
        end if;
    end process;

    read_data <= std_logic_vector(resize(signed(mem(to_integer(unsigned(slot)))), 32));

    process(slot, mem)
        variable base : integer;
        variable idx  : integer;
        variable data : std_logic_vector(511 downto 0);
    begin
        base := to_integer(unsigned(slot));
        data := (others => '0');
        for i in 0 to 15 loop
            idx := base + i;
            if idx <= 63 then
                data(32 * i + 31 downto 32 * i) := std_logic_vector(resize(signed(mem(idx)), 32));
            end if;
        end loop;
        bulk_read_data <= data;
    end process;
end architecture rtl;
