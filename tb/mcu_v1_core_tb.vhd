library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;

entity mcu_v1_core_tb is
end entity mcu_v1_core_tb;

architecture sim of mcu_v1_core_tb is
    signal clk : std_logic := '0';

    signal basic_rst          : std_logic := '1';
    signal basic_input_we     : std_logic := '0';
    signal basic_input_waddr  : std_logic_vector(5 downto 0) := (others => '0');
    signal basic_input_wdata  : std_logic_vector(15 downto 0) := (others => '0');
    signal basic_output_raddr : std_logic_vector(5 downto 0) := (others => '0');
    signal basic_output_rdata : std_logic_vector(15 downto 0);
    signal basic_pc           : std_logic_vector(31 downto 0);
    signal basic_instr        : std_logic_vector(31 downto 0);
    signal basic_halted       : std_logic;
    signal basic_illegal      : std_logic;
    signal basic_z            : std_logic;
    signal basic_n            : std_logic;

    signal fft_rst          : std_logic := '1';
    signal fft_input_we     : std_logic := '0';
    signal fft_input_waddr  : std_logic_vector(5 downto 0) := (others => '0');
    signal fft_input_wdata  : std_logic_vector(15 downto 0) := (others => '0');
    signal fft_output_raddr : std_logic_vector(5 downto 0) := (others => '0');
    signal fft_output_rdata : std_logic_vector(15 downto 0);
    signal fft_pc           : std_logic_vector(31 downto 0);
    signal fft_instr        : std_logic_vector(31 downto 0);
    signal fft_halted       : std_logic;
    signal fft_illegal      : std_logic;
    signal fft_z            : std_logic;
    signal fft_n            : std_logic;

    signal fast_rst          : std_logic := '1';
    signal fast_input_we     : std_logic := '0';
    signal fast_input_waddr  : std_logic_vector(5 downto 0) := (others => '0');
    signal fast_input_wdata  : std_logic_vector(15 downto 0) := (others => '0');
    signal fast_output_raddr : std_logic_vector(5 downto 0) := (others => '0');
    signal fast_output_rdata : std_logic_vector(15 downto 0);
    signal fast_pc           : std_logic_vector(31 downto 0);
    signal fast_instr        : std_logic_vector(31 downto 0);
    signal fast_halted       : std_logic;
    signal fast_illegal      : std_logic;
    signal fast_z            : std_logic;
    signal fast_n            : std_logic;

    signal v3_rst          : std_logic := '1';
    signal v3_input_we     : std_logic := '0';
    signal v3_input_waddr  : std_logic_vector(5 downto 0) := (others => '0');
    signal v3_input_wdata  : std_logic_vector(15 downto 0) := (others => '0');
    signal v3_output_raddr : std_logic_vector(5 downto 0) := (others => '0');
    signal v3_output_rdata : std_logic_vector(15 downto 0);
    signal v3_pc           : std_logic_vector(31 downto 0);
    signal v3_instr        : std_logic_vector(31 downto 0);
    signal v3_halted       : std_logic;
    signal v3_illegal      : std_logic;
    signal v3_z            : std_logic;
    signal v3_n            : std_logic;

    function slv16(value : integer) return std_logic_vector is
    begin
        return std_logic_vector(to_signed(value, 16));
    end function;
