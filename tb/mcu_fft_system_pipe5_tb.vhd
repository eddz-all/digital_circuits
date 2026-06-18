library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;

entity mcu_fft_system_pipe5_tb is
    generic (
        CORE_RELEASE_LOAD_IDX : natural := 0
    );
end entity mcu_fft_system_pipe5_tb;

architecture sim of mcu_fft_system_pipe5_tb is
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
    signal cnt_active : std_logic := '0';
    signal cnt_cycles : natural := 0;
    signal dump_write_cycles : natural := 0;
    signal done      : std_logic;
    signal illegal   : std_logic;
    signal pc_debug  : std_logic_vector(31 downto 0);
    signal instr_debug : std_logic_vector(31 downto 0);
    signal stat_core_cycles : std_logic_vector(31 downto 0);
    signal stat_issue_count : std_logic_vector(31 downto 0);
    signal stat_load_use_stalls : std_logic_vector(31 downto 0);
    signal stat_bulk_load_stalls : std_logic_vector(31 downto 0);
    signal stat_flag_stalls : std_logic_vector(31 downto 0);
    signal stat_branch_flushes : std_logic_vector(31 downto 0);
    signal stat_halt_events : std_logic_vector(31 downto 0);
    signal stat_seg_prologue : std_logic_vector(31 downto 0);
    signal stat_seg_input_load : std_logic_vector(31 downto 0);
    signal stat_seg_stage1 : std_logic_vector(31 downto 0);
    signal stat_seg_stage2 : std_logic_vector(31 downto 0);
    signal stat_seg_stage3 : std_logic_vector(31 downto 0);
    signal stat_seg_twiddle : std_logic_vector(31 downto 0);
    signal stat_seg_output : std_logic_vector(31 downto 0);
    signal stat_seg_done : std_logic_vector(31 downto 0);

    type int_array_t is array (natural range <>) of integer;
    type output_mem_t is array (0 to 63) of std_logic_vector(15 downto 0);

    constant FFT_SAMPLE_INPUT : int_array_t(0 to 143) := (
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

    function slv16(value : integer) return std_logic_vector is
    begin
        return std_logic_vector(to_signed(value, 16));
    end function;

    function slv_to_nat(value : std_logic_vector) return natural is
    begin
        return to_integer(unsigned(value));
    end function;
begin
    clk <= not clk after 5 ns;

    dut : entity work.mcu_fft_system_pipe5
        generic map (
            MEM_FILE       => "asm/fft8_v1_mcu32_basic.mem",
            CORE_ROM_DEPTH => 1024,
            INPUT_COUNT    => 16,
            INPUT_ROM_BASE => 128,
            INPUT_MEM_BASE => 128,
            OUTPUT_COUNT   => 16,
            CORE_RELEASE_LOAD_IDX => CORE_RELEASE_LOAD_IDX
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
            instr_debug       => instr_debug,
            stat_core_cycles => stat_core_cycles,
            stat_issue_count => stat_issue_count,
            stat_load_use_stalls => stat_load_use_stalls,
            stat_bulk_load_stalls => stat_bulk_load_stalls,
            stat_flag_stalls => stat_flag_stalls,
            stat_branch_flushes => stat_branch_flushes,
            stat_halt_events => stat_halt_events,
            stat_seg_prologue => stat_seg_prologue,
            stat_seg_input_load => stat_seg_input_load,
            stat_seg_stage1 => stat_seg_stage1,
            stat_seg_stage2 => stat_seg_stage2,
            stat_seg_stage3 => stat_seg_stage3,
            stat_seg_twiddle => stat_seg_twiddle,
            stat_seg_output => stat_seg_output,
            stat_seg_done => stat_seg_done
        );

    process(clk)
        variable addr : natural;
    begin
        if rising_edge(clk) then
            if test_rom_en = '1' then
                addr := to_integer(unsigned(test_rom_addr));
                assert addr >= 128
                    report "fast path should load only FFT signal slots 128..143"
                    severity failure;
                assert addr < FFT_SAMPLE_INPUT'length
                    report "test_rom_addr out of FFT sample range"
                    severity failure;
                test_vector_in <= slv16(FFT_SAMPLE_INPUT(addr));
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
                cnt_cycles <= 0;
                dump_write_cycles <= 0;
            else
                if cnt_start = '1' and cnt_active = '0' then
                    cnt_active <= '1';
                    cnt_cycles <= cnt_cycles + 1;
                elsif cnt_active = '1' then
                    cnt_cycles <= cnt_cycles + 1;
                end if;

                if cnt_stop = '1' then
                    cnt_active <= '0';
                end if;

                if verify_ram_we = '1' then
                    dump_write_cycles <= dump_write_cycles + 1;
                end if;
            end if;
        end if;
    end process;

    stim : process
        variable core_cycles_i : natural;
        variable issue_count_i : natural;
        variable load_use_stalls_i : natural;
        variable bulk_load_stalls_i : natural;
        variable flag_stalls_i : natural;
        variable branch_flushes_i : natural;
        variable halt_events_i : natural;
        variable seg_prologue_i : natural;
        variable seg_input_load_i : natural;
        variable seg_stage1_i : natural;
        variable seg_stage2_i : natural;
        variable seg_stage3_i : natural;
        variable seg_twiddle_i : natural;
        variable seg_output_i : natural;
        variable seg_done_i : natural;
        variable seg_total_i : natural;
        variable fixed_overhead_i : integer;
        variable wrapper_transition_i : integer;

        procedure wait_cycles(count : natural) is
        begin
            for i in 1 to count loop
                wait until rising_edge(clk);
            end loop;
        end procedure;
    begin
        wait_cycles(4);
        rst <= '0';

        for i in 1 to 3000 loop
            wait until rising_edge(clk);
            exit when done = '1';
        end loop;

        assert done = '1' report "mcu_fft_system_pipe5 did not finish" severity failure;
        assert illegal = '0' report "mcu_fft_system_pipe5 core hit illegal instruction" severity failure;
        assert cnt_start = '0' report "cnt_start should be a pulse" severity failure;

        wait_cycles(1);

        for slot in FFT_EXPECTED_OUTPUT'range loop
            assert verify_mem(slot) = slv16(FFT_EXPECTED_OUTPUT(slot))
                report "verify_mem slot " & integer'image(slot)
                    & " expected " & integer'image(FFT_EXPECTED_OUTPUT(slot))
                    & " got " & integer'image(to_integer(signed(verify_mem(slot))))
                severity failure;
        end loop;

        core_cycles_i := slv_to_nat(stat_core_cycles);
        issue_count_i := slv_to_nat(stat_issue_count);
        load_use_stalls_i := slv_to_nat(stat_load_use_stalls);
        bulk_load_stalls_i := slv_to_nat(stat_bulk_load_stalls);
        flag_stalls_i := slv_to_nat(stat_flag_stalls);
        branch_flushes_i := slv_to_nat(stat_branch_flushes);
        halt_events_i := slv_to_nat(stat_halt_events);
        seg_prologue_i := slv_to_nat(stat_seg_prologue);
        seg_input_load_i := slv_to_nat(stat_seg_input_load);
        seg_stage1_i := slv_to_nat(stat_seg_stage1);
        seg_stage2_i := slv_to_nat(stat_seg_stage2);
        seg_stage3_i := slv_to_nat(stat_seg_stage3);
        seg_twiddle_i := slv_to_nat(stat_seg_twiddle);
        seg_output_i := slv_to_nat(stat_seg_output);
        seg_done_i := slv_to_nat(stat_seg_done);
        seg_total_i := seg_prologue_i + seg_input_load_i + seg_stage1_i
            + seg_stage2_i + seg_stage3_i + seg_twiddle_i + seg_output_i
            + seg_done_i;
        fixed_overhead_i := integer(core_cycles_i) - integer(issue_count_i)
            - integer(load_use_stalls_i) - integer(bulk_load_stalls_i)
            - integer(flag_stalls_i) - integer(branch_flushes_i)
            - integer(halt_events_i);
        wrapper_transition_i := integer(cnt_cycles) - integer(core_cycles_i)
            - integer(dump_write_cycles);

        assert fixed_overhead_i >= 0
            report "pipe5 fixed overhead accounting went negative"
            severity failure;
        assert wrapper_transition_i >= 0
            report "pipe5 system accounting went negative"
            severity failure;
        assert seg_total_i = issue_count_i
            report "pipe5 segment accounting should match issued instruction count"
            severity failure;

        report "mcu_fft_system_pipe5_tb cnt_cycles " & integer'image(cnt_cycles) severity note;
        report "mcu_fft_system_pipe5_tb system_stats core_cycles="
            & integer'image(core_cycles_i)
            & " dump_write_cycles="
            & integer'image(dump_write_cycles)
            & " wrapper_transition_cycles="
            & integer'image(wrapper_transition_i)
            & " overlapped_input_load_cycles=16"
            severity note;
        report "mcu_fft_system_pipe5_tb core_stats issued="
            & integer'image(issue_count_i)
            & " load_use_stalls="
            & integer'image(load_use_stalls_i)
            & " bulk_load_stalls="
            & integer'image(bulk_load_stalls_i)
            & " flag_stalls="
            & integer'image(flag_stalls_i)
            & " branch_flushes="
            & integer'image(branch_flushes_i)
            & " halt_events="
            & integer'image(halt_events_i)
            & " fixed_fill_drain_cycles="
            & integer'image(fixed_overhead_i)
            severity note;
        report "mcu_fft_system_pipe5_tb segment_stats prologue="
            & integer'image(seg_prologue_i)
            & " input_load_scale="
            & integer'image(seg_input_load_i)
            & " stage1="
            & integer'image(seg_stage1_i)
            & " stage2="
            & integer'image(seg_stage2_i)
            & " stage3_butterfly="
            & integer'image(seg_stage3_i)
            & " twiddle_multiply="
            & integer'image(seg_twiddle_i)
            & " output_store="
            & integer'image(seg_output_i)
            & " done_halt="
            & integer'image(seg_done_i)
            severity note;
        report "mcu_fft_system_pipe5_tb passed" severity note;
        finish;
    end process;
end architecture sim;
