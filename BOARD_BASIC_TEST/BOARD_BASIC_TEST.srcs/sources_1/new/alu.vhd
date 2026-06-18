library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mcu_v1_alu is
    port (
        a           : in  std_logic_vector(31 downto 0);
        b           : in  std_logic_vector(31 downto 0);
        c           : in  std_logic_vector(31 downto 0);
        alu_control : in  std_logic_vector(3 downto 0);
        result      : out std_logic_vector(31 downto 0);
        flag_z      : out std_logic;
        flag_n      : out std_logic
    );
end entity mcu_v1_alu;

architecture rtl of mcu_v1_alu is
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

    signal result_i : std_logic_vector(31 downto 0) := (others => '0');
begin
    process(a, b, c, alu_control)
        variable mul64   : signed(63 downto 0);
        variable shamt   : natural range 0 to 31;
        variable a_lo17  : signed(16 downto 0);
        variable a_hi17  : signed(16 downto 0);
        variable b_lo17  : signed(16 downto 0);
        variable b_hi17  : signed(16 downto 0);
        variable lo17    : signed(16 downto 0);
        variable hi17    : signed(16 downto 0);
        variable prod_lo : signed(31 downto 0);
        variable prod_hi : signed(31 downto 0);
        variable sum32   : signed(31 downto 0);
    begin
        mul64   := (others => '0');
        shamt   := to_integer(unsigned(b(4 downto 0)));
        a_lo17  := resize(signed(a(15 downto 0)), 17);
        a_hi17  := resize(signed(a(31 downto 16)), 17);
        b_lo17  := resize(signed(b(15 downto 0)), 17);
        b_hi17  := resize(signed(b(31 downto 16)), 17);
        lo17    := (others => '0');
        hi17    := (others => '0');
        prod_lo := (others => '0');
        prod_hi := (others => '0');
        sum32   := (others => '0');

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
            when ALU_PKHBT =>
                result_i <= b(15 downto 0) & a(15 downto 0);
            when ALU_SADD16 =>
                lo17 := a_lo17 + b_lo17;
                hi17 := a_hi17 + b_hi17;
                result_i <= std_logic_vector(hi17(15 downto 0)) & std_logic_vector(lo17(15 downto 0));
            when ALU_SMUAD =>
                prod_lo := signed(a(15 downto 0)) * signed(b(15 downto 0));
                prod_hi := signed(a(31 downto 16)) * signed(b(31 downto 16));
                sum32 := prod_lo + prod_hi;
                result_i <= std_logic_vector(sum32);
            when ALU_SMUSD =>
                prod_lo := signed(a(15 downto 0)) * signed(b(15 downto 0));
                prod_hi := signed(a(31 downto 16)) * signed(b(31 downto 16));
                sum32 := prod_lo - prod_hi;
                result_i <= std_logic_vector(sum32);
            when ALU_SSAX =>
                lo17 := a_lo17 + b_hi17;
                hi17 := a_hi17 - b_lo17;
                result_i <= std_logic_vector(hi17(15 downto 0)) & std_logic_vector(lo17(15 downto 0));
            when ALU_SSUB16 =>
                lo17 := a_lo17 - b_lo17;
                hi17 := a_hi17 - b_hi17;
                result_i <= std_logic_vector(hi17(15 downto 0)) & std_logic_vector(lo17(15 downto 0));
            when ALU_SMLAD =>
                prod_lo := signed(a(15 downto 0)) * signed(b(15 downto 0));
                prod_hi := signed(a(31 downto 16)) * signed(b(31 downto 16));
                sum32 := prod_lo + prod_hi + signed(c);
                result_i <= std_logic_vector(sum32);
            when others =>
                result_i <= (others => '0');
        end case;
    end process;

    result <= result_i;
    flag_z <= '1' when result_i = x"00000000" else '0';
    flag_n <= result_i(31);
end architecture rtl;
