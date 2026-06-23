library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.mcu4_multi_pkg.all;

entity mcu4_worker_core is
    generic (
        WORKER_ID : natural range 0 to 3 := 0;
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
    type worker_op_t is (
        WOP_NOP,
        WOP_MOV_IMM,
        WOP_MOV_REG,
        WOP_ADD,
        WOP_SUB,
        WOP_AND,
        WOP_ORR,
        WOP_PKHBT,
        WOP_LDR_A,
        WOP_LDR_B,
        WOP_STR_A,
        WOP_STR_B,
        WOP_SADD16,
        WOP_SSUB16,
        WOP_SSAX,
        WOP_SMUAD,
        WOP_SMUSD,
        WOP_ASR,
        WOP_B,
        WOP_BL,
        WOP_HALT,
        WOP_ILLEGAL
    );

    type worker_instr_t is record
        op  : worker_op_t;
        rd  : natural range 0 to 15;
        rn  : natural range 0 to 15;
        rm  : natural range 0 to 15;
        imm : integer range -4096 to 4095;
        idx : natural range 0 to 7;
    end record;

    constant REG_ZERO    : natural := 0;
    constant REG_POS91   : natural := 1;
    constant REG_PACK91  : natural := 3;
    constant REG_PACKN91 : natural := 4;
    constant REG_A       : natural := 5;
    constant REG_B       : natural := 6;
    constant REG_TMP_RE  : natural := 7;
    constant REG_TMP_IM  : natural := 8;
    constant REG_T       : natural := 9;
    constant REG_EVEN    : natural := 10;
    constant REG_ODD     : natural := 11;
    constant REG_LR      : natural := 14;
    constant REG_PC      : natural := 15;

    signal pc_reg     : natural range 0 to 63 := 0;
    signal regs       : reg_file_t := (others => (others => '0'));
    signal halted_reg : std_logic := '0';
    signal illegal_reg : std_logic := '0';

    function blank_instr return worker_instr_t is
        variable inst : worker_instr_t;
    begin
        inst.op := WOP_NOP;
        inst.rd := 0;
        inst.rn := 0;
        inst.rm := 0;
        inst.imm := 0;
        inst.idx := 0;
        return inst;
    end function;

    function mov_imm(rd : natural; imm : integer) return worker_instr_t is
        variable inst : worker_instr_t := blank_instr;
    begin
        inst.op := WOP_MOV_IMM;
        inst.rd := rd;
        inst.imm := imm;
        return inst;
    end function;

    function mov_reg(rd : natural; rm : natural) return worker_instr_t is
        variable inst : worker_instr_t := blank_instr;
    begin
        inst.op := WOP_MOV_REG;
        inst.rd := rd;
        inst.rm := rm;
        return inst;
    end function;

    function sub_reg(rd : natural; rn : natural; rm : natural) return worker_instr_t is
        variable inst : worker_instr_t := blank_instr;
    begin
        inst.op := WOP_SUB;
        inst.rd := rd;
        inst.rn := rn;
        inst.rm := rm;
        return inst;
    end function;

    function pkhbt(rd : natural; rn : natural; rm : natural; shift : natural) return worker_instr_t is
        variable inst : worker_instr_t := blank_instr;
    begin
        inst.op := WOP_PKHBT;
        inst.rd := rd;
        inst.rn := rn;
        inst.rm := rm;
        inst.imm := shift;
        return inst;
    end function;

    function ldr_a(rd : natural; idx : natural) return worker_instr_t is
        variable inst : worker_instr_t := blank_instr;
    begin
        inst.op := WOP_LDR_A;
        inst.rd := rd;
        inst.idx := idx;
        return inst;
    end function;

    function ldr_b(rd : natural; idx : natural) return worker_instr_t is
        variable inst : worker_instr_t := blank_instr;
    begin
        inst.op := WOP_LDR_B;
        inst.rd := rd;
        inst.idx := idx;
        return inst;
    end function;

    function str_a(rd : natural; idx : natural) return worker_instr_t is
        variable inst : worker_instr_t := blank_instr;
    begin
        inst.op := WOP_STR_A;
        inst.rd := rd;
        inst.idx := idx;
        return inst;
    end function;

    function str_b(rd : natural; idx : natural) return worker_instr_t is
        variable inst : worker_instr_t := blank_instr;
    begin
        inst.op := WOP_STR_B;
        inst.rd := rd;
        inst.idx := idx;
        return inst;
    end function;

    function alu2(op : worker_op_t; rd : natural; rn : natural; rm : natural) return worker_instr_t is
        variable inst : worker_instr_t := blank_instr;
    begin
        inst.op := op;
        inst.rd := rd;
        inst.rn := rn;
        inst.rm := rm;
        return inst;
    end function;

    function asr_imm(rd : natural; rn : natural; shift : natural) return worker_instr_t is
        variable inst : worker_instr_t := blank_instr;
    begin
        inst.op := WOP_ASR;
        inst.rd := rd;
        inst.rn := rn;
        inst.imm := shift;
        return inst;
    end function;

    function branch_abs(target_pc : natural) return worker_instr_t is
        variable inst : worker_instr_t := blank_instr;
    begin
        inst.op := WOP_B;
        inst.imm := target_pc;
        return inst;
    end function;

    function branch_link_abs(target_pc : natural) return worker_instr_t is
        variable inst : worker_instr_t := blank_instr;
    begin
        inst.op := WOP_BL;
        inst.imm := target_pc;
        return inst;
    end function;

    function halt_instr return worker_instr_t is
        variable inst : worker_instr_t := blank_instr;
    begin
        inst.op := WOP_HALT;
        return inst;
    end function;

    function illegal_instr return worker_instr_t is
        variable inst : worker_instr_t := blank_instr;
    begin
        inst.op := WOP_ILLEGAL;
        return inst;
    end function;

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

    function smuad(a : word_t; b : word_t) return word_t is
        variable prod_lo : signed(31 downto 0);
        variable prod_hi : signed(31 downto 0);
        variable sum32   : signed(31 downto 0);
    begin
        prod_lo := signed(a(15 downto 0)) * signed(b(15 downto 0));
        prod_hi := signed(a(31 downto 16)) * signed(b(31 downto 16));
        sum32 := prod_lo + prod_hi;
        return std_logic_vector(sum32);
    end function;

    function smusd(a : word_t; b : word_t) return word_t is
        variable prod_lo : signed(31 downto 0);
        variable prod_hi : signed(31 downto 0);
        variable sum32   : signed(31 downto 0);
    begin
        prod_lo := signed(a(15 downto 0)) * signed(b(15 downto 0));
        prod_hi := signed(a(31 downto 16)) * signed(b(31 downto 16));
        sum32 := prod_lo - prod_hi;
        return std_logic_vector(sum32);
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

    function encode_instr(inst : worker_instr_t) return word_t is
        variable enc : unsigned(31 downto 0) := (others => '0');
        variable imm_addr : natural range 0 to 255 := 0;
    begin
        case inst.op is
            when WOP_NOP =>
                enc := unsigned'(x"E1A00000");
            when WOP_MOV_IMM =>
                enc := unsigned'(x"E3A00000");
                enc(15 downto 12) := to_unsigned(inst.rd, 4);
                enc(11 downto 0) := to_unsigned(inst.imm, 12);
            when WOP_MOV_REG =>
                enc := unsigned'(x"E1A00000");
                enc(15 downto 12) := to_unsigned(inst.rd, 4);
                enc(3 downto 0) := to_unsigned(inst.rm, 4);
            when WOP_ADD =>
                enc := unsigned'(x"E0800000");
                enc(19 downto 16) := to_unsigned(inst.rn, 4);
                enc(15 downto 12) := to_unsigned(inst.rd, 4);
                enc(3 downto 0) := to_unsigned(inst.rm, 4);
            when WOP_SUB =>
                enc := unsigned'(x"E0400000");
                enc(19 downto 16) := to_unsigned(inst.rn, 4);
                enc(15 downto 12) := to_unsigned(inst.rd, 4);
                enc(3 downto 0) := to_unsigned(inst.rm, 4);
            when WOP_AND =>
                enc := unsigned'(x"E0000000");
                enc(19 downto 16) := to_unsigned(inst.rn, 4);
                enc(15 downto 12) := to_unsigned(inst.rd, 4);
                enc(3 downto 0) := to_unsigned(inst.rm, 4);
            when WOP_ORR =>
                enc := unsigned'(x"E1800000");
                enc(19 downto 16) := to_unsigned(inst.rn, 4);
                enc(15 downto 12) := to_unsigned(inst.rd, 4);
                enc(3 downto 0) := to_unsigned(inst.rm, 4);
            when WOP_LDR_A | WOP_LDR_B =>
                enc := unsigned'(x"E5900000");
                enc(19 downto 16) := to_unsigned(REG_ZERO, 4);
                enc(15 downto 12) := to_unsigned(inst.rd, 4);
                if inst.op = WOP_LDR_A then
                    imm_addr := (WORK_BUF_A_BASE_WORD + inst.idx) * 4;
                else
                    imm_addr := (WORK_BUF_B_BASE_WORD + inst.idx) * 4;
                end if;
                enc(11 downto 0) := to_unsigned(imm_addr, 12);
            when WOP_STR_A | WOP_STR_B =>
                enc := unsigned'(x"E5800000");
                enc(19 downto 16) := to_unsigned(REG_ZERO, 4);
                enc(15 downto 12) := to_unsigned(inst.rd, 4);
                if inst.op = WOP_STR_A then
                    imm_addr := (WORK_BUF_A_BASE_WORD + inst.idx) * 4;
                else
                    imm_addr := (WORK_BUF_B_BASE_WORD + inst.idx) * 4;
                end if;
                enc(11 downto 0) := to_unsigned(imm_addr, 12);
            when WOP_PKHBT =>
                enc := unsigned'(x"ECA00000");
                enc(19 downto 16) := to_unsigned(inst.rn, 4);
                enc(15 downto 12) := to_unsigned(inst.rd, 4);
                enc(11 downto 7) := to_unsigned(inst.imm, 5);
                enc(3 downto 0) := to_unsigned(inst.rm, 4);
            when WOP_SADD16 =>
                enc := unsigned'(x"ED800000");
                enc(19 downto 16) := to_unsigned(inst.rn, 4);
                enc(15 downto 12) := to_unsigned(inst.rd, 4);
                enc(3 downto 0) := to_unsigned(inst.rm, 4);
            when WOP_SSUB16 =>
                enc := unsigned'(x"ED200000");
                enc(19 downto 16) := to_unsigned(inst.rn, 4);
                enc(15 downto 12) := to_unsigned(inst.rd, 4);
                enc(3 downto 0) := to_unsigned(inst.rm, 4);
            when WOP_SSAX =>
                enc := unsigned'(x"ED080000");
                enc(19 downto 16) := to_unsigned(inst.rn, 4);
                enc(15 downto 12) := to_unsigned(inst.rd, 4);
                enc(3 downto 0) := to_unsigned(inst.rm, 4);
            when WOP_SMUAD =>
                enc := unsigned'(x"EC400000");
                enc(19 downto 16) := to_unsigned(inst.rn, 4);
                enc(15 downto 12) := to_unsigned(inst.rd, 4);
                enc(3 downto 0) := to_unsigned(inst.rm, 4);
            when WOP_SMUSD =>
                enc := unsigned'(x"EC600000");
                enc(19 downto 16) := to_unsigned(inst.rn, 4);
                enc(15 downto 12) := to_unsigned(inst.rd, 4);
                enc(3 downto 0) := to_unsigned(inst.rm, 4);
            when WOP_ASR =>
                enc := unsigned'(x"E3E00000");
                enc(15 downto 12) := to_unsigned(inst.rd, 4);
                enc(3 downto 0) := to_unsigned(inst.rn, 4);
                enc(11 downto 7) := to_unsigned(inst.imm, 5);
            when WOP_B =>
                enc := unsigned'(x"EA000000");
                enc(23 downto 0) := to_unsigned(inst.imm, 24);
            when WOP_BL =>
                enc := unsigned'(x"EB000000");
                enc(23 downto 0) := to_unsigned(inst.imm, 24);
            when WOP_HALT =>
                enc := unsigned'(x"EAFFFFFE");
            when others =>
                enc := unsigned'(x"E1A00000");
        end case;
        return std_logic_vector(enc);
    end function;

    function worker_instr_rom(wid : natural; pc : natural) return word_t is
    begin
        case pc is
            when 0 => return encode_instr(mov_imm(REG_ZERO, 0));
            when 1 => return encode_instr(mov_imm(REG_POS91, 91));
            when 2 => return encode_instr(pkhbt(REG_PACK91, REG_POS91, REG_POS91, 16));
            when 3 => return encode_instr(alu2(WOP_SSUB16, REG_PACKN91, REG_ZERO, REG_PACK91));

            when 4 =>
                case wid is
                    when 0 => return encode_instr(ldr_a(REG_A, 0));
                    when 1 => return encode_instr(ldr_a(REG_A, 2));
                    when 2 => return encode_instr(ldr_a(REG_A, 4));
                    when others => return encode_instr(ldr_a(REG_A, 6));
                end case;
            when 5 =>
                case wid is
                    when 0 => return encode_instr(ldr_a(REG_B, 1));
                    when 1 => return encode_instr(ldr_a(REG_B, 3));
                    when 2 => return encode_instr(ldr_a(REG_B, 5));
                    when others => return encode_instr(ldr_a(REG_B, 7));
                end case;
            when 6 => return encode_instr(alu2(WOP_SADD16, REG_EVEN, REG_A, REG_B));
            when 7 => return encode_instr(alu2(WOP_SSUB16, REG_ODD, REG_A, REG_B));
            when 8 =>
                case wid is
                    when 0 => return encode_instr(str_b(REG_EVEN, 0));
                    when 1 => return encode_instr(str_b(REG_EVEN, 2));
                    when 2 => return encode_instr(str_b(REG_EVEN, 4));
                    when others => return encode_instr(str_b(REG_EVEN, 6));
                end case;
            when 9 =>
                case wid is
                    when 0 => return encode_instr(str_b(REG_ODD, 1));
                    when 1 => return encode_instr(str_b(REG_ODD, 3));
                    when 2 => return encode_instr(str_b(REG_ODD, 5));
                    when others => return encode_instr(str_b(REG_ODD, 7));
                end case;

            when 10 =>
                case wid is
                    when 0 => return encode_instr(ldr_b(REG_A, 0));
                    when 1 => return encode_instr(ldr_b(REG_A, 1));
                    when 2 => return encode_instr(ldr_b(REG_A, 4));
                    when others => return encode_instr(ldr_b(REG_A, 5));
                end case;
            when 11 =>
                case wid is
                    when 0 => return encode_instr(ldr_b(REG_B, 2));
                    when 1 => return encode_instr(ldr_b(REG_B, 3));
                    when 2 => return encode_instr(ldr_b(REG_B, 6));
                    when others => return encode_instr(ldr_b(REG_B, 7));
                end case;
            when 12 =>
                if wid = 1 or wid = 3 then
                    return encode_instr(alu2(WOP_SSAX, REG_T, REG_ZERO, REG_B));
                else
                    return encode_instr(alu2(WOP_SADD16, REG_EVEN, REG_A, REG_B));
                end if;
            when 13 =>
                if wid = 1 or wid = 3 then
                    return encode_instr(alu2(WOP_SADD16, REG_EVEN, REG_A, REG_T));
                else
                    return encode_instr(alu2(WOP_SSUB16, REG_ODD, REG_A, REG_B));
                end if;
            when 14 =>
                if wid = 1 or wid = 3 then
                    return encode_instr(alu2(WOP_SSUB16, REG_ODD, REG_A, REG_T));
                else
                    return encode_instr(str_a(REG_EVEN, 0 + 4 * (wid / 2)));
                end if;
            when 15 =>
                case wid is
                    when 0 => return encode_instr(str_a(REG_ODD, 2));
                    when 1 => return encode_instr(str_a(REG_EVEN, 1));
                    when 2 => return encode_instr(str_a(REG_ODD, 6));
                    when others => return encode_instr(str_a(REG_EVEN, 5));
                end case;
            when 16 =>
                if wid = 1 then
                    return encode_instr(str_a(REG_ODD, 3));
                elsif wid = 3 then
                    return encode_instr(str_a(REG_ODD, 7));
                else
                    return encode_instr(blank_instr);
                end if;

            when 17 =>
                case wid is
                    when 0 => return encode_instr(ldr_a(REG_A, 0));
                    when 1 => return encode_instr(ldr_a(REG_A, 1));
                    when 2 => return encode_instr(ldr_a(REG_A, 2));
                    when others => return encode_instr(ldr_a(REG_A, 3));
                end case;
            when 18 =>
                case wid is
                    when 0 => return encode_instr(ldr_a(REG_B, 4));
                    when 1 => return encode_instr(ldr_a(REG_B, 5));
                    when 2 => return encode_instr(ldr_a(REG_B, 6));
                    when others => return encode_instr(ldr_a(REG_B, 7));
                end case;
            when 19 =>
                if wid = 0 then
                    return encode_instr(alu2(WOP_SADD16, REG_EVEN, REG_A, REG_B));
                elsif wid = 2 then
                    return encode_instr(alu2(WOP_SSAX, REG_T, REG_ZERO, REG_B));
                elsif wid = 1 then
                    return encode_instr(alu2(WOP_SMUAD, REG_TMP_RE, REG_B, REG_PACK91));
                else
                    return encode_instr(alu2(WOP_SMUSD, REG_TMP_RE, REG_B, REG_PACKN91));
                end if;
            when 20 =>
                if wid = 0 then
                    return encode_instr(alu2(WOP_SSUB16, REG_ODD, REG_A, REG_B));
                elsif wid = 2 then
                    return encode_instr(alu2(WOP_SADD16, REG_EVEN, REG_A, REG_T));
                elsif wid = 1 then
                    return encode_instr(alu2(WOP_SMUSD, REG_TMP_IM, REG_B, REG_PACKN91));
                else
                    return encode_instr(alu2(WOP_SMUAD, REG_TMP_IM, REG_B, REG_PACKN91));
                end if;
            when 21 =>
                if wid = 0 then
                    return encode_instr(str_b(REG_EVEN, 0));
                elsif wid = 2 then
                    return encode_instr(alu2(WOP_SSUB16, REG_ODD, REG_A, REG_T));
                else
                    return encode_instr(asr_imm(REG_TMP_RE, REG_TMP_RE, 7));
                end if;
            when 22 =>
                if wid = 0 then
                    return encode_instr(str_b(REG_ODD, 4));
                elsif wid = 2 then
                    return encode_instr(str_b(REG_EVEN, 2));
                else
                    return encode_instr(pkhbt(REG_T, REG_TMP_RE, REG_TMP_IM, 9));
                end if;
            when 23 =>
                if wid = 0 then
                    return encode_instr(blank_instr);
                elsif wid = 2 then
                    return encode_instr(str_b(REG_ODD, 6));
                else
                    return encode_instr(alu2(WOP_SADD16, REG_EVEN, REG_A, REG_T));
                end if;
            when 24 =>
                if wid = 1 or wid = 3 then
                    return encode_instr(alu2(WOP_SSUB16, REG_ODD, REG_A, REG_T));
                else
                    return encode_instr(blank_instr);
                end if;
            when 25 =>
                if wid = 1 then
                    return encode_instr(str_b(REG_EVEN, 1));
                elsif wid = 3 then
                    return encode_instr(str_b(REG_EVEN, 3));
                else
                    return encode_instr(blank_instr);
                end if;
            when 26 =>
                if wid = 1 then
                    return encode_instr(str_b(REG_ODD, 5));
                elsif wid = 3 then
                    return encode_instr(str_b(REG_ODD, 7));
                else
                    return encode_instr(blank_instr);
                end if;
            when others =>
                return encode_instr(halt_instr);
        end case;
    end function;

    function arm_minimum_selftest_rom(pc : natural) return word_t is
    begin
        case pc is
            when 0 => return encode_instr(mov_imm(0, 0));
            when 1 => return encode_instr(mov_imm(1, 7));
            when 2 => return encode_instr(mov_imm(2, 3));
            when 3 => return encode_instr(alu2(WOP_ADD, 3, 1, 2));
            when 4 => return encode_instr(sub_reg(4, 3, 2));
            when 5 => return encode_instr(alu2(WOP_AND, 5, 3, 1));
            when 6 => return encode_instr(alu2(WOP_ORR, 6, 5, 2));
            when 7 => return encode_instr(mov_reg(7, 6));
            when 8 => return encode_instr(ldr_a(8, 0));
            when 9 => return encode_instr(alu2(WOP_ADD, 9, 8, 7));
            when 10 => return encode_instr(str_b(9, 0));
            when 11 => return encode_instr(branch_abs(13));
            when 12 => return encode_instr(str_b(1, 1));
            when 13 => return encode_instr(branch_link_abs(16));
            when 14 => return encode_instr(str_b(10, 2));
            when 15 => return encode_instr(halt_instr);
            when 16 => return encode_instr(alu2(WOP_ADD, 10, 9, 4));
            when 17 => return encode_instr(mov_reg(REG_PC, REG_LR));
            when others => return encode_instr(halt_instr);
        end case;
    end function;

    function selected_instr_rom(program_sel : natural; wid : natural; pc : natural)
        return word_t is
    begin
        if program_sel = 1 then
            return arm_minimum_selftest_rom(pc);
        end if;
        return worker_instr_rom(wid, pc);
    end function;

    function decode_work_mem_access(
        is_store : boolean;
        rd       : natural;
        imm_addr : natural
    ) return worker_instr_t is
        variable word_addr : natural range 0 to 1023 := 0;
    begin
        if (imm_addr mod 4) /= 0 then
            return illegal_instr;
        end if;

        word_addr := imm_addr / 4;
        if word_addr >= WORK_BUF_A_BASE_WORD
            and word_addr < WORK_BUF_A_BASE_WORD + WORK_BUF_WORDS then
            if is_store then
                return str_a(rd, word_addr - WORK_BUF_A_BASE_WORD);
            end if;
            return ldr_a(rd, word_addr - WORK_BUF_A_BASE_WORD);
        elsif word_addr >= WORK_BUF_B_BASE_WORD
            and word_addr < WORK_BUF_B_BASE_WORD + WORK_BUF_WORDS then
            if is_store then
                return str_b(rd, word_addr - WORK_BUF_B_BASE_WORD);
            end if;
            return ldr_b(rd, word_addr - WORK_BUF_B_BASE_WORD);
        end if;

        return illegal_instr;
    end function;

    function decode_worker_instr(instr_word : word_t) return worker_instr_t is
        variable op12     : std_logic_vector(11 downto 0);
        variable rd       : natural range 0 to 15;
        variable rn       : natural range 0 to 15;
        variable rm       : natural range 0 to 15;
        variable imm_addr : natural range 0 to 4095;
    begin
        op12 := instr_word(31 downto 20);
        rd := to_integer(unsigned(instr_word(15 downto 12)));
        rn := to_integer(unsigned(instr_word(19 downto 16)));
        rm := to_integer(unsigned(instr_word(3 downto 0)));
        imm_addr := to_integer(unsigned(instr_word(11 downto 0)));

        if instr_word = x"EAFFFFFE" then
            return halt_instr;
        elsif op12 = x"E3A" then
            return mov_imm(rd, imm_addr);
        elsif op12 = x"E1A" then
            return mov_reg(rd, rm);
        elsif op12 = x"E08" then
            return alu2(WOP_ADD, rd, rn, rm);
        elsif op12 = x"E04" then
            return sub_reg(rd, rn, rm);
        elsif op12 = x"E00" then
            return alu2(WOP_AND, rd, rn, rm);
        elsif op12 = x"E18" then
            return alu2(WOP_ORR, rd, rn, rm);
        elsif op12 = x"E59" then
            if rn /= REG_ZERO then
                return illegal_instr;
            end if;
            return decode_work_mem_access(false, rd, imm_addr);
        elsif op12 = x"E58" then
            if rn /= REG_ZERO then
                return illegal_instr;
            end if;
            return decode_work_mem_access(true, rd, imm_addr);
        elsif op12 = x"ECA" then
            return pkhbt(rd, rn, rm, to_integer(unsigned(instr_word(11 downto 7))));
        elsif op12 = x"ED8" then
            return alu2(WOP_SADD16, rd, rn, rm);
        elsif op12 = x"ED2" then
            return alu2(WOP_SSUB16, rd, rn, rm);
        elsif op12 = x"ED0" then
            return alu2(WOP_SSAX, rd, rn, rm);
        elsif op12 = x"EC4" then
            return alu2(WOP_SMUAD, rd, rn, rm);
        elsif op12 = x"EC6" then
            return alu2(WOP_SMUSD, rd, rn, rm);
        elsif op12 = x"E3E" then
            return asr_imm(rd, rm, to_integer(unsigned(instr_word(11 downto 7))));
        elsif instr_word(31 downto 24) = x"EA" then
            return branch_abs(clamp_pc(to_integer(unsigned(instr_word(23 downto 0)))));
        elsif instr_word(31 downto 24) = x"EB" then
            return branch_link_abs(clamp_pc(to_integer(unsigned(instr_word(23 downto 0)))));
        end if;

        return illegal_instr;
    end function;

    signal instr_word : word_t := (others => '0');
    signal instr : worker_instr_t := blank_instr;
begin
    instr_word <= selected_instr_rom(PROGRAM_ID, WORKER_ID, pc_reg);
    instr <= decode_worker_instr(instr_word);

    buf_a_raddr <= std_logic_vector(to_unsigned(instr.idx, 3))
        when instr.op = WOP_LDR_A or instr.op = WOP_STR_A
        else (others => '0');
    buf_b_raddr <= std_logic_vector(to_unsigned(instr.idx, 3))
        when instr.op = WOP_LDR_B or instr.op = WOP_STR_B
        else (others => '0');

    buf_a_we <= '1' when halted_reg = '0' and instr.op = WOP_STR_A else '0';
    buf_a_waddr <= std_logic_vector(to_unsigned(instr.idx, 3));
    buf_a_wdata <= regs(instr.rd);

    buf_b_we <= '1' when halted_reg = '0' and instr.op = WOP_STR_B else '0';
    buf_b_waddr <= std_logic_vector(to_unsigned(instr.idx, 3));
    buf_b_wdata <= regs(instr.rd);

    process(clk)
        variable res : word_t;
        variable next_pc : natural range 0 to 63;
    begin
        if rising_edge(clk) then
            if rst = '1' then
                pc_reg <= 0;
                regs <= (others => (others => '0'));
                halted_reg <= '0';
                illegal_reg <= '0';
            elsif halted_reg = '0' then
                next_pc := next_seq_pc(pc_reg);
                case instr.op is
                    when WOP_NOP =>
                        null;
                    when WOP_MOV_IMM =>
                        regs(instr.rd) <= std_logic_vector(to_signed(instr.imm, 32));
                    when WOP_MOV_REG =>
                        if instr.rd = REG_PC then
                            next_pc := word_to_pc(regs(instr.rm));
                        else
                            regs(instr.rd) <= regs(instr.rm);
                        end if;
                    when WOP_ADD =>
                        regs(instr.rd) <= std_logic_vector(signed(regs(instr.rn)) + signed(regs(instr.rm)));
                    when WOP_SUB =>
                        regs(instr.rd) <= std_logic_vector(signed(regs(instr.rn)) - signed(regs(instr.rm)));
                    when WOP_AND =>
                        regs(instr.rd) <= regs(instr.rn) and regs(instr.rm);
                    when WOP_ORR =>
                        regs(instr.rd) <= regs(instr.rn) or regs(instr.rm);
                    when WOP_PKHBT =>
                        regs(instr.rd) <= pkhbt_shift(regs(instr.rn), regs(instr.rm), instr.imm);
                    when WOP_LDR_A =>
                        regs(instr.rd) <= buf_a_rdata;
                    when WOP_LDR_B =>
                        regs(instr.rd) <= buf_b_rdata;
                    when WOP_SADD16 =>
                        regs(instr.rd) <= sadd16(regs(instr.rn), regs(instr.rm));
                    when WOP_SSUB16 =>
                        regs(instr.rd) <= ssub16(regs(instr.rn), regs(instr.rm));
                    when WOP_SSAX =>
                        regs(instr.rd) <= ssax(regs(instr.rn), regs(instr.rm));
                    when WOP_SMUAD =>
                        regs(instr.rd) <= smuad(regs(instr.rn), regs(instr.rm));
                    when WOP_SMUSD =>
                        regs(instr.rd) <= smusd(regs(instr.rn), regs(instr.rm));
                    when WOP_ASR =>
                        res := std_logic_vector(shift_right(signed(regs(instr.rn)), instr.imm));
                        regs(instr.rd) <= res;
                    when WOP_B =>
                        next_pc := clamp_pc(instr.imm);
                    when WOP_BL =>
                        regs(REG_LR) <= std_logic_vector(to_unsigned(next_seq_pc(pc_reg) * 4, 32));
                        next_pc := clamp_pc(instr.imm);
                    when WOP_STR_A | WOP_STR_B =>
                        null;
                    when WOP_HALT =>
                        halted_reg <= '1';
                    when WOP_ILLEGAL =>
                        illegal_reg <= '1';
                        halted_reg <= '1';
                end case;

                if instr.op /= WOP_HALT and instr.op /= WOP_ILLEGAL then
                    pc_reg <= next_pc;
                end if;
            end if;
        end if;
    end process;

    halted <= halted_reg;
    illegal <= illegal_reg;
    pc_debug <= std_logic_vector(to_unsigned(pc_reg * 4, 32));
    instr_debug <= instr_word;
end architecture rtl;
