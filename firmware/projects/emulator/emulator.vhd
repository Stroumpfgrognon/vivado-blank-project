--! This file is modified for usage at the KTH emulator and is inspired from the ALTIROC emulator. 
--! Copyright (C) 2001-2022 CERN for the benefit of the ATLAS collaboration.
--! Authors:
--!               Frans Schreuder
--!               Prerna Baranwal
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
use IEEE.std_logic_1164.all;
library UNISIM;
use UNISIM.vcomponents.all;
library XPM;
use XPM.vcomponents.all;
use ieee.numeric_std.all;
use ieee.numeric_std_unsigned.all;

entity emulator is
generic (
    DATARATE_timing : integer := 320;
    packetlength_l: integer :=  3564;
    packetlength_t: integer :=  1;
    DATARATE_lumi : integer := 640;
    EMULATOR_DATA_PATTERN : integer :=0; 
    -- 0 sends 0 hit per window
    -- 1 sends 1 hit per window
    -- 2 sends increment counter
    -- 3 sends BCID 
    -- 4 sends constant and increment (half half)
    -- 5 sends random
    -- 6 send idle at wrong time
    -- 7 send corrupt data at specific ID
    -- 8 send sync at wrong time
    -- 9 sends word instead of idle
    --10 sends two constants half and half
    FST_CMD_en: boolean := TRUE;
    ENDIAN_CHANGER: std_logic_vector(1 downto 0) := "00"
);
port (
    LPGBT_HARD_RSTB : in std_logic;  -- From lpGBT GPIO
    LPGBT_CLK40M_P  : in std_logic;  -- 40MHz from lpGBT ECLK
    LPGBT_CLK40M_N  : in std_logic;
    FAST_CMD_P      : in std_logic;  -- From Timing lpGBT Elink
    FAST_CMD_N      : in std_logic;
    TIMING_DOUT_P   : out std_logic_vector(1 downto 0);  -- To Timing lpGBT Elink
    TIMING_DOUT_N   : out std_logic_vector(1 downto 0);
    LUMI_DOUT_P     : out std_logic_vector(1 downto 0);  -- To Lumi lpGBT Elink
    LUMI_DOUT_N     : out std_logic_vector(1 downto 0);
    --I2C_ADDR        : in std_logic_vector(3 downto 1);   -- Config by PEB
    --I2C_SCL         : in std_logic;                      -- From Timing lpGBT I2C master
    --I2C_SDA         : inout  std_logic;
    -- Test
    REFCLK_P: in std_logic;        -- Local OSC, 200MHz
    REFCLK_N: in std_logic
    --DIPSW:    in std_logic_vector(2 downto 0);        -- Switch SW1
    --TESTPIN: inout std_logic_vector(1 downto 0);          -- Connector J1
    --TP: out std_logic_vector(2 downto 1)                -- 
);
end entity emulator;

