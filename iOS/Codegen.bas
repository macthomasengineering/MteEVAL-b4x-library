Type=StaticCode
Version=2.8
ModulesStructureVersion=1
B4i=true
@EndOfDesignText@
'**********************************************************************************
'*
'* Codegen.bas - Parser and code generator
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

	' Types
	Type MTE_TOKEN ( nType As Int, sText As String )
	Type MTE_JUMP ( nCodeIndex As Int, nLabelIndex As Int ) 
	Type MTE_FUNC_INFO ( nPcode As Int, nArgCount As Int )  
	Type MTE_VARIENT ( nType As Int,  vDouble As Double, vInt As Int, vBoolean As Boolean, vString As String )
	Type MTE_CODE ( byteCode() As Int, constData() As Double ) 
		

	' Global reference to Codeblock
	Private gCodeBlock  As Codeblock
	Private gCodeIndex  As Int

	' Bytecode, Constants table 
	Private gBytecode   As List 
	Private gConstdata  As List 
	Private gIsPcode    As List 
	
	' Parameter and eval expressions
	Private gParamExpr  As String
	Private gEvalExpr   As String 
	
	' Putback
	Private gPutBackCount   As Int 
	Private gPutBackIndex   As Int 
	
	' Jump table
	Private gJumpTable(20) As MTE_JUMP
	Private gJumpCount=0 As Int 
	
	' Labels
	Private gLabelTargets(20) As Int 
	Private gLabelIndex=0 As Int 
		
	' Parameter names
	Private gParameters(20) As String    
	Private gParameterCount=0 As Int
		
	' Parenthesis 
	Private gParenCount As Int 		

	' Token list and navigation
	Private gTokenList      As List
	Private gToken          As MTE_TOKEN
	Private gTokenIndex     As Int 
	Private gTokenEndIndex  As Int 
	
	' Token Types	
	Private Const TOKEN_TYPE_NONE=0 As Int               'ignore
	Private Const TOKEN_TYPE_DELIMITER=1 As Int          'ignore
	Private Const TOKEN_TYPE_IDENTIFIER=2 As Int         'ignore
	Private Const TOKEN_TYPE_NUMBER=3 As Int             'ignore
	Private Const TOKEN_TYPE_KEYWORD=4 As Int            'ignore
	Private Const TOKEN_TYPE_TEMP=5 As Int               'ignore
	Private Const TOKEN_TYPE_STRING=6 As Int             'ignore
	Private Const TOKEN_TYPE_BLOCK=7 As Int              'ignore
	Private Const TOKEN_TYPE_UNKNOWN=8 As Int            'ignore
	Private Const TOKEN_TYPE_FINISHED=9 As Int           'ignore
	Private Const TOKEN_TYPE_HEX_NUMBER=10 As Int        'ignore
	Private Const NULL_TOKEN=Chr(0) As String

	' Expression parsing
	Private Const TOKENIZER_MATCH="\(|\)|>=|<=|<>|\|\||&&|!=|==|<<|>>|0x[\.\da-z]+|[&\^\|~]|[+><=*/\-!%,]|[\.\d]+|\b\w+\b" As String
	Private Const CODEBLOCK_MATCH="(\{)?(\|)?([^\|\}]*)(\|)?([^}]*)(\})?" As String
	
	' Expression groupw
	Private Const GROUP_OPEN_BRACKET   = 1 As Int  
	Private Const GROUP_OPEN_PIPE      = 2 As Int  
	Private Const GROUP_PARAM_EXPR     = 3 As Int
	Private Const GROUP_CLOSE_PIPE     = 4 As Int  
	Private Const GROUP_EVAL_EXPR      = 5 As Int
	Private Const GROUP_CLOSE_BRACKET  = 6 As Int  

	' Abort used to unwind the parser when error found
	Private Const ABORT=False As Boolean
	Private Const SUCCESS=True As Boolean

	' Bit.ParseInt conversion
	Private Const HEX2DECIMAL=16 As Int

	' Internal func table
	Private gFuncInfo    As MTE_FUNC_INFO
	Private aFuncTable() As Object
	Private mapFuncTable As Map
	Private bFuncTableLoaded=False As Boolean
	
	' Offsets into func table
	Private Const FUNC_TABLE_FUNCNAME	= 0 As Int	'ignore
	Private Const FUNC_TABLE_PCODE		= 1 As Int	'ignore
	Private Const FUNC_TABLE_ARGCOUNT	= 2 As Int	'ignore
	
End Sub


'*--------------------------------------------------------- LoadFuncTable
'* 
Private Sub LoadFuncTable
	Private nTableIndex As Int
	
	' Table entry format
	' ------------------
	' Array( "func", pcode, argcount )
	
	' Internal func table
	aFuncTable = Array( "abs",	  PCODE.FUNC_ABS,	1, _
			 		    "iif", 	  PCODE.FUNC_IIF,	3, _
			 		    "if",	  PCODE.FUNC_IIF,	3, _
			 		    "max",	  PCODE.FUNC_MAX,	2, _
			 		    "min",	  PCODE.FUNC_MIN,	2, _
			 		    "sqrt",	  PCODE.FUNC_SQRT,	1, _
			 		    "power",  PCODE.FUNC_POWER,	2, _
			 		    "round",  PCODE.FUNC_ROUND,	1, _
			 		    "floor",  PCODE.FUNC_FLOOR,	1, _
						"ceil",	  PCODE.FUNC_CEIL,	1, _
						"cos", 	  PCODE.FUNC_COS,	1, _
						"cosd",   PCODE.FUNC_COSD,	1, _
						"sin",    PCODE.FUNC_SIN,	1, _
						"sind",   PCODE.FUNC_SIND,	1, _
						"tan",    PCODE.FUNC_TAN,	1, _
						"tand",   PCODE.FUNC_TAND,	1, _
						"acos",   PCODE.FUNC_ACOS,	1, _
						"acosd",  PCODE.FUNC_ACOSD,	1, _
						"asin",   PCODE.FUNC_ASIN,	1, _
						"asind",  PCODE.FUNC_ASIND,	1, _
						"atan",   PCODE.FUNC_ATAN,	1, _
						"atand",  PCODE.FUNC_ATAND,	1, _
						"numberformat", PCODE.FUNC_NUMBER_FORMAT,3, _
						"avg",  PCODE.FUNC_AVG,	2, _
						"####",  PCODE.NONE,  	0)
						 
	' Create map for fast lookup					
	mapFuncTable.Initialize
	For nTableIndex = 0 To aFuncTable.Length-3 Step 3
		mapFuncTable.Put( aFuncTable( nTableIndex + FUNC_TABLE_FUNCNAME ), nTableIndex )
	Next

	bFuncTableLoaded = True 

End Sub

'*--------------------------------------------------------- FindInternalFunc
'* 
Private Sub FindInternalFunc( sName As String ) As MTE_FUNC_INFO
	Private tFuncInfo As MTE_FUNC_INFO
	Private nTableIndex As Object
	
	' Load lookup table
	If ( bFuncTableLoaded = False ) Then 
		LoadFuncTable
	End If 
	
	' Search table for function
	nTableIndex = mapFuncTable.Get(sName)
	If ( nTableIndex <> Null ) Then 	
		tFuncInfo.nPcode    = aFuncTable( nTableIndex + FUNC_TABLE_PCODE )
		tFuncInfo.nArgCount = aFuncTable( nTableIndex + FUNC_TABLE_ARGCOUNT )
	Else 	
		tFuncInfo.nPcode    = -1 				
		tFuncInfo.nArgCount = 0
	End If 

	Return ( tFuncInfo )

