library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity board_top is
    port (
        clk_in1 : in std_logic;
        rst_btn : in std_logic
    );
end entity board_top;

architecture rtl of board_top is
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

    component test_ROM
        port (
            clka  : in  std_logic;
            ena   : in  std_logic;
            wea   : in  std_logic_vector(0 downto 0);
            addra : in  std_logic_vector(5 downto 0);
            dina  : in  std_logic_vector(15 downto 0);
            douta : out std_logic_vector(15 downto 0)
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

    component mcu_fft_system
        port (
            clk : in std_logic;
            rst : in std_logic;

            test_rom_addr : out std_logic_vector(5 downto 0);
            test_rom_en   : out std_logic;
            test_vector_in : in  std_logic_vector(15 downto 0);

            verify_ram_addr : out std_logic_vector(5 downto 0);
            verify_ram_we   : out std_logic;
            verify_vector_out : out std_logic_vector(15 downto 0);

            cnt_start : out std_logic;
            cnt_stop  : out std_logic;

            done         : out std_logic;
            illegal      : out std_logic;
            pc_debug     : out std_logic_vector(31 downto 0);
            instr_debug  : out std_logic_vector(31 downto 0)
        );
    end component;

    signal sys_clk    : std_logic;
    signal clk_locked : std_logic;
    signal sys_rst    : std_logic;

    signal test_rom_addr : std_logic_vector(5 downto 0);
    signal test_rom_en   : std_logic;
    signal test_rom_we   : std_logic_vector(0 downto 0) := "0";
    signal test_vector_in : std_logic_vector(15 downto 0);

    signal verify_ram_write_addr : std_logic_vector(5 downto 0);
    signal verify_ram_addr       : std_logic_vector(5 downto 0);
    signal verify_ram_we   : std_logic;
    signal verify_ram_we_vec : std_logic_vector(0 downto 0);
    signal verify_vector_out : std_logic_vector(15 downto 0);
    signal verify_ram_q      : std_logic_vector(15 downto 0);
    signal readback_state       : readback_state_t := RB_IDLE;
    signal verify_readback_addr   : unsigned(5 downto 0) := (others => '0');
    signal verify_readback_valid  : std_logic := '0';
    signal verify_readback_data   : std_logic_vector(15 downto 0) := (others => '0');
    signal verify_readback_addr_q : std_logic_vector(5 downto 0) := (others => '0');
    signal verify_ila_addr        : std_logic_vector(5 downto 0);

    signal cnt_start  : std_logic;
    signal cnt_stop   : std_logic;
    signal cnt_active : std_logic := '0';
    signal cnt_test   : unsigned(19 downto 0) := (others => '0');

    signal done        : std_logic;
    signal illegal     : std_logic;
    signal pc_debug    : std_logic_vector(31 downto 0);
    signal instr_debug : std_logic_vector(31 downto 0);
    signal ila_readback_valid : std_logic_vector(0 downto 0);
    signal ila_verify_ram_we  : std_logic_vector(0 downto 0);
    signal ila_done           : std_logic_vector(0 downto 0);
    signal ila_illegal        : std_logic_vector(0 downto 0);

    -- synthesis translate_off
    type sim_sample_array_t is array (0 to 15) of integer;
    constant SIM_EXPECTED_INPUT : sim_sample_array_t := (
        0, 0, 32760, 0,
        0, 0, 0, 0,
        0, 0, 0, 0,
        0, 0, 0, 0
    );
    constant SIM_EXPECTED_OUTPUT : sim_sample_array_t := (
        4095, 0, -4095, 0,
        0, -4095, 0, 4095,
        2895, -2896, -2896, 2896,
        -2896, -2896, 2896, 2895
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

    test_rom_we <= "0";
    verify_ram_we_vec(0) <= verify_ram_we;
    ila_readback_valid(0) <= verify_readback_valid;
    ila_verify_ram_we(0) <= verify_ram_we;
    ila_done(0) <= done;
    ila_illegal(0) <= illegal;

    u_test_rom : test_ROM
        port map (
            clka  => sys_clk,
            ena   => test_rom_en,
            wea   => test_rom_we,
            addra => test_rom_addr,
            dina  => (others => '0'),
            douta => test_vector_in
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

    u_mcu_fft_system : mcu_fft_system
        port map (
            clk             => sys_clk,
            rst             => sys_rst,
            test_rom_addr   => test_rom_addr,
            test_rom_en     => test_rom_en,
            test_vector_in  => test_vector_in,
            verify_ram_addr => verify_ram_write_addr,
            verify_ram_we   => verify_ram_we,
            verify_vector_out => verify_vector_out,
            cnt_start       => cnt_start,
            cnt_stop        => cnt_stop,
            done            => done,
            illegal         => illegal,
            pc_debug        => pc_debug,
            instr_debug     => instr_debug
        );

    process(sys_clk)
    begin
        if rising_edge(sys_clk) then
            if sys_rst = '1' then
                cnt_active <= '0';
                cnt_test   <= (others => '0');
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
                readback_state         <= RB_IDLE;
                verify_readback_addr   <= (others => '0');
                verify_readback_valid  <= '0';
                verify_readback_data   <= (others => '0');
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
            probe0 => test_vector_in,
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
        variable rom_en_d1 : std_logic := '0';
        variable rom_en_d2 : std_logic := '0';
        variable rom_addr_d1 : integer range 0 to 63 := 0;
        variable rom_addr_d2 : integer range 0 to 63 := 0;
        variable last_accepted_rom_addr : integer range -1 to 63 := -1;
        variable expected_next_rom_addr : natural := 0;
        variable checked_input_count : natural := 0;
        variable checked_output_count : natural := 0;
        variable output_mismatch_count : natural := 0;
        variable readback_done_checked : boolean := false;
        variable addr : integer range 0 to 63 := 0;
    begin
        if rising_edge(sys_clk) then
            if sys_rst = '1' then
                rom_en_d1 := '0';
                rom_en_d2 := '0';
                rom_addr_d1 := 0;
                rom_addr_d2 := 0;
                last_accepted_rom_addr := -1;
                expected_next_rom_addr := 0;
                checked_input_count := 0;
                checked_output_count := 0;
                output_mismatch_count := 0;
                readback_done_checked := false;
            else
                if rom_en_d2 = '1' and checked_input_count < 16 then
                    assert test_vector_in = sim_slv16(SIM_EXPECTED_INPUT(rom_addr_d2))
                        report "test_vector_in mismatch for test_ROM["
                            & integer'image(rom_addr_d2) & "]"
                        severity failure;
                    checked_input_count := checked_input_count + 1;
                    if checked_input_count = 16 then
                        report "board_top sim: input sequence checks passed" severity note;
                    end if;
                end if;

                rom_en_d2 := rom_en_d1;
                rom_addr_d2 := rom_addr_d1;
                rom_en_d1 := '0';

                if test_rom_en = '1' and expected_next_rom_addr < 16 and
                   to_integer(unsigned(test_rom_addr)) /= last_accepted_rom_addr then
                    addr := to_integer(unsigned(test_rom_addr));
                    assert addr = expected_next_rom_addr
                        report "test_ROM address expected "
                            & integer'image(expected_next_rom_addr)
                            & ", got " & integer'image(addr)
                        severity failure;
                    rom_addr_d1 := addr;
                    last_accepted_rom_addr := addr;
                    rom_en_d1 := '1';
                    expected_next_rom_addr := expected_next_rom_addr + 1;
                end if;

                if verify_ram_we = '1' then
                    report "board_top sim: write verify_RAM["
                        & integer'image(to_integer(unsigned(verify_ram_addr)))
                        & "] <= "
                        & integer'image(to_integer(signed(verify_vector_out)))
                        severity note;
                end if;

                if verify_readback_valid = '1' then
                    addr := to_integer(unsigned(verify_readback_addr_q));
                    assert addr <= 15
                        report "verify_RAM readback address out of range"
                        severity failure;
                    report "board_top sim: verify_RAM["
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
                    report "board_top sim: verify_RAM readback checks passed" severity note;
                    readback_done_checked := true;
                end if;
            end if;
        end if;
    end process;
    -- synthesis translate_on

end architecture rtl;
