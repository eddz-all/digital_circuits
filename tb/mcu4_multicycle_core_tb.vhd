library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;

use work.mcu4_multi_pkg.all;

entity mcu4_multicycle_core_tb is
end entity mcu4_multicycle_core_tb;

architecture sim of mcu4_multicycle_core_tb is
    signal clk : std_logic := '0';
    signal rst : std_logic := '1';
    signal dmem_we : std_logic := '0';
    signal dmem_waddr : word_t := (others => '0');
    signal dmem_wdata : word_t := (others => '0');
    signal dmem_raddr : word_t := (others => '0');
    signal dmem_rdata : word_t;
    signal pc_debug : std_logic_vector(31 downto 0);
    signal instr_debug : std_logic_vector(31 downto 0);
    signal halted_debug : std_logic;
    signal illegal_debug : std_logic;
    signal flag_z_debug : std_logic;
    signal flag_n_debug : std_logic;

    type int_array_t is array (natural range <>) of integer;
    constant FFT_INPUT : int_array_t(0 to 15) := (
        -13, -29, -29, 0, -9, 27, 6, 20,
        27, -9, -18, -23, 0, 18, -21, -20
    );
    constant FFT_EXPECTED_OUTPUT : int_array_t(0 to 15) := (
        -3456, -6134, 6784, -350, -8064, 5878, -6528, -1442,
        -5888, 12668, 11264, 8076, 2816, 3204, 5632, -10124
    );

    function slv16(value : integer) return std_logic_vector is
    begin
        return std_logic_vector(to_signed(value, 16));
    end function;
begin
    clk <= not clk after 5 ns;

    dut : entity work.mcu4_multicycle_core
        port map (
            clk           => clk,
            rst           => rst,
            dmem_we       => dmem_we,
            dmem_waddr    => dmem_waddr,
            dmem_wdata    => dmem_wdata,
            dmem_raddr    => dmem_raddr,
            dmem_rdata    => dmem_rdata,
            pc_debug      => pc_debug,
            instr_debug   => instr_debug,
            halted_debug  => halted_debug,
            illegal_debug => illegal_debug,
            flag_z_debug  => flag_z_debug,
            flag_n_debug  => flag_n_debug
        );

    stim : process
        variable samples : sample16_array_t := (others => (others => '0'));
        variable src_idx : natural range 0 to 7;
        variable output_half : half_t;

        procedure wait_cycles(count : natural) is
        begin
            for i in 1 to count loop
                wait until rising_edge(clk);
            end loop;
        end procedure;
    begin
        wait_cycles(2);

        for i in FFT_INPUT'range loop
            if i < 8 then
                samples(i) := slv16(FFT_INPUT(i));
                dmem_we <= '0';
            else
                src_idx := i - 8;
                dmem_waddr <= dmem_word_addr(DMEM_REGION_A_BASE_WORD + BITREV_ORDER(src_idx));
                dmem_wdata <= pack_q5_to_q12(samples(src_idx), slv16(FFT_INPUT(i)));
                dmem_we <= '1';
            end if;
            wait until rising_edge(clk);
        end loop;
        dmem_we <= '0';
        wait until rising_edge(clk);

        rst <= '0';
        for i in 1 to 200 loop
            wait until rising_edge(clk);
            exit when halted_debug = '1';
        end loop;

        assert halted_debug = '1' report "core did not halt" severity failure;
        assert illegal_debug = '0' report "core hit illegal instruction" severity failure;

        for slot in FFT_EXPECTED_OUTPUT'range loop
            if slot < 8 then
                dmem_raddr <= dmem_word_addr(DMEM_REGION_B_BASE_WORD + slot);
                wait for 1 ns;
                output_half := dmem_rdata(15 downto 0);
            else
                dmem_raddr <= dmem_word_addr(DMEM_REGION_B_BASE_WORD + slot - 8);
                wait for 1 ns;
                output_half := dmem_rdata(31 downto 16);
            end if;
            wait for 1 ns;
            assert output_half = slv16(FFT_EXPECTED_OUTPUT(slot))
                report "core output slot " & integer'image(slot)
                    & " expected " & integer'image(FFT_EXPECTED_OUTPUT(slot))
                    & " got " & integer'image(to_integer(signed(output_half)))
                severity failure;
        end loop;

        report "mcu4_multicycle_core_tb passed" severity note;
        finish;
    end process;
end architecture sim;