End Sub


'*---------------------------------------------------------------- ResetCode
'*
Private Sub ResetCode 

	' init code index
	gCodeIndex = 0   ' First item in bytecode is the codeblock parameter count. 
	                 ' Pcode starts at Bytecode.Get( 1 )
	
	' Init jump count and label index
	gJumpCount      = 0
	gLabelIndex     = 0
	gParameterCount = 0
	gParenCount     = 0
	gPutBackCount   = 0
	gPutBackIndex   = 0
	
	gParamExpr = "" 
	gEvalExpr  = ""
	
End Sub


'*--------------------------------------------------------- CompileCodeBlock
'*
Public Sub CompileCodeBlock( oCodeBlock As Codeblock, Code As MTE_CODE ) As Int
	Private nError As Int 
	
	' Set global reference to the codeblock
	gCodeBlock = oCodeBlock
	
	' On first pass, code and constants stored in list 
	gBytecode.Initialize
	gConstdata.Initialize
	
	' Track location of pcode vs. inline values
	gIsPcode.Initialize 
		
	' Reset code index and tables
	ResetCode
		
	' Extract parameter and eval expressions 
	nError = ExtractExpressions( gCodeBlock ) 

	' If no error, continue
	If ( nError = gCodeBlock.ERROR_NONE ) Then 

		' Process codeblock parameters
		nError = CompileParameters

		' If no error, continue
		If ( nError = gCodeBlock.ERROR_NONE ) Then 
	
			' Store parameter count in the code
			EmitCodeHeader( gParameterCount )

			' Compile expression 
			nError = CompileExpression 

		End If 
		
	End If 
	
	' If error delete the code
	If ( nError <> gCodeBlock.ERROR_NONE  ) Then 
		gBytecode.Initialize
		Return ( nError ) 
	End If
	
	'---------------------------------------------------
	' Convert code and constants to fixed length arrays
	
	' Convert constant data to array 
	Private aConstdata( gConstdata.size ) As Double 
	Private i As Int 
	For i=0 To gConstdata.Size -1 
		aConstdata( i ) = gConstdata.Get( i )	
	Next
	
	' Convert bytecode to array 
	Private aBytecode( gBytecode.size ) As Int
	For i=0 To gBytecode.Size -1 
		aBytecode( i ) = gBytecode.Get( i )	
	Next
	
	' Store data and bytecode
	Code.constData = aConstdata
	Code.byteCode  = aBytecode
	
	Return  ( nError )
				
End Sub

'***************************************************************************
'* 
'* Parser
'* 
'***************************************************************************

'*--------------------------------------------------------- CompileExpression
'*
'*           
Private Sub CompileExpression As Int
	Private bFinished As Boolean 
	Private bSuccess As Boolean 

	' Tokenize expression	
	gTokenList = Tokenize( gEvalExpr )

	bFinished = False
	Do Until ( bFinished ) 

		' Run Parser and generate code	
		bSuccess = EvalExpression
		
		If ( bSuccess = ABORT )  Then 
			Exit
		End If

		' Check for completion or unexpected error
		Select ( gToken.nType ) 
		Case TOKEN_TYPE_FINISHED
			DoEndCode                          
			FixupJumps
			bFinished = True
		Case TOKEN_TYPE_NONE			
			SetError( gCodeBlock.ERROR_OTHER, "Token type none." )
			bFinished = True 
		Case TOKEN_TYPE_UNKNOWN 
			SetError( gCodeBlock.ERROR_OTHER, "Unknown token." )
			bFinished = True
		End Select
	Loop

	Return ( gCodeBlock.Error ) 

End Sub 


'*--------------------------------------------------------- CompileParameters
'*
'* GetToken Advancement
'* --------------------
'* 1.  |a,b,c|
'*      ^
'* 2.  |a,b,c|
'*       ^
'* 3.  |a,b,c|
'*        ^
'* 4.  |a,b,c|
'*         ^
'* 5.  |a,b,c|
'*          ^
'* 6.  |a,b,c|
'*           ^
Private Sub CompileParameters As Int
	Private bFinished As Boolean 
	Private nCommaCount=0 As Int

	' Reset parameter count
	gParameterCount = 0
	
	' Tokenize parameter expression
	gTokenList = Tokenize( gParamExpr )

	' Build table of parameter names
	bFinished = False 
	Do Until ( bFinished )

		' Get parameter
		GetToken 

		Select ( gToken.nType )

		Case TOKEN_TYPE_IDENTIFIER 
			
			' Reserved word?
			If ( gToken.sText = "ce" Or gToken.sText = "cpi" ) Then 
				SetError( gCodeBlock.ERROR_RESERVED_WORD, gToken.sText )
				Exit	
			End If
			
			' Store variable name
			gParameters( gParameterCount ) = gToken.sText
			
			' Increment count
			gParameterCount = gParameterCount + 1 
			
			' Reset comma count
			nCommaCount = 0

		Case TOKEN_TYPE_DELIMITER			

			' Not a comma?
			If ( gToken.sText <> "," ) Then 
				SetError2( gCodeBlock.ERROR_MISSING_COMMA )
				Exit
			End If

			' Missed argument?
			If ( nCommaCount > 0 ) Then 
				SetError2( gCodeBlock.ERROR_MISSING_PARAM )
				Exit
			End If

			' Bump comma count
			nCommaCount = nCommaCount + 1 
			
		Case TOKEN_TYPE_FINISHED 

			If ( nCommaCount > 0 ) Then 
				SetError2( gCodeBlock.ERROR_MISSING_PARAM )
			End If

			bFinished = True 

		Case Else 

			' Invalid value in args list
			SetError2( gCodeBlock.ERROR_MISSING_PARAM )
			
		End Select

		' If error exit loop
		If ( gCodeBlock.Error <> gCodeBlock.ERROR_NONE ) Then 
			bFinished = True
		End If

	Loop
	
	Return ( gCodeBlock.Error ) 
	
End Sub

#if B4I 

