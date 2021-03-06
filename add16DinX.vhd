-- megafunction wizard: %PARALLEL_ADD%
-- GENERATION: STANDARD
-- VERSION: WM1.0
-- MODULE: parallel_add 

-- ============================================================
-- File Name: add16DinX.vhd
-- Megafunction Name(s):
-- 			parallel_add
--
-- Simulation Library Files(s):
-- 			altera_mf
-- ============================================================
-- ************************************************************
-- THIS IS A WIZARD-GENERATED FILE. DO NOT EDIT THIS FILE!
--
-- 20.1.0 Build 711 06/05/2020 SJ Lite Edition
-- ************************************************************


--Copyright (C) 2020  Intel Corporation. All rights reserved.
--Your use of Intel Corporation's design tools, logic functions 
--and other software and tools, and any partner logic 
--functions, and any output files from any of the foregoing 
--(including device programming or simulation files), and any 
--associated documentation or information are expressly subject 
--to the terms and conditions of the Intel Program License 
--Subscription Agreement, the Intel Quartus Prime License Agreement,
--the Intel FPGA IP License Agreement, or other applicable license
--agreement, including, without limitation, that your use is for
--the sole purpose of programming logic devices manufactured by
--Intel and sold by Intel or its authorized distributors.  Please
--refer to the applicable agreement for further details, at
--https://fpgasoftware.intel.com/eula.


LIBRARY ieee;
USE ieee.std_logic_1164.all;

LIBRARY altera_mf;
USE altera_mf.altera_mf_components.all;

ENTITY add16DinX IS
	PORT
	(
		data0x		: IN STD_LOGIC_VECTOR (15 DOWNTO 0);
		data1x		: IN STD_LOGIC_VECTOR (15 DOWNTO 0);
		data2x		: IN STD_LOGIC_VECTOR (15 DOWNTO 0);
		data3x		: IN STD_LOGIC_VECTOR (15 DOWNTO 0);
		data4x		: IN STD_LOGIC_VECTOR (15 DOWNTO 0);
		data5x		: IN STD_LOGIC_VECTOR (15 DOWNTO 0);
		data6x		: IN STD_LOGIC_VECTOR (15 DOWNTO 0);
		data7x		: IN STD_LOGIC_VECTOR (15 DOWNTO 0);
		result		: OUT STD_LOGIC_VECTOR (15 DOWNTO 0)
	);
END add16DinX;


ARCHITECTURE SYN OF add16dinx IS

--	type ALTERA_MF_LOGIC_2D is array (NATURAL RANGE <>, NATURAL RANGE <>) of STD_LOGIC;

	SIGNAL sub_wire0	: STD_LOGIC_VECTOR (15 DOWNTO 0);
	SIGNAL sub_wire1	: ALTERA_MF_LOGIC_2D (7 DOWNTO 0, 15 DOWNTO 0);
	SIGNAL sub_wire2	: STD_LOGIC_VECTOR (15 DOWNTO 0);
	SIGNAL sub_wire3	: STD_LOGIC_VECTOR (15 DOWNTO 0);
	SIGNAL sub_wire4	: STD_LOGIC_VECTOR (15 DOWNTO 0);
	SIGNAL sub_wire5	: STD_LOGIC_VECTOR (15 DOWNTO 0);
	SIGNAL sub_wire6	: STD_LOGIC_VECTOR (15 DOWNTO 0);
	SIGNAL sub_wire7	: STD_LOGIC_VECTOR (15 DOWNTO 0);
	SIGNAL sub_wire8	: STD_LOGIC_VECTOR (15 DOWNTO 0);
	SIGNAL sub_wire9	: STD_LOGIC_VECTOR (15 DOWNTO 0);

