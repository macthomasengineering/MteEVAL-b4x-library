/**********************************************************************************
 '*
 '* Codegen.java - Parser and code generator
 '*
 **********************************************************************************/
/**********************************************************************************
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
 **********************************************************************************/
package com.macthomasengineering.mteevals2;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.regex.*;
import anywheresoftware.b4a.BA;


@BA.Hide
// Internal func table
enum InternalFunc {

    FUNC_ABS(           "abs",          Pcode.FUNC_ABS,     1 ),
    FUNC_IIF(           "iif",          Pcode.FUNC_IIF,     3 ),
    FUNC_IF(            "if",           Pcode.FUNC_IIF,     3 ),
    FUNC_MAX(           "max",          Pcode.FUNC_MAX,     2 ),
    FUNC_MIN(           "min",          Pcode.FUNC_MIN,     2 ),
    FUNC_SQRT(          "sqrt",         Pcode.FUNC_SQRT,    1 ),
    FUNC_POWER(         "power",        Pcode.FUNC_POWER,   2 ),
    FUNC_ROUND(         "round",        Pcode.FUNC_ROUND,   1 ),
    FUNC_FLOOR(         "floor",        Pcode.FUNC_FLOOR,   1 ),
    FUNC_CEIL(          "ceil",         Pcode.FUNC_CEIL,    1 ),
    FUNC_COS(           "cos",          Pcode.FUNC_COS,     1 ),
    FUNC_COSD(          "cosd",         Pcode.FUNC_COSD,    1 ),
    FUNC_SIN(           "sin",          Pcode.FUNC_SIN,     1 ),
    FUNC_SIND(          "sind",         Pcode.FUNC_SIND,    1 ),
    FUNC_TAN(           "tan",          Pcode.FUNC_TAN,     1 ),
    FUNC_TAND(          "tand",         Pcode.FUNC_TAND,    1 ),
    FUNC_ACOS(          "acos",         Pcode.FUNC_ACOS,    1 ),
    FUNC_ACOSD(         "acosd",        Pcode.FUNC_ACOSD,   1 ),
    FUNC_ASIN(          "asin",         Pcode.FUNC_ASIN,    1 ),
    FUNC_ASIND(         "asind",        Pcode.FUNC_ASIND,   1 ),
    FUNC_ATAN(          "atan",         Pcode.FUNC_ATAN,    1 ),
    FUNC_ATAND(         "atand",        Pcode.FUNC_ATAND,   1 ),
    FUNC_NUMBER_FORMAT( "numberformat", Pcode.FUNC_NUMBER_FORMAT, 3 ),
    FUNC_AVG(           "avg",          Pcode.FUNC_AVG, 2 ),
    FUNC_NONE(          "####",         Pcode.NONE,     0 );

    String name;
    int pcode;
    int argcount;

    InternalFunc( String name, int pcode, int argcount ) {
        this.name = name;
        this.pcode = pcode;
        this.argcount = argcount;
    }

    @Override
    public String toString() {
        return ( name + "()" );
    }
}

@BA.Hide
/**----------------------------------------------------------------------- Codegen()
* Codegen()
*/
public class Codegen {

    private static Codeblock codeBlock;
    private static List<Integer> byteCode;
    private static List<Double> constData;
    private static List<Boolean> isPcode;    // needed for peephole optimization
    private static int codeIndex = 0;        // index in byteCode where next instruction will be stored

    // Parameter and eval expressions
    private static String exprParam;
    private static String exprEval;

    // Putback
    private static int putbackCount;
    private static int putbackIndex;

    // Jump table
    private static MteJump jumpTable[] = new MteJump[20];
    private static int jumpCount = 0;

    // Labels
    private static int labelTargets[] = new int[20];
    private static int labelIndex = 0;

    // Parameter names
    private static String parameters[] = new String[20];
    private static int parameterCount = 0;

    // Parens
    private static int parenCount = 0;

    // Token list and navigation
    private static List<String> tokenList;
    private static MteToken token = new MteToken();
    private static int tokenIndex = 0;
    private static int tokenEndIndex = 0;

    // Token types
    private static final int TOKEN_TYPE_NONE = 0;
    private static final int TOKEN_TYPE_DELIMITER = 1;
    private static final int TOKEN_TYPE_IDENTIFIER = 2;
    private static final int TOKEN_TYPE_NUMBER = 3;
    private static final int TOKEN_TYPE_KEYWORD = 4;
    private static final int TOKEN_TYPE_TEMP = 5;
    private static final int TOKEN_TYPE_STRING = 6;
    private static final int TOKEN_TYPE_BLOCK = 7;
    private static final int TOKEN_TYPE_UNKNOWN = 8;
    private static final int TOKEN_TYPE_FINISHED = 9;
    private static final int TOKEN_TYPE_HEX_NUMBER = 10;
    private static final int NULL_TOKEN = '\0';

    // Expression parsing
    private static final String CODEBLOCK_MATCH = "(\\{)?(\\|)?([^|\\}]*)(\\|)?([^}]*)(\\})?";
    private static final String TOKENIZER_MATCH = "\\(|\\)|>=|<=|<>|\\|\\||&&|!=|==|<<|>>|0x[.\\da-z]+|[&\\^|~]|[+><=*/\\-!%,]|[.\\d]+|\\b\\w+\\b";

    // Expression groups
    private static final int GROUP_OPEN_BRACKET = 1;
    private static final int GROUP_OPEN_PIPE = 2;
    private static final int GROUP_PARAM_EXPR = 3;
    private static final int GROUP_CLOSE_PIPE = 4;
    private static final int GROUP_EVAL_EXPR = 5;
    private static final int GROUP_CLOSE_BRACKET = 6;
    private static final int GROUP_EXPECTED_COUNT = 6;

