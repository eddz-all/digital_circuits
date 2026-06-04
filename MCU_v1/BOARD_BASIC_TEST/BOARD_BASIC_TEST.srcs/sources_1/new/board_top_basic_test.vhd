library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity board_top_basic_test is
    port (
        clk_in1 : in std_logic;
        rst_btn : in std_logic
    );
end entity board_top_basic_test;

architecture rtl of board_top_basic_test is
    type state_t is (
        S_LOAD0,
        S_LOAD1,
        S_RUN,
        S_DUMP_ADDR,
        S_DUMP_WRITE,
        S_DONE
    );

    type readback_state_t is (
        RB_IDLE,
        RB_WAIT1,
        RB_WAIT2,
        RB_CAPTURE,
        RB_NEXT,
        RB_DONE
    );

    component clk_wiz_0
        port (
            clk_out1 : out std_logic;
            reset    : in  std_logic;
            locked   : out std_logic;
            clk_in1  : in  std_logic
        );
    end component;

    component verify_RAM
        port (
            clka  : in  std_logic;
            ena   : in  std_logic;
            wea   : in  std_logic_vector(0 downto 0);
            addra : in  std_logic_vector(5 downto 0);
            dina  : in  std_logic_vector(15 downto 0);
            douta : out std_logic_vector(15 downto 0)
        );
    end component;

    component ila_0
        port (
            clk    : in std_logic;
            probe0 : in std_logic_vector(15 downto 0);
            probe1 : in std_logic_vector(19 downto 0);
            probe2 : in std_logic_vector(5 downto 0);
            probe3 : in std_logic_vector(15 downto 0);
            probe4 : in std_logic_vector(0 downto 0);
            probe5 : in std_logic_vector(0 downto 0);
            probe6 : in std_logic_vector(0 downto 0);
            probe7 : in std_logic_vector(0 downto 0)
        );
    end component;

    signal sys_clk    : std_logic;
    signal clk_locked : std_logic;
    signal sys_rst    : std_logic;

    signal state : state_t := S_LOAD0;

    signal core_rst          : std_logic := '1';
    signal core_input_we     : std_logic := '0';
    signal core_input_waddr  : std_logic_vector(5 downto 0) := (others => '0');
    signal core_input_wdata  : std_logic_vector(15 downto 0) := (others => '0');
    signal core_output_raddr : std_logic_vector(5 downto 0) := (others => '0');
    signal core_output_rdata : std_logic_vector(15 downto 0);
    signal core_halted       : std_logic;
    signal core_illegal      : std_logic;
    signal core_flag_z       : std_logic;
    signal core_flag_n       : std_logic;
    signal pc_debug          : std_logic_vector(31 downto 0);
    signal instr_debug       : std_logic_vector(31 downto 0);

    signal dump_idx : unsigned(5 downto 0) := (others => '0');

    signal verify_ram_write_addr : std_logic_vector(5 downto 0) := (others => '0');
    signal verify_ram_addr       : std_logic_vector(5 downto 0);
    signal verify_ram_we         : std_logic := '0';
    signal verify_ram_we_vec     : std_logic_vector(0 downto 0);
    signal verify_vector_out     : std_logic_vector(15 downto 0) := (others => '0');
    signal verify_ram_q          : std_logic_vector(15 downto 0);

    signal readback_state        : readback_state_t := RB_IDLE;
    signal verify_readback_addr  : unsigned(5 downto 0) := (others => '0');
    signal verify_readback_valid : std_logic := '0';
    signal verify_readback_data  : std_logic_vector(15 downto 0) := (others => '0');
    signal verify_readback_addr_q : std_logic_vector(5 downto 0) := (others => '0');
    signal verify_ila_addr       : std_logic_vector(5 downto 0);

    signal cnt_start  : std_logic := '0';
    signal cnt_stop   : std_logic := '0';
    signal cnt_active : std_logic := '0';
    signal cnt_test   : unsigned(19 downto 0) := (others => '0');

    signal done : std_logic;
    signal ila_readback_valid : std_logic_vector(0 downto 0);
    signal ila_verify_ram_we  : std_logic_vector(0 downto 0);
    signal ila_done           : std_logic_vector(0 downto 0);
    signal ila_illegal        : std_logic_vector(0 downto 0);

    -- synthesis translate_off
    type sim_sample_array_t is array (0 to 15) of integer;
    constant SIM_EXPECTED_OUTPUT : sim_sample_array_t := (
        500, 1500, 707, 520,
        -20, 123, 0, 0,
        0, 0, 0, 0,
        0, 0, 0, 0
    );

    function sim_slv16(value : integer) return std_logic_vector is
    begin
        return std_logic_vector(to_signed(value, 16));
    end function;
    -- synthesis translate_on
