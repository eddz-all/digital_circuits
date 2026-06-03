library ieee;
use ieee.std_logic_1164.all;

package mcu_v1_pkg is
    constant ALU_AND     : std_logic_vector(3 downto 0) := "0000";
    constant ALU_ORR     : std_logic_vector(3 downto 0) := "0001";
    constant ALU_ADD     : std_logic_vector(3 downto 0) := "0010";
    constant ALU_SUB     : std_logic_vector(3 downto 0) := "0011";
    constant ALU_MUL     : std_logic_vector(3 downto 0) := "0100";
    constant ALU_ASR     : std_logic_vector(3 downto 0) := "0101";
    constant ALU_MOV     : std_logic_vector(3 downto 0) := "0110";
    constant ALU_SHADD16 : std_logic_vector(3 downto 0) := "0111";
    constant ALU_SHSUB16 : std_logic_vector(3 downto 0) := "1000";
    constant ALU_SMUAD   : std_logic_vector(3 downto 0) := "1001";
    constant ALU_SMUSD   : std_logic_vector(3 downto 0) := "1010";
    constant ALU_SXTH    : std_logic_vector(3 downto 0) := "1011";
    constant ALU_PKHBT   : std_logic_vector(3 downto 0) := "1100";
    constant ALU_SSAX    : std_logic_vector(3 downto 0) := "1101";
    constant ALU_SSUB16  : std_logic_vector(3 downto 0) := "1110";
    constant ALU_SMLAD   : std_logic_vector(3 downto 0) := "1111";

    constant COND_EQ : std_logic_vector(3 downto 0) := "0000";
    constant COND_NE : std_logic_vector(3 downto 0) := "0001";
    constant COND_AL : std_logic_vector(3 downto 0) := "1110";

    constant OP_DATA   : std_logic_vector(1 downto 0) := "00";
    constant OP_MEM    : std_logic_vector(1 downto 0) := "01";
    constant OP_BRANCH : std_logic_vector(1 downto 0) := "10";
    constant OP_EXT    : std_logic_vector(1 downto 0) := "11";

    constant OPC_AND : std_logic_vector(3 downto 0) := "0000";
    constant OPC_ADD : std_logic_vector(3 downto 0) := "0100";
    constant OPC_SUB : std_logic_vector(3 downto 0) := "0010";
    constant OPC_MUL : std_logic_vector(3 downto 0) := "1001";
    constant OPC_CMP : std_logic_vector(3 downto 0) := "1010";
    constant OPC_ORR : std_logic_vector(3 downto 0) := "1100";
    constant OPC_MOV : std_logic_vector(3 downto 0) := "1101";
    constant OPC_ASR : std_logic_vector(3 downto 0) := "1111";

    constant EXT_SHADD16 : std_logic_vector(4 downto 0) := "00000";
    constant EXT_SHSUB16 : std_logic_vector(4 downto 0) := "00001";
    constant EXT_SMUAD   : std_logic_vector(4 downto 0) := "00010";
    constant EXT_SMUSD   : std_logic_vector(4 downto 0) := "00011";
    constant EXT_SXTH    : std_logic_vector(4 downto 0) := "00100";
    constant EXT_PKHBT   : std_logic_vector(4 downto 0) := "00101";
    constant EXT_LDMIA   : std_logic_vector(4 downto 0) := "00110";
    constant EXT_STRD    : std_logic_vector(4 downto 0) := "00111";
    constant EXT_SSAX    : std_logic_vector(4 downto 0) := "01000";
    constant EXT_SSUB16  : std_logic_vector(4 downto 0) := "01001";
    constant EXT_SMLAD   : std_logic_vector(4 downto 0) := "01010";
    constant EXT_STMIA   : std_logic_vector(4 downto 0) := "01011";

    constant REGION_INPUT  : std_logic_vector(1 downto 0) := "00";
    constant REGION_WORK   : std_logic_vector(1 downto 0) := "01";
    constant REGION_OUTPUT : std_logic_vector(1 downto 0) := "10";
end package mcu_v1_pkg;
