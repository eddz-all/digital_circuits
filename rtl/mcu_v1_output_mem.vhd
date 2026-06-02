library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mcu_v1_output_mem is
    port (
        clk          : in  std_logic;
        rst          : in  std_logic;
        we           : in  std_logic;
        we2          : in  std_logic;
        slot         : in  std_logic_vector(5 downto 0);
        slot2        : in  std_logic_vector(5 downto 0);
        write_data   : in  std_logic_vector(31 downto 0);
        write_data2  : in  std_logic_vector(31 downto 0);
        output_raddr : in  std_logic_vector(5 downto 0);
        output_rdata : out std_logic_vector(15 downto 0);
        read_data    : out std_logic_vector(31 downto 0);
        bulk_read_data : out std_logic_vector(511 downto 0)
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
            else
                if we = '1' then
                    mem(to_integer(unsigned(slot))) <= write_data(15 downto 0);
                end if;
                if we2 = '1' then
                    mem(to_integer(unsigned(slot2))) <= write_data2(15 downto 0);
                end if;
            end if;
        end if;
    end process;

    output_rdata <= mem(to_integer(unsigned(output_raddr)));
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
