-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- 
-- =============================================================================
-- Authors:					Patrick Lehmann
--
-- Module:					Sorting Network: Odd-Even-Merge-Sort
--
-- Description:
-- ------------------------------------
--	TODO
--
-- License:
-- =============================================================================
-- Copyright 2007-2016 Technische Universitaet Dresden - Germany
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
-- =============================================================================

library IEEE;
use			IEEE.STD_LOGIC_1164.all;
use			IEEE.NUMERIC_STD.all;

library PoC;
use			PoC.math.all;
use			PoC.utils.all;
use			PoC.vectors.all;
use			PoC.components.all;


entity sortnet_OddEvenMergeSort is
	generic (
		INPUTS								: POSITIVE	:= 8;
		KEY_BITS							: POSITIVE	:= 32;
		DATA_BITS							: POSITIVE	:= 32;
		META_BITS							: NATURAL		:= 2;
		PIPELINE_STAGE_AFTER	: NATURAL		:= 2;
		ADD_INPUT_REGISTERS		: BOOLEAN		:= FALSE;
		ADD_OUTPUT_REGISTERS	: BOOLEAN		:= TRUE
	);
	port (
		Clock				: in	STD_LOGIC;
		Reset				: in	STD_LOGIC;
		
		Inverse			: in	STD_LOGIC		:= '0';
		
		In_Valid		: in	STD_LOGIC;
		In_IsKey		: in	STD_LOGIC;
		In_Data			: in	T_SLM(INPUTS - 1 downto 0, DATA_BITS - 1 downto 0);
		In_Meta			: in	STD_LOGIC_VECTOR(META_BITS - 1 downto 0);
		
		Out_Valid		: out	STD_LOGIC;
		Out_IsKey		: out	STD_LOGIC;
		Out_Data		: out	T_SLM(INPUTS - 1 downto 0, DATA_BITS - 1 downto 0);
		Out_Meta		: out	STD_LOGIC_VECTOR(META_BITS - 1 downto 0)
	);
end entity;