architecture rtl of emulator is

    signal reset: std_logic;
    signal clk_wiz_reset, locked: std_logic;
    signal dataclk_timing, serialclk_timing: std_logic;
    signal dataclk_lumi, serialclk_lumi: std_logic;
    signal clk160: std_logic;
    signal clk320: std_logic;
    signal clk640: std_logic;
    signal clk32, clk64, clk128, clk40, clk80: std_logic;
    signal clk200, clk200_ibuf: std_logic;
    
    signal data_10b, data_10b_inv : std_logic_vector(9 downto 0);
    signal data_16b_lumi, data_16b_lumi_inv : std_logic_vector(15 downto 0);
    signal data_16b_lumi_swapped : std_logic_vector(15 downto 0);

    signal data_8b: std_logic_vector(7 downto 0);
    signal CharIsK: std_logic;

    signal cnt_l: std_logic_vector(11 downto 0);
    signal lumi_7b_data: std_logic_vector(6 downto 0);
    signal lumi_5b_data: std_logic_vector(4 downto 0);
    signal lumi_12b_data: std_logic_vector(11 downto 0);  
  --signal tready: std_logic;
    
    
    --K-word for 8b10b
    constant Kchar_sop    : std_logic_vector (7 downto 0) := "00111100"; -- K28.1   3c    
    constant Kchar_comma  : std_logic_vector (7 downto 0) := "10111100"; -- K28.5   bc
    constant Kchar_eop    : std_logic_vector (7 downto 0) := "11011100"; -- K28.6   dc
    constant K_28_7       : std_logic_vector (7 downto 0) := "11111100"; -- K28.7   fc

    --K-word for 6b8b
    constant K_47         : std_logic_vector (5 downto 0) := "000111";    --47
    constant K_78         : std_logic_vector (5 downto 0) := "111000";    --78
    constant K_55         : std_logic_vector (5 downto 0) := "010101";    --55
    constant K_6a         : std_logic_vector (5 downto 0) := "101010";    --6a
    constant M7_c        : std_logic_vector (6 downto 0) := "0001000";
    constant M5_c        : std_logic_vector (4 downto 0) := "10001";
    signal M7        : std_logic_vector (6 downto 0);
    signal M5        : std_logic_vector (4 downto 0);

    signal trigger, bcr, cal, gbrst, settrigid, synclumi, fastcmd_locked: std_logic;
    signal trigid: std_logic_vector(11 downto 0);
    signal L1ID: std_logic_vector(23 downto 0);
    signal XL1ID: std_logic_vector(7 downto 0); 
    signal BCID: std_logic_vector(11 downto 0);
    signal lumi_byte: std_logic_vector(7 downto 0);
    signal timing_byte: std_logic_vector(7 downto 0);
    
    signal trigger_counter: std_logic_vector(7 downto 0);
    
    -- FIFO related signals
    signal wr_en_timing, rd_en_timing, full_timing, empty_timing: std_logic;
    signal din_timing, dout_timing: std_logic_vector(43 downto 0);

    signal wr_en_lumi, rd_en_lumi, full_lumi, empty_lumi: std_logic;
    signal din_lumi : std_logic_vector(15 downto 0); 
    signal dout_lumi: std_logic_vector(7 downto 0);

    -- init flag
    signal init : std_logic;
    -- fault injection flag
    signal fault : std_logic:='0';

    component clk_wiz_0
    port
     (-- Clock in ports
      -- Clock out ports
      clk32          : out    std_logic;
      clk40          : out    std_logic;
      clk64          : out    std_logic;
      clk80          : out    std_logic;
      clk128          : out    std_logic;
      clk160          : out    std_logic;
      clk320          : out    std_logic;
      -- Status and control signals

      reset             : in     std_logic;
      locked            : out    std_logic;
      clk_in1_p         : in     std_logic;
      clk_in1_n         : in     std_logic
     );
    end component;
    
    COMPONENT vio_fastcmd
      PORT (
        clk : IN STD_LOGIC;
        probe_in0 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
        probe_in1 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
        probe_in2 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
        probe_in3 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
        probe_in4 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
        probe_in5 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
        probe_in6 : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
        probe_in7 : IN STD_LOGIC_VECTOR(0 DOWNTO 0)
      );
    END COMPONENT;

begin

lumi_12b_data <= lumi_5b_data & lumi_7b_data;

clk200_buf: IBUFDS
port map(
    I => REFCLK_P,
    IB => REFCLK_N,
    O => clk200_ibuf
);

clk200_bufg: BUFG
port map(
    I => clk200_ibuf,
    O => clk200
);

 
clk0 : clk_wiz_0
   port map ( 
  -- Clock out ports  
   clk160 => clk160,
   clk320 => clk320,
   clk80 => clk80,
   clk32 => clk32,
   clk64 => clk64,
   clk128 => clk128,
   clk40 => clk40,
  -- Status and control signals                
   reset => clk_wiz_reset,
   locked => locked,
   -- Clock in ports
   clk_in1_p => LPGBT_CLK40M_P,
   clk_in1_n => LPGBT_CLK40M_N
 );
 
g_datarate_320_timing: if DATARATE_timing = 320 generate
    serialclk_timing <= clk160;
    dataclk_timing <= clk32;
end generate;

g_datarate_640_timing: if DATARATE_timing = 640 generate -- 640/64 = 10 bits
    serialclk_timing <= clk320;
    dataclk_timing <= clk64;
end generate;

--g_datarate_1280_timing: if DATARATE_timing = 1280 generate
--    serialclk_timing <= clk640;
--    dataclk_timing <= clk128;
--end generate;

-- g_datarate_lumi: if DATARATE_lumi = 1280 generate
--     serialclk_lumi <= clk640;
--     dataclk_lumi <= clk160;
-- end generate;

g_datarate_lumi: if DATARATE_lumi = 640 generate -- 640/40 = 16 bits
    serialclk_lumi <= clk320;
    dataclk_lumi <= clk40;
end generate;

    clk_wiz_reset <= not LPGBT_HARD_RSTB;
    reset <= not locked;
 