BEGIN
	sub_wire8    <= data0x(15 DOWNTO 0);
	sub_wire7    <= data1x(15 DOWNTO 0);
	sub_wire6    <= data2x(15 DOWNTO 0);
	sub_wire5    <= data3x(15 DOWNTO 0);
	sub_wire4    <= data4x(15 DOWNTO 0);
	sub_wire3    <= data5x(15 DOWNTO 0);
	sub_wire2    <= data6x(15 DOWNTO 0);
	sub_wire0    <= data7x(15 DOWNTO 0);
	sub_wire1(7, 0)    <= sub_wire0(0);
	sub_wire1(7, 1)    <= sub_wire0(1);
	sub_wire1(7, 2)    <= sub_wire0(2);
	sub_wire1(7, 3)    <= sub_wire0(3);
	sub_wire1(7, 4)    <= sub_wire0(4);
	sub_wire1(7, 5)    <= sub_wire0(5);
	sub_wire1(7, 6)    <= sub_wire0(6);
	sub_wire1(7, 7)    <= sub_wire0(7);
	sub_wire1(7, 8)    <= sub_wire0(8);
	sub_wire1(7, 9)    <= sub_wire0(9);
	sub_wire1(7, 10)    <= sub_wire0(10);
	sub_wire1(7, 11)    <= sub_wire0(11);
	sub_wire1(7, 12)    <= sub_wire0(12);
	sub_wire1(7, 13)    <= sub_wire0(13);
	sub_wire1(7, 14)    <= sub_wire0(14);
	sub_wire1(7, 15)    <= sub_wire0(15);
	sub_wire1(6, 0)    <= sub_wire2(0);
	sub_wire1(6, 1)    <= sub_wire2(1);
	sub_wire1(6, 2)    <= sub_wire2(2);
	sub_wire1(6, 3)    <= sub_wire2(3);
	sub_wire1(6, 4)    <= sub_wire2(4);
	sub_wire1(6, 5)    <= sub_wire2(5);
	sub_wire1(6, 6)    <= sub_wire2(6);
	sub_wire1(6, 7)    <= sub_wire2(7);
	sub_wire1(6, 8)    <= sub_wire2(8);
	sub_wire1(6, 9)    <= sub_wire2(9);
	sub_wire1(6, 10)    <= sub_wire2(10);
	sub_wire1(6, 11)    <= sub_wire2(11);
	sub_wire1(6, 12)    <= sub_wire2(12);
	sub_wire1(6, 13)    <= sub_wire2(13);
	sub_wire1(6, 14)    <= sub_wire2(14);
	sub_wire1(6, 15)    <= sub_wire2(15);
	sub_wire1(5, 0)    <= sub_wire3(0);
	sub_wire1(5, 1)    <= sub_wire3(1);
	sub_wire1(5, 2)    <= sub_wire3(2);
	sub_wire1(5, 3)    <= sub_wire3(3);
	sub_wire1(5, 4)    <= sub_wire3(4);
	sub_wire1(5, 5)    <= sub_wire3(5);
	sub_wire1(5, 6)    <= sub_wire3(6);
	sub_wire1(5, 7)    <= sub_wire3(7);
	sub_wire1(5, 8)    <= sub_wire3(8);
	sub_wire1(5, 9)    <= sub_wire3(9);
	sub_wire1(5, 10)    <= sub_wire3(10);
	sub_wire1(5, 11)    <= sub_wire3(11);
	sub_wire1(5, 12)    <= sub_wire3(12);
	sub_wire1(5, 13)    <= sub_wire3(13);
	sub_wire1(5, 14)    <= sub_wire3(14);
	sub_wire1(5, 15)    <= sub_wire3(15);
	sub_wire1(4, 0)    <= sub_wire4(0);
	sub_wire1(4, 1)    <= sub_wire4(1);
	sub_wire1(4, 2)    <= sub_wire4(2);
	sub_wire1(4, 3)    <= sub_wire4(3);
	sub_wire1(4, 4)    <= sub_wire4(4);
	sub_wire1(4, 5)    <= sub_wire4(5);
	sub_wire1(4, 6)    <= sub_wire4(6);
	sub_wire1(4, 7)    <= sub_wire4(7);
	sub_wire1(4, 8)    <= sub_wire4(8);
	sub_wire1(4, 9)    <= sub_wire4(9);
	sub_wire1(4, 10)    <= sub_wire4(10);
	sub_wire1(4, 11)    <= sub_wire4(11);
	sub_wire1(4, 12)    <= sub_wire4(12);
	sub_wire1(4, 13)    <= sub_wire4(13);
	sub_wire1(4, 14)    <= sub_wire4(14);
	sub_wire1(4, 15)    <= sub_wire4(15);
	sub_wire1(3, 0)    <= sub_wire5(0);
	sub_wire1(3, 1)    <= sub_wire5(1);
	sub_wire1(3, 2)    <= sub_wire5(2);
	sub_wire1(3, 3)    <= sub_wire5(3);
	sub_wire1(3, 4)    <= sub_wire5(4);
	sub_wire1(3, 5)    <= sub_wire5(5);
	sub_wire1(3, 6)    <= sub_wire5(6);
	sub_wire1(3, 7)    <= sub_wire5(7);
	sub_wire1(3, 8)    <= sub_wire5(8);
	sub_wire1(3, 9)    <= sub_wire5(9);
	sub_wire1(3, 10)    <= sub_wire5(10);
	sub_wire1(3, 11)    <= sub_wire5(11);
	sub_wire1(3, 12)    <= sub_wire5(12);
	sub_wire1(3, 13)    <= sub_wire5(13);
	sub_wire1(3, 14)    <= sub_wire5(14);
	sub_wire1(3, 15)    <= sub_wire5(15);
	sub_wire1(2, 0)    <= sub_wire6(0);
	sub_wire1(2, 1)    <= sub_wire6(1);
	sub_wire1(2, 2)    <= sub_wire6(2);
	sub_wire1(2, 3)    <= sub_wire6(3);
	sub_wire1(2, 4)    <= sub_wire6(4);
	sub_wire1(2, 5)    <= sub_wire6(5);
	sub_wire1(2, 6)    <= sub_wire6(6);
	sub_wire1(2, 7)    <= sub_wire6(7);
	sub_wire1(2, 8)    <= sub_wire6(8);
	sub_wire1(2, 9)    <= sub_wire6(9);
	sub_wire1(2, 10)    <= sub_wire6(10);
	sub_wire1(2, 11)    <= sub_wire6(11);
	sub_wire1(2, 12)    <= sub_wire6(12);
	sub_wire1(2, 13)    <= sub_wire6(13);
	sub_wire1(2, 14)    <= sub_wire6(14);
	sub_wire1(2, 15)    <= sub_wire6(15);
	sub_wire1(1, 0)    <= sub_wire7(0);
	sub_wire1(1, 1)    <= sub_wire7(1);
	sub_wire1(1, 2)    <= sub_wire7(2);
	sub_wire1(1, 3)    <= sub_wire7(3);
	sub_wire1(1, 4)    <= sub_wire7(4);
	sub_wire1(1, 5)    <= sub_wire7(5);
	sub_wire1(1, 6)    <= sub_wire7(6);
	sub_wire1(1, 7)    <= sub_wire7(7);
	sub_wire1(1, 8)    <= sub_wire7(8);
	sub_wire1(1, 9)    <= sub_wire7(9);
	sub_wire1(1, 10)    <= sub_wire7(10);
	sub_wire1(1, 11)    <= sub_wire7(11);
	sub_wire1(1, 12)    <= sub_wire7(12);
	sub_wire1(1, 13)    <= sub_wire7(13);
	sub_wire1(1, 14)    <= sub_wire7(14);
	sub_wire1(1, 15)    <= sub_wire7(15);
	sub_wire1(0, 0)    <= sub_wire8(0);
	sub_wire1(0, 1)    <= sub_wire8(1);
	sub_wire1(0, 2)    <= sub_wire8(2);
	sub_wire1(0, 3)    <= sub_wire8(3);
	sub_wire1(0, 4)    <= sub_wire8(4);
	sub_wire1(0, 5)    <= sub_wire8(5);
	sub_wire1(0, 6)    <= sub_wire8(6);
	sub_wire1(0, 7)    <= sub_wire8(7);
	sub_wire1(0, 8)    <= sub_wire8(8);
	sub_wire1(0, 9)    <= sub_wire8(9);
	sub_wire1(0, 10)    <= sub_wire8(10);
	sub_wire1(0, 11)    <= sub_wire8(11);
	sub_wire1(0, 12)    <= sub_wire8(12);
	sub_wire1(0, 13)    <= sub_wire8(13);
	sub_wire1(0, 14)    <= sub_wire8(14);
	sub_wire1(0, 15)    <= sub_wire8(15);
	result    <= sub_wire9(15 DOWNTO 0);

	parallel_add_component : parallel_add
	GENERIC MAP (
		msw_subtract => "NO",
		pipeline => 0,
		representation => "UNSIGNED",
		result_alignment => "LSB",
		shift => 0,
		size => 8,
		width => 16,
		widthr => 16,
		lpm_type => "parallel_add"
	)
	PORT MAP (
		data => sub_wire1,
		result => sub_wire9
	);



