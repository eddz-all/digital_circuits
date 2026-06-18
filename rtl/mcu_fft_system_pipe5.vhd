library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mcu_fft_system_pipe5 is
    generic (
        MEM_FILE       : string := "asm/fft8_v1_mcu32_basic.mem";
        CORE_ROM_DEPTH : positive := 1024;
        INPUT_COUNT    : positive := 16;
        INPUT_ROM_BASE : natural := 128;
        INPUT_MEM_BASE : natural := 128;
        OUTPUT_COUNT   : positive := 16;
        CORE_RELEASE_LOAD_IDX : natural := 0
    );
    port (
        clk : in std_logic;
        rst : in std_logic;

        test_rom_addr  : out std_logic_vector(7 downto 0);
        test_rom_en    : out std_logic;
        test_vector_in : in  std_logic_vector(15 downto 0);

        verify_ram_addr   : out std_logic_vector(5 downto 0);
        verify_ram_we     : out std_logic;
        verify_vector_out : out std_logic_vector(15 downto 0);

        cnt_start : out std_logic;
        cnt_stop  : out std_logic;

        done        : out std_logic;
        illegal     : out std_logic;
        pc_debug    : out std_logic_vector(31 downto 0);
        instr_debug : out std_logic_vector(31 downto 0);

        stat_core_cycles      : out std_logic_vector(31 downto 0);
        stat_issue_count      : out std_logic_vector(31 downto 0);
        stat_load_use_stalls  : out std_logic_vector(31 downto 0);
        stat_bulk_load_stalls : out std_logic_vector(31 downto 0);
        stat_flag_stalls      : out std_logic_vector(31 downto 0);
        stat_branch_flushes   : out std_logic_vector(31 downto 0);
        stat_halt_events      : out std_logic_vector(31 downto 0);
        stat_seg_prologue     : out std_logic_vector(31 downto 0);
        stat_seg_input_load   : out std_logic_vector(31 downto 0);
        stat_seg_stage1       : out std_logic_vector(31 downto 0);
        stat_seg_stage2       : out std_logic_vector(31 downto 0);
        stat_seg_stage3       : out std_logic_vector(31 downto 0);
        stat_seg_twiddle      : out std_logic_vector(31 downto 0);
        stat_seg_output       : out std_logic_vector(31 downto 0);
        stat_seg_done         : out std_logic_vector(31 downto 0)
    );
end entity mcu_fft_system_pipe5;

architecture rtl of mcu_fft_system_pipe5 is
    type state_t is (
        S_LOAD_REQ,
        S_LOAD_WAIT,
        S_LOAD_STREAM,
        S_RUN,
        S_DUMP_WRITE,
        S_DONE
    );

    signal state : state_t := S_LOAD_REQ;
    signal load_idx : integer range 0 to INPUT_COUNT - 1 := 0;
    signal dump_idx : integer range 0 to OUTPUT_COUNT - 1 := 0;

    signal core_rst          : std_logic := '1';
    signal core_input_we     : std_logic := '0';
    signal core_input_waddr  : std_logic_vector(7 downto 0) := (others => '0');
    signal core_input_wdata  : std_logic_vector(15 downto 0) := (others => '0');
    signal core_output_raddr : std_logic_vector(5 downto 0) := (others => '0');
    signal core_output_rdata : std_logic_vector(15 downto 0);

    signal core_halted  : std_logic;
    signal core_illegal : std_logic;
    signal core_flag_z  : std_logic;
    signal core_flag_n  : std_logic;
    signal core_stat_core_cycles : std_logic_vector(31 downto 0);
    signal core_stat_issue_count : std_logic_vector(31 downto 0);
    signal core_stat_load_use_stalls : std_logic_vector(31 downto 0);
    signal core_stat_bulk_load_stalls : std_logic_vector(31 downto 0);
    signal core_stat_flag_stalls : std_logic_vector(31 downto 0);
    signal core_stat_branch_flushes : std_logic_vector(31 downto 0);
    signal core_stat_halt_events : std_logic_vector(31 downto 0);
    signal core_stat_seg_prologue : std_logic_vector(31 downto 0);
    signal core_stat_seg_input_load : std_logic_vector(31 downto 0);
    signal core_stat_seg_stage1 : std_logic_vector(31 downto 0);
    signal core_stat_seg_stage2 : std_logic_vector(31 downto 0);
    signal core_stat_seg_stage3 : std_logic_vector(31 downto 0);
    signal core_stat_seg_twiddle : std_logic_vector(31 downto 0);
    signal core_stat_seg_output : std_logic_vector(31 downto 0);
    signal core_stat_seg_done : std_logic_vector(31 downto 0);
