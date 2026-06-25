library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.mcu4_multi_pkg.all;

entity mcu4_worker_core is
    generic (
        WORKER_ID  : natural range 0 to 3 := 0;
        PROGRAM_ID : natural range 0 to 1 := 0
    );
    port (
        clk : in std_logic;
        rst : in std_logic;

        buf_a_raddr : out std_logic_vector(2 downto 0);
        buf_a_rdata : in  word_t;
        buf_a_raddr2 : out std_logic_vector(2 downto 0);
        buf_a_rdata2 : in  word_t;
        buf_b_raddr : out std_logic_vector(2 downto 0);
        buf_b_rdata : in  word_t;
        buf_b_raddr2 : out std_logic_vector(2 downto 0);
        buf_b_rdata2 : in  word_t;

        buf_a_we    : out std_logic;
        buf_a_waddr : out std_logic_vector(2 downto 0);
        buf_a_wdata : out word_t;
        buf_a_we2    : out std_logic;
        buf_a_waddr2 : out std_logic_vector(2 downto 0);
        buf_a_wdata2 : out word_t;
        buf_b_we    : out std_logic;
        buf_b_waddr : out std_logic_vector(2 downto 0);
        buf_b_wdata : out word_t;
        buf_b_we2    : out std_logic;
        buf_b_waddr2 : out std_logic_vector(2 downto 0);
        buf_b_wdata2 : out word_t;

        halted      : out std_logic;
        illegal     : out std_logic;
        pc_debug    : out word_t;
        instr_debug : out word_t
    );
end entity mcu4_worker_core;

