library ieee;
use ieee.std_logic_1164.all;

use work.mcu_8core_dsp_pkg.all;

entity mcu_8core_instr_rom is
    generic (
        CORE_ID   : natural := 0;
        ROM_DEPTH : positive := 64
    );
    port (
        pc_index : in  natural;
        instr    : out word_t
    );
end entity mcu_8core_instr_rom;

architecture rtl of mcu_8core_instr_rom is
begin
    process(pc_index)
    begin
        if pc_index < ROM_DEPTH and pc_index <= WORKER_PROGRAM'high then
            instr <= WORKER_PROGRAM(pc_index);
        else
            instr <= (others => '0');
        end if;
    end process;
end architecture rtl;
