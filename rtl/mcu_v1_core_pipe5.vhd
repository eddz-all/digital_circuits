library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mcu_v1_core_pipe5 is
    generic (
        MEM_FILE  : string := "asm/fft8_v1_mcu32_basic.mem";
        ROM_DEPTH : positive := 1024
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
        flag_n_debug  : out std_logic;

        stat_core_cycles      : out std_logic_vector(31 downto 0);
        stat_issue_count      : out std_logic_vector(31 downto 0);
        stat_load_use_stalls  : out std_logic_vector(31 downto 0);
        stat_bulk_load_stalls : out std_logic_vector(31 downto 0);
        stat_flag_stalls      : out std_logic_vector(31 downto 0);
        stat_branch_flushes   : out std_logic_vector(31 downto 0);
        stat_halt_events      : out std_logic_vector(31 downto 0);
        stat_seg_prologue     : out std_logic_vector(31 downto 0);
        stat_seg_input_load   : out std_logic_vector(31 downto 0);
        stat_seg_stage1       : out std_logic_vector(31 downto 0);
        stat_seg_stage2       : out std_logic_vector(31 downto 0);
        stat_seg_stage3       : out std_logic_vector(31 downto 0);
        stat_seg_twiddle      : out std_logic_vector(31 downto 0);
        stat_seg_output       : out std_logic_vector(31 downto 0);
        stat_seg_done         : out std_logic_vector(31 downto 0)
    );
end entity mcu_v1_core_pipe5;

