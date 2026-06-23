library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.mcu4_multi_pkg.all;

entity mcu4_multicycle_core is
    port (
        clk           : in  std_logic;
        rst           : in  std_logic;

        input_we      : in  std_logic;
        input_waddr   : in  std_logic_vector(7 downto 0);
        input_wdata   : in  half_t;

        output_raddr  : in  std_logic_vector(5 downto 0);
        output_rdata  : out half_t;

        pc_debug      : out word_t;
        instr_debug   : out word_t;
        halted_debug  : out std_logic;
        illegal_debug : out std_logic;
        flag_z_debug  : out std_logic;
        flag_n_debug  : out std_logic
    );
end entity mcu4_multicycle_core;

architecture rtl of mcu4_multicycle_core is
    type state_t is (
        S_EXEC,
        S_HALT
    );

    signal state_reg : state_t := S_EXEC;
    signal pc_reg    : natural range 0 to 63 := 0;
    signal regs      : reg_file_t := (others => (others => '0'));
    signal flag_z    : std_logic := '0';
    signal flag_n    : std_logic := '0';
    signal halted    : std_logic := '0';
    signal illegal   : std_logic := '0';

    signal instr       : word_t := (others => '0');
    signal cond_ok     : std_logic;
    signal dec_illegal : std_logic;
    signal reg_write   : std_logic;
    signal mem_read    : std_logic;
    signal mem_write   : std_logic;
    signal mem_to_reg  : std_logic;
    signal flag_write  : std_logic;
    signal branch_taken : std_logic;
    signal branch_link  : std_logic;
    signal alu_control  : std_logic_vector(3 downto 0);
    signal alu_src_imm  : std_logic;
    signal ra1          : reg_addr_t;
    signal ra2          : reg_addr_t;
    signal wa           : reg_addr_t;
    signal imm_ext      : word_t;
    signal branch_offset : word_t;

    signal input_samples : sample16_array_t := (others => (others => '0'));
    signal buf_a         : complex8_array_t := (others => (others => '0'));
    signal buf_b         : complex8_array_t := (others => (others => '0'));

    signal lane_start     : std_logic_vector(3 downto 0) := (others => '0');
    signal lane_done      : std_logic_vector(3 downto 0);
    signal lane_busy      : std_logic_vector(3 downto 0);
    signal lane_done_seen : std_logic_vector(3 downto 0) := (others => '0');
    signal lane_a         : lane4_word_array_t := (others => (others => '0'));
    signal lane_b         : lane4_word_array_t := (others => (others => '0'));
    signal lane_even      : lane4_word_array_t;
    signal lane_odd       : lane4_word_array_t;
    signal lane_mode      : lane4_mode_array_t := (others => MODE_W0);

    function alu_eval(
        control : std_logic_vector(3 downto 0);
        a_value : word_t;
        b_value : word_t
    ) return word_t is
        variable res : word_t;
    begin
        case control is
            when ALU_AND =>
                res := a_value and b_value;
            when ALU_ORR =>
                res := a_value or b_value;
            when ALU_ADD =>
                res := std_logic_vector(signed(a_value) + signed(b_value));
            when ALU_SUB =>
                res := std_logic_vector(signed(a_value) - signed(b_value));
            when ALU_MOV =>
                res := b_value;
            when others =>
                res := a_value;
        end case;
        return res;
    end function;