begin
    clk <= not clk after 5 ns;

    basic_core : entity work.mcu_v1_core
        generic map (
            MEM_FILE  => "asm/test_mcu_v1_basic.mem",
            ROM_DEPTH => 256
        )
        port map (
            clk          => clk,
            rst          => basic_rst,
            input_we     => basic_input_we,
            input_waddr  => basic_input_waddr,
            input_wdata  => basic_input_wdata,
            output_raddr => basic_output_raddr,
            output_rdata => basic_output_rdata,
            pc_debug     => basic_pc,
            instr_debug  => basic_instr,
            halted_debug => basic_halted,
            illegal_debug => basic_illegal,
            flag_z_debug => basic_z,
            flag_n_debug => basic_n
        );

    fft_core : entity work.mcu_v1_core
        generic map (
            MEM_FILE  => "asm/fft8_v1_mcu32_basic.mem",
            ROM_DEPTH => 1024
        )
        port map (
            clk          => clk,
            rst          => fft_rst,
            input_we     => fft_input_we,
            input_waddr  => fft_input_waddr,
            input_wdata  => fft_input_wdata,
            output_raddr => fft_output_raddr,
            output_rdata => fft_output_rdata,
            pc_debug     => fft_pc,
            instr_debug  => fft_instr,
            halted_debug => fft_halted,
            illegal_debug => fft_illegal,
            flag_z_debug => fft_z,
            flag_n_debug => fft_n
        );

    fast_core : entity work.mcu_v1_core
        generic map (
            MEM_FILE  => "asm/fft8_v2_packed_dsp.mem",
            ROM_DEPTH => 512
        )
        port map (
            clk          => clk,
            rst          => fast_rst,
            input_we     => fast_input_we,
            input_waddr  => fast_input_waddr,
            input_wdata  => fast_input_wdata,
            output_raddr => fast_output_raddr,
            output_rdata => fast_output_rdata,
            pc_debug     => fast_pc,
            instr_debug  => fast_instr,
            halted_debug => fast_halted,
            illegal_debug => fast_illegal,
            flag_z_debug => fast_z,
            flag_n_debug => fast_n
        );

    v3_core : entity work.mcu_v1_core
        generic map (
            MEM_FILE  => "asm/fft8_v3_arch_dsp.mem",
            ROM_DEPTH => 256
        )
        port map (
            clk          => clk,
            rst          => v3_rst,
            input_we     => v3_input_we,
            input_waddr  => v3_input_waddr,
            input_wdata  => v3_input_wdata,
            output_raddr => v3_output_raddr,
            output_rdata => v3_output_rdata,
            pc_debug     => v3_pc,
            instr_debug  => v3_instr,
            halted_debug => v3_halted,
            illegal_debug => v3_illegal,
            flag_z_debug => v3_z,
            flag_n_debug => v3_n
        );

    stim : process
        procedure wait_cycles(count : natural) is
        begin
            for i in 1 to count loop
                wait until rising_edge(clk);
            end loop;
        end procedure;

        procedure write_basic_input(slot : natural; value : integer) is
        begin
            basic_input_waddr <= std_logic_vector(to_unsigned(slot, 6));
            basic_input_wdata <= slv16(value);
            basic_input_we <= '1';
            wait until rising_edge(clk);
            wait for 1 ns;
            basic_input_we <= '0';
        end procedure;

        procedure write_fft_input(slot : natural; value : integer) is
        begin
            fft_input_waddr <= std_logic_vector(to_unsigned(slot, 6));
            fft_input_wdata <= slv16(value);
            fft_input_we <= '1';
            wait until rising_edge(clk);
            wait for 1 ns;
            fft_input_we <= '0';
        end procedure;

        procedure write_fast_input(slot : natural; value : integer) is
        begin
            fast_input_waddr <= std_logic_vector(to_unsigned(slot, 6));
            fast_input_wdata <= slv16(value);
            fast_input_we <= '1';
            wait until rising_edge(clk);
            wait for 1 ns;
            fast_input_we <= '0';
        end procedure;

        procedure write_v3_input(slot : natural; value : integer) is
        begin
            v3_input_waddr <= std_logic_vector(to_unsigned(slot, 6));
            v3_input_wdata <= slv16(value);
            v3_input_we <= '1';
            wait until rising_edge(clk);
            wait for 1 ns;
            v3_input_we <= '0';
        end procedure;

        procedure expect_basic_output(slot : natural; value : integer) is
        begin
            basic_output_raddr <= std_logic_vector(to_unsigned(slot, 6));
            wait for 1 ns;
            assert basic_output_rdata = slv16(value)
                report "basic output slot " & integer'image(slot)
                    & " expected " & integer'image(value)
                severity failure;
        end procedure;

        procedure expect_fft_output(slot : natural; value : integer) is
        begin
            fft_output_raddr <= std_logic_vector(to_unsigned(slot, 6));
            wait for 1 ns;
            assert fft_output_rdata = slv16(value)
                report "fft output slot " & integer'image(slot)
                    & " expected " & integer'image(value)
                severity failure;
        end procedure;

        procedure expect_fast_output(slot : natural; value : integer) is
        begin
            fast_output_raddr <= std_logic_vector(to_unsigned(slot, 6));
            wait for 1 ns;
            assert fast_output_rdata = slv16(value)
                report "fast output slot " & integer'image(slot)
                    & " expected " & integer'image(value)
                severity failure;
        end procedure;

        procedure expect_v3_output(slot : natural; value : integer) is
        begin
            v3_output_raddr <= std_logic_vector(to_unsigned(slot, 6));
            wait for 1 ns;
            assert v3_output_rdata = slv16(value)
                report "v3 output slot " & integer'image(slot)
                    & " expected " & integer'image(value)
                severity failure;
        end procedure;
    begin
        wait_cycles(2);

        write_basic_input(0, 1000);
        write_basic_input(1, -500);
        basic_rst <= '0';
        wait_cycles(60);

        assert basic_illegal = '0' report "basic program hit illegal instruction" severity failure;
        assert basic_halted = '1' report "basic program did not reach DONE self-loop" severity failure;
        assert basic_pc = x"0000008C" report "basic PC should be at DONE" severity failure;
        expect_basic_output(0, 500);
        expect_basic_output(1, 1500);
        expect_basic_output(2, 707);
        expect_basic_output(3, 123);
        expect_basic_output(4, 8);
        expect_basic_output(5, 11);
        expect_basic_output(6, 16#0074#);
        expect_basic_output(7, 0);

        write_fft_input(0, 32760);
        fft_rst <= '0';
        wait_cycles(320);

        assert fft_illegal = '0' report "FFT program hit illegal instruction" severity failure;
        assert fft_halted = '1' report "FFT program did not reach DONE self-loop" severity failure;
        assert fft_pc = x"00000474" report "FFT PC should be at DONE" severity failure;

        for complex_i in 0 to 7 loop
            expect_fft_output(2 * complex_i, 4095);
            expect_fft_output(2 * complex_i + 1, 0);
        end loop;

        fft_rst <= '1';
        wait_cycles(2);
        for slot_i in 0 to 15 loop
            if slot_i = 2 then
                write_fft_input(slot_i, 32760);
            else
                write_fft_input(slot_i, 0);
            end if;
        end loop;
        fft_rst <= '0';
        wait_cycles(320);

        assert fft_illegal = '0' report "FFT x1 program hit illegal instruction" severity failure;
        assert fft_halted = '1' report "FFT x1 program did not reach DONE self-loop" severity failure;
        assert fft_pc = x"00000474" report "FFT x1 PC should be at DONE" severity failure;
        expect_fft_output(0, 4095);
        expect_fft_output(1, 0);
        expect_fft_output(2, -4095);
        expect_fft_output(3, 0);
        expect_fft_output(4, 0);
        expect_fft_output(5, -4095);
        expect_fft_output(6, 0);
        expect_fft_output(7, 4095);
        expect_fft_output(8, 2895);
        expect_fft_output(9, -2896);
        expect_fft_output(10, -2896);
        expect_fft_output(11, 2896);
        expect_fft_output(12, -2896);
        expect_fft_output(13, -2896);
        expect_fft_output(14, 2896);
        expect_fft_output(15, 2895);

        write_fast_input(0, 32760);
        fast_rst <= '0';
        wait_cycles(150);

        assert fast_illegal = '0' report "fast FFT program hit illegal instruction" severity failure;
        assert fast_halted = '1' report "fast FFT program did not reach DONE self-loop" severity failure;
        assert fast_pc = x"000001DC" report "fast FFT PC should be at DONE" severity failure;

        for complex_i in 0 to 7 loop
            expect_fast_output(2 * complex_i, 4095);
            expect_fast_output(2 * complex_i + 1, 0);
        end loop;

        fast_rst <= '1';
        wait_cycles(2);
        for slot_i in 0 to 15 loop
            if slot_i = 2 then
                write_fast_input(slot_i, 32760);
            else
                write_fast_input(slot_i, 0);
            end if;
        end loop;
        fast_rst <= '0';
        wait_cycles(150);

        assert fast_illegal = '0' report "fast FFT x1 program hit illegal instruction" severity failure;
        assert fast_halted = '1' report "fast FFT x1 program did not reach DONE self-loop" severity failure;
        assert fast_pc = x"000001DC" report "fast FFT x1 PC should be at DONE" severity failure;
        expect_fast_output(0, 4095);
        expect_fast_output(1, 0);
        expect_fast_output(2, -4095);
        expect_fast_output(3, 0);
        expect_fast_output(4, 0);
        expect_fast_output(5, -4095);
        expect_fast_output(6, 0);
        expect_fast_output(7, 4095);
        expect_fast_output(8, 2895);
        expect_fast_output(9, -2896);
        expect_fast_output(10, -2896);
        expect_fast_output(11, 2896);
        expect_fast_output(12, -2896);
        expect_fast_output(13, -2896);
        expect_fast_output(14, 2896);
        expect_fast_output(15, 2895);

        write_v3_input(0, 32760);
        v3_rst <= '0';
        wait_cycles(130);

        assert v3_illegal = '0' report "V3 FFT program hit illegal instruction" severity failure;
        assert v3_halted = '1' report "V3 FFT program did not reach DONE self-loop" severity failure;
        assert v3_pc = x"00000184" report "V3 FFT PC should be at DONE" severity failure;

        for complex_i in 0 to 7 loop
            expect_v3_output(2 * complex_i, 4095);
            expect_v3_output(2 * complex_i + 1, 0);
        end loop;

        v3_rst <= '1';
        wait_cycles(2);
        for slot_i in 0 to 15 loop
            if slot_i = 2 then
                write_v3_input(slot_i, 32760);
            else
                write_v3_input(slot_i, 0);
            end if;
        end loop;
        v3_rst <= '0';
        wait_cycles(130);

        assert v3_illegal = '0' report "V3 FFT x1 program hit illegal instruction" severity failure;
        assert v3_halted = '1' report "V3 FFT x1 program did not reach DONE self-loop" severity failure;
        assert v3_pc = x"00000184" report "V3 FFT x1 PC should be at DONE" severity failure;
        expect_v3_output(0, 4095);
        expect_v3_output(1, 0);
        expect_v3_output(2, -4095);
        expect_v3_output(3, 0);
        expect_v3_output(4, 0);
        expect_v3_output(5, -4095);
        expect_v3_output(6, 0);
        expect_v3_output(7, 4095);
        expect_v3_output(8, 2895);
        expect_v3_output(9, -2896);
        expect_v3_output(10, -2896);
        expect_v3_output(11, 2896);
        expect_v3_output(12, -2896);
        expect_v3_output(13, -2896);
        expect_v3_output(14, 2896);
        expect_v3_output(15, 2895);

        report "mcu_v1_core_tb passed" severity note;
        finish;
    end process;
end architecture sim;