begin
    assert INPUT_COUNT <= 256
        report "mcu_fft_system_pipe5 INPUT_COUNT must fit test_rom_addr[7:0]"
        severity failure;
    assert INPUT_ROM_BASE + INPUT_COUNT <= 256
        report "mcu_fft_system_pipe5 input ROM window must fit test_rom_addr[7:0]"
        severity failure;
    assert INPUT_MEM_BASE + INPUT_COUNT <= 256
        report "mcu_fft_system_pipe5 input memory window must fit input_waddr[7:0]"
        severity failure;
    assert OUTPUT_COUNT <= 64
        report "mcu_fft_system_pipe5 OUTPUT_COUNT must fit verify_ram_addr[5:0]"
        severity failure;
    assert CORE_RELEASE_LOAD_IDX < INPUT_COUNT
        report "mcu_fft_system_pipe5 CORE_RELEASE_LOAD_IDX must be inside input load window"
        severity failure;

    u_core : entity work.mcu_v1_core_pipe5
        generic map (
            MEM_FILE  => MEM_FILE,
            ROM_DEPTH => CORE_ROM_DEPTH
        )
        port map (
            clk           => clk,
            rst           => core_rst,
            input_we      => core_input_we,
            input_waddr   => core_input_waddr,
            input_wdata   => core_input_wdata,
            output_raddr  => core_output_raddr,
            output_rdata  => core_output_rdata,
            pc_debug      => pc_debug,
            instr_debug   => instr_debug,
            halted_debug  => core_halted,
            illegal_debug => core_illegal,
            flag_z_debug  => core_flag_z,
            flag_n_debug  => core_flag_n,
            stat_core_cycles => core_stat_core_cycles,
            stat_issue_count => core_stat_issue_count,
            stat_load_use_stalls => core_stat_load_use_stalls,
            stat_bulk_load_stalls => core_stat_bulk_load_stalls,
            stat_flag_stalls => core_stat_flag_stalls,
            stat_branch_flushes => core_stat_branch_flushes,
            stat_halt_events => core_stat_halt_events,
            stat_seg_prologue => core_stat_seg_prologue,
            stat_seg_input_load => core_stat_seg_input_load,
            stat_seg_stage1 => core_stat_seg_stage1,
            stat_seg_stage2 => core_stat_seg_stage2,
            stat_seg_stage3 => core_stat_seg_stage3,
            stat_seg_twiddle => core_stat_seg_twiddle,
            stat_seg_output => core_stat_seg_output,
            stat_seg_done => core_stat_seg_done
        );

    illegal <= core_illegal;
    done <= '1' when state = S_DONE else '0';
    stat_core_cycles <= core_stat_core_cycles;
    stat_issue_count <= core_stat_issue_count;
    stat_load_use_stalls <= core_stat_load_use_stalls;
    stat_bulk_load_stalls <= core_stat_bulk_load_stalls;
    stat_flag_stalls <= core_stat_flag_stalls;
    stat_branch_flushes <= core_stat_branch_flushes;
    stat_halt_events <= core_stat_halt_events;
    stat_seg_prologue <= core_stat_seg_prologue;
    stat_seg_input_load <= core_stat_seg_input_load;
    stat_seg_stage1 <= core_stat_seg_stage1;
    stat_seg_stage2 <= core_stat_seg_stage2;
    stat_seg_stage3 <= core_stat_seg_stage3;
    stat_seg_twiddle <= core_stat_seg_twiddle;
    stat_seg_output <= core_stat_seg_output;
    stat_seg_done <= core_stat_seg_done;

    process(clk)
        variable last_input  : integer;
        variable last_output : integer;
    begin
        if rising_edge(clk) then
            last_input := INPUT_COUNT - 1;
            last_output := OUTPUT_COUNT - 1;

            if rst = '1' then
                state <= S_LOAD_REQ;
                load_idx <= 0;
                dump_idx <= 0;
                core_rst <= '1';
                core_input_we <= '0';
                core_input_waddr <= (others => '0');
                core_input_wdata <= (others => '0');
                core_output_raddr <= (others => '0');
                test_rom_addr <= (others => '0');
                test_rom_en <= '0';
                verify_ram_addr <= (others => '0');
                verify_ram_we <= '0';
                verify_vector_out <= (others => '0');
                cnt_start <= '0';
                cnt_stop <= '0';
            else
                core_input_we <= '0';
                test_rom_en <= '0';
                verify_ram_we <= '0';
                cnt_start <= '0';
                cnt_stop <= '0';

                case state is
                    when S_LOAD_REQ =>
                        core_rst <= '1';
                        test_rom_en <= '1';
                        test_rom_addr <= std_logic_vector(to_unsigned(INPUT_ROM_BASE + load_idx, 8));
                        state <= S_LOAD_WAIT;

                    when S_LOAD_WAIT =>
                        core_rst <= '1';
                        test_rom_en <= '1';
                        load_idx <= 0;
                        if last_input = 0 then
                            test_rom_addr <= std_logic_vector(to_unsigned(INPUT_ROM_BASE, 8));
                        else
                            test_rom_addr <= std_logic_vector(to_unsigned(INPUT_ROM_BASE + 1, 8));
                        end if;
                        state <= S_LOAD_STREAM;

                    when S_LOAD_STREAM =>
                        if load_idx >= CORE_RELEASE_LOAD_IDX then
                            core_rst <= '0';
                        else
                            core_rst <= '1';
                        end if;
                        core_input_we <= '1';
                        core_input_waddr <= std_logic_vector(to_unsigned(INPUT_MEM_BASE + load_idx, 8));
                        core_input_wdata <= test_vector_in;
                        if load_idx = 0 then
                            cnt_start <= '1';
                        end if;
                        if load_idx = last_input then
                            load_idx <= 0;
                            core_rst <= '0';
                            state <= S_RUN;
                        else
                            if load_idx + 1 < last_input then
                                test_rom_en <= '1';
                                test_rom_addr <= std_logic_vector(to_unsigned(INPUT_ROM_BASE + load_idx + 2, 8));
                            end if;
                            load_idx <= load_idx + 1;
                            state <= S_LOAD_STREAM;
                        end if;

                    when S_RUN =>
                        core_rst <= '0';
                        if core_halted = '1' or core_illegal = '1' then
                            verify_ram_we <= '1';
                            verify_ram_addr <= (others => '0');
                            verify_vector_out <= core_output_rdata;
                            if last_output = 0 then
                                cnt_stop <= '1';
                                state <= S_DONE;
                            else
                                dump_idx <= 1;
                                core_output_raddr <= std_logic_vector(to_unsigned(1, 6));
                                state <= S_DUMP_WRITE;
                            end if;
                        end if;

                    when S_DUMP_WRITE =>
                        core_rst <= '0';
                        verify_ram_we <= '1';
                        verify_ram_addr <= std_logic_vector(to_unsigned(dump_idx, 6));
                        verify_vector_out <= core_output_rdata;
                        if dump_idx = last_output then
                            cnt_stop <= '1';
                            state <= S_DONE;
                        else
                            dump_idx <= dump_idx + 1;
                            core_output_raddr <= std_logic_vector(to_unsigned(dump_idx + 1, 6));
                            state <= S_DUMP_WRITE;
                        end if;

                    when S_DONE =>
                        core_rst <= '0';
                        null;
                end case;
            end if;
        end if;
    end process;
end architecture rtl;
