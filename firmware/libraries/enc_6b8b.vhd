library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use ieee.std_logic_arith.all;
use ieee.numeric_std.all;

entity enc_6b8b is
port( word6b: in std_logic_vector(5 downto 0);
      ena: in std_logic;
      clk: in std_logic;
      rst: in std_logic;
      word8b: out std_logic_vector(7 downto 0) 
);
end enc_6b8b;

architecture behave of enc_6b8b is
signal countbits1: std_logic_vector(3 downto 0):=(others=>'0');
signal word8b_tmp: std_logic_vector(7 downto 0);
signal w6b_0, w6b_1, w6b_2, w6b_3, w6b_4, w6b_5: std_logic_vector(3 downto 0):=(others=>'0');

begin
  --caculate disparity
  w6b_0 <= "000" & word6b(0);
  w6b_1 <= "000" & word6b(1);
  w6b_2 <= "000" & word6b(2);
  w6b_3 <= "000" & word6b(3);
  w6b_4 <= "000" & word6b(4);
  w6b_5 <= "000" & word6b(5);
  countbits1 <= w6b_0+w6b_1+w6b_2+w6b_3+w6b_4+w6b_5;  


  process(clk,ena)
    begin
      if rising_edge(clk)then
        if rst = '1' then
            word8b_tmp <= (others => '0');
        else
        if (ena= '1') then
          case countbits1 is
          when "0010" => 
            if (word6b /= "110000") then
              word8b_tmp <= "11" & word6b;
            else
              word8b_tmp <= "01001011";
            end if;
          when "0011" => 
            case word6b is
                when "000111" => word8b_tmp <= "01" & word6b;
                when "111000" => word8b_tmp <= "01" & word6b;
                when "010101" => word8b_tmp <= "01" & word6b;
                when "101010" => word8b_tmp <= "01" & word6b;
                when others => word8b_tmp <= "10" & word6b;
            end case;
          when "0100" =>
            if (word6b /= "001111") then
              word8b_tmp <= "00" & word6b;
            else
              word8b_tmp <= "01001011";
            end if;
          when others =>
            case word6b is
              when "000000" => word8b_tmp <= "01011001";
              when "000001" => word8b_tmp <= "01110001";
              when "000010" => word8b_tmp <= "01110010";
              when "000100" => word8b_tmp <= "01100101";
              when "001000" => word8b_tmp <= "01101001";
              when "010000" => word8b_tmp <= "01010011";
              when "100000" => word8b_tmp <= "01100011";
              when "111111" => word8b_tmp <= "01100110";
              when "111110" => word8b_tmp <= "01001110";
              when "111101" => word8b_tmp <= "01001101";
              when "111011" => word8b_tmp <= "01011010";
              when "110111" => word8b_tmp <= "01010110";
              when "101111" => word8b_tmp <= "01101100";
              when "011111" => word8b_tmp <= "01011100";
              when others => word8b_tmp <= (others => '0');
              
            end case;
          end case;
        end if; 
      end if;
      end if;
  end process;

  process(clk) begin
    if rising_edge(clk) then
      word8b <= word8b_tmp;
    end if ;

  end process;
      
        
end behave;        
      