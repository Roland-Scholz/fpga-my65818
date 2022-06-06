
library ieee;
use ieee.std_logic_1164.all;
--use IEEE.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
use ieee.numeric_std.all;


entity RS65816 is
	port(
		seg7			: out std_logic_vector (7 downto 0);
		seg7_digit	: out std_logic_vector (3 downto 0);
		led1			: out std_logic;
		led2			: out std_logic;
		led3			: out std_logic;
		led4			: out std_logic;
		
		TXD0			: out std_logic;		-- Uart	Txd
		RXD0			: in std_logic;		-- Uart	Rxd
		RXD1			: in std_logic;		-- Mouse	Rxd
		
		reset_in		: in std_logic;
		clk			: in std_logic;
		key1			: in std_logic;
		key2			: in std_logic;
		
		sync			: out std_logic;
		video			: out std_logic_vector(8 downto 0);
		
		sdram_a		: out unsigned(11 downto 0);
		sdram_ba		: out unsigned (1 downto 0);
		sdram_dq		: inout std_logic_vector (15 downto 0);
		sdram_clk	: out std_logic;
		sdram_cke	: out std_logic;
		sdram_cs_n	: out std_logic;
		sdram_ras_n	: out std_logic;
		sdram_cas_n	: out std_logic;
		sdram_we_n	: out std_logic;
		sdram_mldq	: out std_logic;
		sdram_mhdq	: out std_logic;

		SDmiso		: in std_logic;
		SDsclk		: out std_logic;
		SDss			: out STD_LOGIC_VECTOR(0 DOWNTO 0);
		SDmosi		: out std_logic;
		
		ps2Clk		: in std_logic;
		ps2Data		: in std_logic
		--testClk		: out std_logic
	);
	
end RS65816;

