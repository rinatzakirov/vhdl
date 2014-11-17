use work.all;
use work.util.all;
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
USE IEEE.math_real.ALL;
use work.testbench_mm_master_pkg.all;

entity stream_to_avalon_tb is
end entity;

architecture sim of stream_to_avalon_tb is

  signal stream_valid : std_logic                    ;
  signal stream_ready : std_logic                    ;
  signal stream_data  : std_logic_vector(15 downto 0);

  signal ctl_write: std_logic;
  signal ctl_read: std_logic;
  signal ctl_address: std_logic_vector(31 downto 0);
  signal ctl_writedata: std_logic_vector(31 downto 0);
  signal ctl_readdata: std_logic_vector(31 downto 0);
  signal ctl_waitrequest: std_logic;
  signal ctl_readdatavalid: std_logic;
  signal writer_write: std_logic;
  signal writer_waitrequest: std_logic;
  signal writer_address: std_logic_vector(31 downto 0);
  signal writer_burstcount: std_logic_vector(9 downto 0);
  signal writer_writedata: std_logic_vector(127 downto 0);
  
  signal clk, rst: std_logic;
  signal rnd: real;
  
begin

  clock: entity work.clock_gen
  port map
  (
    clk => clk ,
    rst => rst ,
    rnd => rnd
  );
  
  source: entity work.random_stream_source
  generic map (speed => 0.1, bw => 16, incrementing => true)
  port map
  (
    clk        => clk                 ,
    rst        => rst                 ,
    out_valid  => stream_valid        ,
    out_ready  => stream_ready        ,
    out_data   => stream_data         
  );			  
  
  writer_waitrequest <= '1' when rnd > 0.01 else '0';

  dut: entity work.stream_to_avalon
  port map
  (
    stream_clk    => clk           ,
    stream_rst    => rst           ,
    stream_data   => stream_data   ,
    stream_valid  => stream_valid  ,
    stream_ready  => stream_ready  ,
    
    clk => clk,
    rst => rst,
    
    ctl_write            => ctl_write                      ,
    ctl_read             => ctl_read                       ,
    ctl_address          => ctl_address(3 downto 0)        ,
    ctl_writedata        => ctl_writedata                  ,
    ctl_readdata         => ctl_readdata                   ,
    ctl_waitrequest      => ctl_waitrequest                ,
    ctl_readdatavalid    => ctl_readdatavalid              ,

    writer_write         => writer_write                   ,
    writer_waitrequest   => writer_waitrequest             ,
    writer_address       => writer_address                 ,
    writer_burstcount    => writer_burstcount              ,
    writer_writedata     => writer_writedata   
  );
  
  tb_sm: entity work.testbench_mm_master generic map (instructions => (
    (do_write, 1, 1024),
	(do_write, 2, 8192),
	(do_write, 0, 1),
	(do_write, 0, 2),
	(do_write, 0, 0),
    (do_idle, 0, 0)
  )) port map
  (
    clk => clk,
    rst => rst,
    
    mm_write       => ctl_write           ,
    mm_waitrequest => ctl_waitrequest     ,
    mm_address     => ctl_address         ,
    mm_writedata   => ctl_writedata  
  );
  ctl_read <= '0';

end architecture;



















