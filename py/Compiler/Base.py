# EMACS settings: -*-	tab-width: 2; indent-tabs-mode: t -*-
# vim: tabstop=2:shiftwidth=2:noexpandtab
# kate: tab-width 2; replace-tabs off; indent-width 2;
# 
# ==============================================================================
# Authors:				 	Patrick Lehmann
# 
# Python Class:			Base class for all PoC***Compilers
# 
# Description:
# ------------------------------------
#		TODO:
#		- 
#		- 
#
# License:
# ==============================================================================
# Copyright 2007-2015 Technische Universitaet Dresden - Germany
#											Chair for VLSI-Design, Diagnostics and Architecture
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#		http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# ==============================================================================

# entry point
if __name__ != "__main__":
	# place library initialization code here
	pass
else:
	from lib.Functions import Exit
	Exit.printThisIsNoExecutableFile("The PoC-Library - Python Class PoCCompiler")

# load dependencies
from Base.Exceptions import *
from Compiler.Exceptions import *

class PoCCompiler(object):
	# private fields
	__host =				None
	__debug =				False
	__verbose =			False
	__quiet =				False
	__showLogs =		False
	__showReport =	False
	__dryRun =			False

	def __init__(self, host, showLogs, showReport):
		self.__host =				host
		
		self.__debug =			host.debug
		self.__verbose =		host.verbose
		self.__quiet =			host.quiet
		self.__showLogs =		showLogs
		self.__showReport =	showReport

	# class properties
	# ============================================================================
	@property
	def host(self):				return self.__host
	
	@property
	def debug(self):			return self.__debug
	
	@property
	def verbose(self):		return self.__verbose
	
	@property
	def quiet(self):			return self.__quiet
	
	@property
	def showLogs(self):		return self.__showLogs
	
	@property
	def showReport(self):	return self.__showReport
	
	# print messages
	# ============================================================================
	def printDebug(self, message):
		if (self.debug):
			print("DEBUG: " + message)
	
	def printVerbose(self, message):
		if (self.verbose):
			print(message)
	
	def printNonQuiet(self, message):
		if (not self.quiet):
			print(message)
