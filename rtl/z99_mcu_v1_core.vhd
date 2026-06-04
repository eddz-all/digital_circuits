library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.mcu_v1_pkg.all;

entity mcu_v1_core is
    generic (
        MEM_FILE  : string := "asm/fft8_v5_arm_strict_59.mem";
        ROM_DEPTH : positive := 256
    );
    port (
        clk : in std_logic;
        rst : in std_logic;

        input_we    : in  std_logic;
        input_waddr : in  std_logic_vector(5 downto 0);
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
    signal pc_reg  : std_logic_vector(31 downto 0) := (others => '0');
    signal pc_next : std_logic_vector(31 downto 0);
    signal instr   : std_logic_vector(31 downto 0) := (others => '0');

    signal flag_z_reg : std_logic := '0';
    signal flag_n_reg : std_logic := '0';
    signal alu_z      : std_logic := '0';
    signal alu_n      : std_logic := '0';

    signal cond_ok       : std_logic := '0';
    signal illegal_instr : std_logic := '0';
    signal reg_write     : std_logic := '0';
    signal mem_read      : std_logic := '0';
    signal mem_write     : std_logic := '0';
    signal mem_to_reg    : std_logic := '0';
    signal flag_write    : std_logic := '0';
    signal branch_taken  : std_logic := '0';
    signal branch_link   : std_logic := '0';
    signal bulk_load     : std_logic := '0';
    signal bulk_store    : std_logic := '0';
    signal store_double  : std_logic := '0';
    signal bulk_writeback : std_logic := '0';
    signal alu_control   : std_logic_vector(3 downto 0) := ALU_ADD;
    signal alu_src_imm   : std_logic := '0';
    signal ra1           : std_logic_vector(3 downto 0) := (others => '0');
    signal ra2           : std_logic_vector(3 downto 0) := (others => '0');
    signal ra3           : std_logic_vector(3 downto 0) := (others => '0');
    signal wa            : std_logic_vector(3 downto 0) := (others => '0');
    signal bulk_regmask  : std_logic_vector(15 downto 0) := (others => '0');
    signal imm_ext       : std_logic_vector(31 downto 0) := (others => '0');
    signal branch_offset : std_logic_vector(31 downto 0) := (others => '0');

    signal reg_rd1 : std_logic_vector(31 downto 0) := (others => '0');
    signal reg_rd2 : std_logic_vector(31 downto 0) := (others => '0');
    signal reg_rd3 : std_logic_vector(31 downto 0) := (others => '0');
    signal reg_bulk_rd : std_logic_vector(511 downto 0) := (others => '0');
    signal alu_b   : std_logic_vector(31 downto 0) := (others => '0');
    signal alu_res : std_logic_vector(31 downto 0) := (others => '0');
    signal mem_rd  : std_logic_vector(31 downto 0) := (others => '0');
    signal bulk_mem_rd : std_logic_vector(511 downto 0) := (others => '0');
    signal bulk_we_mask : std_logic_vector(15 downto 0) := (others => '0');
    signal bulk_wd : std_logic_vector(511 downto 0) := (others => '0');
    signal bulk_store_data : std_logic_vector(511 downto 0) := (others => '0');
    signal ldmia_wb_data : std_logic_vector(31 downto 0) := (others => '0');
    signal wb_data : std_logic_vector(31 downto 0) := (others => '0');

    signal halted_i : std_logic;

    function popcount(mask : std_logic_vector(15 downto 0)) return natural is
        variable count : natural := 0;
    begin
        for i in mask'range loop
            if mask(i) = '1' then
                count := count + 1;
            end if;
        end loop;
        return count;
    end function;
begin
    u_rom : entity work.mcu_v1_instr_rom
        generic map (
            MEM_FILE => MEM_FILE,
            DEPTH    => ROM_DEPTH
        )
        port map (
            pc    => pc_reg,
            instr => instr
        );

    u_decoder : entity work.mcu_v1_decoder
        port map (
            instr         => instr,
            flag_z        => flag_z_reg,
            flag_n        => flag_n_reg,
            cond_ok       => cond_ok,
            illegal_instr => illegal_instr,
            reg_write     => reg_write,
            mem_read      => mem_read,
            mem_write     => mem_write,
            mem_to_reg    => mem_to_reg,
            flag_write    => flag_write,
            branch_taken  => branch_taken,
            branch_link   => branch_link,
            bulk_load     => bulk_load,
            bulk_store    => bulk_store,
            store_double  => store_double,
            bulk_writeback => bulk_writeback,
            alu_control   => alu_control,
            alu_src_imm   => alu_src_imm,
            ra1           => ra1,
            ra2           => ra2,
            ra3           => ra3,
            wa            => wa,
            bulk_regmask  => bulk_regmask,
            imm_ext       => imm_ext,
            branch_offset => branch_offset
        );

    u_regfile : entity work.mcu_v1_regfile
        port map (
            clk => clk,
            rst => rst,
            we  => reg_write,
            ra1 => ra1,
            ra2 => ra2,
            ra3 => ra3,
            wa  => wa,
            wd  => wb_data,
            bulk_we_mask => bulk_we_mask,
            bulk_wd      => bulk_wd,
            rd1 => reg_rd1,
            rd2 => reg_rd2,
            rd3 => reg_rd3,
            bulk_rd => reg_bulk_rd
        );

    alu_b <= imm_ext when alu_src_imm = '1' else reg_rd2;

    u_alu : entity work.mcu_v1_alu
        port map (
            a           => reg_rd1,
            b           => alu_b,
            c           => reg_rd3,
            alu_control => alu_control,
            result      => alu_res,
            flag_z      => alu_z,
            flag_n      => alu_n
        );

    u_data_mem : entity work.mcu_v1_data_mem
        port map (
            clk          => clk,
            rst          => rst,
            addr         => alu_res,
            write_data   => reg_rd2,
            write_data2  => reg_rd3,
            mem_read     => mem_read,
            mem_write    => mem_write,
            bulk_store   => bulk_store,
            store_double => store_double,
            bulk_write_data => bulk_store_data,
            bulk_regmask => bulk_regmask,
            read_data    => mem_rd,
            bulk_read_data => bulk_mem_rd,
            input_we     => input_we,
            input_waddr  => input_waddr,
            input_wdata  => input_wdata,
            output_raddr => output_raddr,
            output_rdata => output_rdata
        );

    process(bulk_regmask, bulk_mem_rd)
        variable data_index : natural range 0 to 16;
    begin
        bulk_wd <= (others => '0');
        data_index := 0;
        for reg_index in 0 to 15 loop
            if bulk_regmask(reg_index) = '1' then
                bulk_wd(32 * reg_index + 31 downto 32 * reg_index) <=
                    bulk_mem_rd(32 * data_index + 31 downto 32 * data_index);
                data_index := data_index + 1;
            end if;
        end loop;
    end process;

    process(bulk_regmask, reg_bulk_rd)
        variable data_index : natural range 0 to 16;
    begin
        bulk_store_data <= (others => '0');
        data_index := 0;
        for reg_index in 0 to 15 loop
            if bulk_regmask(reg_index) = '1' then
                bulk_store_data(32 * data_index + 31 downto 32 * data_index) <=
                    reg_bulk_rd(32 * reg_index + 31 downto 32 * reg_index);
                data_index := data_index + 1;
            end if;
        end loop;
    end process;

    bulk_we_mask <= bulk_regmask when bulk_load = '1' else (others => '0');
    ldmia_wb_data <= std_logic_vector(unsigned(reg_rd1) + to_unsigned(4 * popcount(bulk_regmask), 32));

    wb_data <= std_logic_vector(unsigned(pc_reg) + 4) when branch_link = '1'
        else ldmia_wb_data when bulk_writeback = '1'
        else mem_rd when mem_to_reg = '1'
        else alu_res;

    u_pc_unit : entity work.mcu_v1_pc_unit
        port map (
            pc_current    => pc_reg,
            branch_taken  => branch_taken,
            branch_offset => branch_offset,
            pc_next       => pc_next,
            halted        => halted_i
        );

    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                pc_reg <= (others => '0');
                flag_z_reg <= '0';
                flag_n_reg <= '0';
            else
                pc_reg <= pc_next;
                if flag_write = '1' then
                    flag_z_reg <= alu_z;
                    flag_n_reg <= alu_n;
                end if;
            end if;
        end if;
    end process;

    pc_debug <= pc_reg;
    instr_debug <= instr;
    halted_debug <= halted_i;
    illegal_debug <= illegal_instr;
    flag_z_debug <= flag_z_reg;
    flag_n_debug <= flag_n_reg;
end architecture rtl;
