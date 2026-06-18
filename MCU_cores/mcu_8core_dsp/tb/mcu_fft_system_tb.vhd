library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;

entity mcu_fft_system_tb is
end entity mcu_fft_system_tb;

architecture sim of mcu_fft_system_tb is
    signal clk : std_logic := '0';
    signal rst : std_logic := '1';

    signal test_rom_addr  : std_logic_vector(7 downto 0);
    signal test_rom_en    : std_logic;
    signal test_vector_in : std_logic_vector(15 downto 0) := (others => '0');

    signal verify_ram_addr   : std_logic_vector(5 downto 0);
    signal verify_ram_we     : std_logic;
    signal verify_vector_out : std_logic_vector(15 downto 0);

    signal cnt_start : std_logic;
    signal cnt_stop  : std_logic;
    signal done      : std_logic;
    signal illegal   : std_logic;
    signal pc_debug  : std_logic_vector(31 downto 0);
    signal instr_debug : std_logic_vector(31 downto 0);

    type int_array_t is array (natural range <>) of integer;
    type output_mem_t is array (0 to 63) of std_logic_vector(15 downto 0);

    constant FFT_SIGNAL_INPUT : int_array_t(0 to 15) := (
        -13, -29, -29, 0, -9, 27, 6, 20,
        27, -9, -18, -23, 0, 18, -21, -20
    );

    constant TEACHER_INPUT : int_array_t(0 to 143) := (
        128, 128, 128, 128, 128, 128, 128, 128,
        128, 91, 0, -91, -128, -91, 0, 91,
        128, 0, -128, 0, 128, 0, -128, 0,
        128, -91, 0, 91, -128, 91, 0, -91,
        128, -128, 128, -128, 128, -128, 128, -128,
        128, -91, 0, 91, -128, 91, 0, -91,
        128, 0, -128, 0, 128, 0, -128, 0,
        128, 91, 0, -91, -128, -91, 0, 91,
        0, 0, 0, 0, 0, 0, 0, 0,
        0, -91, -128, -91, 0, 91, 128, 91,
        0, -128, 0, 128, 0, -128, 0, 128,
        0, -91, 128, -91, 0, 91, -128, 91,
        0, 0, 0, 0, 0, 0, 0, 0,
        0, 91, -128, 91, 0, -91, 128, -91,
        0, 128, 0, -128, 0, 128, 0, -128,
        0, 91, 128, 91, 0, -91, -128, -91,
        -13, -29, -29, 0, -9, 27, 6, 20,
        27, -9, -18, -23, 0, 18, -21, -20
    );

    constant FFT_EXPECTED_OUTPUT : int_array_t(0 to 15) := (
        -3456, -6134, 6784, -350, -8064, 5878, -6528, -1442,
        -5888, 12668, 11264, 8076, 2816, 3204, 5632, -10124
    );

    signal verify_mem : output_mem_t := (others => (others => '0'));
    signal max_rom_addr_seen : natural := 0;
    signal cnt_active : std_logic := '0';
    signal counted_cycles : natural := 0;

    function slv16(value : integer) return std_logic_vector is
    begin
        return std_logic_vector(to_signed(value, 16));
    end function;
begin
    clk <= not clk after 5 ns;

    dut : entity work.mcu_fft_system
        generic map (
            MEM_FILE       => "unused",
            CORE_ROM_DEPTH => 64,
            INPUT_ROM_BASE => 128,
            INPUT_COUNT    => 16,
            OUTPUT_COUNT   => 16
        )
        port map (
            clk               => clk,
            rst               => rst,
            test_rom_addr     => test_rom_addr,
            test_rom_en       => test_rom_en,
            test_vector_in    => test_vector_in,
            verify_ram_addr   => verify_ram_addr,
            verify_ram_we     => verify_ram_we,
            verify_vector_out => verify_vector_out,
            cnt_start         => cnt_start,
            cnt_stop          => cnt_stop,
            done              => done,
            illegal           => illegal,
            pc_debug          => pc_debug,
            instr_debug       => instr_debug
        );

    process(clk)
        variable addr : natural;
    begin
        if rising_edge(clk) then
            if test_rom_en = '1' then
                addr := to_integer(unsigned(test_rom_addr));
                assert addr >= 128 and addr < TEACHER_INPUT'length
                    report "test_rom_addr outside teacher signal window 128..143"
                    severity failure;
                test_vector_in <= slv16(TEACHER_INPUT(addr));
                if addr > max_rom_addr_seen then
                    max_rom_addr_seen <= addr;
                end if;
            end if;

            if verify_ram_we = '1' then
                addr := to_integer(unsigned(verify_ram_addr));
                assert addr < FFT_EXPECTED_OUTPUT'length
                    report "verify_ram_addr out of expected FFT output range"
                    severity failure;
                verify_mem(addr) <= verify_vector_out;
            end if;
        end if;
    end process;

    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                cnt_active <= '0';
                counted_cycles <= 0;
            else
                if cnt_start = '1' and cnt_active = '0' then
                    cnt_active <= '1';
                    counted_cycles <= counted_cycles + 1;
                    assert max_rom_addr_seen = 143
                        report "cnt_start fired before all 16 signal inputs were read"
                        severity failure;
                elsif cnt_active = '1' then
                    counted_cycles <= counted_cycles + 1;
                end if;

                if cnt_stop = '1' then
                    cnt_active <= '0';
                end if;
            end if;
        end if;
    end process;

    stim : process
        procedure wait_cycles(count : natural) is
        begin
            for i in 1 to count loop
                wait until rising_edge(clk);
            end loop;
        end procedure;
    begin
        wait_cycles(4);
        rst <= '0';

        for i in 1 to 300 loop
            wait until rising_edge(clk);
            exit when done = '1';
        end loop;

        assert done = '1' report "mcu_fft_system did not finish" severity failure;
        assert illegal = '0' report "mcu_fft_system core hit illegal instruction" severity failure;
        assert max_rom_addr_seen = 143 report "system did not read exactly through teacher input slot 143" severity failure;
        assert counted_cycles > 0 report "counter never started" severity failure;

        wait_cycles(1);

        for slot in FFT_EXPECTED_OUTPUT'range loop
            assert verify_mem(slot) = slv16(FFT_EXPECTED_OUTPUT(slot))
                report "verify_mem slot " & integer'image(slot)
                    & " expected " & integer'image(FFT_EXPECTED_OUTPUT(slot))
                    & " got " & integer'image(to_integer(signed(verify_mem(slot))))
                severity failure;
        end loop;

        report "mcu_fft_system_tb passed, counted_cycles="
            & integer'image(counted_cycles)
            severity note;
        finish;
    end process;
end architecture sim;