-- differtial ouput for timing and lumi channel.    
     serT0: entity work.oserdes_10b
      Port map(
      din => data_10b,
      serial_out_p => LUMI_DOUT_P(0),
      serial_out_n => LUMI_DOUT_N(0),
      reset  => reset,
      --tready => tready,
      dataclk => dataclk_timing,
      serialclk => serialclk_timing);

     serT1: entity work.oserdes_10b
      Port map(
      din => data_10b_inv,
      serial_out_p => LUMI_DOUT_P(1),
      serial_out_n => LUMI_DOUT_N(1),
      reset  => reset,
      --tready => open,
      dataclk => dataclk_timing,
      serialclk => serialclk_timing);
    
    
     serL0: entity work.oserdes_16b
      Port map(
      din => dout_lumi,
      serial_out_p => TIMING_DOUT_P(0),
      serial_out_n => TIMING_DOUT_N(0),
      reset  => reset,
      --tready => open,
      dataclk => clk80,
    --   dataclk => dataclk_lumi,
      serialclk => serialclk_lumi);

     serL1: entity work.oserdes_16b
      Port map(
      din => not dout_lumi,
      serial_out_p => TIMING_DOUT_P(1),
      serial_out_n => TIMING_DOUT_N(1),
      reset  => reset,
      --tready => open,
      dataclk => clk80,
    --   dataclk => dataclk_lumi,
      serialclk => serialclk_lumi);
   
    
datagen_timing: process(dataclk_timing, reset)
    variable cnt: integer range 0 to packetlength_t+4;
begin
    if reset = '1' then 
        cnt := packetlength_t+4;
        data_8b <= Kchar_comma;
        CharIsK <= '1';
        timing_byte<= (others =>'0');
        rd_en_timing<='0';
    elsif rising_edge(dataclk_timing) then
            CharIsK <= '0';

            case( cnt ) is
                when 0 =>
                    data_8b <= Kchar_comma;-- the tart of dataframe should follow the pattern of K28.5, K28.7, K28.7
                    CharIsK <= '1';
                    timing_byte<=timing_byte+1;
                when 1 | 2 =>
                    data_8b <= K_28_7;--dout_timing(7 downto 0);
                    CharIsK <= '1';
                when 3 to (packetlength_t+2) =>
                    data_8b<=trigger_counter;
                    timing_byte<=timing_byte+2;
                when (packetlength_t+3) =>
                    data_8b <=  Kchar_eop;
                    CharIsK <= '1';
                    timing_byte<= (others =>'0');
                when others =>
                    data_8b <= Kchar_comma;
                    CharIsK <= '1';
                    timing_byte<= (others =>'0');
            end case ;

            if cnt /= packetlength_t+4 then
                cnt := cnt + 1;
            else
                cnt := 0;
                if empty_timing = '1' then
                    rd_en_timing <= '0'; --Read trigger information from FIFO.
                else 
                    rd_en_timing<='1';
                end if;
            end if;
    end if;
end process;

process(dataclk_lumi, reset)
begin
    if reset = '1'  then
        cnt_l <= (others=>'0');
        rd_en_lumi <= '0';
        wr_en_lumi <= '0';
    elsif rising_edge(dataclk_lumi) then
        rd_en_lumi <= '1';
        wr_en_lumi <= '1';
        -- if empty_lumi = '1' then
        --     rd_en_lumi <= '0'; --Read trigger information from FIFO.
        -- else 
        --     rd_en_lumi<='1';
        -- end if;

        if (cnt_l < packetlength_l-1) then
            cnt_l <= cnt_l + 1;
        else
            cnt_l <= (others=>'0');
        end if;
    end if;
end process;

lumi_0s: if EMULATOR_DATA_PATTERN = 0 generate -- 0 sends 0 hit per window
    datagen_lumi: process(dataclk_lumi)
    begin
        if rising_edge(dataclk_lumi) then
            if reset = '1'  then 
                lumi_7b_data <= K_55(0) & K_6A; -- ALTIROC_LUMI_RESET_WORD = 556A
                lumi_5b_data <= K_55(5 downto 1);
                init <= '0';
            else
                case( to_integer(unsigned(cnt_l)) ) is
                    when 0 =>
                        if init = '0' then
                            init <= '1';
                            lumi_7b_data <=  "0000000";
                            lumi_5b_data <=  "00000";
                        else 
                            lumi_7b_data <= K_47(0) & K_78;
                            lumi_5b_data <= K_47(5 downto 1);
                        end if;
                    when 1 to (packetlength_l-1) =>
                        lumi_7b_data <=  "0000000";
                        lumi_5b_data <=  "00000";
                    when others =>
                        lumi_7b_data <= K_47(0) & K_78;
                        lumi_5b_data <= K_47(5 downto 1); 
                end case ;
            end if; 
        end if;
    end process;