'*-------------------------------------------------------- ExtractExpressions
'*
Private Sub ExtractExpressions( cb As Codeblock )  As Int
	Private matchParts As Matcher
	Private sTrimmed As String 
	Private i As Int 
	Private nGroupCount As Int 
	Private nError As Int 
	Private sDetail As String
	Private sGroupText As String

	gEvalExpr = ""
	gParamExpr = ""
	
	' Strip spaces and change case
	sTrimmed = cb.Text.Replace(" ", "" ).ToLowerCase

	' Break expression into component parts
	matchParts = Regex.Matcher(CODEBLOCK_MATCH, sTrimmed )		
	
	' Apply pattern		
	 matchParts.Find

	' Save group count
	nGroupCount = matchParts.GroupCount 

	nGroupCount = nGroupCount - 1 

	' No matches?
	If ( nGroupCount = 0 ) Then 
		Return ( SetError( gCodeBlock.ERROR_SYNTAX, "" ) )
	End If 
	
	' Inspect groups
	For i = 1 To nGroupCount 

		sGroupText = "" 
		Try
			sGroupText = matchParts.Group( i )
						
			' Build detail string
			If ( sGroupText <> Null ) Then 
				sDetail = sDetail & sGroupText
			End If

		    ' Group value missing
			If ( sGroupText = Null ) Then 
			
				' Which one is missing?
				Select( i ) 
				Case GROUP_OPEN_BRACKET
					nError = gCodeBlock.ERROR_MISSING_BRACKET					
				Case GROUP_OPEN_PIPE
					nError = gCodeBlock.ERROR_MISSING_PIPE														
				' Case GROUP_PARAM_EXPR                               ' Param expr null ok.
				'	nError = gCodeBlock.ERROR_MISSING_PARAM														
				Case GROUP_CLOSE_PIPE
					nError = gCodeBlock.ERROR_MISSING_PIPE														
				Case GROUP_EVAL_EXPR
					nError = gCodeBlock.ERROR_MISSING_EXPR 														
				Case GROUP_CLOSE_BRACKET
					nError = gCodeBlock.ERROR_MISSING_BRACKET					
				End Select
			
			End If 
		Catch
			nError = gCodeBlock.ERROR_SYNTAX
		End Try


		' If error found, complete detail and return here
		If ( nError <> gCodeBlock.ERROR_NONE)  Then 
			sDetail = sDetail & " <e" & nError & ">"
			SetError( nError, sDetail )
			Return ( nError ) 
		End If
				
	Next

	' RegEx should create six groups
	If ( nGroupCount = 6 ) Then 

		 ' Store parameter expression
		 If ( matchParts.Group( GROUP_PARAM_EXPR ) <> Null ) Then 
			gParamExpr = matchParts.Group( GROUP_PARAM_EXPR )  ' a,b,c
		End If

		' Store main expression
		gEvalExpr  = matchParts.Group( GROUP_EVAL_EXPR )  ' 1 * a + c * 5
		
		' And it's not zero length
		If ( gEvalExpr.Length <> 0 ) Then
			Return ( gCodeBlock.ERROR_NONE )
		End If 
							
	End If 

	' Set syntax error
	nError = gCodeBlock.ERROR_SYNTAX
	sDetail = sDetail & " <e" & nError & ">"
	
	Return ( SetError( nError, sDetail ) )
	
End Sub

#else

'*-------------------------------------------------------- ExtractExpressions
'*
Private Sub ExtractExpressions( cb As Codeblock )  As Int
	Private matchParts As Matcher
	Private sTrimmed As String 
	Private i As Int 
	Private nGroupCount As Int 
	Private nError As Int 
	Private sDetail As String

	gEvalExpr = ""
	gParamExpr = ""
	
	' Strip spaces and change case
	sTrimmed = cb.Text.Replace(" ", "" ).ToLowerCase

	' Break expression into component parts
	matchParts = Regex.Matcher(CODEBLOCK_MATCH, sTrimmed )		
	
	' Apply pattern		
	matchParts.Find

	' Save group count
	nGroupCount = matchParts.GroupCount 

	' No matches?
	If ( nGroupCount = 0 ) Then 
		Return ( SetError( gCodeBlock.ERROR_SYNTAX, "" ) )
	End If 
	
	' Inspect groups
	For i = 1 To nGroupCount 
		
		' Build detail string
		If ( matchParts.Group( i ) <> Null ) Then 
			sDetail = sDetail & matchParts.Group( i )
		End If

	    ' Group value missing
		If ( matchParts.Group( i ) = Null ) Then 
		
			' Which one is missing?
			Select( i ) 
			Case GROUP_OPEN_BRACKET
				nError = gCodeBlock.ERROR_MISSING_BRACKET					
			Case GROUP_OPEN_PIPE
				nError = gCodeBlock.ERROR_MISSING_PIPE														
			' Case GROUP_PARAM_EXPR                               ' Param expr null ok.
			'	nError = gCodeBlock.ERROR_MISSING_PARAM														
			Case GROUP_CLOSE_PIPE
				nError = gCodeBlock.ERROR_MISSING_PIPE														
			Case GROUP_EVAL_EXPR
				nError = gCodeBlock.ERROR_MISSING_EXPR 														
			Case GROUP_CLOSE_BRACKET
				nError = gCodeBlock.ERROR_MISSING_BRACKET					
			End Select
		
		End If 

		' If error found, complete detail and return here
		If ( nError <> gCodeBlock.ERROR_NONE)  Then 
			sDetail = sDetail & " <e" & nError & ">"
			SetError( nError, sDetail )
			Return ( nError ) 
		End If
				
	Next

	' RegEx should create six groups
	If ( nGroupCount = 6 ) Then 

		 ' Store parameter expression
		 If ( matchParts.Group( GROUP_PARAM_EXPR ) <> Null ) Then 
			gParamExpr = matchParts.Group( GROUP_PARAM_EXPR )  ' a,b,c
		End If

		' Store main expression
		gEvalExpr  = matchParts.Group( GROUP_EVAL_EXPR )  ' 1 * a + c * 5
		
		' And it's not zero length
		If ( gEvalExpr.Length <> 0 ) Then
			Return ( gCodeBlock.ERROR_NONE )
		End If 
							
	End If 

	' Set syntax error
	nError = gCodeBlock.ERROR_SYNTAX
	sDetail = sDetail & " <e" & nError & ">"
	
	Return ( SetError( nError, sDetail ) )
	
End Sub

#end if 

'*----------------------------------------------------------------- Tokenize
'*
Private Sub Tokenize( sExpr As String ) As List 
	Private lstTokens As List 
	Private matchExpr As Matcher
	
	lstTokens.Initialize

	matchExpr = Regex.Matcher(TOKENIZER_MATCH, sExpr)

	' Extract tokens	 
	Do While ( matchExpr.Find = True ) 
		lstTokens.Add( matchExpr.Match )
	Loop
	
	' Reset navigation
	gTokenIndex    = -1
	gTokenEndIndex = lstTokens.Size - 1 
		
	Return ( lstTokens )
	
End Sub


'*----------------------------------------------------------------- GetToken
'*
Private Sub GetToken As Int
	Private sMatch As String 
	' Private sLeadChar As String
	
	' Init token
	gToken.nType = TOKEN_TYPE_NONE
	gToken.sText = NULL_TOKEN

	'Advance index 
	gTokenIndex = gTokenIndex + 1 
	
	'If index is past the end, no more tokens	
	If ( gTokenIndex > gTokenEndIndex ) Then 
		gToken.nType = TOKEN_TYPE_FINISHED
		Return  (gToken.nType)
	End If

	' Get token
	sMatch = gTokenList.Get( gTokenIndex ) 

	'Mtelog.Dbg( "sMatch=" & sMatch )
	'Log( "sMatch=" & sMatch )
		
	' Relational operator?
	If ( Regex.IsMatch("<=|>=|==|<|>|!=|\|\||&&|&", sMatch)  = True ) Then 
		
		gToken.sText = sMatch
		gToken.nType = TOKEN_TYPE_DELIMITER
		Return ( gToken.nType )

	End If

	' Bit Shift operator?
	If ( Regex.IsMatch("<<|>>", sMatch)  = True ) Then 
		
		gToken.sText = sMatch
		gToken.nType = TOKEN_TYPE_DELIMITER
		Return ( gToken.nType )

	End If

	' General Delimeter? 
	If ( Regex.IsMatch("[+\-*^/%(),!|~=]", sMatch)  = True ) Then 
	
		gToken.sText = sMatch
		gToken.nType = TOKEN_TYPE_DELIMITER
		Return ( gToken.nType ) 

	End If 

	' Is Hex Number? 
	If ( Regex.IsMatch("0x[\.\da-z]+", sMatch) = True ) Then 

		gToken.sText = sMatch
		gToken.nType = TOKEN_TYPE_HEX_NUMBER
		Return ( gToken.nType )
		
	End If

	' Number?
	If ( IsNumber( sMatch ) = True ) Then 

		gToken.sText = sMatch
		gToken.nType = TOKEN_TYPE_NUMBER
		Return ( gToken.nType )

	End If
	
	' Is it a word?
	If ( Regex.IsMatch( "\w+", sMatch ) = True ) Then 
		
		gToken.sText = sMatch 
		gToken.nType = TOKEN_TYPE_IDENTIFIER
		
	' Unknown
	Else 

		SyntaxError( gCodeBlock.ERROR_OTHER )
		
		gToken.sText = sMatch		
		gToken.nType = TOKEN_TYPE_UNKNOWN
		
	End If

	Return ( gToken.nType ) 

