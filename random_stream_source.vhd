library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
USE IEEE.math_real.ALL;

entity random_stream_source is
  generic
  ( 
    speed: real    := 1.0;
    bw   : integer := 8;
    seed1: positive := 55352;
    seed2: positive := 23124
  );
  port
  (
    clk         : in  std_logic                         ;
    rst         : in  std_logic                         ;
    out_valid   : out std_logic                         ;
    out_ready   : in  std_logic                         ;
    out_data    : out std_logic_vector(bw - 1 downto 0)
  );
end entity;

architecture syn of random_stream_source is
  signal out_valid_i: std_logic;
begin

  out_valid <= out_valid_i;

  process
  variable rand: real;
  variable seed1var: positive := seed1;
  variable seed2var: positive := seed2;
  begin
    if rising_edge(clk) then
      if rst = '1' then
        out_valid_i <= '0';
        out_data <= (others => '0');
      else
        uniform(seed1var, seed2var, rand);
        if rand < speed then
          out_valid_i <= '1';
        else
          out_valid_i <= '0';
        end if;
        
        if out_valid_i = '1' and out_ready = '1' then
          out_data <= std_logic_vector(to_unsigned(INTEGER(TRUNC(rand * 1048577.0)), bw));
        end if;
      end if;
    end if;
  end process;

end architecture;



















