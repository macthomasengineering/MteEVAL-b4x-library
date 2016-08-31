Type=Class
Version=4.2
ModulesStructureVersion=1
B4J=true
@EndOfDesignText@
'**********************************************************************************
'*
'* Codeblock.bas - Compilable blocks of code
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

#Region Revision History
'**********************************************************************************
'* Revision History:
'*
'* No.        Who  Date        Description
'* =====      ===  ==========  ======================================================
'* 1.03       MTE  2016/08/29  - Added support for bitwise operators << >> ~ ^
'*                             - Added internal function Power()
'*                             - Removed Push instructions in DoIIF.  Push was not 
'*                               needed. This caused the error in the Kitchen Sink test 
'*                               case.
'*                             - Prefixed Types with MTE_ to prevent naming conflicts 
'*                               with Type definitions in applications.
'* 1.02       MTE  2016/08/26  - Fixed syntax error bug with parenthetical comma
'*                               expressions 
'*                             - Moved software CPU to local stack to support Codeblock 
'*                               nesting
'*                             - Added support for hexadecimal number format 0xNNNN
'*                             - Added strucural code to support bitwise operators
'*                             - Added syntax error trap for bitwise ops until supported.
'* 1.01       MTE  2016/08/23  - Added #if B4I in Run.bas for Mod operator
'*                             - Added #if B4I and custom ExtractExpressions until 
'*                               we sort out the RegEx difference between B4A and B4I 
'* 1.00       MTE  2016/08/23  - Preparing for release
'* 0.01       MTE  2016/08/11  - Begin here!
'*
'*
'**********************************************************************************
#End Region

Sub Class_Globals

	Private Bytecode As List 
	Public Text As String
	Public Error As Int 
	Public ErrorDesc As String 
	Public ErrorDetail As String 
		
	' Errors
	Public Const ERROR_NONE              =  0 As Int
	Public Const ERROR_SYNTAX            =  1 As Int
	Public Const ERROR_MISSING_BRACKET   =  2 As Int
	Public Const ERROR_MISSING_PIPE      =  3 As Int
	Public Const ERROR_MISSING_PAREN     =  4 As Int
	Public Const ERROR_MISSING_COMMA     =  5 As Int
	Public Const ERROR_MISSING_ARG       =  6 As Int
	Public Const ERROR_NOT_A_VAR         =  7 As Int
	Public Const ERROR_MISSING_PARAM     =  8 As Int
	Public Const ERROR_MISSING_EXPR      =  9 As Int
	Public Const ERROR_RESERVED_WORD     = 10 As Int
	Public Const ERROR_TOO_MANY_ARGS     = 11 As Int
	Public Const ERROR_UNBALANCED_PARENS = 12 As Int
	Public Const ERROR_PUTBACK           = 13 As Int
	Public Const ERROR_UNSUPPORTED_OPER  = 14 As Int
	Public Const ERROR_NO_CODE           = 20 As Int
	Public Const ERROR_ILLEGAL_CODE      = 21 As Int
	Public Const ERROR_INSUFFICIENT_ARGS = 22 As Int
	Public Const ERROR_STACK_OVERFLOW    = 23 As Int
	Public Const ERROR_DIVIDE_BY_ZERO    = 24 As Int
	Public Const ERROR_ARG_NOT_NUMBER    = 25 As Int
	Public Const ERROR_OTHER             = 33 As Int

	Private VersionText="1.03" As String
	
End Sub

'-------------------------------------------------
' Initialize Codeblock
'
'
'
Public Sub Initialize

	Text = ""	
	Error = ERROR_NONE
	ErrorDesc = ""
	ErrorDetail = "" 
		
End Sub

'-------------------------------------------------
' Compile expression into Codeblock
'
' Example:  Dim cb as Codeblock
'           error = cb.Compile( "{||3+8}" )
'
Public Sub Compile( sCodeblock As String )  As Int
	Private nResult As Int

	' Reset code and error
	Bytecode.Initialize
	Error = ERROR_NONE
	ErrorDesc = ""
	ErrorDetail = "" 

	' Store codeblock in text form 
	Text = sCodeblock

	' Compile the codeblock		
	nResult = Codegen.CompileCodeBlock( Me, Bytecode ) 
		
	Return ( nResult )		
	
End Sub

'-------------------------------------------------
' Evaulate a Codeblock
'
' Example:  Dim cb as Codeblock
'           error  = cb.Compile( "{||3+8}" )
'           result = cb.Eval
'
Public Sub Eval As Double
	Private nResult As Double  'ignore
	Private aArgs() As Object
	
	nResult = Run.Execute( Me, Bytecode, aArgs )
	
	Return ( nResult )
End Sub

'-------------------------------------------------
' Evaulate a Codeblock with parameters
'
' Example:  Dim cb as CodeBlock
'           error = cb.Compile( "{|a,b|3*a+8*b}" )
'           result = cb.Eval2( Array( 6, 10 ) )
'
Public Sub Eval2( aArgs() As Object ) As Double
	Private nResult As Double  'ignore
	
	nResult = Run.Execute(  Me, Bytecode, aArgs )
	
	Return ( nResult )
End Sub

'-------------------------------------------------
' Decompile Codeblock
'
' Example:  Dim cb as CodeBlock
'           Dim Decode as List
'           error = cb.Compile( "{|a,b|3*a+8*b}" )
'           Decode = cb.Decompile
'
Public Sub Decompile As List
	Private Decode As List
	Decode.Initialize
	Run.Dump(  Me, Bytecode, Decode )
	Return ( Decode )
End Sub

'-------------------------------------------------
' Version of MteEval library
'
'
'
Public Sub Version As String
	Return ( VersionText )
End Sub


