-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- 
-- ============================================================================
-- Authors:					Martin Zabel
--									Patrick Lehmann
--
-- Module:				 	Instantiate enhanced simple dual-port memory on Altera 
--									FPGAs.
-- 
-- Description:
-- ------------------------------------
-- Quartus synthesis does not infer this RAM type correctly.
-- Instead, altsyncram is instantiated directly.
--
-- For further documentation see module "ocram_esdp" 
-- (src/mem/ocram/ocram_esdp.vhdl).
--
-- License:
-- ============================================================================
-- Copyright 2008-2015 Technische Universitaet Dresden - Germany
--										 Chair for VLSI-Design, Diagnostics and Architecture
-- 
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
-- 
--		http://www.apache.org/licenses/LICENSE-2.0
-- 
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
-- ============================================================================

library	IEEE;
use			IEEE.std_logic_1164.all;
use			IEEE.numeric_std.all;

library	altera_mf;
use			altera_mf.all;

library PoC;
use			PoC.utils.all;
use			PoC.strings.all;


entity ocram_esdp_altera is
	generic (
		A_BITS		: positive;
		D_BITS		: positive;
		FILENAME	: STRING		:= ""
	);
	port (
		clk1 : in	std_logic;
		clk2 : in	std_logic;
		ce1	: in	std_logic;
		ce2	: in	std_logic;
		we1	: in	std_logic;
		a1	 : in	unsigned(A_BITS-1 downto 0);
		a2	 : in	unsigned(A_BITS-1 downto 0);
		d1	 : in	std_logic_vector(D_BITS-1 downto 0);
		q1	 : out std_logic_vector(D_BITS-1 downto 0);
		q2	 : out std_logic_vector(D_BITS-1 downto 0)
	);
end ocram_esdp_altera;


architecture rtl of ocram_esdp_altera is
	component altsyncram
		generic (
			address_aclr_a						: STRING;
			address_aclr_b						: STRING;
			address_reg_b							: STRING;
			indata_aclr_a							: STRING;
			indata_aclr_b							: STRING;
			indata_reg_b							: STRING;
			init_file									: STRING;
			intended_device_family		: STRING;
			lpm_type									: STRING;
			numwords_a								: NATURAL;
			numwords_b								: NATURAL;
			operation_mode						: STRING;
			outdata_aclr_a						: STRING;
			outdata_aclr_b						: STRING;
			outdata_reg_a							: STRING;
			outdata_reg_b							: STRING;
			power_up_uninitialized		: STRING;
			widthad_a									: NATURAL;
			widthad_b									: NATURAL;
			width_a										: NATURAL;
			width_b										: NATURAL;
			width_byteena_a						: NATURAL;
			width_byteena_b						: NATURAL;
			wrcontrol_aclr_a					: STRING;
			wrcontrol_aclr_b					: STRING;
			wrcontrol_wraddress_reg_b : STRING
		);
		port (
			clocken0	: in	STD_LOGIC;
			clocken1	: in	STD_LOGIC;
			wren_a		: in	STD_LOGIC;
			clock0		: in	STD_LOGIC;
			wren_b		: in	STD_LOGIC;
			clock1		: in	STD_LOGIC;
			address_a : in	STD_LOGIC_VECTOR (widthad_a-1 downto 0);
			address_b : in	STD_LOGIC_VECTOR (widthad_b-1 downto 0);
			q_a				: out STD_LOGIC_VECTOR (width_a-1 downto 0);
			q_b				: out STD_LOGIC_VECTOR (width_b-1 downto 0);
			data_a		: in	STD_LOGIC_VECTOR (width_a-1 downto 0);
			data_b		: in	STD_LOGIC_VECTOR (width_b-1 downto 0)
		);
	end component;

	constant DEPTH			: positive	:= 2**A_BITS;
	constant INIT_FILE	: STRING		:= ite((str_length(FILENAME) = 0), "UNUSED", FILENAME);

	signal a1_sl : std_logic_vector(A_BITS-1 downto 0);
	signal a2_sl : std_logic_vector(A_BITS-1 downto 0);

begin

	a1_sl <= std_logic_vector(a1);
	a2_sl <= std_logic_vector(a2);
	
	mem : altsyncram
		generic map (
			address_aclr_a						=> "NONE",
			address_aclr_b						=> "NONE",
			address_reg_b							=> "CLOCK1",
			indata_aclr_a							=> "NONE",
			indata_aclr_b							=> "NONE",
			indata_reg_b							=> "CLOCK1",
			init_file									=> INIT_FILE,
			intended_device_family		=> "Stratix",
			lpm_type									=> "altsyncram",
			numwords_a								=> DEPTH,
			numwords_b								=> DEPTH,
			operation_mode						=> "BIDIR_DUAL_PORT",
			outdata_aclr_a						=> "NONE",
			outdata_aclr_b						=> "NONE",
			outdata_reg_a							=> "UNREGISTERED",
			outdata_reg_b							=> "UNREGISTERED",
			power_up_uninitialized		=> "FALSE",
			widthad_a									=> A_BITS,
			widthad_b									=> A_BITS,
			width_a										=> D_BITS,
			width_b										=> D_BITS,
			width_byteena_a						=> 1,
			width_byteena_b						=> 1,
			wrcontrol_aclr_a					=> "NONE",
			wrcontrol_aclr_b					=> "NONE",
			wrcontrol_wraddress_reg_b	=> "CLOCK1"
		)
		port map (
			clock0										=> clk1,
			clock1										=> clk2,
			clocken0									=> ce1,
			clocken1									=> ce2,
			wren_a										=> we1,
			wren_b										=> '0',
			address_a									=> a1_sl,
			address_b									=> a2_sl,
			data_a										=> d1,
			data_b										=> (others => '0'),
			q_a												=> q1,
			q_b												=> q2
		);
end rtl;
