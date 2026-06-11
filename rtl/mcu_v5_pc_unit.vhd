library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mcu_v5_pc_unit is
    port (
        pc_current    : in  std_logic_vector(31 downto 0);
        branch_taken  : in  std_logic;
        branch_offset : in  std_logic_vector(31 downto 0);
        pc_next       : out std_logic_vector(31 downto 0);
        halted        : out std_logic
    );
end entity mcu_v5_pc_unit;

architecture rtl of mcu_v5_pc_unit is
    signal pc_next_i : std_logic_vector(31 downto 0) := (others => '0');
begin
    pc_next_i <= std_logic_vector(signed(pc_current) + to_signed(8, 32) + signed(branch_offset))
        when branch_taken = '1'
        else std_logic_vector(unsigned(pc_current) + 4);

    pc_next <= pc_next_i;
    halted <= '1' when branch_taken = '1' and pc_next_i = pc_current else '0';
end architecture rtl;
