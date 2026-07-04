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
    type worker_decode_entry_t is record
        op      : worker_op_t;
        rd      : natural range 0 to 15;
        rn      : natural range 0 to 15;
        rm      : natural range 0 to 15;
        imm     : integer range -4096 to 4095;
        idx     : natural range 0 to 7;
        illegal : std_logic;
    end record;
    type worker_decode_rom_t is array (0 to 63) of worker_decode_entry_t;

    constant DECODE_NOP : worker_decode_entry_t := (
        op      => WOP_NOP,
        rd      => 0,
        rn      => 0,
        rm      => 0,
        imm     => 0,
        idx     => 0,
        illegal => '0'
    );

    constant WPAIR_NONE_CODE          : std_logic_vector(2 downto 0) := "000";
    constant WPAIR_MOV_IMM_CODE       : std_logic_vector(2 downto 0) := "001";
    constant WPAIR_LDR_BANK0_CODE     : std_logic_vector(2 downto 0) := "010";
    constant WPAIR_LDR_BANK1_CODE     : std_logic_vector(2 downto 0) := "011";
    constant WPAIR_STR_BANK0_CODE     : std_logic_vector(2 downto 0) := "100";
    constant WPAIR_STR_BANK1_CODE     : std_logic_vector(2 downto 0) := "101";
    constant WPAIR_SADD16_SSUB16_CODE : std_logic_vector(2 downto 0) := "110";

    constant INSTR_NOP  : word_t := x"E1A00000";
    constant INSTR_DONE : word_t := x"EAFFFFFE";

    -- PROGRAM_ID = 0: FFT worker programs. Each worker has a concrete 32-bit
    -- instruction ROM image; these words are not built by an RTL encoder.
    constant FFT_ROM_W0 : program_rom_t := (
         0 => x"E3A00000", -- MOV r0, #0
         1 => x"E3A0105B", -- MOV r1, #91
         2 => x"E6813811", -- PKHBT r3, r1, r1, LSL #16
         3 => x"E6104F73", -- SSUB16 r4, r0, r3
         4 => x"E5905040", -- LDR r5, [dmem_bank0+0]
         5 => x"E5906044", -- LDR r6, [dmem_bank0+1]
         6 => x"E615AF16", -- SADD16 r10, r5, r6
         7 => x"E615BF76", -- SSUB16 r11, r5, r6
         8 => x"E580A080", -- STR r10, [dmem_bank1+0]
         9 => x"E580B084", -- STR r11, [dmem_bank1+1]
        10 => x"E5905080", -- LDR r5, [dmem_bank1+0]
        11 => x"E5906088", -- LDR r6, [dmem_bank1+2]
        12 => x"E615AF16", -- SADD16 r10, r5, r6
        13 => x"E615BF76", -- SSUB16 r11, r5, r6
        14 => x"E580A040", -- STR r10, [dmem_bank0+0]
        15 => x"E580B048", -- STR r11, [dmem_bank0+2]
        16 => INSTR_NOP,   -- NOP
        17 => x"E5905040", -- LDR r5, [dmem_bank0+0]
        18 => x"E5906050", -- LDR r6, [dmem_bank0+4]
        19 => x"E615AF16", -- SADD16 r10, r5, r6
        20 => x"E615BF76", -- SSUB16 r11, r5, r6
        21 => x"E580A080", -- STR r10, [dmem_bank1+0]
        22 => x"E580B090", -- STR r11, [dmem_bank1+4]
        23 => INSTR_NOP,   -- NOP
        24 => INSTR_NOP,   -- NOP
        25 => INSTR_NOP,   -- NOP
        26 => INSTR_NOP,   -- NOP
        others => INSTR_DONE
    );

    constant FFT_ROM_W1 : program_rom_t := (
         0 => x"E3A00000", -- MOV r0, #0
         1 => x"E3A0105B", -- MOV r1, #91
         2 => x"E6813811", -- PKHBT r3, r1, r1, LSL #16
         3 => x"E6104F73", -- SSUB16 r4, r0, r3
         4 => x"E5905048", -- LDR r5, [dmem_bank0+2]
         5 => x"E590604C", -- LDR r6, [dmem_bank0+3]
         6 => x"E615AF16", -- SADD16 r10, r5, r6
         7 => x"E615BF76", -- SSUB16 r11, r5, r6
         8 => x"E580A088", -- STR r10, [dmem_bank1+2]
         9 => x"E580B08C", -- STR r11, [dmem_bank1+3]
        10 => x"E5905084", -- LDR r5, [dmem_bank1+1]
        11 => x"E590608C", -- LDR r6, [dmem_bank1+3]
        12 => x"E6109F56", -- SSAX r9, r0, r6
        13 => x"E615AF19", -- SADD16 r10, r5, r9
        14 => x"E615BF79", -- SSUB16 r11, r5, r9
        15 => x"E580A044", -- STR r10, [dmem_bank0+1]
        16 => x"E580B04C", -- STR r11, [dmem_bank0+3]
        17 => x"E5905044", -- LDR r5, [dmem_bank0+1]
        18 => x"E5906054", -- LDR r6, [dmem_bank0+5]
        19 => x"E707F316", -- SMUAD r7, r6, r3
        20 => x"E708F456", -- SMUSD r8, r6, r4
        21 => x"E1A073C7", -- ASR r7, r7, #7
        22 => x"E6879498", -- PKHBT r9, r7, r8, LSL #9
        23 => x"E615AF19", -- SADD16 r10, r5, r9
        24 => x"E615BF79", -- SSUB16 r11, r5, r9
        25 => x"E580A084", -- STR r10, [dmem_bank1+1]
        26 => x"E580B094", -- STR r11, [dmem_bank1+5]
        others => INSTR_DONE
    );

    constant FFT_ROM_W2 : program_rom_t := (
         0 => x"E3A00000", -- MOV r0, #0
         1 => x"E3A0105B", -- MOV r1, #91
         2 => x"E6813811", -- PKHBT r3, r1, r1, LSL #16
         3 => x"E6104F73", -- SSUB16 r4, r0, r3
         4 => x"E5905050", -- LDR r5, [dmem_bank0+4]
         5 => x"E5906054", -- LDR r6, [dmem_bank0+5]
         6 => x"E615AF16", -- SADD16 r10, r5, r6
         7 => x"E615BF76", -- SSUB16 r11, r5, r6
         8 => x"E580A090", -- STR r10, [dmem_bank1+4]
         9 => x"E580B094", -- STR r11, [dmem_bank1+5]
        10 => x"E5905090", -- LDR r5, [dmem_bank1+4]
        11 => x"E5906098", -- LDR r6, [dmem_bank1+6]
        12 => x"E615AF16", -- SADD16 r10, r5, r6
        13 => x"E615BF76", -- SSUB16 r11, r5, r6
        14 => x"E580A050", -- STR r10, [dmem_bank0+4]
        15 => x"E580B058", -- STR r11, [dmem_bank0+6]
        16 => INSTR_NOP,   -- NOP
        17 => x"E5905048", -- LDR r5, [dmem_bank0+2]
        18 => x"E5906058", -- LDR r6, [dmem_bank0+6]
        19 => x"E6109F56", -- SSAX r9, r0, r6
        20 => x"E615AF19", -- SADD16 r10, r5, r9
        21 => x"E615BF79", -- SSUB16 r11, r5, r9
        22 => x"E580A088", -- STR r10, [dmem_bank1+2]
        23 => x"E580B098", -- STR r11, [dmem_bank1+6]
        24 => INSTR_NOP,   -- NOP
        25 => INSTR_NOP,   -- NOP
        26 => INSTR_NOP,   -- NOP
        others => INSTR_DONE
    );

    constant FFT_ROM_W3 : program_rom_t := (
         0 => x"E3A00000", -- MOV r0, #0
         1 => x"E3A0105B", -- MOV r1, #91
         2 => x"E6813811", -- PKHBT r3, r1, r1, LSL #16
         3 => x"E6104F73", -- SSUB16 r4, r0, r3
         4 => x"E5905058", -- LDR r5, [dmem_bank0+6]
         5 => x"E590605C", -- LDR r6, [dmem_bank0+7]
         6 => x"E615AF16", -- SADD16 r10, r5, r6
         7 => x"E615BF76", -- SSUB16 r11, r5, r6
         8 => x"E580A098", -- STR r10, [dmem_bank1+6]
         9 => x"E580B09C", -- STR r11, [dmem_bank1+7]
        10 => x"E5905094", -- LDR r5, [dmem_bank1+5]
        11 => x"E590609C", -- LDR r6, [dmem_bank1+7]
        12 => x"E6109F56", -- SSAX r9, r0, r6
        13 => x"E615AF19", -- SADD16 r10, r5, r9
        14 => x"E615BF79", -- SSUB16 r11, r5, r9
        15 => x"E580A054", -- STR r10, [dmem_bank0+5]
        16 => x"E580B05C", -- STR r11, [dmem_bank0+7]
        17 => x"E590504C", -- LDR r5, [dmem_bank0+3]
        18 => x"E590605C", -- LDR r6, [dmem_bank0+7]
        19 => x"E707F456", -- SMUSD r7, r6, r4
        20 => x"E708F416", -- SMUAD r8, r6, r4
        21 => x"E1A073C7", -- ASR r7, r7, #7
        22 => x"E6879498", -- PKHBT r9, r7, r8, LSL #9
        23 => x"E615AF19", -- SADD16 r10, r5, r9
        24 => x"E615BF79", -- SSUB16 r11, r5, r9
        25 => x"E580A08C", -- STR r10, [dmem_bank1+3]
        26 => x"E580B09C", -- STR r11, [dmem_bank1+7]
        others => INSTR_DONE
    );

    -- PROGRAM_ID = 1: single-core PPT/basic-instruction test program.
    -- Intended board mode: PROGRAM_ID=1, ACTIVE_CORES=1.
    constant SELFTEST_ROM : program_rom_t := (
         0 => x"E3A00000", -- MOV r0, #0
         1 => x"E3A01007", -- MOV r1, #7
         2 => x"E5801044", -- STR r1, [r0, #0x44] ; data[1] = MOV result
         3 => x"E3A02003", -- MOV r2, #3
         4 => x"E0813002", -- ADD r3, r1, r2
         5 => x"E5803048", -- STR r3, [r0, #0x48] ; data[2] = ADD result
         6 => x"E0434002", -- SUB r4, r3, r2
         7 => x"E580404C", -- STR r4, [r0, #0x4C] ; data[3] = SUB result
         8 => x"E0035001", -- AND r5, r3, r1
         9 => x"E5805050", -- STR r5, [r0, #0x50] ; data[4] = AND result
        10 => x"E1856002", -- ORR r6, r5, r2
        11 => x"E5806054", -- STR r6, [r0, #0x54] ; data[5] = ORR result
        12 => x"E5908040", -- LDR r8, [r0, #0x40] ; data[0] input
        13 => x"E5808058", -- STR r8, [r0, #0x58] ; data[6] = LDR result
        14 => x"E3A0B000", -- MOV r11, #0 ; branch poison accumulator
        15 => x"EA000000", -- B selftest_after_skip
        16 => x"E3A0B063", -- MOV r11, #99 ; skipped poison
        17 => x"EB000002", -- BL selftest_subroutine
        18 => x"E08AC00B", -- ADD r12, r10, r11
        19 => x"E580C05C", -- STR r12, [r0, #0x5C] ; data[7] = control-flow result
        20 => INSTR_DONE,   -- B . completion sentinel
        21 => x"E3A0A00F", -- MOV r10, #15
        22 => x"E1A0F00E", -- MOV pc, lr
        others => INSTR_DONE
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
        variable target_index : integer range -4096 to 4095;
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

        if instr_value(31 downto 20) = x"E3A"
          and instr_value(19 downto 16) = x"0"
          and instr_value(11 downto 8) = x"0" then
            op_value := WOP_MOV_IMM;
            rd_value := to_integer(unsigned(instr_value(15 downto 12)));
            imm_value := to_integer(unsigned(instr_value(7 downto 0)));
        elsif instr_value(31 downto 20) = x"E1A"
          and instr_value(19 downto 16) = x"0"
          and instr_value(6 downto 5) = "10"
          and instr_value(4) = '0' then
            op_value := WOP_ASR;
            rd_value := to_integer(unsigned(instr_value(15 downto 12)));
            rn_value := to_integer(unsigned(instr_value(3 downto 0)));
            imm_value := to_integer(unsigned(instr_value(11 downto 7)));
        elsif instr_value(31 downto 20) = x"E1A"
          and instr_value(19 downto 16) = x"0"
          and instr_value(11 downto 4) = x"00" then
            rd_value := to_integer(unsigned(instr_value(15 downto 12)));
            rm_value := to_integer(unsigned(instr_value(3 downto 0)));
            if instr_value(15 downto 12) = x"0" and instr_value(3 downto 0) = x"0" then
                op_value := WOP_NOP;
            else
                op_value := WOP_MOV_REG;
            end if;
        elsif instr_value(31 downto 20) = x"E08"
          and instr_value(11 downto 4) = x"00" then
            op_value := WOP_ADD;
            rn_value := to_integer(unsigned(instr_value(19 downto 16)));
            rd_value := to_integer(unsigned(instr_value(15 downto 12)));
            rm_value := to_integer(unsigned(instr_value(3 downto 0)));
        elsif instr_value(31 downto 20) = x"E04"
          and instr_value(11 downto 4) = x"00" then
            op_value := WOP_SUB;
            rn_value := to_integer(unsigned(instr_value(19 downto 16)));
            rd_value := to_integer(unsigned(instr_value(15 downto 12)));
            rm_value := to_integer(unsigned(instr_value(3 downto 0)));
        elsif instr_value(31 downto 20) = x"E00"
          and instr_value(11 downto 4) = x"00" then
            op_value := WOP_AND;
            rn_value := to_integer(unsigned(instr_value(19 downto 16)));
            rd_value := to_integer(unsigned(instr_value(15 downto 12)));
            rm_value := to_integer(unsigned(instr_value(3 downto 0)));
        elsif instr_value(31 downto 20) = x"E18"
          and instr_value(11 downto 4) = x"00" then
            op_value := WOP_ORR;
            rn_value := to_integer(unsigned(instr_value(19 downto 16)));
            rd_value := to_integer(unsigned(instr_value(15 downto 12)));
            rm_value := to_integer(unsigned(instr_value(3 downto 0)));
        elsif instr_value(31 downto 28) = x"E"
          and instr_value(27 downto 20) = x"68"
          and instr_value(6 downto 5) = "00"
          and instr_value(4) = '1' then
            op_value := WOP_PKHBT;
            rn_value := to_integer(unsigned(instr_value(19 downto 16)));
            rd_value := to_integer(unsigned(instr_value(15 downto 12)));
            rm_value := to_integer(unsigned(instr_value(3 downto 0)));
            imm_value := to_integer(unsigned(instr_value(11 downto 7)));
        elsif instr_value(31 downto 20) = x"E59"
          and instr_value(19 downto 16) = x"0" then
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
        elsif instr_value(31 downto 20) = x"E58"
          and instr_value(19 downto 16) = x"0" then
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
        elsif instr_value(31 downto 28) = x"E"
          and instr_value(27 downto 20) = x"61"
          and instr_value(11 downto 8) = x"F"
          and instr_value(4) = '1' then
            case instr_value(7 downto 4) is
                when x"1" =>
                    op_value := WOP_SADD16;
                when x"7" =>
                    op_value := WOP_SSUB16;
                when x"5" =>
                    op_value := WOP_SSAX;
                when others =>
                    illegal_value := '1';
            end case;
            rn_value := to_integer(unsigned(instr_value(19 downto 16)));
            rd_value := to_integer(unsigned(instr_value(15 downto 12)));
            rm_value := to_integer(unsigned(instr_value(3 downto 0)));
        elsif instr_value(31 downto 28) = x"E"
          and instr_value(27 downto 20) = x"70"
          and instr_value(15 downto 12) = x"F" then
            case instr_value(7 downto 4) is
                when x"1" =>
                    op_value := WOP_SMUAD;
                when x"5" =>
                    op_value := WOP_SMUSD;
                when others =>
                    illegal_value := '1';
            end case;
            rd_value := to_integer(unsigned(instr_value(19 downto 16)));
            rn_value := to_integer(unsigned(instr_value(3 downto 0)));
            rm_value := to_integer(unsigned(instr_value(11 downto 8)));
        elsif instr_value(31 downto 24) = x"EA"
              or instr_value(31 downto 24) = x"EB" then
            branch_off := to_integer(signed(instr_value(23 downto 0)));
            target_index := pc_value + 2 + branch_off;
            if target_index < 0 or target_index > 63 then
                illegal_value := '1';
                imm_value := 0;
            else
                imm_value := target_index * 4;
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

    function build_decode_rom(constant rom : program_rom_t) return worker_decode_rom_t is
        variable result : worker_decode_rom_t := (others => DECODE_NOP);
        variable pc_vec : std_logic_vector(5 downto 0);
        variable op_v : worker_op_t;
        variable rd_v : natural range 0 to 15;
        variable rn_v : natural range 0 to 15;
        variable rm_v : natural range 0 to 15;
        variable imm_v : integer range -4096 to 4095;
        variable idx_v : natural range 0 to 7;
        variable illegal_v : std_logic;
    begin
        for pc in 0 to 63 loop
            pc_vec := std_logic_vector(to_unsigned(pc, 6));
            decode_instr_word(
                rom(pc),
                pc_vec,
                op_v,
                rd_v,
                rn_v,
                rm_v,
                imm_v,
                idx_v,
                illegal_v
            );

            result(pc).op      := op_v;
            result(pc).rd      := rd_v;
            result(pc).rn      := rn_v;
            result(pc).rm      := rm_v;
            result(pc).imm     := imm_v;
            result(pc).idx     := idx_v;
            result(pc).illegal := illegal_v;
        end loop;

        return result;
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
    constant FFT_DEC_W0 : worker_decode_rom_t := build_decode_rom(FFT_ROM_W0);
    constant FFT_DEC_W1 : worker_decode_rom_t := build_decode_rom(FFT_ROM_W1);
    constant FFT_DEC_W2 : worker_decode_rom_t := build_decode_rom(FFT_ROM_W2);
    constant FFT_DEC_W3 : worker_decode_rom_t := build_decode_rom(FFT_ROM_W3);
    constant SELFTEST_DEC : worker_decode_rom_t := build_decode_rom(SELFTEST_ROM);
begin
    process(pc_index)
        variable pc : natural range 0 to 63;
        variable next_pc : natural range 0 to 63;
        variable instr_value : word_t;
        variable pair_value : std_logic_vector(2 downto 0);
        variable next_pair_value : std_logic_vector(2 downto 0);
        variable decode_value : worker_decode_entry_t;
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
            decode_value := SELFTEST_DEC(pc);
        else
            case WORKER_ID is
                when 0 =>
                    instr_value := FFT_ROM_W0(pc);
                    pair_value := FFT_PAIR_W0(pc);
                    next_pair_value := FFT_PAIR_W0(next_pc);
                    decode_value := FFT_DEC_W0(pc);
                when 1 =>
                    instr_value := FFT_ROM_W1(pc);
                    pair_value := FFT_PAIR_W1(pc);
                    next_pair_value := FFT_PAIR_W1(next_pc);
                    decode_value := FFT_DEC_W1(pc);
                when 2 =>
                    instr_value := FFT_ROM_W2(pc);
                    pair_value := FFT_PAIR_W2(pc);
                    next_pair_value := FFT_PAIR_W2(next_pc);
                    decode_value := FFT_DEC_W2(pc);
                when others =>
                    instr_value := FFT_ROM_W3(pc);
                    pair_value := FFT_PAIR_W3(pc);
                    next_pair_value := FFT_PAIR_W3(next_pc);
                    decode_value := FFT_DEC_W3(pc);
            end case;
        end if;

        instr <= instr_value;
        dec_op <= decode_value.op;
        dec_rd <= decode_value.rd;
        dec_rn <= decode_value.rn;
        dec_rm <= decode_value.rm;
        dec_imm <= decode_value.imm;
        dec_idx <= decode_value.idx;
        dec_illegal <= decode_value.illegal;
        pair_kind <= pair_value;
        next_pair_kind <= next_pair_value;
    end process;
end architecture rtl;
