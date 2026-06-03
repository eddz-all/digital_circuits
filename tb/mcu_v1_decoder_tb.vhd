library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.mcu_v1_pkg.all;

entity mcu_v1_decoder_tb is
end entity mcu_v1_decoder_tb;

architecture sim of mcu_v1_decoder_tb is
    signal instr         : std_logic_vector(31 downto 0) := (others => '0');
    signal flag_z        : std_logic := '0';
    signal flag_n        : std_logic := '0';
    signal cond_ok       : std_logic;
    signal illegal_instr : std_logic;
    signal reg_write     : std_logic;
    signal mem_read      : std_logic;
    signal mem_write     : std_logic;
    signal mem_to_reg    : std_logic;
    signal flag_write    : std_logic;
    signal branch_taken  : std_logic;
    signal branch_link   : std_logic;
    signal bulk_load     : std_logic;
    signal store_double  : std_logic;
    signal bulk_writeback : std_logic;
    signal alu_control   : std_logic_vector(3 downto 0);
    signal alu_src_imm   : std_logic;
    signal ra1           : std_logic_vector(3 downto 0);
    signal ra2           : std_logic_vector(3 downto 0);
    signal ra3           : std_logic_vector(3 downto 0);
    signal wa            : std_logic_vector(3 downto 0);
    signal bulk_regmask  : std_logic_vector(15 downto 0);
    signal imm_ext       : std_logic_vector(31 downto 0);
    signal branch_offset : std_logic_vector(31 downto 0);
