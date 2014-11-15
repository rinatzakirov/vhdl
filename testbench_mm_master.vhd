library work;
use work.util.all;
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
USE IEEE.math_real.ALL;

package testbench_mm_master_pkg is
  constant do_idle: integer := 0;
  constant do_write: integer := 1;
  --constant do_read: integer := 2;
  constant do_goto: integer := 3;
  
  type instruction_t is array(integer range <>) of integer;
  type instructions_t is array(integer range <>) of instruction_t(0 to 2);
end package;

use work.testbench_mm_master_pkg.all;
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
USE IEEE.math_real.ALL;
library work;
use work.util.all;

entity testbench_mm_master is
  generic
  (
    instructions: instructions_t
  );
  port
  (
    clk: in std_logic;
    rst: in std_logic;
    
    mm_write      : out std_logic                    ;
    mm_waitrequest: in  std_logic                    ;
    mm_address    : out std_logic_vector(31 downto 0);
    mm_writedata  : out std_logic_vector(31 downto 0)
  );
end entity;

architecture syn of testbench_mm_master is

  type state_t is (s_idle, s_write);
  signal state: state_t;
  
begin

  process (clk)
  variable pc: integer;
  begin
    if rising_edge(clk) then
      if rst = '1' then
        pc := 0;
        state <= s_idle;
        mm_write <= '0';
        mm_address <= (others => '0');
        mm_writedata <= (others => '0');
      else
        case state is 
        when s_idle => 
          if instructions(pc)(0) = do_write then
            state <= s_write;
            mm_write <= '1';
            mm_address <= toSlv(instructions(pc)(1), 31);
            mm_writedata <= toSlv(instructions(pc)(2), 31);
            pc := pc + 1;
          end if;
          if instructions(pc)(0) = do_goto then
            pc := instructions(pc)(1);
          end if;
        when s_write =>
          if mm_waitrequest = '0' then
            state <= s_idle;
            mm_write <= '0';
            mm_address <= (others => '0');
            mm_writedata <= (others => '0');
          end if;
        end case;
      end if;
    end if;
  end process;

end architecture;



















