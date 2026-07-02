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
        pc_index    : in  std_logic_vector(5 downto 0);
        instr       : out word_t;
        dec_op      : out worker_op_t;
        dec_rd      : out natural range 0 to 15;
        dec_rn      : out natural range 0 to 15;
        dec_rm      : out natural range 0 to 15;
        dec_imm     : out integer range -4096 to 4095;
        dec_idx     : out natural range 0 to 7;
        dec_illegal : out std_logic;
        pair_kind   : out std_logic_vector(2 downto 0);
        next_pair_kind : out std_logic_vector(2 downto 0)
    );
end entity mcu4_worker_instr_rom;

architecture rtl of mcu4_worker_instr_rom is
    type worker_pair_rom_t is array (0 to 63) of std_logic_vector(2 downto 0);

    constant WPAIR_NONE_CODE          : std_logic_vector(2 downto 0) := "000";
    constant WPAIR_MOV_IMM_CODE       : std_logic_vector(2 downto 0) := "001";
    constant WPAIR_LDR_BANK0_CODE     : std_logic_vector(2 downto 0) := "010";
    constant WPAIR_LDR_BANK1_CODE     : std_logic_vector(2 downto 0) := "011";
    constant WPAIR_STR_BANK0_CODE     : std_logic_vector(2 downto 0) := "100";
    constant WPAIR_STR_BANK1_CODE     : std_logic_vector(2 downto 0) := "101";
    constant WPAIR_SADD16_SSUB16_CODE : std_logic_vector(2 downto 0) := "110";

    constant INSTR_NOP  : word_t := x"E1A00000";
    constant INSTR_HALT : word_t := x"EAFFFFFE";

    -- PROGRAM_ID = 0: FFT worker programs. Each worker has a concrete 32-bit
    -- instruction ROM image; these words are not built by an RTL encoder.
    constant FFT_ROM_W0 : program_rom_t := (
         0 => x"E3A00000", -- MOV r0, #0
         1 => x"E3A0105B", -- MOV r1, #91
         2 => x"ECA13801", -- PKHBT r3, r1, r1, LSL #16
         3 => x"ED204003", -- SSUB16 r4, r0, r3
         4 => x"E5905040", -- LDR r5, [dmem_bank0+0]
         5 => x"E5906044", -- LDR r6, [dmem_bank0+1]
         6 => x"ED85A006", -- SADD16 r10, r5, r6
         7 => x"ED25B006", -- SSUB16 r11, r5, r6
         8 => x"E580A080", -- STR r10, [dmem_bank1+0]
         9 => x"E580B084", -- STR r11, [dmem_bank1+1]
        10 => x"E5905080", -- LDR r5, [dmem_bank1+0]
        11 => x"E5906088", -- LDR r6, [dmem_bank1+2]
        12 => x"ED85A006", -- SADD16 r10, r5, r6
        13 => x"ED25B006", -- SSUB16 r11, r5, r6
        14 => x"E580A040", -- STR r10, [dmem_bank0+0]
        15 => x"E580B048", -- STR r11, [dmem_bank0+2]
        16 => INSTR_NOP,   -- NOP
        17 => x"E5905040", -- LDR r5, [dmem_bank0+0]
        18 => x"E5906050", -- LDR r6, [dmem_bank0+4]
        19 => x"ED85A006", -- SADD16 r10, r5, r6
        20 => x"ED25B006", -- SSUB16 r11, r5, r6
        21 => x"E580A080", -- STR r10, [dmem_bank1+0]
        22 => x"E580B090", -- STR r11, [dmem_bank1+4]
        23 => INSTR_NOP,   -- NOP
        24 => INSTR_NOP,   -- NOP
        25 => INSTR_NOP,   -- NOP
        26 => INSTR_NOP,   -- NOP
        others => INSTR_HALT
    );

    constant FFT_ROM_W1 : program_rom_t := (
         0 => x"E3A00000", -- MOV r0, #0
         1 => x"E3A0105B", -- MOV r1, #91
         2 => x"ECA13801", -- PKHBT r3, r1, r1, LSL #16
         3 => x"ED204003", -- SSUB16 r4, r0, r3
         4 => x"E5905048", -- LDR r5, [dmem_bank0+2]
         5 => x"E590604C", -- LDR r6, [dmem_bank0+3]
         6 => x"ED85A006", -- SADD16 r10, r5, r6
         7 => x"ED25B006", -- SSUB16 r11, r5, r6
         8 => x"E580A088", -- STR r10, [dmem_bank1+2]
         9 => x"E580B08C", -- STR r11, [dmem_bank1+3]
        10 => x"E5905084", -- LDR r5, [dmem_bank1+1]
        11 => x"E590608C", -- LDR r6, [dmem_bank1+3]
        12 => x"ED009006", -- SSAX r9, r0, r6
        13 => x"ED85A009", -- SADD16 r10, r5, r9
        14 => x"ED25B009", -- SSUB16 r11, r5, r9
        15 => x"E580A044", -- STR r10, [dmem_bank0+1]
        16 => x"E580B04C", -- STR r11, [dmem_bank0+3]
        17 => x"E5905044", -- LDR r5, [dmem_bank0+1]
        18 => x"E5906054", -- LDR r6, [dmem_bank0+5]
        19 => x"EC467003", -- SMUAD r7, r6, r3
        20 => x"EC668004", -- SMUSD r8, r6, r4
        21 => x"E3E07387", -- ASR r7, r7, #7
        22 => x"ECA79488", -- PKHBT r9, r7, r8, LSL #9
        23 => x"ED85A009", -- SADD16 r10, r5, r9
        24 => x"ED25B009", -- SSUB16 r11, r5, r9
        25 => x"E580A084", -- STR r10, [dmem_bank1+1]
        26 => x"E580B094", -- STR r11, [dmem_bank1+5]
        others => INSTR_HALT
    );

    constant FFT_ROM_W2 : program_rom_t := (
         0 => x"E3A00000", -- MOV r0, #0
         1 => x"E3A0105B", -- MOV r1, #91
         2 => x"ECA13801", -- PKHBT r3, r1, r1, LSL #16
         3 => x"ED204003", -- SSUB16 r4, r0, r3
         4 => x"E5905050", -- LDR r5, [dmem_bank0+4]
         5 => x"E5906054", -- LDR r6, [dmem_bank0+5]
         6 => x"ED85A006", -- SADD16 r10, r5, r6
         7 => x"ED25B006", -- SSUB16 r11, r5, r6
         8 => x"E580A090", -- STR r10, [dmem_bank1+4]
         9 => x"E580B094", -- STR r11, [dmem_bank1+5]
        10 => x"E5905090", -- LDR r5, [dmem_bank1+4]
        11 => x"E5906098", -- LDR r6, [dmem_bank1+6]
        12 => x"ED85A006", -- SADD16 r10, r5, r6
        13 => x"ED25B006", -- SSUB16 r11, r5, r6
        14 => x"E580A050", -- STR r10, [dmem_bank0+4]
        15 => x"E580B058", -- STR r11, [dmem_bank0+6]
        16 => INSTR_NOP,   -- NOP
        17 => x"E5905048", -- LDR r5, [dmem_bank0+2]
        18 => x"E5906058", -- LDR r6, [dmem_bank0+6]
        19 => x"ED009006", -- SSAX r9, r0, r6
        20 => x"ED85A009", -- SADD16 r10, r5, r9
        21 => x"ED25B009", -- SSUB16 r11, r5, r9
        22 => x"E580A088", -- STR r10, [dmem_bank1+2]
        23 => x"E580B098", -- STR r11, [dmem_bank1+6]
        24 => INSTR_NOP,   -- NOP
        25 => INSTR_NOP,   -- NOP
        26 => INSTR_NOP,   -- NOP
        others => INSTR_HALT
    );

    constant FFT_ROM_W3 : program_rom_t := (
         0 => x"E3A00000", -- MOV r0, #0
         1 => x"E3A0105B", -- MOV r1, #91
         2 => x"ECA13801", -- PKHBT r3, r1, r1, LSL #16
         3 => x"ED204003", -- SSUB16 r4, r0, r3
         4 => x"E5905058", -- LDR r5, [dmem_bank0+6]
         5 => x"E590605C", -- LDR r6, [dmem_bank0+7]
         6 => x"ED85A006", -- SADD16 r10, r5, r6
         7 => x"ED25B006", -- SSUB16 r11, r5, r6
         8 => x"E580A098", -- STR r10, [dmem_bank1+6]
         9 => x"E580B09C", -- STR r11, [dmem_bank1+7]
        10 => x"E5905094", -- LDR r5, [dmem_bank1+5]
        11 => x"E590609C", -- LDR r6, [dmem_bank1+7]
        12 => x"ED009006", -- SSAX r9, r0, r6
        13 => x"ED85A009", -- SADD16 r10, r5, r9
        14 => x"ED25B009", -- SSUB16 r11, r5, r9
        15 => x"E580A054", -- STR r10, [dmem_bank0+5]
        16 => x"E580B05C", -- STR r11, [dmem_bank0+7]
        17 => x"E590504C", -- LDR r5, [dmem_bank0+3]
        18 => x"E590605C", -- LDR r6, [dmem_bank0+7]
        19 => x"EC667004", -- SMUSD r7, r6, r4
        20 => x"EC468004", -- SMUAD r8, r6, r4
        21 => x"E3E07387", -- ASR r7, r7, #7
        22 => x"ECA79488", -- PKHBT r9, r7, r8, LSL #9
        23 => x"ED85A009", -- SADD16 r10, r5, r9
        24 => x"ED25B009", -- SSUB16 r11, r5, r9
        25 => x"E580A08C", -- STR r10, [dmem_bank1+3]
        26 => x"E580B09C", -- STR r11, [dmem_bank1+7]
        others => INSTR_HALT
    );

    -- PROGRAM_ID = 1: single-core PPT/basic-instruction test program.
    -- Intended board mode: PROGRAM_ID=1, ACTIVE_CORES=1.
    constant SELFTEST_ROM : program_rom_t := (
         0 => x"E3A00000", -- MOV r0, #0
         1 => x"E3A01007", -- MOV r1, #7
         2 => x"E3A02003", -- MOV r2, #3
         3 => x"E0813002", -- ADD r3, r1, r2
         4 => x"E0434002", -- SUB r4, r3, r2
         5 => x"E0035001", -- AND r5, r3, r1
         6 => x"E1856002", -- ORR r6, r5, r2
         7 => x"E1A07006", -- MOV r7, r6
         8 => x"E5908040", -- LDR r8, [r0, #0x40] ; data[0]
         9 => x"E0889007", -- ADD r9, r8, r7
        10 => x"E5809044", -- STR r9, [r0, #0x44] ; data[1]
        11 => x"EA000000", -- B selftest_after_skip
        12 => x"E5802050", -- STR r2, [r0, #0x50] ; data[4], skipped poison
        13 => x"EB000002", -- BL selftest_subroutine
        14 => x"E5801048", -- STR r1, [r0, #0x48] ; data[2]
        15 => x"E580A04C", -- STR r10, [r0, #0x4C] ; data[3]
        16 => INSTR_HALT,   -- HALT
        17 => x"E089A004", -- ADD r10, r9, r4
        18 => x"E1A0F00E", -- MOV pc, lr
        others => INSTR_HALT
    );

    procedure decode_instr_word(
        constant instr_value : in word_t;
        constant pc_value_in : in std_logic_vector(5 downto 0);
        variable op_value      : out worker_op_t;
        variable rd_value      : out natural range 0 to 15;
        variable rn_value      : out natural range 0 to 15;
        variable rm_value      : out natural range 0 to 15;
        variable imm_value     : out integer range -4096 to 4095;
        variable idx_value     : out natural range 0 to 7;
        variable illegal_value : out std_logic
    ) is
        variable word_addr : natural range 0 to 1023;
        variable target_pc : integer range -4096 to 4095;
        variable branch_off : integer range -8388608 to 8388607;
        variable pc_value : integer range 0 to 63;
    begin
        op_value := WOP_NOP;
        rd_value := 0;
        rn_value := 0;
        rm_value := 0;
        imm_value := 0;
        idx_value := 0;
        illegal_value := '0';

        pc_value := to_integer(unsigned(pc_value_in));

        if instr_value = INSTR_HALT then
            op_value := WOP_HALT;
        elsif instr_value(31 downto 20) = x"E3A" then
            op_value := WOP_MOV_IMM;
            rd_value := to_integer(unsigned(instr_value(15 downto 12)));
            imm_value := to_integer(unsigned(instr_value(11 downto 0)));
        elsif instr_value(31 downto 20) = x"E3E" then
            op_value := WOP_ASR;
            rd_value := to_integer(unsigned(instr_value(15 downto 12)));
            rn_value := to_integer(unsigned(instr_value(3 downto 0)));
            imm_value := to_integer(unsigned(instr_value(11 downto 7)));
        elsif instr_value(31 downto 20) = x"E1A" then
            rd_value := to_integer(unsigned(instr_value(15 downto 12)));
            rm_value := to_integer(unsigned(instr_value(3 downto 0)));
            if instr_value(15 downto 12) = x"0" and instr_value(3 downto 0) = x"0" then
                op_value := WOP_NOP;
            else
                op_value := WOP_MOV_REG;
            end if;
        elsif instr_value(31 downto 20) = x"E08" then
            op_value := WOP_ADD;
            rn_value := to_integer(unsigned(instr_value(19 downto 16)));
            rd_value := to_integer(unsigned(instr_value(15 downto 12)));
            rm_value := to_integer(unsigned(instr_value(3 downto 0)));
        elsif instr_value(31 downto 20) = x"E04" then
            op_value := WOP_SUB;
            rn_value := to_integer(unsigned(instr_value(19 downto 16)));
            rd_value := to_integer(unsigned(instr_value(15 downto 12)));
            rm_value := to_integer(unsigned(instr_value(3 downto 0)));
        elsif instr_value(31 downto 20) = x"E00" then
            op_value := WOP_AND;
            rn_value := to_integer(unsigned(instr_value(19 downto 16)));
            rd_value := to_integer(unsigned(instr_value(15 downto 12)));
            rm_value := to_integer(unsigned(instr_value(3 downto 0)));
        elsif instr_value(31 downto 20) = x"E18" then
            op_value := WOP_ORR;
            rn_value := to_integer(unsigned(instr_value(19 downto 16)));
            rd_value := to_integer(unsigned(instr_value(15 downto 12)));
            rm_value := to_integer(unsigned(instr_value(3 downto 0)));
        elsif instr_value(31 downto 20) = x"ECA" then
            op_value := WOP_PKHBT;
            rn_value := to_integer(unsigned(instr_value(19 downto 16)));
            rd_value := to_integer(unsigned(instr_value(15 downto 12)));
            rm_value := to_integer(unsigned(instr_value(3 downto 0)));
            imm_value := to_integer(unsigned(instr_value(11 downto 7)));
        elsif instr_value(31 downto 20) = x"E59" then
            rd_value := to_integer(unsigned(instr_value(15 downto 12)));
            word_addr := to_integer(unsigned(instr_value(11 downto 0))) / 4;
            if word_addr >= DMEM_BANK0_BASE_WORD
               and word_addr < DMEM_BANK0_BASE_WORD + DMEM_BANK_WORDS then
                op_value := WOP_LDR_BANK0;
                idx_value := word_addr - DMEM_BANK0_BASE_WORD;
            elsif word_addr >= DMEM_BANK1_BASE_WORD
                  and word_addr < DMEM_BANK1_BASE_WORD + DMEM_BANK_WORDS then
                op_value := WOP_LDR_BANK1;
                idx_value := word_addr - DMEM_BANK1_BASE_WORD;
            else
                illegal_value := '1';
            end if;
        elsif instr_value(31 downto 20) = x"E58" then
            rd_value := to_integer(unsigned(instr_value(15 downto 12)));
            word_addr := to_integer(unsigned(instr_value(11 downto 0))) / 4;
            if word_addr >= DMEM_BANK0_BASE_WORD
               and word_addr < DMEM_BANK0_BASE_WORD + DMEM_BANK_WORDS then
                op_value := WOP_STR_BANK0;
                idx_value := word_addr - DMEM_BANK0_BASE_WORD;
            elsif word_addr >= DMEM_BANK1_BASE_WORD
                  and word_addr < DMEM_BANK1_BASE_WORD + DMEM_BANK_WORDS then
                op_value := WOP_STR_BANK1;
                idx_value := word_addr - DMEM_BANK1_BASE_WORD;
            else
                illegal_value := '1';
            end if;
        elsif instr_value(31 downto 24) = x"ED" then
            case instr_value(23 downto 20) is
                when x"8" =>
                    op_value := WOP_SADD16;
                when x"2" =>
                    op_value := WOP_SSUB16;
                when x"0" =>
                    op_value := WOP_SSAX;
                when others =>
                    illegal_value := '1';
            end case;
            rn_value := to_integer(unsigned(instr_value(19 downto 16)));
            rd_value := to_integer(unsigned(instr_value(15 downto 12)));
            rm_value := to_integer(unsigned(instr_value(3 downto 0)));
        elsif instr_value(31 downto 24) = x"EC" then
            case instr_value(23 downto 20) is
                when x"4" =>
                    op_value := WOP_SMUAD;
                when x"6" =>
                    op_value := WOP_SMUSD;
                when others =>
                    illegal_value := '1';
            end case;
            rn_value := to_integer(unsigned(instr_value(19 downto 16)));
            rd_value := to_integer(unsigned(instr_value(15 downto 12)));
            rm_value := to_integer(unsigned(instr_value(3 downto 0)));
        elsif instr_value(31 downto 24) = x"EA"
              or instr_value(31 downto 24) = x"EB" then
            branch_off := to_integer(signed(instr_value(23 downto 0)));
            target_pc := pc_value + 2 + branch_off;
            if target_pc < 0 or target_pc > 63 then
                illegal_value := '1';
                imm_value := 0;
            else
                imm_value := target_pc;
            end if;

            if instr_value(31 downto 24) = x"EB" then
                op_value := WOP_BL;
            else
                op_value := WOP_B;
            end if;
        else
            illegal_value := '1';
        end if;
    end procedure;

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
    ) return std_logic_vector is
    begin
        if illegal_a = '1' or illegal_b = '1' then
            return WPAIR_NONE_CODE;
        elsif op_a = WOP_MOV_IMM
          and op_b = WOP_MOV_IMM
          and rd_a /= rd_b then
            return WPAIR_MOV_IMM_CODE;
        elsif op_a = WOP_LDR_BANK0
          and op_b = WOP_LDR_BANK0
          and rd_a /= rd_b then
            return WPAIR_LDR_BANK0_CODE;
        elsif op_a = WOP_LDR_BANK1
          and op_b = WOP_LDR_BANK1
          and rd_a /= rd_b then
            return WPAIR_LDR_BANK1_CODE;
        elsif op_a = WOP_STR_BANK0
          and op_b = WOP_STR_BANK0
          and idx_a /= idx_b then
            return WPAIR_STR_BANK0_CODE;
        elsif op_a = WOP_STR_BANK1
          and op_b = WOP_STR_BANK1
          and idx_a /= idx_b then
            return WPAIR_STR_BANK1_CODE;
        elsif op_a = WOP_SADD16
          and op_b = WOP_SSUB16
          and rn_a = rn_b
          and rm_a = rm_b
          and rd_a /= rd_b then
            return WPAIR_SADD16_SSUB16_CODE;
        end if;

        return WPAIR_NONE_CODE;
    end function;

    function build_pair_rom(constant rom : program_rom_t) return worker_pair_rom_t is
        variable result : worker_pair_rom_t := (others => WPAIR_NONE_CODE);
        variable pc_vec : std_logic_vector(5 downto 0);
        variable next_pc_vec : std_logic_vector(5 downto 0);
        variable next_pc : natural range 0 to 63;
        variable op_a : worker_op_t;
        variable rd_a : natural range 0 to 15;
        variable rn_a : natural range 0 to 15;
        variable rm_a : natural range 0 to 15;
        variable imm_a : integer range -4096 to 4095;
        variable idx_a : natural range 0 to 7;
        variable illegal_a : std_logic;
        variable op_b : worker_op_t;
        variable rd_b : natural range 0 to 15;
        variable rn_b : natural range 0 to 15;
        variable rm_b : natural range 0 to 15;
        variable imm_b : integer range -4096 to 4095;
        variable idx_b : natural range 0 to 7;
        variable illegal_b : std_logic;
    begin
        for pc in 0 to 63 loop
            if pc < 63 then
                next_pc := pc + 1;
            else
                next_pc := 63;
            end if;

            pc_vec := std_logic_vector(to_unsigned(pc, 6));
            next_pc_vec := std_logic_vector(to_unsigned(next_pc, 6));

            decode_instr_word(
                rom(pc),
                pc_vec,
                op_a,
                rd_a,
                rn_a,
                rm_a,
                imm_a,
                idx_a,
                illegal_a
            );
            decode_instr_word(
                rom(next_pc),
                next_pc_vec,
                op_b,
                rd_b,
                rn_b,
                rm_b,
                imm_b,
                idx_b,
                illegal_b
            );

            result(pc) := calc_pair_kind(
                op_a,
                rd_a,
                rn_a,
                rm_a,
                idx_a,
                illegal_a,
                op_b,
                rd_b,
                rn_b,
                rm_b,
                idx_b,
                illegal_b
            );
        end loop;

        return result;
    end function;

    constant FFT_PAIR_W0 : worker_pair_rom_t := build_pair_rom(FFT_ROM_W0);
    constant FFT_PAIR_W1 : worker_pair_rom_t := build_pair_rom(FFT_ROM_W1);
    constant FFT_PAIR_W2 : worker_pair_rom_t := build_pair_rom(FFT_ROM_W2);
    constant FFT_PAIR_W3 : worker_pair_rom_t := build_pair_rom(FFT_ROM_W3);
    constant SELFTEST_PAIR : worker_pair_rom_t := build_pair_rom(SELFTEST_ROM);
begin
    process(pc_index)
        variable pc : natural range 0 to 63;
        variable next_pc : natural range 0 to 63;
        variable instr_value : word_t;
        variable pair_value : std_logic_vector(2 downto 0);
        variable next_pair_value : std_logic_vector(2 downto 0);
        variable op_value : worker_op_t;
        variable rd_value : natural range 0 to 15;
        variable rn_value : natural range 0 to 15;
        variable rm_value : natural range 0 to 15;
        variable imm_value : integer range -4096 to 4095;
        variable idx_value : natural range 0 to 7;
        variable illegal_value : std_logic;
    begin
        pc := to_integer(unsigned(pc_index));
        if pc < 63 then
            next_pc := pc + 1;
        else
            next_pc := 63;
        end if;

        if PROGRAM_ID = 1 then
            instr_value := SELFTEST_ROM(pc);
            pair_value := SELFTEST_PAIR(pc);
            next_pair_value := SELFTEST_PAIR(next_pc);
        else
            case WORKER_ID is
                when 0 =>
                    instr_value := FFT_ROM_W0(pc);
                    pair_value := FFT_PAIR_W0(pc);
                    next_pair_value := FFT_PAIR_W0(next_pc);
                when 1 =>
                    instr_value := FFT_ROM_W1(pc);
                    pair_value := FFT_PAIR_W1(pc);
                    next_pair_value := FFT_PAIR_W1(next_pc);
                when 2 =>
                    instr_value := FFT_ROM_W2(pc);
                    pair_value := FFT_PAIR_W2(pc);
                    next_pair_value := FFT_PAIR_W2(next_pc);
                when others =>
                    instr_value := FFT_ROM_W3(pc);
                    pair_value := FFT_PAIR_W3(pc);
                    next_pair_value := FFT_PAIR_W3(next_pc);
            end case;
        end if;

        decode_instr_word(
            instr_value,
            pc_index,
            op_value,
            rd_value,
            rn_value,
            rm_value,
            imm_value,
            idx_value,
            illegal_value
        );

        instr <= instr_value;
        dec_op <= op_value;
        dec_rd <= rd_value;
        dec_rn <= rn_value;
        dec_rm <= rm_value;
        dec_imm <= imm_value;
        dec_idx <= idx_value;
        dec_illegal <= illegal_value;
        pair_kind <= pair_value;
        next_pair_kind <= next_pair_value;
    end process;
end architecture rtl;