END SYN;

-- ============================================================
-- CNX file retrieval info
-- ============================================================
-- Retrieval info: PRIVATE: INTENDED_DEVICE_FAMILY STRING "Cyclone IV E"
-- Retrieval info: PRIVATE: SYNTH_WRAPPER_GEN_POSTFIX STRING "0"
-- Retrieval info: LIBRARY: altera_mf altera_mf.altera_mf_components.all
-- Retrieval info: CONSTANT: MSW_SUBTRACT STRING "NO"
-- Retrieval info: CONSTANT: PIPELINE NUMERIC "0"
-- Retrieval info: CONSTANT: REPRESENTATION STRING "UNSIGNED"
-- Retrieval info: CONSTANT: RESULT_ALIGNMENT STRING "LSB"
-- Retrieval info: CONSTANT: SHIFT NUMERIC "0"
-- Retrieval info: CONSTANT: SIZE NUMERIC "8"
-- Retrieval info: CONSTANT: WIDTH NUMERIC "16"
-- Retrieval info: CONSTANT: WIDTHR NUMERIC "16"
-- Retrieval info: USED_PORT: data0x 0 0 16 0 INPUT NODEFVAL "data0x[15..0]"
-- Retrieval info: USED_PORT: data1x 0 0 16 0 INPUT NODEFVAL "data1x[15..0]"
-- Retrieval info: USED_PORT: data2x 0 0 16 0 INPUT NODEFVAL "data2x[15..0]"
-- Retrieval info: USED_PORT: data3x 0 0 16 0 INPUT NODEFVAL "data3x[15..0]"
-- Retrieval info: USED_PORT: data4x 0 0 16 0 INPUT NODEFVAL "data4x[15..0]"
-- Retrieval info: USED_PORT: data5x 0 0 16 0 INPUT NODEFVAL "data5x[15..0]"
-- Retrieval info: USED_PORT: data6x 0 0 16 0 INPUT NODEFVAL "data6x[15..0]"
-- Retrieval info: USED_PORT: data7x 0 0 16 0 INPUT NODEFVAL "data7x[15..0]"
-- Retrieval info: USED_PORT: result 0 0 16 0 OUTPUT NODEFVAL "result[15..0]"
-- Retrieval info: CONNECT: @data 1 0 16 0 data0x 0 0 16 0
-- Retrieval info: CONNECT: @data 1 1 16 0 data1x 0 0 16 0
-- Retrieval info: CONNECT: @data 1 2 16 0 data2x 0 0 16 0
-- Retrieval info: CONNECT: @data 1 3 16 0 data3x 0 0 16 0
-- Retrieval info: CONNECT: @data 1 4 16 0 data4x 0 0 16 0
-- Retrieval info: CONNECT: @data 1 5 16 0 data5x 0 0 16 0
-- Retrieval info: CONNECT: @data 1 6 16 0 data6x 0 0 16 0
-- Retrieval info: CONNECT: @data 1 7 16 0 data7x 0 0 16 0
-- Retrieval info: CONNECT: result 0 0 16 0 @result 0 0 16 0
-- Retrieval info: GEN_FILE: TYPE_NORMAL add16DinX.vhd TRUE
-- Retrieval info: GEN_FILE: TYPE_NORMAL add16DinX.inc FALSE
-- Retrieval info: GEN_FILE: TYPE_NORMAL add16DinX.cmp TRUE
-- Retrieval info: GEN_FILE: TYPE_NORMAL add16DinX.bsf FALSE
-- Retrieval info: GEN_FILE: TYPE_NORMAL add16DinX_inst.vhd FALSE
-- Retrieval info: LIB_FILE: altera_mf