End Sub

'*------------------------------------------------------------ EvalExpression
'*
Private Sub EvalExpression  As Boolean
	Private bSuccess As Boolean 
	
	' Get this party started! 
	GetToken

	' Evaluate assignment
	bSuccess = EvalAssignment 
	If ( bSuccess = ABORT ) Then Return ( ABORT )
	
	' Return token to the input stream. This is needed due to "look ahead" 
	' nature of the parser.  
	bSuccess = PutBack
	If ( bSuccess = ABORT ) Then Return ( ABORT )
		

	Return ( SUCCESS )
End Sub

'*------------------------------------------------------------- EvalAssignment
'*
Private Sub EvalAssignment As Boolean
	Private bSuccess As Boolean
	Private nVarIndex As Int
	Private bSuccess As Boolean
	Private tSaveToken As MTE_TOKEN
	
	' Possible variable?	
	If ( gToken.nType = TOKEN_TYPE_IDENTIFIER ) Then 
	
		' Look for it
		nVarIndex = FindParameter( gToken.sText )
		If ( nVarIndex >= 0 ) Then 

			' Save token
			tSaveToken.sText = gToken.sText
			tSaveToken.nType = gToken.nType

			' Assignment operator?		
			GetToken
			If ( gToken.sText = "=" ) Then 
			
				' Could be a series of assignments
				GetToken
				bSuccess = EvalAssignment
				If ( bSuccess = ABORT ) Then Return ( ABORT )
									
					' Store in memory				
					DoStoreVariable( nVarIndex )
			
					' Done
					Return ( SUCCESS )

			' Not an assignment?
			Else 

				' Put back in stream
				PutBack
		
				' Restore token
				gToken.sText = tSaveToken.sText
				gToken.nType = tSaveToken.nType
		
			End If 
				
		End If 	

	End If 
	
	' Next precedence
	bSuccess = EvalLogicalOr 
	If ( bSuccess = ABORT ) Then Return ( ABORT )
	
	Return ( SUCCESS ) 

End Sub


'*-------------------------------------------------------------- EvalLogicalOr
'*
Private Sub EvalLogicalOr As Boolean
	Private sOperator As String
	Private nDropOut As Int 
	Private bSuccess As Boolean
			
	' Next precedence
	bSuccess = EvalLogicalAnd
	If ( bSuccess = ABORT ) Then Return ( ABORT )
	
	' Save operator on local stack
	sOperator = gToken.sText 

	' Process Or	
	Do While ( sOperator = "||" ) 
		
		' Gen label for dropout
		nDropOut = NewLabel
		
		' If true skip right operand 
		BranchTrue( nDropOut ) 
		
		' Push, get, and do next level
		Push
		GetToken 
	    bSuccess = EvalLogicalAnd
		If ( bSuccess = ABORT ) Then Return ( ABORT )
		
		' Gen code
		DoLogicalOr

		' Post dropout label
		PostLabel( nDropOut ) 

		' Update operator 
		sOperator = gToken.sText 

	Loop
	
	Return ( SUCCESS ) 

End Sub

'*------------------------------------------------------------- EvalLogicalAnd
'*
Private Sub EvalLogicalAnd As Boolean
	Private sOperator As String 
	Private nDropOut As Int 
	Private bSuccess As Boolean

	' Next higher precedence		
	bSuccess = EvalBitwiseAndOrXor
	If ( bSuccess = ABORT  ) Then Return ( ABORT )
	
	' Save operator on local stack
	sOperator = gToken.sText 

	' Process And	
	Do While ( sOperator = "&&" ) 
		
		' Gen label for dropout
		nDropOut = NewLabel
		
		' If false skip right operand 
		BranchFalse( nDropOut ) 
		
		' Push, get, do next level
		Push
		GetToken 
		
		bSuccess = EvalBitwiseAndOrXor
		If ( bSuccess = ABORT  ) Then Return ( ABORT )
	
		' Gen code
		DoLogicalAnd

		' Post dropout label
		PostLabel( nDropOut ) 

		' Update operator 
		sOperator = gToken.sText 
		
	Loop
		
	Return ( SUCCESS ) 		
		
End Sub

'*---------------------------------------------------------------- EvalBitwise
'*
Private Sub EvalBitwiseAndOrXor As Boolean
	Private sOperator As String 
	Private bSuccess As Boolean 

	' Next higher precedence	
    bSuccess = EvalRelational
	If ( bSuccess = ABORT ) Then Return ( ABORT )
	
	' Store operator on local stack
	sOperator = gToken.sText

	' While And, Xor, Or 	
	Do While ( Regex.IsMatch("&|\^|\|", sOperator )  = True )  
	
		' Push on stack and continue
		Push
		GetToken

  		bSuccess = EvalRelational
		If ( bSuccess = ABORT  ) Then Return ( ABORT )
		
		' Generate code
		Select sOperator
		Case "&"
			DoBitwiseAnd
		Case "|"
			DoBitwiseOr
		Case "^"
			DoBitwiseXor
		End Select
		
		' Update operator as token may have changed
		sOperator = gToken.sText
		
	Loop
	
	Return ( SUCCESS  )

End Sub	

'*------------------------------------------------------------- EvalRelational
'*
Private Sub EvalRelational As Boolean
	Private sOperator As String 
	Private bSuccess As Boolean 
		
	' Next higher rprecedence
	bSuccess = EvalBitShift
	If ( bSuccess = ABORT  ) Then Return ( ABORT )
	
	' Save operator on local stack
	sOperator = gToken.sText 
	
	' Relational operator?
	If ( Regex.IsMatch("<=|>=|==|(?<!:)<(?!<)|(?<!>)>(?!>)|!=", sOperator )  = True ) Then 

		'Push, get, and do next level
		Push
		GetToken 

		bSuccess = EvalBitShift
		If ( bSuccess = ABORT  ) Then Return ( ABORT )
		
		'Which one? 
		Select ( sOperator ) 
		Case "<"                               ' LT
			DoLess
		Case "<="                              ' LE
			DoLessEqual
		Case ">"                               ' GT
			DoGreater
		Case ">="                              ' GE
			DoGreaterEqual
		Case "=="                              ' EQ
			DoEqual
		Case "!="                              ' NE			 
			DoNotEqual
		End Select
		
	End If
	
	Return ( SUCCESS )
	
