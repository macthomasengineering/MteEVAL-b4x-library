Type=StaticCode
Version=2.8
ModulesStructureVersion=1
B4i=true
@EndOfDesignText@
'**********************************************************************************
'*
'* Pcode.bas -  OP codes
'*
'**********************************************************************************

#Region BSD License
'**********************************************************************************
'*
'* Copyright (c) 2016-2017, MacThomas Engineering
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

    ' Null pcode
    Public Const NONE                =  0 As Int

    ' Stack
    Public Const PUSH                =  1 As Int
    Public Const PUSHVAR             =  2 As Int
    Public Const PUSHCONST           =  3 As Int

    ' Load and store
    Public Const LOADCONST           =  4 As Int
    Public Const LOADVAR             =  5 As Int
    Public Const STOREVAR            =  6 As Int

    ' Math
    Public Const NEG                 =  7 As Int
    Public Const ADD                 =  8 As Int
    Public Const SUBTRACT            =  9 As Int
    Public Const DIVIDE              = 10 As Int
    Public Const MULTIPLY            = 11 As Int
    Public Const MODULO              = 12 As Int

    ' Relational
    Public Const EQUAL               = 13 As Int
    Public Const NOT_EQUAL           = 14 As Int
    Public Const LESS_THAN           = 15 As Int
    Public Const LESS_EQUAL          = 16 As Int
    Public Const GREATER_THAN        = 17 As Int
    Public Const GREATER_EQUAL       = 18 As Int

    ' Logical
    Public Const LOGICAL_OR          = 19 As Int
    Public Const LOGICAL_AND         = 20 As Int
    Public Const LOGICAL_NOT         = 21 As Int

    ' Jumps
    Public Const JUMP_ALWAYS         = 22 As Int
    Public Const JUMP_FALSE          = 23 As Int
    Public Const JUMP_TRUE           = 24 As Int

    ' Bitwise
    Public Const BIT_AND             = 25 As Int
    Public Const BIT_OR              = 26 As Int
    Public Const BIT_XOR             = 27 As Int
    Public Const BIT_NOT             = 28 As Int
    Public Const BIT_SHIFT_LEFT      = 29 As Int
    Public Const BIT_SHIFT_RIGHT     = 30 As Int

    ' Internal functions
    Public Const FUNC_IIF            = 31 As Int
    Public Const FUNC_ABS            = 32 As Int
    Public Const FUNC_MAX            = 33 As Int
    Public Const FUNC_MIN            = 34 As Int
    Public Const FUNC_SQRT           = 35 As Int
    Public Const FUNC_POWER          = 36 As Int
    Public Const FUNC_ROUND          = 37 As Int
    Public Const FUNC_FLOOR          = 38 As Int
    Public Const FUNC_CEIL           = 39 As Int
    Public Const FUNC_COS            = 40 As Int
    Public Const FUNC_COSD           = 41 As Int
    Public Const FUNC_SIN            = 42 As Int
    Public Const FUNC_SIND           = 43 As Int
    Public Const FUNC_TAN            = 44 As Int
    Public Const FUNC_TAND           = 45 As Int
    Public Const FUNC_ACOS           = 46 As Int
    Public Const FUNC_ACOSD          = 47 As Int
    Public Const FUNC_ASIN           = 48 As Int
    Public Const FUNC_ASIND          = 49 As Int
    Public Const FUNC_ATAN           = 50 As Int
    Public Const FUNC_ATAND          = 51 As Int
    Public Const FUNC_NUMBER_FORMAT  = 52 As Int
    Public Const FUNC_AVG            = 53 As Int

	' End code
    Public Const ENDCODE             = 54 As Int

End Sub