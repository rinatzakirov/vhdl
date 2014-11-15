use work.all;
use work.util.all;
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity stream_to_avalon is
  port
  (
    stream_clk   : in  std_logic                    ;
    stream_rst   : in  std_logic                    ;
    stream_valid : in  std_logic                    ;
    stream_ready : out std_logic                    ;
    stream_data  : in  std_logic_vector(15 downto 0);
    
    clk: in std_logic;
    rst: in std_logic;

    ctl_write             : in  std_logic                      ;
    ctl_read              : in  std_logic                      ;
    ctl_address           : in  std_logic_vector(3 downto 0)   ;
    ctl_writedata         : in  std_logic_vector(31 downto 0)  ;
    ctl_readdata          : out std_logic_vector(31 downto 0)  ;
    ctl_waitrequest       : out std_logic                      ;
    ctl_readdatavalid     : out std_logic                      ;
    
    writer_write          : out std_logic                      ;
    writer_waitrequest    : in  std_logic                      ;
    writer_address        : out std_logic_vector(31 downto 0)  ;
    writer_burstcount     : out std_logic_vector(9 downto 0)   ;
    writer_writedata      : out std_logic_vector(127 downto 0)
  );
end entity;

architecture syn of stream_to_avalon is
  constant write_little_endian: boolean := true;
  constant burst_size: integer := 256;
  
  constant avalon_bw: integer := writer_writedata'length;
  constant stream_bw: integer := stream_data'length;

  signal stream_wideData, out_data: std_ulogic_vector(avalon_bw - 1 downto 0);
  signal stream_was_full, stream_we, reset_stream_was_full, stream_start, writer_valid, writer_ready, ws_stream_start, stream_start_r, ws_stream_stop, stream_stop_r, stream_stop, writer_fifo_rst,
         stream_ready_i, writer_write_i, ws_almost_empty, ws_empty, zero_fill, fifo_empty, keep_going, ws_stream_was_full, ws_stream_was_full_r,
         writer_enough_data, writer_start, writer_busy, ws_stream_busy, ws_stream_busy_r, stream_busy, burst_active, ws_fifo_reset, rs_fifo_reset_r, rs_fifo_reset, stream_fifo_rst: std_ulogic;
  signal writer_burstWritten: integer range 0 to burst_size - 1;
  signal sample_count: integer range 0 to (avalon_bw / stream_bw) - 1;
  signal writer_nextAddress, writer_startAddress, writer_totalWords, writer_wordsToGo: unsigned(31 downto 0);

