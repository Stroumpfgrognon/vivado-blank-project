--! This file is part of the altiroc emulator
--! Copyright (C) 2001-2022 CERN for the benefit of the ATLAS collaboration.
--! Authors:
--!               Frans Schreuder
--! 
--!   Licensed under the Apache License, Version 2.0 (the "License");
--!   you may not use this file except in compliance with the License.
--!   You may obtain a copy of the License at
--!
--!       http://www.apache.org/licenses/LICENSE-2.0
--!
--!   Unless required by applicable law or agreed to in writing, software
--!   distributed under the License is distributed on an "AS IS" BASIS,
--!   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
--!   See the License for the specific language governing permissions and
--!   limitations under the License.


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
library UNISIM;
use UNISIM.VComponents.all;
library XPM;
use XPM.VComponents.all;

entity fastcmd_decoder is
Port (
    reset : in std_logic;
    clk160: in std_logic;
    clk200: in std_logic; 
    FAST_CMD_P      : in std_logic;  -- From Timing lpGBT Elink
    FAST_CMD_N      : in std_logic;
    trigger_o : out std_logic;
    bcr_o : out std_logic;
    cal_o : out std_logic;
    gbrst_o : out std_logic;
    settrigid_o : out std_logic;
    synclumi_o : out std_logic;
    trigid_o : out std_logic_vector(11 downto 0);
    locked_o : out std_logic
);
end fastcmd_decoder;

architecture Behavioral of fastcmd_decoder is
    --! From Altiroc specification https://edms.cern.ch/ui/file/2509521/1/ALTIROC_specification.pdf
    --! Table 3.1: Fast Command definition
    
    constant IDLE      : std_logic_vector(7 downto 0) := "10101100"; -- IDLE frame
    constant TRIGGER   : std_logic_vector(7 downto 0) := "10110010"; -- L0 or L1 trigger
    constant BCR       : std_logic_vector(7 downto 0) := "10011001"; -- Bunch Counter Reset
    constant TRIGBCR   : std_logic_vector(7 downto 0) := "01101001"; -- Trigger and BCR
    constant CAL       : std_logic_vector(7 downto 0) := "11010100"; -- Calibration Pulse
    constant GBRST     : std_logic_vector(7 downto 0) := "11001010"; -- Global Reset
    constant SYNCLUMI  : std_logic_vector(7 downto 0) := "01100110"; -- Synchronize luminosity stream
    constant SETTRIGID : std_logic_vector(7 downto 0) := "01010011"; -- Set Trigger ID
    constant TRIGID    : std_logic_vector(7 downto 0) := "01XXXX01"; -- Trigger ID
    
    attribute IODELAY_GROUP : STRING;
    attribute IODELAY_GROUP of IDELAYCTRL0: label is "IDELAYCTRL0";
    attribute IODELAY_GROUP of IDELAYE2_0: label is "IDELAYCTRL0";
    signal Q1, Q2, FAST_CMD, FAST_CMD_BUF, notQ1, notQ2, notQ2_p1: std_logic;
    signal locked_s : std_logic;
   
    signal shiftreg: std_logic_vector(7 downto 0);
    signal dvalid_shift: std_logic_vector(3 downto 0);
    signal CNTVALUE: std_logic_vector(4 downto 0);
    
    attribute MARK_DEBUG: STRING;
    attribute MARK_DEBUG of Q1, Q2, notQ1, notQ2, shiftreg, dvalid_shift, CNTVALUE: signal is "true";
    signal increment_delay: std_logic;
    signal increment_delay_cnt: integer range 0 to 255;
    --signal locked_200_s: std_logic;
    signal AdditionalDelay: std_logic;
begin

