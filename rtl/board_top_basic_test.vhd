library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.mcu4_multi_pkg.all;

entity board_top_basic_test is
    port (
        clk_in1 : in  std_logic;
        rst_btn : in  std_logic;
        test    : out std_logic
    );
end entity board_top_basic_test;

architecture rtl of board_top_basic_test is
    component ila_basic
        port (
            clk    : in std_logic;
            probe0 : in std_logic_vector(0 downto 0);
            probe1 : in std_logic_vector(0 downto 0);
            probe2 : in std_logic_vector(3 downto 0);
            probe3 : in std_logic_vector(3 downto 0)
        );
    end component;

    type state_t is (
        S_INIT_BANK0,
        S_INIT_BANK1,
        S_RUN,
        S_CHECK_MOV,
        S_CHECK_ADD,
        S_CHECK_SUB,
        S_CHECK_AND,
        S_CHECK_ORR,
        S_CHECK_LDR,
        S_CHECK_CONTROL,
        S_CHECK_BANK1,
        S_DONE
    );

    constant TIMEOUT_CYCLES : unsigned(7 downto 0) := to_unsigned(120, 8);
    constant ERROR_NONE        : std_logic_vector(3 downto 0) := x"0";
    constant ERROR_ILLEGAL     : std_logic_vector(3 downto 0) := x"1";
    constant ERROR_TIMEOUT     : std_logic_vector(3 downto 0) := x"2";
    constant ERROR_MOV         : std_logic_vector(3 downto 0) := x"3";
    constant ERROR_ADD         : std_logic_vector(3 downto 0) := x"4";
    constant ERROR_SUB         : std_logic_vector(3 downto 0) := x"5";
    constant ERROR_AND         : std_logic_vector(3 downto 0) := x"6";
    constant ERROR_ORR         : std_logic_vector(3 downto 0) := x"7";
    constant ERROR_LDR         : std_logic_vector(3 downto 0) := x"8";
    constant ERROR_CONTROL     : std_logic_vector(3 downto 0) := x"9";
    constant ERROR_BANK1_DIRTY : std_logic_vector(3 downto 0) := x"A";

    constant ADDR_INPUT   : natural := 0;
    constant ADDR_MOV     : natural := 1;
    constant ADDR_ADD     : natural := 2;
    constant ADDR_SUB     : natural := 3;
    constant ADDR_AND     : natural := 4;
    constant ADDR_ORR     : natural := 5;
    constant ADDR_LDR     : natural := 6;
    constant ADDR_CONTROL : natural := 7;

    constant EXPECT_INPUT   : word_t := x"00000005";
    constant EXPECT_MOV     : word_t := x"00000007";
    constant EXPECT_ADD     : word_t := x"0000000A";
    constant EXPECT_SUB     : word_t := x"00000007";
    constant EXPECT_AND     : word_t := x"00000002";
    constant EXPECT_ORR     : word_t := x"00000003";
    constant EXPECT_LDR     : word_t := x"00000005";
    constant EXPECT_CONTROL : word_t := x"0000000F";

    signal sys_clk : std_logic;
    signal sys_rst : std_logic;

    signal state : state_t := S_INIT_BANK0;
    signal init_idx : natural range 0 to 7 := 0;
    signal bank1_check_idx : natural range 0 to 7 := 0;

    signal core_rst : std_logic := '1';
    signal dmem_we : std_logic := '0';
    signal dmem_wbank : std_logic := '0';
    signal dmem_waddr : std_logic_vector(2 downto 0) := (others => '0');
    signal dmem_wdata : word_t := (others => '0');
    signal dmem_rbank : std_logic := '0';
    signal dmem_raddr : std_logic_vector(2 downto 0) := (others => '0');
    signal dmem_rdata : word_t;

    signal halted      : std_logic;
    signal illegal     : std_logic;
    signal pc_debug    : word_t;
    signal instr_debug : word_t;
    signal flag_z_debug : std_logic;
    signal flag_n_debug : std_logic;

    signal test_reg  : std_logic := '1';
    signal test_vec  : std_logic_vector(0 downto 0);
    signal rst_vec   : std_logic_vector(0 downto 0);
    signal error_code : std_logic_vector(3 downto 0) := ERROR_NONE;
    signal state_code : std_logic_vector(3 downto 0) := (others => '0');
    signal done_seen : std_logic := '0';
    signal cycle_count : unsigned(7 downto 0) := (others => '0');

