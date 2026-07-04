library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;

use work.mcu4_multi_pkg.all;

entity mcu4_worker_core_min_arm_tb is
end entity mcu4_worker_core_min_arm_tb;

architecture sim of mcu4_worker_core_min_arm_tb is
    signal clk : std_logic := '0';
    signal rst : std_logic := '1';

    constant ADDR_INPUT   : word_t := dmem_word_addr(DMEM_REGION_A_BASE_WORD + 0);
    constant ADDR_MOV     : word_t := dmem_word_addr(DMEM_REGION_A_BASE_WORD + 1);
    constant ADDR_ADD     : word_t := dmem_word_addr(DMEM_REGION_A_BASE_WORD + 2);
    constant ADDR_SUB     : word_t := dmem_word_addr(DMEM_REGION_A_BASE_WORD + 3);
    constant ADDR_AND     : word_t := dmem_word_addr(DMEM_REGION_A_BASE_WORD + 4);
    constant ADDR_ORR     : word_t := dmem_word_addr(DMEM_REGION_A_BASE_WORD + 5);
    constant ADDR_LDR     : word_t := dmem_word_addr(DMEM_REGION_A_BASE_WORD + 6);
    constant ADDR_CONTROL : word_t := dmem_word_addr(DMEM_REGION_A_BASE_WORD + 7);

    signal dmem_raddr : word_t;
    signal dmem_rdata : word_t;
    signal dmem_raddr2 : word_t;
    signal dmem_rdata2 : word_t;

    signal dmem_we    : std_logic;
    signal dmem_waddr : word_t;
    signal dmem_wdata : word_t;
    signal dmem_we2    : std_logic;
    signal dmem_waddr2 : word_t;
    signal dmem_wdata2 : word_t;

    signal halted      : std_logic;
    signal illegal     : std_logic;
    signal pc_debug    : std_logic_vector(31 downto 0);
    signal instr_debug : std_logic_vector(31 downto 0);

    signal saw_result1 : std_logic := '0';
    signal saw_result2 : std_logic := '0';
    signal saw_result3 : std_logic := '0';
    signal saw_result4 : std_logic := '0';
    signal saw_result5 : std_logic := '0';
    signal saw_result6 : std_logic := '0';
    signal saw_result7 : std_logic := '0';
begin
    clk <= not clk after 5 ns;

    dmem_rdata <= x"00000005" when dmem_raddr = ADDR_INPUT else (others => '0');
    dmem_rdata2 <= x"00000005" when dmem_raddr2 = ADDR_INPUT else (others => '0');

    dut : entity work.mcu4_worker_core
        generic map (
            WORKER_ID => 0,
            PROGRAM_ID => 1
        )
        port map (
            clk         => clk,
            rst         => rst,
            dmem_raddr => dmem_raddr,
            dmem_rdata => dmem_rdata,
            dmem_raddr2 => dmem_raddr2,
            dmem_rdata2 => dmem_rdata2,
            dmem_we    => dmem_we,
            dmem_waddr => dmem_waddr,
            dmem_wdata => dmem_wdata,
            dmem_we2    => dmem_we2,
            dmem_waddr2 => dmem_waddr2,
            dmem_wdata2 => dmem_wdata2,
            halted      => halted,
            illegal     => illegal,
            pc_debug    => pc_debug,
            instr_debug => instr_debug
        );

    monitor : process(clk)
    begin
        if rising_edge(clk) then
            if rst = '0' and dmem_we = '1' then
                if dmem_waddr = ADDR_MOV then
                    assert dmem_wdata = x"00000007"
                        report "MOV result write mismatch at address 0x44"
                        severity failure;
                    saw_result1 <= '1';
                elsif dmem_waddr = ADDR_ADD then
                    assert dmem_wdata = x"0000000A"
                        report "ADD result write mismatch at address 0x48"
                        severity failure;
                    saw_result2 <= '1';
                elsif dmem_waddr = ADDR_SUB then
                    assert dmem_wdata = x"00000007"
                        report "SUB result write mismatch at address 0x4C"
                        severity failure;
                    saw_result3 <= '1';
                elsif dmem_waddr = ADDR_AND then
                    assert dmem_wdata = x"00000002"
                        report "AND result write mismatch at address 0x50"
                        severity failure;
                    saw_result4 <= '1';
                elsif dmem_waddr = ADDR_ORR then
                    assert dmem_wdata = x"00000003"
                        report "ORR result write mismatch at address 0x54"
                        severity failure;
                    saw_result5 <= '1';
                elsif dmem_waddr = ADDR_LDR then
                    assert dmem_wdata = x"00000005"
                        report "LDR result write mismatch at address 0x58"
                        severity failure;
                    saw_result6 <= '1';
                elsif dmem_waddr = ADDR_CONTROL then
                    assert dmem_wdata = x"0000000F"
                        report "BL/MOV pc,lr result write mismatch at address 0x5C"
                        severity failure;
                    saw_result7 <= '1';
                else
                    assert false
                        report "unexpected STR target byte address "
                            & integer'image(to_integer(unsigned(dmem_waddr(11 downto 0))))
                        severity failure;
                end if;
            end if;

            if rst = '0' and dmem_we2 = '1' then
                assert false
                    report "minimum ARM self-test unexpectedly used second write port"
                    severity failure;
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
        wait_cycles(2);
        rst <= '0';

        for i in 1 to 80 loop
            wait until rising_edge(clk);
            exit when instr_debug = x"EAFFFFFE";
        end loop;

        assert instr_debug = x"EAFFFFFE"
            report "minimum ARM self-test did not reach B . sentinel"
            severity failure;
        assert illegal = '0'
            report "minimum ARM self-test hit illegal instruction"
            severity failure;
        assert saw_result1 = '1'
            report "minimum ARM self-test did not execute MOV result store"
            severity failure;
        assert saw_result2 = '1'
            report "minimum ARM self-test did not execute ADD result store"
            severity failure;
        assert saw_result3 = '1'
            report "minimum ARM self-test did not execute SUB result store"
            severity failure;
        assert saw_result4 = '1'
            report "minimum ARM self-test did not execute AND result store"
            severity failure;
        assert saw_result5 = '1'
            report "minimum ARM self-test did not execute ORR result store"
            severity failure;
        assert saw_result6 = '1'
            report "minimum ARM self-test did not execute LDR result store"
            severity failure;
        assert saw_result7 = '1'
            report "minimum ARM self-test did not return from BL"
            severity failure;

        report "mcu4_worker_core_min_arm_tb passed" severity note;
        finish;
    end process;
end architecture sim;