architecture struct of RS65816 is

	type t_cpuState is (CPUCLOCK, CPUWORK, CPUDECODE, CPUIO, CPUIO1, CPUIO2); 
	type t_sdramState is (RAMIDLE, RAMACCESS, RAMWAIT, DMAACCESS, REFRESHACC); 
	
	signal cpuState			: t_cpuState;
	signal ramState			: t_sdramState;
	signal VPA					: std_logic;
	signal VDA					: std_logic;
	
	signal dramDMALatch		: std_logic_vector(15 downto 0);
	signal dmaAddress			: std_logic_vector(23 downto 0);	
	signal cpuAddress			: std_logic_vector(23 downto 0);
	signal oddAddress			: std_logic_vector(23 downto 0);
	signal oddData				: std_logic_vector( 7 downto 0);
	signal cpuDataIn			: std_logic_vector( 7 downto 0);
	signal cpuDataInDebug	: std_logic_vector( 7 downto 0);
	signal cpuDataOut			: std_logic_vector( 7 downto 0);
	signal sysramData			: std_logic_vector( 7 downto 0);
	signal kernelRomData 	: std_logic_vector( 7 downto 0);
	signal myosRomData 		: std_logic_vector( 7 downto 0);
	signal acia0Data			: std_logic_vector( 7 downto 0);
	signal acia1Data			: std_logic_vector( 7 downto 0);
	signal dispRegData 		: std_logic_vector( 7 downto 0);
	signal debReg				: std_logic_vector(23 downto 0);
	signal debDatIn			: std_logic_vector( 7 downto 0);
	signal spiData				: std_logic_vector( 7 downto 0);
	signal ps2kbdData			: std_logic_vector( 7 downto 0);
	signal timer				: std_logic_vector(15 downto 0);
	signal timerCnt			: std_logic_vector(15 downto 0);
	signal timerStatus		: std_logic_vector( 7 downto 0);
	signal specialData		: std_LOGIC_VECTOR( 7 downto 0);
	signal mClock				: std_LOGIC_VECTOR(31 downto 0);
	signal cpuTicks			: std_LOGIC_VECTOR(31 downto 0);
	
	signal cpuRW				: std_logic;
	signal BaudOut0			: std_logic;
	signal reset				: std_logic;
	signal ioClock				: std_logic;

	signal CSkernelROM		: std_logic;
	signal CSmyosROM			: std_logic;
	signal CSsysram			: std_logic;
	signal CSacia0				: std_logic;
	signal CSacia1				: std_logic;
	signal CSsdram				: std_logic;
	signal CSdisplay			: std_logic;
	signal CSSpi				: std_logic;
	signal CSps2kbd			: std_logic;
	signal CSspecial			: std_logic;
	signal CSpalette			: std_logic;
	signal CSspritePalette	: std_logic;
	signal CScharData			: std_logic;
	

	signal mClkCnt				: unsigned(3 downto 0);
		
	signal led1_int			: std_logic;
	signal resClock			: integer := 0;
	signal testClock			: integer := 0;
	
	signal addrEna				: std_logic := '0';
	signal hexEna				: std_logic := '0';
	signal segEna				: std_logic := '0';
	signal seg7adr				: std_logic_vector(1 downto 0);
	signal seg7data			: std_logic_vector(7 downto 0);
	signal seg7adr24			: std_logic_vector(23 downto 0);
	signal slow					: std_logic := '0';
	signal slowPrg				: std_logic;
	signal slowCounter		: integer := 0;
	
	signal key1_int			: std_logic;
	signal key1count			: integer := 0;
	signal key2_int			: std_logic;
	signal key2count			: integer := 0;

	
	signal sdramValid			: std_logic;
	signal sdramDone			: std_logic;
	signal sdramDataOut		: std_logic_vector(15 downto 0);
	signal sdramDataIn		: std_logic_vector(15 downto 0);
	signal sdramAddr			: std_logic_vector(21 downto 0);
	signal sdramReq			: std_logic;
	signal clk100M				: std_logic;
	signal sdramWE				: std_logic;
	signal sdramMldq			: std_logic;
	signal sdramMhdq			: std_logic;
	
	signal dma					: std_logic := '0';
	signal refresh				: std_logic := '0';
	signal refreshReq			: std_logic := '0';
	signal dispClk				: std_logic;
	
	signal latch				: std_logic_vector(2 downto 0);
	signal stop					: std_logic;
	
	signal n_irq_ps2kbd		: std_logic;
	signal n_irq_disp			: std_logic;
	signal softReset			: std_logic := '0';
	signal reset_in_int		: std_logic := '1';
	signal clockTick			: std_logic;
	signal timerIRQ			: std_logic;
	signal acia1IRQ			: std_logic;
	
	signal cpuReady			: std_logic;
	signal cpuMemReq			: std_logic;
	signal cpuMemAck			: std_logic;
	signal dmaAck				: std_logic;
	
	signal dramCnt				: std_logic_vector (7 downto 0);
	signal pFlags				: std_logic_vector (7 downto 0);
	signal operator			: std_logic_vector (7 downto 0);
	signal dramCntMax			: std_logic_vector (7 downto 0) := x"00";
	signal cpuSlow				: std_logic;
	signal debugData			: std_logic_vector (15 downto 0);

	constant io					: std_logic_vector(11 downto 0) := x"FFF";			-- FF:F000 - FF:FFFF
	constant DELAY				: integer := 100000000;
	-- FF:F
