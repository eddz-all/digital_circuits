library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.mcu_v1_pkg.all;
use std.env.all;

entity mcu_v1_alu_tb is
end entity mcu_v1_alu_tb;

architecture sim of mcu_v1_alu_tb is
    signal a           : std_logic_vector(31 downto 0) := (others => '0');
    signal b           : std_logic_vector(31 downto 0) := (others => '0');
    signal alu_control : std_logic_vector(3 downto 0) := ALU_ADD;
    signal result      : std_logic_vector(31 downto 0);
    signal flag_z      : std_logic;
    signal flag_n      : std_logic;
begin
    dut : entity work.mcu_v1_alu
        port map (
            a           => a,
            b           => b,
            alu_control => alu_control,
            result      => result,
            flag_z      => flag_z,
            flag_n      => flag_n
        );

    stim : process
    begin
        -- a = {imag=-2000, real=1000}, b = {imag=3000, real=-500}
        a <= x"F83003E8";
        b <= x"0BB8FE0C";

        alu_control <= ALU_SHADD16;
        wait for 1 ns;
        assert result = x"01F400FA" report "SHADD16 result mismatch" severity failure;

        alu_control <= ALU_SHSUB16;
        wait for 1 ns;
        assert result = x"F63C02EE" report "SHSUB16 result mismatch" severity failure;

        a <= x"00020003";
        b <= x"00040005";

        alu_control <= ALU_SMUAD;
        wait for 1 ns;
        assert result = x"00000017" report "SMUAD result mismatch" severity failure;

        alu_control <= ALU_SMUSD;
        wait for 1 ns;
        assert result = x"00000007" report "SMUSD result mismatch" severity failure;

        a <= x"1234F001";
        alu_control <= ALU_SXTH;
        wait for 1 ns;
        assert result = x"FFFFF001" report "SXTH result mismatch" severity failure;

        a <= x"AAAA0B4F";
        b <= x"BBBBF4B0";
        alu_control <= ALU_PKHBT;
        wait for 1 ns;
        assert result = x"F4B00B4F" report "PKHBT result mismatch" severity failure;

        report "mcu_v1_alu_tb passed" severity note;
        finish;
    end process;
end architecture sim;
