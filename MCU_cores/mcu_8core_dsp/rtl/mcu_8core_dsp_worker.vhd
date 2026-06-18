library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.mcu_8core_dsp_pkg.all;

entity mcu_8core_dsp_worker is
    generic (
        CORE_ID   : natural := 0;
        ROM_DEPTH : positive := 64
    );
    port (
        clk : in std_logic;
        rst : in std_logic;

        input_we    : in  std_logic;
        input_waddr : in  std_logic_vector(7 downto 0);
        input_wdata : in  std_logic_vector(15 downto 0);

        output_real : out std_logic_vector(15 downto 0);
        output_imag : out std_logic_vector(15 downto 0);

        pc_debug      : out std_logic_vector(31 downto 0);
        instr_debug   : out std_logic_vector(31 downto 0);
        halted_debug  : out std_logic;
        illegal_debug : out std_logic
    );
end entity mcu_8core_dsp_worker;

architecture rtl of mcu_8core_dsp_worker is
    signal pc_reg : natural range 0 to ROM_DEPTH - 1 := 0;
    signal input_mem : input_mem_t := (others => (others => '0'));
    signal output_mem : output_pair_t := (others => (others => '0'));
    signal halted_reg : std_logic := '0';
    signal illegal_reg : std_logic := '0';

    signal instr : word_t := (others => '0');
    signal dec_op : std_logic_vector(3 downto 0) := (others => '0');
    signal dec_rd : std_logic_vector(3 downto 0) := (others => '0');
    signal dec_rn : std_logic_vector(3 downto 0) := (others => '0');
    signal dec_rm : std_logic_vector(3 downto 0) := (others => '0');
    signal dec_ra : std_logic_vector(3 downto 0) := (others => '0');
    signal dec_imm_ext : word_t := (others => '0');
    signal dec_sat_bits : std_logic_vector(7 downto 0) := (others => '0');
    signal dec_known_op : std_logic := '0';

    signal reg_we : std_logic := '0';
    signal reg_wa : std_logic_vector(3 downto 0) := (others => '0');
    signal reg_wd : word_t := (others => '0');
    signal rn_data : word_t := (others => '0');
    signal rm_data : word_t := (others => '0');
    signal ra_data : word_t := (others => '0');
    signal rd_data : word_t := (others => '0');

    signal pc_next : natural range 0 to ROM_DEPTH - 1 := 0;
    signal halt_next : std_logic := '0';
    signal illegal_next : std_logic := '0';
    signal output_write_we : std_logic := '0';
    signal output_write_slot : natural range 0 to 1 := 0;
    signal output_write_data : std_logic_vector(15 downto 0) := (others => '0');

    function clean_signed_integer(value : std_logic_vector) return integer is
        variable clean : std_logic_vector(value'range) := (others => '0');
    begin
        for i in value'range loop
            if value(i) = '1' then
                clean(i) := '1';
            end if;
        end loop;
        return to_integer(signed(clean));
    end function;

    function clean_unsigned_natural(value : std_logic_vector) return natural is
        variable clean : std_logic_vector(value'range) := (others => '0');
    begin
        for i in value'range loop
            if value(i) = '1' then
                clean(i) := '1';
            end if;
        end loop;
        return to_integer(unsigned(clean));
    end function;
begin
    u_rom : entity work.mcu_8core_instr_rom
        generic map (
            CORE_ID   => CORE_ID,
            ROM_DEPTH => ROM_DEPTH
        )
        port map (
            pc_index => pc_reg,
            instr    => instr
        );

    u_decoder : entity work.mcu_8core_decoder
        port map (
            instr    => instr,
            op       => dec_op,
            rd       => dec_rd,
            rn       => dec_rn,
            rm       => dec_rm,
            ra       => dec_ra,
            imm_ext  => dec_imm_ext,
            sat_bits => dec_sat_bits,
            known_op => dec_known_op
        );

    u_regfile : entity work.mcu_8core_regfile
        port map (
            clk => clk,
            rst => rst,
            we  => reg_we,
            wa  => reg_wa,
            wd  => reg_wd,
            ra1 => dec_rn,
            ra2 => dec_rm,
            ra3 => dec_ra,
            ra4 => dec_rd,
            rd1 => rn_data,
            rd2 => rm_data,
            rd3 => ra_data,
            rd4 => rd_data
        );

    process(
        pc_reg,
        input_mem,
        output_mem,
        halted_reg,
        illegal_reg,
        dec_op,
        dec_rd,
        dec_imm_ext,
        dec_sat_bits,
        dec_known_op,
        rn_data,
        rm_data,
        ra_data,
        rd_data
    )
        variable imm_i : integer;
        variable sat_bits_i : natural;
        variable addr_i : integer;
        variable input_slot : natural;
        variable coeff_slot : natural;
        variable branch_delta : integer;
    begin
        reg_we <= '0';
        reg_wa <= dec_rd;
        reg_wd <= (others => '0');
        if pc_reg < ROM_DEPTH - 1 then
            pc_next <= pc_reg + 1;
        else
            pc_next <= pc_reg;
        end if;
        halt_next <= '0';
        illegal_next <= '0';
        output_write_we <= '0';
        output_write_slot <= 0;
        output_write_data <= (others => '0');

        imm_i := clean_signed_integer(dec_imm_ext);
        sat_bits_i := clean_unsigned_natural(dec_sat_bits);
        addr_i := 0;
        input_slot := 0;
        coeff_slot := 0;
        branch_delta := 0;

        if halted_reg = '0' and illegal_reg = '0' then
            if dec_known_op = '0' then
                illegal_next <= '1';
            else
                case dec_op is
                    when OP_NOP =>
                        null;

                    when OP_MOVI =>
                        reg_we <= '1';
                        reg_wd <= dec_imm_ext;

                    when OP_LDR =>
                        addr_i := to_integer(signed(rn_data)) + imm_i;
                        if addr_i >= integer(INPUT_BASE)
                            and addr_i < integer(INPUT_BASE + 8 * 4)
                            and (addr_i mod 4) = 0 then
                            input_slot := natural((addr_i - integer(INPUT_BASE)) / 4);
                            reg_we <= '1';
                            reg_wd <= input_word(input_mem, input_slot);
                        elsif addr_i >= integer(COEFF_BASE)
                            and addr_i < integer(COEFF_BASE + 8 * 4)
                            and (addr_i mod 4) = 0 then
                            coeff_slot := natural((addr_i - integer(COEFF_BASE)) / 4);
                            reg_we <= '1';
                            reg_wd <= coeff_word(CORE_ID, coeff_slot);
                        elsif addr_i >= integer(OUTPUT_BASE)
                            and addr_i < integer(OUTPUT_BASE + 2 * 4)
                            and (addr_i mod 4) = 0 then
                            reg_we <= '1';
                            reg_wd <= std_logic_vector(resize(signed(output_mem((addr_i - integer(OUTPUT_BASE)) / 4)), 32));
                        else
                            illegal_next <= '1';
                        end if;

                    when OP_STR =>
                        addr_i := to_integer(signed(rn_data)) + imm_i;
                        if addr_i >= integer(OUTPUT_BASE)
                            and addr_i < integer(OUTPUT_BASE + 2 * 4)
                            and (addr_i mod 4) = 0 then
                            output_write_we <= '1';
                            output_write_slot <= natural((addr_i - integer(OUTPUT_BASE)) / 4);
                            output_write_data <= rd_data(15 downto 0);
                        else
                            illegal_next <= '1';
                        end if;

                    when OP_MUL =>
                        reg_we <= '1';
                        reg_wd <= mul_result(rn_data, rm_data);

                    when OP_MLA =>
                        reg_we <= '1';
                        reg_wd <= mla_result(rn_data, rm_data, ra_data);

                    when OP_SMLSD =>
                        reg_we <= '1';
                        reg_wd <= smlsd_result(rn_data, rm_data, ra_data);

                    when OP_SMLADX =>
                        reg_we <= '1';
                        reg_wd <= smladx_result(rn_data, rm_data, ra_data);

                    when OP_SSAT =>
                        reg_we <= '1';
                        reg_wd <= ssat_result(rn_data, sat_bits_i);

                    when OP_B =>
                        branch_delta := imm_i;
                        if branch_delta = 0 then
                            pc_next <= pc_reg;
                            halt_next <= '1';
                        elsif branch_delta > 0 and pc_reg + natural(branch_delta) < ROM_DEPTH then
                            pc_next <= pc_reg + natural(branch_delta);
                        elsif branch_delta < 0 and natural(-branch_delta) <= pc_reg then
                            pc_next <= pc_reg - natural(-branch_delta);
                        else
                            illegal_next <= '1';
                        end if;

                    when others =>
                        illegal_next <= '1';
                end case;
            end if;
        else
            pc_next <= pc_reg;
        end if;
    end process;

    process(clk)
        variable slot_i : natural;
    begin
        if rising_edge(clk) then
            if input_we = '1' then
                slot_i := to_integer(unsigned(input_waddr));
                if slot_i < INPUT_COUNT_DSP then
                    input_mem(slot_i) <= input_wdata;
                end if;
            end if;

            if rst = '1' then
                pc_reg <= 0;
                output_mem <= (others => (others => '0'));
                halted_reg <= '0';
                illegal_reg <= '0';
            elsif halted_reg = '0' and illegal_reg = '0' then
                pc_reg <= pc_next;
                if output_write_we = '1' then
                    output_mem(output_write_slot) <= output_write_data;
                end if;
                if illegal_next = '1' then
                    illegal_reg <= '1';
                end if;
                if halt_next = '1' then
                    halted_reg <= '1';
                end if;
            end if;
        end if;
    end process;

    output_real <= output_mem(0);
    output_imag <= output_mem(1);
    pc_debug <= std_logic_vector(to_unsigned(pc_reg * 4, 32));
    instr_debug <= instr;
    halted_debug <= halted_reg;
    illegal_debug <= illegal_reg;
end architecture rtl;
