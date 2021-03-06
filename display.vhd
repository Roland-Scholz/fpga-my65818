-- This file is copyright by Grant Searle 2014
-- You are free to use this file in your own projects but must never charge for it nor use it without
-- acknowledgement.
-- Please ask permission from Grant Searle before republishing elsewhere.
-- If you use this file or any part of it, please add an acknowledgement to myself and
-- a link back to my main web site http://searle.hostei.com/grant/    
-- and to the UK101 page at http://searle.hostei.com/grant/uk101FPGA/index.html
--
-- Please check on the above web pages to see if there are any updates before using this file.
-- If for some reason the page is no longer available, please search for "Grant Searle"
-- on the internet to see if I have moved to another web hosting service.
--
-- Grant Searle
-- eMail address available on my main web page link above.

library ieee;
use ieee.std_logic_1164.all;
use  IEEE.NUMERIC_STD.all;
use  IEEE.STD_LOGIC_UNSIGNED.all;
use IEEE.MATH_REAL.ALL;

entity Display is
	port(
		mClk					: in std_logic;
		dispClk				: in std_logic;
		phi2					: in std_logic;
		n_wr 					: in std_logic;
		reset					: in std_logic;		
		cs						: in std_logic;
		intr					: out std_logic;
		refresh				: out std_logic;
		dma					: out std_logic;
		dmaData				: in std_logic_vector (15 downto 0);
		dataIn				: in std_logic_vector (7 downto 0);
		dataOut				: out std_logic_vector (7 downto 0);
		ioaddr				: in	std_logic_vector (10 downto 0);
		dmaAddr				: out std_logic_vector (23 downto 0);
		sync					: out std_logic;
		video					: out std_logic_vector(8 downto 0);
		palCs					: in std_logic;
		spritePaletteCS	: in std_logic;
		charDataCS			: in std_logic;
		dmaAck				: in std_logic
	);
end Display;


architecture rtl of Display is

	type t_dmaState is (DMACLOCK, DMAWAIT, REFRESHWAIT); 

	-- one sprite_line is 16x8bit = 16 Byte
	--type t_sprite is array (15 downto 0) of std_logic_vector (7 downto 0); 
	type t_xPos is array (0 to 7) of std_logic_vector (9 downto 0); 
	type t_spriteData is array (0 to 7) of std_logic_vector (8 downto 0); 
	type t_spriteAddr is array (0 to 7) of std_logic_vector (4 downto 0);
	type t_spriteWren is array (0 to 7) of std_logic;
	type t_spriteDMAAddr is array (0 to 7) of std_logic_vector (23 downto 0);
	
	-- we have 64 registers for controls of dispplay device
	type t_regs is array (47 downto 0) of std_logic_vector (7 downto 0);
	
	signal dmaState					: t_dmaState;
	signal ioaddr6						: std_logic_vector (5 downto 0);
	signal pixelCnt					: std_logic_vector (9 downto 0);
	signal pixelCntDelay1			: std_logic_vector (2 downto 0);
	signal pixelCntDelay2			: std_logic_vector (2 downto 0);
	signal pixelCntDelay3			: std_logic_vector (2 downto 0);
	signal pixelCntDelay4			: std_logic_vector (2 downto 0);
	signal pixelCntDelay5			: std_logic_vector (2 downto 0);
	signal pixelCntDelay6			: std_logic_vector (2 downto 0);
	signal busCnt						: std_logic_vector (9 downto 0);
	signal screenAddr					: std_logic_vector (23 downto 0);
	signal colorAddr					: std_logic_vector (23 downto 0);
	signal spriteAddr					: t_spriteDMAAddr;
	
	signal hsync						: std_logic;
	signal vsync						: std_logic;

	signal vcount_int					: std_logic_vector (8 downto 0);
	signal status_int					: std_logic_vector (7 downto 0);
	
	signal wrenline					: std_logic;
	signal wrenColorRam				: std_logic;
	signal rdenline					: std_logic;
	
	
	signal dispClkCnt					: std_logic_vector (2 downto 0);
	signal lineramDataOut			: std_logic_vector (7 downto 0);
	signal colorRamDataOut			: std_logic_vector (7 downto 0);
	signal lineAdr						: std_logic_vector (7 downto 0);
	signal colorAdr					: std_logic_vector (5 downto 0);
	signal lineAdrRead				: std_logic_vector (8 downto 0);
	signal colorAdrRead				: std_logic_vector (6 downto 0);
	signal video_int					: std_logic_vector (8 downto 0);
			 
	signal fontLine					: std_logic_vector (2 downto 0);
 
	signal dispAddr					: std_logic_vector (15 downto 0);
	 
	signal paletteAddrA				: std_logic_vector (8 downto 0);
	signal paletteAddrB				: std_logic_vector (7 downto 0);
	signal paletteDataA				: std_logic_vector (7 downto 0);
	signal paletteDataB				: std_logic_vector (15 downto 0);
	signal paletteWrenA				: std_logic;
	signal paletteWrenB				: std_logic;
	signal paletteQA					: std_logic_vector (7 downto 0);
	signal paletteQB					: std_logic_vector (15 downto 0);

	signal spritePaletteAddrA		: std_logic_vector (4 downto 0);
	signal spritePaletteAddrB		: std_logic_vector (3 downto 0);
	signal spritePaletteDataA		: std_logic_vector (7 downto 0);
	signal spritePaletteDatab		: std_logic_vector (15 downto 0);
	signal spritePaletteWrenA		: std_logic;
	signal spritePaletteWrenB		: std_logic;
	signal spritePaletteQA			: std_logic_vector (7 downto 0);
	signal spritePaletteQB			: std_logic_vector (15 downto 0);
	
	signal spriteWren					: t_spriteWren;
	signal spriteAddrA				: t_spriteAddr;
	signal spriteAddrB				: t_spriteAddr;
	signal spriteDataIn				: std_logic_vector (15 downto 0);
	signal spriteDataOut				: t_spriteData;
