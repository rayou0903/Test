----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    19:22:50 11/06/2020 
-- Design Name: 
-- Module Name:    serial - RTL 
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

entity serial is
	Port ( 
		CLK 			: in  	STD_LOGIC;	--�N���b�N�M��(32MHz)
		RST 			: in  	STD_LOGIC;	--Papilio���Z�b�g�M��(0�Ń��Z�b�g)
		WE				: in		STD_LOGIC;	--�������ݗL������(0�ŏ������݊J�n)
		IO_RESET		: out		STD_LOGIC;	--9(1�Ń��Z�b�g)
		RESET			: out		STD_LOGIC;	--10(1�Ń��Z�b�g)
		SDO      	: in  	STD_LOGIC;	--13
		SDIO 			: inout  STD_LOGIC;	--14
      SCLK 			: out  	STD_LOGIC;	--15(�V���A���N���b�N 25MHz)
      CS 			: out  	STD_LOGIC;	--16(0�ŒʐM�\)
      SYNC_IN		: out		STD_LOGIC;	--19(�ۗ�)
		IO_UPDATE	: out		STD_LOGIC;	--20(1�ōX�V)
		PSEL			: out		STD_LOGIC_VECTOR(2 downto 0)	--Profile Select(21 to 23)
      );
end serial;

architecture RTL of serial is
	--Clock Generator
	component clk_generator
		port(
			CLK_IN		: in  std_logic;
			CLK_INNER	: out std_logic;
			CLK_OUT		: out std_logic
		);
	end component;
	
	component transmitter
		port(
			CLK	: in		std_logic;	--�����N���b�N
			RST	: in		std_logic;	--���Z�b�g
			WE		: in		std_logic;	--�������ݗL������(0�ŏ������݊J�n)
			PDATA	: in		std_logic_vector(63 downto 0);	--���̓f�[�^(�p������)
			SDIO	: inout	std_logic;	--�o�̓f�[�^(�V���A��)
			BUSY	: out		std_logic;	--�r�W�[�o��(1���r�W�[���)
			CS		: out		std_logic;
			IO_UPDATE : out std_logic
		);
	end component;
	
	--inner signal
	type state_t is (IDLE, REQUEST);
	signal state		: state_t := IDLE;
	signal clk_inner	: std_logic;	--�����N���b�N(200MHz)
	signal pdata		: std_logic_vector(63 downto 0) := "1000011000010000000000000000010111010001011101000101110100011000";	--64�r�b�g
	signal busy			: std_logic;
	signal we_inner	: std_logic := '1';
	--signal sclk_inner : std_logic;
	
begin
	--Clock Generator
	clk_gen : clk_generator
		port map(
			CLK_IN		=> CLK,			--�N���b�N�M��(32MHz)
			CLK_INNER	=> clk_inner,	--�����N���b�N(200MHz)
			CLK_OUT		=> SCLK			--�V���A���N���b�N(25MHz)
		);
		
	tr : transmitter
		port map(
			CLK	=> clk_inner,
			RST	=> RST,
			WE		=> we_inner,
			PDATA	=> pdata,
			SDIO	=> SDIO,
			BUSY	=> busy,
			CS		=> CS,
			IO_UPDATE => IO_UPDATE
		);
	
	process(clk_inner, RST, WE) begin
		IO_RESET	<= '0';
		RESET		<= '0';
		if(RST = '0') then
			IO_RESET		<= '1';
			RESET			<= '1';
			--CS				<= '1';
			SYNC_IN		<= '0';
			--IO_UPDATE 	<= '0';
			PSEL			<= "000";
			
		elsif falling_edge(clk_inner) then
			case state is
				when IDLE =>
					we_inner <= '1';
					--IO_UPDATE 	<= '0';
					if (WE = '0') then
						we_inner <= '0';
						state <= REQUEST;
					end if;
				
				when REQUEST =>
					we_inner <= '1';
					if (busy = '0') then
						--IO_UPDATE 	<= '1';
						state <= IDLE;
					end if;
				
				when others => null;
			end case;
		end if;
	
	end process;
	
--	process(sclk_inner) begin
--		if(sclk_inner = '1') then
--			SCLK <= '1';
--		else
--			SCLK <= '0';
--		end if;
--	end process;
	
end RTL;

