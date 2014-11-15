------------------------------------------------------------------------
-- One element fifo
--
-- Copyright (c) 2014-2014 Rinat Zakirov
-- SPDX-License-Identifier: BSL-1.0
--
------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity one_element_fifo is
  generic
  (
    BW: positive := 8
  );
  port
  (
    clk : in std_ulogic;
    rst : in std_ulogic;
    
    in_data : in std_ulogic_vector(BW - 1 downto 0);
    in_valid : in std_ulogic;
    in_ready : out std_ulogic;

    out_data : out std_ulogic_vector(BW - 1 downto 0);
    out_valid : out std_ulogic;
    out_ready : in std_ulogic
  );
end entity;

architecture rtl of one_element_fifo is

  signal buf_val: std_ulogic;
  signal buf: std_ulogic_vector(in_data'range);
  signal in_ready_i, out_valid_i: std_ulogic;

begin
  in_ready <= in_ready_i;
  out_valid <= out_valid_i;
  
  in_ready_i <= '1' when out_ready = '1' or buf_val = '0' else '0';
  out_valid_i <= '1' when in_valid = '1' or buf_val = '1' else '0';
  out_data <= in_data when buf_val = '0' else buf;

  process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        buf_val <= '0';
      else
        if in_valid = '1' then
          if out_ready = '1' then
            assert (in_ready_i = '1') report "BAD FIFO LOGIC" severity failure;
            if buf_val = '1' then
              buf <= in_data;
            end if;
          else
            if buf_val = '1' then
              assert (in_ready_i = '0') report "BAD FIFO LOGIC" severity failure;
            else
              buf <= in_data;
              buf_val <= '1';
            end if;
          end if;
        else
          if out_ready = '1' then
            if buf_val = '1' then              
              buf_val <= '0';
            end if;
          end if;
        end if;
      end if;
    end if;
  end process;

end architecture rtl;