architecture rtl of mcu4_worker_core is
    type worker_state_t is (
        S_FETCH,
        S_DECODE,
        S_RUN,
        S_DSP_MUL,
        S_DSP_ACC,
        S_DSP_WB,
        S_DSP_PAIR_MUL_ACC,
        S_DSP_PAIR_WB_ACC,
        S_DSP_PAIR_WB
    );

    type worker_pair_t is (
        WPAIR_NONE,
        WPAIR_MOV_IMM,
        WPAIR_LDR_A,
        WPAIR_LDR_B,
        WPAIR_STR_A,
        WPAIR_STR_B,
        WPAIR_SADD16_SSUB16
    );

    signal state_reg    : worker_state_t := S_FETCH;
    signal pc_fetch_reg : natural range 0 to 63 := 0;
    signal pc_index     : std_logic_vector(5 downto 0) := (others => '0');
    signal pc_pair_index : std_logic_vector(5 downto 0) := (others => '0');
    signal instr_reg    : word_t := x"E1A00000";
    signal instr_pc_reg : natural range 0 to 63 := 0;
    signal regs        : reg_file_t := (others => (others => '0'));
    signal halted_reg  : std_logic := '0';
    signal illegal_reg : std_logic := '0';

    signal instr_word  : word_t := (others => '0');
    signal fetch_dec_op      : worker_op_t := WOP_NOP;
    signal fetch_dec_rd      : natural range 0 to 15 := 0;
    signal fetch_dec_rn      : natural range 0 to 15 := 0;
    signal fetch_dec_rm      : natural range 0 to 15 := 0;
    signal fetch_dec_imm     : integer range -4096 to 4095 := 0;
    signal fetch_dec_idx     : natural range 0 to 7 := 0;
    signal fetch_dec_illegal : std_logic := '0';
    signal instr_pair_word  : word_t := (others => '0');
    signal fetch_pair_dec_op      : worker_op_t := WOP_NOP;
    signal fetch_pair_dec_rd      : natural range 0 to 15 := 0;
    signal fetch_pair_dec_rn      : natural range 0 to 15 := 0;
    signal fetch_pair_dec_rm      : natural range 0 to 15 := 0;
    signal fetch_pair_dec_imm     : integer range -4096 to 4095 := 0;
    signal fetch_pair_dec_idx     : natural range 0 to 7 := 0;
    signal fetch_pair_dec_illegal : std_logic := '0';

    signal dec_op      : worker_op_t := WOP_NOP;
    signal dec_rd      : natural range 0 to 15 := 0;
    signal dec_rn      : natural range 0 to 15 := 0;
    signal dec_rm      : natural range 0 to 15 := 0;
    signal dec_imm     : integer range -4096 to 4095 := 0;
    signal dec_idx     : natural range 0 to 7 := 0;
    signal dec_illegal : std_logic := '0';
    signal dec_rd_data : word_t := (others => '0');

    signal exec_op      : worker_op_t := WOP_NOP;
    signal exec_rd      : natural range 0 to 15 := 0;
    signal exec_rn      : natural range 0 to 15 := 0;
    signal exec_rm      : natural range 0 to 15 := 0;
    signal exec_imm     : integer range -4096 to 4095 := 0;
    signal exec_idx     : natural range 0 to 7 := 0;
    signal exec_illegal : std_logic := '0';
    signal exec_instr   : word_t := x"E1A00000";
    signal exec_pc_reg  : natural range 0 to 63 := 0;
    signal exec_rn_data : word_t := (others => '0');
    signal exec_rm_data : word_t := (others => '0');
    signal exec_rd_data : word_t := (others => '0');
    signal exec_dsp_a    : word_t := (others => '0');
    signal exec_dsp_b    : word_t := (others => '0');
    signal exec_pair_kind : worker_pair_t := WPAIR_NONE;

    signal dsp_a         : word_t := (others => '0');
    signal dsp_b         : word_t := (others => '0');
    signal dsp_prod_lo   : signed(31 downto 0) := (others => '0');
    signal dsp_prod_hi   : signed(31 downto 0) := (others => '0');
    signal dsp_sum       : word_t := (others => '0');
    signal dsp_diff      : word_t := (others => '0');
    signal dsp_rd        : natural range 0 to 15 := 0;
    signal dsp_sub       : std_logic := '0';
    signal dsp_sub_acc   : std_logic := '0';
    signal dsp_pc_reg    : natural range 0 to 63 := 0;
    signal dsp_instr_reg : word_t := x"E1A00000";
    signal dsp2_a         : word_t := (others => '0');
    signal dsp2_b         : word_t := (others => '0');
    signal dsp2_prod_lo   : signed(31 downto 0) := (others => '0');
    signal dsp2_prod_hi   : signed(31 downto 0) := (others => '0');
    signal dsp2_sum       : word_t := (others => '0');
    signal dsp2_diff      : word_t := (others => '0');
    signal dsp2_rd        : natural range 0 to 15 := 0;
    signal dsp2_sub       : std_logic := '0';
    signal dsp2_sub_acc   : std_logic := '0';
    signal dsp_pair_ready : std_logic := '0';
    signal dsp_pair_asr_valid  : std_logic := '0';
    signal dsp_pair_asr_result : word_t := (others => '0');

    attribute keep : string;
    attribute dont_touch : string;
    attribute use_dsp : string;
    attribute keep of dsp_sub : signal is "true";
    attribute keep of dsp_sub_acc : signal is "true";
    attribute keep of dsp2_sub : signal is "true";
    attribute keep of dsp2_sub_acc : signal is "true";
    attribute keep of exec_dsp_a : signal is "true";
    attribute keep of exec_dsp_b : signal is "true";
    attribute dont_touch of dsp_sub : signal is "true";
    attribute dont_touch of dsp_sub_acc : signal is "true";
    attribute dont_touch of dsp2_sub : signal is "true";
    attribute dont_touch of dsp2_sub_acc : signal is "true";
    attribute dont_touch of exec_dsp_a : signal is "true";
    attribute dont_touch of exec_dsp_b : signal is "true";
    attribute use_dsp of dsp_sum : signal is "no";
    attribute use_dsp of dsp_diff : signal is "no";
    attribute use_dsp of dsp2_sum : signal is "no";
    attribute use_dsp of dsp2_diff : signal is "no";

    function sadd16(a : word_t; b : word_t) return word_t is
        variable a_lo17 : signed(16 downto 0);
        variable a_hi17 : signed(16 downto 0);
        variable b_lo17 : signed(16 downto 0);
        variable b_hi17 : signed(16 downto 0);
        variable lo17   : signed(16 downto 0);
        variable hi17   : signed(16 downto 0);
    begin
        a_lo17 := resize(signed(a(15 downto 0)), 17);
        a_hi17 := resize(signed(a(31 downto 16)), 17);
        b_lo17 := resize(signed(b(15 downto 0)), 17);
        b_hi17 := resize(signed(b(31 downto 16)), 17);
        lo17 := a_lo17 + b_lo17;
        hi17 := a_hi17 + b_hi17;
        return std_logic_vector(hi17(15 downto 0)) & std_logic_vector(lo17(15 downto 0));
    end function;

    function ssub16(a : word_t; b : word_t) return word_t is
        variable a_lo17 : signed(16 downto 0);
        variable a_hi17 : signed(16 downto 0);
        variable b_lo17 : signed(16 downto 0);
        variable b_hi17 : signed(16 downto 0);
        variable lo17   : signed(16 downto 0);
        variable hi17   : signed(16 downto 0);
    begin
        a_lo17 := resize(signed(a(15 downto 0)), 17);
        a_hi17 := resize(signed(a(31 downto 16)), 17);
        b_lo17 := resize(signed(b(15 downto 0)), 17);
        b_hi17 := resize(signed(b(31 downto 16)), 17);
        lo17 := a_lo17 - b_lo17;
        hi17 := a_hi17 - b_hi17;
        return std_logic_vector(hi17(15 downto 0)) & std_logic_vector(lo17(15 downto 0));
    end function;

    function ssax(a : word_t; b : word_t) return word_t is
        variable a_lo17 : signed(16 downto 0);
        variable a_hi17 : signed(16 downto 0);
        variable b_lo17 : signed(16 downto 0);
        variable b_hi17 : signed(16 downto 0);
        variable lo17   : signed(16 downto 0);
        variable hi17   : signed(16 downto 0);
    begin
        a_lo17 := resize(signed(a(15 downto 0)), 17);
        a_hi17 := resize(signed(a(31 downto 16)), 17);
        b_lo17 := resize(signed(b(15 downto 0)), 17);
        b_hi17 := resize(signed(b(31 downto 16)), 17);
        lo17 := a_lo17 + b_hi17;
        hi17 := a_hi17 - b_lo17;
        return std_logic_vector(hi17(15 downto 0)) & std_logic_vector(lo17(15 downto 0));
    end function;

    function is_dsp_op(op_value : worker_op_t) return boolean is
    begin
        return op_value = WOP_SMUAD or op_value = WOP_SMUSD;
    end function;

    function clamp_pc(value : integer) return natural is
    begin
        if value < 0 then
            return 0;
        elsif value > 63 then
            return 63;
        end if;
        return value;
    end function;

    function next_seq_pc(value : natural) return natural is
    begin
        if value < 63 then
            return value + 1;
        end if;
        return 63;
    end function;

    function next_pair_pc(value : natural) return natural is
    begin
        if value < 62 then
            return value + 2;
        end if;
        return 63;
    end function;

    function word_to_pc(value : word_t) return natural is
        variable idx : natural range 0 to 63 := 0;
    begin
        for bit_pos in 2 to 7 loop
            if value(bit_pos) = '1' then
                idx := idx + (2 ** (bit_pos - 2));
            end if;
        end loop;
        return idx;
    end function;

    function calc_pair_kind(
        constant op_a      : worker_op_t;
        constant rd_a      : natural range 0 to 15;
        constant rn_a      : natural range 0 to 15;
        constant rm_a      : natural range 0 to 15;
        constant idx_a     : natural range 0 to 7;
        constant illegal_a : std_logic;
        constant op_b      : worker_op_t;
        constant rd_b      : natural range 0 to 15;
        constant rn_b      : natural range 0 to 15;
        constant rm_b      : natural range 0 to 15;
        constant idx_b     : natural range 0 to 7;
        constant illegal_b : std_logic
    ) return worker_pair_t is
    begin
        if illegal_a = '1' or illegal_b = '1' then
            return WPAIR_NONE;
        elsif op_a = WOP_MOV_IMM
              and op_b = WOP_MOV_IMM
              and rd_a /= rd_b then
            return WPAIR_MOV_IMM;
        elsif op_a = WOP_LDR_A
              and op_b = WOP_LDR_A
              and rd_a /= rd_b then
            return WPAIR_LDR_A;
        elsif op_a = WOP_LDR_B
              and op_b = WOP_LDR_B
              and rd_a /= rd_b then
            return WPAIR_LDR_B;
        elsif op_a = WOP_STR_A
              and op_b = WOP_STR_A
              and idx_a /= idx_b then
            return WPAIR_STR_A;
        elsif op_a = WOP_STR_B
              and op_b = WOP_STR_B
              and idx_a /= idx_b then
            return WPAIR_STR_B;
        elsif op_a = WOP_SADD16
              and op_b = WOP_SSUB16
              and rn_a = rn_b
              and rm_a = rm_b
              and rd_a /= rd_b then
            return WPAIR_SADD16_SSUB16;
        end if;

        return WPAIR_NONE;
    end function;
