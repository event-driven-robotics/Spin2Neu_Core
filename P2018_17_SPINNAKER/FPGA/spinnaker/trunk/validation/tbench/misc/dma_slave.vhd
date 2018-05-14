-- -----------------------------------------------------------------------------
-- -----------------------------------------------------------------------------
-- Author: 			F. Diotalevi
-- Company:			IIT
-- Purpose:
-- Project:			
-- Department:	Robotics, Brain and Cognitive Sciences
--             Electronic Design Laboratory
-- 
-- No part of this document can be photocopied, 
-- reproduced, translated, or stored on electronic 
-- storage without the prior written agreement of IIT
-- 
-- IIT, Italian Institute of Technology (C) COPYRIGHT 2011
-- ----------------------------------------------------------------------------
-- ----------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_TEXTIO.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.MATH_REAL.ALL;
USE IEEE.numeric_STD.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

library std;
	use std.textio.all;
library work;
	use work.AXI4LiteMasterBFM_pkg.all;

entity dma_slave is
   generic(
      DMASTREAMM_CMD_FILE    : string        := "dmasm.cmd";  -- Command file name
      DMASTREAMM_LOG_FILE    : string        := "dmasm.log"   -- Log file name
		);
    Port ( -- axi stream
           S_AXIS_ACLK    : in  STD_LOGIC;
           S_AXIS_ARESETN : in  STD_LOGIC;
           S_AXIS_TREADY  : out std_logic;
           S_AXIS_TDATA   : in  std_logic_vector(31 downto 0);
           S_AXIS_TLAST   : in  std_logic;
           S_AXIS_TVALID  : in  std_logic;
           -- 
           start          : in  std_logic;
           dma_done       : out std_logic

          );
end dma_slave;

architecture Behavioral of dma_slave is

	-- Clock period definitions
   file logfile_ptr      : text open WRITE_MODE is DMASTREAMM_LOG_FILE;

------------------------------------------------------------------
--- Procedure PrintMsg: print a message 
------------------------------------------------------------------
procedure  PrintMsg(
   constant  message  : in	string(1 to MESSAGE_LENGTH)) is
   variable v_buf_out: line;
begin
  write (v_buf_out, message );
  write (v_buf_out, now);
  writeline (output, v_buf_out);
  write (v_buf_out, message );
  write (v_buf_out, now);
  writeline (logfile_ptr, v_buf_out);
end procedure PrintMsg;

------------------------------------------------------------------
--- Procedure WaitNClockCycles: Wait num_of_clock Cycles 
------------------------------------------------------------------
procedure  WaitNClockCycles(
   signal  aclk   : in  std_logic;
   constant  num_of_clock  : in	integer) is
begin
  for i in 1 to num_of_clock loop
		wait until (aclk'event and aclk='1');
  end loop;
end procedure WaitNClockCycles;


------------------------------------------------------------------
--- Procedure FinishDMA
------------------------------------------------------------------
procedure  FinishDMA(
   signal  aclk  : in std_logic) is
   variable v_buf_out: line;
begin
  for i in 1 to 10 loop
		wait until (aclk'event and aclk='1');
  end loop;
  
  write (v_buf_out, string'(">>>> End of DMA activity") );
  writeline (output, v_buf_out);

  write (v_buf_out, string'(">>>> End of DMA activity") );
  writeline (logfile_ptr, v_buf_out);
  
  assert (FALSE) report " NONE." severity FAILURE;
end procedure FinishDMA;

------------------------------------------------------------------
--- Procedure DMARead
------------------------------------------------------------------
procedure  DMARead(
   signal    aclk           : in  std_logic;
   constant  repeatedBurst  : in  natural;
   signal    S_Axis_TVALID  : in  std_logic;
   signal    S_Axis_TLAST   : in  std_logic;
   signal    S_Axis_TDATA   : in  std_logic_vector (31 downto 0);
   signal    S_Axis_TREADY  : out std_logic
   ) is
   variable v_buf_out: line;
   variable v_Burst : natural;
   variable TDATA : std_logic_vector (31 downto 0);
   variable i : natural;
begin
  
  wait until (aclk'event and aclk='1');
  S_Axis_TREADY <= transport '1' after 0.1 ns;
  write (v_buf_out, now);
  write (v_buf_out, string'(" DMA Read. ") );
  writeline (output, v_buf_out);

  write (v_buf_out, now);
  write (v_buf_out, string'(" DMA Read. ") );
  writeline (logfile_ptr, v_buf_out);
  
  v_Burst := repeatedBurst;
  i:=0;
  while (v_Burst>0) loop
      wait until (aclk'event and aclk='1');
        if (S_Axis_TVALID='1') then
            TDATA:=S_Axis_TDATA;
    	    
            write (v_buf_out, string'("  ") );
    	    write (v_buf_out, repeatedBurst-v_Burst );
            write (v_buf_out, string'("  ") );
    	    write (v_buf_out, i );
    	    write (v_buf_out, string'(": Read ") );
    	    hwrite (v_buf_out, TDATA );
    	    write (v_buf_out, string'(" @ ") );
            write (v_buf_out, now);
            writeline (output, v_buf_out);
    	    
            write (v_buf_out, string'("  ") );
    	    write (v_buf_out, repeatedBurst-v_Burst );
            write (v_buf_out, string'("  ") );
    	    write (v_buf_out, i );
    	    write (v_buf_out, string'(": Read ") );
    	    hwrite (v_buf_out, TDATA );
    	    write (v_buf_out, string'(" @ ") );
            write (v_buf_out, now);
            writeline (logfile_ptr, v_buf_out);
            
            i:=i+1;
        end if;
            
        if (S_Axis_TLAST='1') then
    	    write (v_buf_out, string'(">>> End burst @ ") );
            write (v_buf_out, now);
            writeline (output, v_buf_out);
    	    write (v_buf_out, string'(">>> End burst @ ") );
            write (v_buf_out, now);
            writeline (logfile_ptr, v_buf_out);
            v_burst := v_burst - 1;
            i := 0;
        end if;
  end loop;
  
  S_Axis_TREADY<= transport '0' after 0.1 ns;
end procedure DMARead;

    
signal dbg1, dbg2, dbg3 : std_logic;
signal norandom : std_logic;

begin

--------------------------------------------------
-- Command File FSM
--------------------------------------------------
p_cmd_fsm: process

    variable v_access           : OP_ENTRY;
    variable v_eof              : std_logic;
    variable v_buf_out          : line;
   file cmdfile_ptr      : text open READ_MODE  is DMASTREAMM_CMD_FILE;

begin
    S_Axis_TREADY <= '0';
    dma_done <= '0';
    norandom <= '0';
    
   v_eof := '0';

  loop
      read_cmd_file(cmdfile_ptr, v_access, v_eof);
      exit when (v_eof='1');
      case (v_access.OPCODE) is
            when PRT => PrintMsg(v_access.MESSAGE);
            when DMR => DMARead(S_axis_ACLK,v_access.RPTBURST,S_Axis_TVALID,S_Axis_TLAST,S_Axis_TDATA,S_Axis_TREADY);
            when WAT => WaitNClockCycles(S_AXIS_ACLK,v_access.CLOCK_NUM);
            when others => null;
      end case;
  end loop;
  
  FinishDMA(S_Axis_ACLK);

end process p_cmd_fsm;

end Behavioral;