architecture rtl of mcu_v1_core_pipe5 is
    signal fetch_pc    : std_logic_vector(31 downto 0) := (others => '0');
    signal fetch_instr : std_logic_vector(31 downto 0) := (others => '0');

    signal if_id_valid : std_logic := '0';
    signal if_id_pc    : std_logic_vector(31 downto 0) := (others => '0');
    signal if_id_instr : std_logic_vector(31 downto 0) := (others => '0');

    signal flag_z_reg : std_logic := '0';
    signal flag_n_reg : std_logic := '0';
    signal illegal_reg : std_logic := '0';

    signal dec_cond_ok       : std_logic := '0';
    signal dec_illegal       : std_logic := '0';
    signal dec_reg_write     : std_logic := '0';
    signal dec_mem_read      : std_logic := '0';
    signal dec_mem_write     : std_logic := '0';
    signal dec_mem_to_reg    : std_logic := '0';
    signal dec_flag_write    : std_logic := '0';
    signal dec_branch_taken  : std_logic := '0';
    signal dec_bulk_store    : std_logic := '0';
    signal dec_bulk_writeback : std_logic := '0';
    signal dec_alu_control   : std_logic_vector(3 downto 0) := "0010";
    signal dec_alu_src_imm   : std_logic := '0';
    signal dec_ra1           : std_logic_vector(3 downto 0) := (others => '0');
    signal dec_ra2           : std_logic_vector(3 downto 0) := (others => '0');
    signal dec_ra3           : std_logic_vector(3 downto 0) := (others => '0');
    signal dec_wa            : std_logic_vector(3 downto 0) := (others => '0');
    signal dec_bulk_regmask  : std_logic_vector(15 downto 0) := (others => '0');
    signal dec_imm_ext       : std_logic_vector(31 downto 0) := (others => '0');
    signal dec_branch_offset : std_logic_vector(31 downto 0) := (others => '0');

    signal reg_rd1 : std_logic_vector(31 downto 0) := (others => '0');
    signal reg_rd2 : std_logic_vector(31 downto 0) := (others => '0');
    signal reg_rd3 : std_logic_vector(31 downto 0) := (others => '0');
    signal reg_bulk_rd : std_logic_vector(511 downto 0) := (others => '0');
    signal id_bulk_data : std_logic_vector(511 downto 0) := (others => '0');

    signal id_ex_valid : std_logic := '0';
    signal id_ex_pc : std_logic_vector(31 downto 0) := (others => '0');
    signal id_ex_instr : std_logic_vector(31 downto 0) := (others => '0');
    signal id_ex_reg_write : std_logic := '0';
    signal id_ex_mem_read : std_logic := '0';
    signal id_ex_mem_write : std_logic := '0';
    signal id_ex_mem_to_reg : std_logic := '0';
    signal id_ex_flag_write : std_logic := '0';
    signal id_ex_branch_taken : std_logic := '0';
    signal id_ex_bulk_store : std_logic := '0';
    signal id_ex_bulk_writeback : std_logic := '0';
    signal id_ex_alu_control : std_logic_vector(3 downto 0) := "0010";
    signal id_ex_alu_src_imm : std_logic := '0';
    signal id_ex_ra1 : std_logic_vector(3 downto 0) := (others => '0');
    signal id_ex_ra2 : std_logic_vector(3 downto 0) := (others => '0');
    signal id_ex_ra3 : std_logic_vector(3 downto 0) := (others => '0');
    signal id_ex_wa : std_logic_vector(3 downto 0) := (others => '0');
    signal id_ex_bulk_regmask : std_logic_vector(15 downto 0) := (others => '0');
    signal id_ex_imm_ext : std_logic_vector(31 downto 0) := (others => '0');
    signal id_ex_branch_offset : std_logic_vector(31 downto 0) := (others => '0');
    signal id_ex_op1 : std_logic_vector(31 downto 0) := (others => '0');
    signal id_ex_op2 : std_logic_vector(31 downto 0) := (others => '0');
    signal id_ex_op3 : std_logic_vector(31 downto 0) := (others => '0');
    signal id_ex_bulk_data : std_logic_vector(511 downto 0) := (others => '0');

    signal ex_op1 : std_logic_vector(31 downto 0) := (others => '0');
    signal ex_op2 : std_logic_vector(31 downto 0) := (others => '0');
    signal ex_op3 : std_logic_vector(31 downto 0) := (others => '0');
    signal ex_alu_b : std_logic_vector(31 downto 0) := (others => '0');
    signal ex_alu_res : std_logic_vector(31 downto 0) := (others => '0');
    signal ex_alu_z : std_logic := '0';
    signal ex_alu_n : std_logic := '0';
    signal ex_result : std_logic_vector(31 downto 0) := (others => '0');
    signal ex_branch_target : std_logic_vector(31 downto 0) := (others => '0');
    signal ex_halted : std_logic := '0';

    signal ex_mem_valid : std_logic := '0';
    signal ex_mem_pc : std_logic_vector(31 downto 0) := (others => '0');
    signal ex_mem_instr : std_logic_vector(31 downto 0) := (others => '0');
    signal ex_mem_reg_write : std_logic := '0';
    signal ex_mem_mem_read : std_logic := '0';
    signal ex_mem_mem_write : std_logic := '0';
    signal ex_mem_mem_to_reg : std_logic := '0';
    signal ex_mem_flag_write : std_logic := '0';
    signal ex_mem_bulk_store : std_logic := '0';
    signal ex_mem_wa : std_logic_vector(3 downto 0) := (others => '0');
    signal ex_mem_bulk_regmask : std_logic_vector(15 downto 0) := (others => '0');
    signal ex_mem_addr : std_logic_vector(31 downto 0) := (others => '0');
    signal ex_mem_result : std_logic_vector(31 downto 0) := (others => '0');
    signal ex_mem_write_data : std_logic_vector(31 downto 0) := (others => '0');
    signal ex_mem_bulk_data : std_logic_vector(511 downto 0) := (others => '0');
    signal ex_mem_flag_z : std_logic := '0';
    signal ex_mem_flag_n : std_logic := '0';

    signal mem_rd : std_logic_vector(31 downto 0) := (others => '0');

    signal mem_wb_valid : std_logic := '0';
    signal mem_wb_pc : std_logic_vector(31 downto 0) := (others => '0');
    signal mem_wb_instr : std_logic_vector(31 downto 0) := (others => '0');
    signal mem_wb_reg_write : std_logic := '0';
    signal mem_wb_flag_write : std_logic := '0';
    signal mem_wb_wa : std_logic_vector(3 downto 0) := (others => '0');
    signal mem_wb_result : std_logic_vector(31 downto 0) := (others => '0');
    signal mem_wb_flag_z : std_logic := '0';
    signal mem_wb_flag_n : std_logic := '0';

    constant OP_DATA   : std_logic_vector(1 downto 0) := "00";
    constant OP_MEM    : std_logic_vector(1 downto 0) := "01";
    constant OP_BRANCH : std_logic_vector(1 downto 0) := "10";
    constant OP_EXT    : std_logic_vector(1 downto 0) := "11";

    constant OPC_ADD : std_logic_vector(3 downto 0) := "0100";
    constant OPC_SUB : std_logic_vector(3 downto 0) := "0010";
    constant OPC_MOV : std_logic_vector(3 downto 0) := "1101";
    constant OPC_CMP : std_logic_vector(3 downto 0) := "1010";
    constant OPC_MUL : std_logic_vector(3 downto 0) := "1001";
    constant OPC_ASR : std_logic_vector(3 downto 0) := "1111";

    constant EXT_SMUAD  : std_logic_vector(4 downto 0) := "00010";
    constant EXT_SMUSD  : std_logic_vector(4 downto 0) := "00011";
    constant EXT_PKHBT  : std_logic_vector(4 downto 0) := "00101";
    constant EXT_SSAX   : std_logic_vector(4 downto 0) := "01000";
    constant EXT_SSUB16 : std_logic_vector(4 downto 0) := "01001";
    constant EXT_SMLAD  : std_logic_vector(4 downto 0) := "01010";
    constant EXT_STMIA  : std_logic_vector(4 downto 0) := "01011";
    constant EXT_SADD16 : std_logic_vector(4 downto 0) := "01100";

    signal dec_read_ra1 : std_logic := '0';
    signal dec_read_ra2 : std_logic := '0';
    signal dec_read_ra3 : std_logic := '0';

    signal stall_id : std_logic := '0';
    signal stall_load_use : std_logic := '0';
    signal stall_bulk_load : std_logic := '0';
    signal stall_flag : std_logic := '0';
    signal halted_reg : std_logic := '0';
    signal halted_pc : std_logic_vector(31 downto 0) := (others => '0');
    signal halted_instr : std_logic_vector(31 downto 0) := (others => '0');

    signal stat_core_cycles_reg : unsigned(31 downto 0) := (others => '0');
    signal stat_issue_count_reg : unsigned(31 downto 0) := (others => '0');
    signal stat_load_use_stalls_reg : unsigned(31 downto 0) := (others => '0');
    signal stat_bulk_load_stalls_reg : unsigned(31 downto 0) := (others => '0');
    signal stat_flag_stalls_reg : unsigned(31 downto 0) := (others => '0');
    signal stat_branch_flushes_reg : unsigned(31 downto 0) := (others => '0');
    signal stat_halt_events_reg : unsigned(31 downto 0) := (others => '0');
    signal stat_seg_prologue_reg : unsigned(31 downto 0) := (others => '0');
    signal stat_seg_input_load_reg : unsigned(31 downto 0) := (others => '0');
    signal stat_seg_stage1_reg : unsigned(31 downto 0) := (others => '0');
    signal stat_seg_stage2_reg : unsigned(31 downto 0) := (others => '0');
    signal stat_seg_stage3_reg : unsigned(31 downto 0) := (others => '0');
    signal stat_seg_twiddle_reg : unsigned(31 downto 0) := (others => '0');
    signal stat_seg_output_reg : unsigned(31 downto 0) := (others => '0');
    signal stat_seg_done_reg : unsigned(31 downto 0) := (others => '0');

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

    function reg_in_mask(mask : std_logic_vector(15 downto 0); reg_id : std_logic_vector(3 downto 0)) return boolean is
    begin
        return mask(to_integer(unsigned(reg_id))) = '1';
    end function;

    function same_reg(a : std_logic_vector(3 downto 0); b : std_logic_vector(3 downto 0)) return boolean is
    begin
        return a = b;
    end function;