end generate;

lumi_1s: if EMULATOR_DATA_PATTERN = 1 generate -- 1 sends 1 hit per window
    datagen_lumi: process(dataclk_lumi)
    begin
        if rising_edge(dataclk_lumi) then
            if reset = '1'  then 
                lumi_7b_data <= K_55(0) & K_6A; -- ALTIROC_LUMI_RESET_WORD = 556A
                lumi_5b_data <= K_55(5 downto 1);
                init <= '0';
            else
                case( to_integer(unsigned(cnt_l)) ) is
                    when 0 =>
                        if init = '0' then
                            init <= '1';
                            lumi_7b_data <=  "0000001";
                            lumi_5b_data <=  "00001";
                        else 
                            lumi_7b_data <= K_47(0) & K_78;
                            lumi_5b_data <= K_47(5 downto 1);
                        end if;
                    when 1 to (packetlength_l-1) =>
                        lumi_7b_data <=  "0000001";
                        lumi_5b_data <=  "00001";
                    when others =>
                        lumi_7b_data <= K_47(0) & K_78;
                        lumi_5b_data <= K_47(5 downto 1); 
                end case ;
            end if; 
        end if;
    end process;
end generate;

lumi_incr: if EMULATOR_DATA_PATTERN = 2 generate -- 2 sends increment counter
    datagen_lumi: process(dataclk_lumi)
    begin
        if rising_edge(dataclk_lumi) then
            if reset = '1'  then 
                lumi_7b_data <= K_47(0) & K_78; -- ALTIROC_LUMI_RESET_WORD = 556A
                lumi_5b_data <= K_47(5 downto 1);
                M7 <= (others => '0');
                M5 <= (others => '0');
                init <= '0';
                rd_en_lumi <= '0';
                wr_en_lumi <= '0';
            else
                rd_en_lumi <= '1';
                wr_en_lumi <= '1';
                M7 <= M7 + '1';
                M5 <= M5 + '1';
                case( to_integer(unsigned(cnt_l)) ) is
                    when 0 =>
                        if init = '0' then
                            init <= '1';
                            lumi_7b_data <=  M7;
                            lumi_5b_data <=  M5;
                        else 
                            lumi_7b_data <= K_47(0) & K_78;
                            lumi_5b_data <= K_47(5 downto 1);
                        end if;
                    when 1 to (packetlength_l-1) =>
                        lumi_7b_data <=  M7;
                        lumi_5b_data <=  M5;
                    when others =>
                        lumi_7b_data <= K_47(0) & K_78;
                        lumi_5b_data <= K_47(5 downto 1); 
                end case ;
            end if; 
        end if;
    end process;
end generate;

lumi_BCID: if EMULATOR_DATA_PATTERN = 3 generate -- 3 sends BCID 
    datagen_lumi: process(dataclk_lumi)
    begin
        if rising_edge(dataclk_lumi) then
            if reset = '1'  then 
                lumi_7b_data <= K_55(0) & K_6A; -- ALTIROC_LUMI_RESET_WORD = 556A
                lumi_5b_data <= K_55(5 downto 1);
                init <= '0';
            else
                case( to_integer(unsigned(cnt_l)) ) is
                    when 0 =>
                        if init = '0' then
                            init <= '1';
                            lumi_7b_data <= cnt_l(6 downto 0);
                            lumi_5b_data <= cnt_l(11 downto 7);
                        else 
                            lumi_7b_data <= K_47(0) & K_78;
                            lumi_5b_data <= K_47(5 downto 1);
                        end if;
                    when 1 to (packetlength_l-1) =>
                        lumi_7b_data <= cnt_l(6 downto 0);
                        lumi_5b_data <= cnt_l(11 downto 7);
                    when others =>
                        lumi_7b_data <= K_47(0) & K_78;
                        lumi_5b_data <= K_47(5 downto 1); 
                end case ;
            end if; 
        end if;
    end process;
end generate;

