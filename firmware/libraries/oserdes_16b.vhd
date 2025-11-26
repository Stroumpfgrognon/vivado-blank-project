
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

library UNISIM;
use UNISIM.VComponents.all;

entity oserdes_16b is
  Port (
  Din: in std_logic_vector(7 downto 0);
  serial_out_p: out std_logic;
  serial_out_n: out std_logic;
  reset: in std_logic;
  --tready: out std_logic;
  dataclk: in std_logic;
  serialclk: in std_logic);
end oserdes_16b;

architecture Behavioral of oserdes_16b is
    -- signal flag: std_logic;
    -- signal flag_cnt: std_logic_vector(7 downto 0);
    -- signal rst_delay: std_logic;
    -- signal data_in: std_logic_vector(7 downto 0);
    -- signal delay_cnt: std_logic_vector(7 downto 0);
    signal serial_out: std_logic;

begin

    

    -- posedge: process (serialclk, reset)
    -- begin
    --     if reset = '1' then 
    --         flag_cnt <= (others => '0');
    --         data_in <= "01010101";
    --     elsif rising_edge(serialclk) then
    --         flag_cnt <= flag_cnt + '1';
    --         if flag_cnt(2) = '0' then -- 0 320MHz, 1 160MHZ, 2 80MHz
    --             data_in <= not Din(15 downto 8);
    --         else 
    --             data_in <= not Din(7 downto 0);
    --         end if;
    --     end if;
    -- end process;
    
    -- posedge: process (dataclk, reset)
    --     variable flag: std_logic;
    -- begin
    --     if reset = '1' then 
    --         flag := '0';
    --         data_in <= "01010101";
    --     elsif rising_edge(dataclk) then
    --         flag := not flag;
    --         if flag = '0' then -- 0 320MHz, 1 160MHZ, 2 80MHz
    --             data_in <= not Din(15 downto 8);
    --         else 
    --             data_in <= not Din(7 downto 0);
    --         end if;
    --     end if;
    -- end process;
    

   obuf0: OBUFDS port map(
     I => serial_out,
     O => serial_out_p,
     OB => serial_out_n
   );
    



-- serializer 8:1 (4:1 DDR)
    main : OSERDESE2
    generic map (
        DATA_RATE_OQ      => "DDR",
        DATA_RATE_TQ      => "SDR",
        DATA_WIDTH        => 8,
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
        D1                => Din(7), -- MSB first 
        D2                => Din(6),
        D3                => Din(5),
        D4                => Din(4),
        D5                => Din(3),
        D6                => Din(2),
        D7                => Din(1),
        D8                => Din(0),
        -- D1                => Din(0), -- LSB first
        -- D2                => Din(1),
        -- D3                => Din(2),
        -- D4                => Din(3),
        -- D5                => Din(4),
        -- D6                => Din(5),
        -- D7                => Din(6),
        -- D8                => Din(7),
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

-- library IEEE;
-- use IEEE.STD_LOGIC_1164.ALL;
-- use ieee.numeric_std.all;
-- use ieee.numeric_std_unsigned.all;

-- library UNISIM;
-- use UNISIM.VComponents.all;

-- entity oserdes_16b is
--   Port (
--   Din: in std_logic_vector(15 downto 0);
--   serial_out_p: out std_logic;
--   serial_out_n: out std_logic;
--   reset: in std_logic;
--   --tready: out std_logic;
--   dataclk: in std_logic;
--   serialclk: in std_logic);
-- end oserdes_16b;

-- architecture Behavioral of oserdes_16b is
--     -- signal flag: std_logic;
--     -- signal flag_cnt: std_logic_vector(7 downto 0);
--     signal rst_delay: std_logic;
--     signal data_in: std_logic_vector(7 downto 0);
--     signal delay_cnt: std_logic_vector(7 downto 0);
--     signal serial_out: std_logic;

-- begin

    

--     -- posedge: process (serialclk, reset)
--     -- begin
--     --     if reset = '1' then 
--     --         flag_cnt <= (others => '0');
--     --         data_in <= "01010101";
--     --     elsif rising_edge(serialclk) then
--     --         flag_cnt <= flag_cnt + '1';
--     --         if flag_cnt(2) = '0' then -- 0 320MHz, 1 160MHZ, 2 80MHz
--     --             data_in <= not Din(15 downto 8);
--     --         else 
--     --             data_in <= not Din(7 downto 0);
--     --         end if;
--     --     end if;
--     -- end process;
    
--     posedge: process (dataclk, reset)
--         variable flag: std_logic;
--     begin
--         if reset = '1' then 
--             flag := '0';
--             data_in <= "01010101";
--         elsif rising_edge(dataclk) then
--             flag := not flag;
--             if flag = '0' then -- 0 320MHz, 1 160MHZ, 2 80MHz
--                 data_in <= not Din(15 downto 8);
--             else 
--                 data_in <= not Din(7 downto 0);
--             end if;
--         end if;
--     end process;
    

--    obuf0: OBUFDS port map(
--      I => serial_out,
--      O => serial_out_p,
--      OB => serial_out_n
--    );
    



-- -- serializer 8:1 (4:1 DDR)
--     main : OSERDESE2
--     generic map (
--         DATA_RATE_OQ      => "DDR",
--         DATA_RATE_TQ      => "SDR",
--         DATA_WIDTH        => 8,
--         SERDES_MODE       => "MASTER",
--         TRISTATE_WIDTH    => 1)
--     port map (
--         OQ                => serial_out,
--         OFB               => open,
--         TQ                => open,
--         TFB               => open,
--         SHIFTOUT1         => open,
--         SHIFTOUT2         => open,
--         TBYTEOUT          => open,
--         CLK               => serialclk,
--         CLKDIV            => dataclk,
--         D1                => data_in(7),
--         D2                => data_in(6),
--         D3                => data_in(5),
--         D4                => data_in(4),
--         D5                => data_in(3),
--         D6                => data_in(2),
--         D7                => data_in(1),
--         D8                => data_in(0),
--         TCE               => '0',
--         OCE               => '1',
--         TBYTEIN           => '0',
--         RST               => reset,
--         SHIFTIN1          => '0',
--         SHIFTIN2          => '0',
--         T1                => '0',
--         T2                => '0',
--         T3                => '0',
--         T4                => '0'
--     );



-- end Behavioral;