library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mcu_v1_work_ram is
    port (
        clk        : in  std_logic;
        rst        : in  std_logic;
        we         : in  std_logic;
        slot       : in  std_logic_vector(5 downto 0);
        write_data : in  std_logic_vector(31 downto 0);
        read_data  : out std_logic_vector(31 downto 0)
    );
end entity mcu_v1_work_ram;

architecture rtl of mcu_v1_work_ram is
    type word_array_t is array (0 to 63) of std_logic_vector(31 downto 0);
    signal mem : word_array_t := (others => (others => '0'));
begin
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                mem <= (others => (others => '0'));
            elsif we = '1' then
                mem(to_integer(unsigned(slot))) <= write_data;
            end if;
        end if;
    end process;

    read_data <= mem(to_integer(unsigned(slot)));
end architecture rtl;
