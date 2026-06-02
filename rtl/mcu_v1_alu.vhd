library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mcu_v1_alu is
    port (
        a           : in  std_logic_vector(31 downto 0);
        b           : in  std_logic_vector(31 downto 0);
        alu_control : in  std_logic_vector(2 downto 0);
        result      : out std_logic_vector(31 downto 0);
        flag_z      : out std_logic;
        flag_n      : out std_logic
    );
end entity mcu_v1_alu;

architecture rtl of mcu_v1_alu is
    constant ALU_AND : std_logic_vector(2 downto 0) := "000";
    constant ALU_ORR : std_logic_vector(2 downto 0) := "001";
    constant ALU_ADD : std_logic_vector(2 downto 0) := "010";
    constant ALU_SUB : std_logic_vector(2 downto 0) := "011";
    constant ALU_MUL : std_logic_vector(2 downto 0) := "100";
    constant ALU_ASR : std_logic_vector(2 downto 0) := "101";
    constant ALU_MOV : std_logic_vector(2 downto 0) := "110";

    signal result_i : std_logic_vector(31 downto 0) := (others => '0');
begin
    process(a, b, alu_control)
        variable mul64 : signed(63 downto 0);
        variable shamt : natural range 0 to 31;
    begin
        mul64 := (others => '0');
        shamt := to_integer(unsigned(b(4 downto 0)));

        case alu_control is
            when ALU_AND =>
                result_i <= a and b;
            when ALU_ORR =>
                result_i <= a or b;
            when ALU_ADD =>
                result_i <= std_logic_vector(signed(a) + signed(b));
            when ALU_SUB =>
                result_i <= std_logic_vector(signed(a) - signed(b));
            when ALU_MUL =>
                mul64 := signed(a) * signed(b);
                result_i <= std_logic_vector(mul64(31 downto 0));
            when ALU_ASR =>
                result_i <= std_logic_vector(shift_right(signed(a), shamt));
            when ALU_MOV =>
                result_i <= b;
            when others =>
                result_i <= (others => '0');
        end case;
    end process;

    result <= result_i;
    flag_z <= '1' when result_i = x"00000000" else '0';
    flag_n <= result_i(31);
end architecture rtl;