--	signal spriteData					: std_logic_vector (8 downto 0);
	signal spriteDataArray			: t_spriteData;
	
	signal fontAddrA					: std_logic_vector (10 downto 0);
	signal fontAddrB					: std_logic_vector (10 downto 0);
	signal fontDataA					: std_logic_vector (7 downto 0);
	signal fontDataB					: std_logic_vector (7 downto 0);
	signal fontDataQA					: std_logic_vector (7 downto 0);
	signal fontDataQB					: std_logic_vector (7 downto 0);
	signal fontWrenA					: std_logic;

	signal dispRegDataOut			: std_logic_vector (7 downto 0);
	signal dispRegWren				: std_logic;
	
	signal screenDma					: std_logic;
	signal spriteDma					: std_logic;
	signal soundDma					: std_logic;
	
	signal spriteNo					: integer ;
	signal wordNo						: std_logic_vector (2 downto 0);
	signal spriteNoBus				: integer ;
	signal wordNoBus					: std_logic_vector (2 downto 0);
	
	signal displayRegs				: t_regs;
	signal getSpriteColors			: std_logic := '0';
	signal vVisible					: std_logic;
	signal hVisible					: std_logic;
	signal paletteTemp				: std_logic_vector(8 downto 0);
	signal colorfetch					: std_logic;
	
	
	constant speed						: real := 15000000.0;	-- 960 pixel per line
	constant tline						: real := 0.0000640;		-- one line = 64uS
	
	constant tfront					: real := 0.0000016;
	constant thsync					: real := 0.0000047;
	constant tback						: real := 0.0000057;	