lumi_split: if EMULATOR_DATA_PATTERN = 4 generate -- 4 sends constant and increment
    datagen_lumi: process(dataclk_lumi)
    begin
        if rising_edge(dataclk_lumi) then
            if reset = '1'  then 
                -- lumi_7b_data <= K_55(0) & K_6A; -- ALTIROC_LUMI_RESET_WORD = 556A
                -- lumi_5b_data <= K_55(5 downto 1);
                lumi_7b_data <= K_47(0) & K_78;
                lumi_5b_data <= K_47(5 downto 1);
                M7 <= (others => '0');
                M5 <= (others => '0');
                init <= '0';
            else
                M7 <= M7 + '1';
                M5 <= M5 + '1';
                case( to_integer(unsigned(cnt_l)) ) is
                    when 0 =>
                        if init = '0' then
                            init <= '1';
                            lumi_7b_data <=  M7_c;
                            lumi_5b_data <=  M5_c;
                        else 
                            lumi_7b_data <= K_47(0) & K_78;
                            lumi_5b_data <= K_47(5 downto 1);
                        end if;
                    when 1 to packetlength_l/2 =>
                        lumi_7b_data <=  M7_c;
                        lumi_5b_data <=  M5_c;
                    when packetlength_l/2 + 1 to (packetlength_l-1) =>
                        lumi_7b_data <=  M7;
                        lumi_5b_data <=  M5;
                    when others =>
                        lumi_7b_data <= K_47(0) & K_78;
                        lumi_5b_data <= K_47(5 downto 1); 
                end case ;
            end if; 
        end if;
    end process;
end generate; 



lumi_random: if EMULATOR_DATA_PATTERN = 5 generate -- 5 sends random
signal lfsr_out: std_logic_vector(11 downto 0);
signal i_seed: std_logic_vector(23 downto 0) := (0 => '1', OTHERS =>'0');
signal i_en : std_logic := '1';
begin

    lfsr0: entity work.lfsr
    generic map(
        G_M => 24,          
        G_N => 12,        
        G_POLY => "111000010000000000000000")  -- ex. "1100000" x^7+x^6+1  
        -- "100000101000" 12
    port map(
        i_clk => dataclk_timing,
        i_rstb => reset,
        i_sync_reset => reset,
        i_seed => i_seed,
        i_en => i_en,
        o_lsfr => lfsr_out
        );
    
    datagen_lumi: process(dataclk_lumi)
    begin
        if rising_edge(dataclk_lumi) then
            if reset = '1'  then 
                lumi_7b_data <= K_55(0) & K_6A; -- ALTIROC_LUMI_RESET_WORD = 556A
                lumi_5b_data <= K_55(5 downto 1);
                init <= '0';
            else
                case( to_integer(unsigned(cnt_l)) ) is
                    when 0 =>
                        if init = '0' then
                            init <= '1';
                            lumi_7b_data <= lfsr_out(6 downto 0);
                            lumi_5b_data <= lfsr_out(11 downto 7);
                        else 
                            lumi_7b_data <= K_47(0) & K_78;
                            lumi_5b_data <= K_47(5 downto 1);
                        end if;
                    when 1 to (packetlength_l-1) =>
                        lumi_7b_data <= lfsr_out(6 downto 0);
                        lumi_5b_data <= lfsr_out(11 downto 7);
                    when others =>
                        lumi_7b_data <= K_47(0) & K_78;
                        lumi_5b_data <= K_47(5 downto 1); 
                end case ;
            end if; 
        end if;
    end process;
end generate;  

lumi_failIdle: if EMULATOR_DATA_PATTERN = 6 generate -- 6 sends wrong idle
constant FAULT_BCID : integer := 1000;   
constant N_FAULT : integer := 10;    
begin
    datagen_lumi: process(dataclk_lumi)
    begin
        if rising_edge(dataclk_lumi) then
            if reset = '1'  then 
                lumi_7b_data <= K_55(0) & K_6A; -- ALTIROC_LUMI_RESET_WORD = 556A
                lumi_5b_data <= K_55(5 downto 1);
                init <= '0';
            else
                case( to_integer(unsigned(cnt_l)) ) is
                    when 0 =>
                        if init = '0' then
                            init <= '1';
                            lumi_7b_data <=  "0000001";
                            lumi_5b_data <=  "00001";
                        else 
                            lumi_7b_data <= K_47(0) & K_78;
                            lumi_5b_data <= K_47(5 downto 1);
                        end if;
                    when FAULT_BCID to FAULT_BCID + N_FAULT - 1 =>
                        lumi_7b_data <= K_47(0) & K_78;
                        lumi_5b_data <= K_47(5 downto 1);
                    when others => -- regular case
                        lumi_7b_data <=  "0000001";
                        lumi_5b_data <=  "00001";
                end case ;
            end if; 
        end if;
    end process;
