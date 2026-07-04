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
        variable target_index : integer range -4096 to 4095;
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

        if instr_word(31 downto 20) = x"E3A"
          and instr_word(19 downto 16) = x"0"
          and instr_word(11 downto 8) = x"0" then
            op <= WOP_MOV_IMM;
            rd <= to_integer(unsigned(instr_word(15 downto 12)));
            imm <= to_integer(unsigned(instr_word(7 downto 0)));
        elsif instr_word(31 downto 20) = x"E1A"
          and instr_word(19 downto 16) = x"0"
          and instr_word(6 downto 5) = "10"
          and instr_word(4) = '0' then
            op <= WOP_ASR;
            rd <= to_integer(unsigned(instr_word(15 downto 12)));
            rn <= to_integer(unsigned(instr_word(3 downto 0)));
            imm <= to_integer(unsigned(instr_word(11 downto 7)));
        elsif instr_word(31 downto 20) = x"E1A"
          and instr_word(19 downto 16) = x"0"
          and instr_word(11 downto 4) = x"00" then
            rd <= to_integer(unsigned(instr_word(15 downto 12)));
            rm <= to_integer(unsigned(instr_word(3 downto 0)));
            if instr_word(15 downto 12) = x"0" and instr_word(3 downto 0) = x"0" then
                op <= WOP_NOP;
            else
                op <= WOP_MOV_REG;
            end if;
        elsif instr_word(31 downto 20) = x"E08"
          and instr_word(11 downto 4) = x"00" then
            op <= WOP_ADD;
            rn <= to_integer(unsigned(instr_word(19 downto 16)));
            rd <= to_integer(unsigned(instr_word(15 downto 12)));
            rm <= to_integer(unsigned(instr_word(3 downto 0)));
        elsif instr_word(31 downto 20) = x"E04"
          and instr_word(11 downto 4) = x"00" then
            op <= WOP_SUB;
            rn <= to_integer(unsigned(instr_word(19 downto 16)));
            rd <= to_integer(unsigned(instr_word(15 downto 12)));
            rm <= to_integer(unsigned(instr_word(3 downto 0)));
        elsif instr_word(31 downto 20) = x"E00"
          and instr_word(11 downto 4) = x"00" then
            op <= WOP_AND;
            rn <= to_integer(unsigned(instr_word(19 downto 16)));
            rd <= to_integer(unsigned(instr_word(15 downto 12)));
            rm <= to_integer(unsigned(instr_word(3 downto 0)));
        elsif instr_word(31 downto 20) = x"E18"
          and instr_word(11 downto 4) = x"00" then
            op <= WOP_ORR;
            rn <= to_integer(unsigned(instr_word(19 downto 16)));
            rd <= to_integer(unsigned(instr_word(15 downto 12)));
            rm <= to_integer(unsigned(instr_word(3 downto 0)));
        elsif instr_word(31 downto 28) = x"E"
          and instr_word(27 downto 20) = x"68"
          and instr_word(6 downto 5) = "00"
          and instr_word(4) = '1' then
            op <= WOP_PKHBT;
            rn <= to_integer(unsigned(instr_word(19 downto 16)));
            rd <= to_integer(unsigned(instr_word(15 downto 12)));
            rm <= to_integer(unsigned(instr_word(3 downto 0)));
            imm <= to_integer(unsigned(instr_word(11 downto 7)));
        elsif instr_word(31 downto 20) = x"E59"
          and instr_word(19 downto 16) = x"0" then
            rd <= to_integer(unsigned(instr_word(15 downto 12)));
            word_addr := to_integer(unsigned(instr_word(11 downto 0))) / 4;
            if word_addr >= DMEM_BANK0_BASE_WORD
               and word_addr < DMEM_BANK0_BASE_WORD + DMEM_BANK_WORDS then
                op <= WOP_LDR_BANK0;
                idx <= word_addr - DMEM_BANK0_BASE_WORD;
            elsif word_addr >= DMEM_BANK1_BASE_WORD
                  and word_addr < DMEM_BANK1_BASE_WORD + DMEM_BANK_WORDS then
                op <= WOP_LDR_BANK1;
                idx <= word_addr - DMEM_BANK1_BASE_WORD;
            else
                illegal <= '1';
            end if;
        elsif instr_word(31 downto 20) = x"E58"
          and instr_word(19 downto 16) = x"0" then
            rd <= to_integer(unsigned(instr_word(15 downto 12)));
            word_addr := to_integer(unsigned(instr_word(11 downto 0))) / 4;
            if word_addr >= DMEM_BANK0_BASE_WORD
               and word_addr < DMEM_BANK0_BASE_WORD + DMEM_BANK_WORDS then
                op <= WOP_STR_BANK0;
                idx <= word_addr - DMEM_BANK0_BASE_WORD;
            elsif word_addr >= DMEM_BANK1_BASE_WORD
                  and word_addr < DMEM_BANK1_BASE_WORD + DMEM_BANK_WORDS then
                op <= WOP_STR_BANK1;
                idx <= word_addr - DMEM_BANK1_BASE_WORD;
            else
                illegal <= '1';
            end if;
        elsif instr_word(31 downto 28) = x"E"
          and instr_word(27 downto 20) = x"61"
          and instr_word(11 downto 8) = x"F"
          and instr_word(4) = '1' then
            case instr_word(7 downto 4) is
                when x"1" =>
                    op <= WOP_SADD16;
                when x"7" =>
                    op <= WOP_SSUB16;
                when x"5" =>
                    op <= WOP_SSAX;
                when others =>
                    illegal <= '1';
            end case;
            rn <= to_integer(unsigned(instr_word(19 downto 16)));
            rd <= to_integer(unsigned(instr_word(15 downto 12)));
            rm <= to_integer(unsigned(instr_word(3 downto 0)));
        elsif instr_word(31 downto 28) = x"E"
          and instr_word(27 downto 20) = x"70"
          and instr_word(15 downto 12) = x"F" then
            case instr_word(7 downto 4) is
                when x"1" =>
                    op <= WOP_SMUAD;
                when x"5" =>
                    op <= WOP_SMUSD;
                when others =>
                    illegal <= '1';
            end case;
            rd <= to_integer(unsigned(instr_word(19 downto 16)));
            rn <= to_integer(unsigned(instr_word(3 downto 0)));
            rm <= to_integer(unsigned(instr_word(11 downto 8)));
        elsif instr_word(31 downto 24) = x"EA"
              or instr_word(31 downto 24) = x"EB" then
            branch_off := to_integer(signed(instr_word(23 downto 0)));
            target_index := pc_value + 2 + branch_off;
            if target_index < 0 or target_index > 63 then
                illegal <= '1';
                imm <= 0;
            else
                imm <= target_index * 4;
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
