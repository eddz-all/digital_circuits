library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;

entity mcu4_worker_core_min_arm_tb is
end entity mcu4_worker_core_min_arm_tb;

architecture sim of mcu4_worker_core_min_arm_tb is
    signal clk : std_logic := '0';
    signal rst : std_logic := '1';

    signal buf_a_raddr : std_logic_vector(2 downto 0);
    signal buf_a_rdata : std_logic_vector(31 downto 0);
    signal buf_b_raddr : std_logic_vector(2 downto 0);
    signal buf_b_rdata : std_logic_vector(31 downto 0) := (others => '0');

    signal buf_a_we    : std_logic;
    signal buf_a_waddr : std_logic_vector(2 downto 0);
    signal buf_a_wdata : std_logic_vector(31 downto 0);
    signal buf_b_we    : std_logic;
    signal buf_b_waddr : std_logic_vector(2 downto 0);
    signal buf_b_wdata : std_logic_vector(31 downto 0);

    signal halted      : std_logic;
    signal illegal     : std_logic;
    signal pc_debug    : std_logic_vector(31 downto 0);
    signal instr_debug : std_logic_vector(31 downto 0);

    signal saw_buf_b0 : std_logic := '0';
    signal saw_buf_b2 : std_logic := '0';
    signal saw_mov_imm : std_logic := '0';
    signal saw_add     : std_logic := '0';
    signal saw_ldr     : std_logic := '0';
    signal saw_b       : std_logic := '0';
    signal saw_bl      : std_logic := '0';
    signal saw_mov_pc  : std_logic := '0';
begin
    clk <= not clk after 5 ns;

    buf_a_rdata <= x"00000005" when buf_a_raddr = "000" else (others => '0');

    dut : entity work.mcu4_worker_core
        generic map (
            WORKER_ID => 0,
            PROGRAM_ID => 1
        )
        port map (
            clk         => clk,
            rst         => rst,
            buf_a_raddr => buf_a_raddr,
            buf_a_rdata => buf_a_rdata,
            buf_b_raddr => buf_b_raddr,
            buf_b_rdata => buf_b_rdata,
            buf_a_we    => buf_a_we,
            buf_a_waddr => buf_a_waddr,
            buf_a_wdata => buf_a_wdata,
            buf_b_we    => buf_b_we,
            buf_b_waddr => buf_b_waddr,
            buf_b_wdata => buf_b_wdata,
            halted      => halted,
            illegal     => illegal,
            pc_debug    => pc_debug,
            instr_debug => instr_debug
        );

    monitor : process(clk)
    begin
        if rising_edge(clk) then
            assert buf_a_we = '0'
                report "minimum ARM self-test unexpectedly wrote buf_a"
                severity failure;

            if rst = '0' and buf_b_we = '1' then
                case to_integer(unsigned(buf_b_waddr)) is
                    when 0 =>
                        assert buf_b_wdata = x"00000008"
                            report "ADD/AND/ORR/MOV/LDR/STR result write mismatch at buf_b[0]"
                            severity failure;
                        saw_buf_b0 <= '1';
                    when 2 =>
                        assert buf_b_wdata = x"0000000F"
                            report "BL/MOV pc,lr return result write mismatch at buf_b[2]"
                            severity failure;
                        saw_buf_b2 <= '1';
                    when others =>
                        assert false
                            report "unexpected STR target buf_b["
                                & integer'image(to_integer(unsigned(buf_b_waddr))) & "]"
                            severity failure;
                end case;
            end if;

            if rst = '0' then
                case to_integer(unsigned(pc_debug(7 downto 2))) is
                    when 0 =>
                        assert instr_debug = x"E3A00000"
                            report "instr_debug pc0 should expose MOV r0,#0 ROM word"
                            severity failure;
                        saw_mov_imm <= '1';
                    when 3 =>
                        assert instr_debug = x"E0813002"
                            report "instr_debug pc3 should expose ADD r3,r1,r2 ROM word"
                            severity failure;
                        saw_add <= '1';
                    when 8 =>
                        assert instr_debug = x"E5908040"
                            report "instr_debug pc8 should expose LDR r8,[buf_a+0] ROM word"
                            severity failure;
                        saw_ldr <= '1';
                    when 11 =>
                        assert instr_debug = x"EA00000D"
                            report "instr_debug pc11 should expose B absolute target 13 ROM word"
                            severity failure;
                        saw_b <= '1';
                    when 13 =>
                        assert instr_debug = x"EB000010"
                            report "instr_debug pc13 should expose BL absolute target 16 ROM word"
                            severity failure;
                        saw_bl <= '1';
                    when 17 =>
                        assert instr_debug = x"E1A0F00E"
                            report "instr_debug pc17 should expose MOV pc,lr ROM word"
                            severity failure;
                        saw_mov_pc <= '1';
                    when others =>
                        null;
                end case;
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
            exit when halted = '1';
        end loop;

        assert halted = '1'
            report "minimum ARM self-test did not halt"
            severity failure;
        assert illegal = '0'
            report "minimum ARM self-test hit illegal instruction"
            severity failure;
        assert saw_buf_b0 = '1'
            report "minimum ARM self-test did not execute LDR/STR data path"
            severity failure;
        assert saw_buf_b2 = '1'
            report "minimum ARM self-test did not return from BL"
            severity failure;
        assert saw_mov_imm = '1' and saw_add = '1' and saw_ldr = '1'
            and saw_b = '1' and saw_bl = '1' and saw_mov_pc = '1'
            report "minimum ARM self-test did not observe expected ROM instr_debug words"
            severity failure;

        report "mcu4_worker_core_min_arm_tb passed" severity note;
        finish;
    end process;
end architecture sim;
