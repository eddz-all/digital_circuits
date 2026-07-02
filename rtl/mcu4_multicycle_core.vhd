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

        input_we      : in  std_logic;
        input_waddr   : in  std_logic_vector(7 downto 0);
        input_wdata   : in  half_t;

        output_raddr  : in  std_logic_vector(5 downto 0);
        output_rdata  : out half_t;

        pc_debug      : out word_t;
        instr_debug   : out word_t;
        halted_debug  : out std_logic;
        illegal_debug : out std_logic;
        flag_z_debug  : out std_logic;
        flag_n_debug  : out std_logic
    );
end entity mcu4_multicycle_core;

architecture rtl of mcu4_multicycle_core is
    type worker_addr_array_t is array (0 to 3) of std_logic_vector(2 downto 0);
    type worker_flag_array_t is array (0 to 3) of std_logic;
    type worker_buffer_array_t is array (0 to 3) of dmem_bank_t;

    signal input_samples : sample16_array_t := (others => (others => '0'));
    signal dmem_bank0         : worker_buffer_array_t := (others => (others => (others => '0')));
    signal dmem_bank1         : worker_buffer_array_t := (others => (others => (others => '0')));

    signal worker_dmem_bank0_raddr : worker_addr_array_t := (others => (others => '0'));
    signal worker_dmem_bank1_raddr : worker_addr_array_t := (others => (others => '0'));
    signal worker_dmem_bank0_raddr2 : worker_addr_array_t := (others => (others => '0'));
    signal worker_dmem_bank1_raddr2 : worker_addr_array_t := (others => (others => '0'));
    signal worker_dmem_bank0_rdata : lane4_word_array_t := (others => (others => '0'));
    signal worker_dmem_bank1_rdata : lane4_word_array_t := (others => (others => '0'));
    signal worker_dmem_bank0_rdata2 : lane4_word_array_t := (others => (others => '0'));
    signal worker_dmem_bank1_rdata2 : lane4_word_array_t := (others => (others => '0'));

    signal worker_dmem_bank0_we    : worker_flag_array_t := (others => '0');
    signal worker_dmem_bank1_we    : worker_flag_array_t := (others => '0');
    signal worker_dmem_bank0_we2   : worker_flag_array_t := (others => '0');
    signal worker_dmem_bank1_we2   : worker_flag_array_t := (others => '0');
    signal worker_dmem_bank0_waddr : worker_addr_array_t := (others => (others => '0'));
    signal worker_dmem_bank1_waddr : worker_addr_array_t := (others => (others => '0'));
    signal worker_dmem_bank0_waddr2 : worker_addr_array_t := (others => (others => '0'));
    signal worker_dmem_bank1_waddr2 : worker_addr_array_t := (others => (others => '0'));
    signal worker_dmem_bank0_wdata : lane4_word_array_t := (others => (others => '0'));
    signal worker_dmem_bank1_wdata : lane4_word_array_t := (others => (others => '0'));
    signal worker_dmem_bank0_wdata2 : lane4_word_array_t := (others => (others => '0'));
    signal worker_dmem_bank1_wdata2 : lane4_word_array_t := (others => (others => '0'));

    signal worker_halted : std_logic_vector(3 downto 0) := (others => '0');
    signal worker_illegal : std_logic_vector(3 downto 0) := (others => '0');
    signal worker_pc_debug : lane4_word_array_t := (others => (others => '0'));
    signal worker_instr_debug : lane4_word_array_t := (others => (others => '0'));

    signal all_halted : std_logic;
    signal any_illegal : std_logic;

    function safe_addr3(addr : std_logic_vector(2 downto 0)) return natural is
        variable idx : natural range 0 to 7 := 0;
    begin
        for bit_pos in 0 to 2 loop
            if addr(bit_pos) = '1' then
                idx := idx + (2 ** bit_pos);
            end if;
        end loop;
        return idx;
    end function;
