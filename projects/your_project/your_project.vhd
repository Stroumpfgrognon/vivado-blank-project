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
use ieee.numeric_std.all;

entity your_project is 
generic(
    int_variable : integer := 42;
    other_int_variable : integer := 7;
    BIT_REVERSE : std_logic_vector(1 downto 0) := "00"  -- Bit 1: reverse upper half, Bit 0: reverse lower half
);
port(
    data_in  : in  std_logic_vector(15 downto 0) := (others => '0');
    data_out : out std_logic_vector(15 downto 0)
);
end your_project;

architecture rtl of your_project is
    constant width : integer := 16;
begin

    swap : entity work.one_library
    generic map (
        WIDTH => width,
        REVERSE => BIT_REVERSE
    ) 
    port map (
        data_in => data_in,
        data_out => data_out
    );

end rtl;
 