begin
    sys_clk <= clk_in1;
    sys_rst <= rst_btn;
    test <= test_reg;
    test_vec(0) <= test_reg;
    rst_vec(0) <= sys_rst;
    with state select state_code <=
        x"0" when S_INIT_BANK0,
        x"1" when S_INIT_BANK1,
        x"2" when S_RUN,
        x"3" when S_CHECK_MOV,
        x"4" when S_CHECK_ADD,
        x"5" when S_CHECK_SUB,
        x"6" when S_CHECK_AND,
        x"7" when S_CHECK_ORR,
        x"8" when S_CHECK_LDR,
        x"9" when S_CHECK_CONTROL,
        x"A" when S_CHECK_BANK1,
        x"B" when S_DONE;

    u_core : entity work.mcu4_multicycle_core
        generic map (
            PROGRAM_ID   => 1,
            ACTIVE_CORES => 1
        )
        port map (
            clk           => sys_clk,
            rst           => core_rst,
            dmem_we       => dmem_we,
            dmem_wbank    => dmem_wbank,
            dmem_waddr    => dmem_waddr,
            dmem_wdata    => dmem_wdata,
            dmem_rbank    => dmem_rbank,
            dmem_raddr    => dmem_raddr,
            dmem_rdata    => dmem_rdata,
            pc_debug      => pc_debug,
            instr_debug   => instr_debug,
            halted_debug  => halted,
            illegal_debug => illegal,
            flag_z_debug  => flag_z_debug,
            flag_n_debug  => flag_n_debug
        );

    process(sys_clk)
        variable next_test : std_logic;
    begin
        if rising_edge(sys_clk) then
            if sys_rst = '1' then
                state <= S_INIT_BANK0;
                init_idx <= 0;
                bank1_check_idx <= 0;
                core_rst <= '1';
                dmem_we <= '0';
                dmem_wbank <= '0';
                dmem_waddr <= (others => '0');
                dmem_wdata <= (others => '0');
                dmem_rbank <= '0';
                dmem_raddr <= (others => '0');
                test_reg <= '1';
                error_code <= ERROR_NONE;
                done_seen <= '0';
                cycle_count <= (others => '0');
            else
                next_test := test_reg;
                dmem_we <= '0';

                case state is
                    when S_INIT_BANK0 =>
                        core_rst <= '1';
                        dmem_we <= '1';
                        dmem_wbank <= '0';
                        dmem_waddr <= std_logic_vector(to_unsigned(init_idx, 3));
                        if init_idx = ADDR_INPUT then
                            dmem_wdata <= EXPECT_INPUT;
                        else
                            dmem_wdata <= (others => '0');
                        end if;

                        if init_idx = 7 then
                            init_idx <= 0;
                            state <= S_INIT_BANK1;
                        else
                            init_idx <= init_idx + 1;
                        end if;

                    when S_INIT_BANK1 =>
                        core_rst <= '1';
                        dmem_we <= '1';
                        dmem_wbank <= '1';
                        dmem_waddr <= std_logic_vector(to_unsigned(init_idx, 3));
                        dmem_wdata <= (others => '0');

                        if init_idx = 7 then
                            init_idx <= 0;
                            core_rst <= '0';
                            cycle_count <= (others => '0');
                            state <= S_RUN;
                        else
                            init_idx <= init_idx + 1;
                        end if;

                    when S_RUN =>
                        core_rst <= '0';
                        if test_reg = '1' then
                            if illegal = '1' then
                                next_test := '0';
                                if error_code = ERROR_NONE then
                                    error_code <= ERROR_ILLEGAL;
                                end if;
                            end if;

                            if done_seen = '0' then
                                if halted = '1' then
                                    done_seen <= '1';
                                    dmem_rbank <= '0';
                                    dmem_raddr <= std_logic_vector(to_unsigned(ADDR_MOV, 3));
                                    state <= S_CHECK_MOV;
                                elsif cycle_count = TIMEOUT_CYCLES then
                                    next_test := '0';
                                    if error_code = ERROR_NONE then
                                        error_code <= ERROR_TIMEOUT;
                                    end if;
                                    state <= S_DONE;
                                else
                                    cycle_count <= cycle_count + 1;
                                end if;
                            end if;
                        end if;

                    when S_CHECK_MOV =>
                        core_rst <= '0';
                        if dmem_rdata /= EXPECT_MOV then
                            next_test := '0';
                            if error_code = ERROR_NONE then
                                error_code <= ERROR_MOV;
                            end if;
                        end if;
                        dmem_raddr <= std_logic_vector(to_unsigned(ADDR_ADD, 3));
                        state <= S_CHECK_ADD;

                    when S_CHECK_ADD =>
                        core_rst <= '0';
                        if dmem_rdata /= EXPECT_ADD then
                            next_test := '0';
                            if error_code = ERROR_NONE then
                                error_code <= ERROR_ADD;
                            end if;
                        end if;
                        dmem_raddr <= std_logic_vector(to_unsigned(ADDR_SUB, 3));
                        state <= S_CHECK_SUB;

                    when S_CHECK_SUB =>
                        core_rst <= '0';
                        if dmem_rdata /= EXPECT_SUB then
                            next_test := '0';
                            if error_code = ERROR_NONE then
                                error_code <= ERROR_SUB;
                            end if;
                        end if;
                        dmem_raddr <= std_logic_vector(to_unsigned(ADDR_AND, 3));
                        state <= S_CHECK_AND;

                    when S_CHECK_AND =>
                        core_rst <= '0';
                        if dmem_rdata /= EXPECT_AND then
                            next_test := '0';
                            if error_code = ERROR_NONE then
                                error_code <= ERROR_AND;
                            end if;
                        end if;
                        dmem_raddr <= std_logic_vector(to_unsigned(ADDR_ORR, 3));
                        state <= S_CHECK_ORR;

                    when S_CHECK_ORR =>
                        core_rst <= '0';
                        if dmem_rdata /= EXPECT_ORR then
                            next_test := '0';
                            if error_code = ERROR_NONE then
                                error_code <= ERROR_ORR;
                            end if;
                        end if;
                        dmem_raddr <= std_logic_vector(to_unsigned(ADDR_LDR, 3));
                        state <= S_CHECK_LDR;

                    when S_CHECK_LDR =>
                        core_rst <= '0';
                        if dmem_rdata /= EXPECT_LDR then
                            next_test := '0';
                            if error_code = ERROR_NONE then
                                error_code <= ERROR_LDR;
                            end if;
                        end if;
                        dmem_raddr <= std_logic_vector(to_unsigned(ADDR_CONTROL, 3));
                        state <= S_CHECK_CONTROL;

                    when S_CHECK_CONTROL =>
                        core_rst <= '0';
                        if dmem_rdata /= EXPECT_CONTROL then
                            next_test := '0';
                            if error_code = ERROR_NONE then
                                error_code <= ERROR_CONTROL;
                            end if;
                        end if;
                        bank1_check_idx <= 0;
                        dmem_rbank <= '1';
                        dmem_raddr <= std_logic_vector(to_unsigned(0, 3));
                        state <= S_CHECK_BANK1;

                    when S_CHECK_BANK1 =>
                        core_rst <= '0';
                        if dmem_rdata /= x"00000000" then
                            next_test := '0';
                            if error_code = ERROR_NONE then
                                error_code <= ERROR_BANK1_DIRTY;
                            end if;
                        end if;

                        if bank1_check_idx = 7 then
                            state <= S_DONE;
                        else
                            bank1_check_idx <= bank1_check_idx + 1;
                            dmem_raddr <= std_logic_vector(to_unsigned(bank1_check_idx + 1, 3));
                        end if;

                    when S_DONE =>
                        core_rst <= '0';
                        done_seen <= '1';
                end case;

                test_reg <= next_test;
            end if;
        end if;
    end process;

    u_ila : ila_basic
        port map (
            clk    => sys_clk,
            probe0 => test_vec,
            probe1 => rst_vec,
            probe2 => error_code,
            probe3 => state_code
        );
end architecture rtl;
