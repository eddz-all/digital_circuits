library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mcu_fft_system is
    generic (
        MEM_FILE      : string := "asm/fft8_v5_arm_strict_59.mem";
        CORE_ROM_DEPTH : positive := 256;
        SAMPLE_COUNT  : positive := 16
    );
    port (
        clk : in std_logic;
        rst : in std_logic;

        test_rom_addr : out std_logic_vector(5 downto 0);
        test_rom_en   : out std_logic;
        test_vector_in : in  std_logic_vector(15 downto 0);

        verify_ram_addr  : out std_logic_vector(5 downto 0);
        verify_ram_we    : out std_logic;
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
        S_RUN,
        S_DUMP_ADDR,
        S_DUMP_WRITE,
        S_DONE
    );

    signal state : state_t := S_LOAD_REQ;
    signal load_idx : integer range 0 to SAMPLE_COUNT - 1 := 0;
    signal dump_idx : integer range 0 to SAMPLE_COUNT - 1 := 0;

    signal core_rst         : std_logic := '1';
    signal core_input_we    : std_logic := '0';
    signal core_input_waddr : std_logic_vector(5 downto 0) := (others => '0');
    signal core_input_wdata : std_logic_vector(15 downto 0) := (others => '0');
    signal core_output_raddr : std_logic_vector(5 downto 0) := (others => '0');
    signal core_output_rdata : std_logic_vector(15 downto 0);

    signal core_halted  : std_logic;
    signal core_illegal : std_logic;
    signal core_flag_z  : std_logic;
    signal core_flag_n  : std_logic;
begin
    u_core : entity work.mcu_v1_core
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
            flag_n_debug  => core_flag_n
        );

    illegal <= core_illegal;
    done <= '1' when state = S_DONE else '0';

    process(clk)
        variable last_sample : integer;
    begin
        if rising_edge(clk) then
            last_sample := SAMPLE_COUNT - 1;

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
                        test_rom_addr <= std_logic_vector(to_unsigned(load_idx, 6));
                        state <= S_LOAD_WAIT;

                    when S_LOAD_WAIT =>
                        core_rst <= '1';
                        test_rom_en <= '1';
                        test_rom_addr <= std_logic_vector(to_unsigned(load_idx, 6));
                        state <= S_LOAD_WRITE;

                    when S_LOAD_WRITE =>
                        core_rst <= '1';
                        core_input_we <= '1';
                        core_input_waddr <= std_logic_vector(to_unsigned(load_idx, 6));
                        core_input_wdata <= test_vector_in;
                        if load_idx = 0 then
                            cnt_start <= '1';
                        end if;
                        if load_idx = last_sample then
                            load_idx <= 0;
                            core_rst <= '0';
                            state <= S_RUN;
                        else
                            load_idx <= load_idx + 1;
                            state <= S_LOAD_REQ;
                        end if;

                    when S_RUN =>
                        core_rst <= '0';
                        if core_halted = '1' or core_illegal = '1' then
                            dump_idx <= 0;
                            core_output_raddr <= (others => '0');
                            state <= S_DUMP_ADDR;
                        end if;

                    when S_DUMP_ADDR =>
                        core_rst <= '0';
                        core_output_raddr <= std_logic_vector(to_unsigned(dump_idx, 6));
                        state <= S_DUMP_WRITE;

                    when S_DUMP_WRITE =>
                        core_rst <= '0';
                        verify_ram_we <= '1';
                        verify_ram_addr <= std_logic_vector(to_unsigned(dump_idx, 6));
                        verify_vector_out <= core_output_rdata;
                        if dump_idx = last_sample then
                            cnt_stop <= '1';
                            state <= S_DONE;
                        else
                            dump_idx <= dump_idx + 1;
                            state <= S_DUMP_ADDR;
                        end if;

                    when S_DONE =>
                        core_rst <= '0';
                        null;
                end case;
            end if;
        end if;
    end process;
end architecture rtl;
