library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.mcu4_multi_pkg.all;

entity mcu_fft_system is
    generic (
        INPUT_ROM_BASE : natural := 128;
        INPUT_COUNT    : positive := 16;
        OUTPUT_COUNT   : positive := 16;
        PROGRAM_ID     : natural range 0 to 1 := 0;
        ACTIVE_CORES   : positive range 1 to 4 := 4
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
        instr_debug : out std_logic_vector(31 downto 0)
    );
end entity mcu_fft_system;

architecture rtl of mcu_fft_system is
    type state_t is (
        S_LOAD_REQ,
        S_LOAD_WAIT,
        S_LOAD_WRITE,
        S_START_RUN,
        S_RUN,
        S_DUMP_WRITE,
        S_DONE
    );

    signal state : state_t := S_LOAD_REQ;
    signal load_idx : integer range 0 to INPUT_COUNT - 1 := 0;
    signal dump_idx : integer range 0 to OUTPUT_COUNT - 1 := 0;

    signal input_samples : sample16_array_t := (others => (others => '0'));

    signal core_release_req : std_logic := '0';
    signal core_rst         : std_logic := '1';
    signal core_dmem_we    : std_logic := '0';
    signal core_dmem_wbank : std_logic := '0';
    signal core_dmem_waddr : std_logic_vector(2 downto 0) := (others => '0');
    signal core_dmem_wdata : word_t := (others => '0');
    signal core_dmem_rbank : std_logic := '0';
    signal core_dmem_raddr : std_logic_vector(2 downto 0) := (others => '0');
    signal core_dmem_rdata : word_t;

    signal core_halted  : std_logic;
    signal core_illegal : std_logic;
    signal core_flag_z  : std_logic;
    signal core_flag_n  : std_logic;

    attribute max_fanout : integer;
    attribute max_fanout of core_release_req : signal is 16;
    attribute max_fanout of core_rst         : signal is 16;
begin
    assert INPUT_COUNT = 16
        report "mcu_fft_system expects exactly 16 teacher input slots"
        severity failure;
    assert INPUT_ROM_BASE + INPUT_COUNT <= 256
        report "mcu_fft_system input window must fit test_rom_addr[7:0]"
        severity failure;
    assert OUTPUT_COUNT = 16
        report "mcu_fft_system dumps exactly 16 FFT output slots"
        severity failure;

    u_core : entity work.mcu4_multicycle_core
        generic map (
            PROGRAM_ID   => PROGRAM_ID,
            ACTIVE_CORES => ACTIVE_CORES
        )
        port map (
            clk           => clk,
            rst           => core_rst,
            dmem_we       => core_dmem_we,
            dmem_wbank    => core_dmem_wbank,
            dmem_waddr    => core_dmem_waddr,
            dmem_wdata    => core_dmem_wdata,
            dmem_rbank    => core_dmem_rbank,
            dmem_raddr    => core_dmem_raddr,
            dmem_rdata    => core_dmem_rdata,
            pc_debug      => pc_debug,
            instr_debug   => instr_debug,
            halted_debug  => core_halted,
            illegal_debug => core_illegal,
            flag_z_debug  => core_flag_z,
            flag_n_debug  => core_flag_n
        );

    illegal <= core_illegal;
    done <= '1' when state = S_DONE else '0';
    cnt_stop <= '1' when state = S_RUN and (core_halted = '1' or core_illegal = '1') else '0';
    core_dmem_rbank <= '1' when state = S_DUMP_WRITE else '0';
    core_dmem_raddr <= std_logic_vector(to_unsigned(dump_idx, 3))
        when state = S_DUMP_WRITE and dump_idx < 8
        else std_logic_vector(to_unsigned(dump_idx - 8, 3))
        when state = S_DUMP_WRITE
        else (others => '0');

    process(clk)
        variable last_input  : integer;
        variable last_output : integer;
        variable src_idx     : integer range 0 to 7;
    begin
        if rising_edge(clk) then
            last_input := INPUT_COUNT - 1;
            last_output := OUTPUT_COUNT - 1;

            if rst = '1' then
                state <= S_LOAD_REQ;
                load_idx <= 0;
                dump_idx <= 0;
                core_release_req <= '0';
                core_rst <= '1';
                input_samples <= (others => (others => '0'));
                core_dmem_we <= '0';
                core_dmem_wbank <= '0';
                core_dmem_waddr <= (others => '0');
                core_dmem_wdata <= (others => '0');
                test_rom_addr <= (others => '0');
                test_rom_en <= '0';
                verify_ram_addr <= (others => '0');
                verify_ram_we <= '0';
                verify_vector_out <= (others => '0');
                cnt_start <= '0';
            else
                core_rst <= not core_release_req;
                core_dmem_we <= '0';
                test_rom_en <= '0';
                verify_ram_we <= '0';
                cnt_start <= '0';

                case state is
                    when S_LOAD_REQ =>
                        test_rom_en <= '1';
                        test_rom_addr <= std_logic_vector(to_unsigned(INPUT_ROM_BASE + load_idx, 8));
                        state <= S_LOAD_WAIT;

                    when S_LOAD_WAIT =>
                        test_rom_en <= '1';
                        test_rom_addr <= std_logic_vector(to_unsigned(INPUT_ROM_BASE + load_idx, 8));
                        state <= S_LOAD_WRITE;

                    when S_LOAD_WRITE =>
                        input_samples(load_idx) <= test_vector_in;
                        if load_idx >= 8 then
                            src_idx := load_idx - 8;
                            core_dmem_we <= '1';
                            core_dmem_wbank <= '0';
                            core_dmem_waddr <= std_logic_vector(to_unsigned(BITREV_ORDER(src_idx), 3));
                            core_dmem_wdata <= pack_q5_to_q12(input_samples(src_idx), test_vector_in);
                        end if;
                        if load_idx = last_input then
                            core_release_req <= '1';
                            load_idx <= 0;
                            state <= S_START_RUN;
                        else
                            load_idx <= load_idx + 1;
                            state <= S_LOAD_REQ;
                        end if;

                    when S_START_RUN =>
                        cnt_start <= '1';
                        state <= S_RUN;

                    when S_RUN =>
                        if core_halted = '1' or core_illegal = '1' then
                            dump_idx <= 0;
                            state <= S_DUMP_WRITE;
                        end if;

                    when S_DUMP_WRITE =>
                        verify_ram_we <= '1';
                        verify_ram_addr <= std_logic_vector(to_unsigned(dump_idx, 6));
                        if dump_idx < 8 then
                            verify_vector_out <= core_dmem_rdata(15 downto 0);
                        else
                            verify_vector_out <= core_dmem_rdata(31 downto 16);
                        end if;
                        if dump_idx = last_output then
                            state <= S_DONE;
                        else
                            dump_idx <= dump_idx + 1;
                            state <= S_DUMP_WRITE;
                        end if;

                    when S_DONE =>
                        null;
                end case;
            end if;
        end if;
    end process;
end architecture rtl;
