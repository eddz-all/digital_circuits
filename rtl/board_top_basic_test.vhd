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
            probe0 : in std_logic_vector(0 downto 0)
        );
    end component;

    constant INSTR_NOP  : word_t := x"E1A00000";
    constant INSTR_HALT : word_t := x"EAFFFFFE";
    constant TIMEOUT_CYCLES : unsigned(7 downto 0) := to_unsigned(120, 8);

    signal sys_clk : std_logic;
    signal sys_rst : std_logic;

    signal dmem_bank0_raddr  : std_logic_vector(2 downto 0);
    signal dmem_bank0_rdata  : word_t;
    signal dmem_bank0_raddr2 : std_logic_vector(2 downto 0);
    signal dmem_bank0_rdata2 : word_t;
    signal dmem_bank1_raddr  : std_logic_vector(2 downto 0);
    signal dmem_bank1_rdata  : word_t;
    signal dmem_bank1_raddr2 : std_logic_vector(2 downto 0);
    signal dmem_bank1_rdata2 : word_t;

    signal dmem_bank0_we     : std_logic;
    signal dmem_bank0_waddr  : std_logic_vector(2 downto 0);
    signal dmem_bank0_wdata  : word_t;
    signal dmem_bank0_we2    : std_logic;
    signal dmem_bank0_waddr2 : std_logic_vector(2 downto 0);
    signal dmem_bank0_wdata2 : word_t;
    signal dmem_bank1_we     : std_logic;
    signal dmem_bank1_waddr  : std_logic_vector(2 downto 0);
    signal dmem_bank1_wdata  : word_t;
    signal dmem_bank1_we2    : std_logic;
    signal dmem_bank1_waddr2 : std_logic_vector(2 downto 0);
    signal dmem_bank1_wdata2 : word_t;

    signal halted      : std_logic;
    signal illegal     : std_logic;
    signal pc_debug    : word_t;
    signal instr_debug : word_t;

    signal dmem_bank0_mem : dmem_bank_t := (
        0 => x"00000005",
        others => (others => '0')
    );
    signal test_reg  : std_logic := '1';
    signal test_vec  : std_logic_vector(0 downto 0);
    signal saw_result1    : std_logic := '0';
    signal saw_result2    : std_logic := '0';
    signal saw_result3    : std_logic := '0';
    signal done_seen : std_logic := '0';
    signal cycle_count : unsigned(7 downto 0) := (others => '0');

    function addr3(addr : std_logic_vector(2 downto 0)) return natural is
        variable idx : natural range 0 to 7 := 0;
    begin
        for bit_pos in 0 to 2 loop
            if addr(bit_pos) = '1' then
                idx := idx + (2 ** bit_pos);
            end if;
        end loop;
        return idx;
    end function;

    function selftest_instr_at(pc_idx : natural) return word_t is
    begin
        case pc_idx is
            when 0  => return x"E3A00000";
            when 1  => return x"E3A01007";
            when 2  => return x"E3A02003";
            when 3  => return x"E0813002";
            when 4  => return x"E0434002";
            when 5  => return x"E0035001";
            when 6  => return x"E1856002";
            when 7  => return x"E1A07006";
            when 8  => return x"E5908040";
            when 9  => return x"E0889007";
            when 10 => return x"E5809044";
            when 11 => return x"EA000000";
            when 12 => return x"E5801048";
            when 13 => return x"EB000002";
            when 14 => return x"E5801048";
            when 15 => return x"E580A04C";
            when 16 => return INSTR_HALT;
            when 17 => return x"E089A004";
            when 18 => return x"E1A0F00E";
            when others => return INSTR_HALT;
        end case;
    end function;
