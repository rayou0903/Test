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
		RQ				: in		STD_LOGIC;	--DDS�ǂݏ������N�G�X�g�M��(0�Ń��N�G�X�g)
		R_OR_W		: in		STD_LOGIC;	--�ǂݏ������ʐM��(0(�{�^��������)�œǂݏo���C1�ŏ�������)
		IO_RESET		: out		STD_LOGIC;	--9(1�Ń��Z�b�g)
		RESET			: out		STD_LOGIC;	--10(1�Ń��Z�b�g)
		SDO      	: in  	STD_LOGIC;	--13
		SDIO 			: inout  STD_LOGIC;	--14
      SCLK 			: inout 	STD_LOGIC;	--15(�V���A���N���b�N 1MHz)
      CS 			: out  	STD_LOGIC;	--16(0�ŒʐM�\)
      SYNC_IN		: out		STD_LOGIC;	--19(�ۗ�)
		IO_UPDATE	: out		STD_LOGIC;	--20(1�ōX�V)
		PSEL			: out		STD_LOGIC_VECTOR(2 downto 0);	--Profile Select(21 to 23)
		TXD			: out		STD_LOGIC	--rs232c�p(�Ƃ肠����led�ő�p)
      );
end serial;

architecture RTL of serial is
	--Clock Generator
	component clk_generator
		port(
			CLK_IN		: in  std_logic;
			--CLK_INNER	: out std_logic;
			SCLK			: out std_logic
		);
	end component;

	component dds_communication
		port(
			SCLK			: in		std_logic;								--�V���A���ʐM�p�N���b�N�M��(25MHz)
			RST			: in		std_logic;								--���Z�b�g�M��
			RQ				: in		std_logic;								--���N�G�X�g�M��(1�Ń��N�G�X�g)
			R_OR_W		: in		std_logic;								--�ǂݏ������ʐM��(0�œǂݏo���C1�ŏ�������)
			AC_REG		: in		std_logic_vector(4 downto 0);		--�A�N�Z�X���W�X�^
			DSEND			: in		std_logic_vector(63 downto 0);	--���M�f�[�^
			SDIO			: inout	std_logic;								--�ʐM�M��
			CS				: out		std_logic;								--�`�b�v�Z���N�g�M��(0�ŒʐM�\)
			IO_UPDATE	: out		std_logic;								--�f�[�^�X�V�M��(1�ōX�V)
			DGET			: out		std_logic_vector(63 downto 0);	--��M�f�[�^
			BUSY			: out		std_logic;								--�r�W�[�M��(1�Ńr�W�[���)
			TXD			: out		std_logic
		);
	end component;
	
	--inner signal
	type state_t is (IDLE, DDS_REQUEST, PC_REQUEST, STANDBY);
	signal state		: state_t := IDLE;
	signal clk_rs232c	: std_logic;	--RS232C�p�N���b�N(16MHz)

	signal rq_dds		: std_logic := '0';	--DDS�ǂݏ������N�G�X�g�M��(serial.vhd��dds_communication.vhd�ł̃��N�G�X�g�M���͔��]���Ă���̂Œ���)
	signal rq_pc		: std_logic := '0';	--PC���M���N�G�X�g�M��
	--signal r_or_w		: std_logic;	--�ǂݏ������ʐM��(0�œǂݏo���C1�ŏ�������)
	signal ac_reg		: std_logic_vector(4 downto 0)	:= "00110";
	signal dsend		: std_logic_vector(63 downto 0)	:= "0000000000000000000101110100010111010001011101000110101100010000";
	signal dget			: std_logic_vector(63 downto 0)	:= (others => '0');
	signal busy_dds	: std_logic;
	signal busy_pc		: std_logic;
	signal data_inner	: std_logic_vector(63 downto 0)	:= (others => '0');
	
	--clock
	signal clk_inner_slow	: std_logic;
	signal SCLK_slow			: std_logic;
	signal cnt1					: std_logic_vector(24 downto 0) := (others => '0');
	
begin
	--Clock Generator
	clk_gen : clk_generator
		port map(
			CLK_IN		=> CLK,			--�N���b�N�M��(32MHz)
			SCLK			=> SCLK			--�V���A���N���b�N(1MHz)
		);

	dds_com : dds_communication
		port map(
			SCLK			=> SCLK,
			RST			=> RST,
			RQ				=> rq_dds,
			R_OR_W		=> R_OR_W,
			AC_REG		=> ac_reg,
			DSEND			=> dsend,
			SDIO			=> SDIO,
			CS				=> CS,
			IO_UPDATE	=> IO_UPDATE,
			DGET			=> dget,
			BUSY			=> busy_dds,
			TXD			=> TXD
		);
	--25bit 1000000000000000000000000
	--13bit 1000000000000
--	process(SCLK_slow) begin
--		if rising_edge(SCLK_slow) then
--			cnt1 <= cnt1 + '1';
--			if(cnt1 >= "1000000000000000000000000") then
--				SCLK <= '1';
--			else 
--				SCLK <= '0';
--			end if;
--		end if;
--	end process;


	data_inner <= dget;
	
	process(SCLK, RST, RQ) begin
		IO_RESET	<= '0';
		RESET		<= '0';
		if(RST = '0') then
			IO_RESET		<= '1';
			RESET			<= '1';
			SYNC_IN		<= '0';
			PSEL			<= "000";
			--TXD <= '0';
			
		elsif (falling_edge(SCLK)) then
			case state is
				when IDLE =>
					if(RQ = '0') then
						state <= DDS_REQUEST;
					end if;
				
				when DDS_REQUEST =>
					if(RQ = '1') then
						rq_dds <= '1';
						state <= PC_REQUEST;
					end if;
				
				when PC_REQUEST =>
					if (busy_dds = '0') then
						rq_dds <= '0';
						if(R_OR_W = '0') then
							rq_pc <= '1';
							state <= STANDBY;
						else
							state <= IDLE;
						end if;		
					end if;
					
				when STANDBY =>
					rq_pc <= '0';
					state <= IDLE;
				
				when others => null;
			end case;
		end if;
	end process;
end RTL;