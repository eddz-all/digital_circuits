library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.mcu_v1_pkg.all;

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
    signal region : std_logic_vector(1 downto 0) := (others => '0');
    signal slot   : std_logic_vector(5 downto 0) := (others => '0');

    signal input_read  : std_logic_vector(31 downto 0) := (others => '0');
    signal work_read   : std_logic_vector(31 downto 0) := (others => '0');
    signal output_read : std_logic_vector(31 downto 0) := (others => '0');

    signal work_we   : std_logic := '0';
    signal output_we : std_logic := '0';
begin
    region <= addr(9 downto 8);
    slot <= addr(7 downto 2);
    work_we <= mem_write when region = REGION_WORK else '0';
    output_we <= mem_write when region = REGION_OUTPUT else '0';

    u_input_mem : entity work.mcu_v1_input_mem
        port map (
            clk         => clk,
            input_we    => input_we,
            input_waddr => input_waddr,
            input_wdata => input_wdata,
            slot        => slot,
            read_data   => input_read
        );

    u_work_ram : entity work.mcu_v1_work_ram
        port map (
            clk        => clk,
            rst        => rst,
            we         => work_we,
            slot       => slot,
            write_data => write_data,
            read_data  => work_read
        );

    u_output_mem : entity work.mcu_v1_output_mem
        port map (
            clk          => clk,
            rst          => rst,
            we           => output_we,
            slot         => slot,
            write_data   => write_data,
            output_raddr => output_raddr,
            output_rdata => output_rdata,
            read_data    => output_read
        );

    process(all)
    begin
        read_data <= (others => '0');
        if mem_read = '1' then
            case region is
                when REGION_INPUT =>
                    read_data <= input_read;
                when REGION_WORK =>
                    read_data <= work_read;
                when REGION_OUTPUT =>
                    read_data <= output_read;
                when others =>
                    read_data <= (others => '0');
            end case;
        end if;
    end process;
end architecture rtl;