--														 ----------
--																 12uS  	-- 180 pixel
--														 ==========
	
	constant FRONT_PORCH_END		: integer := natural(ceil(speed * tfront));							-- 1,6uS (24px)
	constant HSYNC_END 				: integer := FRONT_PORCH_END + natural(ceil(speed * thsync));	-- 4,7uS	(71px)
	constant BACK_PORCH_END 		: integer := HSYNC_END + natural(floor(speed * tback)); 			--	5,7uS (85px) = 180px

	
	constant TOP_PORCH_END 			: integer := 0;
	constant	VSYNC_END				: integer := TOP_PORCH_END + 8;
	constant	BOTTOM_PORCH_END		: integer := VSYNC_END + 52 + 8;
	
	constant PIXELPERLINE			: integer := natural(ceil(speed * tline));							-- 64uS 		(960px)
	constant PIXELPERLINE_DISP		: integer := 640;																-- 42.66 uS (640px)
	constant LINES_DISP				: integer := 200;
	constant BORDERWIDTH				: integer := (PIXELPERLINE - PIXELPERLINE_DISP - BACK_PORCH_END) / 2; -- (960 - 640 - 180) / 2 = 70px
	
	
	constant MAX_CHARLINE			: integer := 7; -- std_logic_vector (3 downto 0) := "0111";
	
	constant colorBorderLo			: integer := 0;
	constant colorBorderHi			: integer := 1;
	constant colorBackgroundLo		: integer := 2;
	constant colorBackgroundHi		: integer := 3;
	constant color00Lo				: integer := 4;
	constant color00Hi				: integer := 5;
	constant screenBaseLo			: integer := 6;
	constant	screenBaseHi			: integer := 7;
	constant	screenBaseBank			: integer := 8;
	constant control					: integer := 9;
	constant cursorLo					: integer := 10;					
	constant cursorHi					: integer := 11;					
	constant rasterLo					: integer := 12;					
	constant rasterHi					: integer := 13;					
	constant status					: integer := 14;					
	constant vcountLo					: integer := 15;	
	constant vcountHi					: integer := 16;
	--constant spriteBaseLo			: integer := 17;			
	--constant spriteBaseHi			: integer := 18;			
	constant spriteBaseBank			: integer := 19;			
	constant spriteCntl				: integer := 20;
	constant sprite0addr				: integer := 21;
	constant sprite1addr				: integer := 22;
	constant sprite2addr				: integer := 23;
	constant sprite3addr				: integer := 24;
	constant sprite4addr				: integer := 25;
	constant sprite5addr				: integer := 26;
	constant sprite6addr				: integer := 27;
	constant sprite7addr				: integer := 28;
	
	constant xpos0						: integer := 32;
	constant xpos1						: integer := 33;
	constant xpos2						: integer := 34;
	constant xpos3						: integer := 35;
	constant xpos4						: integer := 36;
	constant xpos5						: integer := 37;
	constant xpos6						: integer := 38;
	constant xpos7						: integer := 39;
	constant xposHi					: integer := 40;
		
/*
	711,11 bus cycles per line
	visible screeen starts at 250px, ca. 185 bus cycles
	
	control:
	;Bit 0 - 0: Text 640x200, 1: HiRes 640x200
	;Bit 1 - 0: see above, 1: LoRes 320x200 8/9 bit color-depth
	;Bit 2 - 0: cursor off, 1: cursor on
	;Bit 3 - n/a
	;Bit 4 - 0: rasterIRQ off, 1: rasterIRQ on
*/

