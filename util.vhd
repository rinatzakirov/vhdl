------------------------------------------------------------------------
-- Random additional utility package
--
-- Copyright (c) 2014-2014 Rinat Zakirov
-- SPDX-License-Identifier: BSL-1.0
--
------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

package util is

  function toSuv(n: integer; size: integer) return std_ulogic_vector;
  function toSuv(n: integer; outsig: std_ulogic_vector) return std_ulogic_vector;
  function unsToSuv(sig: unsigned) return std_ulogic_vector;
  function unsToSlv(sig: unsigned) return std_logic_vector;
  function toSlv(n: integer; size: integer) return std_logic_vector;
  function toSlv(n: integer; outsig: std_logic_vector) return std_logic_vector;
  function toUns(n: integer; size: integer) return unsigned;
  function toUns(n: integer; outsig: unsigned) return unsigned;
  function toSuv(slv: std_logic_vector) return std_ulogic_vector;
  function toSlv(suv: std_ulogic_vector) return std_logic_vector;
  function toInt(slv: std_logic_vector) return integer;
  function toInt(slv: std_ulogic_vector) return integer;

end package;

package body util is

  function toSuv(n: integer; size: integer) return std_ulogic_vector is
  begin
    return std_ulogic_vector(to_unsigned(n, size));
  end function;
  
  function unsToSuv(sig: unsigned) return std_ulogic_vector is
  begin
    return std_ulogic_vector(sig);
  end function;
  
  function unsToSlv(sig: unsigned) return std_logic_vector is
  begin
    return std_logic_vector(sig);
  end function;
  
  function toSlv(n: integer; size: integer) return std_logic_vector is
  begin
    return std_logic_vector(to_unsigned(n, size));
  end function;
  
  function toUns(n: integer; size: integer) return unsigned is
  begin
    return to_unsigned(n, size);
  end function;
  
  function toSuv(n: integer; outsig: std_ulogic_vector) return std_ulogic_vector is
  begin
    return std_ulogic_vector(to_unsigned(n, outsig'length));
  end function;
  
  function toSlv(n: integer; outsig: std_logic_vector) return std_logic_vector is
  begin
    return std_logic_vector(to_unsigned(n, outsig'length));
  end function;
  
  function toUns(n: integer; outsig: unsigned) return unsigned is
  begin
    return to_unsigned(n, outsig'length);
  end function;
  
  function toSlv(suv: std_ulogic_vector) return std_logic_vector is
  begin
    return std_logic_vector(suv);
  end function;

  function toSuv(slv: std_logic_vector) return std_ulogic_vector is
  begin
    return std_ulogic_vector(slv);
  end function;
  
  function toInt(slv: std_logic_vector) return integer is
  begin
    return to_integer(unsigned(slv));
  end function;
  
  function toInt(slv: std_ulogic_vector) return integer is
  begin
    return to_integer(unsigned(slv));
  end function;

end package body;