End Sub

'*---------------------------------------------------------------- EvalBitShift
'*
Private Sub EvalBitShift As Boolean
	Private sOperator As String 
	Private bSuccess As Boolean 

	' Next higher precedence
    bSuccess = EvalAddSub
	If ( bSuccess = ABORT ) Then Return ( ABORT ) 

	sOperator = gToken.sText 
	
	' Bit shift?
	If ( Regex.IsMatch("<<|>>", sOperator )  = True ) Then 

		'Push, get, and do next level
		Push
		GetToken 

		bSuccess = EvalAddSub
		If ( bSuccess = ABORT  ) Then Return ( ABORT )
		
		'Which one? 
		Select ( sOperator ) 
		Case "<<"                               
			DoBitShiftLeft
		Case ">>"                               
			DoBitShiftRight
		End Select

	End If
	
	Return ( SUCCESS )
	
End Sub 

'*----------------------------------------------------------------- EvalAddSub
'* 
Private Sub EvalAddSub As Boolean
	Private sOperator As String 
	Private bSuccess As Boolean
		
	' Next higher precedence	
	bSuccess = EvalFactor
	If ( bSuccess = ABORT ) Then Return ( ABORT )
	
	' Store operator on local stack
	sOperator = gToken.sText

	' While add or subtract	
	Do While ( Regex.IsMatch("[+\-]", sOperator )  = True )  
	
		' Push on stack and continue
		Push
		GetToken

		bSuccess = EvalFactor
		If ( bSuccess = ABORT  ) Then Return ( ABORT )
		
		' Generate code
		Select sOperator
		Case "-"
			DoSubtract
		Case "+"
			DoAdd
		End Select
		
		' Update operator as token may have changed
		sOperator = gToken.sText
		
	Loop
	
	Return ( SUCCESS  )
	
End Sub

'*----------------------------------------------------------------- EvalFactor
'* 
Private Sub EvalFactor As Boolean
	Private sOperator As String
	Private bSuccess As Boolean

	' Next higher precedence
	bSuccess = EvalUnary
	If ( bSuccess = ABORT  ) Then Return ( ABORT )
	
	' Store operator on local stack
	sOperator = gToken.sText

	'While multiply, divide, or modulous
	Do While ( Regex.IsMatch("[\*/%]", sOperator )  = True )  

		' Push value on stack and continue
		Push
		GetToken
		bSuccess = EvalUnary
		If ( bSuccess = ABORT  ) Then Return ( ABORT )
	
		' Generate code
		Select sOperator
		Case "*"
			DoMultiply
		Case "/"
			DoDivide
		Case "%"
			DoModulo
		End Select
		
		' Update operator as token may have changed
		sOperator = gToken.sText
		
	Loop

	Return ( SUCCESS ) 

End Sub

'*------------------------------------------------------------------ EvalUnary
'* 
Private Sub EvalUnary As Boolean
	Private sOperator As String 
	Private bSuccess As Boolean
		
	' Set operator to null
	sOperator = ""
	
	' Is this a unary operator?
	If ( Regex.IsMatch( "[+\-!~]", gToken.sText ) = True ) Then 
		
		' Save operator on local stack and continue
		sOperator = gToken.sText 
		GetToken
		bSuccess = EvalUnary
		If ( bSuccess = ABORT  ) Then Return ( ABORT )
			
	Else 
		
		' Next higher precedence
		bSuccess = EvalParen
		If ( bSuccess = ABORT  ) Then Return ( ABORT )
				
	End If

	' Which one?
	Select sOperator 
	Case "-"
		DoNegate
	Case "!"
		DoLogicalNot					
	Case "~"
		DoBitNot
	End Select

	Return ( SUCCESS ) 
	
End Sub 

'*----------------------------------------------------------------- EvalParen
'* 
Private Sub EvalParen() As Boolean
	Private bSuccess As Boolean
	Private bFinished As Boolean
	
	' Is this an open parenthesis?
	If ( gToken.sText = "(" ) Then
		
		' Count open/close parenthesis
		gParenCount = gParenCount + 1
		
		'Mtelog.Dbg( "( Open paren" )
		
		' Get token
		GetToken
		
		' Eval sub expression
		bFinished = False
		Do Until (bFinished) 

			' Eval sub expression
			bSuccess = EvalAssignment
			If ( bSuccess = ABORT  ) Then Return ( ABORT )

			' If comma, then continue otherwise finish	
			If ( gToken.sText = "," ) Then 
				GetToken
			Else 
				bFinished = True 
			End If

		Loop

		' Expecting a closed parenthesis here
		If ( gToken.sText <> ")" ) Then 
			SyntaxError( gCodeBlock.ERROR_MISSING_PAREN )
			Return ( ABORT )					
		End If

		' Reduce count
		gParenCount = gParenCount - 1
		
		'Mtelog.Dbg( ") Closed paren" )

		' Get next token
		GetToken
						
	Else 
	
		' Next higher precedence
		bSuccess = EvalAtom
		If ( bSuccess = ABORT  ) Then Return ( ABORT )
	
	End If

	Return ( SUCCESS ) 
				
End Sub

'*------------------------------------------------------------------- EvalAtom
'* 
Private Sub EvalAtom As Boolean
	Private nParameterIndex As Int 
	Private bSuccess As Boolean 
		
	Select ( gToken.nType )
	Case TOKEN_TYPE_IDENTIFIER
		
		'Find internal function 
		gFuncInfo = FindInternalFunc( gToken.sText )		

		' If function found 
		If ( gFuncInfo.nPcode > 0 ) Then 
			
			' IIF is special
			If ( gFuncInfo.nPcode = PCODE.FUNC_IIF ) Then 
				
				bSuccess = DoIIF
				If ( bSuccess = ABORT ) Then Return ( ABORT )

			' Call built-in function			
			Else 				

				'Ouput instruction to call function
				bSuccess = DoCallInternalFunc( gFuncInfo )
				If ( bSuccess = ABORT ) Then Return ( ABORT ) 
				
			End If 

		' Either built-in constant or parameter
		Else 
					
			Select ( gToken.sText ) 
			Case  "ce"                         
				DoLoadNumber( cE )
			Case "cpi"						   	   
				DoLoadNumber( cPI )
			Case Else 			
				nParameterIndex = FindParameter( gToken.sText ) 
				If  ( nParameterIndex >= 0 ) Then 
					DoLoadVariable( nParameterIndex )
				Else 
					SyntaxError( gCodeBlock.ERROR_NOT_A_VAR ) 
					Return ( ABORT )
				End If
			End Select
			
		End If 
		
		' Get next token				
		GetToken

	Case TOKEN_TYPE_NUMBER
		
		'Convert string to value
		Private nValue As Double = gToken.sText
				
		' Output instruction to load number
		DoLoadNumber( nValue )
		
		' Get next token
		GetToken

	Case TOKEN_TYPE_DELIMITER

		If ( gToken.sText = ")" And gParenCount = 0 ) Then 
			SyntaxError( gCodeBlock.ERROR_UNBALANCED_PARENS )
			Return ( ABORT )
		End If	
					
		Return ( SUCCESS )

	Case TOKEN_TYPE_FINISHED 

		Return ( SUCCESS )

	Case TOKEN_TYPE_HEX_NUMBER 
		Private nValue As Double
		
		' Convert to decimal
		nValue = Bit.ParseInt( gToken.sText.SubString(2), HEX2DECIMAL )
				
		' Output instruction to load number
		DoLoadNumber( nValue )
		
		' Get next token
		GetToken
				
	Case Else
		
		' Syntax error	
		SyntaxError( gCodeBlock.ERROR_OTHER )
		Return ( ABORT )

	End Select

	Return ( SUCCESS ) 

