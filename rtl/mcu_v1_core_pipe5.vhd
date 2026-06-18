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
        flag_n_debug  : out std_logic
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

    signal stall_id : std_logic := '0';
    signal halted_reg : std_logic := '0';
    signal halted_pc : std_logic_vector(31 downto 0) := (others => '0');
    signal halted_instr : std_logic_vector(31 downto 0) := (others => '0');

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

    process(if_id_valid, dec_ra1, dec_ra2, dec_ra3, dec_bulk_store, dec_bulk_regmask,
            if_id_instr, id_ex_valid, id_ex_reg_write, id_ex_mem_to_reg, id_ex_flag_write,
            id_ex_wa, ex_mem_valid, ex_mem_reg_write, ex_mem_flag_write, ex_mem_wa,
            mem_wb_valid, mem_wb_reg_write, mem_wb_flag_write, mem_wb_wa)
    begin
        stall_id <= '0';
        if if_id_valid = '1' then
            if id_ex_valid = '1' and id_ex_mem_to_reg = '1' and id_ex_reg_write = '1'
                and (same_reg(dec_ra1, id_ex_wa) or same_reg(dec_ra2, id_ex_wa) or same_reg(dec_ra3, id_ex_wa)) then
                stall_id <= '1';
            end if;

            if dec_bulk_store = '1' then
                if id_ex_valid = '1' and id_ex_reg_write = '1' and reg_in_mask(dec_bulk_regmask, id_ex_wa) then
                    stall_id <= '1';
                elsif ex_mem_valid = '1' and ex_mem_reg_write = '1' and reg_in_mask(dec_bulk_regmask, ex_mem_wa) then
                    stall_id <= '1';
                elsif mem_wb_valid = '1' and mem_wb_reg_write = '1' and reg_in_mask(dec_bulk_regmask, mem_wb_wa) then
                    stall_id <= '1';
                end if;
            end if;

            if if_id_instr(31 downto 28) /= "1110"
                and ((id_ex_valid = '1' and id_ex_flag_write = '1')
                    or (ex_mem_valid = '1' and ex_mem_flag_write = '1')
                    or (mem_wb_valid = '1' and mem_wb_flag_write = '1')) then
                stall_id <= '1';
            end if;
        end if;
    end process;

    process(clk)
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
            elsif halted_reg = '0' then
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
                    halted_reg <= '1';
                    halted_pc <= id_ex_pc;
                    halted_instr <= id_ex_instr;
                    fetch_pc <= id_ex_pc;
                    if_id_valid <= '0';
                    id_ex_valid <= '0';
                elsif id_ex_valid = '1' and id_ex_branch_taken = '1' then
                    fetch_pc <= ex_branch_target;
                    if_id_valid <= '0';
                    if_id_pc <= (others => '0');
                    if_id_instr <= (others => '0');
                    id_ex_valid <= '0';
                elsif stall_id = '1' then
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
                    id_ex_bulk_data <= reg_bulk_rd;
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
end architecture rtl;
