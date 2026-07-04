library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.mcu4_multi_pkg.all;

entity mcu4_multicycle_core is
    generic (
        PROGRAM_ID   : natural range 0 to 1 := 0;
        ACTIVE_CORES : positive range 1 to 4 := 4
    );
    port (
        clk           : in  std_logic;
        rst           : in  std_logic;

        dmem_we       : in  std_logic;
        dmem_waddr    : in  word_t;
        dmem_wdata    : in  word_t;
        dmem_raddr    : in  word_t;
        dmem_rdata    : out word_t;

        pc_debug      : out word_t;
        instr_debug   : out word_t;
        halted_debug  : out std_logic;
        illegal_debug : out std_logic;
        flag_z_debug  : out std_logic;
        flag_n_debug  : out std_logic
    );
end entity mcu4_multicycle_core;

architecture rtl of mcu4_multicycle_core is
    constant INSTR_DONE_SENTINEL : word_t := x"EAFFFFFE";

    type worker_flag_array_t is array (0 to 3) of std_logic;
    type worker_dmem_array_t is array (0 to 3) of dmem_t;

    signal dmem         : worker_dmem_array_t := (others => (others => (others => '0')));

    signal worker_dmem_raddr : lane4_word_array_t := (others => (others => '0'));
    signal worker_dmem_raddr2 : lane4_word_array_t := (others => (others => '0'));
    signal worker_dmem_rdata : lane4_word_array_t := (others => (others => '0'));
    signal worker_dmem_rdata2 : lane4_word_array_t := (others => (others => '0'));

    signal worker_dmem_we    : worker_flag_array_t := (others => '0');
    signal worker_dmem_we2   : worker_flag_array_t := (others => '0');
    signal worker_dmem_waddr : lane4_word_array_t := (others => (others => '0'));
    signal worker_dmem_waddr2 : lane4_word_array_t := (others => (others => '0'));
    signal worker_dmem_wdata : lane4_word_array_t := (others => (others => '0'));
    signal worker_dmem_wdata2 : lane4_word_array_t := (others => (others => '0'));

    signal worker_halted : std_logic_vector(3 downto 0) := (others => '0');
    signal worker_done_raw : std_logic_vector(3 downto 0) := (others => '0');
    signal worker_done : std_logic_vector(3 downto 0) := (others => '0');
    signal worker_illegal : std_logic_vector(3 downto 0) := (others => '0');
    signal worker_pc_debug : lane4_word_array_t := (others => (others => '0'));
    signal worker_instr_debug : lane4_word_array_t := (others => (others => '0'));

    signal all_halted : std_logic;
    signal any_illegal : std_logic;

    function safe_dmem_index(addr : word_t) return natural is
        variable idx : natural range 0 to DMEM_WORDS - 1 := 0;
    begin
        for bit_pos in 2 to 7 loop
            if addr(bit_pos) = '1' then
                idx := idx + (2 ** (bit_pos - 2));
            end if;
        end loop;
        return idx;
    end function;
begin
    gen_worker_read_data : for i in 0 to 3 generate
        worker_dmem_rdata(i) <= dmem(i)(safe_dmem_index(worker_dmem_raddr(i)));
        worker_dmem_rdata2(i) <= dmem(i)(safe_dmem_index(worker_dmem_raddr2(i)));
    end generate;

    gen_workers : for i in 0 to 3 generate
        gen_active_worker : if i < ACTIVE_CORES generate
            u_worker : entity work.mcu4_worker_core
                generic map (
                    WORKER_ID  => i,
                    PROGRAM_ID => PROGRAM_ID
                )
                port map (
                    clk         => clk,
                    rst         => rst,
                    dmem_raddr => worker_dmem_raddr(i),
                    dmem_rdata => worker_dmem_rdata(i),
                    dmem_raddr2 => worker_dmem_raddr2(i),
                    dmem_rdata2 => worker_dmem_rdata2(i),
                    dmem_we    => worker_dmem_we(i),
                    dmem_waddr => worker_dmem_waddr(i),
                    dmem_wdata => worker_dmem_wdata(i),
                    dmem_we2    => worker_dmem_we2(i),
                    dmem_waddr2 => worker_dmem_waddr2(i),
                    dmem_wdata2 => worker_dmem_wdata2(i),
                    halted      => worker_halted(i),
                    illegal     => worker_illegal(i),
                    pc_debug    => worker_pc_debug(i),
                    instr_debug => worker_instr_debug(i)
                );

            worker_done_raw(i) <= '1'
                when worker_halted(i) = '1' or worker_instr_debug(i) = INSTR_DONE_SENTINEL
                else '0';
        end generate;

        gen_inactive_worker : if i >= ACTIVE_CORES generate
            worker_dmem_raddr(i) <= (others => '0');
            worker_dmem_raddr2(i) <= (others => '0');
            worker_dmem_we(i) <= '0';
            worker_dmem_we2(i) <= '0';
            worker_dmem_waddr(i) <= (others => '0');
            worker_dmem_waddr2(i) <= (others => '0');
            worker_dmem_wdata(i) <= (others => '0');
            worker_dmem_wdata2(i) <= (others => '0');
            worker_halted(i) <= '1';
            worker_done_raw(i) <= '1';
            worker_illegal(i) <= '0';
            worker_pc_debug(i) <= (others => '0');
            worker_instr_debug(i) <= x"E1A00000";
        end generate;
    end generate;

    dmem_rdata <= dmem(0)(safe_dmem_index(dmem_raddr));

    process(clk)
        variable waddr : natural range 0 to DMEM_WORDS - 1;
    begin
        if rising_edge(clk) then
            if rst = '1' then
                for i in 0 to 3 loop
                    if i < ACTIVE_CORES then
                        worker_done(i) <= '0';
                    else
                        worker_done(i) <= '1';
                    end if;
                end loop;
            else
                for i in 0 to 3 loop
                    if i < ACTIVE_CORES then
                        if worker_done_raw(i) = '1' then
                            worker_done(i) <= '1';
                        end if;
                    else
                        worker_done(i) <= '1';
                    end if;
                end loop;
            end if;

            if dmem_we = '1' then
                waddr := safe_dmem_index(dmem_waddr);
                for replica in 0 to 3 loop
                    dmem(replica)(waddr) <= dmem_wdata;
                end loop;
            end if;

            -- Worker write enables are already suppressed outside S_RUN. Avoid
            -- using the top-level reset as a data-path gate for every buffer
            -- bit; that reset fanout was one of the 200 MHz critical paths.
            for i in 0 to 3 loop
                if worker_dmem_we(i) = '1' then
                    waddr := safe_dmem_index(worker_dmem_waddr(i));
                    for replica in 0 to 3 loop
                        dmem(replica)(waddr) <= worker_dmem_wdata(i);
                    end loop;
                end if;

                if worker_dmem_we2(i) = '1' then
                    waddr := safe_dmem_index(worker_dmem_waddr2(i));
                    for replica in 0 to 3 loop
                        dmem(replica)(waddr) <= worker_dmem_wdata2(i);
                    end loop;
                end if;
            end loop;
        end if;
    end process;

    all_halted <= '1' when worker_done = "1111" else '0';
    any_illegal <= '1' when worker_illegal /= "0000" else '0';

    pc_debug <= worker_pc_debug(0);
    instr_debug <= worker_instr_debug(0);
    halted_debug <= all_halted;
    illegal_debug <= any_illegal;
    flag_z_debug <= '0';
    flag_n_debug <= '0';
end architecture rtl;
