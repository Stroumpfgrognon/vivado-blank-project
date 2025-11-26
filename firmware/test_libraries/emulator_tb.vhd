-- created by Prerna Baranwal for use at KTH
-- basic test bench for the emulator
-- needs to be customised for later usage.


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity emulator_tb is
--  Port ( );
end emulator_tb;

architecture Behavioral of emulator_tb is

    signal resetn, clk40, clk40p, clk40n, clk320: std_logic;
    signal clk200, clk200p, clk200n: std_logic;
    signal timing_dout_p, timing_dout_n, lumi_dout_p, lumi_dout_n: std_logic_vector(1 downto 0);
    constant clk200_period: time := 5ns;
    constant clk320_period: time :=25 ns / 8;
    constant clk40_period: time := clk320_period * 8;
    
    signal FAST_CMD_P, FAST_CMD_N, FAST_CMD: std_logic;

    constant IDLE      : std_logic_vector(7 downto 0) := "10101100"; -- IDLE frame
    constant TRIGGER   : std_logic_vector(7 downto 0) := "10110010"; -- L0 or L1 trigger
    constant BCR       : std_logic_vector(7 downto 0) := "10011001"; -- Bunch Counter Reset
    constant TRIGBCR   : std_logic_vector(7 downto 0) := "01101001"; -- Trigger and BCR
    constant CAL       : std_logic_vector(7 downto 0) := "11010100"; -- Calibration Pulse
    constant GBRST     : std_logic_vector(7 downto 0) := "11001010"; -- Global Reset
    constant SYNCLUMI  : std_logic_vector(7 downto 0) := "01100110"; -- Synchronize luminosity stream
    constant SETTRIGID : std_logic_vector(7 downto 0) := "01010011"; -- Set Trigger ID
    constant TRIGID    : std_logic_vector(7 downto 0) := "01XXXX01"; -- Trigger ID

begin

clk40_proc: process(clk320)
    variable clk40_shift: std_logic_vector(7 downto 0):= x"F0";
begin
    if rising_edge(clk320) then
        clk40_shift := clk40_shift(6 downto 0) & clk40_shift(7);
        clk40 <= clk40_shift(7);
    end if;
end process;

clk40p <= clk40;
clk40n <= not clk40;

clk200_proc: process
begin
    clk200 <= '1';
    wait for clk200_period/2;
    clk200 <= '0';
    wait for clk200_period/2;
end process;

clk320_proc: process
begin
    clk320 <= '1';
    wait for clk320_period/2;
    clk320 <= '0';
    wait for clk320_period/2;
end process;

clk200p <= clk200;
clk200n <= not clk200;

fastcmd_proc: process(clk320)
    variable shiftreg: std_logic_vector(7 downto 0) := IDLE;
begin
    if rising_edge(clk320) then
        FAST_CMD <= shiftreg(7);
        shiftreg := shiftreg(6 downto 0) & shiftreg(7);
    end if;
end process;

FAST_CMD_P <= FAST_CMD;
FAST_CMD_N <= not FAST_CMD;
        

reset_proc: process(clk40)
    variable cnt: integer range 0 to 255 := 0;
begin
    if rising_edge(clk40) then
        if cnt < 255 then
            resetn <= '0';
            cnt := cnt + 1;
        else
            resetn <= '1';
        end if;
    end if;
end process;

uut: entity work.emulator 
port map(
    LPGBT_HARD_RSTB => '1', --: in std_logic;  -- From lpGBT GPIO
    LPGBT_CLK40M_P  => clk40p, --: in std_logic;  -- 40MHz from lpGBT ECLK
    LPGBT_CLK40M_N  => clk40n, --: in std_logic;
    FAST_CMD_P      => FAST_CMD_P, --: in std_logic;  -- From Timing lpGBT Elink
    FAST_CMD_N      => FAST_CMD_N, --: in std_logic;
    TIMING_DOUT_P   => timing_dout_p, --: out std_logic_vector(1 downto 0);  -- To Timing lpGBT Elink
    TIMING_DOUT_N   => timing_dout_n, --: out std_logic_vector(1 downto 0);
    LUMI_DOUT_P     => lumi_dout_p, --: out std_logic_vector(1 downto 0);  -- To Lumi lpGBT Elink
    LUMI_DOUT_N     => lumi_dout_n, --: out std_logic_vector(1 downto 0)
    --I2C_ADDR        : in std_logic_vector(3 downto 1);   -- Config by PEB
    --I2C_SCL         : in std_logic;                      -- From Timing lpGBT I2C master
    --I2C_SDA         : inout  std_logic;
    -- Test
    REFCLK_P => clk200p, --: in std_logic;        -- Local OSC, 200MHz
    REFCLK_N => clk200n --: in std_logic;
    --DIPSW:    in std_logic_vector(2 downto 0);        -- Switch SW1
    --TESTPIN: inout std_logic_vector(1 downto 0);          -- Connector J1
    --TP: out std_logic_vector(2 downto 1)                -- 
);

end Behavioral;

