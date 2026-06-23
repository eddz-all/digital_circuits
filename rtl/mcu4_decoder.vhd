library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.mcu4_multi_pkg.all;

entity mcu4_decoder is
    port (
        instr         : in  word_t;
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

        alu_control   : out std_logic_vector(3 downto 0);
        alu_src_imm   : out std_logic;

        ra1           : out reg_addr_t;
        ra2           : out reg_addr_t;
        wa            : out reg_addr_t;
        imm_ext       : out word_t;
        branch_offset : out word_t
    );
end entity mcu4_decoder;

architecture rtl of mcu4_decoder is
    constant OPC_AND : std_logic_vector(3 downto 0) := "0000";
    constant OPC_SUB : std_logic_vector(3 downto 0) := "0010";
    constant OPC_ADD : std_logic_vector(3 downto 0) := "0100";
    constant OPC_CMP : std_logic_vector(3 downto 0) := "1010";
    constant OPC_ORR : std_logic_vector(3 downto 0) := "1100";
    constant OPC_MOV : std_logic_vector(3 downto 0) := "1101";
begin
    process(instr, flag_z, flag_n)
        variable cond_ok_v : std_logic;
        variable illegal_v : std_logic;
        variable br_v      : signed(31 downto 0);
    begin
        cond_ok_v := '0';
        illegal_v := '0';

        reg_write    <= '0';
        mem_read     <= '0';
        mem_write    <= '0';
        mem_to_reg   <= '0';
        flag_write   <= '0';
        branch_taken <= '0';
        branch_link  <= '0';
        alu_control  <= ALU_PASS;
        alu_src_imm  <= '0';
        ra1          <= instr(19 downto 16);
        ra2          <= instr(3 downto 0);
        wa           <= instr(15 downto 12);
        imm_ext      <= std_logic_vector(resize(unsigned(instr(11 downto 0)), 32));
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
                illegal_v := '1';
        end case;

        if instr(27 downto 26) = "00" then
            alu_src_imm <= instr(25);
            if instr(25) = '1' then
                ra2 <= (others => '0');
            end if;

            case instr(24 downto 21) is
                when OPC_AND =>
                    alu_control <= ALU_AND;
                    reg_write <= cond_ok_v;
                when OPC_SUB =>
                    alu_control <= ALU_SUB;
                    reg_write <= cond_ok_v;
                when OPC_ADD =>
                    alu_control <= ALU_ADD;
                    reg_write <= cond_ok_v;
                when OPC_CMP =>
                    alu_control <= ALU_SUB;
                    flag_write <= cond_ok_v;
                    reg_write <= '0';
                    wa <= (others => '0');
                when OPC_ORR =>
                    alu_control <= ALU_ORR;
                    reg_write <= cond_ok_v;
                when OPC_MOV =>
                    alu_control <= ALU_MOV;
                    reg_write <= cond_ok_v;
                    ra1 <= (others => '0');
                when others =>
                    illegal_v := '1';
            end case;
        elsif instr(27 downto 26) = "01" then
            alu_control <= ALU_ADD;
            alu_src_imm <= '1';
            ra1 <= instr(19 downto 16);
            ra2 <= instr(15 downto 12);
            wa  <= instr(15 downto 12);

            if instr(25) /= '0' or instr(24) /= '1' or instr(23) /= '1'
               or instr(22) /= '0' or instr(21) /= '0' then
                illegal_v := '1';
            end if;

            if instr(20) = '1' then
                mem_read <= cond_ok_v;
                mem_to_reg <= cond_ok_v;
                reg_write <= cond_ok_v;
            else
                mem_write <= cond_ok_v;
            end if;
        elsif instr(27 downto 25) = "101" then
            branch_taken <= cond_ok_v;
            branch_link <= instr(24) and cond_ok_v;
        else
            illegal_v := '1';
        end if;

        if illegal_v = '1' then
            reg_write    <= '0';
            mem_read     <= '0';
            mem_write    <= '0';
            mem_to_reg   <= '0';
            flag_write   <= '0';
            branch_taken <= '0';
            branch_link  <= '0';
        end if;

        cond_ok <= cond_ok_v;
        illegal_instr <= illegal_v;
    end process;
end architecture rtl;
