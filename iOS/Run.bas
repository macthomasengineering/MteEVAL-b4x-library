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

	' Budget
	Private Const STACK_SIZE=50 As Int    'ignore
	Private Const MEMORY_SIZE=20 As Int   'ignore
	
	Private Const CODE_HEADER_PARAM_COUNT = 0 As Int  'ignore
	Private Const CODE_STARTS_HERE        = 1 As Int  'ignore 
	
End Sub

'*--------------------------------------------------------------- Execute
'*
Public Sub Execute( oCodeBlock As Codeblock, cbCode As MTE_CODE, aArgs() As Object ) As Double
	Private nRetVal = 0 As Double 

	' Attempt to run before compiling?	Compile error?
	If ( cbCode.byteCode.Length = 0 ) Then 
		SetError( oCodeBlock, oCodeBlock.ERROR_NO_CODE, "Check compile error." )
		Return ( 0 )
	End If
		 
	' Run code	
	nRetVal = ExecuteCode( oCodeBlock, cbCode, aArgs ) 
	
	Return ( nRetVal ) 
	
End Sub

'*----------------------------------------------------------- ExecuteCode
'*
Private Sub ExecuteCode( oCodeBlock As Codeblock, cbCode As MTE_CODE, aArgs() As Object ) As Double
	Private nPcode As Int
	Private nParamCount As Int
	Private nArgIndex As Int
	Private bRun=True As Boolean 
	Private nRetVal=0 As Double
	Private nAX=0 As Double                      ' Accumlator 
	Private nIP=0 As Int                         ' Instruction pointer
	Private nSP=0 As Int                         ' Stack pointer
	Private aStack( STACK_SIZE + 1 ) As Double   ' Stack, STACK_SIZE + 1 because our stack is one based.
	Private aVarMemory( MEMORY_SIZE )  As Double ' Variable memory
	Private iStackVal, iAX As Int
	Private code() As Int 
	Private constData() As Double 
	Private nVarIndex As Int

	' Set references to bytecode and data
	code = cbCode.byteCode
	constData = cbCode.constData
	
	 ' get parameter count
	 nParamCount = code( CODE_HEADER_PARAM_COUNT ) 
	 
	 ' Invalid number of parameters?  Set error
	 If ( nParamCount > aArgs.Length ) Then 
		SetError( oCodeBlock, oCodeBlock.ERROR_INSUFFICIENT_ARGS, "Expecting " & nParamCount & " arguments." )
		Return ( 0 ) 		
	End If
	
	' How about too many parameters? 
	If ( nParamCount > MEMORY_SIZE ) Then 
		SetError( oCodeBlock, oCodeBlock.ERROR_TOO_MANY_ARGS, "Max arguments=" & MEMORY_SIZE & ", argcount=" & nParamCount )
		Return ( 0 )
	End If
	
	' Store parameters
	If ( nParamCount > 0 ) Then 

		' Store parameter values in variable memory 
		For nArgIndex = 0 To nParamCount - 1
			
			' Validate parameter is a number
			If ( IsNumber( aArgs( nArgIndex )) = False  ) Then 
				SetError( oCodeBlock, oCodeBlock.ERROR_ARG_NOT_NUMBER, "Argument #" & nArgIndex & "not a number." )
				Return ( 0 ) 		
			End If
			
			' Store value
			aVarMemory( nArgIndex ) = aArgs( nArgIndex )		

		Next

	End If 
	
	' Set instruction pointer 
	nIP = CODE_STARTS_HERE
			
	Do While ( bRun ) 

		' get op code	
		nPcode = code( nIP ) 

		'-------------------------- Is this a stack, load or store instruction?
		'
		If ( nPcode <= PCODE.STOREVAR ) Then 
			
			Select ( nPcode ) 
			Case PCODE.PUSH
				' Advance stack pointer and store
				nSP = nSP + 1 

				' Overlfow?				
				If ( nSP > STACK_SIZE ) Then
					StackOverFlowError( oCodeBlock, nIP, nAX, nSP )
					Return ( 0 ) 
				End If
			
				aStack( nSP ) = nAX 
			
				'Mtelog.Dbg( "<--- Push AX=" & nAX )

			Case PCODE.PUSHVAR
				
				' Advance instruction pointer
				nIP = nIP + 1

				' Get index into var memory
				nVarIndex = code(nIP) 

				' Advance stack pointer
				nSP = nSP + 1 
				
				' Store on stack 
				aStack( nSP ) = aVarMemory( nVarIndex )

			Case PCODE.PUSHCONST

				' Advance instruction pointer
				nIP = nIP + 1

				' Get index into the const table
				nVarIndex = code(nIP) 

				' Advance stack pointer
				nSP = nSP + 1 
				
				' Store on stack 
				aStack( nSP ) = constData( nVarIndex ) 

			Case PCODE.LOADCONST 
				
				' Advance instruction pointer
				nIP = nIP + 1

				' Get index into table
				nVarIndex = code(nIP) 
					
				' Load value from code 
				'nAX = code.get( nIP )

				' Get value from const table
				nAX = constData( nVarIndex ) 

			Case PCODE.LOADVAR 
				
				' Advance instruction pointer
				nIP = nIP + 1
				
				' get index into memory block for this var
				nVarIndex = code( nIP ) 
				
				' Fetch value from memory
				nAX = aVarMemory( nVarIndex )

			Case PCODE.STOREVAR
				
				' Advance instruction pointer
				nIP = nIP + 1
				
				' get index into memory block for this var
				nVarIndex = code( nIP ) 
				
				' Store value into memory
				aVarMemory( nVarIndex ) = nAX

			End Select

		'-------------------------------------------------------- Is this math?
		'
		Else If ( nPcode <= PCODE.MODULO ) Then 

			Select ( nPcode ) 
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
					DivideByZeroError( oCodeBlock, nIP, nAX, nSP ) 	
					Return ( 0 )			
				End If

				nAX = aStack( nSP ) / nAX 
				nSP = nSP - 1                       ' pop

			Case PCODE.MODULO
				#If B4I	
					' Cast to int
					iStackVal = aStack(nSP)
					iAX = nAX 
					nAX =  iStackVal Mod iAX
				#else
					nAX = aStack( nSP ) Mod  nAX 
				#end if
				nSP = nSP - 1                       ' pop
			End Select

		'----------------------------------------- Is this relational or logic?
		'
		Else If ( nPcode <= PCODE.LOGICAL_NOT ) Then 

			Select ( nPcode )
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

			End Select

		'------------------------------------------ Is this a jump or bitshift? 
		'
		Else If ( nPcode <= PCODE.BIT_SHIFT_RIGHT ) Then 

			Select ( nPcode )

			Case PCODE.JUMP_ALWAYS

				nIP = nIP + code( nIP + 1 )
				
			Case PCODE.JUMP_FALSE

				If ( nAX = 0 ) Then nIP = nIP + code( nIP + 1 ) Else nIP = nIP + 1
				
			Case PCODE.JUMP_TRUE

				If ( nAX > 0 ) Then nIP = nIP +  code( nIP + 1 ) Else nIP = nIP + 1

			Case PCODE.BIT_AND
				
				' Cast to int
				iStackVal = aStack(nSP) 
				iAX = nAX 							

				nAX = Bit.And( iStackVal, iAX  )
				nSP = nSP - 1                     ' pop

			Case PCODE.BIT_OR
				
				' Cast to int
				iStackVal = aStack(nSP) 
				iAX = nAX 							

				nAX = Bit.Or( iStackVal, iAX )
				nSP = nSP - 1                     ' pop
	        
			Case PCODE.BIT_XOR
				
				' Cast to int
				iStackVal = aStack(nSP) 
				iAX = nAX 							

				nAX = Bit.XOr( iStackVal, iAX  )
				nSP = nSP - 1                     ' pop

			Case PCODE.BIT_NOT
				
				' Cast to int
				iAX = nAX 							

				nAX = Bit.Not( iAX )

				' No need to pop here
				' nSP = nSP - 1                     ' pop
				
			Case PCODE.BIT_SHIFT_LEFT
				
				' Cast to int
				iStackVal = aStack(nSP) 
				iAX = nAX 							

				nAX = Bit.ShiftLeft(iStackVal, iAX)
				nSP = nSP - 1                     ' pop

			Case PCODE.BIT_SHIFT_RIGHT
				
				' Cast to int
				iStackVal = aStack(nSP) 
				iAX = nAX 							

				nAX = Bit.ShiftRight(iStackVal, iAX)
				nSP = nSP - 1                     ' pop

			End Select

		'--------------------------------------------- Is this a user function? 
		'
		Else If ( nPcode <= PCODE.ENDCODE ) Then 

			Select ( nPcode )
	
			Case PCODE.FUNC_ABS
				
				nAX = Abs( aStack( nSP ) )           ' get arg1 off stack and call abs
				nSP = nSP - 1                        ' pop stack

			Case PCODE.FUNC_MAX

				nAX = Max(aStack(nSP - 1), aStack( nSP ))    ' get arg1 and arg2, call max
				nSP = nSP - 2                                ' pop stack

			Case PCODE.FUNC_MIN

				nAX = Min(aStack(nSP - 1), aStack( nSP ))   ' get arg1 and arg2 and call min
				nSP = nSP - 2                               ' pop stack

			Case PCODE.FUNC_SQRT

				nAX = Sqrt( aStack( nSP ) )          ' get arg1 off stack and call sqrt
				nSP = nSP - 1                        ' pop stack

			Case PCODE.FUNC_POWER

				nAX = Power(aStack(nSP - 1), aStack( nSP ))   ' get arg1 and arg2
				nSP = nSP - 2                                 ' pop stack
			
			Case PCODE.FUNC_ROUND
				
				nAX = Round( aStack(nSP) )     ' get arg and call func
				nSP = nSP - 1                  ' pop stack
			
			Case PCODE.FUNC_FLOOR

				nAX = Floor( aStack(nSP) )     ' get arg and call func
				nSP = nSP - 1                  ' pop stack

			Case PCODE.FUNC_CEIL

				nAX = Ceil( aStack(nSP) )      ' get arg and call func
				nSP = nSP - 1                  ' pop stack

			Case PCODE.FUNC_COS

				nAX = Cos( aStack(nSP) )       ' get arg and call func
				nSP = nSP - 1                  ' pop stack
		
			Case PCODE.FUNC_COSD

				nAX = CosD( aStack(nSP) )      ' get arg and call func
				nSP = nSP - 1                  ' pop stack

			Case PCODE.FUNC_SIN

				nAX = Sin( aStack(nSP) )       ' get arg and call func
				nSP = nSP - 1                  ' pop stack
		
			Case PCODE.FUNC_SIND

				nAX = SinD( aStack(nSP) )      ' get arg and call func
				nSP = nSP - 1                  ' pop stack
			
			Case PCODE.FUNC_TAN

				nAX = Tan( aStack(nSP) )     ' get arg and call func
				nSP = nSP - 1                ' pop stack
			
			Case PCODE.FUNC_TAND

				nAX = TanD( aStack(nSP) )    ' get arg and call func
				nSP = nSP - 1                ' pop stack
			
			Case PCODE.FUNC_ACOS

				nAX = ACos( aStack(nSP) )    ' get arg and call func
				nSP = nSP - 1                ' pop stack
			
			Case PCODE.FUNC_ACOSD

				nAX = ACosD( aStack(nSP) )   ' get arg and call func
				nSP = nSP - 1                ' pop stack
			
			Case PCODE.FUNC_ASIN

				nAX = ASin( aStack(nSP) )    ' get arg and call func
				nSP = nSP - 1                ' pop stack
		
			Case PCODE.FUNC_ASIND

				nAX = ASinD( aStack(nSP) )   ' get arg and call func
				nSP = nSP - 1                ' pop stack
			
			Case PCODE.FUNC_ATAN

				nAX = ATan( aStack(nSP) )    ' get arg and call func
				nSP = nSP - 1                ' pop stack
			
			Case PCODE.FUNC_ATAND

				nAX = ATanD( aStack(nSP) )   ' get arg and call func
				nSP = nSP - 1                ' pop stack

			Case PCODE.FUNC_NUMBER_FORMAT

				nAX = NumberFormat( aStack( nSP-2 ), aStack( nSP-1 ), aStack(nSP) )  + 0  ' get arg and call func 
				nSP = nSP - 3                ' pop stack

			Case PCODE.FUNC_AVG

				nAX = avg( aStack( nSP-1 ), aStack(nSP) )   ' get arg and call func
				nSP = nSP - 2              ' pop stack
			
			Case PCODE.ENDCODE

				bRun = False
				nRetVal = nAX 
	
			End Select			
	
		Else 
		
			SetError( oCodeBlock, oCodeBlock.ERROR_ILLEGAL_CODE, "Pcode=" & nPcode )
			Return ( 0 )

		End If 

		' Advance instruction pointer
		nIP = nIP + 1
		
	Loop

	'Mtelog.Dbg( $"CPU state IP=${nIP}, AX=${nAX}, SP=${nSP}"$) 

	Return ( nRetVal ) 
	
