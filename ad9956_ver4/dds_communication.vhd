----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    19:26:10 12/05/2020 
-- Design Name: 
-- Module Name:    dds_communication - Behavioral 
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

entity dds_communication is
	Port ( 
		CLK			: in		STD_LOGIC;								--�N���b�N�M��(�����N���b�N200MHz)
		SCLK			: in		STD_LOGIC;								--�V���A���ʐM�p�N���b�N�M��(25MHz)
		RST			: in		STD_LOGIC;								--���Z�b�g�M��
		RQ				: in		STD_LOGIC;								--���N�G�X�g�M��(1�Ń��N�G�X�g)
		R_OR_W		: in		STD_LOGIC;								--�ǂݏ������ʐM��(0�œǂݏo���C1�ŏ�������)
		AC_REG		: in  	STD_LOGIC_VECTOR (3 downto 0);	--�A�N�Z�X���W�X�^
		DSEND			: in		STD_LOGIC_VECTOR (55 downto 0);	--���M�f�[�^
		SDIO			: inout	STD_LOGIC;								--�ʐM�M��
		CS 			: out		STD_LOGIC;								--�`�b�v�Z���N�g�M��(0�ŒʐM�\)
		IO_UPDATE	: out		STD_LOGIC;								--�f�[�^�X�V�M��(1�ōX�V)
		DGET			: out		STD_LOGIC_VECTOR (55 downto 0);	--��M�f�[�^
		BUSY			: out		STD_LOGIC								--�r�W�[�M��(1�Ńr�W�[���)
	);
end dds_communication;

architecture Behavioral of dds_communication is
	--innner signal
	type state_t is (IDLE, INSTRUCTION, GET, SEND, UPDATE);
	signal state		: state_t := IDLE;												--��ԑJ��
	signal sdio_inner : std_logic_vector(55 downto 0) := (others => '0');	--����SDIO
	signal data 		: std_logic_vector(55 downto 0) := (others => '0');	--��M�f�[�^�̈ꎞ�ۊǏꏊ
	signal bit_cnt		: integer := 0;													--�r�b�g�J�E���^
	signal clk_cnt		: integer := 0;													--�N���b�N�J�E���^
	signal sclk_cnt	: integer := 1;													--SCLK�J�E���^
	
begin
--	process(SCLK) begin
--		if rising_edge(SCLK) then
--			
--			sclk_cnt <= sclk_cnt + 1;
--			
--		end if;
--	end process;

	--SDIO <= sdio_inner(55);
	process(CLK, SCLK, RST) begin
		if(RST = '0') then
			CS				<= '1';
			IO_UPDATE 	<= '0';
			DGET			<= (others => '0');
			BUSY			<= '0';
			sdio_inner	<= (others => '0');
			bit_cnt <= 0;
			clk_cnt <= 0;
			--SDIO <= 'Z';
			
		elsif rising_edge(CLK) then
			if rising_edge(SCLK) then
				sclk_cnt <= 1;
			else
				sclk_cnt <= sclk_cnt + 1;
			end if;
		
			case state is
				when IDLE =>
					if(RQ = '1' and sclk_cnt = 3) then
						CS		<= '0';
						sdio_inner <= R_OR_W & "000" & AC_REG & (55-8 downto 0 => '0');
						BUSY	<= '1';
						state	<= INSTRUCTION;
					else
						CS		<= '1';
						SDIO <= 'Z';
						IO_UPDATE 	<= '0';
						sdio_inner <= "00000000000000000000000000000000000000000000000000000000";
						BUSY	<= '0';
					end if;
					
				when INSTRUCTION =>
					SDIO <= sdio_inner(55);
					if(bit_cnt = 7 and clk_cnt = 7) then
						--CS				<= '1';
						--IO_UPDATE 	<= '1';
						bit_cnt <= 0;		--�r�b�g�J�E���^�����Z�b�g
						clk_cnt <= 0;		--�N���b�N�J�E���^�����Z�b�g
						--��ԑJ��
						if(R_OR_W = '0') then
							--SDIO <= 'Z';
							state	<= GET;
						elsif(R_OR_W = '1') then
							--SDIO <= sdio_inner(55);
							sdio_inner <= DSEND;
							state	<= SEND;
						else
							state <= IDLE;
						end if;
						
					elsif(clk_cnt = 7) then
						clk_cnt   <= 0;										--�N���b�N�J�E���^�����Z�b�g
						bit_cnt   <= bit_cnt + 1;							--�r�b�g�J�E���^��1���₷
						sdio_inner <= sdio_inner(54 downto 0) & '0';	--1�r�b�g���V�t�g
					else
						clk_cnt   <= clk_cnt + 1;
					end if;
				
				when GET =>
					SDIO <= 'Z';
					data(0) <= SDIO;
					if(bit_cnt = 55 and clk_cnt = 7) then
						CS				<= '1';
						bit_cnt <= 0;		--�r�b�g�J�E���^�����Z�b�g
						clk_cnt <= 0;		--�N���b�N�J�E���^�����Z�b�g
						DGET <= data;
						state   <= IDLE;	--�A�C�h����ԂɑJ��
					elsif(clk_cnt = 7) then
						clk_cnt	<= 0;									--�N���b�N�J�E���^�����Z�b�g
						bit_cnt	<= bit_cnt + 1;					--�r�b�g�J�E���^��1���₷
						--DGET		<= DGET(54 downto 0) & SDIO;
						data <= data(54 downto 0) & SDIO;	--1�r�b�g���V�t�g
					else
						clk_cnt   <= clk_cnt + 1;
					end if;
					
				when SEND =>
					SDIO <= sdio_inner(55);
					if(bit_cnt = 55 and clk_cnt = 7) then
						CS				<= '1';
						bit_cnt <= 0;		--�r�b�g�J�E���^�����Z�b�g
						clk_cnt <= 0;		--�N���b�N�J�E���^�����Z�b�g
						state   <= UPDATE;	--�A�b�v�f�[�g��ԂɑJ��
					elsif(clk_cnt = 7) then
						clk_cnt   <= 0;										--�N���b�N�J�E���^�����Z�b�g
						bit_cnt   <= bit_cnt + 1;							--�r�b�g�J�E���^��1���₷
						sdio_inner <= sdio_inner(54 downto 0) & '0';	--1�r�b�g���V�t�g
					else
						clk_cnt   <= clk_cnt + 1;
					end if;

				when UPDATE =>
						if(clk_cnt = 7) then
						
						BUSY  <= '0';
						clk_cnt <= 0;		--�N���b�N�J�E���^�����Z�b�g
						state   <= IDLE;	--�A�C�h����ԂɑJ��
					else
						IO_UPDATE 	<= '1';
						clk_cnt   <= clk_cnt + 1;
					end if;

				when others => null;
			end case;
		end if;
	end process;
end Behavioral;