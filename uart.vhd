-- uart.vhd: UART controller - receiving part
-- Author(s): Oliver Gurka, xgurka00 
--
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

-------------------------------------------------
entity UART_RX is
port(	
    CLK: 	    in std_logic;
	RST: 	    in std_logic;
	DIN: 	    in std_logic;
	DOUT: 	    out std_logic_vector(7 downto 0);
	DOUT_VLD: 	out std_logic
);
end UART_RX;  

-------------------------------------------------
architecture behavioral of UART_RX is
	signal as_per_el : std_logic := '0';
	signal data_all : std_logic := '0';
	signal per_sel : std_logic := '0';
	signal clk_cnt_en : std_logic := '0';
	signal cnt_rst : std_logic := '0';
	signal clk_cnt_rst : std_logic := '0';
	signal period : std_logic_vector(4 downto 0);
	signal clk_counter : std_logic_vector(4 downto 0);
	signal bit_cnt_ce : std_logic := '0';
	signal bit_count : std_logic_vector(3 downto 0);
	signal data : std_logic_vector(7 downto 0) := "00000000";
begin

	fsm : entity work.UART_FSM(behavioral)
	port map (
		CLK => CLK,
		RST => RST,
		AS_PER_EL => as_per_el,
		DIN => DIN,
		DOUT_VLD => DOUT_VLD,
		PER_SEL => per_sel,
		CLK_CNT_EN => clk_cnt_en,
		CNT_RST => cnt_rst,
		BIT_CNT => bit_count
	);

	per_sel_mux : process(per_sel)
	begin
		case per_sel is
			when '0' =>
				period <= "11000";
			when '1' =>
				period <= "10000";
			when others =>
				null;
		end case;
	end process per_sel_mux;

	clk_cnt : process(CLK, clk_cnt_rst, cnt_rst, clk_cnt_en)
	begin
		if cnt_rst='1' or clk_cnt_rst='1' then
			clk_counter <= "00000";
		elsif CLK'event and CLK='1' and clk_cnt_en='1' then
			clk_counter <= clk_counter + '1';
		end if;
	end process clk_cnt;

	clk_cmp : process(period, clk_counter)
	begin
		if period = clk_counter then
			as_per_el <= '1';
			clk_cnt_rst <= '1';
		else 
			as_per_el <= '0';
			clk_cnt_rst <= '0';
		end if;
	end process clk_cmp;

	bit_cnt : process(as_per_el, cnt_rst, bit_cnt_ce)
	begin
		if cnt_rst='1' then
			bit_count <= "0000";
		elsif as_per_el'event and as_per_el='1' and bit_cnt_ce='1' then
			bit_count <= bit_count + '1';
		end if;
	end process bit_cnt;

	bit_cmp : process(bit_count)
	begin
		if bit_count = "1001" then
			data_all <= '1';
			bit_cnt_ce <= '0';
		elsif bit_count = "1000" then
		    data_all <= '1';
		else 
			data_all <= '0';
			bit_cnt_ce <= '1';
		end if;
	end process bit_cmp;

	shift_reg : process (DIN, data_all, as_per_el, CNT_RST)
	begin
	    if CNT_RST='1' then
	       data <= "00000000";
		elsif as_per_el'event and as_per_el='1' and data_all='0' then
			data <= DIN & data(7 downto 1);
		end if;
	end process shift_reg;
	
	DOUT <= data;
end behavioral;