end generate; 

lumi_corrupt: if EMULATOR_DATA_PATTERN = 7 generate -- 7 sends corrupt data
constant FAULT_BCID : integer := 1000; 
constant N_FAULT : integer := 10; 
begin
    datagen_lumi: process(dataclk_lumi)
    begin
        if rising_edge(dataclk_lumi) then
            if reset = '1'  then 
                lumi_7b_data <= K_55(0) & K_6A; -- ALTIROC_LUMI_RESET_WORD = 556A
                lumi_5b_data <= K_55(5 downto 1);
                init <= '0';
                fault <= '0';
            else
                fault <= '0';
                case( to_integer(unsigned(cnt_l)) ) is
                    when 0 =>
                        if init = '0' then
                            init <= '1';
                            lumi_7b_data <=  "0000001";
                            lumi_5b_data <=  "00001";
                        else 
                            lumi_7b_data <= K_47(0) & K_78;
                            lumi_5b_data <= K_47(5 downto 1);
                        end if;
                    -- ------------------------------- fault case ------------------------------- --
                    when FAULT_BCID to FAULT_BCID + N_FAULT - 1 => -- 
                        lumi_7b_data <= "0000000";
                        lumi_5b_data <= "00000";
                        fault <= '1';
                    -- ------------------------------ regular case ------------------------------ --
                    when others => 
                        lumi_7b_data <=  "0000001";
                        lumi_5b_data <=  "00001";
                end case ;
            end if; 
        end if;
    end process;
end generate; 

lumi_failSync: if EMULATOR_DATA_PATTERN = 8 generate -- 8 sends wrong sync 4747
constant FAULT_BCID : integer := 1000;   
constant N_FAULT : integer := 1;    
begin
    datagen_lumi: process(dataclk_lumi)
    begin
        if rising_edge(dataclk_lumi) then
            if reset = '1'  then 
                lumi_7b_data <= K_55(0) & K_6A; -- ALTIROC_LUMI_RESET_WORD = 556A
                lumi_5b_data <= K_55(5 downto 1);
                init <= '0';
            else
                case( to_integer(unsigned(cnt_l)) ) is
                    when 0 =>
                        if init = '0' then
                            init <= '1';
                            lumi_7b_data <=  "0000001";
                            lumi_5b_data <=  "00001";
                        else 
                            lumi_7b_data <= K_47(0) & K_78;
                            lumi_5b_data <= K_47(5 downto 1);
                        end if;
                    when FAULT_BCID to FAULT_BCID + N_FAULT - 1 =>
                        lumi_7b_data <= K_47(0) & K_47;
                        lumi_5b_data <= K_47(5 downto 1);
                    when others => -- regular case
                        lumi_7b_data <=  "0000001";
                        lumi_5b_data <=  "00001";
                end case ;
            end if; 
        end if;
    end process;
end generate; 


lumi_failBCID0: if EMULATOR_DATA_PATTERN = 9 generate -- 9 sends word instead of idle
constant N_TURNS : integer := 5-1;    
signal current_turns : std_logic_vector(9 downto 0);
begin
    datagen_lumi: process(dataclk_lumi)
    begin
        if rising_edge(dataclk_lumi) then
            if reset = '1'  then 
                lumi_7b_data <= K_55(0) & K_6A; -- ALTIROC_LUMI_RESET_WORD = 556A
                lumi_5b_data <= K_55(5 downto 1);
                init <= '0';
                current_turns <= (others => '0');
            else
                case( to_integer(unsigned(cnt_l)) ) is
                    when 0 =>
                        current_turns <= current_turns + '1';
                        if init = '0' or to_integer(unsigned(current_turns)) = N_TURNS then
                            init <= '1';
                            lumi_7b_data <=  "0000001";
                            lumi_5b_data <=  "00001";
                            current_turns <= (others => '0');
                        else 
                            lumi_7b_data <= K_47(0) & K_78;
                            lumi_5b_data <= K_47(5 downto 1);
                        end if;
                    when others => -- regular case
                        lumi_7b_data <=  "0000001";
                        lumi_5b_data <=  "00001";
                end case ;
            end if; 
        end if;
    end process;
end generate; 