begin

	palette: entity work.palette
	port map
	(
		address_a	=> paletteAddrA,
		address_b	=>	paletteAddrB,
		clock_a		=> mClk,
		clock_b		=> dispClk,
	   data_a		=> paletteDataA,
	   data_b		=> paletteDataB,
	   wren_a		=> paletteWrenA,
	   wren_b		=> paletteWrenB,
	   q_a			=> paletteQA,
	   q_b			=> paletteQB
	);
	
	spritePalette: entity work.spritePalette
	port map
	(
		address_a	=> spritePaletteAddrA,
		address_b	=>	spritePaletteAddrB,
		clock_a		=> mClk,
		clock_b		=> mClk,
	   data_a		=> spritePaletteDataA,
	   data_b		=> spritePaletteDataB,
	   wren_a		=> spritePaletteWrenA,
	   wren_b		=> spritePaletteWrenB,
	   q_a			=> spritePaletteQA,
	   q_b			=> spritePaletteQB
	);


	lineRam: entity work.lineram
	port map
	(	
		data			=> dmaData,
		wraddress	=> lineAdr,
		wrclock		=> mClk,
		wren			=> wrenline,
		wrclocken	=> '1',
		
		rdaddress	=> lineAdrRead,
		rdclock		=> dispClk,
		q				=> lineramDataOut,
		rdclocken	=> '1'
		
	);

	colorRam: entity work.colorRam
	port map
	(
		data			=> dmaData,
		wraddress	=> colorAdr,
		wrclock		=> mClk,
		wren			=> wrenColorRam,
		
		rdaddress	=> colorAdrRead,
		rdclock		=> dispClk,
		q				=> colorRamDataOut
	);
	
	fontRam: entity work.fontRam
	port map
	(
		address_a	=> fontAddrA,
		address_b	=> fontAddrB,
		clock_a		=> mClk,
		clock_b		=> dispClk,
		data_a		=>	fontDataA,
		data_b		=> fontDataB,
		wren_a		=> fontWrenA,
		wren_b		=> '0',
		q_a			=> fontDataQA,
		q_b			=> fontDataQB
	);

	intr		<= '1';
	
	ioaddr6 <= ioaddr(5 downto 0);
	
	paletteAddrA <= ioaddr(8 downto 0);
	spritePaletteAddrA <= ioaddr(4 downto 0);
	fontAddrA <= ioaddr;
	
	paletteDataA <= dataIn;
	spritePaletteDataA <= dataIn;
	fontDataA <= dataIn;
	
	paletteWrenB <= '0';
	spritePaletteWrenB <= '0';	
	
	
	hsync <= '0' when pixelCnt >= FRONT_PORCH_END and pixelCnt < HSYNC_END else '1';
	vsync <= '0' when vcount_int < VSYNC_END else '1';	
	sync	<= hsync and vsync;
	
	-- output internal video data	
	process (all)
	begin
		for i in 0 to 8 loop 
			if video_int(i) = '1' then
				video(i) <= '1';
			else
				video(i) <= 'Z';
			end if;
		end loop;	
	end process;
	
	
	
	-- count pixel per line
	-- generate horizontal and vertical counts
	process (all)
	begin
		if rising_edge(dispClk) then
			
			dispClkCnt <= dispClkCnt + 1;
			
			
			pixelCnt <= pixelCnt + 1;

			if pixelCnt >= PIXELPERLINE-1 then
				pixelCnt <= (others => '0');
				vcount_int <= vcount_int + 1;
							
				if vcount_int >= 312-1 then
					vcount_int <= (others => '0');
				end if;					
			end if;
		end if;
	end process;	
	
	
	process (all)
		variable pix : std_logic;
		variable vBorderw : integer;
	begin
		if displayRegs(control)(1) = '1' then
			vBorderw := BORDERWIDTH;
		else
			vBorderw := BORDERWIDTH + 1;
		end if;
		
		if rising_edge(dispClk) then
		
			
			if reset = '1' or (cs = '1' and n_wr = '0' and to_integer(unsigned(ioaddr6)) = status) then
				status_int <= (others => '0');
			end if;
			
			--
			-- flag raster interrupt if control(4) = 1
			--
			if     displayRegs(control)(4) 	= '1'
				and vcount_int(7 downto 0) 	= displayRegs(rasterLo)
				and vcount_int(8) 				= displayRegs(rasterHi)(0)
				and pixelCnt = BACK_PORCH_END + BORDERWIDTH + PIXELPERLINE_DISP then
				
				status_int(7) <= '1';
			end if;

			if pixelCnt = 0 then
				fontLine <= fontline + 1;
				--if fontline = 7 then
				--	fontline <= (others => '0');
				--end if;
				

				lineAdrRead <= (others => '0');
				colorAdrRead <= (others => '0');
				
				-- if character is vertically finished, do not reset dispAddr 
				if fontline /= 7 and vcount_int >= BOTTOM_PORCH_END then
					dispAddr <= dispAddr - 80;
				end if;		
					
				if vcount_int = 0 then
					fontLine <= "100";
					dispAddr <= (others => '0');
				end if;
			end if;
				
			if pixelCnt >= BACK_PORCH_END + BORDERWIDTH - 5 then				
				
				-- in HiRes read 1 byte per 8 pixel
				-- in LoRes read 1 byte per pixel 
				if 	(pixelCnt (2 downto 0) = 2 /*displayRegs(colorBackgroundLo)(2 downto 0) */ and displayRegs(control)(1) = '0')
					or	(displayRegs(control)(1) = '1' and pixelCnt(0) = '0') then
					lineAdrRead <= lineAdrRead + 1;
				end if;
				if 	pixelCnt (2 downto 0) = 5 and lineAdrRead /= 0 then
					colorAdrRead <= colorAdrRead + 1;
				end if;

				fontAddrB <= lineramDataOut & fontLine;
								
				if displayRegs(control)(0) = '0' then
					pix := fontDataQB(to_integer(unsigned(not pixelCnt(2 downto 0))));
				else
					pix := lineramDataOut(to_integer(unsigned(not pixelCnt(2 downto 0))));
				end if;
				if dispAddr = displayRegs(cursorHi) & displayRegs(cursorLo) then
					pix := pix xor displayRegs(control)(2);
				end if;
				
				if displayRegs(control)(1) = '0' then		-- text mode
					if displayRegs(control)(3) = '0' then	-- monochrome
						if pix = '1' then
							paletteAddrB <= "11111111";
						else
							paletteAddrB <= "00000000";
						end if;
					else
						if pix = '1' then
							paletteAddrB <= "0000" & colorRamDataOut(3 downto 0);
						else
							paletteAddrB <= "0000" & colorRamDataOut(7 downto 4);
						end if;
					end if;					
				else
					paletteAddrB <= lineramDataOut;
				end if;
			end if;		


			--paletteTemp <= paletteQB(8 downto 0);
			
			if pixelCnt < BACK_PORCH_END or vcount_int < VSYNC_END then
				video_int <= (others => '0');
			elsif			pixelCnt >= BACK_PORCH_END + vBorderw 
					and 	pixelCnt  < BACK_PORCH_END + vBorderw + PIXELPERLINE_DISP 
					and 	vcount_int >= BOTTOM_PORCH_END 
					and 	vcount_int <  BOTTOM_PORCH_END + LINES_DISP then
					
					video_int <= paletteQB(8 downto 0);
					
					if displayRegs(control)(0) = '0' then				-- advance cursor-address if text-mode			
						if pixelCnt(2 downto 0) = 7 then
							dispAddr <= dispAddr + 1;
						end if;					
					end if;					
			
			else
				video_int <= displayRegs(colorBorderHi)(0) & displayRegs(colorBorderLo);
			end if;

		
		end if;
	end process;
	
	
	process (all)
	begin
		if rising_edge(mClk) then
		
			paletteWrenA <= '0';
			spritePaletteWrenA <= '0';
			fontWrenA <= '0';

			if reset = '1' then

				displayRegs(colorBorderLo)			<= "00011100";	-- 0		
				displayRegs(colorBorderHi)			<= "00000000";	-- 1
				
				displayRegs(colorBackgroundLo)	<= "00000010";	-- 2
				--displayRegs(colorBackgroundHi)	<= "00000000";	-- 3
				
				--displayRegs(color00Lo)				<= "11111111";	-- 4	
				--displayRegs(color00Hi)				<= "00000001"; -- 5
				
				displayRegs(screenBaseLo)			<= x"00";		-- 6, 00	* 2 = 7F:F800
				displayRegs(screenBaseHi)			<= x"F8";		-- 7, FC
				displayRegs(screenBaseBank)		<= x"3F";		-- 8, 3f
					
				displayRegs(control)					<= "00000100";	-- 9, Cursor on
					
				displayRegs(cursorLo)				<= x"00";		--10
				displayRegs(cursorHi)				<= x"00";		--11
					
				displayRegs(rasterLo)				<= x"00";		--12
				displayRegs(rasterHi)				<= x"00";		--13
			
				--displayRegs(spriteBaseLo)			<= x"00";		--17
		      --displayRegs(spriteBaseHi)			<= x"00";		--18
		      displayRegs(spriteBaseBank)		<= x"3F";		--19, 7E0000 >> 1 = 3F0000
					
				displayRegs(spriteCntl)				<= x"03";		--20
				
		      displayRegs(xpos0)					<= x"80";--		x"80";
		      displayRegs(xpos1)					<= x"A0";--		x"a0";
		      displayRegs(xpos2)					<= x"00";--		x"c0";
		      displayRegs(xpos3)					<= x"00";--		x"e0";
		      displayRegs(xpos4)					<= x"00";--		x"00";
		      displayRegs(xpos5)					<= x"00";--		x"20";
		      displayRegs(xpos6)					<= x"00";--		x"40";
		      displayRegs(xpos7)					<= x"00";--		x"60";
				displayRegs(xposHi)					<= x"00";
				
				displayRegs(sprite0addr)			<= x"00";
				displayRegs(sprite1addr)			<= x"08";
				displayRegs(sprite2addr)			<= x"10";
				displayRegs(sprite3addr)			<= x"18";
				displayRegs(sprite4addr)			<= x"20";
				displayRegs(sprite5addr)			<= x"28";
				displayRegs(sprite6addr)			<= x"30";
				displayRegs(sprite7addr)			<= x"38";
				
				displayRegs(status)					<= x"00";
			else
				if phi2 = '1' then
					if n_wr = '0' then
						if cs = '1' then
							displayRegs(to_integer(unsigned(ioaddr6))) <= dataIn;		
						end if;
						if palCs = '1' then
							paletteWrenA <= '1';
						end if;
						if spritePaletteCS = '1' then
							spritePaletteWrenA <= '1';
						end if;
						if charDataCS = '1' then
							fontWrenA <= '1';
						end if;
					end if;
				else
					displayRegs(status)					<= status_int;
					displayRegs(vcountLo)				<= vcount_int(7 downto 0);
					displayRegs(vcountHi)				<= "0000000" & vcount_int(8);				
				end if;
				
				if n_wr = '1' then
					 
					if palCs = '1' then
						dataOut <= paletteQA;
					end if;
					if spritePaletteCS = '1' then
						dataOut <= spritePaletteQA;
					end if;
					if charDataCS = '1' then
						dataOut <= fontDataQA;
					end if;
					if cs = '1' then
						dataOut <= displayRegs(to_integer(unsigned(ioaddr6)));
					end if;						
				end if;
					
			end if;
				
		end if;							
	end process;
	
	
	mClkP: process (all)
		variable vFetch			: integer;
		variable vColorfetch	: integer;
	begin

		vColorfetch := 0;
		if displayRegs(control)(1) = '0'	then
			vFetch := 40;										-- fetch 2*40 bytes for text mode
			if displayRegs(control)(3) = '1' then
				vColorfetch := 80;							-- fetch addditional 2*40 bytes for text color
			end if;
		else
			vFetch := 160;										-- fetch 2*160 = 320 bytes for grahics
		end if;
				

		if rising_edge(mClk) then
			
			/*
			if reset = '1' then
				dmaState <= DMACLOCK;
				dma		<= '0';
			end if;
			*/
			
			wrenline <= '0';	
			wrenColorRam <= '0';
			
			vVisible <= '0';
			if vcount_int >= BOTTOM_PORCH_END and
				vcount_int <  BOTTOM_PORCH_END + LINES_DISP then
				vVisible <= '1';
			end if;
				
		
			if pixelCnt = 0 then
				spriteNo			<= 0;
				spriteNoBus		<= 0;
				wordNo			<= (others => '0');	
				wordNoBus		<= (others => '0');			
				busCnt			<= (others => '0');
				for i in 0 to 7 loop
					spriteAddrA(i)	<= (others => '1');
				end loop;
				
				lineAdr			<= (others => '1');
				colorAdr			<= (others => '1');
			
				if vcount_int = 0 then
				
					for i in 0 to 7 loop
						spriteAddr(i) <=	displayRegs(spriteBaseBank) & displayRegs(sprite0addr + i) & x"00";
					end loop;
					
					screenAddr <=	displayRegs(screenBaseBank) & 
										displayRegs(screenBaseHi) &
										displayRegs(screenBaseLo);
										
					colorAddr <= displayRegs(screenBaseBank) & 
									((displayRegs(screenBaseHi) & displayRegs(screenBaseLo)) + x"0400");
										
				end if;
			end if;
			
			case dmaState is
			when DMACLOCK =>
				/*
				if pixelCnt = 0 then
					spriteNo			<= 0;
					spriteNoBus		<= 0;
					wordNo			<= (others => '0');	
					wordNoBus		<= (others => '0');			
					busCnt			<= (others => '0');
					
					for i in 0 to 7 loop
						spriteAddrA(i)	<= (others => '1');
					end loop;
					
					lineAdr			<= (others => '1');
				
					if vcount_int = 0 then
					
						for i in 0 to 7 loop
							spriteAddr(i) <=	displayRegs(spriteBaseBank) & displayRegs(sprite0addr + i) & x"00";
						end loop;
						
						screenAddr <=	displayRegs(screenBaseBank) & 
											displayRegs(screenBaseHi) &
											displayRegs(screenBaseLo);
											
					end if;
					*/
				if busCnt < 5 then
						dmaState <= REFRESHWAIT;	
						refresh <= '1';
				elsif busCnt  < vFetch+5 and vVisible = '1' 
						and (   (fontline = "000" and displayRegs(control)(1 downto 0) = "00")
						     or (displayRegs(control)(0) = '1' or displayRegs(control)(1) = '1') ) then
						
						dma <= '1';
						dmaAddr <= screenAddr;	
						dmaState <= DMAWAIT;	
						colorfetch <= '0';		
				elsif busCnt < vColorfetch+5 and vVisible = '1'
						and fontline = "000" and displayRegs(control)(3) = '1' and displayRegs(control)(1 downto 0) = "00" then
						dma <= '1';
						dmaAddr <= colorAddr;	
						dmaState <= DMAWAIT;	
						colorfetch <= '1';
				end if;
			when REFRESHWAIT =>
				if dmaAck = '1' then
					refresh <= '0';
					dmaState <= DMACLOCK;
					busCnt <= busCnt + 1;
				end if;
			when others =>
				if dmaAck = '1' then
					dmaState <= DMACLOCK;
					dma <= '0';
					if colorfetch = '0' then
						wrenline <= '1';
						lineAdr <= lineAdr + 1;
						screenAddr <= screenAddr + 1;
					else
						wrenColorRam <= '1';
						colorAdr <= colorAdr + 1;
						colorAddr <= colorAddr + 1;						
					end if;
					
					busCnt <= busCnt + 1;
				end if;
			end case;
			 
