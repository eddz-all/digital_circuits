library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.mcu_v1_pkg.all;

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
        branch_link   : out std_logic;
        bulk_load     : out std_logic;
        store_double  : out std_logic;
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
        branch_link   <= '0';
        bulk_load     <= '0';
        store_double  <= '0';
        bulk_writeback <= '0';
        alu_control   <= ALU_ADD;
        alu_src_imm   <= '0';

        ra1 <= instr(19 downto 16);
        ra2 <= instr(3 downto 0);
        ra3 <= instr(3 downto 0);
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
                    when OPC_AND =>
                        alu_control <= ALU_AND;
                        reg_write <= cond_ok_v;
                    when OPC_ADD =>
                        alu_control <= ALU_ADD;
                        reg_write <= cond_ok_v;
                    when OPC_SUB =>
                        alu_control <= ALU_SUB;
                        reg_write <= cond_ok_v;
                    when OPC_ORR =>
                        alu_control <= ALU_ORR;
                        reg_write <= cond_ok_v;
                    when OPC_MOV =>
                        alu_control <= ALU_MOV;
                        reg_write <= cond_ok_v;
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
                if instr(25) /= '0' then
                    illegal_v := '1';
                end if;
                branch_taken <= cond_ok_v;
                branch_link <= cond_ok_v and instr(24);
                if instr(24) = '1' then
                    reg_write <= cond_ok_v;
                    wa <= x"E";
                end if;

            when OP_EXT =>
                alu_src_imm <= '0';
                ra1 <= instr(19 downto 16);
                ra2 <= instr(3 downto 0);
                ra3 <= instr(3 downto 0);
                wa  <= instr(15 downto 12);
                reg_write <= cond_ok_v;

                case instr(25 downto 21) is
                    when EXT_SHADD16 =>
                        alu_control <= ALU_SHADD16;
                        if instr(20) /= '0' or instr(11 downto 4) /= x"00" then
                            illegal_v := '1';
                        end if;
                    when EXT_SHSUB16 =>
                        alu_control <= ALU_SHSUB16;
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
                    when EXT_SXTH =>
                        alu_control <= ALU_SXTH;
                        ra2 <= (others => '0');
                        if instr(20) /= '0' or instr(11 downto 4) /= x"00" then
                            illegal_v := '1';
                        end if;
                        if instr(3 downto 0) /= x"0" then
                            illegal_v := '1';
                        end if;
                    when EXT_PKHBT =>
                        alu_control <= ALU_PKHBT;
                        if instr(20) /= '0' or instr(11 downto 4) /= x"00" then
                            illegal_v := '1';
                        end if;
                    when EXT_LDMIA =>
                        alu_control <= ALU_ADD;
                        alu_src_imm <= '1';
                        imm_ext <= (others => '0');
                        bulk_load <= cond_ok_v;
                        mem_read <= cond_ok_v;
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
                    when EXT_STRD =>
                        alu_control <= ALU_ADD;
                        alu_src_imm <= '1';
                        imm_ext <= std_logic_vector(resize(unsigned(instr(11 downto 4)), 32));
                        ra1 <= instr(19 downto 16);
                        ra2 <= instr(15 downto 12);
                        ra3 <= instr(3 downto 0);
                        mem_write <= cond_ok_v;
                        store_double <= cond_ok_v;
                        reg_write <= '0';
                        if instr(20) /= '0' or instr(5 downto 4) /= "00" then
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
            branch_link  <= '0';
            bulk_load    <= '0';
            store_double <= '0';
            bulk_writeback <= '0';
        end if;

        cond_ok <= cond_ok_v;
        illegal_instr <= illegal_v;
    end process;
end architecture rtl;
