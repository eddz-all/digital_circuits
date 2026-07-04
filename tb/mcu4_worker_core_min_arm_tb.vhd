library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;

entity mcu4_worker_core_min_arm_tb is
end entity mcu4_worker_core_min_arm_tb;

architecture sim of mcu4_worker_core_min_arm_tb is
    signal clk : std_logic := '0';
    signal rst : std_logic := '1';

    signal dmem_bank0_raddr : std_logic_vector(2 downto 0);
    signal dmem_bank0_rdata : std_logic_vector(31 downto 0);
    signal dmem_bank0_raddr2 : std_logic_vector(2 downto 0);
    signal dmem_bank0_rdata2 : std_logic_vector(31 downto 0);
    signal dmem_bank1_raddr : std_logic_vector(2 downto 0);
    signal dmem_bank1_rdata : std_logic_vector(31 downto 0) := (others => '0');
    signal dmem_bank1_raddr2 : std_logic_vector(2 downto 0);
    signal dmem_bank1_rdata2 : std_logic_vector(31 downto 0) := (others => '0');

    signal dmem_bank0_we    : std_logic;
    signal dmem_bank0_waddr : std_logic_vector(2 downto 0);
    signal dmem_bank0_wdata : std_logic_vector(31 downto 0);
    signal dmem_bank0_we2    : std_logic;
    signal dmem_bank0_waddr2 : std_logic_vector(2 downto 0);
    signal dmem_bank0_wdata2 : std_logic_vector(31 downto 0);
    signal dmem_bank1_we    : std_logic;
    signal dmem_bank1_waddr : std_logic_vector(2 downto 0);
    signal dmem_bank1_wdata : std_logic_vector(31 downto 0);
    signal dmem_bank1_we2    : std_logic;
    signal dmem_bank1_waddr2 : std_logic_vector(2 downto 0);
    signal dmem_bank1_wdata2 : std_logic_vector(31 downto 0);

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

    dmem_bank0_rdata <= x"00000005" when dmem_bank0_raddr = "000" else (others => '0');
    dmem_bank0_rdata2 <= x"00000005" when dmem_bank0_raddr2 = "000" else (others => '0');

    dut : entity work.mcu4_worker_core
        generic map (
            WORKER_ID => 0,
            PROGRAM_ID => 1
        )
        port map (
            clk         => clk,
            rst         => rst,
            dmem_bank0_raddr => dmem_bank0_raddr,
            dmem_bank0_rdata => dmem_bank0_rdata,
            dmem_bank0_raddr2 => dmem_bank0_raddr2,
            dmem_bank0_rdata2 => dmem_bank0_rdata2,
            dmem_bank1_raddr => dmem_bank1_raddr,
            dmem_bank1_rdata => dmem_bank1_rdata,
            dmem_bank1_raddr2 => dmem_bank1_raddr2,
            dmem_bank1_rdata2 => dmem_bank1_rdata2,
            dmem_bank0_we    => dmem_bank0_we,
            dmem_bank0_waddr => dmem_bank0_waddr,
            dmem_bank0_wdata => dmem_bank0_wdata,
            dmem_bank0_we2    => dmem_bank0_we2,
            dmem_bank0_waddr2 => dmem_bank0_waddr2,
            dmem_bank0_wdata2 => dmem_bank0_wdata2,
            dmem_bank1_we    => dmem_bank1_we,
            dmem_bank1_waddr => dmem_bank1_waddr,
            dmem_bank1_wdata => dmem_bank1_wdata,
            dmem_bank1_we2    => dmem_bank1_we2,
            dmem_bank1_waddr2 => dmem_bank1_waddr2,
            dmem_bank1_wdata2 => dmem_bank1_wdata2,
            halted      => halted,
            illegal     => illegal,
            pc_debug    => pc_debug,
            instr_debug => instr_debug
        );

    monitor : process(clk)
    begin
        if rising_edge(clk) then
            assert dmem_bank1_we = '0'
                report "minimum ARM self-test unexpectedly wrote dmem_bank1"
                severity failure;
            assert dmem_bank1_we2 = '0'
                report "minimum ARM self-test unexpectedly wrote dmem_bank1 second port"
                severity failure;

            if rst = '0' and dmem_bank0_we = '1' then
                case to_integer(unsigned(dmem_bank0_waddr)) is
                    when 1 =>
                        assert dmem_bank0_wdata = x"00000007"
                            report "MOV result write mismatch at dmem_bank0[1]"
                            severity failure;
                        saw_result1 <= '1';
                    when 2 =>
                        assert dmem_bank0_wdata = x"0000000A"
                            report "ADD result write mismatch at dmem_bank0[2]"
                            severity failure;
                        saw_result2 <= '1';
                    when 3 =>
                        assert dmem_bank0_wdata = x"00000007"
                            report "SUB result write mismatch at dmem_bank0[3]"
                            severity failure;
                        saw_result3 <= '1';
                    when 4 =>
                        assert dmem_bank0_wdata = x"00000002"
                            report "AND result write mismatch at dmem_bank0[4]"
                            severity failure;
                        saw_result4 <= '1';
                    when 5 =>
                        assert dmem_bank0_wdata = x"00000003"
                            report "ORR result write mismatch at dmem_bank0[5]"
                            severity failure;
                        saw_result5 <= '1';
                    when 6 =>
                        assert dmem_bank0_wdata = x"00000005"
                            report "LDR result write mismatch at dmem_bank0[6]"
                            severity failure;
                        saw_result6 <= '1';
                    when 7 =>
                        assert dmem_bank0_wdata = x"0000000F"
                            report "BL/MOV pc,lr result write mismatch at dmem_bank0[7]"
                            severity failure;
                        saw_result7 <= '1';
                    when others =>
                        assert false
                            report "unexpected STR target dmem_bank0["
                                & integer'image(to_integer(unsigned(dmem_bank0_waddr))) & "]"
                            severity failure;
                end case;
            end if;

            if rst = '0' and dmem_bank0_we2 = '1' then
                assert false
                    report "legacy minimum ARM self-test unexpectedly used dmem_bank0 second write port"
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
