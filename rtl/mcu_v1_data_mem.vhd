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
    end process;

    process(all)
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