begin
    dut : entity work.mcu_v1_decoder
        port map (
            instr         => instr,
            flag_z        => flag_z,
            flag_n        => flag_n,
            cond_ok       => cond_ok,
            illegal_instr => illegal_instr,
            reg_write     => reg_write,
            mem_read      => mem_read,
            mem_write     => mem_write,
            mem_to_reg    => mem_to_reg,
            flag_write    => flag_write,
            branch_taken  => branch_taken,
            branch_link   => branch_link,
            bulk_load     => bulk_load,
            store_double  => store_double,
            bulk_writeback => bulk_writeback,
            alu_control   => alu_control,
            alu_src_imm   => alu_src_imm,
            ra1           => ra1,
            ra2           => ra2,
            ra3           => ra3,
            wa            => wa,
            bulk_regmask  => bulk_regmask,
            imm_ext       => imm_ext,
            branch_offset => branch_offset
        );

    stim : process
    begin
        -- MOV R8, #0
        instr <= x"E3A08000";
        flag_z <= '0';
        wait for 1 ns;
        assert illegal_instr = '0' report "MOV should be legal" severity failure;
        assert cond_ok = '1' report "MOV AL condition should pass" severity failure;
        assert reg_write = '1' report "MOV should write register" severity failure;
        assert alu_control = ALU_MOV report "MOV ALU control mismatch" severity failure;
        assert alu_src_imm = '1' report "MOV immediate should select imm" severity failure;
        assert wa = x"8" report "MOV destination should be R8" severity failure;
        assert imm_ext = x"00000000" report "MOV imm_ext mismatch" severity failure;

        -- AND R6, R6, R7
        instr <= x"E0066007";
        wait for 1 ns;
        assert illegal_instr = '0' report "AND should be legal" severity failure;
        assert reg_write = '1' report "AND should write register" severity failure;
        assert alu_control = ALU_AND report "AND ALU control mismatch" severity failure;
        assert alu_src_imm = '0' report "AND should use register operand2" severity failure;
        assert ra1 = x"6" report "AND first source should be R6" severity failure;
        assert ra2 = x"7" report "AND second source should be R7" severity failure;
        assert wa = x"6" report "AND destination should be R6" severity failure;

        -- ORR R7, R6, #3
        instr <= x"E3867003";
        wait for 1 ns;
        assert illegal_instr = '0' report "ORR should be legal" severity failure;
        assert reg_write = '1' report "ORR should write register" severity failure;
        assert alu_control = ALU_ORR report "ORR ALU control mismatch" severity failure;
        assert alu_src_imm = '1' report "ORR immediate should select imm" severity failure;
        assert ra1 = x"6" report "ORR source should be R6" severity failure;
        assert wa = x"7" report "ORR destination should be R7" severity failure;
        assert imm_ext = x"00000003" report "ORR imm12 mismatch" severity failure;

        -- SHADD16 R8, R0, R4
        instr <= x"EC008004";
        wait for 1 ns;
        assert illegal_instr = '0' report "SHADD16 should be legal" severity failure;
        assert reg_write = '1' report "SHADD16 should write register" severity failure;
        assert alu_control = ALU_SHADD16 report "SHADD16 ALU control mismatch" severity failure;
        assert ra1 = x"0" and ra2 = x"4" and wa = x"8"
            report "SHADD16 register fields mismatch" severity failure;

        -- SHSUB16 R4, R0, R4
        instr <= x"EC204004";
        wait for 1 ns;
        assert illegal_instr = '0' report "SHSUB16 should be legal" severity failure;
        assert alu_control = ALU_SHSUB16 report "SHSUB16 ALU control mismatch" severity failure;
        assert ra1 = x"0" and ra2 = x"4" and wa = x"4"
            report "SHSUB16 register fields mismatch" severity failure;

        -- SMUAD R8, R5, R12
        instr <= x"EC45800C";
        wait for 1 ns;
        assert illegal_instr = '0' report "SMUAD should be legal" severity failure;
        assert alu_control = ALU_SMUAD report "SMUAD ALU control mismatch" severity failure;
        assert ra1 = x"5" and ra2 = x"C" and wa = x"8"
            report "SMUAD register fields mismatch" severity failure;

        -- SMUSD R9, R5, R12
        instr <= x"EC65900C";
        wait for 1 ns;
        assert illegal_instr = '0' report "SMUSD should be legal" severity failure;
        assert alu_control = ALU_SMUSD report "SMUSD ALU control mismatch" severity failure;
        assert ra1 = x"5" and ra2 = x"C" and wa = x"9"
            report "SMUSD register fields mismatch" severity failure;

        -- SXTH R8, R6
        instr <= x"EC868000";
        wait for 1 ns;
        assert illegal_instr = '0' report "SXTH should be legal" severity failure;
        assert alu_control = ALU_SXTH report "SXTH ALU control mismatch" severity failure;
        assert ra1 = x"6" and wa = x"8"
            report "SXTH register fields mismatch" severity failure;

        -- PKHBT R5, R8, R9, LSL #16
        instr <= x"ECA85009";
        wait for 1 ns;
        assert illegal_instr = '0' report "PKHBT should be legal" severity failure;
        assert alu_control = ALU_PKHBT report "PKHBT ALU control mismatch" severity failure;
        assert ra1 = x"8" and ra2 = x"9" and wa = x"5"
            report "PKHBT register fields mismatch" severity failure;

        -- SSAX R6, R13, R6
        instr <= x"ED0D6006";
        wait for 1 ns;
        assert illegal_instr = '0' report "SSAX should be legal" severity failure;
        assert reg_write = '1' report "SSAX should write register" severity failure;
        assert alu_control = ALU_SSAX report "SSAX ALU control mismatch" severity failure;
        assert ra1 = x"D" and ra2 = x"6" and wa = x"6"
            report "SSAX register fields mismatch" severity failure;

        -- SSUB16 R14, R13, R12
        instr <= x"ED2DE00C";
        wait for 1 ns;
        assert illegal_instr = '0' report "SSUB16 should be legal" severity failure;
        assert reg_write = '1' report "SSUB16 should write register" severity failure;
        assert alu_control = ALU_SSUB16 report "SSUB16 ALU control mismatch" severity failure;
        assert ra1 = x"D" and ra2 = x"C" and wa = x"E"
            report "SSUB16 register fields mismatch" severity failure;

        -- LDMIA R14!, {R0-R7}
        instr <= x"ECDE00FF";
        wait for 1 ns;
        assert illegal_instr = '0' report "LDMIA should be legal" severity failure;
        assert bulk_load = '1' report "LDMIA should request bulk load" severity failure;
        assert bulk_writeback = '1' report "LDMIA should request writeback" severity failure;
        assert reg_write = '1' report "LDMIA should write back base" severity failure;
        assert mem_read = '1' report "LDMIA should read memory" severity failure;
        assert alu_src_imm = '1' and imm_ext = x"00000000"
            report "LDMIA address should use zero offset" severity failure;
        assert ra1 = x"E" and wa = x"E" and bulk_regmask = x"00FF"
            report "LDMIA fields mismatch" severity failure;

        -- STRD R0, R8, [R10 + 0]
        instr <= x"ECEA0008";
        wait for 1 ns;
        assert illegal_instr = '0' report "STRD should be legal" severity failure;
        assert store_double = '1' report "STRD should request double store" severity failure;
        assert mem_write = '1' report "STRD should write memory" severity failure;
        assert reg_write = '0' report "STRD should not write registers" severity failure;
        assert alu_src_imm = '1' and imm_ext = x"00000000"
            report "STRD offset mismatch" severity failure;
        assert ra1 = x"A" and ra2 = x"0" and ra3 = x"8"
            report "STRD register fields mismatch" severity failure;

        -- ADD R12, R12, #4095
        instr <= x"E28CCFFF";
        wait for 1 ns;
        assert illegal_instr = '0' report "ADD should be legal" severity failure;
        assert reg_write = '1' report "ADD should write register" severity failure;
        assert alu_control = ALU_ADD report "ADD ALU control mismatch" severity failure;
        assert alu_src_imm = '1' report "ADD immediate should select imm" severity failure;
        assert ra1 = x"C" report "ADD source should be R12" severity failure;
        assert wa = x"C" report "ADD destination should be R12" severity failure;
        assert imm_ext = x"00000FFF" report "ADD imm12 mismatch" severity failure;

        -- LDR R0, [R8 + 4]
        instr <= x"E7080004";
        wait for 1 ns;
        assert illegal_instr = '0' report "LDR should be legal" severity failure;
        assert reg_write = '1' report "LDR should write register" severity failure;
        assert mem_read = '1' report "LDR should read memory" severity failure;
        assert mem_to_reg = '1' report "LDR should select memory result" severity failure;
        assert mem_write = '0' report "LDR should not write memory" severity failure;
        assert alu_control = ALU_ADD report "LDR address should use ADD" severity failure;
        assert alu_src_imm = '1' report "LDR should select immediate offset" severity failure;
        assert ra1 = x"8" report "LDR base should be R8" severity failure;
        assert wa = x"0" report "LDR destination should be R0" severity failure;
        assert imm_ext = x"00000004" report "LDR offset mismatch" severity failure;

        -- STR R0, [R10 + 60]
        instr <= x"E50A003C";
        wait for 1 ns;
        assert illegal_instr = '0' report "STR should be legal" severity failure;
        assert reg_write = '0' report "STR should not write register" severity failure;
        assert mem_read = '0' report "STR should not read memory" severity failure;
        assert mem_write = '1' report "STR should write memory" severity failure;
        assert alu_control = ALU_ADD report "STR address should use ADD" severity failure;
        assert alu_src_imm = '1' report "STR should select immediate offset" severity failure;
        assert ra1 = x"A" report "STR base should be R10" severity failure;
        assert ra2 = x"0" report "STR data source should be Rd/R0" severity failure;
        assert imm_ext = x"0000003C" report "STR offset mismatch" severity failure;

        -- MUL R11, R11, R12
        instr <= x"E12BB00C";
        wait for 1 ns;
        assert illegal_instr = '0' report "MUL should be legal" severity failure;
        assert reg_write = '1' report "MUL should write register" severity failure;
        assert alu_control = ALU_MUL report "MUL ALU control mismatch" severity failure;
        assert alu_src_imm = '0' report "MUL should use register operand2" severity failure;
        assert ra1 = x"B" report "MUL first source should be R11" severity failure;
        assert ra2 = x"C" report "MUL second source should be R12" severity failure;
        assert wa = x"B" report "MUL destination should be R11" severity failure;

        -- ASR R11, R11, #15
        instr <= x"E3EBB00F";
        wait for 1 ns;
        assert illegal_instr = '0' report "ASR should be legal" severity failure;
        assert reg_write = '1' report "ASR should write register" severity failure;
        assert alu_control = ALU_ASR report "ASR ALU control mismatch" severity failure;
        assert alu_src_imm = '1' report "ASR should use immediate shift" severity failure;
        assert ra1 = x"B" report "ASR source should be R11" severity failure;
        assert wa = x"B" report "ASR destination should be R11" severity failure;
        assert imm_ext = x"0000000F" report "ASR shift mismatch" severity failure;

        -- CMP R1, #0
        instr <= x"E3510000";
        wait for 1 ns;
        assert illegal_instr = '0' report "CMP should be legal" severity failure;
        assert reg_write = '0' report "CMP should not write register" severity failure;
        assert flag_write = '1' report "CMP should write flags" severity failure;
        assert alu_control = ALU_SUB report "CMP should use SUB" severity failure;
        assert alu_src_imm = '1' report "CMP immediate should select imm" severity failure;
        assert ra1 = x"1" report "CMP source should be R1" severity failure;
        assert imm_ext = x"00000000" report "CMP immediate mismatch" severity failure;

        -- B DONE encoded as imm24 = -2. PC unit must add PC + 8 outside decoder.
        instr <= x"E8FFFFFE";
        flag_z <= '0';
        wait for 1 ns;
        assert illegal_instr = '0' report "B should be legal" severity failure;
        assert branch_taken = '1' report "B AL should branch" severity failure;
        assert branch_offset = x"FFFFFFF8" report "B offset should be -8" severity failure;
        assert branch_link = '0' report "B should not link" severity failure;
        assert reg_write = '0' and mem_read = '0' and mem_write = '0'
            report "B should have no register/memory side effects" severity failure;

        -- BL DONE encoded as imm24 = -2 and link bit = 1.
        instr <= x"E9FFFFFE";
        flag_z <= '0';
        wait for 1 ns;
        assert illegal_instr = '0' report "BL should be legal" severity failure;
        assert branch_taken = '1' report "BL AL should branch" severity failure;
        assert branch_link = '1' report "BL should request link write" severity failure;
        assert reg_write = '1' report "BL should write link register" severity failure;
        assert wa = x"E" report "BL should write R14" severity failure;
        assert branch_offset = x"FFFFFFF8" report "BL offset should be -8" severity failure;

        -- BEQ with Z = 0 should not branch.
        instr <= x"08FFFFFE";
        flag_z <= '0';
        wait for 1 ns;
        assert illegal_instr = '0' report "BEQ should be legal" severity failure;
        assert cond_ok = '0' report "BEQ condition should fail when Z=0" severity failure;
        assert branch_taken = '0' report "BEQ should not branch when Z=0" severity failure;

        -- BEQ with Z = 1 should branch.
        flag_z <= '1';
        wait for 1 ns;
        assert cond_ok = '1' report "BEQ condition should pass when Z=1" severity failure;
        assert branch_taken = '1' report "BEQ should branch when Z=1" severity failure;

        -- BNE with Z = 1 should not branch; with Z = 0 should branch.
        instr <= x"18FFFFFE";
        flag_z <= '1';
        wait for 1 ns;
        assert cond_ok = '0' report "BNE condition should fail when Z=1" severity failure;
        assert branch_taken = '0' report "BNE should not branch when Z=1" severity failure;
        flag_z <= '0';
        wait for 1 ns;
        assert cond_ok = '1' report "BNE condition should pass when Z=0" severity failure;
        assert branch_taken = '1' report "BNE should branch when Z=0" severity failure;

        -- Illegal example: ASR register form is not supported in the first version.
        instr <= x"E1E11002";
        wait for 1 ns;
        assert illegal_instr = '1' report "ASR register form should be illegal" severity failure;
        assert reg_write = '0' and mem_read = '0' and mem_write = '0' and branch_taken = '0' and branch_link = '0'
            report "Illegal instruction should have no side effects" severity failure;

        -- Illegal example: extension reserved bit 20 must be zero.
        instr <= x"EC100000";
        wait for 1 ns;
        assert illegal_instr = '1' report "Extension reserved bit should be illegal" severity failure;
        assert reg_write = '0' and mem_read = '0' and mem_write = '0'
            and branch_taken = '0' and branch_link = '0'
            report "Illegal extension should have no side effects" severity failure;

        -- Illegal example: SSAX reserved bit 20 must be zero.
        instr <= x"ED1D6006";
        wait for 1 ns;
        assert illegal_instr = '1' report "SSAX reserved bit should be illegal" severity failure;
        assert reg_write = '0' and mem_read = '0' and mem_write = '0'
            and branch_taken = '0' and branch_link = '0'
            report "Illegal SSAX should have no side effects" severity failure;

        -- Illegal example: LDMIA writeback base cannot appear in reglist.
        instr <= x"ECDE4000";
        wait for 1 ns;
        assert illegal_instr = '1' report "LDMIA base-in-reglist should be illegal" severity failure;
        assert reg_write = '0' and mem_read = '0' and bulk_load = '0' and bulk_writeback = '0'
            report "Illegal LDMIA should have no side effects" severity failure;

        report "mcu_v1_decoder_tb passed" severity note;
        wait;
    end process;
end architecture sim;