begin
    sys_clk <= clk_in1;
    sys_rst <= rst_btn;
    test <= test_reg;
    test_vec(0) <= test_reg;

    dmem_bank0_rdata <= dmem_bank0_mem(addr3(dmem_bank0_raddr));
    dmem_bank0_rdata2 <= dmem_bank0_mem(addr3(dmem_bank0_raddr2));
    dmem_bank1_rdata <= (others => '0');
    dmem_bank1_rdata2 <= (others => '0');

    u_worker : entity work.mcu4_worker_core
        generic map (
            WORKER_ID  => 0,
            PROGRAM_ID => 1
        )
        port map (
            clk          => sys_clk,
            rst          => sys_rst,
            dmem_bank0_raddr  => dmem_bank0_raddr,
            dmem_bank0_rdata  => dmem_bank0_rdata,
            dmem_bank0_raddr2 => dmem_bank0_raddr2,
            dmem_bank0_rdata2 => dmem_bank0_rdata2,
            dmem_bank1_raddr  => dmem_bank1_raddr,
            dmem_bank1_rdata  => dmem_bank1_rdata,
            dmem_bank1_raddr2 => dmem_bank1_raddr2,
            dmem_bank1_rdata2 => dmem_bank1_rdata2,
            dmem_bank0_we     => dmem_bank0_we,
            dmem_bank0_waddr  => dmem_bank0_waddr,
            dmem_bank0_wdata  => dmem_bank0_wdata,
            dmem_bank0_we2    => dmem_bank0_we2,
            dmem_bank0_waddr2 => dmem_bank0_waddr2,
            dmem_bank0_wdata2 => dmem_bank0_wdata2,
            dmem_bank1_we     => dmem_bank1_we,
            dmem_bank1_waddr  => dmem_bank1_waddr,
            dmem_bank1_wdata  => dmem_bank1_wdata,
            dmem_bank1_we2    => dmem_bank1_we2,
            dmem_bank1_waddr2 => dmem_bank1_waddr2,
            dmem_bank1_wdata2 => dmem_bank1_wdata2,
            halted       => halted,
            illegal      => illegal,
            pc_debug     => pc_debug,
            instr_debug  => instr_debug
        );

    process(sys_clk)
    begin
        if rising_edge(sys_clk) then
            if sys_rst = '1' then
                dmem_bank0_mem <= (
                    0 => x"00000005",
                    others => (others => '0')
                );
            else
                if dmem_bank0_we = '1' then
                    dmem_bank0_mem(addr3(dmem_bank0_waddr)) <= dmem_bank0_wdata;
                end if;

                if dmem_bank0_we2 = '1' then
                    dmem_bank0_mem(addr3(dmem_bank0_waddr2)) <= dmem_bank0_wdata2;
                end if;
            end if;
        end if;
    end process;

    process(sys_clk)
        variable next_test : std_logic;
        variable next_saw_result1 : std_logic;
        variable next_saw_result2 : std_logic;
        variable next_saw_result3 : std_logic;
        variable pc_idx : natural range 0 to 63;
        variable expected_instr : word_t;
    begin
        if rising_edge(sys_clk) then
            if sys_rst = '1' then
                test_reg <= '1';
                saw_result1 <= '0';
                saw_result2 <= '0';
                saw_result3 <= '0';
                done_seen <= '0';
                cycle_count <= (others => '0');
            else
                next_test := test_reg;
                next_saw_result1 := saw_result1;
                next_saw_result2 := saw_result2;
                next_saw_result3 := saw_result3;

                if test_reg = '1' then
                    if illegal = '1' then
                        next_test := '0';
                    end if;

                    if dmem_bank1_we = '1' or dmem_bank1_we2 = '1' then
                        next_test := '0';
                    end if;

                    if halted = '0' and instr_debug /= INSTR_NOP then
                        if pc_debug(31 downto 8) /= x"000000" then
                            next_test := '0';
                        else
                            pc_idx := to_integer(unsigned(pc_debug(7 downto 2)));
                            expected_instr := selftest_instr_at(pc_idx);
                            if instr_debug /= expected_instr then
                                next_test := '0';
                            end if;
                        end if;
                    end if;

                    if dmem_bank0_we = '1' then
                        case addr3(dmem_bank0_waddr) is
                            when 1 =>
                                if next_saw_result1 = '1' or dmem_bank0_wdata /= x"00000008" then
                                    next_test := '0';
                                end if;
                                next_saw_result1 := '1';
                            when 2 =>
                                if next_saw_result2 = '1' or dmem_bank0_wdata /= x"00000007" then
                                    next_test := '0';
                                end if;
                                next_saw_result2 := '1';
                            when 3 =>
                                if next_saw_result3 = '1' or dmem_bank0_wdata /= x"0000000F" then
                                    next_test := '0';
                                end if;
                                next_saw_result3 := '1';
                            when others =>
                                next_test := '0';
                        end case;
                    end if;

                    if dmem_bank0_we2 = '1' then
                        case addr3(dmem_bank0_waddr2) is
                            when 1 =>
                                if next_saw_result1 = '1' or dmem_bank0_wdata2 /= x"00000008" then
                                    next_test := '0';
                                end if;
                                next_saw_result1 := '1';
                            when 2 =>
                                if next_saw_result2 = '1' or dmem_bank0_wdata2 /= x"00000007" then
                                    next_test := '0';
                                end if;
                                next_saw_result2 := '1';
                            when 3 =>
                                if next_saw_result3 = '1' or dmem_bank0_wdata2 /= x"0000000F" then
                                    next_test := '0';
                                end if;
                                next_saw_result3 := '1';
                            when others =>
                                next_test := '0';
                        end case;
                    end if;

                    if done_seen = '0' then
                        if halted = '1' then
                            done_seen <= '1';
                            if next_saw_result1 /= '1' or next_saw_result2 /= '1' or next_saw_result3 /= '1' then
                                next_test := '0';
                            end if;
                        elsif cycle_count = TIMEOUT_CYCLES then
                            next_test := '0';
                        else
                            cycle_count <= cycle_count + 1;
                        end if;
                    end if;
                end if;

                test_reg <= next_test;
                saw_result1 <= next_saw_result1;
                saw_result2 <= next_saw_result2;
                saw_result3 <= next_saw_result3;
            end if;
        end if;
    end process;

    u_ila : ila_basic
        port map (
            clk    => sys_clk,
            probe0 => test_vec
        );
end architecture rtl;
