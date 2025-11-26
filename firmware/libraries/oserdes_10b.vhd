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

library UNISIM;
use UNISIM.VComponents.all;

entity oserdes_10b is
  Port (
  din: in std_logic_vector(9 downto 0);
  serial_out_p: out std_logic;
  serial_out_n: out std_logic;
  reset: in std_logic;
  --tready: out std_logic;
  dataclk: in std_logic;
  serialclk: in std_logic);
end oserdes_10b;

architecture Behavioral of oserdes_10b is
    --signal shiftreg: std_logic_vector(9 downto 0);
    --signal cnt: integer range 0 to 7;
    signal serial_out: std_logic;
    signal shift1, shift2: std_logic;
    --attribute MARK_DEBUG: string;
    --attribute MARK_DEBUG of din: signal is "TRUE";
begin


   --shiftproc: process(dataclk)
   --begin
   --    if rising_edge(dataclk) then
   --        if reset = '1' then
   --            cnt <= 0;
   --            shiftreg <= (others => '0');
   --            tready <= '0';
   --        else
   --            tready <= '0';
   --            if cnt = 0 then
   --                shiftreg <= din;
   --            else
   --                shiftreg <= shiftreg(7 downto 0) & "00";
   --            end if;
   --            if cnt = 3 then
   --                tready <= '1';
   --            end if;
   --            
   --            if cnt = 4 then
   --                cnt <= 0;
   --            else
   --                cnt <= cnt + 1;
   --            end if;
   --
   --        end if;
   --    end if;
   --end process;
   --
   --ODDR_inst : ODDR
   --generic map(
   --   DDR_CLK_EDGE => "SAME_EDGE", -- "OPPOSITE_EDGE" or "SAME_EDGE" 
   --   INIT => '0',   -- Initial value for Q port ('1' or '0')
   --   SRTYPE => "SYNC") -- Reset Type ("ASYNC" or "SYNC")
   --port map (
   --   Q => serial_out,   -- 1-bit DDR output
   --   C => dataclk,    -- 1-bit clock input
   --   CE => '1',  -- 1-bit clock enable input
   --   D1 => shiftreg(9),  -- 1-bit data input (positive edge)
   --   D2 => shiftreg(8),  -- 1-bit data input (negative edge)
   --   R => reset,    -- 1-bit reset input
   --   S => '0'     -- 1-bit set input
   --);
   
   
   obuf0: OBUFDS port map(
     I => serial_out,
     O => serial_out_p,
     OB => serial_out_n
   );

-- serializer 10:1 (5:1 DDR)
    -- master-slave cascaded since data width > 8
    master : OSERDESE2
    generic map (
        DATA_RATE_OQ      => "DDR",
        DATA_RATE_TQ      => "SDR",
        DATA_WIDTH        => 10,
        SERDES_MODE       => "MASTER",
        TRISTATE_WIDTH    => 1)
    port map (
        OQ                => serial_out,
        OFB               => open,
        TQ                => open,
        TFB               => open,
        SHIFTOUT1         => open,
        SHIFTOUT2         => open,
        TBYTEOUT          => open,
        CLK               => serialclk,
        CLKDIV            => dataclk,
        D1                => din(9),
        D2                => din(8),
        D3                => din(7),
        D4                => din(6),
        D5                => din(5),
        D6                => din(4),
        D7                => din(3),
        D8                => din(2),
        TCE               => '0',
        OCE               => '1',
        TBYTEIN           => '0',
        RST               => reset,
        SHIFTIN1          => shift1,
        SHIFTIN2          => shift2,
        T1                => '0',
        T2                => '0',
        T3                => '0',
        T4                => '0'
    );

    slave : OSERDESE2
    generic map (
        DATA_RATE_OQ      => "DDR",
        DATA_RATE_TQ      => "SDR",
        DATA_WIDTH        => 10,
        SERDES_MODE       => "SLAVE",
        TRISTATE_WIDTH    => 1)
    port map (
        OQ                => open,
        OFB               => open,
        TQ                => open,
        TFB               => open,
        SHIFTOUT1         => shift1,
        SHIFTOUT2         => shift2,
        TBYTEOUT          => open,
        CLK               => serialclk,
        CLKDIV            => dataclk,
        D1                => '0',
        D2                => '0',
        D3                => din(1),
        D4                => din(0),
        D5                => '0',
        D6                => '0',
        D7                => '0',
        D8                => '0',
        TCE               => '0',
        OCE               => '1',
        TBYTEIN           => '0',
        RST               => reset,
        SHIFTIN1          => '0',
        SHIFTIN2          => '0',
        T1                => '0',
        T2                => '0',
        T3                => '0',
        T4                => '0'
    );



end Behavioral;

 