begin
    gen_worker_read_data : for i in 0 to 3 generate
        worker_dmem_bank0_rdata(i) <= dmem_bank0(i)(safe_addr3(worker_dmem_bank0_raddr(i)));
        worker_dmem_bank1_rdata(i) <= dmem_bank1(i)(safe_addr3(worker_dmem_bank1_raddr(i)));
        worker_dmem_bank0_rdata2(i) <= dmem_bank0(i)(safe_addr3(worker_dmem_bank0_raddr2(i)));
        worker_dmem_bank1_rdata2(i) <= dmem_bank1(i)(safe_addr3(worker_dmem_bank1_raddr2(i)));
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
                    dmem_bank0_raddr => worker_dmem_bank0_raddr(i),
                    dmem_bank0_rdata => worker_dmem_bank0_rdata(i),
                    dmem_bank0_raddr2 => worker_dmem_bank0_raddr2(i),
                    dmem_bank0_rdata2 => worker_dmem_bank0_rdata2(i),
                    dmem_bank1_raddr => worker_dmem_bank1_raddr(i),
                    dmem_bank1_rdata => worker_dmem_bank1_rdata(i),
                    dmem_bank1_raddr2 => worker_dmem_bank1_raddr2(i),
                    dmem_bank1_rdata2 => worker_dmem_bank1_rdata2(i),
                    dmem_bank0_we    => worker_dmem_bank0_we(i),
                    dmem_bank0_waddr => worker_dmem_bank0_waddr(i),
                    dmem_bank0_wdata => worker_dmem_bank0_wdata(i),
                    dmem_bank0_we2    => worker_dmem_bank0_we2(i),
                    dmem_bank0_waddr2 => worker_dmem_bank0_waddr2(i),
                    dmem_bank0_wdata2 => worker_dmem_bank0_wdata2(i),
                    dmem_bank1_we    => worker_dmem_bank1_we(i),
                    dmem_bank1_waddr => worker_dmem_bank1_waddr(i),
                    dmem_bank1_wdata => worker_dmem_bank1_wdata(i),
                    dmem_bank1_we2    => worker_dmem_bank1_we2(i),
                    dmem_bank1_waddr2 => worker_dmem_bank1_waddr2(i),
                    dmem_bank1_wdata2 => worker_dmem_bank1_wdata2(i),
                    halted      => worker_halted(i),
                    illegal     => worker_illegal(i),
                    pc_debug    => worker_pc_debug(i),
                    instr_debug => worker_instr_debug(i)
                );
        end generate;

        gen_inactive_worker : if i >= ACTIVE_CORES generate
            worker_dmem_bank0_raddr(i) <= (others => '0');
            worker_dmem_bank1_raddr(i) <= (others => '0');
            worker_dmem_bank0_raddr2(i) <= (others => '0');
            worker_dmem_bank1_raddr2(i) <= (others => '0');
            worker_dmem_bank0_we(i) <= '0';
            worker_dmem_bank1_we(i) <= '0';
            worker_dmem_bank0_we2(i) <= '0';
            worker_dmem_bank1_we2(i) <= '0';
            worker_dmem_bank0_waddr(i) <= (others => '0');
            worker_dmem_bank1_waddr(i) <= (others => '0');
            worker_dmem_bank0_waddr2(i) <= (others => '0');
            worker_dmem_bank1_waddr2(i) <= (others => '0');
            worker_dmem_bank0_wdata(i) <= (others => '0');
            worker_dmem_bank1_wdata(i) <= (others => '0');
            worker_dmem_bank0_wdata2(i) <= (others => '0');
            worker_dmem_bank1_wdata2(i) <= (others => '0');
            worker_halted(i) <= '1';
            worker_illegal(i) <= '0';
            worker_pc_debug(i) <= (others => '0');
            worker_instr_debug(i) <= x"E1A00000";
        end generate;
    end generate;

    process(output_raddr, dmem_bank0, dmem_bank1)
        variable idx : natural range 0 to 63;
    begin
        idx := to_integer(unsigned(output_raddr));
        if PROGRAM_ID = 1 then
            if idx < 8 then
                output_rdata <= dmem_bank0(0)(idx)(15 downto 0);
            else
                output_rdata <= (others => '0');
            end if;
        else
            if idx < 8 then
                output_rdata <= dmem_bank1(0)(idx)(15 downto 0);
            elsif idx < 16 then
                output_rdata <= dmem_bank1(0)(idx - 8)(31 downto 16);
            else
                output_rdata <= (others => '0');
            end if;
        end if;
    end process;

    process(clk)
        variable slot : natural range 0 to 255;
        variable src_idx : natural range 0 to 7;
        variable waddr : natural range 0 to 7;
    begin
        if rising_edge(clk) then
            slot := to_integer(unsigned(input_waddr));
            if input_we = '1' and slot < 16 then
                input_samples(slot) <= input_wdata;
                if slot >= 8 then
                    src_idx := slot - 8;
                    for replica in 0 to 3 loop
                        dmem_bank0(replica)(BITREV_ORDER(src_idx)) <= pack_q5_to_q12(input_samples(src_idx), input_wdata);
                    end loop;
                end if;
            end if;

            -- Worker write enables are already suppressed outside S_RUN. Avoid
            -- using the top-level reset as a data-path gate for every buffer
            -- bit; that reset fanout was one of the 200 MHz critical paths.
            for i in 0 to 3 loop
                if worker_dmem_bank0_we(i) = '1' then
                    waddr := to_integer(unsigned(worker_dmem_bank0_waddr(i)));
                    for replica in 0 to 3 loop
                        dmem_bank0(replica)(waddr) <= worker_dmem_bank0_wdata(i);
                    end loop;
                end if;

                if worker_dmem_bank0_we2(i) = '1' then
                    waddr := to_integer(unsigned(worker_dmem_bank0_waddr2(i)));
                    for replica in 0 to 3 loop
                        dmem_bank0(replica)(waddr) <= worker_dmem_bank0_wdata2(i);
                    end loop;
                end if;

                if worker_dmem_bank1_we(i) = '1' then
                    waddr := to_integer(unsigned(worker_dmem_bank1_waddr(i)));
                    for replica in 0 to 3 loop
                        dmem_bank1(replica)(waddr) <= worker_dmem_bank1_wdata(i);
                    end loop;
                end if;

                if worker_dmem_bank1_we2(i) = '1' then
                    waddr := to_integer(unsigned(worker_dmem_bank1_waddr2(i)));
                    for replica in 0 to 3 loop
                        dmem_bank1(replica)(waddr) <= worker_dmem_bank1_wdata2(i);
                    end loop;
                end if;
            end loop;
        end if;
    end process;

    all_halted <= '1' when worker_halted = "1111" else '0';
    any_illegal <= '1' when worker_illegal /= "0000" else '0';

    pc_debug <= worker_pc_debug(0);
    instr_debug <= worker_instr_debug(0);
    halted_debug <= all_halted;
    illegal_debug <= any_illegal;
    flag_z_debug <= '0';
    flag_n_debug <= '0';
end architecture rtl;