begin
		

	process (all)
	begin 
		if rising_edge(clk100M) then
		
			cpuMemAck	<= '0';
			dmaAck		<= '0';
			
			if reset = '1' then
				sdramReq		<= '0';
				ramState		<= RAMIDLE;
			else				
				case ramState is
				when RAMIDLE =>
					if refresh	= '1' then
							refreshReq	<= '1';
							ramState		<= REFRESHACC;
					elsif dma = '1' then
							sdramAddr	<= dmaAddress(21 downto 0);
							sdramWE		<= '0';
							--sdramDataIn <=	cpuDataOut & cpuDataOut;
							sdramMldq	<= '0';
							sdramMhdq	<= '0';
							sdramReq		<= '1';
							ramState		<= DMAACCESS;	
					elsif cpuMemReq = '1' then
							sdramAddr	<= cpuAddress(22 downto 1);
							sdramWE		<= not cpuRW;
							sdramDataIn <=	cpuDataOut & cpuDataOut;
							if cpuRW = '1' then
								sdramMldq	<= '1';
								sdramMhdq	<= '1';
							else
								sdramMldq	<= cpuAddress(0);
								sdramMhdq	<= not cpuAddress(0);
							end if;
							sdramReq		<= '1';
							ramState		<= RAMACCESS;
					end if;
				when REFRESHACC =>
					if sdramDone = '1' then
						ramState		<= RAMWAIT;
						dmaAck		<= '1';
						refreshReq	<= '0';
					end if;
				when RAMACCESS =>
					if sdramDone = '1' then
						sdramReq		<= '0';
						ramState		<= RAMWAIT;
						cpuMemAck	<= '1';
						dramDMALatch <= sdramDataOut;
						if cpuRW = '1' then
							if cpuAddress(0) = '0' then
								oddAddress <= "0" & cpuAddress(22 downto 1) & "1";
								oddData <= sdramDataOut(15 downto 8);
							end if;
						else
							if cpuAddress = oddAddress then
								oddData	<= cpuDataOut;
							end if;
						end if;						
					end if;
						
				when DMAACCESS	=>
					if sdramDone = '1' then
						sdramReq		<= '0';
						ramState		<= RAMWAIT;
						dmaAck		<= '1';
						dramDMALatch <= sdramDataOut;	
					end if;
				when RAMWAIT =>
						ramState		<= RAMIDLE;				
				when others =>
					null;
				end case;
				
			end if;
		end if;
	end process;
	
	process (all)
	begin 
		
		led1 <= cpuRW;
		led2 <= timerIRQ;
		led3 <= '1';
		led4 <= '1';

		addrEna <= '1';

						
		if rising_edge(clk100M) then
			if reset = '1' then
				cpuState		<= CPUCLOCK;
				cpuMemReq	<= '0';
				slow			<= '0';
			else
				cpuReady		<= '0';
				ioClock		<= '0';
				
				
				--slow <= not cpuRW and CSmyosROM and ioClock;
				
				case cpuState is
				
				when CPUCLOCK =>
											
					if CSkernelROM	= '1' then
						cpuDataIn <= kernelRomData;
					elsif CSmyosROM	= '1' then
						cpuDataIn <= myosRomData;
					elsif CSsysram	= '1' then
						cpuDataIn <= sysramData;
					elsif CSacia0	= '1' then
						cpuDataIn <= acia0Data;
					elsif CSacia1	= '1' then
						cpuDataIn <= acia1Data;
					elsif CSspecial	= '1' then
						cpuDataIn <= specialData;
					elsif CSspi	= '1' then
						cpuDataIn <= spiData;
					elsif CSps2kbd	= '1' then
						cpuDataIn <= ps2kbdData;
					elsif CSdisplay = '1' or CSpalette = '1' or CSspritePalette	= '1' or CScharData = '1'then
						cpuDataIn <= dispRegData;
					else 
						cpuDataIn <= x"AA";
					end if;
					
					/*
					if (slow = '1' or cpuSlow = '1' or slowPrg = '1') and testClock < DELAY * 2 then
						testClock <= testClock + 1;
						if testClock < DELAY then
							debugData <= cpuAddress(15 downto 0);
							cpuState <= CPUCLOCK;
						elsif testClock < DELAY * 2 then
							if cpuRW = '1' then
								debugData <= x"00" & cpuDataIn;
							else
								debugData <= x"00" & cpuDataOut;
							end if;
							cpuState <= CPUCLOCK;
						end if;
					else*/
						cpuState <= CPUWORK;
						cpuReady <= '1';
					--end if;

				when CPUWORK =>
					cpuState <= CPUDECODE;
					testClock <= 0;
					
				when CPUDECODE =>
					
					cpuState	<= CPUIO1;
					
					CSacia0 				<= '0';
					CSacia1 				<= '0';
					CSspecial			<= '0';					
					CSsysram				<= '0';
					CSkernelROM 		<= '0';
					CSmyosROM 			<= '0';
					CSsdram				<= '0';
					CSdisplay			<= '0';
					CSpalette			<= '0';
					CSspritePalette	<= '0';
					CScharData			<= '0';
					CSspi					<= '0';
					CSps2kbd				<= '0';
						
					cpuMemReq			<= '0';
					
					if VDA = '0' and VPA = '0' then
						cpuState <= CPUWORK;
						cpuReady <= '1';
					else
											
						if cpuAddress(23 downto 12)		= io then
						
							ioClock				<= '1';

							if cpuAddress(11 downto 4)		= x"F8"				then	-- FF:FF8x
								CSspecial <= '1';
							end if;	 
							if cpuAddress(11 downto 4)		= x"F9"				then	-- FF:FF9x
								CSspi <= '1';			
							end if;
							if cpuAddress(11 downto 4)		= x"FA"				then	-- FF:FFAx
								CSacia1 <= '1';
							end if;
							if cpuAddress(11 downto 4)		= x"FD"				then	-- FF:FFDx
								CSps2kbd <= '1';
							end if;
							if cpuAddress(11 downto 4)		= x"FE"				then	-- FF:FFEx
								CSacia0 <= '1';
							end if;
							if cpuAddress(11 downto 6)		= x"E" & "00"		then	-- FF:FE00-3F
								CSdisplay <= '1';	
							end if;
							if cpuAddress(11 downto 6)		= x"E" & "01"		then	-- FF:FE40-7F
								CSspritePalette <= '1';
							end if;
							if cpuAddress(11 downto 9)		= "110"				then 	-- FF:FC00-FF:FDFF
								CSpalette <= '1';
							end if;							
							if cpuAddress(11)					= '0' 				then 	-- FF:F000-FF:F7FF
								CScharData <= '1';
							end if;
						end if;
						
						if cpuAddress(23) = '0' then
							if cpuAddress(23 downto 13)	= x"00" & "111"		then	-- kernel	00:E000-FFFF
								CSKernelROM <= '1';
							--elsif cpuAddress(23 downto 11) = x"000" & "0"		then	-- sysram 	00:0000-07FF
							--	CSsysram <= '1';
							elsif cpuAddress(23 downto 13)	= x"00" & "110"	then	-- myos		00:C000-DFFF
								CSmyosROM <= '1';
							else
								if cpuRW = '1' and cpuAddress = oddAddress then
									cpuDataIn <= oddData;
									cpuState <= CPUWORK;
									cpuReady <= '1';
								else
									CSsdram		<= '1';
									cpuMemReq	<= '1';
									cpuState		<= CPUIO;
								end if;
							end if;
						end if;
						
					end if;
					
				when CPUIO1 =>
						cpuState		<= CPUIO2;
						
				when CPUIO2 =>
						cpuState		<= CPUCLOCK;
					
				when CPUIO =>
					if cpuMemAck = '1' then
						cpuMemReq	<= '0';
						cpuReady		<= '1';
						cpuState		<= CPUWORK;
						--cpuState		<= CPUCLOCK;
						if cpuAddress(0) = '0' then
							cpuDataIn <= dramDMALatch(7 downto 0);
						else
							cpuDataIn <= dramDMALatch(15 downto 8);
						end if;
					end if;
					
				when others =>
					null;
				end case;		
				
			end if;
		end if;
	end process;
	

	u0: entity work.RS65C816
	port map (
		CLK					=> clk100M, --clk100M, --cpuClock,
		RST_N					=> not reset,
		RDY_IN				=> cpuReady,
		NMI_N					=> '1',  
		IRQ_N					=> timerIRQ and n_irq_ps2kbd and acia1IRQ,
		ABORT_N				=> '1',
		D_IN					=> cpuDataIn,
		D_OUT    			=> cpuDataOut,
		A_OUT					=> cpuAddress,
		WE  					=> cpuRW,
		VPA					=> VPA,
		VDA					=> VDA,
		pFlags				=> pFlags,
		cpuSlow				=> cpuSlow
	);

