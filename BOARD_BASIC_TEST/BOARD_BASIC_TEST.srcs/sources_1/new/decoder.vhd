library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mcu_v1_decoder is
    port (
        instr         : in  std_logic_vector(31 downto 0);
        flag_z        : in  std_logic;
        flag_n        : in  std_logic;

        cond_ok       : out std_logic;
        illegal_instr : out std_logic;

        reg_write     : out std_logic;
        mem_read      : out std_logic;
        mem_write     : out std_logic;
        mem_to_reg    : out std_logic;
        flag_write    : out std_logic;
        branch_taken  : out std_logic;
        bulk_store    : out std_logic;
        bulk_writeback : out std_logic;

        alu_control   : out std_logic_vector(3 downto 0);
        alu_src_imm   : out std_logic;

        ra1           : out std_logic_vector(3 downto 0);
        ra2           : out std_logic_vector(3 downto 0);
        ra3           : out std_logic_vector(3 downto 0);
        wa            : out std_logic_vector(3 downto 0);
        bulk_regmask  : out std_logic_vector(15 downto 0);

        imm_ext       : out std_logic_vector(31 downto 0);
        branch_offset : out std_logic_vector(31 downto 0)
    );
end entity mcu_v1_decoder;

architecture rtl of mcu_v1_decoder is
    constant ALU_AND   : std_logic_vector(3 downto 0) := "0000";
    constant ALU_ORR   : std_logic_vector(3 downto 0) := "0001";
    constant ALU_ADD   : std_logic_vector(3 downto 0) := "0010";
    constant ALU_SUB   : std_logic_vector(3 downto 0) := "0011";
    constant ALU_MUL   : std_logic_vector(3 downto 0) := "0100";
    constant ALU_ASR   : std_logic_vector(3 downto 0) := "0101";
    constant ALU_MOV   : std_logic_vector(3 downto 0) := "0110";
    constant ALU_PKHBT : std_logic_vector(3 downto 0) := "0111";
    constant ALU_SMLAD : std_logic_vector(3 downto 0) := "1000";
    constant ALU_SADD16 : std_logic_vector(3 downto 0) := "1001";
    constant ALU_SMUAD  : std_logic_vector(3 downto 0) := "1010";
    constant ALU_SMUSD  : std_logic_vector(3 downto 0) := "1011";
    constant ALU_SSAX   : std_logic_vector(3 downto 0) := "1100";
    constant ALU_SSUB16 : std_logic_vector(3 downto 0) := "1101";
    constant ALU_LSL    : std_logic_vector(3 downto 0) := "1110";

    constant COND_EQ : std_logic_vector(3 downto 0) := "0000";
    constant COND_NE : std_logic_vector(3 downto 0) := "0001";
    constant COND_AL : std_logic_vector(3 downto 0) := "1110";

    constant OP_DATA   : std_logic_vector(1 downto 0) := "00";
    constant OP_MEM    : std_logic_vector(1 downto 0) := "01";
    constant OP_BRANCH : std_logic_vector(1 downto 0) := "10";
    constant OP_EXT    : std_logic_vector(1 downto 0) := "11";

    constant OPC_ADD : std_logic_vector(3 downto 0) := "0100";
    constant OPC_SUB : std_logic_vector(3 downto 0) := "0010";
    constant OPC_MOV : std_logic_vector(3 downto 0) := "1101";
    constant OPC_CMP : std_logic_vector(3 downto 0) := "1010";
    constant OPC_MUL : std_logic_vector(3 downto 0) := "1001";
    constant OPC_ASR : std_logic_vector(3 downto 0) := "1111";

    constant EXT_SMUAD  : std_logic_vector(4 downto 0) := "00010";
    constant EXT_SMUSD  : std_logic_vector(4 downto 0) := "00011";
    constant EXT_PKHBT : std_logic_vector(4 downto 0) := "00101";
    constant EXT_SSAX   : std_logic_vector(4 downto 0) := "01000";
    constant EXT_SSUB16 : std_logic_vector(4 downto 0) := "01001";
    constant EXT_SMLAD : std_logic_vector(4 downto 0) := "01010";
    constant EXT_STMIA : std_logic_vector(4 downto 0) := "01011";
    constant EXT_SADD16 : std_logic_vector(4 downto 0) := "01100";
