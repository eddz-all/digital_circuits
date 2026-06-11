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

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mcu_v1_work_ram is
    port (
        clk        : in  std_logic;
        rst        : in  std_logic;
        we         : in  std_logic;
        we2        : in  std_logic;
        slot       : in  std_logic_vector(5 downto 0);
        slot2      : in  std_logic_vector(5 downto 0);
        write_data : in  std_logic_vector(31 downto 0);
        write_data2 : in std_logic_vector(31 downto 0);
        bulk_store : in std_logic;
        bulk_write_data : in std_logic_vector(511 downto 0);
        bulk_regmask : in std_logic_vector(15 downto 0);
        read_data  : out std_logic_vector(31 downto 0);
        bulk_read_data : out std_logic_vector(511 downto 0)
    );
end entity mcu_v1_work_ram;

architecture rtl of mcu_v1_work_ram is
    type word_array_t is array (0 to 63) of std_logic_vector(31 downto 0);
    signal mem : word_array_t := (others => (others => '0'));
begin
    process(clk)
        variable base_slot : integer;
        variable data_index : natural range 0 to 16;
        variable idx : integer;
    begin
        if rising_edge(clk) then
            if rst = '1' then
                mem <= (others => (others => '0'));
            else
                if we = '1' then
                    mem(to_integer(unsigned(slot))) <= write_data;
                end if;
                if we2 = '1' then
                    mem(to_integer(unsigned(slot2))) <= write_data2;
                end if;
                if bulk_store = '1' then
                    base_slot := to_integer(unsigned(slot));
                    data_index := 0;
                    for reg_index in 0 to 15 loop
                        if bulk_regmask(reg_index) = '1' then
                            idx := base_slot + data_index;
                            if idx <= 63 then
                                mem(idx) <= bulk_write_data(32 * data_index + 31 downto 32 * data_index);
                            end if;
                            data_index := data_index + 1;
                        end if;
                    end loop;
                end if;
            end if;
        end if;
    end process;

    read_data <= mem(to_integer(unsigned(slot)));

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
                data(32 * i + 31 downto 32 * i) := mem(idx);
            end if;
        end loop;
        bulk_read_data <= data;
    end process;
end architecture rtl;

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
        bulk_store   : in  std_logic;
        bulk_write_data : in std_logic_vector(511 downto 0);
        bulk_regmask : in std_logic_vector(15 downto 0);
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
        variable base_slot : integer;
        variable data_index : natural range 0 to 16;
        variable idx : integer;
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
                if bulk_store = '1' then
                    base_slot := to_integer(unsigned(slot));
                    data_index := 0;
                    for reg_index in 0 to 15 loop
                        if bulk_regmask(reg_index) = '1' then
                            idx := base_slot + data_index;
                            if idx <= 63 then
                                mem(idx) <= bulk_write_data(32 * data_index + 15 downto 32 * data_index);
                            end if;
                            data_index := data_index + 1;
                        end if;
                    end loop;
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
