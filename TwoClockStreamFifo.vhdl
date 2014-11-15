------------------------------------------------------------------------
-- TwoClockStreamFifo
--
-- Copyright (c) 2014-2014 Rinat Zakirov
-- SPDX-License-Identifier: BSL-1.0
--
-- Configurable buffering between an input and output stream.
-- See vhdl-extras simple_fifo for additional documentation.
-- SYNC_READ = true uses block ram
-- SYNC_READ = false uses dist ram
------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity TwoClockStreamFifo is
    generic(
        MEM_SIZE           : positive;
        SYNC_READ          : boolean    := true
    );
    port(
        -- input bus
        in_clk : in std_ulogic;
        in_rst : in std_ulogic;
        in_data : in std_ulogic_vector;
        in_valid : in std_ulogic;
        in_ready : out std_ulogic;

        -- output bus
        out_clk  : in std_ulogic;
        out_rst : in std_ulogic;
        out_data : out std_ulogic_vector;
        out_valid : out std_ulogic;
        out_ready : in std_ulogic;

        --space and availability
        empty               : out std_ulogic; -- This is a workaround to avoid making this fifo be an appropriate fifo which asserts valid when it has data
        almost_empty_thresh : in  natural range 0 to MEM_SIZE-1 := 1;
        almost_full_thresh  : in  natural range 0 to MEM_SIZE-1 := 1;
        almost_empty        : out std_ulogic;
        almost_full         : out std_ulogic
    );
end entity TwoClockStreamFifo;

architecture rtl of TwoClockStreamFifo is

    signal Empty_i : std_ulogic;
    signal Full : std_ulogic;
    signal We : std_ulogic;
    signal Re : std_ulogic;

begin

    in_ready <= not Full;
    We <= in_valid and not Full;
    Re <= out_ready and not Empty_i;
    Empty <= Empty_i;

    process (out_clk, Empty_i)
        variable syncValid : std_ulogic := '0';
    begin
        if (rising_edge(out_clk)) then
            if (out_rst = '1') then
                syncValid := '0';
            else
                syncValid := Re;
            end if;
        end if;
        if (SYNC_READ) then
            out_valid <= syncValid;
        else
            out_valid <= not Empty_i;
        end if;
    end process;

    fifo: entity work.fifo
    generic map (
        RESET_ACTIVE_LEVEL => '1',
        MEM_SIZE => MEM_SIZE,
        SYNC_READ => SYNC_READ
    )
    port map (
        Wr_Clock => in_clk,
        Wr_Reset => in_rst,

        Rd_Clock => out_clk,
        Rd_Reset => out_rst,

        We => We,
        Wr_data => in_data,

        Re => Re,
        Rd_data => out_data,

        Empty => Empty_i,
        Full => Full,

        Almost_empty_thresh => almost_empty_thresh,
        Almost_full_thresh => almost_full_thresh,
        Almost_empty => almost_empty,
        Almost_full => almost_full
    );
end architecture rtl;
