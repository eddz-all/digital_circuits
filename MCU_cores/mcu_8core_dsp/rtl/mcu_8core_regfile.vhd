library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.mcu_8core_dsp_pkg.all;

entity mcu_8core_regfile is
    port (
        clk : in std_logic;
        rst : in std_logic;

        we : in std_logic;
        wa : in std_logic_vector(3 downto 0);
        wd : in word_t;

        ra1 : in std_logic_vector(3 downto 0);
        ra2 : in std_logic_vector(3 downto 0);
        ra3 : in std_logic_vector(3 downto 0);
        ra4 : in std_logic_vector(3 downto 0);

        rd1 : out word_t;
        rd2 : out word_t;
        rd3 : out word_t;
        rd4 : out word_t
    );
end entity mcu_8core_regfile;

architecture rtl of mcu_8core_regfile is
    signal regs : reg_file_t := (others => (others => '0'));

    function reg_index(addr : std_logic_vector(3 downto 0)) return natural is
        variable result : natural := 0;
    begin
        for i in addr'range loop
            result := result * 2;
            if addr(i) = '1' then
                result := result + 1;
            end if;
        end loop;
        return result;
    end function;
begin
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                regs <= (others => (others => '0'));
            elsif we = '1' and reg_index(wa) /= 15 then
                regs(reg_index(wa)) <= wd;
            end if;
        end if;
    end process;

    rd1 <= regs(reg_index(ra1));
    rd2 <= regs(reg_index(ra2));
    rd3 <= regs(reg_index(ra3));
    rd4 <= regs(reg_index(ra4));
end architecture rtl;