IDELAYE2_0 : IDELAYE2
   generic map (
      CINVCTRL_SEL => "FALSE",          -- Enable dynamic clock inversion (FALSE, TRUE)
      DELAY_SRC => "IDATAIN",           -- Delay input (IDATAIN, DATAIN)
      HIGH_PERFORMANCE_MODE => "TRUE", -- Reduced jitter ("TRUE"), Reduced power ("FALSE")
      IDELAY_TYPE => "VARIABLE",           -- FIXED, VARIABLE, VAR_LOAD, VAR_LOAD_PIPE
      IDELAY_VALUE => 0,                -- Input delay tap setting (0-31)
      PIPE_SEL => "FALSE",              -- Select pipelined mode, FALSE, TRUE
      REFCLK_FREQUENCY => 200.0,        -- IDELAYCTRL clock input frequency in MHz (190.0-210.0, 290.0-310.0).
      SIGNAL_PATTERN => "DATA"          -- DATA, CLOCK input signal
   )
   port map (
      CNTVALUEOUT => CNTVALUE, -- 5-bit output: Counter value output
      DATAOUT => FAST_CMD,         -- 1-bit output: Delayed data output
      C => clk160,                     -- 1-bit input: Clock input
      CE => increment_delay,                   -- 1-bit input: Active high enable increment/decrement input
      CINVCTRL => '0',       -- 1-bit input: Dynamic clock inversion input
      CNTVALUEIN => "00000",   -- 5-bit input: Counter value input
      DATAIN => '0',           -- 1-bit input: Internal delay data input
      IDATAIN => FAST_CMD_BUF,         -- 1-bit input: Data input from the I/O
      INC => '1',                 -- 1-bit input: Increment / Decrement tap delay input
      LD => '0',                   -- 1-bit input: Load IDELAY_VALUE input
      LDPIPEEN => '0',       -- 1-bit input: Enable PIPELINE register to load data input
      REGRST => reset            -- 1-bit input: Active-high reset tap-delay input
   );

IDELAYCTRL0 : IDELAYCTRL
   port map (
      RDY => open,       -- 1-bit output: Ready output
      REFCLK => clk200, -- 1-bit input: Reference clock input
      RST => reset        -- 1-bit input: Active high reset input
   );
		