begin
    u_clk_wiz : clk_wiz_0
        port map (
            clk_out1 => sys_clk,
            reset    => '0',
            locked   => clk_locked,
            clk_in1  => clk_in1
        );

    sys_rst <= rst_btn or (not clk_locked);
    done <= '1' when state = S_DONE else '0';

    verify_ram_addr <= std_logic_vector(verify_readback_addr)
                       when readback_state = RB_WAIT1 or
                            readback_state = RB_WAIT2 or
                            readback_state = RB_CAPTURE or
                            readback_state = RB_NEXT
                       else verify_ram_write_addr;

    verify_ila_addr <= verify_readback_addr_q
                       when readback_state = RB_WAIT1 or
                            readback_state = RB_WAIT2 or
                            readback_state = RB_CAPTURE or
                            readback_state = RB_NEXT or
                            readback_state = RB_DONE
                       else verify_ram_write_addr;

    verify_ram_we_vec(0) <= verify_ram_we;
    ila_readback_valid(0) <= verify_readback_valid;
    ila_verify_ram_we(0) <= verify_ram_we;
    ila_done(0) <= done;
    ila_illegal(0) <= core_illegal;

    u_core : entity work.mcu_v1_core
        generic map (
            MEM_FILE  => "asm/test_mcu_v1_basic.mem",
            ROM_DEPTH => 1024
        )
        port map (
            clk           => sys_clk,
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
            flag_n_debug  => core_flag_n
        );

    u_verify_ram : verify_RAM
        port map (
            clka  => sys_clk,
            ena   => '1',
            wea   => verify_ram_we_vec,
            addra => verify_ram_addr,
            dina  => verify_vector_out,
            douta => verify_ram_q
        );

    process(sys_clk)
    begin
        if rising_edge(sys_clk) then
            if sys_rst = '1' then
                state <= S_LOAD0;
                core_rst <= '1';
                core_input_we <= '0';
                core_input_waddr <= (others => '0');
                core_input_wdata <= (others => '0');
                core_output_raddr <= (others => '0');
                dump_idx <= (others => '0');
                verify_ram_write_addr <= (others => '0');
                verify_ram_we <= '0';
                verify_vector_out <= (others => '0');
                cnt_start <= '0';
                cnt_stop <= '0';
            else
                core_input_we <= '0';
                verify_ram_we <= '0';
                cnt_start <= '0';
                cnt_stop <= '0';

                case state is
                    when S_LOAD0 =>
                        core_rst <= '1';
                        core_input_we <= '1';
                        core_input_waddr <= std_logic_vector(to_unsigned(0, 6));
                        core_input_wdata <= std_logic_vector(to_signed(1000, 16));
                        cnt_start <= '1';
                        state <= S_LOAD1;

                    when S_LOAD1 =>
                        core_rst <= '1';
                        core_input_we <= '1';
                        core_input_waddr <= std_logic_vector(to_unsigned(1, 6));
                        core_input_wdata <= std_logic_vector(to_signed(-500, 16));
                        state <= S_RUN;

                    when S_RUN =>
                        core_rst <= '0';
                        if core_halted = '1' or core_illegal = '1' then
                            dump_idx <= (others => '0');
                            core_output_raddr <= (others => '0');
                            state <= S_DUMP_ADDR;
                        end if;

                    when S_DUMP_ADDR =>
                        core_rst <= '0';
                        core_output_raddr <= std_logic_vector(dump_idx);
                        state <= S_DUMP_WRITE;

                    when S_DUMP_WRITE =>
                        core_rst <= '0';
                        verify_ram_we <= '1';
                        verify_ram_write_addr <= std_logic_vector(dump_idx);
                        verify_vector_out <= core_output_rdata;
                        if dump_idx = to_unsigned(15, 6) then
                            cnt_stop <= '1';
                            state <= S_DONE;
                        else
                            dump_idx <= dump_idx + 1;
                            state <= S_DUMP_ADDR;
                        end if;

                    when S_DONE =>
                        core_rst <= '0';
                end case;
            end if;
        end if;
    end process;

    process(sys_clk)
    begin
        if rising_edge(sys_clk) then
            if sys_rst = '1' then
                cnt_active <= '0';
                cnt_test <= (others => '0');
            else
                if cnt_start = '1' and cnt_active = '0' then
                    cnt_active <= '1';
                    cnt_test <= cnt_test + 1;
                elsif cnt_active = '1' then
                    cnt_test <= cnt_test + 1;
                end if;

                if cnt_stop = '1' then
                    cnt_active <= '0';
                end if;
            end if;
        end if;
    end process;

    process(sys_clk)
    begin
        if rising_edge(sys_clk) then
            if sys_rst = '1' then
                readback_state <= RB_IDLE;
                verify_readback_addr <= (others => '0');
                verify_readback_valid <= '0';
                verify_readback_data <= (others => '0');
                verify_readback_addr_q <= (others => '0');
            else
                verify_readback_valid <= '0';

                case readback_state is
                    when RB_IDLE =>
                        if done = '1' then
                            verify_readback_addr <= (others => '0');
                            readback_state <= RB_WAIT1;
                        end if;

                    when RB_WAIT1 =>
                        readback_state <= RB_WAIT2;

                    when RB_WAIT2 =>
                        readback_state <= RB_CAPTURE;

                    when RB_CAPTURE =>
                        verify_readback_addr_q <= std_logic_vector(verify_readback_addr);
                        verify_readback_data <= verify_ram_q;
                        verify_readback_valid <= '1';
                        readback_state <= RB_NEXT;

                    when RB_NEXT =>
                        if verify_readback_addr = to_unsigned(15, 6) then
                            readback_state <= RB_DONE;
                        else
                            verify_readback_addr <= verify_readback_addr + 1;
                            readback_state <= RB_WAIT1;
                        end if;

                    when RB_DONE =>
                        null;
                end case;
            end if;
        end if;
    end process;

    u_ila : ila_0
        port map (
            clk    => sys_clk,
            probe0 => core_input_wdata,
            probe1 => std_logic_vector(cnt_test),
            probe2 => verify_ila_addr,
            probe3 => verify_readback_data,
            probe4 => ila_readback_valid,
            probe5 => ila_verify_ram_we,
            probe6 => ila_done,
            probe7 => ila_illegal
        );

    -- synthesis translate_off
    sim_checker : process(sys_clk)
        variable checked_output_count : natural := 0;
        variable output_mismatch_count : natural := 0;
        variable readback_done_checked : boolean := false;
        variable addr : integer range 0 to 63 := 0;
    begin
        if rising_edge(sys_clk) then
            if sys_rst = '1' then
                checked_output_count := 0;
                output_mismatch_count := 0;
                readback_done_checked := false;
            else
                if core_input_we = '1' then
                    report "board_top_basic_test sim: input_mem["
                        & integer'image(to_integer(unsigned(core_input_waddr)))
                        & "] <= "
                        & integer'image(to_integer(signed(core_input_wdata)))
                        severity note;
                end if;

                if verify_ram_we = '1' then
                    report "board_top_basic_test sim: write verify_RAM["
                        & integer'image(to_integer(unsigned(verify_ram_write_addr)))
                        & "] <= "
                        & integer'image(to_integer(signed(verify_vector_out)))
                        severity note;
                end if;

                if verify_readback_valid = '1' then
                    addr := to_integer(unsigned(verify_readback_addr_q));
                    assert addr <= 15
                        report "verify_RAM readback address out of range"
                        severity failure;
                    report "board_top_basic_test sim: verify_RAM["
                        & integer'image(addr)
                        & "] got "
                        & integer'image(to_integer(signed(verify_readback_data)))
                        & ", expected "
                        & integer'image(SIM_EXPECTED_OUTPUT(addr))
                        severity note;
                    if verify_readback_data /= sim_slv16(SIM_EXPECTED_OUTPUT(addr)) then
                        output_mismatch_count := output_mismatch_count + 1;
                        report "verify_RAM[" & integer'image(addr)
                            & "] readback mismatch noted: got "
                            & integer'image(to_integer(signed(verify_readback_data)))
                            & ", expected "
                            & integer'image(SIM_EXPECTED_OUTPUT(addr))
                            severity warning;
                    end if;
                    checked_output_count := checked_output_count + 1;
                end if;

                if readback_state = RB_DONE and not readback_done_checked then
                    assert checked_output_count = 16
                        report "expected 16 verify_RAM readback samples, got "
                            & integer'image(checked_output_count)
                        severity failure;
                    assert output_mismatch_count = 0
                        report "verify_RAM readback had "
                            & integer'image(output_mismatch_count)
                            & " mismatched samples"
                        severity failure;
                    assert core_illegal = '0'
                        report "basic program hit illegal instruction"
                        severity failure;
                    report "board_top_basic_test sim: verify_RAM readback checks passed" severity note;
                    readback_done_checked := true;
                end if;
            end if;
        end if;
    end process;
    -- synthesis translate_on
end architecture rtl;
