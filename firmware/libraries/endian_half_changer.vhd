--------------------------------------------------------------------------------
-- endian_half_changer.vhd
-- Module to swap bit order of a std_logic_vector
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity endian_half_changer is
    Generic (
        WIDTH   : integer := 16;    -- Width of the input/output vector (must be even)
        REVERSE : std_logic_vector(1 downto 0) := "11"  -- Bit 1: reverse upper half, Bit 0: reverse lower half
    );
    Port (
        data_in  : in  std_logic_vector(WIDTH-1 downto 0);
        data_out : out std_logic_vector(WIDTH-1 downto 0)
    );
end endian_half_changer;

architecture Behavioral of endian_half_changer is
    constant HALF_WIDTH : integer := WIDTH / 2;
begin
    -- Lower half (bits 0 to HALF_WIDTH-1)
    gen_lower_reversed: if REVERSE(0) = '1' generate
        gen_lower_bits: for i in 0 to HALF_WIDTH-1 generate
            data_out(i) <= data_in(HALF_WIDTH-1-i);
        end generate;
    end generate;
    
    gen_lower_normal: if REVERSE(0) = '0' generate
        data_out(HALF_WIDTH-1 downto 0) <= data_in(HALF_WIDTH-1 downto 0);
    end generate;
    
    -- Upper half (bits HALF_WIDTH to WIDTH-1)
    gen_upper_reversed: if REVERSE(1) = '1' generate
        gen_upper_bits: for i in HALF_WIDTH to WIDTH-1 generate
            data_out(i) <= data_in(WIDTH-1-(i-HALF_WIDTH));
        end generate;
    end generate;
    
    gen_upper_normal: if REVERSE(1) = '0' generate
        data_out(WIDTH-1 downto HALF_WIDTH) <= data_in(WIDTH-1 downto HALF_WIDTH);
    end generate;
    
end Behavioral;