    // Abort used to unwind parser when error found
    private static boolean ABORT = false;
    private static boolean SUCCESS = true;

    // Internal func table
    private static Map<String, InternalFunc> funcTableMap;
    private static boolean isFuncTableLoaded = false;

    /**------------------------------------------------------------ loadFuncTable()
     */
    private static void loadFuncTable() {

        // Create map and load it up
        funcTableMap = new HashMap<>();
        for ( InternalFunc func : InternalFunc.values() ) {
            funcTableMap.put( func.name, func  );
        }

        // mark table loaded
        isFuncTableLoaded = true;
    }

    /**--------------------------------------------------------- findInternalFunc()
     */
    private static InternalFunc findInternalFunc( String name ) {
        InternalFunc funcInfo;

        // If table not loaded
        if ( !isFuncTableLoaded )
            loadFuncTable();

        // Search map for func
        funcInfo = funcTableMap.get( name );

        // If not found set funcinfo to none
        if ( funcInfo == null )  funcInfo = InternalFunc.FUNC_NONE;

        return ( funcInfo );
    }

    /**---------------------------------------------------------------- resetCode()
     */
    private static void resetCode() {

        // ToDo - Does this include all to reset?

        // Init code index
        codeIndex = 0;  // First item in bytecode is the codeblock parameter count
                        // Pcodes start at byteCode[ 1 ]

        // Reset counters and indexes
        jumpCount = 0;
        labelIndex = 0;
        parameterCount = 0;
        parenCount = 0;
        putbackCount = 0;
        putbackIndex = 0;

        // reset expressions
        exprParam = "";
        exprEval = "";
    }

    /**--------------------------------------------------------- compileCodeBlock()
     */
    public static Error compileCodeBlock( Codeblock cb ) {
        Error err;

        // Store local reference to codeblock and bytecode
        codeBlock = cb;

        // On first pass, code and constants stored in list
        byteCode = new ArrayList<Integer>();
        constData = new ArrayList<Double>();

        // Create list to track location of pcode vs. inline values
        isPcode = new ArrayList<Boolean>();

        // Reset code index and tables
        resetCode();

        // Parse expression into components
        err = extractExpressions();

        // If no error, continue
        if ( err == Error.NONE ) {

            // Process codeblock parameters
            err = compileParameters();

            // If no error, continue
            if ( err == Error.NONE ) {

                // Store parameter count in the code
                emitCodeHeader( parameterCount );

                // Compile expression
                err = compileExpression();
            }
        }

        // If error, delete the code
        if ( err != Error.NONE ) {
            byteCode.clear();
            return ( err );
        }

        //-------------------------------------------------------------
        // Convert code and constant storage from list to fixed arrays.

        // convert constant data to array
        int size = constData.size();
        codeBlock.code.constData = new double[size];
        for ( int i = 0; i < size; i++ ) {
            codeBlock.code.constData[i] = constData.get(i);
        }

        // convert bytecode to array
        size = byteCode.size();
        codeBlock.code.byteCode = new int[ size ];
        for ( int i = 0; i < size; i++ ) {
            codeBlock.code.byteCode[i] = byteCode.get(i);
        }
        return ( err );
    }

    /**------------------------------------------------------- extractExpressions()
    */
    private static Error extractExpressions() {
        Error err = Error.NONE;

        // Trim and format
        String exprTrimmed = codeBlock.codeblockText.trim().toLowerCase();

        // Parse expression into component parts
        Pattern p = Pattern.compile(CODEBLOCK_MATCH);
        Matcher matchParts = p.matcher(exprTrimmed);
        matchParts.find();

        // get match count
        int groupcount = matchParts.groupCount();

        // No matches return here
        if (groupcount == 0) {
            return (setError(Error.SYNTAX, ""));
        }

        // Mtelog.console("Groupcount=" + Integer.toString(groupcount));

        // Prepare for worst
        StringBuilder errDetail = new StringBuilder("");

        // Inspect groups
        for (int i = 1; i <= groupcount; i++) {

            // Mtelog.console("Group (" + Integer.toString(i) + ")=" + matchParts.group(i));

            // Is group value missing?
            if (matchParts.group(i) == null)
            {
                // Which one?
                switch (i) {
                    case GROUP_OPEN_BRACKET:
                        err = Error.MISSING_BRACKET;
                        break;
                    case GROUP_OPEN_PIPE:
                        err = Error.MISSING_PIPE;
                        break;
                    case GROUP_PARAM_EXPR:
                        err = Error.NONE;    // ToDo. If main expression references arg this is an error
                        break;
                    case GROUP_CLOSE_PIPE:
                        err = Error.MISSING_PIPE;
                        break;
                    case GROUP_EVAL_EXPR:
                        err = Error.MISSING_EXPR;
                        break;
                    case GROUP_CLOSE_BRACKET:
                        err = Error.MISSING_BRACKET;
                        break;
                }
            }
            else {
                errDetail.append(matchParts.group(i));
            }

            // If error, complete detail and return here
            if (err != Error.NONE) {

                // Add error code
                errDetail.append("<e")
                         .append(Integer.toString(err.errCode))
                         .append(">");

                // Set and return error code
                return (setError(err, errDetail.toString()));
            }

        }

        // Regex should create six groups
        if ( groupcount == GROUP_EXPECTED_COUNT ) {

            // Store parameter expression
            exprParam = matchParts.group(GROUP_PARAM_EXPR) == null ? "" : matchParts.group(GROUP_PARAM_EXPR);

            // Store main expression
            exprEval = matchParts.group( GROUP_EVAL_EXPR );   // 1 * a + c * 5

            // And not zero length
            if( exprEval.length() != 0 ) {
                return ( Error.NONE );
            }
        }

        // Set syntax error
        err = Error.SYNTAX;
        errDetail.append("<e")
                .append(Integer.toString(err.errCode))
                .append(">");

        return ( setError( err, errDetail.toString() ) );

    }

