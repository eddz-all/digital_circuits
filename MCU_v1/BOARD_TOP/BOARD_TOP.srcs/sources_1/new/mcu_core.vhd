library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mcu_v1_core is
    generic (
        MEM_FILE  : string := "asm/fft8_v1_mcu32_basic.mem";
        ROM_DEPTH : positive := 1024
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
    signal alu_control   : std_logic_vector(2 downto 0) := "010";
    signal alu_src_imm   : std_logic := '0';
    signal ra1           : std_logic_vector(3 downto 0) := (others => '0');
    signal ra2           : std_logic_vector(3 downto 0) := (others => '0');
    signal wa            : std_logic_vector(3 downto 0) := (others => '0');
    signal imm_ext       : std_logic_vector(31 downto 0) := (others => '0');
    signal branch_offset : std_logic_vector(31 downto 0) := (others => '0');

    signal reg_rd1 : std_logic_vector(31 downto 0) := (others => '0');
    signal reg_rd2 : std_logic_vector(31 downto 0) := (others => '0');
    signal alu_b   : std_logic_vector(31 downto 0) := (others => '0');
    signal alu_res : std_logic_vector(31 downto 0) := (others => '0');
    signal mem_rd  : std_logic_vector(31 downto 0) := (others => '0');
    signal wb_data : std_logic_vector(31 downto 0) := (others => '0');

    signal halted_i : std_logic;
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
            alu_control   => alu_control,
            alu_src_imm   => alu_src_imm,
            ra1           => ra1,
            ra2           => ra2,
            wa            => wa,
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
            wa  => wa,
            wd  => wb_data,
            rd1 => reg_rd1,
            rd2 => reg_rd2
        );

    alu_b <= imm_ext when alu_src_imm = '1' else reg_rd2;

    u_alu : entity work.mcu_v1_alu
        port map (
            a           => reg_rd1,
            b           => alu_b,
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
            mem_read     => mem_read,
            mem_write    => mem_write,
            read_data    => mem_rd,
            input_we     => input_we,
            input_waddr  => input_waddr,
            input_wdata  => input_wdata,
            output_raddr => output_raddr,
            output_rdata => output_rdata
        );

    wb_data <= mem_rd when mem_to_reg = '1' else alu_res;

    pc_next <= std_logic_vector(signed(pc_reg) + to_signed(8, 32) + signed(branch_offset))
        when branch_taken = '1'
        else std_logic_vector(unsigned(pc_reg) + 4);

    halted_i <= '1' when branch_taken = '1' and pc_next = pc_reg else '0';

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

