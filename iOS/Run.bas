Type=StaticCode
Version=2.8
ModulesStructureVersion=1
B4i=true
@EndOfDesignText@
'**********************************************************************************
'*
'* Run.bas - Execute code
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

	' Budget
	Private Const STACK_SIZE=100 As Int   'ignore
	Private Const MEMORY_SIZE=20 As Int   'ignore

	' Global reference to Codeblock
	Private gCodeBlock As Codeblock

	' Virtual Machine
	Private nAX=0 As Double                    ' Accumlator 
	Private nIP=0 As Int                       ' Instruction pointer
	Private nSP=0 As Int                       ' Stack pointer
	Private aStack( STACK_SIZE ) As Double     ' Stack
	
	' Variable memory storage (Parameters stored here)
	Private aVarMemory( MEMORY_SIZE )  As Double
	
	Private Const CODE_HEADER_PARAM_COUNT = 0 As Int  'ignore
	Private Const CODE_STARTS_HERE        = 1 As Int  'ignore 
				
End Sub

'*--------------------------------------------------------------- Execute
'*
Public Sub Execute( oCodeBlock As Codeblock, Bytecode As List, aArgs() As Object ) As Double
	Private nRetVal As Double 
	Private nParamCount As Int
	Private nArgIndex As Int

	
	' Set global reference to Codeblock 
	gCodeBlock = oCodeBlock 

	' Attempt to run before compiling?	Compile error?
	If ( Bytecode.Size = 0 ) Then 
		SetError( gCodeBlock.ERROR_NO_CODE, "Check compile error." )
		Return ( 0 )
	End If
	
	 ' Get parameter count
	 nParamCount = Bytecode.Get( CODE_HEADER_PARAM_COUNT ) 
	 
	 ' Invalid number of parameters?  Return error
	 If ( nParamCount > aArgs.Length ) Then 
		SetError( gCodeBlock.ERROR_INSUFFICIENT_ARGS, "Expecting " & nParamCount & " arguments." )
		Return ( 0 ) 		
	End If
	
	' Store parameters
	If ( nParamCount > 0 ) Then 
		
		' Store parameter values in variable memory 
		For nArgIndex = 0 To nParamCount - 1
			
			' Validate parameter is a number
			If ( IsNumber( aArgs( nArgIndex )) = False  ) Then 
				SetError( gCodeBlock.ERROR_ARG_NOT_NUMBER, "Argument #" & nArgIndex & "not a number." )
				Return ( 0 ) 		
			End If
			aVarMemory( nArgIndex ) = aArgs( nArgIndex )		

		Next

	End If 
		 
	' Run code	
	nRetVal = ExecuteCode( Bytecode ) 
	
	Return ( nRetVal ) 
	
End Sub

'*----------------------------------------------------------- ExecuteCode
'*
Private Sub ExecuteCode( Code As List ) As Double
	Private nPcode As Int
	Private bRun=True As Boolean 
	Private nRetVal=0 As Double
	Private nValue As Double
	
	' Set instruction pointer 
	nIP = CODE_STARTS_HERE
			
	Do While ( bRun ) 

		' Get op code	
		nPcode = Code.Get( nIP ) 

		' Execute
		Select ( nPcode ) 

		Case PCODE.PUSH

			' Advance stack pointer and store
			nSP = nSP + 1 

			' Overlfow?				
			If ( nSP >= STACK_SIZE ) Then
				StackOverFlowError
				Return ( 0 ) 
			End If
			
			aStack( nSP ) = nAX 
			
			'Mtelog.Dbg( "<--- Push AX=" & nAX )

	    Case PCODE.NEG
			
			nAX = - (nAX)

	    Case PCODE.ADD
		
			nAX = aStack( nSP ) + nAX 
			nSP = nSP - 1                     ' pop
			
		Case PCODE.SUBTRACT

			nAX = aStack( nSP ) - nAX 
			nSP = nSP - 1                      ' pop

		Case PCODE.MULTIPLY

			nAX = aStack( nSP ) * nAX 
			nSP = nSP - 1                      ' pop

		Case PCODE.DIVIDE

			' Check for divide by zero
			If ( nAX = 0 ) Then 
				DivideByZeroError 	
				Return ( 0 )			
			End If

			nAX = aStack( nSP ) / nAX 
			nSP = nSP - 1                       ' pop

		Case PCODE.MODULO
