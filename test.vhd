library ieee;
use ieee.std_logic_1164.all;
entity decoder_2_to_4_w_enable is
   port(EN, A0, A1: in std_logic;)
   D0, D1, D2, D3: out std_logic);
   end decoder_2_to_4_w_enable;