/*			
				busCnt <= busCnt + 1;
								
				dma			<= '0';
				screenDma	<= '0';
				spriteDma	<= '0';
				refresh		<= '0';	
					
				if screenDma = '1' then
					wrenline <= '1';
					lineAdr <= lineAdr + 1;
				elsif spriteDma = '1' then
					getSpriteColors <= '1';
					spritePaletteAddrB <= dmaData(7 downto 4);
				end if;
	
				if busCnt < 5 then 
					refresh		<= '1';
				else
					if 	 vcount_int >= BOTTOM_PORCH_END 
						and vcount_int <  BOTTOM_PORCH_END + LINES_DISP then

						--
						-- read 8 words per sprite, 8 sprites
						--
						if busCnt >= 5 and busCnt < 5+(8*8) then
						
							wordNoBus <= wordNoBus + 1;
							spriteDma <= '1';
							if wordNoBus = 7 then
								spriteNoBus <= spriteNoBus + 1;
							end if;
							if displayRegs(spriteCntl)(spriteNoBus) = '1' then
								dma <= '1';
								dmaAddr <= spriteAddr(spriteNoBus);
							end if;
							spriteAddr(spriteNoBus) <= spriteAddr(spriteNoBus) + 1;
						
						elsif	 busCnt >= 70 
							and busCnt  < 70 + fetch
							and (   (fontLine = "000" and displayRegs(control)(1 downto 0) = "00") 
								   or displayRegs(control)(0) = '1' or displayRegs(control)(1) = '1') then
						
							screenAddr <= screenAddr + 1;
							dma <= '1';
							screenDma <= '1';
							dmaAddr <= screenAddr;						
						end if;
						
					end if;	
				end if;		
	*/			
			
			
/*				
			if getSpriteColors = '1' then
					
				if mclkCnt <= 3 then
					spriteDataIn <= spritePaletteQB;
					spriteAddrA(spriteNo) <= spriteAddrA(spriteNo) + 1;
					spriteWren(spriteNo) <= '1';
				end if;
				
				if mclkCnt = 8 then								
					spritePaletteAddrB <= dmaData(3 downto 0);
				elsif mclkCnt = 0 then					
					spritePaletteAddrB <= dmaData(15 downto 12);
				elsif mclkCnt = 1 then					
					spritePaletteAddrB <= dmaData(11 downto 8);
				elsif mclkCnt = 4 then					
					getSpriteColors <= '0';	
					wordNo <= wordNo + 1;
					if wordNo = 7 then
						spriteNo <= spriteNo + 1;
					end if;
					for i in 0 to 7 loop 
						spriteWren(i) <= '0';
					end loop;
					
				end if;
			end if;
*/		
		
		end if;	--rising_edge(mClk)
	end process;
	
end;
