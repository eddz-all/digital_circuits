library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.mcu_8core_dsp_pkg.all;

entity mcu_v1_core is
    generic (
        MEM_FILE  : string := "asm/fft8_v1_mcu32_basic.mem";
        ROM_DEPTH : positive := 64
    );
    port (
        clk : in std_logic;
        rst : in std_logic;

        input_we    : in  std_logic;
        input_waddr : in  std_logic_vector(7 downto 0);
        input_wdata : in  std_logic_vector(15 downto 0);

        output_raddr : in  std_logic_vector(5 downto 0);
        output_rdata : out std_logic_vector(15 downto 0);

        pc_debug      : out std_logic_vector(31 downto 0);
        instr_debug   : out std_logic_vector(31 downto 0);
        halted_debug  : out std_logic;
        illegal_debug : out std_logic;
        flag_z_debug  : out std_logic;
        flag_n_debug  : out std_logic
    );
end entity mcu_v1_core;

architecture rtl of mcu_v1_core is
    signal core_real : half_array_t(0 to CORE_COUNT - 1) := (others => (others => '0'));
    signal core_imag : half_array_t(0 to CORE_COUNT - 1) := (others => (others => '0'));
    signal core_pc : word_array_t(0 to CORE_COUNT - 1) := (others => (others => '0'));
    signal core_instr : word_array_t(0 to CORE_COUNT - 1) := (others => (others => '0'));
    signal core_halted : std_logic_vector(0 to CORE_COUNT - 1) := (others => '0');
    signal core_illegal : std_logic_vector(0 to CORE_COUNT - 1) := (others => '0');

    signal all_halted : std_logic;
    signal any_illegal : std_logic;
begin
    gen_workers : for i in 0 to CORE_COUNT - 1 generate
        u_worker : entity work.mcu_8core_dsp_worker
            generic map (
                CORE_ID   => i,
                ROM_DEPTH => ROM_DEPTH
            )
            port map (
                clk           => clk,
                rst           => rst,
                input_we      => input_we,
                input_waddr   => input_waddr,
                input_wdata   => input_wdata,
                output_real   => core_real(i),
                output_imag   => core_imag(i),
                pc_debug      => core_pc(i),
                instr_debug   => core_instr(i),
                halted_debug  => core_halted(i),
                illegal_debug => core_illegal(i)
            );
    end generate;

    process(core_halted)
        variable reduced : std_logic;
    begin
        reduced := '1';
        for i in core_halted'range loop
            reduced := reduced and core_halted(i);
        end loop;
        all_halted <= reduced;
    end process;

    process(core_illegal)
        variable reduced : std_logic;
    begin
        reduced := '0';
        for i in core_illegal'range loop
            reduced := reduced or core_illegal(i);
        end loop;
        any_illegal <= reduced;
    end process;

    process(output_raddr, core_real, core_imag)
        variable addr_i : natural;
    begin
        addr_i := to_integer(unsigned(output_raddr));
        output_rdata <= (others => '0');
        if addr_i < CORE_COUNT then
            output_rdata <= core_real(addr_i);
        elsif addr_i < CORE_COUNT * 2 then
            output_rdata <= core_imag(addr_i - CORE_COUNT);
        end if;
    end process;

    pc_debug <= core_pc(0);
    instr_debug <= core_instr(0);
    halted_debug <= all_halted;
    illegal_debug <= any_illegal;
    flag_z_debug <= '0';
    flag_n_debug <= '0';
end architecture rtl;