    /**-------------------------------------------------------- compileParameters()
     */
    private static Error compileParameters() {
        Error err = Error.NONE;
        boolean finished = false;
        int commacount = 0;

        // Reset parameter count
        parameterCount = 0;

        // Tokenenize parameter expression
        tokenList = tokenizeExpr( exprParam );

        // Build table of parameter names
        do {

           // Get parameter
           getToken();

           switch ( token.type ) {
               case TOKEN_TYPE_IDENTIFIER:

                   // Reserved word?
                   if ( token.text.equals("ce") || token.text.equals("cpi") ) {
                        return ( setError( Error.RESERVED_WORD, token.text ));
                   }

                   // Store variable name
                   parameters[ parameterCount ] = token.text;

                   // Increment parameter count
                   parameterCount++;

                   // ToDo - Generate error if more parameters than memory

                   // Reset comma count
                   commacount = 0;

                   break;
               case TOKEN_TYPE_DELIMITER:

                   // Not a comma?
                   if ( !token.text.equals(",") ) {
                       return setError2(Error.MISSING_COMMA);
                   }

                   // Missed argument?
                   if ( commacount > 0 ) {
                       return setError2(Error.MISSING_PARAM);
                   }

                   // Bump comma count
                   commacount++;

                   break;
               case TOKEN_TYPE_FINISHED:

                   if ( commacount > 0 ) {
                       return setError2( Error.MISSING_PARAM );
                   }

                   finished=true;
                   break;

               default:
                   return setError2( Error.MISSING_PARAM );
           }

        } while (!finished);

        return ( err );
    }

    /**-------------------------------------------------------- compileExpression()
     */
    private static Error compileExpression() {
        boolean finished = false;
        boolean success = true;

        // Tokenenize main expression
        tokenList = tokenizeExpr( exprEval );

         while ( !finished ) {

             // Run parser and generate code
             success = evalExpression();
             if ( success == ABORT )
                 break;

            // Check for completeion or unexpected error
            switch (token.type) {
                case TOKEN_TYPE_FINISHED:
                    doEndCode();
                    fixupJumps();
                    finished = true;
                    break;
                case TOKEN_TYPE_NONE:
                    setError( Error.OTHER, "Token type none.");
                    finished = true;
                    break;
                case TOKEN_TYPE_UNKNOWN:
                    setError( Error.OTHER, "Unknown token.");
                    finished = true;
                    break;
            }
         }

        return ( codeBlock.lastError );
    }

    /**----------------------------------------------------------- EvalExpression()
     */
    private static boolean evalExpression() {
        boolean success = false;

        // Get this party started!
        getToken();

        // Evaluate assignment
        success = evalAssignment();
        if ( success == ABORT ) return ( ABORT );

        // Return token to the input stream.  This is needed due to the "look ahead"
        // nature of the parser
        success = putBack();
        if ( success == ABORT ) return ( ABORT );

        return ( SUCCESS );
    }

    /**----------------------------------------------------------- EvalAssignment()
     */
    private static boolean evalAssignment() {
        boolean success = false;
        int varindex;

        // Possible variable?
        if ( token.type == TOKEN_TYPE_IDENTIFIER ) {

            // Look for it
            varindex = findParameter( token.text );
            if ( varindex >= 0 ) {

                // Save token
                MteToken saveToken = new MteToken();
                saveToken.text = token.text;
                saveToken.type = token.type;

                // Assignment operator?
                getToken();
                if ( token.text.equals("=") ) {

                    // Could be a series of assignments
                    getToken();
                    success = evalAssignment();
                    if ( success == ABORT ) return ( ABORT );

                    // Store in memory
                    doStoreVariable( varindex );

                    // Done
                    return ( SUCCESS );

                }

                // Not an assignment?
                else {

                    // Put back in stream
                    putBack();

                    // Restore token
                    token.text = saveToken.text;
                    token.type = saveToken.type;

                }
            }
        }

        // Next precedence
        success = evalLogicalOr();
        if ( success == ABORT ) return ( ABORT );

        return ( SUCCESS );
    }

    /**------------------------------------------------------------ EvalLogicalOr()
     */
    private static boolean evalLogicalOr() {
        String operator;
        int dropout;
        boolean success = false;

        // Next precedence
        success = evalLogicalAnd();
        if ( success == ABORT ) return ( ABORT );

        // Save operator on local stack
        operator = token.text;

        // Process Or
        while ( operator.equals("||") ) {

            // Gen label for dropout
            dropout = newLabel();

            // If true skip right operand
            branchTrue(dropout);

            // Push, get, and do next level
            push();
            getToken();

            success = evalLogicalAnd();
            if ( success == ABORT ) return ( ABORT );

            // Gen code
            doLogicalOr();

            // Post dropout label
            postLabel( dropout );

            // Update operator
            operator = token.text;

        }

        return ( SUCCESS );
    }

    /**----------------------------------------------------------- EvalLogicalAnd()
     */
    private static boolean evalLogicalAnd() {
        String operator;
        int dropout;
        boolean success = false;

        // Next higher precedence
        success = evalBitwiseAndOrXor();
        if ( success == ABORT ) return ( ABORT );

        // Save operator on local stack
        operator = token.text;

        // Process And
        while ( operator.equals("&&") ) {

            // Gen label for dropout
            dropout = newLabel();

            // If false skip right operand
            branchFalse(dropout);

            // Push, get, and do next level
            push();
            getToken();

            success = evalBitwiseAndOrXor();
            if ( success == ABORT ) return ( ABORT );

            // Gen code
            doLogicalAnd();

            // Post dropout label
            postLabel(dropout);

            // Update operator
            operator = token.text;

        }

        return ( SUCCESS );
    }

