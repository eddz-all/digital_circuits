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
            addra : in  std_logic_vector(7 downto 0);
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

            test_rom_addr : out std_logic_vector(7 downto 0);
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

    signal test_rom_addr : std_logic_vector(7 downto 0);
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
        -13, -29, -29, 0,
        -9, 27, 6, 20,
        27, -9, -18, -23,
        0, 18, -21, -20
    );
    constant SIM_EXPECTED_OUTPUT : sim_sample_array_t := (
        -3456, -6134, 6784, -350,
        -8064, 5878, -6528, -1442,
        -5888, 12668, 11264, 8076,
        2816, 3204, 5632, -10124
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
        variable rom_addr_d1 : integer range 0 to 255 := 0;
        variable printed_rom_count : natural := 0;
        variable printed_readback_count : natural := 0;
        variable readback_done_printed : boolean := false;
        variable addr : integer range 0 to 63 := 0;
    begin
        if rising_edge(sys_clk) then
            if sys_rst = '1' then
                rom_en_d1 := '0';
                rom_addr_d1 := 0;
                printed_rom_count := 0;
                printed_readback_count := 0;
                readback_done_printed := false;
            else
                if rom_en_d1 = '1' and printed_rom_count < 16 then
                    report "ROM_BUS: addr="
                        & integer'image(rom_addr_d1)
                        & " data="
                        & integer'image(to_integer(signed(test_vector_in)))
                        severity note;
                    printed_rom_count := printed_rom_count + 1;
                    if printed_rom_count = 16 then
                        report "ROM_BUS: printed 16 samples" severity note;
                    end if;
                end if;

                rom_en_d1 := '0';
                if test_rom_en = '1' and printed_rom_count < 16 then
                    rom_addr_d1 := to_integer(unsigned(test_rom_addr));
                    rom_en_d1 := '1';
                end if;

                if verify_ram_we = '1' then
                    report "VERIFY_WRITE: addr="
                        & integer'image(to_integer(unsigned(verify_ram_addr)))
                        & " data="
                        & integer'image(to_integer(signed(verify_vector_out)))
                        severity note;
                end if;

                if verify_readback_valid = '1' then
                    addr := to_integer(unsigned(verify_readback_addr_q));
                    report "VERIFY_READ: addr="
                        & integer'image(addr)
                        & " data="
                        & integer'image(to_integer(signed(verify_readback_data)))
                        severity note;
                    printed_readback_count := printed_readback_count + 1;
                end if;

                if readback_state = RB_DONE and not readback_done_printed then
                    report "VERIFY_READ: printed "
                        & integer'image(printed_readback_count)
                        & " samples"
                        severity note;
                    readback_done_printed := true;
                end if;
            end if;
        end if;
    end process;
    -- synthesis translate_on

end architecture rtl;