#If B4I	
			Private nTStack, nTAX As Int
			nTStack = aStack(nSP)
			nTAX = nAX 
			nAX =  nTStack Mod nTAX 
#else
			nAX = aStack( nSP ) Mod  nAX 
#end if
			nSP = nSP - 1                       ' pop

        Case PCODE.EQUAL

			If  ( aStack( nSP ) =  nAX ) Then nAX = 1 Else nAX = 0
			nSP = nSP - 1 

        Case PCODE.NOT_EQUAL

			If  ( aStack( nSP ) <>  nAX ) Then nAX = 1 Else nAX = 0
			nSP = nSP - 1 

        Case PCODE.LESS_THAN

			If  ( aStack( nSP ) <  nAX ) Then nAX = 1 Else nAX = 0
			nSP = nSP - 1 
			
        Case PCODE.LESS_EQUAL

			If  ( aStack( nSP ) <=  nAX ) Then nAX = 1 Else nAX = 0
			nSP = nSP - 1 

        Case PCODE.GREATER_THAN

			If  ( aStack( nSP ) >  nAX ) Then nAX = 1 Else nAX = 0
			nSP = nSP - 1 

        Case PCODE.GREATER_EQUAL

			If  ( aStack( nSP ) >=  nAX ) Then nAX = 1 Else nAX = 0
			nSP = nSP - 1 

		Case PCODE.LOGICAL_OR

			' A > 0 or B > 0
			If ( ( aStack( nSP ) > 0 ) Or ( nAX > 0 ) ) Then nAX = 1 Else nAX = 0
			nSP = nSP - 1 

		Case PCODE.LOGICAL_AND
			
			' A > 0 And B > 0
			If ( ( aStack( nSP ) > 0 ) And ( nAX > 0 ) ) Then nAX = 1 Else nAX = 0
			nSP = nSP - 1 

		Case PCODE.LOGICAL_NOT
			
			' !( A )
			If (nAX = 0 ) Then nAX = 1 Else 	nAX = 0				
			
		Case PCODE.JUMP_ALWAYS

			nIP = nIP + Code.Get( nIP + 1 )
			
		Case PCODE.JUMP_FALSE

			If ( nAX = 0 ) Then nIP = nIP + Code.Get( nIP + 1 ) Else nIP = nIP + 1
			
		Case PCODE.JUMP_TRUE

			If ( nAX > 0 ) Then nIP = nIP +  Code.Get( nIP + 1 ) Else nIP = nIP + 1

		Case PCODE.LOADCONST 
			
			' Advance instruction pointer
			nIP = nIP + 1
			
			' Load value from code 
			nAX = Code.Get( nIP )

		Case PCODE.LOADVAR 
			Private nVarIndex As Int 
			
			' Advance instruction pointer
			nIP = nIP + 1
			
			' Get index into memory block for this var
			nVarIndex = Code.Get( nIP ) 
			
			' Fetch value from memory
			nAX = aVarMemory( nVarIndex )

		Case PCODE.FUNC_ABS
			
			nValue = aStack( nSP )               ' get arg 
			nSP = nSP - 1                        ' pop stack
			nAX = Abs( nValue )                  ' call func

		Case PCODE.FUNC_MAX

			nAX = Max(aStack(nSP - 1), aStack( nSP ))    ' get arg1 and arg2
			nSP = nSP - 2                                ' pop stack

		Case PCODE.FUNC_MIN

			nAX = Min(aStack(nSP - 1), aStack( nSP ))   ' get arg1 and arg2
			nSP = nSP - 2                               ' pop stack

		Case PCODE.FUNC_SQRT

			nValue = aStack( nSP )               ' get arg 
			nSP = nSP - 1                        ' pop stack
			nAX = Sqrt( nValue )                 ' call func

		Case PCODE.ENDCODE

			bRun = False
			nRetVal = nAX 
			
		Case Else
			
			SetError( gCodeBlock.ERROR_ILLEGAL_CODE, "Pcode=" & nPcode )
			Return ( 0 )
			
		End Select

		' Advance instruction pointer
		nIP = nIP + 1
		
	Loop

	'Mtelog.Dbg( $"CPU state IP=${nIP}, AX=${nAX}, SP=${nSP}"$) 

	Return ( nRetVal ) 
	
End Sub