    /**------------------------------------------------------ evalBitwiseAndOrXor()
     */
    private static boolean evalBitwiseAndOrXor() {
        String operator;
        boolean success = true;
        Matcher m;

        success = evalRelational();
        if ( success == ABORT ) return ( ABORT );

        // Store operator on local stack
        operator = token.text;

        m = TokenPattern.bitOper2.matcher( operator );
        while (  m.matches() ) {

            // Push on stack and continue
            push();
            getToken();

            success = evalRelational();
            if ( success == ABORT ) return ( ABORT );

            // Generate code
            switch ( operator ) {
                case "&":
                    doBitwiseAnd();
                    break;
                case "|":
                    doBitwiseOr();
                    break;
                case "^":
                    doBitwiseXor();
                    break;
            }

            // Update operator as token may have changed
            operator = token.text;

            // Refresh
            m = TokenPattern.bitOper2.matcher( operator );
        }

        return ( SUCCESS );
    }

    /**----------------------------------------------------------- EvalRelational()
     */
    private static boolean evalRelational() {
        String operator;
        boolean success = true;
        Matcher m;

        success = evalBitShift();
        if ( success == ABORT ) return ( ABORT );

        // Store operator on local stack
        operator = token.text;

        m = TokenPattern.relOper2.matcher( operator );
        if  (  m.matches() ) {

            // Push on stack and continue
            push();
            getToken();

            success = evalBitShift();
            if ( success == ABORT ) return ( ABORT );

            // Generate code
            switch ( operator ) {
                case "<":
                    doLess();
                    break;
                case "<=":
                    doLessEqual();
                    break;
                case ">":
                    doGreater();
                    break;
                case ">=":
                    doGreaterEqual();
                    break;
                case "==":
                    doEqual();
                    break;
                case "!=":
                    doNotEqual();
                    break;
            }
        }
        return ( SUCCESS );
    }

    /**------------------------------------------------------------- evalBitShift()
     */
    private static boolean evalBitShift() {
        String operator;
        boolean success = true;
        Matcher m;

        success = evalAddSub();
        if ( success == ABORT ) return ( ABORT );

        // Store operator on local stack
        operator = token.text;

        m = TokenPattern.bitOper.matcher( operator );
        if  (  m.matches() ) {

            // Push on stack and continue
            push();
            getToken();

            success = evalAddSub();
            if ( success == ABORT ) return ( ABORT );

            // Generate code
            switch ( operator ) {
                case "<<":
                    doBitShiftLeft();
                    break;
                case ">>":
                    doBitShiftRight();
                    break;
            }
        }

        return ( SUCCESS );
    }

    /**--------------------------------------------------------------- evalAddSub()
     */
    private static boolean evalAddSub() {
        String operator;
        boolean success = true;
        Matcher m;

        success = evalFactor();
        if ( success == ABORT ) return ( ABORT );

        // Store operator on local stack
        operator = token.text;

        m = TokenPattern.isAddSub.matcher( operator );
        while (  m.matches() ) {

            // Push on stack and continue
            push();
            getToken();

            success = evalFactor();
            if ( success == ABORT ) return ( ABORT );

            // Generate code
            switch ( operator ) {
                case "-":
                    doSubtract();
                    break;
                case "+":
                    doAdd();
                    break;
            }

            // Update operator as token may have changed
            operator = token.text;

            // Refresh matcher
            m = TokenPattern.isAddSub.matcher( operator );
        }

        return ( SUCCESS );
    }

    /**--------------------------------------------------------------- evalFactor()
     */
    private static boolean evalFactor() {
        String operator;
        boolean success = true;
        Matcher m;

        success = evalUnary();
        if ( success == ABORT ) return ( ABORT );

        // Store operator on local stack
        operator = token.text;

        // While multiply, divide, or modulo
        m = TokenPattern.isFactor.matcher( operator );
        while (  m.matches() ) {

            // Push on stack and continue
            push();
            getToken();

            success = evalUnary();
            if ( success == ABORT ) return ( ABORT );

            // Generate code
            switch ( operator ) {
                case "*":
                    doMultiply();
                    break;
                case "/":
                    doDivide();
                    break;
                case "%":
                    doModulo();
                    break;
            }

            // Update operator as token may have changed
            operator = token.text;

            // Refresh matcher
            m = TokenPattern.isFactor.matcher( operator );
        }

        return ( SUCCESS );
    }

    /**---------------------------------------------------------------- EvalUnary()
     */
    private static boolean evalUnary() {
        String operator;
        boolean success = true;
        Matcher m;

        operator = "";

        // Is this a unary operator?
        m = TokenPattern.isUnary.matcher( token.text );
        if  (  m.matches() ) {

            // Save operator on stack and continue
            operator = token.text;
            getToken();
            success = evalUnary();
            if (success == ABORT) return (ABORT);

        }
        else {

            // Next higher precedence
            success = evalParen();
            if (success == ABORT) return (ABORT);
        }

        // Which one?
        switch ( operator ) {
            case "-":
                doNegate();
                break;
            case "!":
                doLogicalNot();
                break;
            case "~":
                doBitNot();
                break;
        }

        return (SUCCESS);
    }

    /**---------------------------------------------------------------- evalParen()
     */
    private static boolean evalParen() {
        boolean success = false;
        boolean finished = false;

        // Is this an open parenthesis?
        if ( token.text.equals("(") ) {

            // Count open parenthesis
            parenCount++;

            // get token
            getToken();

            // Eval sub expression
            while ( !finished ) {

                success = evalAssignment();
                if (success == ABORT) return (ABORT);

                // If comma, then continue
                if ( token.text.equals(",") ) {
                    getToken();
                }
                else {
                    finished = true;
                }
            }

            // Expecting a closed parenthesis here
            if ( !token.text.equals(")")) {
                syntaxError( Error.MISSING_PAREN );
                return ( ABORT );
            }

            // Reduce count
            parenCount--;

            // Get next token
            getToken();
        }
        else {

            success = evalAtom();
            if (success == ABORT) return (ABORT);
        }
        return ( SUCCESS );
    }

