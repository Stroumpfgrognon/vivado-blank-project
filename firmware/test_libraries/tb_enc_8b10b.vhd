-- Copyright 2002    Chuck Benz, Hollis, NH   
-- Copyright 2020    Frans Schreuder
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.


-- The information and description contained herein is the
-- property of Chuck Benz.
--
-- Permission is granted for any reuse of this information
-- and description as long as this copyright notice is
-- preserved.  Modifications may be made as long as this
-- notice is preserved.

-- Changelog:
-- 11 October  2002: Chuck Benz: updated with clearer messages, and checking decodeout
-- 3  November 2020: Frans Schreuder: Translated to VHDL, added UVVM testbench

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;

use work.lookup_8b10b.all; -- code8b10b lookup table

entity tb_enc_8b10b is
end entity tb_enc_8b10b;

architecture test of tb_enc_8b10b is
    signal encodein, encodein_p1, encodein_p2, encodein_p3: std_logic_vector(8 downto 0);
    signal i: integer := 0;
    signal encodeout : std_logic_vector(9 downto 0) := (others => '0');
    signal clk, reset: std_logic := '1';
    constant clk_period: time := 10 ns;

    signal code: code_type;
    
    -- signal for observation
    signal exp_neg   : std_logic_vector(9 downto 0);
    signal exp_pos   : std_logic_vector(9 downto 0);
    signal match_neg : std_logic;
    signal match_pos : std_logic;
    signal check_en  : std_logic := '0';
    signal exp_neg_q, exp_pos_q : std_logic_vector(9 downto 0);  

    -- wait for n rising edge
    procedure wait_n_rising_edge(signal c : std_logic; n : natural) is
    begin
      for k in 1 to n loop
        wait until rising_edge(c);
      end loop;
    end procedure;

  begin
    clk_proc : process
    begin
      while true loop
        clk <= '0'; wait for clk_period/2;
        clk <= '1'; wait for clk_period/2;
      end loop;
    end process;

   reset_proc: process
    begin
        reset <= '1';
        wait for clk_period;
        reset <= '0';
        wait;
    end process;

    DUTE: entity work.enc_8b10b
      port map(
        reset   => reset,
        clk     => clk,
        ena     => '1',
        KI      => code.k,
        datain  => code.val_8b,
        dataout => encodeout
      );

    encodein  <= code.k & code.val_8b; 
    
    -- signal for observation    
    exp_neg   <= code.val_10b_neg;          
    exp_pos   <= code.val_10b_pos;
    
    process(clk)
     begin
     if rising_edge(clk) then
        exp_neg_q <= code.val_10b_neg;
        exp_pos_q <= code.val_10b_pos;
     end if;
    end process;
    
    match_neg <= '1' when encodeout = exp_neg_q else '0';
    match_pos <= '1' when encodeout = exp_pos_q else '0';

   pipe_proc: process(clk, reset)
    begin
        if reset = '1' then
            encodein_p1 <= (others => '0');
            encodein_p2 <= (others => '0');
            encodein_p3 <= (others => '0');
        elsif rising_edge(clk) then
            encodein_p1 <= code.k & code.val_8b;
            encodein_p2 <= encodein_p1;
            encodein_p3 <= encodein_p2;
        end if;
    end process;
    
    selectCode: process(i)
    begin
        if i < 268 then
            code <= code8b10b(i);
        else
            code <= ('U', "UUUUUUUU", "UUUUUUUUUU", "UUUUUUUUUU", 'U');
        end if;
    end process;

    sequencer: process
    begin
        wait until reset = '0';
        report "ENCODER-ONLY: iterate all 268 valid inputs";

        for il in 0 to 267 loop
            i <= il;

            wait_n_rising_edge(clk, 1);
            
            check_en <= '1';

            assert (check_en = '0') or (encodeout = exp_pos_q) or (encodeout = exp_neg_q)
              report "Encoder output must equal val_10b_neg or val_10b_pos at idx="
                     & integer'image(il)
              severity error;
        end loop;

        report "SIMULATION COMPLETED";
        std.env.stop;
        wait;
    end process;

end architecture test;