begin

  stream_fifo_rst <= stream_rst or rs_fifo_reset;
  writer_fifo_rst <= rst or rs_fifo_reset;
  writer_enough_data <= '0' when ws_almost_empty = '1' or fifo_empty = '1' else '1';
  
  stream_ready <= stream_ready_i;
  
  writer_writedata <= toSlv(out_data) when zero_fill = '0' else (others => '0');
  fifo_inst: entity work.TwoClockStreamFifo
  generic map
  (
    MEM_SIZE  => burst_size * 2,
    SYNC_READ => true
  )
  port map
  (
    in_clk   => stream_clk       ,
    in_rst   => stream_fifo_rst       ,
    in_data  => stream_wideData  ,
    in_valid => stream_we        ,
    in_ready => stream_ready_i     ,

    out_clk   => clk      ,
    out_rst   => writer_fifo_rst ,
    out_data  => out_data,
    out_valid => writer_valid    ,
    out_ready => writer_ready    ,

    almost_empty_thresh => burst_size,
    almost_empty        => ws_almost_empty,
    empty     => fifo_empty
  );
  
  process (stream_clk)
  begin
    if rising_edge(stream_clk) then
      if stream_rst = '1' then
        stream_wideData <= (others => '0');
        sample_count <= 0;
        stream_we <= '0';
        stream_was_full <= '0';
      else
        rs_fifo_reset_r <= ws_fifo_reset;
        rs_fifo_reset <= rs_fifo_reset_r;
        stream_start_r <= ws_stream_start;
        stream_start <= stream_start_r;
        stream_stop_r <= ws_stream_stop;
        stream_stop <= stream_stop_r;
        
        if reset_stream_was_full = '1' then
          stream_was_full <= '0';
        end if;
        if stream_ready_i = '0' then
          stream_was_full <= '1';
        end if;
        
        if stream_busy = '0' then
          if stream_start = '1' then
              stream_busy <= '1';
          end if;
          sample_count <= 0;
          stream_we <= '0';
        else
          if stream_stop = '1' then
              stream_busy <= '0';
          end if;
          if stream_valid = '1' then
            stream_we <= '0';
            if write_little_endian then
              stream_wideData <= toSuv(stream_data) & stream_wideData(avalon_bw - 1 downto stream_bw);
            else
              stream_wideData <= stream_wideData(avalon_bw - 1 - stream_bw downto 0) & toSuv(stream_data);
            end if;
            if sample_count = (avalon_bw / stream_bw) - 1 then
              sample_count <= 0;
              if stream_ready_i = '1' then
                stream_we <= '1';
              end if;
            else
              sample_count <= sample_count + 1;
            end if;
          end if;
        end if;
      end if;
    end if;
  end process;
  
  process (clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        ctl_waitrequest <= '0';
        ctl_readdatavalid <= '0';
        writer_start <= '0';
        writer_totalWords <= toUns(0, writer_totalWords);
        writer_startAddress <= toUns(0, writer_startAddress);
        ws_stream_start <= '0';
        ws_stream_stop <= '0';
        ws_fifo_reset <= '0';
        zero_fill <= '0';
        keep_going <= '0';
      else
        ws_stream_was_full_r <= stream_was_full;
        ws_stream_was_full <= ws_stream_was_full_r;
        if keep_going = '0' then
          writer_start <= '0';
        end if;
        if ctl_write = '1' then
          case ctl_address is
          when "0000" =>
            writer_start <= ctl_writedata(0);
            ws_stream_start <= ctl_writedata(1);
            ws_stream_stop <= ctl_writedata(2);
            ws_fifo_reset <= ctl_writedata(3);
            reset_stream_was_full <= ctl_writedata(4);
            zero_fill <= ctl_writedata(5);
            keep_going <= ctl_writedata(6);
          when "0001" =>
            writer_startAddress <= unsigned(ctl_writedata);
          when "0010" =>
            writer_totalWords <= unsigned(ctl_writedata);
          when others =>
          end case;
        end if;
        ctl_readdatavalid <= ctl_read;
        if ctl_read = '1' then
          case ctl_address is
          when "0000" =>
            ctl_readdata <= (others => '0');
            ctl_readdata(0) <= writer_busy;
            ctl_readdata(1) <= ws_stream_busy;
            ctl_readdata(2) <= ws_stream_was_full;
          when "0001" =>
            ctl_readdata <= unsToSlv(writer_nextAddress);
          when "0010" =>
            ctl_readdata <= unsToSlv(writer_wordsToGo);
          when others =>
          end case;
        end if;
      end if;
    end if;
  end process;
  
  writer_write <= writer_write_i;  
  writer_ready <= writer_write_i and not writer_waitrequest;
  process (clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        writer_write_i <= '0';
        writer_burstcount <= (others => '0');
        writer_busy <= '0';
        burst_active <= '0';
      else
        ws_stream_busy_r <= stream_busy;
        ws_stream_busy <= ws_stream_busy_r;
        if writer_busy = '0' then
          if writer_start = '1' then
            writer_busy <= '1';
            writer_nextAddress <= writer_startAddress;
            writer_wordsToGo <= writer_totalWords;
            burst_active <= '0';
          end if;
        else
          if burst_active = '1' then
            if writer_waitrequest = '0' then
              writer_wordsToGo <= writer_wordsToGo - 1;
              writer_nextAddress <= writer_nextAddress + avalon_bw / 8;
              if writer_burstWritten = burst_size - 1 then
                writer_write_i <= '0';
                writer_burstcount <= (others => '0');
                burst_active <= '0';
              else
                writer_burstWritten <= writer_burstWritten + 1;
              end if;
            end if;
          else
            if writer_wordsToGo < burst_size then
              writer_busy <= '0';
            else
              if writer_enough_data = '1' or zero_fill = '1' then
                burst_active <= '1';
                writer_address <= unsToSlv(writer_nextAddress);
                writer_burstWritten <= 0;
                writer_burstcount <= toSlv(burst_size, writer_burstcount'length);
                writer_write_i <= '1';
              end if;
            end if;
          end if;
        end if;
      end if;
    end if;
  end process;
  

end architecture;



