    /**----------------------------------------------------------------- evalAtom()
     */
    private static boolean evalAtom() {
        int parameterindex = 0;
        boolean success;
        double value;
        final int HEX2DECIMAL=16;
        InternalFunc funcInfo;

        switch ( token.type ) {

            case TOKEN_TYPE_IDENTIFIER:

                // Find internal function
                funcInfo = findInternalFunc( token.text );

                // If function found
                if ( funcInfo.pcode > 0 ) {

                    // IIF is special
                    if ( funcInfo.pcode == Pcode.FUNC_IIF ) {

                        success = doIIF();
                        if ( success == ABORT ) return ( ABORT );

                    }
                    // Call internal function
                    else {
                        // Output instruction to call internal func
                        success = doCallInternalFunc( funcInfo );
                        if ( success == ABORT ) return ( ABORT );
                    }
                }

                // Either built-in constant or parameter
                else {

                    switch (token.text) {
                        case "ce":
                            doLoadNumber(Math.E);
                            break;
                        case "cpi":
                            doLoadNumber(Math.PI);
                            break;
                        default:
                            parameterindex = findParameter(token.text);
                            if (parameterindex >= 0) {
                                doLoadVariable(parameterindex);
                            } else {
                                syntaxError(Error.NOT_A_VAR);
                                return (ABORT);
                            }
                    }
                }

                // Get next token
                getToken();
                break;

            case TOKEN_TYPE_NUMBER:

                // Convert string to double
                value = Double.parseDouble( token.text );

                // Output instruction to load number
                doLoadNumber( value );

                // Get next token
                getToken();
                break;

            case TOKEN_TYPE_DELIMITER:

                if ( token.text.equals(")") && parenCount == 0 ) {
                    syntaxError( Error.UNBALANCED_PARENS );
                    return ( ABORT );
                }

                return ( SUCCESS );

            case TOKEN_TYPE_FINISHED:

                return ( SUCCESS );

            case TOKEN_TYPE_HEX_NUMBER:

                // Convert hex to decimal
                value = Integer.parseInt( token.text.substring(2), HEX2DECIMAL );

                // Ouput instruction to load number
                doLoadNumber( value );

                // Get next token
                getToken();

                break;
            default:
                syntaxError( Error.OTHER );
                return ( ABORT );
        }

        return ( SUCCESS );
    }

    /**------------------------------------------------------------------ getArgs()
     */
    private static boolean getArgs( int expectedArgCount ) {
        boolean success, finished;
        int argcount=0;

        // Get next token
        getToken();

        // If not opening paren
        if ( !token.text.equals("(") ) {
            syntaxError( Error.MISSING_PAREN );
            return ( ABORT );
        }

        // Get next token
        getToken();

        // If closing paren, no args. This is ok.
        if ( token.text.equals(")") ) {
            return ( SUCCESS );
        }

        // Return token to stream
        putBack();

        finished = false;
        while ( !finished ) {

            // Parse arguments
            success = evalExpression();
            if ( success == ABORT ) return ( ABORT );

            // Count args. Too many?
            argcount++;
            if ( argcount > expectedArgCount ) {
                syntaxError( Error.TOO_MANY_ARGS );
                return ( ABORT );
            }

            // Push value on stack and get next token
            push();
            getToken();

            // If no comma, we've consumed all the arguments
            if ( !token.text.equals(",") ) {
                finished = true;
            }

        }

        // Short arguments?
        if ( argcount > expectedArgCount ) {
            syntaxError( Error.INSUFFICIENT_ARGS );
            return ( ABORT );
        }

        // Should be closing paren here
        if ( !token.text.equals(")") ) {
            syntaxError( Error.MISSING_PAREN );
            return ( ABORT );
        }

        return ( SUCCESS );
    }


    /**------------------------------------------------------------------ putBack()
     */
    private static boolean putBack() {

        // Safety check to prevent parser from hanging on bug
        if ( putbackIndex == tokenIndex ) {
            putbackCount++;
            if (putbackCount > 5) {
                syntaxError(Error.PUTBACK);
                return (ABORT);
            }
        }
        else {
            putbackIndex = tokenIndex;
            putbackCount = 0;
        }

        // Decrement token index
        tokenIndex--;

        return ( SUCCESS );
    }


    /**------------------------------------------------------------- tokenizeExpr()
     */
    private static List<String> tokenizeExpr( String exprTarget ) {

        List<String> exprTokens = new ArrayList<>();

        Pattern p = Pattern.compile( TOKENIZER_MATCH );
        Matcher matchExpr = p.matcher( exprTarget );

        // Load list with tokens
        while ( matchExpr.find() ) {
            exprTokens.add(matchExpr.group());
        }

        // Init list navigation
        tokenIndex = -1;
        tokenEndIndex = exprTokens.size() - 1;

        return ( exprTokens );
    }

