--------------------------------------------------------------------------------
-- tb_your_project.vhd
-- Testbench for endian module with half-word reversal control
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_your_project is
end tb_your_project;

architecture Behavioral of tb_your_project is
    
    -- Component declaration
    component your_project is
        Generic (
            int_variable  : integer := 16;
            BIT_REVERSE : std_logic_vector(1 downto 0) := "11"
        );
        Port (
            data_in  : in  std_logic_vector(15 downto 0);
            data_out : out std_logic_vector(15 downto 0)
        );
    end component;
    
    -- Test signals
    signal data_in : std_logic_vector(15 downto 0);
    
    -- Output signals for different REVERSE configurations
    signal data_out_00 : std_logic_vector(15 downto 0);  -- No reversal
    signal data_out_01 : std_logic_vector(15 downto 0);  -- Lower half reversed
    signal data_out_10 : std_logic_vector(15 downto 0);  -- Upper half reversed
    signal data_out_11 : std_logic_vector(15 downto 0);  -- Both halves reversed
    
    -- Helper function to reverse a vector
    function reverse_vector(vec : std_logic_vector) return std_logic_vector is
        variable result : std_logic_vector(vec'range);
    begin
        for i in vec'range loop
            result(i) := vec(vec'high - i + vec'low);
        end loop;
        return result;
    end function;

    function to_hstring(slv: std_logic_vector) return string is
    constant hexlen : integer := (slv'length+3)/4;
    variable longslv : std_logic_vector(slv'length+3 downto 0) := (others => '0');
    variable hex : string(1 to hexlen);
    variable fourbit : std_logic_vector(3 downto 0);
begin
    longslv(slv'length-1 downto 0) := slv;
    for i in hexlen-1 downto 0 loop
        fourbit := longslv(i*4+3 downto i*4);
        case fourbit is
            when "0000" => hex(hexlen-i) := '0';
            when "0001" => hex(hexlen-i) := '1';
            when "0010" => hex(hexlen-i) := '2';
            when "0011" => hex(hexlen-i) := '3';
            when "0100" => hex(hexlen-i) := '4';
            when "0101" => hex(hexlen-i) := '5';
            when "0110" => hex(hexlen-i) := '6';
            when "0111" => hex(hexlen-i) := '7';
            when "1000" => hex(hexlen-i) := '8';
            when "1001" => hex(hexlen-i) := '9';
            when "1010" => hex(hexlen-i) := 'A';
            when "1011" => hex(hexlen-i) := 'B';
            when "1100" => hex(hexlen-i) := 'C';
            when "1101" => hex(hexlen-i) := 'D';
            when "1110" => hex(hexlen-i) := 'E';
            when "1111" => hex(hexlen-i) := 'F';
            when "ZZZZ" => hex(hexlen-i) := 'Z';
            when "UUUU" => hex(hexlen-i) := 'U';
            when "XXXX" => hex(hexlen-i) := 'X';
            when others => hex(hexlen-i) := '?';
        end case;
    end loop;
    return hex;
end function to_hstring;
    
begin
    
    -- DUT instances for each REVERSE configuration
    DUT_00: your_project
        generic map (int_variable => 16, BIT_REVERSE => "00")
        port map (data_in => data_in, data_out => data_out_00);

    DUT_01: your_project
        generic map (int_variable => 16, BIT_REVERSE => "01")
        port map (data_in => data_in, data_out => data_out_01);

    DUT_10: your_project
        generic map (int_variable => 16, BIT_REVERSE => "10")
        port map (data_in => data_in, data_out => data_out_10);

    DUT_11: your_project
        generic map (int_variable => 16, BIT_REVERSE => "11")
        port map (data_in => data_in, data_out => data_out_11);
    
    -- Stimulus process
    stim_proc: process
        variable expected_00, expected_01, expected_10, expected_11 : std_logic_vector(15 downto 0);
        variable test_passed : boolean;
        variable test_count : integer := 0;
    begin
        
        -- Test Case 1: 0x1234 (binary: 0001_0010_0011_0100)
        data_in <= x"1234";
        wait for 10 ns;
        
        -- Expected outputs:
        -- REVERSE="00": No change -> 0x1234
        -- REVERSE="01": Lower reversed -> upper=0x12, lower=0x2C (reverse of 0x34) -> 0x122C
        -- REVERSE="10": Upper reversed -> upper=0x48 (reverse of 0x12), lower=0x34 -> 0x4834
        -- REVERSE="11": Both reversed -> upper=0x48, lower=0x2C -> 0x482C
        
        expected_00 := x"1234";
        expected_01 := x"122C";
        expected_10 := x"4834";
        expected_11 := x"482C";
        
        assert data_out_00 = expected_00
            report "Test 1 failed for REVERSE=00: Expected " & to_hstring(expected_00) & ", got " & to_hstring(data_out_00)
            severity error;
        assert data_out_01 = expected_01
            report "Test 1 failed for REVERSE=01: Expected " & to_hstring(expected_01) & ", got " & to_hstring(data_out_01)
            severity error;
        assert data_out_10 = expected_10
            report "Test 1 failed for REVERSE=10: Expected " & to_hstring(expected_10) & ", got " & to_hstring(data_out_10)
            severity error;
        assert data_out_11 = expected_11
            report "Test 1 failed for REVERSE=11: Expected " & to_hstring(expected_11) & ", got " & to_hstring(data_out_11)
            severity error;
        
        -- report "Test 1 (0x1234) completed";
        
        -- Test Case 2: 0xABCD
        data_in <= x"ABCD";
        wait for 10 ns;
        
        expected_00 := x"ABCD";
        expected_01 := x"ABB3";  -- Lower reversed: B3 is reverse of CD
        expected_10 := x"D5CD";  -- Upper reversed: D5 is reverse of AB
        expected_11 := x"D5B3";  -- Both reversed
        
        assert data_out_00 = expected_00
            report "Test 2 failed for REVERSE=00: Expected " & to_hstring(expected_00) & ", got " & to_hstring(data_out_00)
            severity error;
        assert data_out_01 = expected_01
            report "Test 2 failed for REVERSE=01: Expected " & to_hstring(expected_01) & ", got " & to_hstring(data_out_01)
            severity error;
        assert data_out_10 = expected_10
            report "Test 2 failed for REVERSE=10: Expected " & to_hstring(expected_10) & ", got " & to_hstring(data_out_10)
            severity error;
        assert data_out_11 = expected_11
            report "Test 2 failed for REVERSE=11: Expected " & to_hstring(expected_11) & ", got " & to_hstring(data_out_11)
            severity error;
        
        -- report "Test 2 (0xABCD) completed";
        
        -- Test Case 3: 0xFFFF (all ones)
        data_in <= x"FFFF";
        wait for 10 ns;
        
        expected_00 := x"FFFF";
        expected_01 := x"FFFF";
        expected_10 := x"FFFF";
        expected_11 := x"FFFF";
        
        assert data_out_00 = expected_00 and data_out_01 = expected_01 and 
               data_out_10 = expected_10 and data_out_11 = expected_11
            report "Test 3 failed for 0xFFFF"
            severity error;
        
        -- report "Test 3 (0xFFFF) completed";
        
        -- Test Case 4: 0x0000 (all zeros)
        data_in <= x"0000";
        wait for 10 ns;
        
        expected_00 := x"0000";
        expected_01 := x"0000";
        expected_10 := x"0000";
        expected_11 := x"0000";
        
        assert data_out_00 = expected_00 and data_out_01 = expected_01 and 
               data_out_10 = expected_10 and data_out_11 = expected_11
            report "Test 4 failed for 0x0000"
            severity error;
        
        -- report "Test 4 (0x0000) completed";
        
        -- Test Case 5: 0x8001 (specific bit pattern)
        data_in <= x"8001";
        wait for 10 ns;
        
        expected_00 := x"8001";
        expected_01 := x"8080";  -- Lower reversed: 80 is reverse of 01
        expected_10 := x"0101";  -- Upper reversed: 01 is reverse of 80
        expected_11 := x"0180";  -- Both reversed
        
        assert data_out_00 = expected_00
            report "Test 5 failed for REVERSE=00: Expected " & to_hstring(expected_00) & ", got " & to_hstring(data_out_00)
            severity error;
        assert data_out_01 = expected_01
            report "Test 5 failed for REVERSE=01: Expected " & to_hstring(expected_01) & ", got " & to_hstring(data_out_01)
            severity error;
        assert data_out_10 = expected_10
            report "Test 5 failed for REVERSE=10: Expected " & to_hstring(expected_10) & ", got " & to_hstring(data_out_10)
            severity error;
        assert data_out_11 = expected_11
            report "Test 5 failed for REVERSE=11: Expected " & to_hstring(expected_11) & ", got " & to_hstring(data_out_11)
            severity error;
        
        -- report "Test 5 (0x8001) completed";
        
        -- Test Case 6: 0x5AA5 (alternating pattern)
        data_in <= x"5AA5";
        wait for 10 ns;
        
        expected_00 := x"5AA5";
        expected_01 := x"5AA5";  -- Lower reversed: A5 reversed is A5 (symmetric)
        expected_10 := x"5AA5";  -- Upper reversed: 55 is reverse of 5A
        expected_11 := x"5AA5";  -- Both reversed
        
        assert data_out_00 = expected_00
            report "Test 6 failed for REVERSE=00: Expected " & to_hstring(expected_00) & ", got " & to_hstring(data_out_00)
            severity error;
        assert data_out_01 = expected_01
            report "Test 6 failed for REVERSE=01: Expected " & to_hstring(expected_01) & ", got " & to_hstring(data_out_01)
            severity error;
        assert data_out_10 = expected_10
            report "Test 6 failed for REVERSE=10: Expected " & to_hstring(expected_10) & ", got " & to_hstring(data_out_10)
            severity error;
        assert data_out_11 = expected_11
            report "Test 6 failed for REVERSE=11: Expected " & to_hstring(expected_11) & ", got " & to_hstring(data_out_11)
            severity error;
        
        -- report "Test 6 (0x5AA5) completed";
        
        report "=== All tests completed successfully. Check above messages for errors ===" severity note;
        wait;
        std.env.stop;
    end process;
    
end Behavioral;