begin
    u_rom : entity work.mcu4_instr_rom
        port map (
            pc_index => std_logic_vector(to_unsigned(pc_reg, 6)),
            instr    => instr
        );

    u_decoder : entity work.mcu4_decoder
        port map (
            instr         => instr,
            flag_z        => flag_z,
            flag_n        => flag_n,
            cond_ok       => cond_ok,
            illegal_instr => dec_illegal,
            reg_write     => reg_write,
            mem_read      => mem_read,
            mem_write     => mem_write,
            mem_to_reg    => mem_to_reg,
            flag_write    => flag_write,
            branch_taken  => branch_taken,
            branch_link   => branch_link,
            alu_control   => alu_control,
            alu_src_imm   => alu_src_imm,
            ra1           => ra1,
            ra2           => ra2,
            wa            => wa,
            imm_ext       => imm_ext,
            branch_offset => branch_offset
        );

    gen_lanes : for i in 0 to 3 generate
        u_lane : entity work.mcu4_butterfly_lane
            port map (
                clk          => clk,
                rst          => rst,
                start        => lane_start(i),
                twiddle_mode => lane_mode(i),
                a_in         => lane_a(i),
                b_in         => lane_b(i),
                even_out     => lane_even(i),
                odd_out      => lane_odd(i),
                done         => lane_done(i),
                busy         => lane_busy(i)
            );
    end generate;

    process(output_raddr, buf_b)
        variable idx : natural range 0 to 63;
    begin
        idx := to_integer(unsigned(output_raddr));
        if idx < 8 then
            output_rdata <= buf_b(idx)(15 downto 0);
        elsif idx < 16 then
            output_rdata <= buf_b(idx - 8)(31 downto 16);
        else
            output_rdata <= (others => '0');
        end if;
    end process;

    process(clk)
        variable slot : natural range 0 to 255;
        variable src_idx : natural range 0 to 7;
        variable next_done_seen : std_logic_vector(3 downto 0);
        variable rn_idx : natural range 0 to 15;
        variable rm_idx : natural range 0 to 15;
        variable rd_idx : natural range 0 to 15;
        variable op_a : word_t;
        variable op_b : word_t;
        variable alu_res : word_t;
        variable mem_idx : natural range 0 to 63;
        variable work_idx : natural range 0 to 7;
        variable stage_id : natural range 0 to 3;
        variable load_data : word_t;
        variable branch_words : integer;
        variable target_pc : integer;
    begin
        if rising_edge(clk) then
            slot := to_integer(unsigned(input_waddr));
            if input_we = '1' and slot < 16 then
                input_samples(slot) <= input_wdata;
                if slot >= 8 then
                    src_idx := slot - 8;
                    buf_a(BITREV_ORDER(src_idx)) <= pack_q5_to_q12(input_samples(src_idx), input_wdata);
                end if;
            end if;

            if rst = '1' then
                state_reg <= S_EXEC;
                pc_reg <= 0;
                regs <= (others => (others => '0'));
                flag_z <= '0';
                flag_n <= '0';
                halted <= '0';
                illegal <= '0';
                lane_start <= (others => '0');
                lane_done_seen <= (others => '0');
                lane_a <= (others => (others => '0'));
                lane_b <= (others => (others => '0'));
                lane_mode <= (others => MODE_W0);
            else
                lane_start <= (others => '0');

                case state_reg is
                    when S_EXEC =>
                        next_done_seen := lane_done_seen or lane_done;
                        lane_done_seen <= next_done_seen;
                        rn_idx := to_integer(unsigned(ra1));
                        rm_idx := to_integer(unsigned(ra2));
                        rd_idx := to_integer(unsigned(wa));
                        op_a := regs(rn_idx);
                        if alu_src_imm = '1' then
                            op_b := imm_ext;
                        else
                            op_b := regs(rm_idx);
                        end if;
                        alu_res := alu_eval(alu_control, op_a, op_b);

                        if dec_illegal = '1' then
                            illegal <= '1';
                            halted <= '1';
                            state_reg <= S_HALT;
                        elsif branch_taken = '1' then
                            branch_words := to_integer(signed(branch_offset(31 downto 2)));
                            target_pc := pc_reg + 2 + branch_words;
                            if branch_link = '1' then
                                regs(14) <= std_logic_vector(to_unsigned((pc_reg + 1) * 4, 32));
                            end if;
                            if target_pc < 0 or target_pc > 63 then
                                illegal <= '1';
                                halted <= '1';
                                state_reg <= S_HALT;
                            elsif target_pc = pc_reg then
                                halted <= '1';
                                state_reg <= S_HALT;
                            else
                                pc_reg <= target_pc;
                            end if;
                        else
                            if mem_write = '1' then
                                mem_idx := to_integer(unsigned(alu_res(7 downto 2)));
                                if mem_idx = MMIO_BFLY_STAGE0_START_WORD
                                   or mem_idx = MMIO_BFLY_STAGE1_START_WORD
                                   or mem_idx = MMIO_BFLY_STAGE2_START_WORD then
                                    if mem_idx = MMIO_BFLY_STAGE0_START_WORD then
                                        stage_id := 0;
                                    elsif mem_idx = MMIO_BFLY_STAGE1_START_WORD then
                                        stage_id := 1;
                                    else
                                        stage_id := 2;
                                    end if;

                                    lane_done_seen <= (others => '0');
                                    lane_start <= (others => '1');

                                    if stage_id = 0 then
                                        lane_a(0) <= buf_a(0);
                                        lane_b(0) <= buf_a(1);
                                        lane_mode(0) <= MODE_W0;
                                        lane_a(1) <= buf_a(2);
                                        lane_b(1) <= buf_a(3);
                                        lane_mode(1) <= MODE_W0;
                                        lane_a(2) <= buf_a(4);
                                        lane_b(2) <= buf_a(5);
                                        lane_mode(2) <= MODE_W0;
                                        lane_a(3) <= buf_a(6);
                                        lane_b(3) <= buf_a(7);
                                        lane_mode(3) <= MODE_W0;
                                    elsif stage_id = 1 then
                                        lane_a(0) <= buf_b(0);
                                        lane_b(0) <= buf_b(2);
                                        lane_mode(0) <= MODE_W0;
                                        lane_a(1) <= buf_b(1);
                                        lane_b(1) <= buf_b(3);
                                        lane_mode(1) <= MODE_W2;
                                        lane_a(2) <= buf_b(4);
                                        lane_b(2) <= buf_b(6);
                                        lane_mode(2) <= MODE_W0;
                                        lane_a(3) <= buf_b(5);
                                        lane_b(3) <= buf_b(7);
                                        lane_mode(3) <= MODE_W2;
                                    elsif stage_id = 2 then
                                        lane_a(0) <= buf_a(0);
                                        lane_b(0) <= buf_a(4);
                                        lane_mode(0) <= MODE_W0;
                                        lane_a(1) <= buf_a(1);
                                        lane_b(1) <= buf_a(5);
                                        lane_mode(1) <= MODE_W1;
                                        lane_a(2) <= buf_a(2);
                                        lane_b(2) <= buf_a(6);
                                        lane_mode(2) <= MODE_W2;
                                        lane_a(3) <= buf_a(3);
                                        lane_b(3) <= buf_a(7);
                                        lane_mode(3) <= MODE_W3;
                                    end if;
                                elsif mem_idx = MMIO_BFLY_STAGE0_COMMIT_WORD
                                      or mem_idx = MMIO_BFLY_STAGE1_COMMIT_WORD
                                      or mem_idx = MMIO_BFLY_STAGE2_COMMIT_WORD then
                                    if mem_idx = MMIO_BFLY_STAGE0_COMMIT_WORD then
                                        stage_id := 0;
                                    elsif mem_idx = MMIO_BFLY_STAGE1_COMMIT_WORD then
                                        stage_id := 1;
                                    else
                                        stage_id := 2;
                                    end if;

                                    if stage_id = 0 then
                                        buf_b(0) <= lane_even(0);
                                        buf_b(1) <= lane_odd(0);
                                        buf_b(2) <= lane_even(1);
                                        buf_b(3) <= lane_odd(1);
                                        buf_b(4) <= lane_even(2);
                                        buf_b(5) <= lane_odd(2);
                                        buf_b(6) <= lane_even(3);
                                        buf_b(7) <= lane_odd(3);
                                    elsif stage_id = 1 then
                                        buf_a(0) <= lane_even(0);
                                        buf_a(2) <= lane_odd(0);
                                        buf_a(1) <= lane_even(1);
                                        buf_a(3) <= lane_odd(1);
                                        buf_a(4) <= lane_even(2);
                                        buf_a(6) <= lane_odd(2);
                                        buf_a(5) <= lane_even(3);
                                        buf_a(7) <= lane_odd(3);
                                    else
                                        buf_b(0) <= lane_even(0);
                                        buf_b(4) <= lane_odd(0);
                                        buf_b(1) <= lane_even(1);
                                        buf_b(5) <= lane_odd(1);
                                        buf_b(2) <= lane_even(2);
                                        buf_b(6) <= lane_odd(2);
                                        buf_b(3) <= lane_even(3);
                                        buf_b(7) <= lane_odd(3);
                                    end if;
                                elsif mem_idx >= WORK_BUF_A_BASE_WORD
                                      and mem_idx < WORK_BUF_A_BASE_WORD + WORK_BUF_WORDS then
                                    work_idx := mem_idx - WORK_BUF_A_BASE_WORD;
                                    buf_a(work_idx) <= regs(rd_idx);
                                elsif mem_idx >= WORK_BUF_B_BASE_WORD
                                      and mem_idx < WORK_BUF_B_BASE_WORD + WORK_BUF_WORDS then
                                    work_idx := mem_idx - WORK_BUF_B_BASE_WORD;
                                    buf_b(work_idx) <= regs(rd_idx);
                                end if;
                            end if;

                            if reg_write = '1' then
                                if rd_idx = 15 then
                                    if to_integer(unsigned(alu_res(7 downto 2))) <= 63 then
                                        pc_reg <= to_integer(unsigned(alu_res(7 downto 2)));
                                    else
                                        illegal <= '1';
                                        halted <= '1';
                                        state_reg <= S_HALT;
                                    end if;
                                else
                                    if mem_read = '1' and mem_to_reg = '1' then
                                        mem_idx := to_integer(unsigned(alu_res(7 downto 2)));
                                        if mem_idx = MMIO_BFLY_STATUS_WORD then
                                            load_data := (others => '0');
                                            load_data(3 downto 0) := next_done_seen;
                                        elsif mem_idx >= WORK_BUF_A_BASE_WORD
                                              and mem_idx < WORK_BUF_A_BASE_WORD + WORK_BUF_WORDS then
                                            work_idx := mem_idx - WORK_BUF_A_BASE_WORD;
                                            load_data := buf_a(work_idx);
                                        elsif mem_idx >= WORK_BUF_B_BASE_WORD
                                              and mem_idx < WORK_BUF_B_BASE_WORD + WORK_BUF_WORDS then
                                            work_idx := mem_idx - WORK_BUF_B_BASE_WORD;
                                            load_data := buf_b(work_idx);
                                        else
                                            load_data := (others => '0');
                                        end if;
                                        regs(rd_idx) <= load_data;
                                        alu_res := load_data;
                                    else
                                        regs(rd_idx) <= alu_res;
                                    end if;
                                end if;
                            end if;

                            if flag_write = '1' then
                                if alu_res = x"00000000" then
                                    flag_z <= '1';
                                else
                                    flag_z <= '0';
                                end if;
                                flag_n <= alu_res(31);
                            end if;

                            if not (reg_write = '1' and rd_idx = 15) then
                                pc_reg <= pc_reg + 1;
                            end if;
                        end if;
                    when S_HALT =>
                        halted <= '1';
                        state_reg <= S_HALT;
                end case;
            end if;
        end if;
    end process;

    pc_debug <= std_logic_vector(to_unsigned(pc_reg * 4, 32));
    instr_debug <= instr;
    halted_debug <= halted;
    illegal_debug <= illegal;
    flag_z_debug <= flag_z;
    flag_n_debug <= flag_n;
end architecture rtl;