    /**----------------------------------------------------------------- getToken()
     */
    private static int getToken() {
        String tokenText;
        Matcher matchToken;

        token.type = TOKEN_TYPE_NONE;
        token.text = "";  // NULL_TOKEN;

        // Advance index
        tokenIndex = tokenIndex + 1;

        // If index is past the end, no more tokens
        if ( tokenIndex > tokenEndIndex ) {
            token.type = TOKEN_TYPE_FINISHED;
            return ( token.type );
        }

        // Get token
        tokenText = tokenList.get( tokenIndex );

        // Relational operator?
        matchToken = TokenPattern.relOper.matcher( tokenText );
        if (  matchToken.matches() ) {

            token.text = tokenText;
            token.type = TOKEN_TYPE_DELIMITER;
            return ( token.type );
        }

        // Bit shift?
        matchToken = TokenPattern.bitOper.matcher( tokenText );
        if (  matchToken.matches() ) {

            token.text = tokenText;
            token.type = TOKEN_TYPE_DELIMITER;
            return ( token.type );
        }

        // General delimiter?
        matchToken = TokenPattern.genOper.matcher( tokenText );
        if (  matchToken.matches() ) {

            token.text = tokenText;
            token.type = TOKEN_TYPE_DELIMITER;
            return ( token.type );
        }

        // Is hex number?
        matchToken = TokenPattern.hexNumber.matcher( tokenText );
        if (  matchToken.matches() ) {

            token.text = tokenText;
            token.type = TOKEN_TYPE_HEX_NUMBER;
            return ( token.type );
        }

        // Is number?
        matchToken = TokenPattern.floatNumber.matcher( tokenText );
        if (  matchToken.matches() ) {

            token.text = tokenText;
            token.type = TOKEN_TYPE_NUMBER;
            return ( token.type );
        }

        // Is text?
        matchToken = TokenPattern.isText.matcher( tokenText );
        if (  matchToken.matches() ) {

            token.text = tokenText;
            token.type = TOKEN_TYPE_IDENTIFIER;
            return ( token.type );

        }
        else {
            syntaxError( Error.OTHER );
            token.text = tokenText;
            token.type = TOKEN_TYPE_UNKNOWN;
        }

        return ( token.type );
    }


//    '***************************************************************************
//    '*
//    '* Code Generator
//    '*
//    '***************************************************************************

    /**--------------------------------------------------------------------- push()
     */
    private static void push() {
        // Mtelog.debug( "push");
        doPush();
    }

    /**------------------------------------------------------------------- doPush()
     */
    private static void doPush() {

        // Mtelog.debug( "doPush");

        // If optimizer enabled, attempt "peephole" optimization of push
        if ( codeBlock.optimizerEnabled ) {

            // "Peep" at previous instruction
            int peepindex = codeIndex - 2;
            int peep = (peepindex > 0 && isPcode.get(peepindex)) ? getShortCode(peepindex) : Pcode.NONE;

            // Optimize loadvar and loadconst
            switch (peep) {
                case Pcode.LOADVAR:
                    emitShortCode( peepindex, Pcode.PUSHVAR );   // Push var directly on stack
                    break;
                case Pcode.LOADCONST:
                    emitShortCode( peepindex, Pcode.PUSHCONST ); // Push const directly on stack
                    break;
                default:
                    emitShortCode( Pcode.PUSH );
            }
        }
        else {
           emitShortCode( Pcode.PUSH );
        }
    }


    /**------------------------------------------------------------ getShortCode()
     */
    private static int getShortCode( int index ) {
        return( byteCode.get(index));
    }


    /**----------------------------------------------------------- emitCodeHeader()
     */
    private static void emitCodeHeader( int paramcount ) {

        byteCode.add( paramcount );
        isPcode.add( false );
        codeIndex++;
    }

    /**------------------------------------------------------------ emitShortCode()
     */
    private static void emitShortCode( int pcode ) {

        // Add instruction
        byteCode.add( pcode );
        isPcode.add( true );
        codeIndex++;

    }
    /**------------------------------------------------------------ emitShortCode()
     */
    private static void emitShortCode( int index, int pcode  ) {

        // Change instruction
        byteCode.set(index, pcode);

    }

    /**------------------------------------------------------------- emitLongCode()
     */
    private static void emitLongCode( int pcode, int value ) {

        // Add pcode
        byteCode.add( pcode );
        isPcode.add( true );
        codeIndex++;

        // Add  value inline
        byteCode.add( value );
        isPcode.add( false );
        codeIndex++;
    }


    /**-------------------------------------------------------------- addConstant()
     */
    private static int addConstant( double value ) {

        // Add value to constants list
        constData.add( value );

        return ( constData.size() - 1 );
    }

    /**------------------------------------------------------- doCallInternalFunc()
     */
    private static boolean doCallInternalFunc( InternalFunc funcInfo ) {
        boolean success = false;

        // Mtelog.debug("doInternalFunc");

        // Get arguments and push on stack
        success = getArgs( funcInfo.argcount );
        if ( success == ABORT ) return ( ABORT );

        // call func
        emitShortCode( funcInfo.pcode);

        return ( SUCCESS );
    }

    /**-------------------------------------------------------------------- doIIF()
     *
     * After getToken returns the TokenIndex is here
     * ----------------------------------------------
     *  1. IIF( ..., ..., ...)
     *        ^
     *  2. IIF( ..., ..., ...)
     *             ^
     *  3. IIF( ..., ..., ...)
     *                  ^
     *  4. IIF( ..., ..., ...)
     *                       ^
     */
    private static boolean doIIF() {
        boolean success = false;
        int iffalse, endofif;

        // Mtelog.debug( "DoIIF");

        // 1. Get next token
        getToken();

        // If not parethesis
        if ( !token.text.equals("(") ) {
            syntaxError( Error.MISSING_PAREN );
            return ( ABORT );
        }

        // Eval conditional expression
        success = evalExpression();
        if ( success == ABORT ) return ( ABORT );

        // Get label
        iffalse = newLabel();

        // 2. Get next token
        getToken();

        // Expect comma here
        if ( !token.text.equals(",") ) {
            syntaxError( Error.MISSING_COMMA );
            return ( ABORT );
        }

        // Post false branch
        branchFalse( iffalse );

        // Get 'then' condition
        success = evalExpression();
        if ( success == ABORT ) return ( ABORT );

        // 3. Get next token
        getToken();

        // Expect comma here
        if ( !token.text.equals(",") ) {
            syntaxError( Error.MISSING_COMMA );
            return ( ABORT );
        }

        // Post label for "else"
        endofif = newLabel();
        branch( endofif );
        postLabel( iffalse );

        // Compile "else" condition
        success = evalExpression();
        if ( success == ABORT ) return ( ABORT );

        // 4. Get next token
        getToken();

        // If not closing parethesis
        if ( !token.text.equals(")") ) {
            syntaxError( Error.MISSING_PAREN );
            return ( ABORT );
        }

        // End of IIF
        postLabel( endofif );

        return ( SUCCESS );
    }

