-- uart_fsm.vhd: UART controller - finite state machine
-- Author(s): Oliver Gurka, xgurka00
--
library ieee;
use ieee.std_logic_1164.all;

-------------------------------------------------
entity UART_FSM is
port(
   CLK : in std_logic;
   RST : in std_logic;
   AS_PER_EL : in std_logic;
   DIN : in std_logic;
   BIT_CNT : in std_logic_vector(3 downto 0);
   
   DOUT_VLD : out std_logic;
   PER_SEL : out std_logic;
   CLK_CNT_EN : out std_logic;
   CNT_RST : out std_logic
   );
end entity UART_FSM;

-------------------------------------------------
architecture behavioral of UART_FSM is
   type state is (IDLE, DATA_EXPECT, DATA_READ, END_EXPECT, VALID, WAIT_READ);
   signal curr_state : state := IDLE;
   signal next_state : state := IDLE;
   
begin

   proc_state : process(CLK, RST, AS_PER_EL, next_state)
   begin
      if RST = '1' then
         curr_state <= IDLE;
      elsif (CLK'event and CLK = '1') then
         curr_state <= next_state;
      end if;
   end process proc_state;

   nstate_logic : process(curr_state, AS_PER_EL, DIN, BIT_CNT)
   begin
      next_state <= IDLE;
      case curr_state is
         when IDLE =>
            if DIN='0' then
               next_state <= DATA_EXPECT;
            else
               next_state <= IDLE;
            end if;
         
         when DATA_EXPECT =>
            if BIT_CNT >= "0001" then
               next_state <= DATA_READ;
            else
               next_state <= DATA_EXPECT;
            end if;
         
         when DATA_READ =>
            if BIT_CNT = "1000" then
               next_state <= END_EXPECT;
            else
               next_state <= DATA_READ;
            end if;
         
         when END_EXPECT =>
            if BIT_CNT = "1001" then
               next_state <= VALID;
            else 
               next_state <= END_EXPECT;
            end if;

         when VALID =>
            next_state <= WAIT_READ;
            
         when WAIT_READ =>
            next_state <= IDLE;
      end case;
   end process nstate_logic;

   output_logic : process(curr_state)
   begin
      DOUT_VLD <= '0';
      PER_SEL <= '0';
      CLK_CNT_EN <= '0';
      CNT_RST <= '0';

      case curr_state is
         when IDLE =>
            CNT_RST <= '1';
         when DATA_EXPECT =>
            CLK_CNT_EN <= '1';
         when DATA_READ =>
            CLK_CNT_EN <= '1';
            PER_SEL <= '1';
         when END_EXPECT =>
            CLK_CNT_EN <= '1';
            PER_SEL <= '1';
         when VALID =>
            DOUT_VLD <= '1';
         when WAIT_READ =>
            CNT_RST <= '1';
      end case;
   end process output_logic;

end behavioral;
