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
        write_data2 : in std_logic_vector(31 downto 0);
        mem_read   : in  std_logic;
        mem_write  : in  std_logic;
        bulk_store : in std_logic;
        store_double : in std_logic;
        bulk_write_data : in std_logic_vector(511 downto 0);
        bulk_regmask : in std_logic_vector(15 downto 0);
        read_data  : out std_logic_vector(31 downto 0);
        bulk_read_data : out std_logic_vector(511 downto 0);

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
    signal slot2  : std_logic_vector(5 downto 0) := (others => '0');

    signal input_read  : std_logic_vector(31 downto 0) := (others => '0');
    signal work_read   : std_logic_vector(31 downto 0) := (others => '0');
    signal output_read : std_logic_vector(31 downto 0) := (others => '0');
    signal input_bulk  : std_logic_vector(511 downto 0) := (others => '0');
    signal work_bulk   : std_logic_vector(511 downto 0) := (others => '0');
    signal output_bulk : std_logic_vector(511 downto 0) := (others => '0');

    signal work_we   : std_logic := '0';
    signal work_we2  : std_logic := '0';
    signal work_bulk_store : std_logic := '0';
    signal output_we : std_logic := '0';
    signal output_we2 : std_logic := '0';
    signal output_bulk_store : std_logic := '0';
begin
    region <= addr(9 downto 8);
    slot <= addr(7 downto 2);
    slot2 <= std_logic_vector(unsigned(addr(7 downto 2)) + 1);
    work_we <= mem_write and not bulk_store when region = REGION_WORK else '0';
    work_we2 <= mem_write and store_double and not bulk_store when region = REGION_WORK else '0';
    work_bulk_store <= mem_write and bulk_store when region = REGION_WORK else '0';
    output_we <= mem_write and not bulk_store when region = REGION_OUTPUT else '0';
    output_we2 <= mem_write and store_double and not bulk_store when region = REGION_OUTPUT else '0';
    output_bulk_store <= mem_write and bulk_store when region = REGION_OUTPUT else '0';

    u_input_mem : entity work.mcu_v1_input_mem
        port map (
            clk         => clk,
            input_we    => input_we,
            input_waddr => input_waddr,
            input_wdata => input_wdata,
            slot        => slot,
            read_data   => input_read,
            bulk_read_data => input_bulk
        );

    u_work_ram : entity work.mcu_v1_work_ram
        port map (
            clk        => clk,
            rst        => rst,
            we         => work_we,
            we2        => work_we2,
            slot       => slot,
            slot2      => slot2,
            write_data => write_data,
            write_data2 => write_data2,
            bulk_store => work_bulk_store,
            bulk_write_data => bulk_write_data,
            bulk_regmask => bulk_regmask,
            read_data  => work_read,
            bulk_read_data => work_bulk
        );

    u_output_mem : entity work.mcu_v1_output_mem
        port map (
            clk          => clk,
            rst          => rst,
            we           => output_we,
            we2          => output_we2,
            slot         => slot,
            slot2        => slot2,
            write_data   => write_data,
            write_data2  => write_data2,
            bulk_store   => output_bulk_store,
            bulk_write_data => bulk_write_data,
            bulk_regmask => bulk_regmask,
            output_raddr => output_raddr,
            output_rdata => output_rdata,
            read_data    => output_read,
            bulk_read_data => output_bulk
        );

    process(mem_read, region, input_read, work_read, output_read)
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

    process(region, input_bulk, work_bulk, output_bulk)
    begin
        case region is
            when REGION_INPUT =>
                bulk_read_data <= input_bulk;
            when REGION_WORK =>
                bulk_read_data <= work_bulk;
            when REGION_OUTPUT =>
                bulk_read_data <= output_bulk;
            when others =>
                bulk_read_data <= (others => '0');
        end case;
    end process;
end architecture rtl;