lumi_half: if EMULATOR_DATA_PATTERN = 10 generate -- 10 sends 2 constant values half and half 
begin
    datagen_lumi: process(dataclk_lumi)
    begin
        if rising_edge(dataclk_lumi) then
            if reset = '1'  then 
                lumi_7b_data <= K_55(0) & K_6A; -- ALTIROC_LUMI_RESET_WORD = 556A
                lumi_5b_data <= K_55(5 downto 1);
                init <= '0';
            else
                case( to_integer(unsigned(cnt_l)) ) is
                    when 0 =>
                        if init = '0' then
                            init <= '1';
                            lumi_7b_data <=  "0000001";
                            lumi_5b_data <=  "00001";
                        else 
                            lumi_7b_data <= K_47(0) & K_78;
                            lumi_5b_data <= K_47(5 downto 1);
                        end if;
                    when 1 to packetlength_l/2 =>
                        lumi_7b_data <=  "0000100";
                        lumi_5b_data <=  "00100";
                    when packetlength_l/2 + 1 to (packetlength_l-1) =>
                        lumi_7b_data <=  "0000001";
                        lumi_5b_data <=  "00001";
                    when others =>
                        lumi_7b_data <= K_47(0) & K_78;
                        lumi_5b_data <= K_47(5 downto 1); 
                end case ;
            end if; 
        end if;
    end process;
end generate; 


trigger_counter_p : process(dataclk_timing, reset)
begin
    if reset = '1' then
        trigger_counter <= (others=>'0');
    elsif rising_edge(dataclk_timing) then
            if trigger = '1' then
                trigger_counter <= trigger_counter + 1;
            end if;
    end if;       
end process;

enc0: entity work.enc_8b10b      
    port map( 
        reset => reset,
        clk => dataclk_timing,
        ena => '1',
        KI => CharIsK, 
        datain => data_8b,
        dataout => data_10b
        );

data_10b_inv <= not data_10b; 

--6b8b encoder for the leading part
enc1: entity work.enc_6b8b      
    port map( 

        clk => dataclk_lumi,
        ena => '1',
        rst => reset,
        word6b => lumi_12b_data(11 downto 6),
        word8b => data_16b_lumi(7 downto 0) -- msb byte sent first
        -- word8b => data_16b_lumi(15 downto 8) -- lsb byte sent first
        );
        
        --6b8b encoder for the tailing part
        enc2: entity work.enc_6b8b      
        port map( 
            
            clk => dataclk_lumi,
            ena => '1',
            rst => reset,
            word6b => lumi_12b_data(5 downto 0),
            -- word8b => data_16b_lumi(7 downto 0) -- lsb byte sent first
            word8b => data_16b_lumi(15 downto 8) -- msb byte sent first
        );    

swap: entity work.endian_half_changer
    generic map(
        WIDTH => 16,
        REVERSE => ENDIAN_CHANGER
    )
    port map(
        data_in => data_16b_lumi,
        data_out => data_16b_lumi_swapped
    );

-- data_16b_lumi_inv <= not data_16b_lumi;


vio_fastcmd0: vio_fastcmd
  PORT MAP (
    clk => clk160,
    probe_in0(0) => trigger,
    probe_in1(0) => bcr,
    probe_in2(0) => cal,
    probe_in3(0) => gbrst,
    probe_in4(0) => settrigid,
    probe_in5(0) => synclumi,
    probe_in6 => trigid,
    probe_in7(0) => fastcmd_locked
  );


fastcmd_dec0: entity work.fastcmd_decoder 
    port map(
        reset           => reset,
        clk160          => clk160,
        clk200          => clk200, 
        FAST_CMD_P      => FAST_CMD_P,
        FAST_CMD_N      => FAST_CMD_N,
        trigger_o       => trigger,
        bcr_o           => bcr,
        cal_o           => cal,
        gbrst_o         => gbrst,
        settrigid_o     => settrigid,
        synclumi_o      => synclumi,
        trigid_o        => trigid,
        locked_o        => fastcmd_locked
    );
