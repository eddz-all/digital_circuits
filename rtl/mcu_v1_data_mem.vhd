library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mcu_v1_data_mem is
    port (
        clk        : in  std_logic;
        rst        : in  std_logic;

        addr       : in  std_logic_vector(31 downto 0);
        write_data : in  std_logic_vector(31 downto 0);
        mem_read   : in  std_logic;
        mem_write  : in  std_logic;
        read_data  : out std_logic_vector(31 downto 0);

        input_we    : in  std_logic;
        input_waddr : in  std_logic_vector(5 downto 0);
        input_wdata : in  std_logic_vector(15 downto 0);

        output_raddr : in  std_logic_vector(5 downto 0);
        output_rdata : out std_logic_vector(15 downto 0)
    );
end entity mcu_v1_data_mem;

architecture rtl of mcu_v1_data_mem is
    type input_array_t is array (0 to 63) of std_logic_vector(15 downto 0);
    type word_array_t  is array (0 to 63) of std_logic_vector(31 downto 0);

    signal input_mem  : input_array_t := (others => (others => '0'));
    signal work_mem   : word_array_t := (others => (others => '0'));
    signal output_mem : input_array_t := (others => (others => '0'));

    signal region : std_logic_vector(1 downto 0) := (others => '0');
    signal slot   : integer range 0 to 63 := 0;
begin
    region <= addr(9 downto 8);
    slot <= to_integer(unsigned(addr(7 downto 2)));

    process(clk)
    begin
        if rising_edge(clk) then
            if input_we = '1' then
                input_mem(to_integer(unsigned(input_waddr))) <= input_wdata;
            end if;

            if rst = '1' then
                work_mem <= (others => (others => '0'));
                output_mem <= (others => (others => '0'));
            else
                if mem_write = '1' then
                    if region = "01" then
                        work_mem(slot) <= write_data;
                    elsif region = "10" then
                        output_mem(slot) <= write_data(15 downto 0);
                    end if;
                end if;
            end if;
        end if;
    end process;

    process(all)
    begin
        read_data <= (others => '0');
        if mem_read = '1' then
            if region = "00" then
                read_data <= std_logic_vector(resize(signed(input_mem(slot)), 32));
            elsif region = "01" then
                read_data <= work_mem(slot);
            elsif region = "10" then
                read_data <= std_logic_vector(resize(signed(output_mem(slot)), 32));
            end if;
        end if;
    end process;

    output_rdata <= output_mem(to_integer(unsigned(output_raddr)));
end architecture rtl;
