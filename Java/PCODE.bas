Type=StaticCode
Version=4.5
ModulesStructureVersion=1
B4J=true
@EndOfDesignText@
'**********************************************************************************
'*
'* Pcode.bas -  OP codes
'*
'**********************************************************************************

#Region BSD License
'**********************************************************************************
'*
'* Copyright (c) 2016, MacThomas Engineering
'* All rights reserved.
'*
'* You may use this file under the terms of the BSD license as follows:
'*
'* Redistribution and use in source and binary forms, with or without
'* modification, are permitted provided that the following conditions are met:
'*
'* 1. Redistributions of source code must retain the above copyright notice, this
'*    list of conditions, and the following disclaimer.
'*
'* 2. Redistributions in binary form must reproduce the above copyright notice,
'*    this list of conditions and the following disclaimer in the documentation
'*    and/or other materials provided with the distribution.
'*
'* 3. MacThomas Engineering may not be used to endorse or promote products derived 
'*    from this software without specific prior written permission.
'*
'* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
'* ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
'* WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
'* DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
'* ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
'* (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
'* LOSS OF USE, DATA, Or PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED And
'* ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
'* (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
'* SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
'*
'**********************************************************************************
#End Region

Sub Process_Globals

	' Stack
	Public Const PUSH          =  1 As Int
	Public Const PUSHVAR       =  2 As Int
	Public Const PUSHCONST     =  3 As Int
	
	' Math
	Public Const NEG           =  4 As Int 
	Public Const ADD           =  5 As Int 
	Public Const SUBTRACT      =  6 As Int 
	Public Const DIVIDE        =  7 As Int 
	Public Const MULTIPLY      =  8 As Int 
	Public Const MODULO        =  9 As Int

	' Logical
	Public Const LOGICAL_OR    = 10 As Int
	Public Const LOGICAL_AND   = 11 As Int
	Public Const LOGICAL_NOT   = 12 As Int

	' Relational 
	Public Const EQUAL         = 13 As Int
	Public Const NOT_EQUAL     = 14 As Int
	Public Const LESS_THAN     = 15 As Int
	Public Const LESS_EQUAL    = 16 As Int
	Public Const GREATER_THAN  = 17 As Int
	Public Const GREATER_EQUAL = 18 As Int
	
	' Bitwise
	Public Const BIT_AND         = 21 As Int
	Public Const BIT_OR          = 22 As Int
	Public Const BIT_XOR         = 23 As Int
	Public Const BIT_NOT         = 24 As Int
	Public Const BIT_SHIFT_LEFT  = 25 As Int
	Public Const BIT_SHIFT_RIGHT = 26 As Int
	
	' Jumps
	Public Const JUMP_ALWAYS   = 30 As Int 
	Public Const JUMP_FALSE    = 31 As Int 
	Public Const JUMP_TRUE     = 32 As Int 

	' Load and store
	Public Const LOADCONST     = 40 As Int
	Public Const LOADVAR       = 41 As Int
	Public Const STOREVAR      = 42 As Int

	' Internal functions
	Public Const FUNC_ABS      = 50 As Int 
	Public Const FUNC_IIF      = 51 As Int
	Public Const FUNC_MAX      = 52 As Int
	Public Const FUNC_MIN      = 53 As Int
	Public Const FUNC_SQRT     = 54 As Int
	Public Const FUNC_POWER    = 55 As Int
	Public Const FUNC_ROUND    = 56 As Int
	Public Const FUNC_FLOOR    = 57 As Int
	Public Const FUNC_CEIL     = 58 As Int
	Public Const FUNC_COS      = 59 As Int
	Public Const FUNC_COSD     = 60 As Int 
	Public Const FUNC_SIN      = 61 As Int 
	Public Const FUNC_SIND     = 62 As Int 
	Public Const FUNC_TAN      = 63 As Int
	Public Const FUNC_TAND     = 64 As Int
	Public Const FUNC_ACOS     = 65 As Int
	Public Const FUNC_ACOSD    = 66 As Int 
	Public Const FUNC_ASIN     = 67 As Int 
	Public Const FUNC_ASIND    = 68 As Int 
	Public Const FUNC_ATAN     = 69 As Int 
	Public Const FUNC_ATAND    = 70 As Int 

	' End code
	Public Const ENDCODE       = 100 As Int
			
End Sub