End Sub


'*--------------------------------------------------------------------- GetArgs
'* 
Private Sub GetArgs( nExpectedArgs As Int ) As Boolean 
	Private bFinished As Boolean 
	Private nArgCount=0 As Int 
	Private bSuccess As Boolean
			
	' Get next token
	GetToken

	' If not a parenthesis	
	If ( gToken.sText <> "(" ) Then 
		SyntaxError( gCodeBlock.ERROR_MISSING_PAREN ) 
		Return ( ABORT )
	End If

	'  Get next token
	GetToken

	' If closing paren, no args.  
	If ( gToken.sText = ")" ) Then 
		Return ( SUCCESS )
	End If
	
	' Return token to stream
	PutBack

	bFinished = False
	Do Until ( bFinished ) 
		
		' Parse arguments
		bSuccess = EvalExpression
		If ( bSuccess = ABORT  ) Then Return ( ABORT )

		' Count args.  Too many?
		nArgCount = nArgCount + 1
		If ( nArgCount > nExpectedArgs ) Then 
			SyntaxError( gCodeBlock.ERROR_TOO_MANY_ARGS ) 
			Return ( ABORT )
		End If
		
		' Push value on stack and get next token
		Push
		GetToken				
		
		' If no comma, we've consumed all the arguments
		If ( gToken.sText <> "," ) Then 
			bFinished = True
		End If
	
	Loop

	' Short arguments? 
	If ( nArgCount < nExpectedArgs ) Then 
		SyntaxError( gCodeBlock.ERROR_INSUFFICIENT_ARGS) 
		Return ( ABORT )
	End If
			
	' Should be closing paren here
	If ( gToken.sText <> ")" ) Then
		SyntaxError( gCodeBlock.ERROR_MISSING_PAREN ) 
		Return ( ABORT )
	End If
	
	Return ( SUCCESS ) 

End Sub

'*--------------------------------------------------------------------- PutBack
'*
Private Sub PutBack As Boolean 

	' Safety check to prevent parser from hanging on bug
	If ( gPutBackIndex = gTokenIndex ) Then 
		gPutBackCount = gPutBackCount + 1 
		If ( gPutBackCount > 5 ) Then 
			SyntaxError( gCodeBlock.ERROR_PUTBACK )
			Return ( ABORT )
		End If			
	Else 
		gPutBackIndex = gTokenIndex 
		gPutBackCount = 0
	End If

	' Decrement token index  
	gTokenIndex = gTokenIndex - 1 

		 
	 Return ( SUCCESS )
	 
End Sub


'*----------------------------------------------------------------------- Push
'*
Private Sub Push

	DoPush
	
End Sub

'***************************************************************************
'* 
'* Code Generator
'* 
'***************************************************************************

'*------------------------------------------------------------- EmitCodeHeader
'* 
Private Sub EmitCodeHeader( nParamCount As Int )

	gBytecode.Add( nParamCount )
	gIsPcode.Add( False )
	gCodeIndex = gCodeIndex + 1

End Sub 

'*--------------------------------------------------------------- GetShortCode
'* 
Private Sub GetShortCode( nIndex As Int ) As Int
	Private nPcode As Int 
	nPcode = gBytecode.Get( nIndex ) 
	Return ( nPcode ) 
End Sub


'*-------------------------------------------------------------- EmitShortCode
'* 
Private Sub EmitShortCode( nPcode As Int )
	
	' Add instruction
	gBytecode.Add( nPcode )
	gIsPcode.Add( True ) 
	gCodeIndex = gCodeIndex + 1
		
End Sub

'*------------------------------------------------------------ EmitShortCodeAt
'* 
Private Sub EmitShortCodeAt( nIndex As Int, nPcode As Int )
	
	' Change instruction 
	gBytecode.Set( nIndex, nPcode ) 
		
End Sub

'*--------------------------------------------------------------- EmitLongCode
'* 
Private Sub EmitLongCode( nPcode As Int, nValue As Int )

	' Add Pcode
	gBytecode.Add( nPcode )
	gIsPcode.Add( True )
	gCodeIndex = gCodeIndex + 1

	' Add value inline
	gBytecode.Add( nValue ) 
	gIsPcode.Add( False )
	gCodeIndex = gCodeIndex + 1
	
End Sub

'*---------------------------------------------------------------- AddConstant
'* 
Private Sub AddConstant(  nValue As Double ) As Int
	
	gConstdata.Add( nValue ) 
	Return ( gConstdata.Size - 1 ) 
	
End Sub

'*--------------------------------------------------------- DoCallInternalFunc
'* 
Private Sub DoCallInternalFunc( tFuncInfo As MTE_FUNC_INFO ) As Boolean
	Private bSuccess As Boolean
	
	'Mtelog.Dbg( "DoInternalFunc")
	
	' Get arguments and push on stack
	bSuccess = GetArgs( tFuncInfo.nArgCount ) 
	If ( bSuccess = ABORT ) Then Return ( ABORT ) 

	' Call func	
	EmitShortCode( tFuncInfo.nPcode )	
			
	Return ( SUCCESS ) 
				
End Sub

'*---------------------------------------------------------------------- DoIFF
'* 
'* After GetToken returns the TokenIndex is here
'* ----------------------------------------------
'*  1. IIF( ..., ..., ...)
'*        ^
'*  2. IIF( ..., ..., ...)
'*             ^
'*  3. IIF( ..., ..., ...)
'*                  ^
'*  4. IIF( ..., ..., ...)
'*                       ^
'*                       
Private Sub DoIIF As Boolean
	Private nIfFalse As Int 
	Private nEndofIf As Int 
	Private bSuccess As Boolean
		
	'Mtelog.Dbg( "DoIIF")
											
	' 1. Get next token
	GetToken

	' If not a parenthesis	
	If ( gToken.sText <> "(" ) Then 
		SyntaxError( gCodeBlock.ERROR_MISSING_PAREN )
		Return ( ABORT )
	End If

	' Eval conditional expression
	bSuccess = EvalExpression
	If ( bSuccess = ABORT ) Then Return ( ABORT )
	
	' Get labels
	nIfFalse = NewLabel 
	
	' Always "else" with iif() so no need for this here
	' nEndofIf = nIfFalse 
	
	' 2. Get next token
	GetToken

	' Expect a comma here
	If ( gToken.sText <> "," ) Then 
		SyntaxError( gCodeBlock.ERROR_MISSING_COMMA ) 
		Return ( ABORT )
	End If

	' Set false branch
	BranchFalse(nIfFalse)
	
	' Get Then condition 
	bSuccess = EvalExpression 
	If ( bSuccess = ABORT ) Then Return ( ABORT ) 
			
	' 3. Get next token
	GetToken			
	
	' Expect a comma here
	If ( gToken.sText <> "," ) Then 
		SyntaxError( gCodeBlock.ERROR_MISSING_COMMA )
		Return ( ABORT )
	End If
	
	' Post label for "Else"
	nEndofIf = NewLabel
	Branch( nEndofIf )
	PostLabel( nIfFalse )
	
	' Compile Else condition
	bSuccess = EvalExpression 
	If ( bSuccess = ABORT ) Then Return ( ABORT )

	' 4. Get Next token
	GetToken				

	' Should be closing paren
	If ( gToken.sText <> ")" ) Then
		SyntaxError( gCodeBlock.ERROR_MISSING_PAREN )
		Return ( ABORT )
	End If

	' End of IIF
	PostLabel( nEndofIf ) 

	Return ( SUCCESS )
			
