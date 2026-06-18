library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.mcu_8core_dsp_pkg.all;

entity mcu_8core_decoder is
    port (
        instr      : in  word_t;
        op         : out std_logic_vector(3 downto 0);
        rd         : out std_logic_vector(3 downto 0);
        rn         : out std_logic_vector(3 downto 0);
        rm         : out std_logic_vector(3 downto 0);
        ra         : out std_logic_vector(3 downto 0);
        imm_ext    : out word_t;
        sat_bits   : out std_logic_vector(7 downto 0);
        known_op   : out std_logic
    );
end entity mcu_8core_decoder;

architecture rtl of mcu_8core_decoder is
begin
    process(instr)
        variable op_v : std_logic_vector(3 downto 0);
    begin
        op_v := instr(31 downto 28);

        op <= op_v;
        rd <= instr(27 downto 24);
        rn <= instr(23 downto 20);
        rm <= instr(19 downto 16);
        ra <= instr(15 downto 12);
        imm_ext <= std_logic_vector(resize(signed(instr(15 downto 0)), 32));
        sat_bits <= instr(15 downto 8);

        case op_v is
            when OP_NOP | OP_MOVI | OP_LDR | OP_STR | OP_MUL | OP_MLA |
                 OP_SMLSD | OP_SMLADX | OP_SSAT | OP_B =>
                known_op <= '1';
            when others =>
                known_op <= '0';
        end case;
    end process;
end architecture rtl;
