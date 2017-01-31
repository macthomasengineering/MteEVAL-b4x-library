Type=Class
Version=4.7
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

#Region Revision History
'**********************************************************************************
'* Revision History:
'*
'* No.        Who  Date        Description
'* =====      ===  ==========  ======================================================
'* 1.06.0     MTE  2017/01/30  - Added peephole optimization to PUSH, LOADVAR, and 
'*                               LOADCONST
'*                             - Optimized bytecode and constants into fixed length 
'*                               arrays
'*                             - Renumbered pcodes and grouped instructions in Run.bas
'*                               to workaround B4X select/case performance.
'*                             - Removed pop instruction from bitwise not
'* 1.04.3     MTE  2016/10/11  - Removed Mtelog from B4J library. B4A and B4I ok.
'* 1.04.2     MTE  2016/10/09  - Added trig functions, round(), floor(), and ceil().
'*                             - Replaced FindInternalFunc case statement with a
'*                               lookup table.
'*                             - Added support for variable assignments.
'* 1.03       MTE  2016/08/30  - Added support for bitwise operators << >> ~ ^
'*                             - Added internal function Power()
'*                             - Removed Push instructions in DoIIF.  Push was not 
'*                               needed. This caused the error in the Kitchen Sink test 
'*                               case.
'*                             - Prefixed Types with MTE_ to prevent naming conflicts 
'*                               with Type definitions in applications.
'* 1.02       MTE  2016/08/26  - Fixed syntax error bug with parenthetical expression
'*                               lists. 
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

	Private Code As MTE_CODE
	Public Text As String
	Public Error As Int 
	Public ErrorDesc As String 
	Public ErrorDetail As String 
	Public OptimizerEnabled=True As Boolean

	Private VersionText="1.06.0" As String
	
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
' Compile expression into a Codeblock
'
' Example:  Dim cb as Codeblock
'           cb.Initialize
'           error = cb.Compile( "{||3+8}" )
'
Public Sub Compile( sCodeblock As String )  As Int
	Private nResult As Int

	' Reset code and error
	Code.Initialize
	Error = ERROR_NONE
	ErrorDesc = ""
	ErrorDetail = "" 

	' Store codeblock in text form 
	Text = sCodeblock
	
	' Compile the codeblock		
	nResult = Codegen.CompileCodeBlock( Me, Code ) 
		
	Return ( nResult )		
	
End Sub

'-------------------------------------------------
' Evaulate a Codeblock
'
' Example:  Dim cb as Codeblock
'           cb.Initialize
'           error  = cb.Compile( "{||3+8}" )
'           result = cb.Eval
'
Public Sub Eval As Double
	Private nResult As Double  'ignore
	Private aArgs() As Object
	
	nResult = Run.Execute( Me, Code, aArgs )
	
	Return ( nResult )
End Sub

'-------------------------------------------------
' Evaulate a Codeblock with parameters
'
' Example:  Dim cb as CodeBlock
'           cb.Initialize
'           error = cb.Compile( "{|a,b|3*a+8*b}" )
'           result = cb.Eval2( Array( 6, 10 ) )
'
Public Sub Eval2( aArgs() As Object ) As Double
	Private nResult As Double  'ignore
	
	nResult = Run.Execute(  Me, Code, aArgs )
	
	Return ( nResult )
End Sub

'-------------------------------------------------
' Decompile a Codeblock
'
' Example:  Dim cb as CodeBlock
'           Dim Decode as List
'           cb.Initialize
'           error = cb.Compile( "{|a,b|3*a+8*b}" )
'           Decode = cb.Decompile
'
Public Sub Decompile As List
	Private Decode As List
	Decode.Initialize
	Run.Dump(  Me, Code, Decode )
	Return ( Decode )
End Sub

'-------------------------------------------------
' Version of MteEval library
'
'
Public Sub getVersion As String
	Return ( VersionText )
End Sub

'-------------------------------------------------
' Optimizer status
'
Public Sub getDisableOptimizations As Boolean 
	Return ( Not( OptimizerEnabled ) )
End Sub

'-------------------------------------------------
' Disable or enable the optimizer 
'
Public Sub setDisableOptimizations( bDisable As Boolean )
	OptimizerEnabled = Not( bDisable ) 
End Sub


Public Sub getText As String
	Return ( Text )
End Sub

Public Sub getError As Int 
	Return ( Error )
End Sub	

Public Sub getErrorDesc As String 
	Return ( ErrorDesc )
End Sub

Public Sub getErrorDetail As String 
	Return ( ErrorDetail )
End Sub