begin
    pc_index <= std_logic_vector(to_unsigned(pc_fetch_reg, 6));
    pc_pair_index <= std_logic_vector(to_unsigned(next_seq_pc(pc_fetch_reg), 6));

    u_instr_rom : entity work.mcu4_worker_instr_rom
        generic map (
            WORKER_ID  => WORKER_ID,
            PROGRAM_ID => PROGRAM_ID
        )
        port map (
            pc_index => pc_index,
            instr    => instr_word
        );

    u_decoder : entity work.mcu4_worker_decoder
        port map (
            instr_word => instr_word,
            pc_index   => pc_index,
            op         => fetch_dec_op,
            rd         => fetch_dec_rd,
            rn         => fetch_dec_rn,
            rm         => fetch_dec_rm,
            imm        => fetch_dec_imm,
            idx        => fetch_dec_idx,
            illegal    => fetch_dec_illegal
        );

    u_instr_pair_rom : entity work.mcu4_worker_instr_rom
        generic map (
            WORKER_ID  => WORKER_ID,
            PROGRAM_ID => PROGRAM_ID
        )
        port map (
            pc_index => pc_pair_index,
            instr    => instr_pair_word
        );

    u_pair_decoder : entity work.mcu4_worker_decoder
        port map (
            instr_word => instr_pair_word,
            pc_index   => pc_pair_index,
            op         => fetch_pair_dec_op,
            rd         => fetch_pair_dec_rd,
            rn         => fetch_pair_dec_rn,
            rm         => fetch_pair_dec_rm,
            imm        => fetch_pair_dec_imm,
            idx        => fetch_pair_dec_idx,
            illegal    => fetch_pair_dec_illegal
        );

    buf_a_raddr <= std_logic_vector(to_unsigned(exec_idx, 3))
        when state_reg = S_RUN and (exec_op = WOP_LDR_A or exec_op = WOP_STR_A)
        else (others => '0');
    buf_a_raddr2 <= std_logic_vector(to_unsigned(dec_idx, 3))
        when state_reg = S_RUN and exec_pair_kind = WPAIR_LDR_A
        else (others => '0');
    buf_b_raddr <= std_logic_vector(to_unsigned(exec_idx, 3))
        when state_reg = S_RUN and (exec_op = WOP_LDR_B or exec_op = WOP_STR_B)
        else (others => '0');
    buf_b_raddr2 <= std_logic_vector(to_unsigned(dec_idx, 3))
        when state_reg = S_RUN and exec_pair_kind = WPAIR_LDR_B
        else (others => '0');

    buf_a_we <= '1' when halted_reg = '0'
                         and illegal_reg = '0'
                         and state_reg = S_RUN
                         and exec_illegal = '0'
                         and exec_op = WOP_STR_A
                else '0';
    buf_a_waddr <= std_logic_vector(to_unsigned(exec_idx, 3));
    buf_a_wdata <= exec_rd_data;
    buf_a_we2 <= '1' when halted_reg = '0'
                          and illegal_reg = '0'
                          and state_reg = S_RUN
                          and exec_illegal = '0'
                          and exec_pair_kind = WPAIR_STR_A
                 else '0';
    buf_a_waddr2 <= std_logic_vector(to_unsigned(dec_idx, 3));
    buf_a_wdata2 <= dec_rd_data;

    buf_b_we <= '1' when halted_reg = '0'
                         and illegal_reg = '0'
                         and state_reg = S_RUN
                         and exec_illegal = '0'
                         and exec_op = WOP_STR_B
                else '0';
    buf_b_waddr <= std_logic_vector(to_unsigned(exec_idx, 3));
    buf_b_wdata <= exec_rd_data;
    buf_b_we2 <= '1' when halted_reg = '0'
                          and illegal_reg = '0'
                          and state_reg = S_RUN
                          and exec_illegal = '0'
                          and exec_pair_kind = WPAIR_STR_B
                 else '0';
    buf_b_waddr2 <= std_logic_vector(to_unsigned(dec_idx, 3));
    buf_b_wdata2 <= dec_rd_data;

    process(clk)
        variable res : word_t;
        variable branch_taken : boolean;
        variable branch_target : natural range 0 to 63;
        variable start_dsp : boolean;
        variable wb_valid : boolean;
        variable wb_rd : natural range 0 to 15;
        variable wb_data : word_t;
        variable wb2_valid : boolean;
        variable wb2_rd : natural range 0 to 15;
        variable wb2_data : word_t;
        variable pair_valid : boolean;

        impure function forwarded_reg_value(
            constant reg_idx         : natural range 0 to 15;
            constant forward_a_valid : boolean;
            constant forward_a_rd    : natural range 0 to 15;
            constant forward_a_data  : word_t;
            constant forward_b_valid : boolean;
            constant forward_b_rd    : natural range 0 to 15;
            constant forward_b_data  : word_t
        ) return word_t is
            variable value : word_t;
        begin
            value := regs(reg_idx);

            if forward_a_valid and forward_a_rd = reg_idx then
                value := forward_a_data;
            end if;

            if forward_b_valid and forward_b_rd = reg_idx then
                value := forward_b_data;
            end if;

            return value;
        end function;

        procedure load_exec_from_decode(
            constant forward_valid : in boolean;
            constant forward_rd    : in natural range 0 to 15;
            constant forward_data  : in word_t
        ) is
            variable rn_value : word_t;
            variable rm_value : word_t;
            variable rd_value : word_t;
        begin
            rn_value := regs(dec_rn);
            rm_value := regs(dec_rm);
            rd_value := regs(dec_rd);

            if forward_valid then
                if forward_rd = dec_rn then
                    rn_value := forward_data;
                end if;
                if forward_rd = dec_rm then
                    rm_value := forward_data;
                end if;
                if forward_rd = dec_rd then
                    rd_value := forward_data;
                end if;
            end if;

            exec_op <= dec_op;
            exec_rd <= dec_rd;
            exec_rn <= dec_rn;
            exec_rm <= dec_rm;
            exec_imm <= dec_imm;
            exec_idx <= dec_idx;
            exec_illegal <= dec_illegal;
            exec_instr <= instr_reg;
            exec_pc_reg <= instr_pc_reg;
            exec_rn_data <= rn_value;
            exec_rm_data <= rm_value;
            exec_rd_data <= rd_value;
            exec_dsp_a <= rn_value;
            exec_dsp_b <= rm_value;
        end procedure;

        procedure load_exec_from_decode_dual(
            constant forward_a_valid : in boolean;
            constant forward_a_rd    : in natural range 0 to 15;
            constant forward_a_data  : in word_t;
            constant forward_b_valid : in boolean;
            constant forward_b_rd    : in natural range 0 to 15;
            constant forward_b_data  : in word_t
        ) is
            variable rn_value : word_t;
            variable rm_value : word_t;
            variable rd_value : word_t;
        begin
            rn_value := regs(dec_rn);
            rm_value := regs(dec_rm);
            rd_value := regs(dec_rd);

            if forward_a_valid then
                if forward_a_rd = dec_rn then
                    rn_value := forward_a_data;
                end if;
                if forward_a_rd = dec_rm then
                    rm_value := forward_a_data;
                end if;
                if forward_a_rd = dec_rd then
                    rd_value := forward_a_data;
                end if;
            end if;

            if forward_b_valid then
                if forward_b_rd = dec_rn then
                    rn_value := forward_b_data;
                end if;
                if forward_b_rd = dec_rm then
                    rm_value := forward_b_data;
                end if;
                if forward_b_rd = dec_rd then
                    rd_value := forward_b_data;
                end if;
            end if;

            exec_op <= dec_op;
            exec_rd <= dec_rd;
            exec_rn <= dec_rn;
            exec_rm <= dec_rm;
            exec_imm <= dec_imm;
            exec_idx <= dec_idx;
            exec_illegal <= dec_illegal;
            exec_instr <= instr_reg;
            exec_pc_reg <= instr_pc_reg;
            exec_rn_data <= rn_value;
            exec_rm_data <= rm_value;
            exec_rd_data <= rd_value;
            exec_dsp_a <= rn_value;
            exec_dsp_b <= rm_value;
        end procedure;

        procedure load_exec_from_fetch_dual(
            constant forward_a_valid : in boolean;
            constant forward_a_rd    : in natural range 0 to 15;
            constant forward_a_data  : in word_t;
            constant forward_b_valid : in boolean;
            constant forward_b_rd    : in natural range 0 to 15;
            constant forward_b_data  : in word_t
        ) is
            variable rn_value : word_t;
            variable rm_value : word_t;
            variable rd_value : word_t;
        begin
            rn_value := regs(fetch_dec_rn);
            rm_value := regs(fetch_dec_rm);
            rd_value := regs(fetch_dec_rd);

            if forward_a_valid then
                if forward_a_rd = fetch_dec_rn then
                    rn_value := forward_a_data;
                end if;
                if forward_a_rd = fetch_dec_rm then
                    rm_value := forward_a_data;
                end if;
                if forward_a_rd = fetch_dec_rd then
                    rd_value := forward_a_data;
                end if;
            end if;

            if forward_b_valid then
                if forward_b_rd = fetch_dec_rn then
                    rn_value := forward_b_data;
                end if;
                if forward_b_rd = fetch_dec_rm then
                    rm_value := forward_b_data;
                end if;
                if forward_b_rd = fetch_dec_rd then
                    rd_value := forward_b_data;
                end if;
            end if;

            exec_op <= fetch_dec_op;
            exec_rd <= fetch_dec_rd;
            exec_rn <= fetch_dec_rn;
            exec_rm <= fetch_dec_rm;
            exec_imm <= fetch_dec_imm;
            exec_idx <= fetch_dec_idx;
            exec_illegal <= fetch_dec_illegal;
            exec_instr <= instr_word;
            exec_pc_reg <= pc_fetch_reg;
            exec_rn_data <= rn_value;
            exec_rm_data <= rm_value;
            exec_rd_data <= rd_value;
            exec_dsp_a <= rn_value;
            exec_dsp_b <= rm_value;

            instr_reg <= instr_pair_word;
            instr_pc_reg <= next_seq_pc(pc_fetch_reg);
            dec_op <= fetch_pair_dec_op;
            dec_rd <= fetch_pair_dec_rd;
            dec_rn <= fetch_pair_dec_rn;
            dec_rm <= fetch_pair_dec_rm;
            dec_imm <= fetch_pair_dec_imm;
            dec_idx <= fetch_pair_dec_idx;
            dec_illegal <= fetch_pair_dec_illegal;
            dec_rd_data <= forwarded_reg_value(
                fetch_pair_dec_rd,
                forward_a_valid, forward_a_rd, forward_a_data,
                forward_b_valid, forward_b_rd, forward_b_data
            );
            exec_pair_kind <= calc_pair_kind(
                fetch_dec_op,
                fetch_dec_rd,
                fetch_dec_rn,
                fetch_dec_rm,
                fetch_dec_idx,
                fetch_dec_illegal,
                fetch_pair_dec_op,
                fetch_pair_dec_rd,
                fetch_pair_dec_rn,
                fetch_pair_dec_rm,
                fetch_pair_dec_idx,
                fetch_pair_dec_illegal
            );
            pc_fetch_reg <= next_pair_pc(pc_fetch_reg);
        end procedure;

        procedure refresh_exec_operands(
            constant forward_valid : in boolean;
            constant forward_rd    : in natural range 0 to 15;
            constant forward_data  : in word_t
        ) is
            variable rn_value : word_t;
            variable rm_value : word_t;
            variable rd_value : word_t;
        begin
            rn_value := regs(exec_rn);
            rm_value := regs(exec_rm);
            rd_value := regs(exec_rd);

            if forward_valid then
                if forward_rd = exec_rn then
                    rn_value := forward_data;
                end if;
                if forward_rd = exec_rm then
                    rm_value := forward_data;
                end if;
                if forward_rd = exec_rd then
                    rd_value := forward_data;
                end if;
            end if;

            exec_rn_data <= rn_value;
            exec_rm_data <= rm_value;
            exec_rd_data <= rd_value;
            exec_dsp_a <= rn_value;
            exec_dsp_b <= rm_value;
        end procedure;

        procedure fetch_into_decode(
            constant forward_a_valid : in boolean;
            constant forward_a_rd    : in natural range 0 to 15;
            constant forward_a_data  : in word_t;
            constant forward_b_valid : in boolean;
            constant forward_b_rd    : in natural range 0 to 15;
            constant forward_b_data  : in word_t
        ) is
        begin
            instr_reg <= instr_word;
            instr_pc_reg <= pc_fetch_reg;
            dec_op <= fetch_dec_op;
            dec_rd <= fetch_dec_rd;
            dec_rn <= fetch_dec_rn;
            dec_rm <= fetch_dec_rm;
            dec_imm <= fetch_dec_imm;
            dec_idx <= fetch_dec_idx;
            dec_illegal <= fetch_dec_illegal;
            dec_rd_data <= forwarded_reg_value(
                fetch_dec_rd,
                forward_a_valid, forward_a_rd, forward_a_data,
                forward_b_valid, forward_b_rd, forward_b_data
            );
            exec_pair_kind <= calc_pair_kind(
                dec_op,
                dec_rd,
                dec_rn,
                dec_rm,
                dec_idx,
                dec_illegal,
                fetch_dec_op,
                fetch_dec_rd,
                fetch_dec_rn,
                fetch_dec_rm,
                fetch_dec_idx,
                fetch_dec_illegal
            );
            pc_fetch_reg <= next_seq_pc(pc_fetch_reg);
        end procedure;
    begin
        if rising_edge(clk) then
            wb_valid := false;
            wb_rd := 0;
            wb_data := (others => '0');
            wb2_valid := false;
            wb2_rd := 0;
            wb2_data := (others => '0');
            pair_valid := false;

            if rst = '1' then
                state_reg <= S_FETCH;
                pc_fetch_reg <= 0;
                halted_reg <= '0';
                illegal_reg <= '0';
                exec_pair_kind <= WPAIR_NONE;
                dsp_pair_ready <= '0';
                -- Data-path registers are overwritten by fetch/decode or by
                -- the program prologue before use. Leaving them out of reset
                -- keeps the core reset fanout small enough for higher clocks.
            elsif halted_reg = '0' and illegal_reg = '0' then
                case state_reg is
                    when S_FETCH =>
                        fetch_into_decode(
                            false, 0, (others => '0'),
                            false, 0, (others => '0')
                        );
                        state_reg <= S_DECODE;

                    when S_DECODE =>
                        load_exec_from_decode(false, 0, (others => '0'));
                        fetch_into_decode(
                            false, 0, (others => '0'),
                            false, 0, (others => '0')
                        );
                        state_reg <= S_RUN;

                    when S_RUN =>
                        if exec_illegal = '1' then
                            illegal_reg <= '1';
                            halted_reg <= '1';
                        else
                            branch_taken := false;
                            branch_target := 0;
                            start_dsp := false;

                            case exec_pair_kind is
                                when WPAIR_MOV_IMM =>
                                    pair_valid := true;
                                    wb_valid := true;
                                    wb_rd := exec_rd;
                                    wb_data := std_logic_vector(to_signed(exec_imm, 32));
                                    wb2_valid := true;
                                    wb2_rd := dec_rd;
                                    wb2_data := std_logic_vector(to_signed(dec_imm, 32));
                                when WPAIR_LDR_A =>
                                    pair_valid := true;
                                    wb_valid := true;
                                    wb_rd := exec_rd;
                                    wb_data := buf_a_rdata;
                                    wb2_valid := true;
                                    wb2_rd := dec_rd;
                                    wb2_data := buf_a_rdata2;
                                when WPAIR_LDR_B =>
                                    pair_valid := true;
                                    wb_valid := true;
                                    wb_rd := exec_rd;
                                    wb_data := buf_b_rdata;
                                    wb2_valid := true;
                                    wb2_rd := dec_rd;
                                    wb2_data := buf_b_rdata2;
                                when WPAIR_STR_A | WPAIR_STR_B =>
                                    pair_valid := true;
                                when WPAIR_SADD16_SSUB16 =>
                                    pair_valid := true;
                                    wb_valid := true;
                                    wb_rd := exec_rd;
                                    wb_data := sadd16(exec_rn_data, exec_rm_data);
                                    wb2_valid := true;
                                    wb2_rd := dec_rd;
                                    wb2_data := ssub16(exec_rn_data, exec_rm_data);
                                when WPAIR_NONE =>
                                    null;
                            end case;

                            if pair_valid then
                                if wb_valid then
                                    regs(wb_rd) <= wb_data;
                                end if;
                                if wb2_valid then
                                    regs(wb2_rd) <= wb2_data;
                                end if;
                                load_exec_from_fetch_dual(
                                    wb_valid, wb_rd, wb_data,
                                    wb2_valid, wb2_rd, wb2_data
                                );
                                state_reg <= S_RUN;
                            else
                                case exec_op is
                                    when WOP_NOP =>
                                        null;
                                    when WOP_MOV_IMM =>
                                        wb_valid := true;
                                        wb_rd := exec_rd;
                                        wb_data := std_logic_vector(to_signed(exec_imm, 32));
                                        regs(exec_rd) <= wb_data;
                                    when WOP_MOV_REG =>
                                        if exec_rd = REG_PC then
                                            branch_taken := true;
                                            branch_target := word_to_pc(exec_rm_data);
                                        else
                                            wb_valid := true;
                                            wb_rd := exec_rd;
                                            wb_data := exec_rm_data;
                                            regs(exec_rd) <= wb_data;
                                        end if;
                                    when WOP_ADD =>
                                        wb_valid := true;
                                        wb_rd := exec_rd;
                                        wb_data := std_logic_vector(signed(exec_rn_data) + signed(exec_rm_data));
                                        regs(exec_rd) <= wb_data;
                                    when WOP_SUB =>
                                        wb_valid := true;
                                        wb_rd := exec_rd;
                                        wb_data := std_logic_vector(signed(exec_rn_data) - signed(exec_rm_data));
                                        regs(exec_rd) <= wb_data;
                                    when WOP_AND =>
                                        wb_valid := true;
                                        wb_rd := exec_rd;
                                        wb_data := exec_rn_data and exec_rm_data;
                                        regs(exec_rd) <= wb_data;
                                    when WOP_ORR =>
                                        wb_valid := true;
                                        wb_rd := exec_rd;
                                        wb_data := exec_rn_data or exec_rm_data;
                                        regs(exec_rd) <= wb_data;
                                    when WOP_PKHBT =>
                                        wb_valid := true;
                                        wb_rd := exec_rd;
                                        wb_data := pkhbt_shift(exec_rn_data, exec_rm_data, exec_imm);
                                        regs(exec_rd) <= wb_data;
                                    when WOP_LDR_A =>
                                        wb_valid := true;
                                        wb_rd := exec_rd;
                                        wb_data := buf_a_rdata;
                                        regs(exec_rd) <= wb_data;
                                    when WOP_LDR_B =>
                                        wb_valid := true;
                                        wb_rd := exec_rd;
                                        wb_data := buf_b_rdata;
                                        regs(exec_rd) <= wb_data;
                                    when WOP_SADD16 =>
                                        wb_valid := true;
                                        wb_rd := exec_rd;
                                        wb_data := sadd16(exec_rn_data, exec_rm_data);
                                        regs(exec_rd) <= wb_data;
                                    when WOP_SSUB16 =>
                                        wb_valid := true;
                                        wb_rd := exec_rd;
                                        wb_data := ssub16(exec_rn_data, exec_rm_data);
                                        regs(exec_rd) <= wb_data;
                                    when WOP_SSAX =>
                                        wb_valid := true;
                                        wb_rd := exec_rd;
                                        wb_data := ssax(exec_rn_data, exec_rm_data);
                                        regs(exec_rd) <= wb_data;
                                    when WOP_SMUAD | WOP_SMUSD =>
                                        dsp_a <= exec_dsp_a;
                                        dsp_b <= exec_dsp_b;
                                        dsp_rd <= exec_rd;
                                        if exec_op = WOP_SMUSD then
                                            dsp_sub <= '1';
                                        else
                                            dsp_sub <= '0';
                                        end if;
                                        -- Precompute pair eligibility before exec_* is reused by the paired DSP.
                                        if is_dsp_op(dec_op)
                                           and dec_illegal = '0'
                                           and dec_rn /= exec_rd
                                           and dec_rm /= exec_rd
                                           and dec_rd /= exec_rd then
                                            dsp_pair_ready <= '1';
                                        else
                                            dsp_pair_ready <= '0';
                                        end if;
                                        dsp_pc_reg <= exec_pc_reg;
                                        dsp_instr_reg <= exec_instr;
                                        start_dsp := true;
                                    when WOP_ASR =>
                                        wb_valid := true;
                                        wb_rd := exec_rd;
                                        res := std_logic_vector(shift_right(signed(exec_rn_data), exec_imm));
                                        wb_data := res;
                                        regs(exec_rd) <= wb_data;
                                    when WOP_B =>
                                        branch_taken := true;
                                        branch_target := clamp_pc(exec_imm);
                                    when WOP_BL =>
                                        regs(REG_LR) <= std_logic_vector(to_unsigned(next_seq_pc(exec_pc_reg) * 4, 32));
                                        branch_taken := true;
                                        branch_target := clamp_pc(exec_imm);
                                    when WOP_STR_A | WOP_STR_B =>
                                        null;
                                    when WOP_HALT =>
                                        halted_reg <= '1';
                                end case;

                                if exec_op = WOP_HALT then
                                    null;
                                elsif branch_taken then
                                    exec_op <= WOP_NOP;
                                    exec_instr <= x"E1A00000";
                                    exec_pc_reg <= branch_target;
                                    instr_reg <= x"E1A00000";
                                    instr_pc_reg <= branch_target;
                                    dec_op <= WOP_NOP;
                                    dec_rd <= 0;
                                    dec_rn <= 0;
                                    dec_rm <= 0;
                                    dec_imm <= 0;
                                    dec_idx <= 0;
                                    dec_illegal <= '0';
                                    dec_rd_data <= (others => '0');
                                    exec_pair_kind <= WPAIR_NONE;
                                    dsp_pair_ready <= '0';
                                    pc_fetch_reg <= branch_target;
                                    state_reg <= S_FETCH;
                                else
                                    load_exec_from_decode(wb_valid, wb_rd, wb_data);
                                    fetch_into_decode(
                                        wb_valid, wb_rd, wb_data,
                                        false, 0, (others => '0')
                                    );
                                    if start_dsp then
                                        state_reg <= S_DSP_MUL;
                                    else
                                        state_reg <= S_RUN;
                                    end if;
                                end if;
                            end if;
                        end if;

                    when S_DSP_MUL =>
                        dsp_prod_lo <= signed(dsp_a(15 downto 0)) * signed(dsp_b(15 downto 0));
                        dsp_prod_hi <= signed(dsp_a(31 downto 16)) * signed(dsp_b(31 downto 16));
                        dsp_sub_acc <= dsp_sub;
                        -- Signal reads use the previous cycle's precomputed value here.
                        dsp_pair_ready <= '0';
                        if dsp_pair_ready = '1' then
                            dsp2_a <= exec_dsp_a;
                            dsp2_b <= exec_dsp_b;
                            dsp2_rd <= exec_rd;
                            if exec_op = WOP_SMUSD then
                                dsp2_sub <= '1';
                            else
                                dsp2_sub <= '0';
                            end if;
                            load_exec_from_decode(false, 0, (others => '0'));
                            fetch_into_decode(
                                false, 0, (others => '0'),
                                false, 0, (others => '0')
                            );
                            state_reg <= S_DSP_PAIR_MUL_ACC;
                        else
                            state_reg <= S_DSP_ACC;
                        end if;

                    when S_DSP_ACC =>
                        dsp_sum <= std_logic_vector(dsp_prod_lo + dsp_prod_hi);
                        dsp_diff <= std_logic_vector(dsp_prod_lo - dsp_prod_hi);
                        state_reg <= S_DSP_WB;

                    when S_DSP_WB =>
                        if dsp_sub_acc = '1' then
                            wb_data := dsp_diff;
                        else
                            wb_data := dsp_sum;
                        end if;
                        wb_valid := true;
                        wb_rd := dsp_rd;
                        regs(dsp_rd) <= wb_data;
                        refresh_exec_operands(wb_valid, wb_rd, wb_data);
                        state_reg <= S_RUN;

                    when S_DSP_PAIR_MUL_ACC =>
                        dsp_sum <= std_logic_vector(dsp_prod_lo + dsp_prod_hi);
                        dsp_diff <= std_logic_vector(dsp_prod_lo - dsp_prod_hi);
                        dsp2_prod_lo <= signed(dsp2_a(15 downto 0)) * signed(dsp2_b(15 downto 0));
                        dsp2_prod_hi <= signed(dsp2_a(31 downto 16)) * signed(dsp2_b(31 downto 16));
                        dsp2_sub_acc <= dsp2_sub;
                        state_reg <= S_DSP_PAIR_WB_ACC;

                    when S_DSP_PAIR_WB_ACC =>
                        if dsp_sub_acc = '1' then
                            wb_data := dsp_diff;
                        else
                            wb_data := dsp_sum;
                        end if;
                        wb_valid := true;
                        wb_rd := dsp_rd;
                        regs(dsp_rd) <= wb_data;
                        refresh_exec_operands(wb_valid, wb_rd, wb_data);
                        if exec_op = WOP_ASR
                           and exec_illegal = '0'
                           and exec_rn = dsp_rd
                           and exec_rd /= dsp2_rd then
                            dsp_pair_asr_valid <= '1';
                            dsp_pair_asr_result <= std_logic_vector(shift_right(signed(wb_data), exec_imm));
                        else
                            dsp_pair_asr_valid <= '0';
                            dsp_pair_asr_result <= (others => '0');
                        end if;
                        dsp2_sum <= std_logic_vector(dsp2_prod_lo + dsp2_prod_hi);
                        dsp2_diff <= std_logic_vector(dsp2_prod_lo - dsp2_prod_hi);
                        state_reg <= S_DSP_PAIR_WB;

                    when S_DSP_PAIR_WB =>
                        if dsp2_sub_acc = '1' then
                            wb_data := dsp2_diff;
                        else
                            wb_data := dsp2_sum;
                        end if;

                        -- The common FFT DSP pair is followed by ASR of the
                        -- first result; retire it with the second DSP writeback.
                        if dsp_pair_asr_valid = '1' then
                            res := dsp_pair_asr_result;
                            regs(dsp2_rd) <= wb_data;
                            regs(exec_rd) <= res;
                            load_exec_from_decode_dual(
                                true, dsp2_rd, wb_data,
                                true, exec_rd, res
                            );
                            fetch_into_decode(
                                true, dsp2_rd, wb_data,
                                true, exec_rd, res
                            );
                        else
                            wb_valid := true;
                            wb_rd := dsp2_rd;
                            regs(dsp2_rd) <= wb_data;
                            refresh_exec_operands(wb_valid, wb_rd, wb_data);
                        end if;
                        state_reg <= S_RUN;
                end case;
            end if;
        end if;
    end process;

    halted <= halted_reg;
    illegal <= illegal_reg;
    pc_debug <= std_logic_vector(to_unsigned(dsp_pc_reg * 4, 32))
        when state_reg = S_DSP_MUL or state_reg = S_DSP_ACC or state_reg = S_DSP_WB
             or state_reg = S_DSP_PAIR_MUL_ACC
             or state_reg = S_DSP_PAIR_WB_ACC
             or state_reg = S_DSP_PAIR_WB
        else std_logic_vector(to_unsigned(exec_pc_reg * 4, 32))
        when state_reg = S_RUN
        else std_logic_vector(to_unsigned(instr_pc_reg * 4, 32))
        when state_reg = S_DECODE
        else std_logic_vector(to_unsigned(pc_fetch_reg * 4, 32));
    instr_debug <= dsp_instr_reg
        when state_reg = S_DSP_MUL or state_reg = S_DSP_ACC or state_reg = S_DSP_WB
             or state_reg = S_DSP_PAIR_MUL_ACC
             or state_reg = S_DSP_PAIR_WB_ACC
             or state_reg = S_DSP_PAIR_WB
        else exec_instr
        when state_reg = S_RUN
        else instr_reg;
end architecture rtl;