'*------------------------------------------------------- StackOverFlowError
'*
Private Sub StackOverFlowError As Int 
	Private sDetail As String 

	' Prcoessor state
	sDetail = $"IP=${nIP}, AX=${nAX}, SP=${nSP}"$

	Return ( SetError( gCodeBlock.ERROR_STACK_OVERFLOW, sDetail )  )
	
End Sub 

'*------------------------------------------------------- StackOverFlowError
'*
Private Sub DivideByZeroError As Int 
	Private sDetail As String 

	' Prcoessor state
	sDetail = $"IP=${nIP}, AX=${nAX}, SP=${nSP}"$

	Return ( SetError( gCodeBlock.ERROR_DIVIDE_BY_ZERO, sDetail )  )
	
End Sub 



'*---------------------------------------------------------------- SetError
'*
Private Sub SetError( nError As Int, sDetail As String )  As Int
	Private sDesc As String 
		
	' Get error description
	Select( nError ) 
	Case gCodeBlock.ERROR_NO_CODE
		sDesc = "No code to execute."
	Case gCodeBlock.ERROR_ILLEGAL_CODE
		sDesc = "Ilegal Instruction."
	Case gCodeBlock.ERROR_INSUFFICIENT_ARGS
		sDesc = "Insufficient arguments."
	Case gCodeBlock.ERROR_STACK_OVERFLOW
		sDesc = "Stack Overflow."
	Case gCodeBlock.ERROR_DIVIDE_BY_ZERO
		sDesc = "Divide by zero."
	Case Else 
		sDesc = "Other error."				
	End Select

	' Store error
	gCodeBlock.Error = nError
	gCodeBlock.ErrorDesc = sDesc
	gCodeBlock.ErrorDetail = sDetail

	Return ( nError )	
	
End Sub


'*-------------------------------------------------------------- Dump
'*
Public Sub Dump( oCodeBlock As Codeblock, Bytecode As List, Codelist As List ) As List 

	' If no code then return here	
	If ( Bytecode.Size = 0 ) Then 
		Return ( Codelist )
	End If

	'  Dump instructions to a list
	DumpCode( Bytecode, Codelist )
	
	Return ( Codelist  )	

End Sub

