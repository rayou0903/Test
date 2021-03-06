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
		SCLK			: in		STD_LOGIC;								--シリアル通信用クロック信号(25MHz)
		RST			: in		STD_LOGIC;								--リセット信号
		RQ				: in		STD_LOGIC;								--リクエスト信号(1でリクエスト)
		R_OR_W		: in		STD_LOGIC;								--読み書き識別信号(0で読み出し，1で書き込み)
		AC_REG		: in  	STD_LOGIC_VECTOR (4 downto 0);	--アクセスレジスタ
		DSEND			: in		STD_LOGIC_VECTOR (63 downto 0);	--送信データ
		SDIO			: inout	STD_LOGIC;								--通信信号
		CS 			: out		STD_LOGIC;								--チップセレクト信号(0で通信可能)
		IO_UPDATE	: out		STD_LOGIC;								--データ更新信号(1で更新)
		DGET			: out		STD_LOGIC_VECTOR (63 downto 0);	--受信データ
		BUSY			: out		STD_LOGIC;								--ビジー信号(1でビジー状態)
		TXD			: out		STD_LOGIC
	);
end dds_communication;

architecture Behavioral of dds_communication is
	--innner signal
	type state_t is (IDLE, INSTRUCTION, GET, SEND, UPDATE);
	signal state		: state_t := IDLE;												--状態遷移
	signal sdio_inner : std_logic_vector(63 downto 0) := (others => '0');	--内部SDIO
	signal data 		: std_logic_vector(63 downto 0) := (others => '0');	--受信データの一時保管場所
	signal bit_cnt		: integer := 0;													--ビットカウンタ
	signal rq_flag		: std_logic := '0';
	
begin

	--SDIO <= sdio_inner(63);
	process(SCLK, RST, RQ) begin
		if(RST = '0') then
			CS				<= '1';
			IO_UPDATE 	<= '0';
			DGET			<= (others => '0');
			BUSY			<= '0';
			sdio_inner	<= (others => '0');
			bit_cnt <= 0;
			--SDIO <= 'Z';
			TXD <= '0';
			rq_flag <= '0';
			state <= IDLE;
			
		elsif falling_edge(SCLK) then
		
			case state is
				when IDLE =>
					if(RQ = '1') then
						sdio_inner <= not(R_OR_W) & "00" & AC_REG & (63-8 downto 0 => '0');		--後でnotを削除するかも
						BUSY	<= '1';
						state	<= INSTRUCTION;
					else
						CS		<= '1';
						SDIO <= 'Z';
						IO_UPDATE 	<= '0';
						sdio_inner <= (others => '0');
						BUSY	<= '0';
--						if(RQ = '1') then
--							rq_flag <= '1';
--						end if;
					end if;
					
				when INSTRUCTION =>
					CS		<= '0';
					SDIO <= sdio_inner(63);
					if(bit_cnt = 7) then
						rq_flag <= '0';
						--CS				<= '1';
						--IO_UPDATE 	<= '1';
						bit_cnt <= 0;		--ビットカウンタをリセット
						--状態遷移
						if(R_OR_W = '0') then
							--SDIO <= 'Z';
							state	<= GET;
						elsif(R_OR_W = '1') then
							--SDIO <= sdio_inner(63);
							sdio_inner <= DSEND;
							state	<= SEND;
						else
							state <= IDLE;
						end if;

					else
						bit_cnt   <= bit_cnt + 1;							--ビットカウンタを1増やす
						sdio_inner <= sdio_inner(62 downto 0) & '0';	--1ビット左シフト
					end if;
				
--				when GET =>
--					SDIO <= 'Z';
--					data(0) <= SDIO;
--					if(bit_cnt = 63 and clk_cnt = 7) then
--						CS				<= '1';
--						bit_cnt <= 0;		--ビットカウンタをリセット
--						clk_cnt <= 0;		--クロックカウンタをリセット
--						DGET <= data;
--						state   <= IDLE;	--アイドル状態に遷移
--					elsif(clk_cnt = 7) then
--						clk_cnt	<= 0;									--クロックカウンタをリセット
--						bit_cnt	<= bit_cnt + 1;					--ビットカウンタを1増やす
--						--DGET		<= DGET(54 downto 0) & SDIO;
--						data <= data(62 downto 0) & SDIO;	--1ビット左シフト
--					else
--						clk_cnt   <= clk_cnt + 1;
--					end if;
					
				when SEND =>
					SDIO <= sdio_inner(63);
					if(bit_cnt = 63) then
						bit_cnt <= 0;		--ビットカウンタをリセット
						state   <= UPDATE;	--アップデート状態に遷移

					else
						bit_cnt   <= bit_cnt + 1;							--ビットカウンタを1増やす
						sdio_inner <= sdio_inner(62 downto 0) & '0';	--1ビット左シフト
					end if;

				when UPDATE =>
					CS		<= '1';
					TXD	<= '1';
					BUSY  <= '0';
					IO_UPDATE 	<= '1';
					state   <= IDLE;	--アイドル状態に遷移

				when others => null;
			end case;
		end if;
	end process;
end Behavioral;