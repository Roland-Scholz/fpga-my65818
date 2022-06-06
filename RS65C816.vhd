library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
--use IEEE.STD_LOGIC_SIGNED.all;
--library work;

--
-- ToDo:
--
-- BRL check
-- IRQ
-- NMI
--

entity RS65C816 is
    port( 
        CLK			: in std_logic;
		  RST_N		: in std_logic;
		  RDY_IN		: in std_logic;
        NMI_N		: in std_logic;  
		  IRQ_N		: in std_logic; 
		  ABORT_N	: in std_logic;   -- just for WAI only
        D_IN		: in std_logic_vector(7 downto 0);
        D_OUT     : out std_logic_vector(7 downto 0);
        A_OUT     : out std_logic_vector(23 downto 0);
        WE  		: out std_logic; 
		  RDY_OUT 	: out std_logic;
		  VPA 		: out std_logic;
		  VDA 		: out std_logic;
		  MLB 		: out std_logic;
		  VPB 		: out std_logic;
		  pFlags		: out std_logic_vector(7 downto 0);
		  cpuSlow	: out std_logic
    );
end RS65C816;

architecture rtl of RS65C816 is
--	type		t_AddrModes is array (0 to 255) of std_logic_vector (4 downto 0); 
	type		t_procState IS (fetchOpcode, decodeOpcode, decodeOpcodeDummyA, decodeOpcodeDummyB, fetchAbsHi, fetchAbsBank, fetchRelHi,
									rwAbsDataLo, rwAbsDataHi, readIndirectLo, readIndirectHi, readIndirectBank, fetchIndirectHi, doALUdflag,
									pushLo, pushHi, pushBank, pushEnd, popLo, popHi, popBank, popFlags, storeLo, storeHi, doALU, doFlags, dead,
									fetchImmHi, fetchImmBank, readByte, writeByte, fetchSrcBank, startUp, pushFlags, readPCLo, readPCHi, readPCEnd,
									restoreFlags, decodeOpcodeLen2, dpageXY, fetchRelHiA, doALUdflagHi);
	
	signal	procState		: t_procState;
	signal	afterAlu			: t_procState;
	signal	afterPushLo		: t_procState;
		
	signal	pc					: std_logic_vector (23 downto 0);
	alias		progBank			: std_logic_vector ( 7 downto 0) is pc(23 downto 16);
	alias		pc16				: std_logic_vector (15 downto 0) is pc(15 downto 0);
	alias		pcHI				: std_logic_vector ( 7 downto 0) is pc(15 downto 8);
	alias		pc8				: std_logic_vector ( 7 downto 0) is pc(7 downto 0);
	
	signal	oldPc16			: std_logic_vector (15 downto 0);
		
	signal	A16				: std_logic_vector (15 downto 0);
	alias		AHI				: std_logic_vector (7 downto 0) is A16 (15 downto 8);
	alias		A8					: std_logic_vector (7 downto 0) is A16 (7 downto 0);
		
	signal	X16				: std_logic_vector (15 downto 0);
	alias		XHI				: std_logic_vector (7 downto 0) is X16 (15 downto 8);
	alias		X8					: std_logic_vector (7 downto 0) is X16 (7 downto 0);
		
	signal	Y16				: std_logic_vector (15 downto 0);
	alias		YHI				: std_logic_vector (7 downto 0) is Y16 (15 downto 8);
	alias		Y8					: std_logic_vector (7 downto 0) is Y16 (7 downto 0);
			
	signal	pc16plus1		: std_logic_vector (15 downto 0);
	signal	pc16addBra		: std_logic_vector (15 downto 0);
	signal	pc16addBrl		: std_logic_vector (15 downto 0);
	signal	pc16subBra		: std_logic_vector (15 downto 0);
	signal	pc16per			: std_logic_vector (15 downto 0);
	signal	val16				: std_logic_vector (15 downto 0);
	alias		val8				: std_logic_vector (7 downto 0) is val16 (7 downto 0);
	alias		valHI				: std_logic_vector (7 downto 0) is val16 (15 downto 8);
	signal	progBankTemp	: std_logic_vector (7 downto 0);
	signal	flag816			: std_logic;
		
		
	signal	stackp			: std_logic_vector (15 downto 0);
	signal	direct			: std_logic_vector (15 downto 0);
	signal	dataBank			: std_logic_vector (7 downto 0);
	signal	flags				: std_logic_vector (7 downto 0);
	alias		N_flag			: std_logic is flags(7);
	alias		V_flag			: std_logic is flags(6);
	alias		M_flag			: std_logic is flags(5);
	alias		X_flag			: std_logic is flags(4);
	alias		D_flag			: std_logic is flags(3);
	alias		I_flag			: std_logic is flags(2);
	alias		Z_flag			: std_logic is flags(1);
	alias		C_flag			: std_logic is flags(0);
		
	signal	aluC_flag		: std_logic;
	signal	COP_flag			: std_logic;

	signal	opA				:	std_logic_vector(15 downto 0);
	alias		opAHi				:	std_logic_vector(7 downto 0) is opA(15 downto 8);
	alias		opA8				:	std_logic_vector(7 downto 0) is opA(7 downto 0);
			
	signal	opBB				:	std_logic_vector(15 downto 0);
	signal	opB				:	std_logic_vector(15 downto 0);
	alias		opBHI				:	std_logic_vector(7 downto 0) is opB(15 downto 8);
	alias		opB8				:	std_logic_vector(7 downto 0) is opB(7 downto 0);

	signal	addr				: std_logic_vector (23 downto 0);
	alias		addrLo			: std_logic_vector (7 downto 0) is addr(7 downto 0);
	alias		addrHi			: std_logic_vector (7 downto 0) is addr(15 downto 8);
	alias		addrBank			: std_logic_vector (7 downto 0) is addr(23 downto 16);
	alias		addrWord			: std_logic_vector (15 downto 0) is addr(15 downto 0);
		
	signal	opcode			: std_logic_vector (7 downto 0);
		
	signal	long				: std_logic;
	signal	rwData			: std_logic;
	signal	movNeg			: std_logic;
	signal	interrupt		: std_logic_vector(1 downto 0);
	signal	adc				: std_logic;
	signal	sbc				: std_logic;
	signal	fetch				: std_logic;
	signal	aluAddHi			: std_logic;
	signal	doOpcode			: std_logic;
	signal	stop				: std_logic;
	signal	waitflag			: std_logic;
	signal	tempFlags		: std_logic_vector ( 7 downto 0);
	signal	tempRes			: std_logic_vector ( 7 downto 0);
	signal	wdm				: std_logic_vector ( 7 downto 0);
	signal	carrys			: std_logic_vector ( 3 downto 0);
		
	signal	stackpDin		: std_logic_vector (15 downto 0);
	signal	branchIn			: std_logic_vector (15 downto 0);
	signal	stackpPlus1		: std_logic_vector (15 downto 0);
	signal	stackpMinus1	: std_logic_vector (15 downto 0);
	signal	addrPlus1		: std_logic_vector (23 downto 0);
	signal	addrMinus1		: std_logic_vector (23 downto 0);
		
	signal	absBase    		: std_logic_vector (23 downto 0);
	signal	xInd				: std_logic_vector (15 downto 0);
	signal	yInd				: std_logic_vector (15 downto 0);
	signal	directX			: std_logic_vector (15 downto 0);
	signal	directY			: std_logic_vector (15 downto 0);
	signal	sum				: std_logic_vector (15 downto 0);
	
	signal   opcodeData  	: std_logic_vector(25 downto 0);	
	alias    opcodeAddrMode : std_logic_vector(4 downto 0) is opcodeData(25 downto 21);
	alias		opcodeOpA 		: std_logic_vector(3 downto 0) is opcodeData(20 downto 17);
	alias		opcodeOpB		: std_logic_vector(3 downto 0) is opcodeData(16 downto 13);
	alias		opcodeTarget	: std_logic_vector(3 downto 0) is opcodeData(12 downto 9);	
	alias		opcodeOperator : std_logic_vector(3 downto 0) is opcodeData(8 downto 5);
	alias    opcodeRead		: std_logic is opcodeData(4);
	alias    opcodeWrite		: std_logic is opcodeData(3);
	alias    preCarry			: std_logic is opcodeData(2);
	alias    carryValue		: std_logic is opcodeData(1);
	alias		getCarry			: std_logic is opcodeData(0);
	

   constant IMPLIED			: std_logic_vector(4 downto 0) := "00000";
   constant IMPFLAGS 		: std_logic_vector(4 downto 0) := "00001";
   constant IMMEDIATE		: std_logic_vector(4 downto 0) := "00010";
   constant STACKREL 		: std_logic_vector(4 downto 0) := "00011";
   constant DPAGE 			: std_logic_vector(4 downto 0) := "00100";
   constant DPAGEX 			: std_logic_vector(4 downto 0) := "00101";
   constant DPAGEY 			: std_logic_vector(4 downto 0) := "00110";
   constant DPAGEIND			: std_logic_vector(4 downto 0) := "00111";
   constant DPAGEINDX 		: std_logic_vector(4 downto 0) := "01000";
   constant DPAGEINDY 		: std_logic_vector(4 downto 0) := "01001";
   constant INDLONG 			: std_logic_vector(4 downto 0) := "01010";
   constant INDLONGY 		: std_logic_vector(4 downto 0) := "01011";
   constant STACKINDY 		: std_logic_vector(4 downto 0) := "01100";
   constant ABSOLUTE 		: std_logic_vector(4 downto 0) := "01101";
   constant ABSOLUTEX 		: std_logic_vector(4 downto 0) := "01110";
   constant ABSOLUTEY 		: std_logic_vector(4 downto 0) := "01111";
   constant ABSLONG			: std_logic_vector(4 downto 0) := "10000";
   constant ABSLONGX 		: std_logic_vector(4 downto 0) := "10001";
   constant INDIRECT 		: std_logic_vector(4 downto 0) := "10010";	-- JMP($aaaa)
   constant INDIRECTX 		: std_logic_vector(4 downto 0) := "10011";	-- JMP($aaaa,x), JSR ($aaaa,x)
   constant INDIRECTLON 	: std_logic_vector(4 downto 0) := "10100";
   constant BRANCHREL 		: std_logic_vector(4 downto 0) := "10101";
   constant BRANCHLONG 		: std_logic_vector(4 downto 0) := "10110";
   constant BLOCKMOVE		: std_logic_vector(4 downto 0) := "10111";
	constant IMMEDLONG		: std_logic_vector(4 downto 0) := "11000";
	constant BREAK				: std_logic_vector(4 downto 0) := "11001";
	constant COP				: std_logic_vector(4 downto 0) := "11010";
	constant STP				: std_logic_vector(4 downto 0) := "11011";
	constant WAI				: std_logic_vector(4 downto 0) := "11100";
	
	constant OP_ADC			: std_logic_vector(3 downto 0) := "0000";
	constant OP_SBC			: std_logic_vector(3 downto 0) := "0001";
	constant OP_AND			: std_logic_vector(3 downto 0) := "0010";
	constant OP_ORA			: std_logic_vector(3 downto 0) := "0011";
	constant OP_EOR			: std_logic_vector(3 downto 0) := "0100";
	constant OP_ROL			: std_logic_vector(3 downto 0) := "0101";
	constant OP_ROR			: std_logic_vector(3 downto 0) := "0110";
	constant OP_REP			: std_logic_vector(3 downto 0) := "0111";
	constant OP_PUS			: std_logic_vector(3 downto 0) := "1000";
	constant OP_POP			: std_logic_vector(3 downto 0) := "1001";
	constant OP_NOP			: std_logic_vector(3 downto 0) := "1010";
	constant OP_XBA			: std_logic_vector(3 downto 0) := "1011";
	constant OP_SEP			: std_logic_vector(3 downto 0) := "1100";
	constant OP_BIT			: std_logic_vector(3 downto 0) := "1101";
			
	constant OP_0				: std_logic_vector(3 downto 0) := "0000";
	constant OP_A				: std_logic_vector(3 downto 0) := "0001";
	constant OP_X				: std_logic_vector(3 downto 0) := "0010";
	constant OP_Y				: std_logic_vector(3 downto 0) := "0011";
	constant OP_V				: std_logic_vector(3 downto 0) := "0100";
	constant OP_S				: std_logic_vector(3 downto 0) := "0101";
	constant OP_D				: std_logic_vector(3 downto 0) := "0110";
	constant OP_F				: std_logic_vector(3 downto 0) := "0111";
	constant OP_K				: std_logic_vector(3 downto 0) := "1000";
	constant OP_B				: std_logic_vector(3 downto 0) := "1001";	
	constant OP_PC16			: std_logic_vector(3 downto 0) := "1010";	
	constant OP_PC24			: std_logic_vector(3 downto 0) := "1011";	
		
	constant COPVEC			: std_logic_vector(23 downto 0) := x"00FFE4";
	constant BRKVEC			: std_logic_vector(23 downto 0) := x"00FFE6";
	constant NMIVEC			: std_logic_vector(23 downto 0) := x"00FFEA";
	constant IRQVEC			: std_logic_vector(23 downto 0) := x"00FFEE";
		
	constant	COPINT			: std_logic_vector(1 downto 0) := "00";	
	constant	BRKINT			: std_logic_vector(1 downto 0) := "01";	
	constant	NMIINT			: std_logic_vector(1 downto 0) := "10";	
	constant	IRQINT			: std_logic_vector(1 downto 0) := "11";	

