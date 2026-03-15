--+----------------------------------------------------------------------------
--| 
--| COPYRIGHT 2017 United States Air Force Academy All rights reserved.
--| 
--| United States Air Force Academy     __  _______ ___    _________ 
--| Dept of Electrical &               / / / / ___//   |  / ____/   |
--| Computer Engineering              / / / /\__ \/ /| | / /_  / /| |
--| 2354 Fairchild Drive Ste 2F6     / /_/ /___/ / ___ |/ __/ / ___ |
--| USAF Academy, CO 80840           \____//____/_/  |_/_/   /_/  |_|
--| 
--| ---------------------------------------------------------------------------
--|
--| FILENAME      : thunderbird_fsm.vhd
--| AUTHOR(S)     : Capt Phillip Warner, Capt Dan Johnson
--| CREATED       : 03/2017 Last modified 06/25/2020
--| DESCRIPTION   : This file implements the ECE 281 Lab 2 Thunderbird tail lights
--|					FSM using enumerated types.  This was used to create the
--|					erroneous sim for GR1
--|
--|					Inputs:  i_clk 	 --> 100 MHz clock from FPGA
--|                          i_left  --> left turn signal
--|                          i_right --> right turn signal
--|                          i_reset --> FSM reset
--|
--|					Outputs:  o_lights_L (2:0) --> 3-bit left turn signal lights
--|					          o_lights_R (2:0) --> 3-bit right turn signal lights
--|
--|					Upon reset, the FSM by defaults has all lights off.
--|					Left ON - pattern of increasing lights to left
--|						(OFF, LA, LA/LB, LA/LB/LC, repeat)
--|					Right ON - pattern of increasing lights to right
--|						(OFF, RA, RA/RB, RA/RB/RC, repeat)
--|					L and R ON - hazard lights (OFF, ALL ON, repeat)
--|					A is LSB of lights output and C is MSB.
--|					Once a pattern starts, it finishes back at OFF before it 
--|					can be changed by the inputs
--|					
--|
--|                 xxx State Encoding key
--|                 --------------------
--|                  State | Encoding
--|                 --------------------
--|                  OFF   | 
--|                  ON    | 
--|                  R1    | 
--|                  R2    | 
--|                  R3    | 
--|                  L1    | 
--|                  L2    | 
--|                  L3    | 
--|                 --------------------
--|
--|
--+----------------------------------------------------------------------------
--|
--| REQUIRED FILES :
--|
--|    Libraries : ieee
--|    Packages  : std_logic_1164, numeric_std
--|    Files     : None
--|
--+----------------------------------------------------------------------------
--|
--| NAMING CONVENSIONS :
--|
--|    xb_<port name>           = off-chip bidirectional port ( _pads file )
--|    xi_<port name>           = off-chip input port         ( _pads file )
--|    xo_<port name>           = off-chip output port        ( _pads file )
--|    b_<port name>            = on-chip bidirectional port
--|    i_<port name>            = on-chip input port
--|    o_<port name>            = on-chip output port
--|    c_<signal name>          = combinatorial signal
--|    f_<signal name>          = synchronous signal
--|    ff_<signal name>         = pipeline stage (ff_, fff_, etc.)
--|    <signal name>_n          = active low signal
--|    w_<signal name>          = top level wiring signal
--|    g_<generic name>         = generic
--|    k_<constant name>        = constant
--|    v_<variable name>        = variable
--|    sm_<state machine type>  = state machine type definition
--|    s_<signal name>          = state name
--|
--+----------------------------------------------------------------------------
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
 
entity thunderbird_fsm is 
    port (
        i_clk, i_reset  : in    std_logic;
        i_left, i_right : in    std_logic;
        o_lights_L      : out   std_logic_vector(2 downto 0);
        o_lights_R      : out   std_logic_vector(2 downto 0)
    );
end thunderbird_fsm;

architecture thunderbird_fsm_arch of thunderbird_fsm is 

-- CONSTANTS ------------------------------------------------------------------
    subtype sm_state is std_logic_vector(2 downto 0);
    constant k_OFF : sm_state := "000";
    constant k_ON  : sm_state := "001";
    constant k_L1  : sm_state := "010";
    constant k_L2  : sm_state := "011";
    constant k_L3  : sm_state := "100";
    constant k_R1  : sm_state := "101";
    constant k_R2  : sm_state := "110";
    constant k_R3  : sm_state := "111";

    signal f_S, f_S_next : sm_state := k_OFF;

begin

	-- CONCURRENT STATEMENTS --------------------------------------------------------	
    with f_S select
        o_lights_L <= "000" when k_OFF,
                      "111" when k_ON,
                      "001" when k_L1,
                      "011" when k_L2,
                      "111" when k_L3,
                      "000" when others;

    with f_S select
        o_lights_R <= "000" when k_OFF,
                      "111" when k_ON,
                      "001" when k_R1,
                      "011" when k_R2,
                      "111" when k_R3,
                      "000" when others;
	
	-- PROCESSES --------------------------------------------------------------------					   
    register_proc : process(i_clk)
    begin
        if rising_edge(i_clk) then
            if i_reset = '1' then
                f_S <= k_OFF;
            else
                f_S <= f_S_next;
            end if;
        end if;
    end process register_proc;

    next_state_proc : process(f_S, i_left, i_right)
    begin
        case f_S is
            when k_OFF =>
                if (i_left = '1' and i_right = '1') then f_S_next <= k_ON;
                elsif (i_left = '1') then f_S_next <= k_L1;
                elsif (i_right = '1') then f_S_next <= k_R1;
                else f_S_next <= k_OFF;
                end if;
            when k_ON => f_S_next <= k_OFF;
            when k_L1 => f_S_next <= k_L2;
            when k_L2 => f_S_next <= k_L3;
            when k_L3 => f_S_next <= k_OFF;
            when k_R1 => f_S_next <= k_R2;
            when k_R2 => f_S_next <= k_R3;
            when k_R3 => f_S_next <= k_OFF;
            when others => f_S_next <= k_OFF;
        end case;
    end process next_state_proc;
    
    
end thunderbird_fsm_arch;