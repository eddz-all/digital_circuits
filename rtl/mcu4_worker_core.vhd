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
        buf_b_raddr : out std_logic_vector(2 downto 0);
        buf_b_rdata : in  word_t;

        buf_a_we    : out std_logic;
        buf_a_waddr : out std_logic_vector(2 downto 0);
        buf_a_wdata : out word_t;
        buf_b_we    : out std_logic;
        buf_b_waddr : out std_logic_vector(2 downto 0);
        buf_b_wdata : out word_t;

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
        S_DSP_WB
    );

    signal state_reg    : worker_state_t := S_FETCH;
    signal pc_fetch_reg : natural range 0 to 63 := 0;
    signal pc_index     : std_logic_vector(5 downto 0) := (others => '0');
    signal dec_pc_index : std_logic_vector(5 downto 0) := (others => '0');
    signal instr_reg    : word_t := x"E1A00000";
    signal instr_pc_reg : natural range 0 to 63 := 0;
    signal regs        : reg_file_t := (others => (others => '0'));
    signal halted_reg  : std_logic := '0';
    signal illegal_reg : std_logic := '0';

    signal instr_word  : word_t := (others => '0');
    signal dec_op      : worker_op_t := WOP_NOP;
    signal dec_rd      : natural range 0 to 15 := 0;
    signal dec_rn      : natural range 0 to 15 := 0;
    signal dec_rm      : natural range 0 to 15 := 0;
    signal dec_imm     : integer range -4096 to 4095 := 0;
    signal dec_idx     : natural range 0 to 7 := 0;
    signal dec_illegal : std_logic := '0';

    signal exec_op      : worker_op_t := WOP_NOP;
    signal exec_rd      : natural range 0 to 15 := 0;
    signal exec_rn      : natural range 0 to 15 := 0;
    signal exec_rm      : natural range 0 to 15 := 0;
    signal exec_imm     : integer range -4096 to 4095 := 0;
    signal exec_idx     : natural range 0 to 7 := 0;
    signal exec_illegal : std_logic := '0';
    signal exec_instr   : word_t := x"E1A00000";
    signal exec_pc_reg  : natural range 0 to 63 := 0;

    signal dsp_a         : word_t := (others => '0');
    signal dsp_b         : word_t := (others => '0');
    signal dsp_prod_lo   : signed(31 downto 0) := (others => '0');
    signal dsp_prod_hi   : signed(31 downto 0) := (others => '0');
    signal dsp_rd        : natural range 0 to 15 := 0;
    signal dsp_op        : worker_op_t := WOP_NOP;
    signal dsp_pc_reg    : natural range 0 to 63 := 0;
    signal dsp_instr_reg : word_t := x"E1A00000";

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
begin
    pc_index <= std_logic_vector(to_unsigned(pc_fetch_reg, 6));
    dec_pc_index <= std_logic_vector(to_unsigned(instr_pc_reg, 6));

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
            instr_word => instr_reg,
            pc_index   => dec_pc_index,
            op         => dec_op,
            rd         => dec_rd,
            rn         => dec_rn,
            rm         => dec_rm,
            imm        => dec_imm,
            idx        => dec_idx,
            illegal    => dec_illegal
        );

    buf_a_raddr <= std_logic_vector(to_unsigned(exec_idx, 3))
        when state_reg = S_RUN and (exec_op = WOP_LDR_A or exec_op = WOP_STR_A)
        else (others => '0');
    buf_b_raddr <= std_logic_vector(to_unsigned(exec_idx, 3))
        when state_reg = S_RUN and (exec_op = WOP_LDR_B or exec_op = WOP_STR_B)
        else (others => '0');

    buf_a_we <= '1' when halted_reg = '0'
                         and illegal_reg = '0'
                         and state_reg = S_RUN
                         and exec_illegal = '0'
                         and exec_op = WOP_STR_A
                else '0';
    buf_a_waddr <= std_logic_vector(to_unsigned(exec_idx, 3));
    buf_a_wdata <= regs(exec_rd);

    buf_b_we <= '1' when halted_reg = '0'
                         and illegal_reg = '0'
                         and state_reg = S_RUN
                         and exec_illegal = '0'
                         and exec_op = WOP_STR_B
                else '0';
    buf_b_waddr <= std_logic_vector(to_unsigned(exec_idx, 3));
    buf_b_wdata <= regs(exec_rd);

    process(clk)
        variable res : word_t;
        variable branch_taken : boolean;
        variable branch_target : natural range 0 to 63;
        variable start_dsp : boolean;

        procedure load_exec_from_decode is
        begin
            exec_op <= dec_op;
            exec_rd <= dec_rd;
            exec_rn <= dec_rn;
            exec_rm <= dec_rm;
            exec_imm <= dec_imm;
            exec_idx <= dec_idx;
            exec_illegal <= dec_illegal;
            exec_instr <= instr_reg;
            exec_pc_reg <= instr_pc_reg;
        end procedure;

        procedure fetch_into_decode is
        begin
            instr_reg <= instr_word;
            instr_pc_reg <= pc_fetch_reg;
            pc_fetch_reg <= next_seq_pc(pc_fetch_reg);
        end procedure;
    begin
        if rising_edge(clk) then
            if rst = '1' then
                state_reg <= S_FETCH;
                pc_fetch_reg <= 0;
                instr_pc_reg <= 0;
                instr_reg <= x"E1A00000";
                exec_op <= WOP_NOP;
                exec_rd <= 0;
                exec_rn <= 0;
                exec_rm <= 0;
                exec_imm <= 0;
                exec_idx <= 0;
                exec_illegal <= '0';
                exec_instr <= x"E1A00000";
                exec_pc_reg <= 0;
                regs <= (others => (others => '0'));
                halted_reg <= '0';
                illegal_reg <= '0';
                dsp_a <= (others => '0');
                dsp_b <= (others => '0');
                dsp_prod_lo <= (others => '0');
                dsp_prod_hi <= (others => '0');
                dsp_rd <= 0;
                dsp_op <= WOP_NOP;
                dsp_pc_reg <= 0;
                dsp_instr_reg <= x"E1A00000";
            elsif halted_reg = '0' and illegal_reg = '0' then
                case state_reg is
                    when S_FETCH =>
                        fetch_into_decode;
                        state_reg <= S_DECODE;

                    when S_DECODE =>
                        load_exec_from_decode;
                        fetch_into_decode;
                        state_reg <= S_RUN;

                    when S_RUN =>
                        if exec_illegal = '1' then
                            illegal_reg <= '1';
                            halted_reg <= '1';
                        else
                            branch_taken := false;
                            branch_target := 0;
                            start_dsp := false;

                            case exec_op is
                                when WOP_NOP =>
                                    null;
                                when WOP_MOV_IMM =>
                                    regs(exec_rd) <= std_logic_vector(to_signed(exec_imm, 32));
                                when WOP_MOV_REG =>
                                    if exec_rd = REG_PC then
                                        branch_taken := true;
                                        branch_target := word_to_pc(regs(exec_rm));
                                    else
                                        regs(exec_rd) <= regs(exec_rm);
                                    end if;
                                when WOP_ADD =>
                                    regs(exec_rd) <= std_logic_vector(signed(regs(exec_rn)) + signed(regs(exec_rm)));
                                when WOP_SUB =>
                                    regs(exec_rd) <= std_logic_vector(signed(regs(exec_rn)) - signed(regs(exec_rm)));
                                when WOP_AND =>
                                    regs(exec_rd) <= regs(exec_rn) and regs(exec_rm);
                                when WOP_ORR =>
                                    regs(exec_rd) <= regs(exec_rn) or regs(exec_rm);
                                when WOP_PKHBT =>
                                    regs(exec_rd) <= pkhbt_shift(regs(exec_rn), regs(exec_rm), exec_imm);
                                when WOP_LDR_A =>
                                    regs(exec_rd) <= buf_a_rdata;
                                when WOP_LDR_B =>
                                    regs(exec_rd) <= buf_b_rdata;
                                when WOP_SADD16 =>
                                    regs(exec_rd) <= sadd16(regs(exec_rn), regs(exec_rm));
                                when WOP_SSUB16 =>
                                    regs(exec_rd) <= ssub16(regs(exec_rn), regs(exec_rm));
                                when WOP_SSAX =>
                                    regs(exec_rd) <= ssax(regs(exec_rn), regs(exec_rm));
                                when WOP_SMUAD | WOP_SMUSD =>
                                    dsp_a <= regs(exec_rn);
                                    dsp_b <= regs(exec_rm);
                                    dsp_rd <= exec_rd;
                                    dsp_op <= exec_op;
                                    dsp_pc_reg <= exec_pc_reg;
                                    dsp_instr_reg <= exec_instr;
                                    start_dsp := true;
                                when WOP_ASR =>
                                    res := std_logic_vector(shift_right(signed(regs(exec_rn)), exec_imm));
                                    regs(exec_rd) <= res;
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
                                pc_fetch_reg <= branch_target;
                                state_reg <= S_FETCH;
                            else
                                load_exec_from_decode;
                                fetch_into_decode;
                                if start_dsp then
                                    state_reg <= S_DSP_MUL;
                                else
                                    state_reg <= S_RUN;
                                end if;
                            end if;
                        end if;

                    when S_DSP_MUL =>
                        dsp_prod_lo <= signed(dsp_a(15 downto 0)) * signed(dsp_b(15 downto 0));
                        dsp_prod_hi <= signed(dsp_a(31 downto 16)) * signed(dsp_b(31 downto 16));
                        state_reg <= S_DSP_WB;

                    when S_DSP_WB =>
                        if dsp_op = WOP_SMUAD then
                            regs(dsp_rd) <= std_logic_vector(dsp_prod_lo + dsp_prod_hi);
                        else
                            regs(dsp_rd) <= std_logic_vector(dsp_prod_lo - dsp_prod_hi);
                        end if;
                        state_reg <= S_RUN;
                end case;
            end if;
        end if;
    end process;

    halted <= halted_reg;
    illegal <= illegal_reg;
    pc_debug <= std_logic_vector(to_unsigned(dsp_pc_reg * 4, 32))
        when state_reg = S_DSP_MUL or state_reg = S_DSP_WB
        else std_logic_vector(to_unsigned(exec_pc_reg * 4, 32))
        when state_reg = S_RUN
        else std_logic_vector(to_unsigned(instr_pc_reg * 4, 32))
        when state_reg = S_DECODE
        else std_logic_vector(to_unsigned(pc_fetch_reg * 4, 32));
    instr_debug <= dsp_instr_reg
        when state_reg = S_DSP_MUL or state_reg = S_DSP_WB
        else exec_instr
        when state_reg = S_RUN
        else instr_reg;
end architecture rtl;
