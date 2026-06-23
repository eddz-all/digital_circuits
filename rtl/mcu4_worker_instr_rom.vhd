library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.mcu4_multi_pkg.all;

entity mcu4_worker_instr_rom is
    generic (
        WORKER_ID  : natural range 0 to 3 := 0;
        PROGRAM_ID : natural range 0 to 1 := 0
    );
    port (
        pc_index : in  std_logic_vector(5 downto 0);
        instr    : out word_t
    );
end entity mcu4_worker_instr_rom;

architecture rtl of mcu4_worker_instr_rom is
    function enc_reg(base : word_t; rd : natural; rn : natural; rm : natural)
        return word_t is
        variable enc : unsigned(31 downto 0);
    begin
        enc := unsigned(base);
        enc(19 downto 16) := to_unsigned(rn, 4);
        enc(15 downto 12) := to_unsigned(rd, 4);
        enc(3 downto 0) := to_unsigned(rm, 4);
        return std_logic_vector(enc);
    end function;

    function enc_mov_imm(rd : natural; imm : natural) return word_t is
        variable enc : unsigned(31 downto 0);
    begin
        enc := unsigned'(x"E3A00000");
        enc(15 downto 12) := to_unsigned(rd, 4);
        enc(11 downto 0) := to_unsigned(imm, 12);
        return std_logic_vector(enc);
    end function;

    function enc_mov_reg(rd : natural; rm : natural) return word_t is
    begin
        return enc_reg(x"E1A00000", rd, 0, rm);
    end function;

    function enc_pkhbt(rd : natural; rn : natural; rm : natural; shift : natural)
        return word_t is
        variable enc : unsigned(31 downto 0);
    begin
        enc := unsigned'(x"ECA00000");
        enc(19 downto 16) := to_unsigned(rn, 4);
        enc(15 downto 12) := to_unsigned(rd, 4);
        enc(11 downto 7) := to_unsigned(shift, 5);
        enc(3 downto 0) := to_unsigned(rm, 4);
        return std_logic_vector(enc);
    end function;

    function enc_asr(rd : natural; rn : natural; shift : natural) return word_t is
        variable enc : unsigned(31 downto 0);
    begin
        enc := unsigned'(x"E3E00000");
        enc(15 downto 12) := to_unsigned(rd, 4);
        enc(11 downto 7) := to_unsigned(shift, 5);
        enc(3 downto 0) := to_unsigned(rn, 4);
        return std_logic_vector(enc);
    end function;

    function enc_load_store(
        is_load : boolean;
        use_buf_a : boolean;
        rd : natural;
        idx : natural
    ) return word_t is
        variable enc : unsigned(31 downto 0);
        variable imm_addr : natural range 0 to 4095;
    begin
        if is_load then
            enc := unsigned'(x"E5900000");
        else
            enc := unsigned'(x"E5800000");
        end if;

        if use_buf_a then
            imm_addr := (WORK_BUF_A_BASE_WORD + idx) * 4;
        else
            imm_addr := (WORK_BUF_B_BASE_WORD + idx) * 4;
        end if;

        enc(19 downto 16) := to_unsigned(REG_ZERO, 4);
        enc(15 downto 12) := to_unsigned(rd, 4);
        enc(11 downto 0) := to_unsigned(imm_addr, 12);
        return std_logic_vector(enc);
    end function;

    function enc_ldr_a(rd : natural; idx : natural) return word_t is
    begin
        return enc_load_store(true, true, rd, idx);
    end function;

    function enc_ldr_b(rd : natural; idx : natural) return word_t is
    begin
        return enc_load_store(true, false, rd, idx);
    end function;

    function enc_str_a(rd : natural; idx : natural) return word_t is
    begin
        return enc_load_store(false, true, rd, idx);
    end function;

    function enc_str_b(rd : natural; idx : natural) return word_t is
    begin
        return enc_load_store(false, false, rd, idx);
    end function;

    function enc_alu(op : worker_op_t; rd : natural; rn : natural; rm : natural)
        return word_t is
    begin
        case op is
            when WOP_ADD =>
                return enc_reg(x"E0800000", rd, rn, rm);
            when WOP_SUB =>
                return enc_reg(x"E0400000", rd, rn, rm);
            when WOP_AND =>
                return enc_reg(x"E0000000", rd, rn, rm);
            when WOP_ORR =>
                return enc_reg(x"E1800000", rd, rn, rm);
            when WOP_SADD16 =>
                return enc_reg(x"ED800000", rd, rn, rm);
            when WOP_SSUB16 =>
                return enc_reg(x"ED200000", rd, rn, rm);
            when WOP_SSAX =>
                return enc_reg(x"ED000000", rd, rn, rm);
            when WOP_SMUAD =>
                return enc_reg(x"EC400000", rd, rn, rm);
            when WOP_SMUSD =>
                return enc_reg(x"EC600000", rd, rn, rm);
            when others =>
                return x"E1A00000";
        end case;
    end function;

    function enc_branch(target_pc : integer; current_pc : natural; link : boolean)
        return word_t is
        variable enc : unsigned(31 downto 0);
        variable offset : signed(23 downto 0);
    begin
        if link then
            enc := unsigned'(x"EB000000");
        else
            enc := unsigned'(x"EA000000");
        end if;
        offset := to_signed(target_pc - integer(current_pc) - 2, 24);
        enc(23 downto 0) := unsigned(offset);
        return std_logic_vector(enc);
    end function;

    function fft_program_word(wid : natural; pc : natural) return word_t is
    begin
        case pc is
            when 0 => return enc_mov_imm(REG_ZERO, 0);
            when 1 => return enc_mov_imm(REG_POS91, 91);
            when 2 => return enc_pkhbt(REG_PACK91, REG_POS91, REG_POS91, 16);
            when 3 => return enc_alu(WOP_SSUB16, REG_PACKN91, REG_ZERO, REG_PACK91);

            when 4 =>
                case wid is
                    when 0 => return enc_ldr_a(REG_A, 0);
                    when 1 => return enc_ldr_a(REG_A, 2);
                    when 2 => return enc_ldr_a(REG_A, 4);
                    when others => return enc_ldr_a(REG_A, 6);
                end case;
            when 5 =>
                case wid is
                    when 0 => return enc_ldr_a(REG_B, 1);
                    when 1 => return enc_ldr_a(REG_B, 3);
                    when 2 => return enc_ldr_a(REG_B, 5);
                    when others => return enc_ldr_a(REG_B, 7);
                end case;
            when 6 => return enc_alu(WOP_SADD16, REG_EVEN, REG_A, REG_B);
            when 7 => return enc_alu(WOP_SSUB16, REG_ODD, REG_A, REG_B);
            when 8 =>
                case wid is
                    when 0 => return enc_str_b(REG_EVEN, 0);
                    when 1 => return enc_str_b(REG_EVEN, 2);
                    when 2 => return enc_str_b(REG_EVEN, 4);
                    when others => return enc_str_b(REG_EVEN, 6);
                end case;
            when 9 =>
                case wid is
                    when 0 => return enc_str_b(REG_ODD, 1);
                    when 1 => return enc_str_b(REG_ODD, 3);
                    when 2 => return enc_str_b(REG_ODD, 5);
                    when others => return enc_str_b(REG_ODD, 7);
                end case;

            when 10 =>
                case wid is
                    when 0 => return enc_ldr_b(REG_A, 0);
                    when 1 => return enc_ldr_b(REG_A, 1);
                    when 2 => return enc_ldr_b(REG_A, 4);
                    when others => return enc_ldr_b(REG_A, 5);
                end case;
            when 11 =>
                case wid is
                    when 0 => return enc_ldr_b(REG_B, 2);
                    when 1 => return enc_ldr_b(REG_B, 3);
                    when 2 => return enc_ldr_b(REG_B, 6);
                    when others => return enc_ldr_b(REG_B, 7);
                end case;
            when 12 =>
                if wid = 1 or wid = 3 then
                    return enc_alu(WOP_SSAX, REG_T, REG_ZERO, REG_B);
                else
                    return enc_alu(WOP_SADD16, REG_EVEN, REG_A, REG_B);
                end if;
            when 13 =>
                if wid = 1 or wid = 3 then
                    return enc_alu(WOP_SADD16, REG_EVEN, REG_A, REG_T);
                else
                    return enc_alu(WOP_SSUB16, REG_ODD, REG_A, REG_B);
                end if;
            when 14 =>
                if wid = 1 or wid = 3 then
                    return enc_alu(WOP_SSUB16, REG_ODD, REG_A, REG_T);
                else
                    return enc_str_a(REG_EVEN, 0 + 4 * (wid / 2));
                end if;
            when 15 =>
                case wid is
                    when 0 => return enc_str_a(REG_ODD, 2);
                    when 1 => return enc_str_a(REG_EVEN, 1);
                    when 2 => return enc_str_a(REG_ODD, 6);
                    when others => return enc_str_a(REG_EVEN, 5);
                end case;
            when 16 =>
                if wid = 1 then
                    return enc_str_a(REG_ODD, 3);
                elsif wid = 3 then
                    return enc_str_a(REG_ODD, 7);
                else
                    return x"E1A00000";
                end if;

            when 17 =>
                case wid is
                    when 0 => return enc_ldr_a(REG_A, 0);
                    when 1 => return enc_ldr_a(REG_A, 1);
                    when 2 => return enc_ldr_a(REG_A, 2);
                    when others => return enc_ldr_a(REG_A, 3);
                end case;
            when 18 =>
                case wid is
                    when 0 => return enc_ldr_a(REG_B, 4);
                    when 1 => return enc_ldr_a(REG_B, 5);
                    when 2 => return enc_ldr_a(REG_B, 6);
                    when others => return enc_ldr_a(REG_B, 7);
                end case;
            when 19 =>
                if wid = 0 then
                    return enc_alu(WOP_SADD16, REG_EVEN, REG_A, REG_B);
                elsif wid = 2 then
                    return enc_alu(WOP_SSAX, REG_T, REG_ZERO, REG_B);
                elsif wid = 1 then
                    return enc_alu(WOP_SMUAD, REG_TMP_RE, REG_B, REG_PACK91);
                else
                    return enc_alu(WOP_SMUSD, REG_TMP_RE, REG_B, REG_PACKN91);
                end if;
            when 20 =>
                if wid = 0 then
                    return enc_alu(WOP_SSUB16, REG_ODD, REG_A, REG_B);
                elsif wid = 2 then
                    return enc_alu(WOP_SADD16, REG_EVEN, REG_A, REG_T);
                elsif wid = 1 then
                    return enc_alu(WOP_SMUSD, REG_TMP_IM, REG_B, REG_PACKN91);
                else
                    return enc_alu(WOP_SMUAD, REG_TMP_IM, REG_B, REG_PACKN91);
                end if;
            when 21 =>
                if wid = 0 then
                    return enc_str_b(REG_EVEN, 0);
                elsif wid = 2 then
                    return enc_alu(WOP_SSUB16, REG_ODD, REG_A, REG_T);
                else
                    return enc_asr(REG_TMP_RE, REG_TMP_RE, 7);
                end if;
            when 22 =>
                if wid = 0 then
                    return enc_str_b(REG_ODD, 4);
                elsif wid = 2 then
                    return enc_str_b(REG_EVEN, 2);
                else
                    return enc_pkhbt(REG_T, REG_TMP_RE, REG_TMP_IM, 9);
                end if;
            when 23 =>
                if wid = 0 then
                    return x"E1A00000";
                elsif wid = 2 then
                    return enc_str_b(REG_ODD, 6);
                else
                    return enc_alu(WOP_SADD16, REG_EVEN, REG_A, REG_T);
                end if;
            when 24 =>
                if wid = 1 or wid = 3 then
                    return enc_alu(WOP_SSUB16, REG_ODD, REG_A, REG_T);
                else
                    return x"E1A00000";
                end if;
            when 25 =>
                if wid = 1 then
                    return enc_str_b(REG_EVEN, 1);
                elsif wid = 3 then
                    return enc_str_b(REG_EVEN, 3);
                else
                    return x"E1A00000";
                end if;
            when 26 =>
                if wid = 1 then
                    return enc_str_b(REG_ODD, 5);
                elsif wid = 3 then
                    return enc_str_b(REG_ODD, 7);
                else
                    return x"E1A00000";
                end if;
            when others =>
                return x"EAFFFFFE";
        end case;
    end function;

    function selftest_program_word(pc : natural) return word_t is
    begin
        case pc is
            when 0 => return enc_mov_imm(0, 0);
            when 1 => return enc_mov_imm(1, 7);
            when 2 => return enc_mov_imm(2, 3);
            when 3 => return enc_alu(WOP_ADD, 3, 1, 2);
            when 4 => return enc_alu(WOP_SUB, 4, 3, 2);
            when 5 => return enc_alu(WOP_AND, 5, 3, 1);
            when 6 => return enc_alu(WOP_ORR, 6, 5, 2);
            when 7 => return enc_mov_reg(7, 6);
            when 8 => return enc_ldr_a(8, 0);
            when 9 => return enc_alu(WOP_ADD, 9, 8, 7);
            when 10 => return enc_str_b(9, 0);
            when 11 => return enc_branch(13, 11, false);
            when 12 => return enc_str_b(1, 1);
            when 13 => return enc_branch(16, 13, true);
            when 14 => return enc_str_b(10, 2);
            when 15 => return x"EAFFFFFE";
            when 16 => return enc_alu(WOP_ADD, 10, 9, 4);
            when 17 => return enc_mov_reg(REG_PC, REG_LR);
            when others => return x"EAFFFFFE";
        end case;
    end function;
begin
    process(pc_index)
        variable pc : natural range 0 to 63;
    begin
        pc := to_integer(unsigned(pc_index));
        if PROGRAM_ID = 1 then
            instr <= selftest_program_word(pc);
        else
            instr <= fft_program_word(WORKER_ID, pc);
        end if;
    end process;
end architecture rtl;
