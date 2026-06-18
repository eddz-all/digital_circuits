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
        bulk_store : in  std_logic;
        bulk_write_data : in std_logic_vector(511 downto 0);
        bulk_regmask : in std_logic_vector(15 downto 0);
        read_data  : out std_logic_vector(31 downto 0);

        input_we    : in  std_logic;
        input_waddr : in  std_logic_vector(7 downto 0);
        input_wdata : in  std_logic_vector(15 downto 0);

        output_raddr : in  std_logic_vector(5 downto 0);
        output_rdata : out std_logic_vector(15 downto 0)
    );
end entity mcu_v1_data_mem;

architecture rtl of mcu_v1_data_mem is
    constant TEACHER_INPUT_SLOTS  : natural := 144;
    constant WORK_BASE            : natural := 16#400#;
    constant WORK_SLOTS           : natural := 64;
    constant LEGACY_OUTPUT_BASE   : natural := 16#200#;
    constant TEACHER_OUTPUT_BASE  : natural := 16#800#;
    constant OUTPUT_SLOTS         : natural := 64;

    type input_array_t is array (0 to TEACHER_INPUT_SLOTS - 1) of std_logic_vector(15 downto 0);
    type word_array_t  is array (0 to 63) of std_logic_vector(31 downto 0);
    type output_array_t is array (0 to OUTPUT_SLOTS - 1) of std_logic_vector(15 downto 0);

    signal input_mem  : input_array_t := (others => (others => '0'));
    signal work_mem   : word_array_t := (others => (others => '0'));
    signal output_mem : output_array_t := (others => (others => '0'));
begin
    process(clk)
        variable addr_i : natural;
        variable slot_i : natural;
        variable target_addr : natural;
        variable data_index : natural range 0 to 16;
    begin
        if rising_edge(clk) then
            if input_we = '1' then
                slot_i := to_integer(unsigned(input_waddr));
                if slot_i < TEACHER_INPUT_SLOTS then
                    input_mem(slot_i) <= input_wdata;
                end if;
            end if;

            if rst = '1' then
                work_mem <= (others => (others => '0'));
                output_mem <= (others => (others => '0'));
            else
                if mem_write = '1' then
                    addr_i := to_integer(unsigned(addr(15 downto 0)));
                    if addr(1 downto 0) = "00" then
                        if bulk_store = '1' then
                            data_index := 0;
                            for reg_index in 0 to 15 loop
                                if bulk_regmask(reg_index) = '1' then
                                    target_addr := addr_i + data_index * 4;
                                    if target_addr >= TEACHER_OUTPUT_BASE
                                        and target_addr < TEACHER_OUTPUT_BASE + OUTPUT_SLOTS * 4 then
                                        output_mem((target_addr - TEACHER_OUTPUT_BASE) / 4) <=
                                            bulk_write_data(32 * data_index + 15 downto 32 * data_index);
                                    elsif target_addr >= LEGACY_OUTPUT_BASE
                                        and target_addr < LEGACY_OUTPUT_BASE + OUTPUT_SLOTS * 4 then
                                        output_mem((target_addr - LEGACY_OUTPUT_BASE) / 4) <=
                                            bulk_write_data(32 * data_index + 15 downto 32 * data_index);
                                    elsif target_addr >= WORK_BASE
                                        and target_addr < WORK_BASE + WORK_SLOTS * 4 then
                                        work_mem((target_addr - WORK_BASE) / 4) <=
                                            bulk_write_data(32 * data_index + 31 downto 32 * data_index);
                                    end if;
                                    data_index := data_index + 1;
                                end if;
                            end loop;
                        else
                            if addr_i >= TEACHER_OUTPUT_BASE
                                and addr_i < TEACHER_OUTPUT_BASE + OUTPUT_SLOTS * 4 then
                                output_mem((addr_i - TEACHER_OUTPUT_BASE) / 4) <= write_data(15 downto 0);
                            elsif addr_i >= LEGACY_OUTPUT_BASE
                                and addr_i < LEGACY_OUTPUT_BASE + OUTPUT_SLOTS * 4 then
                                output_mem((addr_i - LEGACY_OUTPUT_BASE) / 4) <= write_data(15 downto 0);
                            elsif addr_i >= WORK_BASE
                                and addr_i < WORK_BASE + WORK_SLOTS * 4 then
                                work_mem((addr_i - WORK_BASE) / 4) <= write_data;
                            end if;
                        end if;
                    end if;
                end if;
            end if;
        end if;
    end process;

    process(mem_read, addr, input_mem, work_mem, output_mem)
        variable addr_i : natural;
    begin
        read_data <= (others => '0');
        if mem_read = '1' then
            addr_i := to_integer(unsigned(addr(15 downto 0)));
            if addr(1 downto 0) = "00" then
                if addr_i < TEACHER_INPUT_SLOTS * 4 then
                    read_data <= std_logic_vector(resize(signed(input_mem(addr_i / 4)), 32));
                elsif addr_i >= WORK_BASE
                    and addr_i < WORK_BASE + WORK_SLOTS * 4 then
                    read_data <= work_mem((addr_i - WORK_BASE) / 4);
                elsif addr_i >= TEACHER_OUTPUT_BASE
                    and addr_i < TEACHER_OUTPUT_BASE + OUTPUT_SLOTS * 4 then
                    read_data <= std_logic_vector(resize(signed(output_mem((addr_i - TEACHER_OUTPUT_BASE) / 4)), 32));
                end if;
            end if;
        end if;
    end process;

    output_rdata <= output_mem(to_integer(unsigned(output_raddr)));
end architecture rtl;