End Sub

'*--------------------------------------------------------------------------
'* 
Private Sub DoBitwiseAnd 
	'Mtelog.Dbg( "DoBitwiseAnd()" )
	EmitShortCode( PCODE.BIT_AND ) 
End Sub

'*--------------------------------------------------------------------------
'* 
Private Sub DoBitwiseOr
	'Mtelog.Dbg( "DoBitwiseOr()" )
	EmitShortCode( PCODE.BIT_OR ) 
End Sub

'*--------------------------------------------------------------------------
'* 
Private Sub DoBitwiseXor
	'Mtelog.Dbg( "DoBitwiseXor()" )
	EmitShortCode( PCODE.BIT_XOR ) 
End Sub


'*--------------------------------------------------------------------------
'* 
Private Sub DoBitShiftLeft
	'Mtelog.Dbg( "DoBitShiftLeft()" )
	EmitShortCode( PCODE.BIT_SHIFT_LEFT ) 
End Sub

'*--------------------------------------------------------------------------
'* 
Private Sub DoBitShiftRight
	'Mtelog.Dbg( "DoBitShiftRight()" )
	EmitShortCode( PCODE.BIT_SHIFT_RIGHT ) 
End Sub

'*-----------------------------------------------------------------
'* 
Private Sub DoBitNot
	'Mtelog.Dbg( "DoBitNot()" )
	EmitShortCode( PCODE.BIT_NOT ) 
End Sub

'*------------------------------------------------------------- DoLoadNumber
'* 
 Sub DoLoadNumber( nValue As Double ) 
	Private nConstIndex As Int 
	
	' Add constant to table
	nConstIndex = AddConstant( nValue ) 

	'Mtelog.Dbg( "DoLoadNumber(), nValue=" & nValue ) 
	EmitLongCode( PCODE.LOADCONST, nConstIndex ) 
	
End Sub

'*----------------------------------------------------------- DoLoadVariable
'* 
Private Sub DoLoadVariable( nIndex As Int )
	
	'Mtelog.Dbg( "DoLoadVariable") 
	EmitLongCode( PCODE.LOADVAR, nIndex  ) 

End Sub

'*---------------------------------------------------------- DoStoreVariable
'*
Sub DoStoreVariable( nVarIndex As Int  ) 

	'Mtelog.Dbg( "DoStoreVariable") 
	EmitLongCode( PCODE.STOREVAR, nVarIndex  ) 
	
End Sub


'*--------------------------------------------------------------------------
'* 
Private Sub DoMultiply

	'Mtelog.Dbg( "DoMultiply" )
	EmitShortCode( PCODE.MULTIPLY ) 

End Sub

'*--------------------------------------------------------------------------
'* 
Private Sub DoDivide

	'Mtelog.Dbg( "DoDivide" )
	EmitShortCode( PCODE.DIVIDE ) 
		
End Sub

'*--------------------------------------------------------------------------
'* 
Private Sub DoModulo

	'Mtelog.Dbg( "DoModulo" )
	EmitShortCode( PCODE.MODULO ) 
		
End Sub

'*--------------------------------------------------------------------------
'* 
Private Sub DoNegate

	'Mtelog.Dbg( "DoNegate" )
	EmitShortCode( PCODE.NEG ) 

End Sub

'*--------------------------------------------------------------------------
'* 
Private Sub DoLogicalNot

	'Mtelog.Dbg( "DoLogicalNot" )
	EmitShortCode( PCODE.LOGICAL_NOT ) 
	
End Sub


'*--------------------------------------------------------------------------
'* 
Private Sub DoSubtract

	'Mtelog.Dbg( "DoSubtract") 
	EmitShortCode( PCODE.SUBTRACT ) 
	
End Sub

'*--------------------------------------------------------------------------
'* 
Private Sub DoAdd

	'Mtelog.Dbg( "DoAdd") 
	EmitShortCode( PCODE.ADD ) 
	
End Sub

'*--------------------------------------------------------------------------
'* 
Private Sub DoLess

	'Mtelog.Dbg( "DoLess") 
	EmitShortCode( PCODE.LESS_THAN )

End Sub

'*--------------------------------------------------------------------------
'* 
Private Sub DoLessEqual

	'Mtelog.Dbg( "DoLessEqual") 
	EmitShortCode( PCODE.LESS_EQUAL )

End Sub

'*--------------------------------------------------------------------------
'* 
Private Sub DoGreater

	'Mtelog.Dbg( "DoGreater") 
	EmitShortCode( PCODE.GREATER_THAN )
	
End Sub

'*--------------------------------------------------------------------------
'* 
Private Sub DoGreaterEqual

	'Mtelog.Dbg( "DoGreaterEqual") 
	EmitShortCode( PCODE.GREATER_EQUAL )

End Sub 

'*--------------------------------------------------------------------------
'* 
Private Sub DoEqual 

	'Mtelog.Dbg( "DoEqual") 
	EmitShortCode( PCODE.EQUAL )

End Sub 

'*--------------------------------------------------------------------------
'* 
Private Sub DoNotEqual 

	'Mtelog.Dbg( "DoNotEqual") 
	EmitShortCode( PCODE.NOT_EQUAL )

End Sub

'*--------------------------------------------------------------------------
'* 
Private Sub DoPush
	Private nPeepIndex As Int 
	Private nPeep As Int 
	
	'Mtelog.Dbg("DoPush")

    ' If optimizer enabled, attempt "peephole" optimization of push
	If ( gCodeBlock.OptimizerEnabled = True  ) Then 
	
       	' "Peep" at previous instruction
        nPeepIndex = gCodeIndex - 2
        If ( nPeepIndex > 0 And gIsPcode.Get(nPeepIndex) = True )  Then 
			nPeep = GetShortCode( nPeepIndex ) 
		Else 
			nPeep = PCODE.NONE 
		End If

        ' Optimize loadvar and loadconst
        Select (nPeep) 
            Case PCODE.LOADVAR
                EmitShortCodeAt( nPeepIndex, PCODE.PUSHVAR )   ' Push var directly on stack
            Case PCODE.LOADCONST:
                EmitShortCodeAt( nPeepIndex, PCODE.PUSHCONST ) ' Push const directly on stack
            Case Else 	
                EmitShortCode( PCODE.PUSH )
		End Select
	Else 
		EmitShortCode( PCODE.PUSH )
	End If

End Sub 

'*--------------------------------------------------------------------------
'* 
Private Sub DoEndCode
	
	'Mtelog.Dbg("DoEndCode")
	EmitShortCode( PCODE.ENDCODE )

End Sub 

'*--------------------------------------------------------------------------
'* 
Private Sub NewLabel As Int
	Private nNextLabelIndex As Int 
	nNextLabelIndex = gLabelIndex
	gLabelIndex = gLabelIndex + 1 
	Return ( nNextLabelIndex )