'*---------------------------------------------------------- DumpCode
'*
Private Sub DumpCode( Code As List, Decode As List ) As Int
	Private nPcode As Int
	Private bRun=True As Boolean 
	Private nRetVal=0 As Double
	Private nValue As Double
	Private nTarget As Int
	Private nParamCount As Int
	
	 nParamCount = Code.Get( CODE_HEADER_PARAM_COUNT ) 
	 Decode.Add( "-- Header --" )
	 Decode.Add( "Parameters=" & nParamCount )
	 Decode.Add( "-- Code --" )

	' Set instruction pointer 
	nIP = CODE_STARTS_HERE
			
	Do While ( bRun ) 

		' Get op code	
		nPcode = Code.Get( nIP ) 

		' Execute
		Select ( nPcode ) 

		Case PCODE.PUSH

			Decode.Add(pad( nIP, "push", "ax" ) )

	    Case PCODE.NEG

			Decode.Add(pad( nIP, "neg", "ax"))

	    Case PCODE.ADD
		
			Decode.Add(pad( nIP, "add", "stack[sp] + ax" ))
			Decode.Add(pad( nIP, "pop", ""))
			
		Case PCODE.SUBTRACT

			Decode.Add(pad( nIP, "sub", "stack[sp] - ax"))
			Decode.Add(pad( nIP, "pop", ""))

		Case PCODE.MULTIPLY

			Decode.Add(pad( nIP, "mul", "stack[sp] * ax"))
			Decode.Add(pad( nIP, "pop", ""))

		Case PCODE.DIVIDE

			Decode.Add(pad( nIP, "div", "stack[sp] / ax"))
			Decode.Add(pad( nIP, "pop", ""))

		Case PCODE.MODULO

			Decode.Add(pad( nIP, "mod", "stack[sp] % ax"))
			Decode.Add(pad( nIP, "pop", ""))

        Case PCODE.EQUAL

			Decode.Add(pad( nIP, "eq", "stack[sp] == ax"))
			Decode.Add(pad( nIP, "pop", ""))

        Case PCODE.NOT_EQUAL

			Decode.Add(pad( nIP, "neq", "stack[sp] != ax"))
			Decode.Add(pad( nIP, "pop", ""))

        Case PCODE.LESS_THAN

			Decode.Add(pad( nIP, "lt", "stack[sp] < ax"))
			Decode.Add(pad( nIP, "pop", ""))
			
        Case PCODE.LESS_EQUAL

			Decode.Add(pad( nIP, "le", "stack[sp] <= ax"))
			Decode.Add(pad( nIP, "pop", ""))

        Case PCODE.GREATER_THAN

			Decode.Add(pad( nIP, "gt", "stack[sp] > ax"))
			Decode.Add(pad( nIP, "pop", ""))

        Case PCODE.GREATER_EQUAL

			Decode.Add(pad( nIP, "ge", "stack[sp] >= ax"))
			Decode.Add(pad( nIP, "pop", ""))

		Case PCODE.LOGICAL_OR

			Decode.Add(pad( nIP, "or", "stack[sp] || ax"))
			Decode.Add(pad( nIP, "pop", ""))

		Case PCODE.LOGICAL_AND

			Decode.Add(pad( nIP, "and", "stack[sp] && ax"))
			Decode.Add(pad( nIP, "pop", ""))

		Case PCODE.LOGICAL_NOT

			Decode.Add(pad( nIP, "not", "ax"))
			
		Case PCODE.JUMP_ALWAYS

			nTarget = nIP +  Code.Get( nIP + 1 )  + 1   ' + 1 needed to for correct location
			Decode.Add(pad( nIP, "jump", nTarget))
			nIP = nIP + 1
			
		Case PCODE.JUMP_FALSE

			nTarget = nIP +  Code.Get( nIP + 1 )  + 1   ' + 1 needed to for correct location
			Decode.Add(pad( nIP, "jumpf", nTarget))
			nIP = nIP + 1
			
		Case PCODE.JUMP_TRUE
			Private nTarget As Int
			
			nTarget = nIP +  Code.Get( nIP + 1 ) + 1   ' + 1 needed to for correct location
			Decode.Add(pad( nIP, "jumpt", nTarget))
			nIP = nIP + 1

		Case PCODE.LOADCONST 

			nIP = nIP + 1
			nValue = Code.Get( nIP )
			Decode.Add(pad( nIP-1, "loadc", "ax, " & nValue))

		Case PCODE.LOADVAR 
			Private nVarIndex As Int 

			nIP = nIP + 1
			nVarIndex = Code.Get( nIP )
			Decode.Add(pad( nIP-1, "loadv", $"ax, varmem[${ nVarIndex }]"$))

		Case PCODE.FUNC_ABS

			Decode.Add(pad( nIP, "call", "abs"))
			Decode.Add(pad( nIP, "pop", ""))

		Case PCODE.FUNC_MAX

			Decode.Add(pad( nIP, "call", "max"))
			Decode.Add(pad( nIP, "pop", "2"))

		Case PCODE.FUNC_MIN

			Decode.Add(pad( nIP, "call", "min"))
			Decode.Add(pad( nIP, "pop", "2"))

		Case PCODE.FUNC_SQRT

			Decode.Add(pad( nIP, "call", "sqrt"))
			Decode.Add(pad( nIP, "pop", ""))

		Case PCODE.ENDCODE

			Decode.Add(pad( nIP, "end", ""))
			bRun = False
			
		Case Else

			Decode.Add(pad( nIP, "err", "pcode=" & nPcode))
			Return ( 0 )
			
		End Select

		' Advance instruction pointer
		nIP = nIP + 1
		
	Loop

	Return ( nRetVal ) 
	
End Sub

'*--------------------------------------------------------------- pad
'*
Private Sub pad( nIP2 As Int, sInstruct As String, sOperands As String ) As String 
	Private sInstructWithPad As String 
	Private sIpWithPad As String 
	
	sIpWithPad = nIP2 & ":          "
	sInstructWithPad = sInstruct &  "          "
	
	'Log( "IPLen=" & sIpWithPad.SubString2(0, 7).Length )
	'Log( "InstLen=" & sInstructWithPad.SubString2(0,8).Length )
	

	Return ( sIpWithPad.SubString2(0, 7) & sInstructWithPad.SubString2(0,8) & sOperands )
	
End Sub


Sub btnRunTest_Click
	
End Sub