    /**------------------------------------------------------------- doBitwiseAnd()
     */
    private static void doBitwiseAnd() {
        // Mtelog.debug("doBitwiseAnd()");
        emitShortCode(Pcode.BIT_AND);
    }

    /**-------------------------------------------------------------- doBitwiseOr()
     */
    private static void doBitwiseOr() {
        // Mtelog.debug("doBitwiseOr()");
        emitShortCode(Pcode.BIT_OR);
    }

    /**----------------------------------------------------------- doBitwiseXor()
     */
    private static void doBitwiseXor() {
        // Mtelog.debug("doBitwiseXor()");
        emitShortCode(Pcode.BIT_XOR);
    }

    /**--------------------------------------------------------- doBitShiftLeft()
     */
    private static void doBitShiftLeft() {
        // Mtelog.debug("doBitShiftLeft()");
        emitShortCode(Pcode.BIT_SHIFT_LEFT);
    }

    /**--------------------------------------------------------- doBitShiftRight()
     */
    private static void doBitShiftRight() {
        // Mtelog.debug("doBitShiftRight()");
        emitShortCode(Pcode.BIT_SHIFT_RIGHT);
    }

    /**----------------------------------------------------------------- doBitNot()
     */
    private static void doBitNot() {
        // Mtelog.debug("doBitNot()");
        emitShortCode(Pcode.BIT_NOT);
    }

    /**------------------------------------------------------------- doLoadNumber()
     */
    private static void doLoadNumber( double value ) {

        // Mtelog.debug("doLoadNumber()");

        // Add constant to table
        int constindex = addConstant( value );

        emitLongCode(Pcode.LOADCONST, constindex );
    }

    /**----------------------------------------------------------- doLoadVariable()
     */
    private static void doLoadVariable( int index ) {
        // Mtelog.debug("doLoadVariable()");
        emitLongCode(Pcode.LOADVAR, index );
    }

    /**---------------------------------------------------------- doStoreVariable()
     */
    private static void doStoreVariable( int index ) {

        // Mtelog.debug("doStoreVariable()");
        emitLongCode(Pcode.STOREVAR, index );
    }

    /**---------------------------------------------------------------- doMultiply()
     */
    private static void doMultiply() {

        // Mtelog.debug("doMultiply()");
        emitShortCode(Pcode.MULTIPLY );
    }

    /**----------------------------------------------------------------- doDivide()
     */
    private static void doDivide() {

        // Mtelog.debug("xdoBitNot()");
        emitShortCode(Pcode.DIVIDE);
    }

    /**----------------------------------------------------------------- doModulo()
     */
    private static void doModulo() {
        // Mtelog.debug("dxoBitNot()");
        emitShortCode(Pcode.MODULO);
    }
    /**----------------------------------------------------------------- doNegate()
     */
    private static void doNegate() {
        // Mtelog.debug("xdoBitNot()");
        emitShortCode(Pcode.NEG);
    }

    /**-------------------------------------------------------------- doLogicalNot()
     */
    private static void doLogicalNot() {
        // Mtelog.debug("xdoBitNot()");
        emitShortCode(Pcode.LOGICAL_NOT);
    }

    /**----------------------------------------------------------------- doSubtract()
     */
    private static void doSubtract() {
        // Mtelog.debug("xdoBitNot()");
        emitShortCode(Pcode.SUBTRACT);
    }

    /**--------------------------------------------------------------------- doAdd()
     */
    private static void doAdd() {
        // Mtelog.debug("xdoBitNot()");
        emitShortCode(Pcode.ADD );
    }

    /**-------------------------------------------------------------------- doLess()
     */
    private static void doLess() {
        // Mtelog.debug("xdoBitNot()");
        emitShortCode(Pcode.LESS_THAN);
    }

    /**--------------------------------------------------------------- doLessEqual()
     */
    private static void doLessEqual() {
        // Mtelog.debug("xdoBitNot()");
        emitShortCode(Pcode.LESS_EQUAL);
    }

    /**----------------------------------------------------------------- doBxitNot()
     */
    private static void doGreater() {
        // Mtelog.debug("xdoBitNot()");
        emitShortCode(Pcode.GREATER_THAN);
    }

    /**----------------------------------------------------------------- doBxitNot()
     */
    private static void doGreaterEqual() {
        // Mtelog.debug("xdoBitNot()");
        emitShortCode(Pcode.GREATER_EQUAL);
    }

    /**----------------------------------------------------------------- doBxitNot()
     */
    private static void doEqual() {
        // Mtelog.debug("xdoBitNot()");
        emitShortCode(Pcode.EQUAL);
    }

    /**----------------------------------------------------------------- doBxitNot()
     */
    private static void doNotEqual() {
        // Mtelog.debug("doNotEqual()");
        emitShortCode(Pcode.NOT_EQUAL);
    }

    /**----------------------------------------------------------------- doEndCode()
     */
    private static void doEndCode() {
        // Mtelog.debug("doEndCode()");
        emitShortCode(Pcode.ENDCODE);
    }

    /**----------------------------------------------------------------- newLabel()
     */
    private static int newLabel() {
        int nextLabel = labelIndex;
        labelIndex++;
        return ( nextLabel );
    }