End Sub


'*--------------------------------------------------------------------------
'* 
Private Sub AddJump ( nTargetIndex As Int ) 
	
	' Save the location of the jump instruction in the code
	gJumpTable( gJumpCount ).nCodeIndex  = gCodeIndex  
	
	' Label will have the codeindex where we should jump to
	gJumpTable( gJumpCount ).nLabelIndex = nTargetIndex

	' Bump count
	gJumpCount = gJumpCount + 1	
		
End Sub

'*--------------------------------------------------------------- FixupJumps
'*
Private Sub  FixupJumps 
	Private i As Int 
	Private nCodeIndex As Int
	Private nJumpToIndex As Int
	Private nJumpOffset As Int 
	Private nLastJump As Int 
	
	' Any jumps to fixup?
	If ( gJumpCount > 0 ) Then 
		
		' Fix jumps
		nLastJump = gJumpCount - 1 
		For i = 0 To nLastJump
			
			' This is the location of the jump Pcode
			nCodeIndex = gJumpTable(i).nCodeIndex

			' This is the index where we want to jump to
			nJumpToIndex = gLabelTargets( gJumpTable(i).nLabelIndex ) 

			' Calculate the offset 
			nJumpOffset =  (nJumpToIndex - nCodeIndex) - 1  
					
			' Replace inline value with the correct offset
			gBytecode.Set( nCodeIndex + 1, nJumpOffset)
			
		Next
	
	End If
		
	' Reset jumps and label counts
	gJumpCount  = 0 
	gLabelIndex = 0
	
End Sub

'*--------------------------------------------------------------------------
'* 
Private Sub PostLabel( nLabelIndex As Int ) 
	
	' This is the location (codeindex) where this label should jump to
	gLabelTargets( nLabelIndex ) = gCodeIndex
		
End Sub

'*--------------------------------------------------------------------------
'* 
Private Sub Branch( nLabelIndex As Int ) 

	'Mtelog.Dbg("Branch")
		
	' Add to jump table
	AddJump( nLabelIndex ) 

	' Add jump to code	
	EmitLongCode( PCODE.JUMP_ALWAYS, 0 )
	
End Sub

'*--------------------------------------------------------------------------
'* 
Private Sub BranchFalse( nLabelIndex As Int ) 

	'Mtelog.Dbg("BranchFalse")

	' Add to jump table
	AddJump( nLabelIndex ) 

	' Add jump to code	
	EmitLongCode( PCODE.JUMP_FALSE, 0 )
	
End Sub


'*--------------------------------------------------------------------------
'* 
Private Sub BranchTrue( nLabelIndex As Int ) 

	'Mtelog.Dbg("BranchTrue")
		
	' Add to jump table
	AddJump( nLabelIndex ) 

	' Add jump to code	
	EmitLongCode( PCODE.JUMP_TRUE, 0 )
	
End Sub

'*--------------------------------------------------------------------------
'* 
Private Sub DoLogicalOr
	
	'Mtelog.Dbg( "DoLogicalOr" )
	EmitShortCode( PCODE.LOGICAL_OR )

End Sub

'*--------------------------------------------------------------------------
'* 
Private Sub DoLogicalAnd

	'Mtelog.Dbg( "DoLogicalAnd" )
	EmitShortCode( PCODE.LOGICAL_AND )

End Sub


'*------------------------------------------------------------ FindParameter
'* 
Private Sub FindParameter( sName As String ) As Int 
	Private nIndex As Int 
	Private nLastParam As Int

	' No parameters?
	If ( gParameterCount = 0  )  Then
		Return ( -1 )
	End If

	' Find parameter in list
	nLastParam = gParameterCount - 1
	For nIndex = 0 To nLastParam 
		If ( gParameters( nIndex ) = sName ) Then 
			Return ( nIndex )
		End If
	Next

	Return ( -1 )
End Sub


'***************************************************************************
'* 
'* Error
'* 
'***************************************************************************

'*---------------------------------------------------------------- SetError
'*
Private Sub SetError( nError As Int, sDetail As String )  As Int
	Private sDesc As String 
		
	' Get error description
	Select( nError ) 
	Case gCodeBlock.ERROR_MISSING_BRACKET					
		sDesc = "{ } bracket not found."
	Case gCodeBlock.ERROR_MISSING_PIPE														
		sDesc = "| | pipe not found."
	Case gCodeBlock.ERROR_MISSING_PAREN
		sDesc = "Missing parenthesis."
	Case gCodeBlock.ERROR_MISSING_PARAM
		sDesc = "Missing parameter."														
	Case gCodeBlock.ERROR_MISSING_EXPR					
		sDesc = "Missing expression."
	Case gCodeBlock.ERROR_RESERVED_WORD
		sDesc = "Reserved word." 
	Case gCodeBlock.ERROR_MISSING_COMMA
		sDesc = "Missing comma."
	Case gCodeBlock.ERROR_MISSING_ARG
		sDesc = "Missing argument."
	Case gCodeBlock.ERROR_TOO_MANY_ARGS
		sDesc = "Too many arguments."
	Case gCodeBlock.ERROR_INSUFFICIENT_ARGS
		sDesc = "Insufficient arguments."
	Case gCodeBlock.ERROR_NOT_A_VAR
		sDesc = "Unknown parameter."
	Case gCodeBlock.ERROR_UNBALANCED_PARENS
		sDesc = "Unbalanced parens."
	Case gCodeBlock.ERROR_PUTBACK
		sDesc = "Internal parser error."
	Case gCodeBlock.ERROR_UNSUPPORTED_OPER
		sDesc = "Unsupported operator"
	Case Else 
		sDesc = "Syntax error."				
	End Select

	' Store error
	gCodeBlock.Error = nError
	gCodeBlock.ErrorDesc = sDesc
	gCodeBlock.ErrorDetail = sDetail

	'Mtelog.Console( "Error: nError=" & nError & " - " & sDesc )
	'Mtelog.Console( "Error: " & sDetail )

	Return ( nError )	
End Sub

'*---------------------------------------------------------------- SetError2
'*
Private Sub SetError2( nError As Int ) As Int
	Private sDetail As String 
		
	' Build detail string from tokens
	 sDetail = BuildErrorDetail( nError ) 
	 		
	' Set error in Codeblock
	SetError( nError, sDetail ) 
	
	Return ( nError )
End Sub

'*--------------------------------------------------------- BuildErrorDetail
'*
Private Sub  BuildErrorDetail( nError As Int ) As String 
	Private i As Int
	Private k As Int
	Private sb As StringBuilder

	If ( gTokenIndex < 0 Or gTokenList.Size = 0 ) Then 
		Return ( "" ) 
	End If 		
	
	' Build detail from tokens
	sb.Initialize
	k = Min( gTokenIndex, gTokenEndIndex )
	For i = 0 To k 
		sb.Append( gTokenList.Get( i )  )
	Next

	' Add error code
	sb.Append( " <e" )
	sb.Append( nError )
	sb.Append( ">" )
	
	Return ( sb.ToString )
	
End Sub

'*------------------------------------------------------------- Syntax Error
'* 
Private Sub SyntaxError( nError As Int ) 

	' Set error in codeblock with detail
	SetError2( nError )
	
End Sub