End Sub

'*------------------------------------------------------------ avg
'*
Private Sub avg( val1 As Double, val2 As Double ) As Double 
	Return ( (val1 + val2 )/2 )
End Sub 

'*------------------------------------------------------- StackOverFlowError
'*
Private Sub StackOverFlowError( oCodeBlock As Codeblock, nIP As Int, nAX As Double, nSP As Int) As Int 
	Private sDetail As String 

	' Prcoessor state
	sDetail = $"IP=${nIP}, AX=${nAX}, SP=${nSP}"$

	Return ( SetError( oCodeBlock, oCodeBlock.ERROR_STACK_OVERFLOW, sDetail )  )
	
End Sub 

'*------------------------------------------------------------ DivideByZero
'*
Private Sub DivideByZeroError( oCodeBlock As Codeblock, nIP As Int, nAX As Double, nSP As Int) As Int 
	Private sDetail As String 

	' Prcoessor state
	sDetail = $"IP=${nIP}, AX=${nAX}, SP=${nSP}"$

	Return ( SetError( oCodeBlock, oCodeBlock.ERROR_DIVIDE_BY_ZERO, sDetail )  )
	
End Sub 

'*---------------------------------------------------------------- SetError
'*
Private Sub SetError( oCodeBlock As Codeblock, nError As Int, sDetail As String )  As Int
	Private sDesc As String 
		
	' get error description
	Select( nError ) 
	Case oCodeBlock.ERROR_NO_CODE
		sDesc = "No code to execute."
	Case oCodeBlock.ERROR_ILLEGAL_CODE
		sDesc = "Ilegal Instruction."
	Case oCodeBlock.ERROR_INSUFFICIENT_ARGS
		sDesc = "Insufficient arguments."
	Case oCodeBlock.ERROR_STACK_OVERFLOW
		sDesc = "Stack Overflow."
	Case oCodeBlock.ERROR_DIVIDE_BY_ZERO
		sDesc = "Divide by zero."
	Case Else 
		sDesc = "Other error."				
	End Select

	' Store error
	oCodeBlock.Error = nError
	oCodeBlock.ErrorDesc = sDesc
	oCodeBlock.ErrorDetail = sDetail

	Return ( nError )	
	
