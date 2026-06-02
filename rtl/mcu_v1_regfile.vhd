library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mcu_v1_regfile is
    port (
        clk : in std_logic;
        rst : in std_logic;

        we  : in std_logic;
        ra1 : in std_logic_vector(3 downto 0);
        ra2 : in std_logic_vector(3 downto 0);
        ra3 : in std_logic_vector(3 downto 0);
        wa  : in std_logic_vector(3 downto 0);
        wd  : in std_logic_vector(31 downto 0);
        bulk_we_mask : in std_logic_vector(15 downto 0);
        bulk_wd      : in std_logic_vector(511 downto 0);

        rd1 : out std_logic_vector(31 downto 0);
        rd2 : out std_logic_vector(31 downto 0);
        rd3 : out std_logic_vector(31 downto 0)
    );
end entity mcu_v1_regfile;

architecture rtl of mcu_v1_regfile is
    type reg_array_t is array (0 to 15) of std_logic_vector(31 downto 0);
    signal regs : reg_array_t := (others => (others => '0'));
begin
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                regs <= (others => (others => '0'));
            else
                if we = '1' and wa /= x"F" then
                    regs(to_integer(unsigned(wa))) <= wd;
                end if;
                for i in 0 to 14 loop
                    if bulk_we_mask(i) = '1' then
                        regs(i) <= bulk_wd(32 * i + 31 downto 32 * i);
                    end if;
                end loop;
            end if;
        end if;
    end process;

    rd1 <= regs(to_integer(unsigned(ra1)));
    rd2 <= regs(to_integer(unsigned(ra2)));
    rd3 <= regs(to_integer(unsigned(ra3)));
end architecture rtl;