architecture rtl of sortnet_OddEvenMergeSort is
	constant C_VERBOSE				: BOOLEAN			:= POC_VERBOSE;

	constant BLOCKS						: POSITIVE		:= log2ceil(INPUTS);
	constant STAGES						: POSITIVE		:= triangularNumber(BLOCKS);
	
	constant META_VALID_BIT		: NATURAL			:= 0;
	constant META_ISKEY_BIT		: NATURAL			:= 1;
	constant META_VECTOR_BITS	: POSITIVE		:= META_BITS + 2;
	
	subtype T_META				is STD_LOGIC_VECTOR(META_VECTOR_BITS - 1 downto 0);
	type		T_META_VECTOR	is array(NATURAL range <>) of T_META;
	
	subtype	T_DATA				is STD_LOGIC_VECTOR(DATA_BITS - 1 downto 0);
	type		T_DATA_VECTOR	is array(NATURAL range <>) of T_DATA;
	type		T_DATA_MATRIX	is array(NATURAL range <>) of T_DATA_VECTOR(INPUTS - 1 downto 0);

	function to_dv(slm : T_SLM) return T_DATA_VECTOR is
		variable Result	: T_DATA_VECTOR(slm'range(1));
	begin
		for i in slm'range(1) loop
			for j in slm'high(2) downto slm'low(2) loop
				Result(i)(j)	:= slm(i, j);
			end loop;
		end loop;
		return Result;
	end function;
	
	function to_slm(dv : T_DATA_VECTOR) return T_SLM is
		variable Result	: T_SLM(dv'range, T_DATA'range);
	begin
		for i in dv'range loop
			for j in T_DATA'range loop
				Result(i, j)	:= dv(i)(j);
			end loop;
		end loop;
		return Result;
	end function;
	
	signal In_Valid_d			: STD_LOGIC																						:= '0';
	signal In_IsKey_d			: STD_LOGIC																						:= '0';
	signal In_Data_d			: T_SLM(INPUTS - 1 downto 0, DATA_BITS - 1 downto 0)	:= (others => (others => '0'));
	signal In_Meta_d			: STD_LOGIC_VECTOR(META_BITS - 1 downto 0)						:= (others => '0');
	
	signal MetaVector			: T_META_VECTOR(STAGES downto 0)											:= (others => (others => '0'));
	signal DataMatrix			: T_DATA_MATRIX(STAGES downto 0)											:= (others => (others => (others => '0')));
	
	signal MetaOutputs_d	: T_META																							:= (others => '0');
	signal DataOutputs_d	: T_SLM(INPUTS - 1 downto 0, DATA_BITS - 1 downto 0)	:= (others => (others => '0'));
	
begin
	assert (not C_VERBOSE)
		report "sortnet_OddEvenMergeSort:" & CR &
					 "  DATA_BITS=" & INTEGER'image(DATA_BITS) &
					 "  KEY_BITS=" & INTEGER'image(KEY_BITS) &
					 "  META_BITS=" & INTEGER'image(META_BITS)
		severity NOTE;
	
	In_Valid_d	<= In_Valid	when registered(Clock, ADD_INPUT_REGISTERS);
	In_IsKey_d	<= In_IsKey	when registered(Clock, ADD_INPUT_REGISTERS);
	In_Data_d		<= In_Data	when registered(Clock, ADD_INPUT_REGISTERS);
	In_Meta_d		<= In_Meta	when registered(Clock, ADD_INPUT_REGISTERS);
	
	DataMatrix(0)																														<= to_dv(In_Data_d);
	MetaVector(0)(META_VALID_BIT)																						<= In_Valid_d;
	MetaVector(0)(META_ISKEY_BIT)																						<= In_IsKey_d;
	MetaVector(0)(META_VECTOR_BITS - 1 downto META_VECTOR_BITS - META_BITS)	<= In_Meta_d;
	
  genBlocks : for b in 0 to BLOCKS - 1 generate
		constant GROUPS	: POSITIVE		:= 2 ** (BLOCKS - b - 1);
	begin
		genGroups : for g in 0 to GROUPS - 1 generate
			genStages : for s in 0 to b generate
				constant DISTANCE									: POSITIVE	:= 2 ** (b-s);
				constant STAGE_INDEX							: NATURAL		:= triangularNumber(b) + s;
				constant INSERT_PIPELINE_REGISTER	: BOOLEAN		:= (PIPELINE_STAGE_AFTER /= 0) and (STAGE_INDEX mod PIPELINE_STAGE_AFTER = 0);
				constant START_INDEX							: NATURAL		:= ite((s = 0), 0, DISTANCE);
				constant END_INDEX								: NATURAL		:= ((2**(b+1))-DISTANCE-START_INDEX-1) / (2 * DISTANCE);
				constant SRC											: NATURAL		:= (g * (INPUTS / GROUPS));
			begin
				MetaVector(STAGE_INDEX + 1)		<= MetaVector(STAGE_INDEX) when registered(Clock, INSERT_PIPELINE_REGISTER);
			
				genJ0 : for j in 0 to START_INDEX - 1 generate
					assert (not C_VERBOSE) report INTEGER'image(STAGE_INDEX) & " passthrough: " & INTEGER'image(SRC + j) severity NOTE;
					DataMatrix(STAGE_INDEX + 1)(SRC + j)		<= DataMatrix(STAGE_INDEX)(SRC + j)	when registered(Clock, INSERT_PIPELINE_REGISTER);
				end generate;
				genJ1 : for j in 0 to END_INDEX generate
					constant K		: POSITIVE		:= (j * 2 * DISTANCE) + START_INDEX;
				begin
					genLoop : for i in 0 to DISTANCE - 1 generate
						constant SRC0	: NATURAL		:= SRC + K + i;
						constant SRC1	: NATURAL		:= SRC0 + DISTANCE;
						
						signal Greater		: STD_LOGIC;
						signal Switch_d		: STD_LOGIC;
						signal Switch_en	: STD_LOGIC;
						signal Switch_r		: STD_LOGIC		:= '0';
						signal Switch			: STD_LOGIC;
						signal NewData0		: T_DATA;
						signal NewData1		: T_DATA;
					begin
						assert (not C_VERBOSE) report INTEGER'image(STAGE_INDEX) & "     compare: " & INTEGER'image(SRC0) & " <-> " & INTEGER'image(SRC1) severity NOTE;
	
						Greater		<= to_sl(unsigned(DataMatrix(STAGE_INDEX)(SRC0)(KEY_BITS - 1 downto 0)) > unsigned(DataMatrix(STAGE_INDEX)(SRC1)(KEY_BITS - 1 downto 0)));
						Switch_d	<= Greater xor Inverse;
						Switch_en	<= MetaVector(STAGE_INDEX)(META_ISKEY_BIT) and MetaVector(STAGE_INDEX)(META_VALID_BIT);
						Switch_r	<= ffdre(q => Switch_r, d => Switch_d, en => Switch_en) when rising_edge(Clock);
						Switch		<= mux(Switch_en, Switch_r, Switch_d);
		
						NewData0		<= mux(Switch, DataMatrix(STAGE_INDEX)(SRC0), DataMatrix(STAGE_INDEX)(SRC1));
						NewData1		<= mux(Switch, DataMatrix(STAGE_INDEX)(SRC1), DataMatrix(STAGE_INDEX)(SRC0));
		
						DataMatrix(STAGE_INDEX + 1)(SRC0)		<= NewData0	when registered(Clock, INSERT_PIPELINE_REGISTER);
						DataMatrix(STAGE_INDEX + 1)(SRC1)		<= NewData1	when registered(Clock, INSERT_PIPELINE_REGISTER);
					end generate;
				end generate;
				genJ2 : for j in (((END_INDEX * 2 * DISTANCE) + START_INDEX) + 2*DISTANCE) to (INPUTS / GROUPS) - 1 generate
					assert (not C_VERBOSE) report INTEGER'image(STAGE_INDEX) & " passthrough: " & INTEGER'image(SRC + j) severity NOTE;
					DataMatrix(STAGE_INDEX + 1)(SRC + j)		<= DataMatrix(STAGE_INDEX)(SRC + j)	when registered(Clock, INSERT_PIPELINE_REGISTER);
				end generate;
			end generate;
		end generate;
	end generate;
	
	MetaOutputs_d		<= MetaVector(STAGES)					when registered(Clock, ADD_OUTPUT_REGISTERS);
	DataOutputs_d		<= to_slm(DataMatrix(STAGES))	when registered(Clock, ADD_OUTPUT_REGISTERS);
	
	Out_Valid				<= MetaOutputs_d(META_VALID_BIT);
	Out_IsKey				<= MetaOutputs_d(META_ISKEY_BIT);
	Out_Data				<= DataOutputs_d;
	Out_Meta				<= MetaOutputs_d(META_VECTOR_BITS - 1 downto META_VECTOR_BITS - META_BITS);
end architecture;