begin
    process(instr, flag_z, flag_n)
        variable cond_ok_v : std_logic;
        variable illegal_v : std_logic;
        variable br_v      : signed(31 downto 0);
        variable rn_index  : natural range 0 to 15;
    begin
        cond_ok_v := '0';
        illegal_v := '0';
        rn_index := to_integer(unsigned(instr(19 downto 16)));

        reg_write     <= '0';
        mem_read      <= '0';
        mem_write     <= '0';
        mem_to_reg    <= '0';
        flag_write    <= '0';
        branch_taken  <= '0';
        bulk_store    <= '0';
        bulk_writeback <= '0';
        alu_control   <= ALU_ADD;
        alu_src_imm   <= '0';

        ra1 <= instr(19 downto 16);
        ra2 <= instr(3 downto 0);
        ra3 <= instr(11 downto 8);
        wa  <= instr(15 downto 12);
        bulk_regmask <= (others => '0');

        imm_ext <= std_logic_vector(resize(unsigned(instr(11 downto 0)), 32));
        br_v := shift_left(resize(signed(instr(23 downto 0)), 32), 2);
        branch_offset <= std_logic_vector(br_v);

        case instr(31 downto 28) is
            when COND_AL =>
                cond_ok_v := '1';
            when COND_EQ =>
                cond_ok_v := flag_z;
            when COND_NE =>
                cond_ok_v := not flag_z;
            when others =>
                cond_ok_v := '0';
                illegal_v := '1';
        end case;

        case instr(27 downto 26) is
            when OP_DATA =>
                alu_src_imm <= instr(25);
                if instr(25) = '1' then
                    ra2 <= (others => '0');
                else
                    ra2 <= instr(3 downto 0);
                end if;

                if instr(20) = '1' and instr(24 downto 21) /= OPC_CMP then
                    illegal_v := '1';
                end if;

                case instr(24 downto 21) is
                    when OPC_ADD =>
                        alu_control <= ALU_ADD;
                        reg_write <= cond_ok_v;
                    when OPC_SUB =>
                        alu_control <= ALU_SUB;
                        reg_write <= cond_ok_v;
                    when OPC_MOV =>
                        alu_control <= ALU_MOV;
                        reg_write <= cond_ok_v;
                        if instr(25) = '0' and instr(11 downto 4) /= x"00" then
                            if instr(6 downto 5) = "00" and instr(4) = '0' then
                                alu_control <= ALU_LSL;
                                alu_src_imm <= '1';
                                ra1 <= instr(3 downto 0);
                                ra2 <= (others => '0');
                                imm_ext <= std_logic_vector(resize(unsigned(instr(11 downto 7)), 32));
                            else
                                illegal_v := '1';
                            end if;
                        end if;
                    when OPC_CMP =>
                        alu_control <= ALU_SUB;
                        flag_write <= cond_ok_v;
                        reg_write <= '0';
                        wa <= (others => '0');
                        if instr(20) /= '1' then
                            illegal_v := '1';
                        end if;
                    when OPC_MUL =>
                        alu_control <= ALU_MUL;
                        reg_write <= cond_ok_v;
                        if instr(25) /= '0' then
                            illegal_v := '1';
                        end if;
                    when OPC_ASR =>
                        alu_control <= ALU_ASR;
                        alu_src_imm <= '1';
                        ra2 <= (others => '0');
                        reg_write <= cond_ok_v;
                        if instr(25) /= '1' then
                            illegal_v := '1';
                        end if;
                    when others =>
                        illegal_v := '1';
                end case;

            when OP_MEM =>
                alu_control <= ALU_ADD;
                alu_src_imm <= '1';
                ra1 <= instr(19 downto 16);
                wa  <= instr(15 downto 12);
                ra2 <= instr(15 downto 12);

                if instr(24) /= '1' or instr(23 downto 20) /= "0000" then
                    illegal_v := '1';
                end if;

                if instr(25) = '1' then
                    mem_read   <= cond_ok_v;
                    reg_write  <= cond_ok_v;
                    mem_to_reg <= cond_ok_v;
                    ra2 <= (others => '0');
                else
                    mem_write <= cond_ok_v;
                end if;

            when OP_BRANCH =>
                if instr(25 downto 24) /= "00" then
                    illegal_v := '1';
                end if;
                branch_taken <= cond_ok_v;

            when OP_EXT =>
                alu_src_imm <= '0';
                ra1 <= instr(19 downto 16);
                ra2 <= instr(3 downto 0);
                ra3 <= instr(11 downto 8);
                wa  <= instr(15 downto 12);
                reg_write <= cond_ok_v;

                case instr(25 downto 21) is
                    when EXT_SADD16 =>
                        alu_control <= ALU_SADD16;
                        if instr(20) /= '0' or instr(11 downto 4) /= x"00" then
                            illegal_v := '1';
                        end if;
                    when EXT_SMUAD =>
                        alu_control <= ALU_SMUAD;
                        if instr(20) /= '0' or instr(11 downto 4) /= x"00" then
                            illegal_v := '1';
                        end if;
                    when EXT_SMUSD =>
                        alu_control <= ALU_SMUSD;
                        if instr(20) /= '0' or instr(11 downto 4) /= x"00" then
                            illegal_v := '1';
                        end if;
                    when EXT_PKHBT =>
                        alu_control <= ALU_PKHBT;
                        imm_ext <= std_logic_vector(resize(unsigned(instr(11 downto 7)), 32));
                        ra3 <= (others => '0');
                        if instr(20) /= '0' or instr(6 downto 4) /= "000" then
                            illegal_v := '1';
                        end if;
                    when EXT_SSAX =>
                        alu_control <= ALU_SSAX;
                        if instr(20) /= '0' or instr(11 downto 4) /= x"00" then
                            illegal_v := '1';
                        end if;
                    when EXT_SSUB16 =>
                        alu_control <= ALU_SSUB16;
                        if instr(20) /= '0' or instr(11 downto 4) /= x"00" then
                            illegal_v := '1';
                        end if;
                    when EXT_SMLAD =>
                        alu_control <= ALU_SMLAD;
                        if instr(20) /= '0' or instr(7 downto 4) /= x"0" then
                            illegal_v := '1';
                        end if;
                    when EXT_STMIA =>
                        alu_control <= ALU_ADD;
                        alu_src_imm <= '1';
                        imm_ext <= (others => '0');
                        mem_write <= cond_ok_v;
                        bulk_store <= cond_ok_v;
                        reg_write <= cond_ok_v and instr(20);
                        bulk_writeback <= cond_ok_v and instr(20);
                        wa <= instr(19 downto 16);
                        bulk_regmask <= instr(15 downto 0);
                        if instr(20) /= '1'
                            or instr(15 downto 0) = x"0000"
                            or instr(15) = '1'
                            or instr(rn_index) = '1' then
                            illegal_v := '1';
                        end if;
                    when others =>
                        illegal_v := '1';
                end case;

            when others =>
                illegal_v := '1';
        end case;

        if illegal_v = '1' then
            reg_write    <= '0';
            mem_read     <= '0';
            mem_write    <= '0';
            mem_to_reg   <= '0';
            flag_write   <= '0';
            branch_taken <= '0';
            bulk_store   <= '0';
            bulk_writeback <= '0';
        end if;

        cond_ok <= cond_ok_v;
        illegal_instr <= illegal_v;
    end process;
end architecture rtl;