IBUFDS0: IBUFDS
    port map(
        I => FAST_CMD_P,
        IB => FAST_CMD_N,
        O => FAST_CMD_BUF
    );				
					
 IDDR0: IDDR 
   generic map (
      DDR_CLK_EDGE => "SAME_EDGE_PIPELINED",  
      INIT_Q1 => '0',
      INIT_Q2 => '0',
      SRTYPE => "SYNC") 
   port map (
      Q1 => Q1, 
      Q2 => Q2,
      C => clk160,
      CE => '1',
      D => FAST_CMD,
      R => reset,
      S => '0'
      );
      
    locked_o <= locked_s;
					
	notQ1 <= not Q1; --inverted because P and N on the IBUFDS are swapped.
	notQ2 <= not Q2;		

   --xpm_cdc_single_inst : xpm_cdc_single
   --   generic map (
   --      DEST_SYNC_FF => 4,   -- DECIMAL; range: 2-10
   --      INIT_SYNC_FF => 0,   -- DECIMAL; 0=disable simulation init values, 1=enable simulation init values
   --      SIM_ASSERT_CHK => 0, -- DECIMAL; 0=disable simulation messages, 1=enable simulation messages
   --      SRC_INPUT_REG => 1   -- DECIMAL; 0=do not register input, 1=register input
   --   )
   --   port map (
   --      dest_out => locked_200_s, -- 1-bit output: src_in synchronized to the destination clock domain. This output
   --                            -- is registered.
   --
   --      dest_clk => clk200, -- 1-bit input: Clock signal for the destination clock domain.
   --      src_clk => clk160,   -- 1-bit input: optional; required when SRC_INPUT_REG = 1
   --      src_in => locked_s      -- 1-bit input: Input signal to be synchronized to dest_clk domain.
   --   );
   --   
   --   xpm_cdc_single_AdditionalDelayinst : xpm_cdc_single
   --   generic map (
   --      DEST_SYNC_FF => 4,   -- DECIMAL; range: 2-10
   --      INIT_SYNC_FF => 0,   -- DECIMAL; 0=disable simulation init values, 1=enable simulation init values
   --      SIM_ASSERT_CHK => 0, -- DECIMAL; 0=disable simulation messages, 1=enable simulation messages
   --      SRC_INPUT_REG => 1   -- DECIMAL; 0=do not register input, 1=register input
   --   )
   --   port map (
   --      dest_out => AdditionalDelay, -- 1-bit output: src_in synchronized to the destination clock domain. This output
   --                            -- is registered.
   --
   --      dest_clk => clk160, -- 1-bit input: Clock signal for the destination clock domain.
   --      src_clk => clk200,   -- 1-bit input: optional; required when SRC_INPUT_REG = 1
   --      src_in => AdditionalDelay200      -- 1-bit input: Input signal to be synchronized to dest_clk domain.
   --   );


    increment_delay_proc: process(clk160)
    begin
        if rising_edge(clk160) then
            increment_delay <= '0';
            if increment_delay_cnt /= 255 then
                increment_delay_cnt <= increment_delay_cnt + 1;
            else
                increment_delay_cnt <= 0;
                increment_delay <= not locked_s; --if not locked, rotate idelay until a lock is found.
                if CNTVALUE = "11111" then
                    AdditionalDelay <= not AdditionalDelay;
                end if;
            end if;
        end if;
    end process;
    
    fastcmd_proc: process(clk160) 
        variable trigid_cnt: integer range 0 to 3;
    begin
        
        if rising_edge(clk160) then
            if reset = '1' then
                dvalid_shift <= "0000";
                trigid_cnt := 0;
            else
                trigger_o <= '0';
                bcr_o <= '0';
                cal_o <= '0';
                gbrst_o <= '0';
                synclumi_o <= '0';
                settrigid_o <= '0';
                notQ2_p1 <= notQ2;
                if AdditionalDelay = '0' then
                    shiftreg <= shiftreg(5 downto 0) & notQ1 & notQ2; --Shift in 2 DDR bits.
                else
                    shiftreg <= shiftreg(5 downto 0) & notQ2_p1 & notQ1 ; --Shift in 2 DDR bits.
                end if;
                dvalid_shift <= dvalid_shift(2 downto 0) & dvalid_shift(3);
                if locked_s = '0' then
                    if shiftreg = IDLE then
                        locked_s <= '1';
                        dvalid_shift <= "0010"; --In the current state it would have been "0001";
                    end if;

                else
                    if dvalid_shift(0) = '1' then
                        case shiftreg is
                            when IDLE => NULL;
                            when TRIGGER   => trigger_o <= '1';  
                            when BCR       => bcr_o <= '1';
                            when TRIGBCR   => trigger_o <= '1';
                                              bcr_o <= '1';
                            when CAL       => cal_o <= '1';
                            when GBRST     => gbrst_o <= '1';
                            when SYNCLUMI  => synclumi_o <= '1';
                            when SETTRIGID => trigid_cnt := 3;
                            when others =>
                                if shiftreg(7 downto 6) = TRIGID(7 downto 6) and
                                    shiftreg(1 downto 0) = TRIGID(1 downto 0) then
                                    case trigid_cnt is
                                        when 3 => trigid_o(11 downto 8) <= shiftreg(5 downto 2);
                                                  trigid_cnt := 2;
                                        when 2 => trigid_o(7 downto 4) <= shiftreg(5 downto 2);
                                                  trigid_cnt := 1;
                                        when 1 => trigid_o(3 downto 0) <= shiftreg(5 downto 2);
                                                  trigid_cnt := 0;
                                                  settrigid_o <= '1';
                                        when 0 => locked_s <= '0';
                                    end case;
                                else
                                    locked_s <= '0';
                                    dvalid_shift <= "0000";
                                end if;  
                        end case;
                    end if; --dvalid
                end if; --locked
            end if; --reset
        end if; --rising_edge
    end process;

end Behavioral;
