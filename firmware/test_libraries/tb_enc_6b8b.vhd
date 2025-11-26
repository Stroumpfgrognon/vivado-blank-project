library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_enc_6b8b is
end entity;

architecture sim of tb_enc_6b8b is
  -- DUT interface signals
  signal clk     : std_logic := '0';
  signal rst     : std_logic := '0';
  signal ena     : std_logic := '0';
  signal word6b  : std_logic_vector(5 downto 0) := (others=>'0');
  signal word8b  : std_logic_vector(7 downto 0);

  -- Counters and expected-value
  signal err_cnt  : integer := 0;
  signal chk_cnt  : integer := 0;
  signal exp_prev : std_logic_vector(7 downto 0) := (others=>'0');
  signal exp_now  : std_logic_vector(7 downto 0) := (others=>'0');

  -- One-cycle delay
  signal cmp_skip  : integer := 1;      

  component enc_6b8b
    port(
      word6b : in  std_logic_vector(5 downto 0);
      ena    : in  std_logic;
      clk    : in  std_logic;
      rst    : in  std_logic;
      word8b : out std_logic_vector(7 downto 0)
    );
  end component;

  -- Reference for 6b→8b encoder
  function enc6b_to_8b(w : std_logic_vector(5 downto 0)) return std_logic_vector is
    variable count1 : integer := 0;
    variable r      : std_logic_vector(7 downto 0) := (others=>'0');
  
  begin
    for i in 0 to 5 loop
      if w(i) = '1' then
        count1 := count1 + 1;
      end if;
    end loop;

    if count1 = 2 then
      if w /= "110000" then
        r := "11" & w;
      else
        r := "01001011";
      end if;

    else
      if count1 = 3 then
        if (w = "000111") or (w = "111000") or (w = "010101") or (w = "101010") then
          r := "01" & w;
        else
          r := "10" & w;
        end if;

    else
      if count1 = 4 then
        if w /= "001111" then
          r := "00" & w;
        else
          r := "01001011";
        end if;

    else
      case w is
        when "000000" => r := "01011001";
        when "000001" => r := "01110001";
        when "000010" => r := "01110010";
        when "000100" => r := "01100101";
        when "001000" => r := "01101001";
        when "010000" => r := "01010011";
        when "100000" => r := "01100011";
        when "111111" => r := "01100110";
        when "111110" => r := "01001110";
        when "111101" => r := "01001101";
        when "111011" => r := "01011010";
        when "110111" => r := "01010110";
        when "101111" => r := "01101100";
        when "011111" => r := "01011100";
        when others   => r := (others=>'0');
      end case;
    end if;
    end if;
    end if;

    return r;
  end function;

  begin
  dut_i: enc_6b8b
    port map (
      word6b => word6b,
      ena    => ena,
      clk    => clk,
      rst    => rst,
      word8b => word8b
    );

  clk <= not clk after 5 ns;

  rst_proc : process
  begin
    rst <= '1';
    wait for 25 ns; 
    rst <= '0';
    wait;
  end process;

  checker : process
    variable model_now : std_logic_vector(7 downto 0);
  begin
    wait until rising_edge(clk);
    --wait for 0 ns;--

    if rst = '1' then
      exp_prev <= (others => '0');
      exp_now  <= (others => '0');
      cmp_skip <= 1;
    else
      if cmp_skip = 0 then
        -- report "Checking : " & integer'image(to_integer(unsigned(word8b))) & " as word8b and " & integer'image(to_integer(unsigned(exp_prev))) & " as exp_prev" severity note;
        if word8b /= exp_prev then
          report "MISMATCH"
            severity error;
          err_cnt <= err_cnt + 1;
        end if;
        chk_cnt <= chk_cnt + 1;
      else
        cmp_skip <= cmp_skip - 1;
      end if;

      exp_prev <= exp_now;
      if ena = '1' then
        model_now := enc6b_to_8b(word6b);
        exp_now   <= model_now;
      else
        exp_now   <= exp_now;
      end if;  
      
    end if;
  end process;

  stim : process
  begin
    wait until rst = '0';
    wait until rising_edge(clk);

    for pass in 1 to 2 loop
      for i in 0 to 63 loop
        if (i mod 7) = 0 then
          ena    <= '0';
          word6b <= std_logic_vector(to_unsigned(i, 6));
          wait until rising_edge(clk);
        end if;

        ena    <= '1';
        word6b <= std_logic_vector(to_unsigned(i, 6));
        wait until rising_edge(clk);
      end loop;
    end loop;

    ena <= '0';
    wait until rising_edge(clk);
    wait until rising_edge(clk);

    if err_cnt = 0 then
      report "TB PASS. Checked=" & integer'image(chk_cnt) severity note;
    else
      report "TB FAIL. Errors=" & integer'image(err_cnt) &
             "  Checked=" & integer'image(chk_cnt) severity failure;
    end if;
    std.env.stop;
    wait;
  end process;

end architecture;