End Sub


'***************************************************************************
'* 
'* Decompiler
'* 
'***************************************************************************

'*-------------------------------------------------------------- Dump
'*
Public Sub Dump( oCodeBlock As Codeblock, Code As MTE_CODE, Codelist As List ) As List 

	' If no code then return here	
	If ( Code.byteCode.Length = 0 ) Then 
		Return ( Codelist )
	End If

	'  Dump instructions to a list
	'DumpCode( Bytecode, Codelist )
	DumpCode( Code, Codelist )
	
	Return ( Codelist  )	

End Sub

'*---------------------------------------------------------- DumpCode
'*
Private Sub DumpCode( cbCode As MTE_CODE, Decode As List ) As Int
	Private nPcode As Int
	Private bRun=True As Boolean 
	Private nRetVal=0 As Double
	Private nValue As Double
	Private nVarIndex As Int
	Private nTarget As Int
	Private nParamCount As Int
	Private nIP As Int
	Private code() As Int 
	Private constData() As Double 
	
	' Set references to bytecode and data
	code = cbCode.byteCode
	constData = cbCode.constData
	
	' Get parameter count
	 nParamCount = code( CODE_HEADER_PARAM_COUNT )
	 Decode.Add( "-- Header --" )
	 Decode.Add( "Parameters=" & nParamCount )
	 Decode.Add( "-- Code --" )

	' Set instruction pointer 
	nIP = CODE_STARTS_HERE
			
	Do While ( bRun ) 

		' get op code	
		nPcode = code( nIP ) 

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

		Case PCODE.BIT_AND

			Decode.Add(pad( nIP, "bitand", "stack[sp] & ax"))
			Decode.Add(pad( nIP, "pop", ""))

		Case PCODE.BIT_OR

			Decode.Add(pad( nIP, "bitor", "stack[sp] | ax"))
			Decode.Add(pad( nIP, "pop", ""))

		Case PCODE.BIT_XOR

			Decode.Add(pad( nIP, "bitxor", "stack[sp] ^ ax"))
			Decode.Add(pad( nIP, "pop", ""))

		Case PCODE.BIT_NOT

			Decode.Add(pad( nIP, "bitnot", "~ ax"))

		Case PCODE.BIT_SHIFT_LEFT

			Decode.Add(pad( nIP, "bitlft", "stack[sp] << ax"))
			Decode.Add(pad( nIP, "pop", ""))

		Case PCODE.BIT_SHIFT_RIGHT

			Decode.Add(pad( nIP, "bitrgt", "stack[sp] >> ax"))
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

			nTarget = nIP +  code( nIP + 1 )  + 1   ' + 1 needed for correct location
			Decode.Add(pad( nIP, "jump", nTarget))
			nIP = nIP + 1
			
		Case PCODE.JUMP_FALSE

			nTarget = nIP +  code( nIP + 1 )  + 1   ' + 1 needed for correct location
			Decode.Add(pad( nIP, "jumpf", nTarget))
			nIP = nIP + 1
			
		Case PCODE.JUMP_TRUE
			
			nTarget = nIP +  code( nIP + 1 ) + 1   ' + 1 needed for correct location
			Decode.Add(pad( nIP, "jumpt", nTarget))
			nIP = nIP + 1
		
		Case PCODE.PUSHVAR

			nIP = nIP + 1
			nVarIndex = code( nIP )
			Decode.Add(pad( nIP-1, "pushv", $"varmem[${ nVarIndex }]"$))

		Case PCODE.PUSHCONST 
			
			nIP = nIP + 1
			nVarIndex = code( nIP )
			
			' Get value from const data table
			nValue = constData( nVarIndex ) 
			
			Decode.Add(pad( nIP-1, "pushc", nValue ))

		Case PCODE.LOADCONST 
			
			nIP = nIP + 1
			nVarIndex = code( nIP )
			
			' Get value from const data table
			nValue = constData( nVarIndex ) 
			
			Decode.Add(pad( nIP-1, "loadc", "ax, " & nValue ))

		Case PCODE.LOADVAR 

			nIP = nIP + 1
			nVarIndex = code( nIP )
			Decode.Add(pad( nIP-1, "loadv", $"ax, varmem[${ nVarIndex }]"$))

		Case PCODE.STOREVAR

			nIP = nIP + 1
			nVarIndex = code( nIP )
			Decode.Add(pad( nIP-1, "storev", $"varmem[${ nVarIndex }], ax"$))

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

		Case PCODE.FUNC_POWER

			Decode.Add(pad( nIP, "call", "power"))
			Decode.Add(pad( nIP, "pop", "2"))
			
		Case PCODE.FUNC_ROUND
			Decode.Add(pad( nIP, "call", "round"))
			Decode.Add(pad( nIP, "pop", ""))
			
		Case PCODE.FUNC_FLOOR
			Decode.Add(pad( nIP, "call", "floor"))
			Decode.Add(pad( nIP, "pop", ""))

		Case PCODE.FUNC_CEIL

			Decode.Add(pad( nIP, "call", "ceil"))
			Decode.Add(pad( nIP, "pop", ""))

		Case PCODE.FUNC_COS

			Decode.Add(pad( nIP, "call", "cos"))
			Decode.Add(pad( nIP, "pop", ""))
		
		Case PCODE.FUNC_COSD

			Decode.Add(pad( nIP, "call", "cosd"))
			Decode.Add(pad( nIP, "pop", ""))

		Case PCODE.FUNC_SIN

			Decode.Add(pad( nIP, "call", "sin"))
			Decode.Add(pad( nIP, "pop", ""))
		
		Case PCODE.FUNC_SIND

			Decode.Add(pad( nIP, "call", "sind"))
			Decode.Add(pad( nIP, "pop", ""))
		
		Case PCODE.FUNC_TAN

			Decode.Add(pad( nIP, "call", "tan"))
			Decode.Add(pad( nIP, "pop", ""))
		
		Case PCODE.FUNC_TAND

			Decode.Add(pad( nIP, "call", "tand"))
			Decode.Add(pad( nIP, "pop", ""))
		
		Case PCODE.FUNC_ACOS

			Decode.Add(pad( nIP, "call", "acos"))
			Decode.Add(pad( nIP, "pop", ""))
		
		Case PCODE.FUNC_ACOSD

			Decode.Add(pad( nIP, "call", "acosd"))
			Decode.Add(pad( nIP, "pop", ""))
		
		Case PCODE.FUNC_ASIN

			Decode.Add(pad( nIP, "call", "asin"))
			Decode.Add(pad( nIP, "pop", ""))
		
		Case PCODE.FUNC_ASIND

			Decode.Add(pad( nIP, "call", "asind"))
			Decode.Add(pad( nIP, "pop", ""))
		
		Case PCODE.FUNC_ATAN

			Decode.Add(pad( nIP, "call", "atan"))
			Decode.Add(pad( nIP, "pop", ""))
		
		Case PCODE.FUNC_ATAND

			Decode.Add(pad( nIP, "call", "atand"))
			Decode.Add(pad( nIP, "pop", ""))

		Case PCODE.FUNC_NUMBER_FORMAT

			Decode.Add(pad( nIP, "call", "numberformat"))
			Decode.Add(pad( nIP, "pop", "3"))

		Case PCODE.FUNC_AVG

			Decode.Add(pad( nIP, "call", "avg"))
			Decode.Add(pad( nIP, "pop", "2"))
		
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
Private Sub pad( nIP As Int, sInstruct As String, sOperands As String ) As String 
	Private sInstructWithPad As String 
	Private sIpWithPad As String 
	
	sIpWithPad = nIP & ":          "
	sInstructWithPad = sInstruct &  "          "

	Return ( sIpWithPad.SubString2(0, 7) & sInstructWithPad.SubString2(0,8) & sOperands )
	
End Sub