g_trigger: if FST_CMD_en = TRUE generate   
    trigger_proc: process(clk160, reset)
        variable increment_Xl1ID: std_logic;
        variable cnt4: integer range 0 to 3;
    begin
        if reset = '1' then
            L1ID <= (others => '0');
            XL1ID <= (others => '0');
            BCID <= x"000";
            cnt4 := 0;
            increment_Xl1ID := '0';
        elsif rising_edge(clk160) then
                increment_Xl1ID := '0';
                if trigger = '1' then
                    if L1ID = x"FFFFFF" then
                        increment_Xl1ID := '1';
                        L1ID <= (others => '0');
                    else
                        L1ID <= L1ID + 1;
                    end if;
                    
                end if;
                if settrigid = '1' then
                    increment_Xl1ID := '1';
                    L1ID <= x"000" & trigid;
                end if;
                if increment_XL1ID = '1' then
                    XL1ID <= XL1ID + 1;
                end if;
                if cnt4 = 3 then
                    cnt4 := 0;
                    BCID <= BCID + 1;
                else
                    cnt4 := cnt4+1;
                end if;
                if bcr = '1' then
                    BCID <= x"000";
                end if;
        end if;
    end process;
    din_timing <= BCID & XL1ID & L1ID;
    else generate
    din_timing<= x"3333_3333_333";
end generate;    
    
    --FIFO to cross clock domain from clk160 to timing channel at whatever the data clock is.
    fifo0: xpm_fifo_async
   generic map (
      CASCADE_HEIGHT => 0,
      CDC_SYNC_STAGES => 2,
      DOUT_RESET_VALUE => "0",
      ECC_MODE => "no_ecc",
      FIFO_MEMORY_TYPE => "auto",
      FIFO_READ_LATENCY => 1,
      FIFO_WRITE_DEPTH => 16,
      FULL_RESET_VALUE => 0,
      PROG_EMPTY_THRESH => 6,
      PROG_FULL_THRESH => 10,
      RD_DATA_COUNT_WIDTH => 1,
      READ_DATA_WIDTH => 44,
      READ_MODE => "std",
      RELATED_CLOCKS => 0,
      SIM_ASSERT_CHK => 0,
      USE_ADV_FEATURES => "0000",
      WAKEUP_TIME => 0,
      WRITE_DATA_WIDTH => 44,
      WR_DATA_COUNT_WIDTH => 1
   )
   port map (
      almost_empty => open,
      almost_full => open,
      data_valid => open, 
      dbiterr => open,
      dout => dout_timing,
      empty => empty_timing,
      full => full_timing,
      overflow => open,
      prog_empty => open,
      prog_full => open,
      rd_data_count => open,
      rd_rst_busy => open,
      sbiterr => open,
      underflow => open,
      wr_ack => open,
      wr_data_count => open,
      wr_rst_busy => open,
      din => din_timing,
      injectdbiterr => '0',
      injectsbiterr => '0',
      rd_clk => dataclk_timing,
      rd_en => rd_en_timing,
      rst => reset,
      sleep => '0',
      wr_clk => clk160,
      wr_en => wr_en_timing
   );   

   --FIFO to cross clock domain from clk40 to lumi channel at whatever the data clock is.
   fifo1: xpm_fifo_async
   generic map (
      CASCADE_HEIGHT => 0,
      CDC_SYNC_STAGES => 2,
      DOUT_RESET_VALUE => "0",
      ECC_MODE => "no_ecc",
      FIFO_MEMORY_TYPE => "auto",
      FIFO_READ_LATENCY => 1,
      FIFO_WRITE_DEPTH => 16,
      FULL_RESET_VALUE => 0,
      PROG_EMPTY_THRESH => 6,
      PROG_FULL_THRESH => 10,
      RD_DATA_COUNT_WIDTH => 1,
      READ_DATA_WIDTH => 8,
      READ_MODE => "std",
      RELATED_CLOCKS => 0,
      SIM_ASSERT_CHK => 0,
      USE_ADV_FEATURES => "0000",
      WAKEUP_TIME => 0,
      WRITE_DATA_WIDTH => 16,
      WR_DATA_COUNT_WIDTH => 1
   )
   port map (
      almost_empty => open,
      almost_full => open,
      data_valid => open, 
      dbiterr => open,
      dout => dout_lumi,
      empty => empty_lumi,
      full => full_lumi,
      overflow => open,
      prog_empty => open,
      prog_full => open,
      rd_data_count => open,
      rd_rst_busy => open,
      sbiterr => open,
      underflow => open,
      wr_ack => open,
      wr_data_count => open,
      wr_rst_busy => open,
      din => data_16b_lumi_swapped,
      injectdbiterr => '0',
      injectsbiterr => '0',
      rd_clk => clk80,
      rd_en => rd_en_lumi,
    --   rd_en => '0',
      rst => reset,
      sleep => '0',
      wr_clk => dataclk_lumi,
      wr_en => wr_en_lumi
   );  
   
   
   
   wr_en_timing <= not full_timing;
--    wr_en_lumi <= not full_lumi;
   
     
end architecture rtl;