    /**------------------------------------------------------------------ addJump()
     */
    private static void addJump( int jumptarget ) {

        // Create new jump
        MteJump jump = new MteJump();
        jump.codeindex  = codeIndex;
        jump.labelindex = jumptarget;

        // Save the location of the jump instruction in the code
        jumpTable[ jumpCount ] = jump;

        // Bump count
        jumpCount++;
    }

    /**--------------------------------------------------------------- fixupJumps()
     */
    private static void fixupJumps() {
        int codeindex, jumpindex, jumpoffset;

        // Any jumps to fixup?
        if ( jumpCount > 0 ) {

            // Fix jumps
            for ( int i = 0; i < jumpCount; i++ ) {

                // This is the location of the jump pcode
                codeindex = jumpTable[ i ].codeindex;

                // This is the index where we want to jump to
                jumpindex = labelTargets[ jumpTable[i].labelindex ];

                // Calculate offset
                jumpoffset = (jumpindex - codeindex) - 1;

                // Replace inline value with corrected offset
                // emitShortCode( codeindex + 1, jumpoffset );
                byteCode.set( codeindex + 1, jumpoffset );
            }
        }

        // Reset jumps and label counts
        jumpCount  = 0;
        labelIndex = 0;
    }

    /**---------------------------------------------------------------- postLabel()
     */
    private static void postLabel( int labelIndex ) {

        // This is the location (codeindex) where this label should jump to
        labelTargets[ labelIndex ] = codeIndex;

    }

    /**------------------------------------------------------------------- branch()
     */
    private static void branch( int labelIndex ) {

        // Mtelog.debug( "branch");

        addJump( labelIndex );
        emitLongCode( Pcode.JUMP_ALWAYS, 0 );
    }

    /**-------------------------------------------------------------- branchFalse()
     */
    private static void branchFalse( int labelIndex ) {

        // Mtelog.debug( "branchFalse");

        addJump( labelIndex );
        emitLongCode( Pcode.JUMP_FALSE, 0 );
    }


    /**--------------------------------------------------------------- branchTrue()
     */
    private static void branchTrue( int labelIndex ) {

        // Mtelog.debug( "branchTrue");

        addJump( labelIndex );
        emitLongCode( Pcode.JUMP_TRUE, 0 );
    }

    /**-------------------------------------------------------------- doLogicalOr()
     */
    private static void doLogicalOr() {
        // Mtelog.debug( "doLogicalOr()" );
        emitShortCode( Pcode.LOGICAL_OR );
    }

    /**------------------------------------------------------------- doLogicalAnd()
     */
    private static void doLogicalAnd() {
        // Mtelog.debug( "doLogicalAnd()" );
        emitShortCode( Pcode.LOGICAL_AND );
    }

    /**------------------------------------------------------------ findParameter()
     */
    private static int findParameter( String nameTarget ) {

        // Any parameters?
        if ( parameterCount == 0 ) return ( -1 );

        // Find parameter in list
        for ( int i=0; i < parameterCount; i++ ) {
            if ( parameters[i].equals(nameTarget) )
                return ( i );
        }

        return ( -1 );
    }


//    '***************************************************************************
//    '*
//    '* Error
//    '*
//    '***************************************************************************

    /**----------------------------------------------------------------- SetError()
     */
    private static Error setError( Error err, String errDetail ) {

        // Store last error and detail
        codeBlock.lastError = err;
        codeBlock.errDetail = errDetail;

        return ( err );
    }

    /**---------------------------------------------------------------- SetError2()
     */
    private static Error setError2( Error err ) {
        String errDetail = buildErrorDetail( err );
        return ( setError( err, errDetail) );
    }

    /**--------------------------------------------------------- BuildErrorDetail()
     */
    private static String buildErrorDetail( Error err ) {

        // No tokens?
        if ( tokenIndex < 0 || tokenList.size() == 0 ) return ( "" );

        // Build detail from tokens
        StringBuilder sb = new StringBuilder();
        int k = ( tokenIndex <= tokenEndIndex ) ? tokenIndex : tokenEndIndex;
        for ( int i = 0; i <= k; i++ ) {
            sb.append( tokenList.get( i ));
        }

        // Add error code
        sb.append( "<e").append( Integer.toString(err.errCode)).append(">");

        return ( sb.toString() );
    }

    /**--------------------------------------------------------------- syntaxError()
     */
    private static void syntaxError( Error err ) {

        // Set error in codeblock with detail
        setError2( err );
    }

}
/**---------------------------------------------------------------------- MteToken()
*/
class MteToken {
    int type;
    String text;
}

/**----------------------------------------------------------------------- MteJump()
 */
class MteJump {
    int codeindex;
    int labelindex;
}
/**------------------------------------------------------------------ TokenPattern()
 */
class TokenPattern {

    public static Pattern relOper       = Pattern.compile("<=|>=|==|<|>|!=|\\|\\||&&|&");
    public static Pattern bitOper       = Pattern.compile("<<|>>");
    public static Pattern genOper       = Pattern.compile("[+\\-*^/%(),!|~=]");
    public static Pattern hexNumber     = Pattern.compile("0x[\\.\\da-z]+");
    public static Pattern isText        = Pattern.compile("\\w+");
    public static Pattern floatNumber   = Pattern.compile("[-+]?\\b[0-9]*\\.?[0-9]+\\b");
    // -----
    public static Pattern bitOper2      = Pattern.compile("&|\\^|\\|");
    public static Pattern relOper2      = Pattern.compile("<=|>=|==|(?<!:)<(?!<)|(?<!>)>(?!>)|!="); // ToDo. should relOper be updated to relOper2?
    public static Pattern isAddSub      = Pattern.compile("[+\\-]");
    public static Pattern isFactor      = Pattern.compile("[\\*/%]");
    public static Pattern isUnary       = Pattern.compile("[+\\-!~]");
}