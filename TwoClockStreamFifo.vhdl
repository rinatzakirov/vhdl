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
        MEM_SIZE           : positive
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
        
        -- almost_empty_thresh is a little tricky:
        -- Values below 3 should not be used here because of the additional buffering on the output stage
        -- It is assumed that by the time the fill level reaches the required amount, the output clock has done at least a couple of cycles for the output to 
        -- have been able to read one item and put it into the store. If that didn't happen, the threshold would reach on one too little number of items.
        -- So, it if generally safe if the threshold is not too small compared to the speed at which the data is filling as seen by the output clock
        almost_empty_thresh : in  natural range 3 to MEM_SIZE-1 := 3;
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
  
  signal data_buf, fifo_rd_data: std_ulogic_vector(out_data'range);
  signal data_buf_val: std_logic;
  
  signal fifo_val: std_logic;
  signal out_valid_i: std_logic;
  
  signal almost_empty_thresh_minus_one: natural range 2 to MEM_SIZE-2;
begin

  almost_empty_thresh_minus_one <= almost_empty_thresh - 1;

  in_ready <= not Full;
  We <= in_valid and not Full;
  Empty <= Empty_i;
  out_valid <= out_valid_i;
  
  out_valid_i <= data_buf_val or fifo_val;
  out_data <= data_buf when data_buf_val = '1' else fifo_rd_data;
  Re <= (not Empty_i) when 
                        (data_buf_val = '0' and fifo_val = '0') or
                        (data_buf_val = '0' and fifo_val = '1' and out_ready = '1') or
                        (data_buf_val = '1' and fifo_val = '0' and out_ready = '1')
                      else '0';
  
  process (out_clk)
  begin
      if (rising_edge(out_clk)) then
        fifo_val <= Re;
        if (out_rst = '1') then
          fifo_val <= '0';
          data_buf_val <= '0';
        else
          if out_ready = '1' then
            if data_buf_val = '1' then
              if fifo_val = '1' then
                data_buf <= fifo_rd_data;
              else
                data_buf_val <= '0';
              end if;
            end if;
          else
            if data_buf_val = '1' then
              if fifo_val = '1' then
                assert false report "BAD LOGIC" severity failure;
              end if;
            else
              if fifo_val = '1' then
                data_buf_val <= '1';
                data_buf <= fifo_rd_data;
              end if;
            end if;
          end if;
        end if;
      end if;
  end process;

  fifo: entity work.fifo
  generic map (
      RESET_ACTIVE_LEVEL => '1',
      MEM_SIZE => MEM_SIZE,
      SYNC_READ => true,
      READ_AHEAD => false
  )
  port map (
      Wr_Clock => in_clk,
      Wr_Reset => in_rst,

      Rd_Clock => out_clk,
      Rd_Reset => out_rst,

      We => We,
      Wr_data => in_data,

      Re => Re,
      Rd_data => fifo_rd_data,

      Empty => Empty_i,
      Full => Full,

      Almost_empty_thresh => almost_empty_thresh_minus_one,
      Almost_full_thresh => almost_full_thresh,
      Almost_empty => almost_empty,
      Almost_full => almost_full
  );
end architecture rtl;
