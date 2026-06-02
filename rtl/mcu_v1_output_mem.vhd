library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mcu_v1_output_mem is
    port (
        clk          : in  std_logic;
        rst          : in  std_logic;
        we           : in  std_logic;
        slot         : in  std_logic_vector(5 downto 0);
        write_data   : in  std_logic_vector(31 downto 0);
        output_raddr : in  std_logic_vector(5 downto 0);
        output_rdata : out std_logic_vector(15 downto 0);
        read_data    : out std_logic_vector(31 downto 0)
    );
end entity mcu_v1_output_mem;

architecture rtl of mcu_v1_output_mem is
    type output_array_t is array (0 to 63) of std_logic_vector(15 downto 0);
    signal mem : output_array_t := (others => (others => '0'));
begin
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                mem <= (others => (others => '0'));
            elsif we = '1' then
                mem(to_integer(unsigned(slot))) <= write_data(15 downto 0);
            end if;
        end if;
    end process;

    output_rdata <= mem(to_integer(unsigned(output_raddr)));
    read_data <= std_logic_vector(resize(signed(mem(to_integer(unsigned(slot)))), 32));
end architecture rtl;
