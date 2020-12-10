----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    01:08:00 11/23/2020 
-- Design Name: 
-- Module Name:    transmitter - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity transmitter is
	Port ( 
		CLK	: in		STD_LOGIC;
		RST	: in		STD_LOGIC;
		WE		: in  	STD_LOGIC;	--�������ݗL������(0�ŏ������݊J�n)
		PDATA	: in  	STD_LOGIC_VECTOR (63 downto 0);
		SDIO	: inout  STD_LOGIC;
		BUSY	: out		STD_LOGIC;	--�r�W�[�o��(1���r�W�[���)
		CS		: out		STD_LOGIC;
		IO_UPDATE : out STD_LOGIC
		);
end transmitter;

architecture Behavioral of transmitter is
	--inner signal
	type state_t is (IDLE, SEND, UPDATE);
	signal state		: state_t := IDLE;
	signal sdio_inner : std_logic_vector(63 downto 0) := "0000000000000000000000000000000000000000000000000000000000000000";
	signal bit_cnt		: integer := 0;
	signal clk_cnt		: integer := 0;

begin
	SDIO <= sdio_inner(63);
	process(CLK, RST) begin
		if(RST = '0') then
			CS				<= '1';
			IO_UPDATE 	<= '0';
			sdio_inner <= "0000000000000000000000000000000000000000000000000000000000000000";
			BUSY <= '0';
			
		elsif falling_edge(CLK) then
			case state is
				when IDLE =>
					if(WE = '0') then
						CS		<= '0';
						sdio_inner <= PDATA;
						BUSY	<= '1';
						state	<= SEND;
					else
						sdio_inner <= "0000000000000000000000000000000000000000000000000000000000000000";
						BUSY	<= '0';
					end if;
					
				when SEND =>
					if(bit_cnt = 63 and clk_cnt = 7) then
						CS				<= '1';
						IO_UPDATE 	<= '1';
						--BUSY  <= '0';
						bit_cnt <= 0;		--�r�b�g�J�E���^�����Z�b�g
						clk_cnt <= 0;		--�N���b�N�J�E���^�����Z�b�g
						state   <= UPDATE;	--�A�b�v�f�[�g��ԂɑJ��
					elsif(clk_cnt = 7) then
						clk_cnt   <= 0;										--�N���b�N�J�E���^�����Z�b�g
						bit_cnt   <= bit_cnt + 1;							--�r�b�g�J�E���^��1���₷
						sdio_inner <= sdio_inner(62 downto 0) & '0';	--1�r�b�g���V�t�g
					else
						clk_cnt   <= clk_cnt + 1;
					end if;
					
				when UPDATE =>
						if(clk_cnt = 7) then
						IO_UPDATE 	<= '0';
						BUSY  <= '0';
						clk_cnt <= 0;		--�N���b�N�J�E���^�����Z�b�g
						state   <= IDLE;	--�A�C�h����ԂɑJ��
					else
						clk_cnt   <= clk_cnt + 1;
					end if;
					
				when others => null;
			end case;
		end if;
	end process;

end Behavioral;

