library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.mcu4_multi_pkg.all;

entity mcu4_worker_decoder is
    port (
        instr_word : in  word_t;
        pc_index   : in  std_logic_vector(5 downto 0);

        op      : out worker_op_t;
        rd      : out natural range 0 to 15;
        rn      : out natural range 0 to 15;
        rm      : out natural range 0 to 15;
        imm     : out integer range -4096 to 4095;
        idx     : out natural range 0 to 7;
        illegal : out std_logic
    );
end entity mcu4_worker_decoder;

architecture rtl of mcu4_worker_decoder is
begin
    process(instr_word, pc_index)
        variable word_addr : natural range 0 to 1023;
        variable target_pc : integer range -4096 to 4095;
        variable branch_off : integer range -8388608 to 8388607;
        variable pc_value : integer range 0 to 63;
    begin
        op <= WOP_NOP;
        rd <= 0;
        rn <= 0;
        rm <= 0;
        imm <= 0;
        idx <= 0;
        illegal <= '0';

        pc_value := to_integer(unsigned(pc_index));

        if instr_word = x"EAFFFFFE" then
            op <= WOP_HALT;
        elsif instr_word(31 downto 20) = x"E3A" then
            op <= WOP_MOV_IMM;
            rd <= to_integer(unsigned(instr_word(15 downto 12)));
            imm <= to_integer(unsigned(instr_word(11 downto 0)));
        elsif instr_word(31 downto 20) = x"E3E" then
            op <= WOP_ASR;
            rd <= to_integer(unsigned(instr_word(15 downto 12)));
            rn <= to_integer(unsigned(instr_word(3 downto 0)));
            imm <= to_integer(unsigned(instr_word(11 downto 7)));
        elsif instr_word(31 downto 20) = x"E1A" then
            rd <= to_integer(unsigned(instr_word(15 downto 12)));
            rm <= to_integer(unsigned(instr_word(3 downto 0)));
            if instr_word(15 downto 12) = x"0" and instr_word(3 downto 0) = x"0" then
                op <= WOP_NOP;
            else
                op <= WOP_MOV_REG;
            end if;
        elsif instr_word(31 downto 20) = x"E08" then
            op <= WOP_ADD;
            rn <= to_integer(unsigned(instr_word(19 downto 16)));
            rd <= to_integer(unsigned(instr_word(15 downto 12)));
            rm <= to_integer(unsigned(instr_word(3 downto 0)));
        elsif instr_word(31 downto 20) = x"E04" then
            op <= WOP_SUB;
            rn <= to_integer(unsigned(instr_word(19 downto 16)));
            rd <= to_integer(unsigned(instr_word(15 downto 12)));
            rm <= to_integer(unsigned(instr_word(3 downto 0)));
        elsif instr_word(31 downto 20) = x"E00" then
            op <= WOP_AND;
            rn <= to_integer(unsigned(instr_word(19 downto 16)));
            rd <= to_integer(unsigned(instr_word(15 downto 12)));
            rm <= to_integer(unsigned(instr_word(3 downto 0)));
        elsif instr_word(31 downto 20) = x"E18" then
            op <= WOP_ORR;
            rn <= to_integer(unsigned(instr_word(19 downto 16)));
            rd <= to_integer(unsigned(instr_word(15 downto 12)));
            rm <= to_integer(unsigned(instr_word(3 downto 0)));
        elsif instr_word(31 downto 20) = x"ECA" then
            op <= WOP_PKHBT;
            rn <= to_integer(unsigned(instr_word(19 downto 16)));
            rd <= to_integer(unsigned(instr_word(15 downto 12)));
            rm <= to_integer(unsigned(instr_word(3 downto 0)));
            imm <= to_integer(unsigned(instr_word(11 downto 7)));
        elsif instr_word(31 downto 20) = x"E59" then
            rd <= to_integer(unsigned(instr_word(15 downto 12)));
            word_addr := to_integer(unsigned(instr_word(11 downto 0))) / 4;
            if word_addr >= WORK_BUF_A_BASE_WORD
               and word_addr < WORK_BUF_A_BASE_WORD + WORK_BUF_WORDS then
                op <= WOP_LDR_A;
                idx <= word_addr - WORK_BUF_A_BASE_WORD;
            elsif word_addr >= WORK_BUF_B_BASE_WORD
                  and word_addr < WORK_BUF_B_BASE_WORD + WORK_BUF_WORDS then
                op <= WOP_LDR_B;
                idx <= word_addr - WORK_BUF_B_BASE_WORD;
            else
                illegal <= '1';
            end if;
        elsif instr_word(31 downto 20) = x"E58" then
            rd <= to_integer(unsigned(instr_word(15 downto 12)));
            word_addr := to_integer(unsigned(instr_word(11 downto 0))) / 4;
            if word_addr >= WORK_BUF_A_BASE_WORD
               and word_addr < WORK_BUF_A_BASE_WORD + WORK_BUF_WORDS then
                op <= WOP_STR_A;
                idx <= word_addr - WORK_BUF_A_BASE_WORD;
            elsif word_addr >= WORK_BUF_B_BASE_WORD
                  and word_addr < WORK_BUF_B_BASE_WORD + WORK_BUF_WORDS then
                op <= WOP_STR_B;
                idx <= word_addr - WORK_BUF_B_BASE_WORD;
            else
                illegal <= '1';
            end if;
        elsif instr_word(31 downto 24) = x"ED" then
            case instr_word(23 downto 20) is
                when x"8" =>
                    op <= WOP_SADD16;
                when x"2" =>
                    op <= WOP_SSUB16;
                when x"0" =>
                    op <= WOP_SSAX;
                when others =>
                    illegal <= '1';
            end case;
            rn <= to_integer(unsigned(instr_word(19 downto 16)));
            rd <= to_integer(unsigned(instr_word(15 downto 12)));
            rm <= to_integer(unsigned(instr_word(3 downto 0)));
        elsif instr_word(31 downto 24) = x"EC" then
            case instr_word(23 downto 20) is
                when x"4" =>
                    op <= WOP_SMUAD;
                when x"6" =>
                    op <= WOP_SMUSD;
                when others =>
                    illegal <= '1';
            end case;
            rn <= to_integer(unsigned(instr_word(19 downto 16)));
            rd <= to_integer(unsigned(instr_word(15 downto 12)));
            rm <= to_integer(unsigned(instr_word(3 downto 0)));
        elsif instr_word(31 downto 24) = x"EA"
              or instr_word(31 downto 24) = x"EB" then
            branch_off := to_integer(signed(instr_word(23 downto 0)));
            target_pc := pc_value + 2 + branch_off;
            if target_pc < 0 or target_pc > 63 then
                illegal <= '1';
                imm <= 0;
            else
                imm <= target_pc;
            end if;

            if instr_word(31 downto 24) = x"EB" then
                op <= WOP_BL;
            else
                op <= WOP_B;
            end if;
        else
            illegal <= '1';
        end if;
    end process;
end architecture rtl;