/*
	u1: entity work.sysram
	port map (
		address		=> cpuAddress(10 downto 0),
		clock			=> clk100M,
		data			=> cpuDataOut,
		wren			=> not cpuRW and CSsysram and ioClock,
		q				=> sysramData
	);
*/

	kernel: entity work.kernel
	port map (
		address		=> cpuAddress(12 downto 0),
		clock			=> clk100M,
		q				=> kernelRomData
	);
	
	myos: entity work.myos
	port map	
	(
		address		=> cpuAddress(12 downto 0),
		clock			=> clk100M,
		q				=> myosRomData
	);

	
	u3: entity work.pll
	port map (
		inclk0		=> clk,				--   50 Mhz in
		c0				=> clk100M,			--  100 Mhz out
		c1				=>	sdram_clk,		--  100 Mhz out -45 degrees
		c2				=> dispClk			--   15 Mhz out, video
	);
	
	
	u4: entity work.Display
	port map(
		mClk 					=> clk100M,
		dispClk				=> dispClk,
		phi2					=> ioClock,
		n_wr 					=> cpuRW,
		reset					=> reset,
		intr					=> n_irq_disp,
		
		refresh				=> refresh,
		dma					=> dma,
		dmaAddr				=> dmaAddress,
		dmaData				=> dramDMALatch,
		dmaAck				=> dmaAck,
		
		ioaddr				=> cpuAddress(10 downto 0),
				
		dataIn				=> cpuDataOut,
		dataOut				=> dispRegData,
				
		cs						=> CSdisplay,
		palCs					=> CSpalette,
		spritePaletteCS	=> CSspritePalette,
		charDataCS			=> CScharData,
		
		sync					=> sync,
		video					=> video

	);
	
	
	u5: entity work.sdram_simple
	port map (
    reset			=> reset,
    -- clock
    clk				=> clk100M,
    -- address bus
    addr				=> unsigned(sdramAddr),
	 
	 dqml				=> sdramMldq,
	 dqmh				=> sdramMhdq,
	 
    -- input data bus
    data				=>	sdramDataIn,
    -- When the write enable signal is asserted, a write operation will be performed.
    we				=>	sdramWE,--'0',--not cpuRW,
    -- When the request signal is asserted, an operation will be performed.
    req				=>	sdramReq,
    -- The acknowledge signal is asserted by the SDRAM controller when
    -- a request has been accepted.
--    ack				=> sdramAck,
    -- The valid signal is asserted when there is a valid word on the output
    -- data bus.
    valid			=>	sdramValid,
	 done_o			=> sdramDone,
    -- output data bus
    q					=> sdramDataOut,
	 refresh			=> refreshReq,
    -- SDRAM interface (e.g. AS4C16M16SA-6TCN, IS42S16400F, etc.)
    sdram_a			=>	sdram_a,
    sdram_ba		=> sdram_ba,	
    sdram_dq		=> sdram_dq,
    sdram_cke		=> sdram_cke,	
    sdram_cs_n		=> sdram_cs_n,	
    sdram_ras_n	=> sdram_ras_n,
    sdram_cas_n	=>	sdram_cas_n, 
    sdram_we_n		=> sdram_we_n,
    sdram_dqml		=> sdram_mldq,	
    sdram_dqmh 	=> sdram_mhdq 
	);	
	
	
	uart:entity work.uart
	generic map (
		CLK_FREQ	=> 100,		-- Main frequency (MHz)
--		SER_FREQ	=> 460800	-- Baud rate (bps)	
--		SER_FREQ	=> 230400	-- Baud rate (bps)	
		SER_FREQ	=> 115200	-- Baud rate (bps)	
	)
	port map (
		-- Control
		clk			=> clk100M,			-- Main clock
		rst			=>	reset,			-- Main reset
		-- External Interface
		rx				=> RXD0,				-- RS232 received serial data
		tx				=> TXD0,				-- RS232 transmitted serial data
		-- uPC Interface
		cs				=> CSacia0 and ioClock,
		rw				=>	cpuRW,
		addr			=> cpuAddress(2 downto 0),
		dataIn		=> cpuDataOut,		-- Data to transmit
		dataOut		=> acia0Data		-- Received data 
	);
	
	
	mouse:entity work.uart
	generic map (
		CLK_FREQ	=> 100,		-- Main frequency (MHz)
		SER_FREQ	=> 1200		-- Baud rate (bps)	
	)
	port map (
		-- Control
		clk			=> clk100M,			-- Main clock
		rst			=>	reset,			-- Main reset
		-- External Interface
		rx				=> RXD1,				-- RS232 received serial data
		--tx				=> TXD0,				-- RS232 transmitted serial data
		-- uPC Interface
		cs				=> CSacia1 and ioClock,
		rw				=>	cpuRW,
		addr			=> cpuAddress(2 downto 0),
		dataIn		=> cpuDataOut,		-- Data to transmit
		dataOut		=> acia1Data,		-- Received data
		intn			=> acia1IRQ	
	);	
	
	
	special:entity work.special
	port map (
		clk			=> clk100M,			-- Main clock
		rst			=>	reset,			-- Main reset
		dataIn		=> cpuDataOut,		-- Data to transmit
		dataOut		=> specialData,	-- Received data 
		cpuAddress	=> cpuAddress,
		cs				=> CSspecial and ioClock,
		rw				=> cpuRW,
		timerIRQ		=> timerIRQ,
		seg7			=>	seg7,				
		seg7Digit	=>	seg7_digit,
		debug			=> '1',
		softReset	=> softReset,
		slow			=> slowPrg,
		debugData	=> debugData
	);
	
	
	u6: entity work.spi_master
	port map 
	(
		clock			=> clk100M,
		phi2			=> ioClock,
		wr				=> cpuRW,
		cs				=> CSSpi,
		CPUaddr		=> cpuAddress(3 downto 0),	
		CPUdataIn	=> cpuDataOut,
		CPUDataOut	=>	spiData,
		reset_n 		=> not reset,
		miso			=> SDmiso,
		sclk    		=> SDsclk,
		ss_n    		=> SDss,
		mosi    		=> SDmosi
	);
	
	
	u8: entity work.my6502keyboard
	port map(
    clock		=> clk100M,
	 phi2			=> ioClock,
	 wr			=> cpuRW,													--read=1, write=0
	 cs			=> CSps2kbd,									         --chip select active high
	 CPUaddr		=> cpuAddress(3 DOWNTO 0),  							--addr of registers
	 CPUdataIn	=> cpuDataOut,												--data in
	 CPUDataOut	=> ps2kbdData,												--data out
    reset_n 	=> not reset,												--asynchronous reset
	 intr			=> n_irq_ps2kbd,			        
	 PS2_CLK		=> ps2Clk,
	 PS2_DATA	=> ps2Data
	 );
	
	process (all)
	begin
		if rising_edge(clk100M) then
			if reset = '1' then
--				slow <= '0';
			end if;
			
			if key1 = '0' then
				key1_int <= '1';			
			end if;
			if key2 = '0' then
				key2_int <= '1';			
			end if;
			
			if key1_int = '1' then
				key1count <= key1count + 1;
				if key1count = 0 then
--					slow <= not slow;
					latch <= latch + 1;
				end if;
				
			end if;
			if key1count = 25000000 then
				key1count <= 0;
				key1_int <= '0';
			end if;
			
			if key2_int = '1' then
				key2count <= key2count + 1;
				if key2count = 0 then
					stop <= not stop;
				end if;				
			end if;
			if key2count = 25000000 then
				key2count <= 0;
				key2_int <= '0';
			end if;
			
			
		end if;
	end process;

	
	process (all)
	begin
		--led1 <= not reset;
		
		if rising_edge(clk100M) then
			if (reset_in = '0' or softReset = '1') and reset = '0' then
				reset_in_int <= '0';
			end if;
			
			if reset_in_int = '0' then
				if resClock < 25000000 then
					resClock <= resClock + 1;
					reset <= '1';
				else
					reset <= '0';
					reset_in_int <= '1';
					resClock <= 0;
				end if;
			end if;
			
		end if;
	end process;		
end;
