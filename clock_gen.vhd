library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
USE IEEE.math_real.ALL;

entity clock_gen is
  generic ( freq: real := 100.0 );
  port
  (
    clk: out std_logic;
    rst: out std_logic;
    rnd: out real
  );
end entity;

architecture syn of clock_gen is
  signal clk_i: std_logic := '0';
  signal rst_i: std_logic := '1';
begin

  clk <= clk_i;
  rst <= rst_i;

  process
  variable seed1, seed2: positive;
  variable rnd_var: real;
  begin
    wait for (500 ns / freq);
    clk_i <= not clk_i;
    uniform(seed1, seed2, rnd_var);
    rnd <= rnd_var after 10 ps;
  end process;

  process(clk_i)
  variable count: integer := 0;
  begin
    if rising_edge(clk_i) then
      count := count + 1;
      if count = 10 then
        rst_i <= '0';
      end if;
    end if;
  end process;

end architecture;



