begin
    u_rom : entity work.mcu_v1_instr_rom
        generic map (
            MEM_FILE => MEM_FILE,
            DEPTH    => ROM_DEPTH
        )
        port map (
            pc    => fetch_pc,
            instr => fetch_instr
        );

    u_decoder : entity work.mcu_v1_decoder
        port map (
            instr         => if_id_instr,
            flag_z        => flag_z_reg,
            flag_n        => flag_n_reg,
            cond_ok       => dec_cond_ok,
            illegal_instr => dec_illegal,
            reg_write     => dec_reg_write,
            mem_read      => dec_mem_read,
            mem_write     => dec_mem_write,
            mem_to_reg    => dec_mem_to_reg,
            flag_write    => dec_flag_write,
            branch_taken  => dec_branch_taken,
            bulk_store    => dec_bulk_store,
            bulk_writeback => dec_bulk_writeback,
            alu_control   => dec_alu_control,
            alu_src_imm   => dec_alu_src_imm,
            ra1           => dec_ra1,
            ra2           => dec_ra2,
            ra3           => dec_ra3,
            wa            => dec_wa,
            bulk_regmask  => dec_bulk_regmask,
            imm_ext       => dec_imm_ext,
            branch_offset => dec_branch_offset
        );

    u_regfile : entity work.mcu_v1_regfile
        port map (
            clk => clk,
            rst => rst,
            we  => mem_wb_reg_write,
            ra1 => dec_ra1,
            ra2 => dec_ra2,
            ra3 => dec_ra3,
            wa  => mem_wb_wa,
            wd  => mem_wb_result,
            rd1 => reg_rd1,
            rd2 => reg_rd2,
            rd3 => reg_rd3,
            bulk_rd => reg_bulk_rd
        );

    u_alu : entity work.mcu_v1_alu
        port map (
            a           => ex_op1,
            b           => ex_alu_b,
            c           => ex_op3,
            alu_control => id_ex_alu_control,
            result      => ex_alu_res,
            flag_z      => ex_alu_z,
            flag_n      => ex_alu_n
        );

    u_data_mem : entity work.mcu_v1_data_mem
        port map (
            clk          => clk,
            rst          => rst,
            addr         => ex_mem_addr,
            write_data   => ex_mem_write_data,
            mem_read     => ex_mem_mem_read,
            mem_write    => ex_mem_mem_write,
            bulk_store   => ex_mem_bulk_store,
            bulk_write_data => ex_mem_bulk_data,
            bulk_regmask => ex_mem_bulk_regmask,
            read_data    => mem_rd,
            input_we     => input_we,
            input_waddr  => input_waddr,
            input_wdata  => input_wdata,
            output_raddr => output_raddr,
            output_rdata => output_rdata
        );

    process(id_ex_ra1, id_ex_op1, ex_mem_valid, ex_mem_reg_write, ex_mem_mem_to_reg,
            ex_mem_wa, ex_mem_result, mem_wb_valid, mem_wb_reg_write, mem_wb_wa, mem_wb_result)
    begin
        ex_op1 <= id_ex_op1;
        if ex_mem_valid = '1' and ex_mem_reg_write = '1' and ex_mem_mem_to_reg = '0'
            and same_reg(id_ex_ra1, ex_mem_wa) then
            ex_op1 <= ex_mem_result;
        elsif mem_wb_valid = '1' and mem_wb_reg_write = '1' and same_reg(id_ex_ra1, mem_wb_wa) then
            ex_op1 <= mem_wb_result;
        end if;
    end process;

    process(id_ex_ra2, id_ex_op2, ex_mem_valid, ex_mem_reg_write, ex_mem_mem_to_reg,
            ex_mem_wa, ex_mem_result, mem_wb_valid, mem_wb_reg_write, mem_wb_wa, mem_wb_result)
    begin
        ex_op2 <= id_ex_op2;
        if ex_mem_valid = '1' and ex_mem_reg_write = '1' and ex_mem_mem_to_reg = '0'
            and same_reg(id_ex_ra2, ex_mem_wa) then
            ex_op2 <= ex_mem_result;
        elsif mem_wb_valid = '1' and mem_wb_reg_write = '1' and same_reg(id_ex_ra2, mem_wb_wa) then
            ex_op2 <= mem_wb_result;
        end if;
    end process;

    process(id_ex_ra3, id_ex_op3, ex_mem_valid, ex_mem_reg_write, ex_mem_mem_to_reg,
            ex_mem_wa, ex_mem_result, mem_wb_valid, mem_wb_reg_write, mem_wb_wa, mem_wb_result)
    begin
        ex_op3 <= id_ex_op3;
        if ex_mem_valid = '1' and ex_mem_reg_write = '1' and ex_mem_mem_to_reg = '0'
            and same_reg(id_ex_ra3, ex_mem_wa) then
            ex_op3 <= ex_mem_result;
        elsif mem_wb_valid = '1' and mem_wb_reg_write = '1' and same_reg(id_ex_ra3, mem_wb_wa) then
            ex_op3 <= mem_wb_result;
        end if;
    end process;

    ex_alu_b <= id_ex_imm_ext when id_ex_alu_src_imm = '1' else ex_op2;

    ex_result <= std_logic_vector(unsigned(ex_op1) + to_unsigned(4 * popcount(id_ex_bulk_regmask), 32))
        when id_ex_bulk_writeback = '1'
        else ex_alu_res;

    ex_branch_target <= std_logic_vector(signed(id_ex_pc) + to_signed(8, 32) + signed(id_ex_branch_offset));
    ex_halted <= '1' when id_ex_valid = '1' and id_ex_branch_taken = '1' and ex_branch_target = id_ex_pc else '0';

    process(if_id_instr)
    begin
        dec_read_ra1 <= '0';
        dec_read_ra2 <= '0';
        dec_read_ra3 <= '0';

        case if_id_instr(27 downto 26) is
            when OP_DATA =>
                case if_id_instr(24 downto 21) is
                    when OPC_ADD | OPC_SUB | OPC_CMP =>
                        dec_read_ra1 <= '1';
                        if if_id_instr(25) = '0' then
                            dec_read_ra2 <= '1';
                        end if;
                    when OPC_MOV =>
                        if if_id_instr(25) = '0' then
                            if if_id_instr(11 downto 4) = x"00" then
                                dec_read_ra2 <= '1';
                            else
                                dec_read_ra1 <= '1';
                            end if;
                        end if;
                    when OPC_MUL =>
                        dec_read_ra1 <= '1';
                        dec_read_ra2 <= '1';
                    when OPC_ASR =>
                        dec_read_ra1 <= '1';
                    when others =>
                        null;
                end case;

            when OP_MEM =>
                dec_read_ra1 <= '1';
                if if_id_instr(25) = '0' then
                    dec_read_ra2 <= '1';
                end if;

            when OP_EXT =>
                case if_id_instr(25 downto 21) is
                    when EXT_SADD16 | EXT_SMUAD | EXT_SMUSD | EXT_PKHBT | EXT_SSAX | EXT_SSUB16 =>
                        dec_read_ra1 <= '1';
                        dec_read_ra2 <= '1';
                    when EXT_SMLAD =>
                        dec_read_ra1 <= '1';
                        dec_read_ra2 <= '1';
                        dec_read_ra3 <= '1';
                    when EXT_STMIA =>
                        dec_read_ra1 <= '1';
                    when others =>
                        null;
                end case;

            when OP_BRANCH =>
                null;

            when others =>
                null;
        end case;
    end process;

    process(reg_bulk_rd, id_ex_valid, id_ex_reg_write, id_ex_mem_to_reg, id_ex_wa, ex_result,
            ex_mem_valid, ex_mem_reg_write, ex_mem_mem_to_reg, ex_mem_wa, ex_mem_result,
            mem_wb_valid, mem_wb_reg_write, mem_wb_wa, mem_wb_result)
        variable data : std_logic_vector(511 downto 0);
        variable reg_index : natural range 0 to 15;
    begin
        data := reg_bulk_rd;

        if mem_wb_valid = '1' and mem_wb_reg_write = '1' then
            reg_index := to_integer(unsigned(mem_wb_wa));
            data(32 * reg_index + 31 downto 32 * reg_index) := mem_wb_result;
        end if;

        if ex_mem_valid = '1' and ex_mem_reg_write = '1' and ex_mem_mem_to_reg = '0' then
            reg_index := to_integer(unsigned(ex_mem_wa));
            data(32 * reg_index + 31 downto 32 * reg_index) := ex_mem_result;
        end if;

        if id_ex_valid = '1' and id_ex_reg_write = '1' and id_ex_mem_to_reg = '0' then
            reg_index := to_integer(unsigned(id_ex_wa));
            data(32 * reg_index + 31 downto 32 * reg_index) := ex_result;
        end if;

        id_bulk_data <= data;
    end process;

    process(if_id_valid, dec_ra1, dec_ra2, dec_ra3, dec_bulk_store, dec_bulk_regmask,
            dec_read_ra1, dec_read_ra2, dec_read_ra3,
            if_id_instr, id_ex_valid, id_ex_reg_write, id_ex_mem_to_reg, id_ex_flag_write,
            id_ex_wa, ex_mem_valid, ex_mem_reg_write, ex_mem_mem_to_reg, ex_mem_flag_write, ex_mem_wa,
            mem_wb_valid, mem_wb_reg_write, mem_wb_flag_write, mem_wb_wa)
        variable load_use_v : std_logic;
        variable bulk_load_v : std_logic;
        variable flag_v : std_logic;
    begin
        load_use_v := '0';
        bulk_load_v := '0';
        flag_v := '0';

        if if_id_valid = '1' then
            if id_ex_valid = '1' and id_ex_mem_to_reg = '1' and id_ex_reg_write = '1'
                and ((dec_read_ra1 = '1' and same_reg(dec_ra1, id_ex_wa))
                    or (dec_read_ra2 = '1' and same_reg(dec_ra2, id_ex_wa))
                    or (dec_read_ra3 = '1' and same_reg(dec_ra3, id_ex_wa))) then
                if dec_bulk_store = '1' then
                    bulk_load_v := '1';
                else
                    load_use_v := '1';
                end if;
            end if;

            if dec_bulk_store = '1' then
                if id_ex_valid = '1' and id_ex_reg_write = '1' and id_ex_mem_to_reg = '1'
                    and reg_in_mask(dec_bulk_regmask, id_ex_wa) then
                    bulk_load_v := '1';
                elsif ex_mem_valid = '1' and ex_mem_reg_write = '1' and ex_mem_mem_to_reg = '1'
                    and reg_in_mask(dec_bulk_regmask, ex_mem_wa) then
                    bulk_load_v := '1';
                end if;
            end if;

            if if_id_instr(31 downto 28) /= "1110"
                and ((id_ex_valid = '1' and id_ex_flag_write = '1')
                    or (ex_mem_valid = '1' and ex_mem_flag_write = '1')
                    or (mem_wb_valid = '1' and mem_wb_flag_write = '1')) then
                flag_v := '1';
            end if;
        end if;

        stall_load_use <= load_use_v;
        stall_bulk_load <= bulk_load_v;
        stall_flag <= flag_v;
        stall_id <= load_use_v or bulk_load_v or flag_v;
    end process;

    process(clk)
        variable issue_pc_i : natural;
    begin
        if rising_edge(clk) then
            if rst = '1' then
                fetch_pc <= (others => '0');
                if_id_valid <= '0';
                if_id_pc <= (others => '0');
                if_id_instr <= (others => '0');

                id_ex_valid <= '0';
                id_ex_pc <= (others => '0');
                id_ex_instr <= (others => '0');
                id_ex_reg_write <= '0';
                id_ex_mem_read <= '0';
                id_ex_mem_write <= '0';
                id_ex_mem_to_reg <= '0';
                id_ex_flag_write <= '0';
                id_ex_branch_taken <= '0';
                id_ex_bulk_store <= '0';
                id_ex_bulk_writeback <= '0';
                id_ex_alu_control <= "0010";
                id_ex_alu_src_imm <= '0';
                id_ex_ra1 <= (others => '0');
                id_ex_ra2 <= (others => '0');
                id_ex_ra3 <= (others => '0');
                id_ex_wa <= (others => '0');
                id_ex_bulk_regmask <= (others => '0');
                id_ex_imm_ext <= (others => '0');
                id_ex_branch_offset <= (others => '0');
                id_ex_op1 <= (others => '0');
                id_ex_op2 <= (others => '0');
                id_ex_op3 <= (others => '0');
                id_ex_bulk_data <= (others => '0');

                ex_mem_valid <= '0';
                ex_mem_pc <= (others => '0');
                ex_mem_instr <= (others => '0');
                ex_mem_reg_write <= '0';
                ex_mem_mem_read <= '0';
                ex_mem_mem_write <= '0';
                ex_mem_mem_to_reg <= '0';
                ex_mem_flag_write <= '0';
                ex_mem_bulk_store <= '0';
                ex_mem_wa <= (others => '0');
                ex_mem_bulk_regmask <= (others => '0');
                ex_mem_addr <= (others => '0');
                ex_mem_result <= (others => '0');
                ex_mem_write_data <= (others => '0');
                ex_mem_bulk_data <= (others => '0');
                ex_mem_flag_z <= '0';
                ex_mem_flag_n <= '0';

                mem_wb_valid <= '0';
                mem_wb_pc <= (others => '0');
                mem_wb_instr <= (others => '0');
                mem_wb_reg_write <= '0';
                mem_wb_flag_write <= '0';
                mem_wb_wa <= (others => '0');
                mem_wb_result <= (others => '0');
                mem_wb_flag_z <= '0';
                mem_wb_flag_n <= '0';

                flag_z_reg <= '0';
                flag_n_reg <= '0';
                illegal_reg <= '0';
                halted_reg <= '0';
                halted_pc <= (others => '0');
                halted_instr <= (others => '0');
                stat_core_cycles_reg <= (others => '0');
                stat_issue_count_reg <= (others => '0');
                stat_load_use_stalls_reg <= (others => '0');
                stat_bulk_load_stalls_reg <= (others => '0');
                stat_flag_stalls_reg <= (others => '0');
                stat_branch_flushes_reg <= (others => '0');
                stat_halt_events_reg <= (others => '0');
                stat_seg_prologue_reg <= (others => '0');
                stat_seg_input_load_reg <= (others => '0');
                stat_seg_stage1_reg <= (others => '0');
                stat_seg_stage2_reg <= (others => '0');
                stat_seg_stage3_reg <= (others => '0');
                stat_seg_twiddle_reg <= (others => '0');
                stat_seg_output_reg <= (others => '0');
                stat_seg_done_reg <= (others => '0');
            elsif halted_reg = '0' then
                stat_core_cycles_reg <= stat_core_cycles_reg + 1;

                if mem_wb_valid = '1' and mem_wb_flag_write = '1' then
                    flag_z_reg <= mem_wb_flag_z;
                    flag_n_reg <= mem_wb_flag_n;
                end if;

                mem_wb_valid <= ex_mem_valid;
                mem_wb_pc <= ex_mem_pc;
                mem_wb_instr <= ex_mem_instr;
                mem_wb_reg_write <= ex_mem_reg_write;
                mem_wb_flag_write <= ex_mem_flag_write;
                mem_wb_wa <= ex_mem_wa;
                mem_wb_flag_z <= ex_mem_flag_z;
                mem_wb_flag_n <= ex_mem_flag_n;
                if ex_mem_mem_to_reg = '1' then
                    mem_wb_result <= mem_rd;
                else
                    mem_wb_result <= ex_mem_result;
                end if;

                ex_mem_valid <= id_ex_valid;
                ex_mem_pc <= id_ex_pc;
                ex_mem_instr <= id_ex_instr;
                ex_mem_reg_write <= id_ex_reg_write;
                ex_mem_mem_read <= id_ex_mem_read;
                ex_mem_mem_write <= id_ex_mem_write;
                ex_mem_mem_to_reg <= id_ex_mem_to_reg;
                ex_mem_flag_write <= id_ex_flag_write;
                ex_mem_bulk_store <= id_ex_bulk_store;
                ex_mem_wa <= id_ex_wa;
                ex_mem_bulk_regmask <= id_ex_bulk_regmask;
                ex_mem_addr <= ex_alu_res;
                ex_mem_result <= ex_result;
                ex_mem_write_data <= ex_op2;
                ex_mem_bulk_data <= id_ex_bulk_data;
                ex_mem_flag_z <= ex_alu_z;
                ex_mem_flag_n <= ex_alu_n;

                if dec_illegal = '1' and if_id_valid = '1'
                    and not (id_ex_valid = '1' and id_ex_branch_taken = '1') then
                    illegal_reg <= '1';
                end if;

                if ex_halted = '1' then
                    stat_halt_events_reg <= stat_halt_events_reg + 1;
                    halted_reg <= '1';
                    halted_pc <= id_ex_pc;
                    halted_instr <= id_ex_instr;
                    fetch_pc <= id_ex_pc;
                    if_id_valid <= '0';
                    id_ex_valid <= '0';
                elsif id_ex_valid = '1' and id_ex_branch_taken = '1' then
                    stat_branch_flushes_reg <= stat_branch_flushes_reg + 1;
                    fetch_pc <= ex_branch_target;
                    if_id_valid <= '0';
                    if_id_pc <= (others => '0');
                    if_id_instr <= (others => '0');
                    id_ex_valid <= '0';
                elsif stall_id = '1' then
                    if stall_bulk_load = '1' then
                        stat_bulk_load_stalls_reg <= stat_bulk_load_stalls_reg + 1;
                    elsif stall_load_use = '1' then
                        stat_load_use_stalls_reg <= stat_load_use_stalls_reg + 1;
                    elsif stall_flag = '1' then
                        stat_flag_stalls_reg <= stat_flag_stalls_reg + 1;
                    end if;

                    id_ex_valid <= '0';
                    id_ex_pc <= (others => '0');
                    id_ex_instr <= (others => '0');
                    id_ex_reg_write <= '0';
                    id_ex_mem_read <= '0';
                    id_ex_mem_write <= '0';
                    id_ex_mem_to_reg <= '0';
                    id_ex_flag_write <= '0';
                    id_ex_branch_taken <= '0';
                    id_ex_bulk_store <= '0';
                    id_ex_bulk_writeback <= '0';
                else
                    if_id_valid <= '1';
                    if_id_pc <= fetch_pc;
                    if_id_instr <= fetch_instr;
                    fetch_pc <= std_logic_vector(unsigned(fetch_pc) + 4);

                    if if_id_valid = '1' and dec_illegal = '0' then
                        stat_issue_count_reg <= stat_issue_count_reg + 1;
                        issue_pc_i := to_integer(unsigned(if_id_pc(15 downto 0)));
                        if issue_pc_i <= 16#0010# then
                            stat_seg_prologue_reg <= stat_seg_prologue_reg + 1;
                        elsif issue_pc_i <= 16#00B0# then
                            stat_seg_input_load_reg <= stat_seg_input_load_reg + 1;
                        elsif issue_pc_i <= 16#00E0# then
                            stat_seg_stage1_reg <= stat_seg_stage1_reg + 1;
                        elsif issue_pc_i <= 16#0118# then
                            stat_seg_stage2_reg <= stat_seg_stage2_reg + 1;
                        elsif issue_pc_i = 16#0128# or issue_pc_i = 16#012C#
                            or issue_pc_i = 16#0130# or issue_pc_i = 16#0134#
                            or issue_pc_i = 16#0138# or issue_pc_i = 16#0158#
                            or issue_pc_i = 16#015C# or issue_pc_i = 16#0160#
                            or issue_pc_i = 16#0164# or issue_pc_i = 16#0168# then
                            stat_seg_twiddle_reg <= stat_seg_twiddle_reg + 1;
                        elsif issue_pc_i <= 16#0174# then
                            stat_seg_stage3_reg <= stat_seg_stage3_reg + 1;
                        elsif issue_pc_i <= 16#01A0# then
                            stat_seg_output_reg <= stat_seg_output_reg + 1;
                        else
                            stat_seg_done_reg <= stat_seg_done_reg + 1;
                        end if;
                    end if;

                    id_ex_valid <= if_id_valid and not dec_illegal;
                    id_ex_pc <= if_id_pc;
                    id_ex_instr <= if_id_instr;
                    id_ex_reg_write <= dec_reg_write and if_id_valid and not dec_illegal;
                    id_ex_mem_read <= dec_mem_read and if_id_valid and not dec_illegal;
                    id_ex_mem_write <= dec_mem_write and if_id_valid and not dec_illegal;
                    id_ex_mem_to_reg <= dec_mem_to_reg and if_id_valid and not dec_illegal;
                    id_ex_flag_write <= dec_flag_write and if_id_valid and not dec_illegal;
                    id_ex_branch_taken <= dec_branch_taken and if_id_valid and not dec_illegal;
                    id_ex_bulk_store <= dec_bulk_store and if_id_valid and not dec_illegal;
                    id_ex_bulk_writeback <= dec_bulk_writeback and if_id_valid and not dec_illegal;
                    id_ex_alu_control <= dec_alu_control;
                    id_ex_alu_src_imm <= dec_alu_src_imm;
                    id_ex_ra1 <= dec_ra1;
                    id_ex_ra2 <= dec_ra2;
                    id_ex_ra3 <= dec_ra3;
                    id_ex_wa <= dec_wa;
                    id_ex_bulk_regmask <= dec_bulk_regmask;
                    id_ex_imm_ext <= dec_imm_ext;
                    id_ex_branch_offset <= dec_branch_offset;
                    id_ex_op1 <= reg_rd1;
                    if mem_wb_valid = '1' and mem_wb_reg_write = '1' and same_reg(dec_ra1, mem_wb_wa) then
                        id_ex_op1 <= mem_wb_result;
                    end if;

                    id_ex_op2 <= reg_rd2;
                    if mem_wb_valid = '1' and mem_wb_reg_write = '1' and same_reg(dec_ra2, mem_wb_wa) then
                        id_ex_op2 <= mem_wb_result;
                    end if;

                    id_ex_op3 <= reg_rd3;
                    if mem_wb_valid = '1' and mem_wb_reg_write = '1' and same_reg(dec_ra3, mem_wb_wa) then
                        id_ex_op3 <= mem_wb_result;
                    end if;
                    id_ex_bulk_data <= id_bulk_data;
                end if;
            end if;
        end if;
    end process;

    pc_debug <= halted_pc when halted_reg = '1'
        else id_ex_pc when id_ex_valid = '1'
        else if_id_pc;
    instr_debug <= halted_instr when halted_reg = '1'
        else id_ex_instr when id_ex_valid = '1'
        else if_id_instr;
    halted_debug <= halted_reg or ex_halted;
    illegal_debug <= illegal_reg
        or (dec_illegal and if_id_valid and not (id_ex_valid and id_ex_branch_taken));
    flag_z_debug <= flag_z_reg;
    flag_n_debug <= flag_n_reg;
    stat_core_cycles <= std_logic_vector(stat_core_cycles_reg);
    stat_issue_count <= std_logic_vector(stat_issue_count_reg);
    stat_load_use_stalls <= std_logic_vector(stat_load_use_stalls_reg);
    stat_bulk_load_stalls <= std_logic_vector(stat_bulk_load_stalls_reg);
    stat_flag_stalls <= std_logic_vector(stat_flag_stalls_reg);
    stat_branch_flushes <= std_logic_vector(stat_branch_flushes_reg);
    stat_halt_events <= std_logic_vector(stat_halt_events_reg);
    stat_seg_prologue <= std_logic_vector(stat_seg_prologue_reg);
    stat_seg_input_load <= std_logic_vector(stat_seg_input_load_reg);
    stat_seg_stage1 <= std_logic_vector(stat_seg_stage1_reg);
    stat_seg_stage2 <= std_logic_vector(stat_seg_stage2_reg);
    stat_seg_stage3 <= std_logic_vector(stat_seg_stage3_reg);
    stat_seg_twiddle <= std_logic_vector(stat_seg_twiddle_reg);
    stat_seg_output <= std_logic_vector(stat_seg_output_reg);
    stat_seg_done <= std_logic_vector(stat_seg_done_reg);
end architecture rtl;