begin
	
	addPCper: entity work.add16				-- adder for BRL & PER
	port map (
		dataa			=> pc16,
		datab			=> val16,					--D_IN & val8, 
		cin			=> '1',
		result		=> pc16per
	);
	
	addPCbranch: entity work.add16			-- adder for simple branches
	port map (
		dataa			=> pc16,
		datab			=> branchIn, 
		cin			=> '1',
		result		=> pc16addBra
	);
	
	pcPlus1: entity work.add16					-- adder increment PC by 1
	port map (
		dataa			=> pc16,
		datab			=> x"0001",
		cin			=> '0',
		result		=> pc16plus1
	);
	
	stackPlus1: entity work.add16				-- stackp increment by 1
	port map (
		dataa			=> stackp,
		datab			=> x"0001",
		cin			=> '0',
		result		=> stackpPlus1
	);
	
	stackMinus1: entity work.add16			-- stackp decrement by 1
	port map (
		dataa			=> stackp,
		datab			=> x"FFFF",
		cin			=> '0',
		result		=> stackpMinus1
	);
	
	addrPlusOne: entity work.add24_1			-- addr increment by 1
	port map (
		dataa			=> addr,
		result		=> addrPlus1
	);	
	
	addrMinusOne: entity work.sub24_1		-- addr increment by 1
	port map (
		dataa			=> addr,
		result		=> addrMinus1
	);	
	
	u2: entity work.opcodes
	port map (
		address		=> opcode,
		clock			=> CLK,
		q				=> opcodeData,
		clken			=> '1'--RDY_IN
	);

	
	opBB <= not opB when opcodeOperator = OP_SBC else opB;
		
	A_OUT 	<= pc when rwData = '0' else addr;
	VDA		<= rwData and fetch;
	VPA		<= not rwData and fetch; 
	
	process (all)
								
		variable branchFlag	:	std_logic;
		variable	vflag816		:	std_logic;
		variable vCarry		:	std_logic;
		variable vCarryB		:	std_logic;
		variable	result16a	:	std_logic_vector(15 downto 0);
		variable	result16b	:	std_logic_vector(15 downto 0);
		
		variable	result17		:	std_logic_vector(16 downto 0);
		alias		result16		:	std_logic_vector(15 downto 0) is result17(15 downto 0);
		alias		result9 		:	std_logic_vector( 8 downto 0) is result17( 8 downto 0);
		alias		result8 		:	std_logic_vector( 7 downto 0) is result17( 7 downto 0);
		
		variable	nibble0		:	std_logic_vector( 4 downto 0);
		alias		nibble04		:	std_logic_vector( 3 downto 0) is nibble0( 3 downto 0);
		variable	nibble1		:	std_logic_vector( 4 downto 0);
		alias		nibble14		:	std_logic_vector( 3 downto 0) is nibble1( 3 downto 0);
		variable	nibble2		:	std_logic_vector( 4 downto 0);
		alias		nibble24		:	std_logic_vector( 3 downto 0) is nibble2( 3 downto 0);
		variable	nibble3		:	std_logic_vector( 4 downto 0);
		alias		nibble34		:	std_logic_vector( 3 downto 0) is nibble3( 3 downto 0);
		
		variable	noFlags		:	std_logic;
		
	begin
	
		if val8(7) = '0' then
			branchIn <= x"00" & val8;
		else
			branchIn <= x"FF" & val8;
		end if;	
		

		if	rising_edge(CLK) then
				
			if RST_N = '0' then
				pc 			<= x"00FFFB";--"x"00FFFC";
				dataBank		<= x"00";
				stackp		<= x"01FF";
				direct		<= x"0000";
				wdm			<= x"00";
				
				I_flag		<= '1';	-- interrupt disable
				D_flag		<= '0';	-- decimal off
				M_flag		<= '1';	--	accu  8-bit
				X_flag		<= '1';	-- index 8-bit
				
				COP_flag		<= '0';
				doOpcode		<= '0';
				stop			<= '0';
				waitflag		<= '0';
				
				procState	<= decodeOpcodeDummyA;
				opcode		<= x"4C";
				cpuSlow		<= '0';
								
			elsif RDY_IN = '1' and stop = '0' then
				
				WE			<= '1';
				rwData	<= '0';
				fetch		<= '1';
				cpuSlow	<= '0';
				aluAddHi <= '0';
				
				case procState is
				
				--
				--
				--
				when fetchOpcode =>
					fetch <= '0';
					
					procState <= decodeOpcodeDummyA;		--decodeOpcode;-- 
					
					if waitflag = '1' then
						if IRQ_N = '1' and NMI_N = '1' then
							fetch <= '0';
							procState <= fetchOpcode;
						else
							waitflag <= '0';
						end if;
					end if;

					-- save opcode
					opcode <= D_IN;
											
					absBase <= dataBank & x"0000";
					oldPc16 <= pc16;
					
					if NMI_N = '0' then
						procState <= pushBank;
						afterPushLo <= pushFlags;
						opA <= pc16;
						progBankTemp <= progBank;					
						interrupt <= NMIINT;
					elsif IRQ_N = '0' and I_flag = '0' then
						procState <= pushBank;
						afterPushLo <= pushFlags;
						opA <= pc16;
						progBankTemp <= progBank;						
						interrupt <= IRQINT;
					elsif wdm(2 downto 0) = 7 and doOpcode = '0' and COP_flag = '0' then
							procState <= pushBank;
							afterPushLo <= pushFlags;
							opA <= pc16;
							progBankTemp <= progBank;
							interrupt <= COPINT;
							COP_flag <= '1';
					end if;
					
					doOpcode <= '0';
					
					if X_flag = '1' then
						XHI <= x"00";
						YHI <= x"00";
					end if;
					
					
				when decodeOpcodeDummyA =>
					fetch <= '0';
					procState <= decodeOpcode;	--decodeOpcodeDummyB; --decodeOpcode;--
					afterAlu <= fetchOpcode;
					afterPushLo <= pushEnd;

					xInd <= X16;
					yInd <= Y16;
					
					directX <= direct + X16;
					directY <= direct + Y16;
					
					pc16 <= pc16plus1;				
	
	
	
				when decodeOpcode =>
				
					procState <= decodeOpcodeLen2;	
					
					adc <= '0';
					sbc <= '0';
					long <= '0';
										
					if opcodeTarget = OP_A and getCarry = '1' then
						if opcodeOperator = OP_ADC then
							adc <= '1';
						end if;
						if opcodeOperator = OP_SBC then
							sbc <= '1';
						end if;
					end if;
					
					
					case opcodeOpA is
					when OP_A => opA	<= A16;					
					when OP_B => opA8	<= dataBank;
					when OP_D => opA	<= direct;
					when OP_F => opA8 <= flags;
					when OP_K => opA8	<= progBank;
					when OP_S => opA	<= stackp;
					when OP_V => opA	<= x"00" & D_IN;
					when OP_X => opA	<= X16; 
					when OP_Y => opA	<= Y16;
					when others =>
						opA <= (others => '0');
					end case;
					
					opB <= (others =>'0');
					
					case opcodeTarget is
					when OP_A										=> 
						if opcodeOpA = OP_D or opcodeOpA = OP_S then
							vflag816 := '0';															-- tdc, tsc
						else
							vflag816 := M_flag;
						end if;
					when OP_V										=> vflag816 := M_flag;
					when OP_X | OP_Y 								=> vflag816 := X_flag;
					when OP_S | OP_D | OP_PC16	| OP_PC24	=> vflag816 := '0';
					when OP_0										=>									-- CMP, CPX, CPY, BIT
						if opcodeOpA = OP_A then
							vflag816 := M_flag;
						else
							vflag816 := X_flag;
						end if;
					when others 									=>	vflag816 := '1';
					end case;
					
					flag816 <= vflag816;
					
					if preCarry = '1' then
						aluC_flag <= carryValue;
					else
					   aluC_flag <= C_flag;
					end if;

					case opcodeAddrMode is		
					when STP =>
						stop <= '1';
						
					when WAI =>
						waitflag <= '1';
						procState <= fetchOpcode;
						
					when IMPLIED =>					
						case opcodeOperator is
						when OP_POP	=>	
							if opcodeRead = '0' then			-- RTI
								procState <= popFlags;			-- pop flags, PC-lo, hi, bank
								afterAlu <= restoreFlags;
							else
								procState <= popLo;				-- pop PC-lo, hi, bank
							end if;
							stackp <= stackpPlus1;
							addrBank <= x"00";
							addrWord <= stackpPlus1;					
							rwData <= '1';
							if opcodeTarget = OP_PC24 then
								long <= '1';
							end if;
						when OP_PUS	=>	
							fetch <= '0';
							if vflag816 = '0' then
								procState <= pushHi;
							else
								procState <= pushLo;
							end if;						
						when others =>
						   fetch <= '0';
							if opcodeOperator = OP_XBA then	--force XBA 8-bit
								flag816 <= '1';
							end if;
							if opcodeOpA = OP_S then
								flag816 <= '0';
							end if;	
							procState <= doALU;
						end case;
						
					when IMPFLAGS =>
						procState <= fetchOpcode;
						case opcode(7 downto 6) is
						when "00" => C_flag <= opcode(5); 
						when "01" => I_flag <= opcode(5); 
						when "10" => V_flag <= '0';
						when "11" => D_flag <= opcode(5); 
						end case;				

					when others =>
						null;
					end case;
	
	
				when decodeOpcodeLen2 =>
				
					case opcodeOpB is
					when OP_V => opB8 <= D_IN;
					when OP_A => opB <= A16;
					when others =>
						null;
					end case;

					val8 <= D_IN;
			
					case opcodeAddrMode is				
					when IMMEDIATE =>
						pc16 <= pc16plus1;
						if flag816 = '1' then
							fetch <= '0';
							procState <= doALU;
							
							if opcode = x"42" then				-- WDM
								wdm <= D_IN;
							end if;
						else
							procState <= fetchImmHi;
						end if;
						
					when IMMEDLONG =>
						procState <= fetchImmHi;
						pc16 <= pc16plus1;
						long <= '1';
						
					when BRANCHLONG =>
						pc16 <= pc16plus1;
						procState <= fetchRelHi;
						
					when BRANCHREL | STACKREL | STACKINDY | DPAGEINDY | DPAGE | DPAGEX | DPAGEY =>
						fetch <= '0';
						procState <= dpageXY;
						
					when DPAGEIND =>
						yInd <= (others => '0');
						fetch <= '0';
						procState <= dpageXY;
						
					when INDLONGY =>
						fetch <= '0';
						long <= '1';
						procState <= dpageXY; --readIndirectLo;

					when INDLONG =>
						yInd <= (others => '0');
						fetch <= '0';
						long <= '1';
						procState <= dpageXY;
						
					when DPAGEINDX =>
						yInd <= (others => '0');
						fetch <= '0';
						procState <= dpageXY; --readIndirectLo;					
						
					when INDIRECTLON =>
						procState <= fetchIndirectHi;
						yInd <= (others => '0');
						long <= '1';
						pc16 <= pc16plus1;
					
					when INDIRECT | INDIRECTX =>
						procState <= fetchIndirectHi;
						yInd <= (others => '0');
						pc16 <= pc16plus1;											
																	
					when ABSOLUTE =>
						procState <= fetchAbsHi;
						pc16 <= pc16plus1;
						
					when ABSOLUTEX =>
						procState <= fetchAbsHi;
						pc16 <= pc16plus1;
						absBase <= absBase + xInd;
						
					when ABSOLUTEY =>
						procState <= fetchAbsHi;
						pc16 <= pc16plus1;
						absBase <= absBase + yInd;

					when ABSLONG =>
						absBase <= (others => '0');
						procState <= fetchAbsHi;
						pc16 <= pc16plus1;
						long <= '1';
						
					when ABSLONGX =>
						absBase <= x"00" & xInd;
						procState <= fetchAbsHi;
						pc16 <= pc16plus1;
						long <= '1';					
					
					when BLOCKMOVE =>
						procState <= fetchSrcBank;
						dataBank <= D_IN;
						pc16 <= pc16plus1;
						movNeg <= opcode(4);
											
					when COP =>
						fetch <= '0';
						procState <= pushBank;
						afterPushLo <= pushFlags;
						opA <= pc16plus1;
						progBankTemp <= progBank;
						interrupt <= COPINT;
						
					when BREAK =>
						fetch <= '0';
						procState <= pushBank;
						afterPushLo <= pushFlags;
						opA <= pc16plus1;
						progBankTemp <= progBank;
						interrupt <= BRKINT;						

					when others =>
						procState <= dead;
					end case;
				

			
				when dpageXY =>
				
					case opcodeAddrMode is
					when BRANCHREL =>
						pc16 <= pc16plus1;
						procState <= fetchOpcode;

						case opcode(7 downto 6) is
						when "00" => branchFlag := N_flag; 
						when "01" => branchFlag := V_flag; 
						when "10" => branchFlag := C_flag; 
						when "11" => branchFlag := Z_flag; 
						end case;
						
						if branchFlag = opcode(5) or opcode(7 downto 4) = "1000" then	-- BRA x80
							pc16 <= pc16addBra;
						end if;

					when STACKREL =>								-- adc 1,s
						procState <= rwAbsDataLo;
						addr <= x"00" & (stackp + val8);
						rwData <= '1';								
						if opcodeWrite = '1' then				-- no read-modify-write
							WE <= '0';
							D_OUT <= A8;
						end if;
						
					when STACKINDY =>
						addr <= x"00" & (stackp + val8);		--lda (1,s),y
						rwData <= '1';
						procState <= readIndirectLo;

					when DPAGEINDX =>								-- lda (zp,x)
						addr <= x"00" & (directX + val8);	-- x"00" & directPlusDinX;--(directPlusDin + xInd);
						rwData <= '1';
						procState <= readIndirectLo;
						
					when DPAGE | DPAGEX | DPAGEY =>
					
						procState <= rwAbsDataLo;
						
						rwData <= '1';		
						
						case opcodeAddrMode is
						when DPAGE =>
							addr <= x"00" & (direct + val8);
						when DPAGEX =>
							addr <= x"00" & (directX + val8);
						when DPAGEY =>
							addr <= x"00" & (directY + val8);
						when others => null;
						end case;
						
						if opcodeWrite = '1' and opcodeRead = '0' then
							WE <= '0';
							case opcodeOpA is
							when OP_A => D_OUT <= A8;
							when OP_X => D_OUT <= X8; 
							when OP_Y => D_OUT <= Y8;
							when others => D_OUT <= (others => '0');
							end case;
						end if;
												
					when INDLONG | INDLONGY | DPAGEIND | DPAGEINDY =>
						rwdata <= '1';
						addr <= x"00" & (direct + (x"00" & val8));	
						procState <= readIndirectLo;
						
					when others =>
						null;
					end case;
						
					
				when fetchRelHi =>
					procState <= fetchRelHiA;
					fetch <= '0';
					valHi <= D_IN;

				when fetchRelHiA =>
					if opcodeOperator = OP_PUS then	-- PER
						fetch <= '0';
						procState <= pushHi;
						pc16 <= pc16plus1;
						opA <= pc16per;		
					else
						procState <= fetchOpcode;		-- BRL			
						pc16 <= pc16per;
					end if;
					
				when fetchSrcBank =>
					procState <= readByte;
					pc16 <= pc16plus1;
					
					if A16 = x"FFFF" then
						procState <= fetchOpcode;
					else
						addr <= D_IN & X16;
						rwData <= '1';
					end if;

					
				when readByte =>
					procState <= writeByte;
					addr <= dataBank & Y16;
					D_OUT <= D_IN;
					WE <= '0';
					rwData <= '1';
					if movNeg then
						X16 <= X16 + 1;
						Y16 <= Y16 + 1;
					else
						X16 <= X16 - 1;
						Y16 <= Y16 - 1;
					end if;
					A16 <= A16 - 1;

				when writeByte =>
					procState <= fetchOpcode;
					pc16 <= oldPc16;
					
				--
				--
				--
				when fetchIndirectHi =>
					procState <= readIndirectLo;
					
					case opcodeAddrMode is
					when INDIRECTX =>					
						addr <= (progBank & D_IN & val8) + xInd;
					when INDIRECT =>
						addr <= x"00" & D_IN & val8;
					when others =>
						addr <= dataBank & D_IN & val8;
					end case;
					
					rwdata <= '1';
					
				--
				--
				--
				when popFlags =>
					procState <= popLo;
					tempFlags <= D_IN;
					stackp <= stackpPlus1;
					addrWord <= stackpPlus1;					
					rwData <= '1';


				when popLo =>
					procState <= doALU;
					opB8 <= D_IN;

					if flag816 = '0' then 
						procState <= popHi;

						stackp <= stackpPlus1;
						addrWord <= stackpPlus1;					
						rwData <= '1';
					end if;
					
				--
				--
				--
				when popHi =>
					opBHI <= D_IN;
					
					if long = '0' then
						fetch <= '0';
						procState <= doALU;
					else
						procState <= popBank;					
						stackp <= stackpPlus1;
						addrWord <= stackpPlus1;					
						rwData <= '1';
					end if;
					
				--
				--
				--					
				when popBank =>
					fetch <= '0';
					procState <= doALU;-- fetchOpcode;		
					progBank <= D_IN;
				--
				--
				--
				when fetchImmHi =>
					valHI <= D_IN;
					pc16 <= pc16plus1;
					
					if long = '0' then						
						if OPCodeTarget = OP_PC16 then		-- JMP $aabb
							opA <= pc16;
							pc16 <= D_IN & val8;
							procState <= fetchOpcode;
							if opcodeWrite = '1' then			-- JSR $aabb
								fetch <= '0';
								procState <= pushHi;
							end if;
						elsif OpcodeTarget = OP_S then
							opA <= D_IN & val8;
							fetch <= '0';
							procState <= pushHi;
						else
							fetch <= '0';						
							opBHI <= D_IN;
							procState <= doALU;
						end if;
					else
						procState <= fetchImmBank;
					end if;

					
				when fetchImmBank =>
					procState <= fetchOpcode;
					opA <= pc16;							-- save PC24
					progBankTemp <= progBank;
	
					pc <= D_IN & val16;					-- JMP $aabbcc
					
					if opcodeWrite = '1' then			-- JSL $aabbcc
						procState <= pushBank;
					end if;
					
					
				when fetchAbsHi =>
					valHi <= D_IN;
					
					if long = '0' then
						procState <= rwAbsDataLo;
						rwData <= '1';
						
						addr <= absBase + (D_IN & val8);
						
						if opcodeWrite = '1' and opcodeRead = '0' then
							WE <= '0';
							D_OUT <= opA8;
						end if;
					else
						procState <= fetchAbsBank;
						pc16 <= pc16plus1;
					end if;
					
					
				when fetchAbsBank =>
					procState <= rwAbsDataLo;
					rwData <= '1';
					
					addr <= absBase + (D_IN & val16);
					
					if opcodeWrite = '1' and opcodeRead = '0' then
						WE <= '0';
						D_OUT <= opA8;
					end if;
					
				
				when rwAbsDataLo =>
					pc16 <= pc16plus1;
					
					if opcodeWrite = '1' and opcodeRead = '1' then		--read-modify-write
						opA8 <= D_IN;
						afterAlu <= storeLo;
					else
						opB8 <= D_IN;
					end if;
					
					if flag816 = '0' then
						procState <= rwAbsDataHi;
						rwData <= '1';
						addr <= addrPlus1;
						if opcodeWrite = '1' and opcodeRead = '0' then
							WE <= '0';
							D_OUT <= opAHI;
						end if;
					else					
						if opcodeRead = '1' then
							fetch <= '0';
							procState <= doALU;
						else
							procState <= fetchOpcode;
						end if;					end if;

					
				when rwAbsDataHi =>
					fetch <= '0';
					if opcodeWrite = '1' and opcodeRead = '1' then
						opAHI <= D_IN;
						afterAlu <= storeLo;
						addr <= addrMinus1;
					else
						opBHI <= D_IN;
					end if;

					if opcodeRead = '1' then
						if opcodeTarget = OP_S then
							opA <= D_IN & opB8;
							procState <= pushHi;
						else
							procState <= doALU;
						end if;
					else
						fetch <= '1';
						procState <= fetchOpcode;
					end if;


				when storeLo =>
					if flag816 = '0' then
						procState <= storeHi;
					else
						procState <= pushEnd;
					end if;
					
					rwData <= '1';
					WE <= '0';
					D_OUT <= val8;

					
				when storeHi =>
					addr <= addrPlus1;
					procState <= pushEnd;
					rwData <= '1';
					WE <= '0';
					D_OUT <= valHi;

					
				when pushBank =>
					procState <= pushHi;
					WE <= '0';
					rwData <= '1';
					addr <= x"00" & stackp;
					D_OUT <= progBankTemp;
					stackp <= stackpMinus1;


				when pushHi =>
					procState <= pushLo;
					WE <= '0';
					rwData <= '1';
					addr <= x"00" & stackp;
					D_OUT <= opAHI;
					stackp <= stackpMinus1;

					
				when pushLo =>
					procState <= afterPushLo;
					WE <= '0';
					rwData <= '1';
					addr <= x"00" & stackp;
					D_OUT <= opA8;
					stackp <= stackpMinus1;
				
				
				when pushEnd =>
					procState <= fetchOpcode;
					
	
				when pushFlags =>
					procState <= readPCLo;
					WE <= '0';
					rwData <= '1';
					addr <= x"00" & stackp;
					D_OUT <= flags;
					stackp <= stackpMinus1;
					I_flag <= '1';
					D_flag <= '0';
					
								
				when readPCLo =>
					procState <= readPCHi;
					case interrupt is
					when "00" => addr <= COPVEC;
					when "01" => addr <= BRKVEC;
					when "10" => addr <= NMIVEC;
					when "11" => addr <= IRQVEC;
					end case;
					rwData <= '1';
					
					
				when readPCHi =>
					procState <= readPCEnd;
					pc8 <= D_IN;
					rwData <= '1';
					addr <= addrPlus1;
					
					
				when readPCEnd =>
					procState <= fetchOpcode;
					pcHi <= D_IN;
					progBank <= x"00";

				
				when readIndirectLo =>
					procState <= readIndirectHi;
					val8 <= D_IN;
					addr <= addrPlus1;
					rwData <= '1';
				
				
				when readIndirectHi =>
					rwData <= '1';
					valHI <= D_IN;
					if long = '0' then
						procState <= rwAbsDataLo;
						addr <= (dataBank & D_IN & val8) + yInd;
						if opcodeTarget = OP_PC16 then
							opA <= pc16;
							procState <= fetchOpcode;
							pc16 <= D_IN & val8;
							rwData <= '0';
							if opcodeWrite = '1' then			-- JSR
								fetch <= '0';
								procState <= pushHi;
							end if;
						end if;
						
						if opcodeWrite = '1' then
							WE <= '0';
							D_OUT <= opA8;
						end if;				
					else
						procState <= readIndirectBank;
						addr <= addrPlus1;
						long <= '0';
					end if;
					
					
				when readIndirectBank =>
					procState <= rwAbsDataLo;
					rwData <= '1';
					
					addr <= (D_IN & val16) + yInd;


					if opcodeTarget = OP_PC24 then
						procState <= fetchOpcode;
						pc <= D_IN & val16;
						rwData <= '0';
					elsif opcodeWrite = '1' then
						WE <= '0';
						D_OUT <= opA8;
					end if;				
				--
				--
				--
				when doALU =>

					noFlags := '0';
					
					procState <= afterAlu;
					if afterAlu /= fetchOpcode then
						fetch <= '0';
					end if;
									
					if flag816 = '0' then
						case opcodeOperator is
						when OP_ADC | 
						     OP_POP |
							  OP_SBC				=> 
												  
									if (adc = '1' or sbc = '1') and d_flag = '1' then
										if aluAddHi = '0' then
											noFlags := '1';
											aluAddHi <= '1';
											fetch <= '0';
											procState <= doALU;
											nibble0 := "0" & opA( 3 downto  0) + opBB( 3 downto  0) + aluC_flag;										 
											nibble1 := "0" & opA( 7 downto  4) + opBB( 7 downto  4) + nibble0(4);										 
										
											tempRes <= nibble14 & nibble04;
											carrys(1 downto 0) <= nibble1(4) & nibble0(4);
										else														
											nibble2 := "0" & opA(11 downto  8) + opBB(11 downto  8) + carrys(1);
											nibble3 := "0" & opA(15 downto 12) + opBB(15 downto 12) + nibble2(4);
											result17 := nibble3 & nibble24 & tempRes;
											carrys(3 downto 2) <= nibble3(4) & nibble2(4);	
										end if;										
									else
										result17 := ("0" & opA) + opBB + aluC_flag;
									end if;
														
						when OP_AND	| OP_BIT	=> result16 := opA and opB;
						when OP_EOR				=> result16 := opA xor opB;
						when OP_ORA | OP_SEP => result16 := opA or  opB;
						when OP_ROL				=> result17 := opA(15 downto 0) & aluC_flag;
						when OP_ROR				=> result17 := opA(0) & aluC_flag & opA(15 downto 1);			
						when OP_REP				=> result16 := opA and not opB;		
						when others				=> null;
						end case;
						
						case opcodeTarget is
						when OP_A					=> A16 		<= result16; 
						when OP_D					=> direct 	<= result16; 
						when OP_S					=> stackp 	<= result16; 
						when OP_X					=> X16 		<= result16;
						when OP_Y					=> Y16 		<= result16;
						when OP_V					=> val16 	<= result16;
						when OP_PC16 | OP_PC24	=> pc16 		<= result16;
						when others					=> null;
						end case;
						
						
						if adc or sbc then
							V_flag <= (opA(15) xor result16(15)) and (opBB(15) xor result16(15));
							if D_flag = '1' and noFlags = '0' then
								fetch <= '0';
								procState <= doALUdflag;
							end if;
						end if;
						
						if opcodeTarget /= OP_PC16 and opcodeTarget /= OP_S and opcodeTarget /= OP_PC24 then
							if (opcodeOperator = OP_SEP) or (opcodeOperator = OP_REP) then
								if (opA and opB) = X"0000" then Z_flag <= '1'; else Z_flag <= '0'; end if;
							else
								if opcodeOperator = OP_BIT then
									N_flag <= opB(15);
									V_flag <= opB(14);
								else
									N_flag <= result16(15);
								end if;
								if result16 = x"0000" then Z_flag <= '1'; else Z_flag <= '0'; end if;
							end if;
						end if;
							
						if getCarry = '1' then
							C_flag <= result17(16);
						end if;	
					
					else
						case opcodeOperator is
						when OP_ADC |
							  OP_POP	| 
							  OP_SBC				=> 
														nibble0 := "0" & opA8(3 downto 0) + opBB(3 downto 0) + aluC_flag;
														nibble1 := "0" & opA8(7 downto 4) + opBB(7 downto 4) + nibble0(4);
														result9 := nibble1 & nibble04;
														carrys(1 downto 0) <= nibble1(4) & nibble0(4);
																									
						when OP_AND	| OP_BIT	=> result8 := opA8 and opB8;
						when OP_EOR				=> result8 := opA8 xor opB8;
						when OP_ORA	| OP_SEP	=> result8 := opA8 or  opB8;
						when OP_ROL				=> result9 := opA8 & aluC_flag;
						when OP_ROR				=> result9 := opA8(0) & aluC_flag & opA8(7 downto 1);				
						when OP_REP				=> result8 := opA8 and not opB8;
						when OP_XBA				=> result8 := AHI; AHI <= A8;
						when others				=> null;
						end case;
						
						case opcodeTarget is
						when OP_A				=> A8			<= result8; 
						when OP_B				=> dataBank	<= result8; 
						when OP_X				=> X8			<= result8;
						when OP_Y				=> Y8			<= result8;
						when OP_V				=> val8		<= result8;
						when OP_F				=> flags		<= result8;
						when others				=> null;
						end case;
						
						--opResult9 <= result9;
						
						if adc or sbc then
							V_flag <= (opA8(7) xor result8(7)) and (opBB(7) xor result8(7));
							if D_flag = '1' then
								fetch <= '0';
								procState <= doALUdflag;
							end if;
						end if;
						
						if opcodeTarget /= OP_F then
							if (opcodeOperator = OP_SEP) or (opcodeOperator = OP_REP) then
								if (opA8 and opB8) = X"00" then Z_flag <= '1'; else Z_flag <= '0'; end if;
							else
								if opcodeOperator = OP_BIT then
									N_flag <= opB8(7);
									V_flag <= opB8(6);
								else
									N_flag <= result8(7);
								end if;
								if result8 = x"00" then Z_flag <= '1'; else Z_flag <= '0'; end if;
							end if;
						end if;
						
						if getCarry = '1' then
							C_flag <= result9(8);
						end if;
					end if;

					
					
				when doALUdflag =>
					procState <= afterAlu;
					if afterAlu /= fetchOpcode then
						fetch <= '0';
					end if;

					if flag816 = '0' then
						procState <= doALUdflagHi;
						fetch <= '0';
					end if;
					
					vCarry := '0';
					result16a := A16;
					
					
					if adc = '1' then
					 
						if result16a(3 downto 0) > 9 or carrys(0) = '1' then
							result16a(3 downto 0) := result16a(3 downto 0) + x"6";
							
							if carrys(0) = '0' then
								result16a(15 downto 4) := result16a(15 downto 4) + 1;
							end if;
						end if;
						if result16a(7 downto 4) > 9 or carrys(1) = '1' then
							result16a(7 downto 4) := result16a(7 downto 4) + x"6";
							vCarry := '1';
						end if;	
						A8 <= result16a(7 downto 0);
								
											
						C_flag <= vCarry;
					
					else					
						if A16(3 downto 0) > 9 then
							A16(3 downto 0) <= A16(3 downto 0) + x"A";
						end if;
						if A16(7 downto 4) > 9 then
							A16(7 downto 4) <= A16(7 downto 4) + x"A";
						end if;

					end if;			
					
	
				when doALUdflagHi =>
					procState <= afterAlu;
					if afterAlu /= fetchOpcode then
						fetch <= '0';
					end if;
				
					if adc = '1' then

						vCarryB := C_flag;
						result16b := A16;
						
						if vCarryB = '1' and carrys(1) = '0' then
							result16b(15 downto 8) := result16b(15 downto 8) + 1;
						end if;
						
						vCarryB := '0';
						
						if result16b(11 downto 8) > 9 or carrys(2) = '1' then
							result16b(11 downto 8) := result16b(11 downto 8) + x"6";
							if carrys(2) = '0' then
								result16b(15 downto 12) := result16b(15 downto 12) + 1;
							end if;
						end if;
						if result16b(15 downto 12) > 9 or carrys(3) = '1' then
							result16b(15 downto 12) := result16b(15 downto 12) + x"6";
							vCarryB := '1';
						end if;	
						AHI <= result16b(15 downto 8);				
						
						C_flag <= vCarryB;
	
					else
					
						if A16(11 downto 8) > 9 then
							A16(11 downto 8) <= A16(11 downto 8) + x"A";
						end if;	
						if A16(15 downto 12) > 9 then
							A16(15 downto 12) <= A16(15 downto 12) + x"A";
						end if;	
					end if;

				when restoreFlags =>
					flags <= tempFlags;
					procState <= fetchOpcode;
					if interrupt = COPINT and wdm(2 downto 0) = 7 then
						doOpcode <= '1';
						COP_flag <= '0';
					end if;
					
				--
				--
				--
				when others =>
					null;
				end case;
				
			end if;
		end if;
		
	end process;
end rtl;