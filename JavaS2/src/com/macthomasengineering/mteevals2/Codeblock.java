/**********************************************************************************
'*
'* Codeblock.java - Compilable blocks of code
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
/**********************************************************************************
'* Revision History:
'*
'* No.        Who  Date        Description
'* =====      ===  ==========  ======================================================
'* 1.05.1     MTE  2016/12/31  - Ported library to native Java. Published as "S2" edition
'*                             - Added peephole optimization for PUSH, LOADVAR, and LOADCONST
'*                             - Fixed bug with bitwise ! instruction where value was popped
'*                               off stack in error
'*                             - Renumbered and realigned Pcodes for future support of inline
'*                               Java optimization of B4X coded version of the library.
'*                             - Ported library to native Java. Published as "S2" edition
'* 1.04.4     MTE  2016/10/17  - Fixed button naming in Android library build project
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
'
***************************************************************************************/
package com.macthomasengineering.mteevals2;

import anywheresoftware.b4a.*;
import java.util.ArrayList;
import java.util.List;

@BA.DesignerName("Build 20161231")
@BA.Version(1.05F)
@BA.Author("MacThomasEngineering")
@BA.ShortName("Codeblock")
/**--------------------------------------------------------------------- Codeblock{}
 * Codeblock()
 */
public class Codeblock {

    @BA.Hide
    protected Code code;
    @BA.Hide
    protected String codeblockText;
    @BA.Hide
    protected Error lastError;
    @BA.Hide
    protected String ErrorDesc = "";
    @BA.Hide
    protected String errDetail;
    @BA.Hide
    protected boolean optimizerEnabled;
    @BA.Hide
    static String version = "1.05.1-S2";

    // Error codes
    public static final int ERROR_NONE = 0;
    public static final int ERROR_SYNTAX            =  1;
    public static final int ERROR_MISSING_BRACKET   =  2;
    public static final int ERROR_MISSING_PIPE      =  3;
    public static final int ERROR_MISSING_PAREN     =  4;
    public static final int ERROR_MISSING_COMMA     =  5;
    public static final int ERROR_MISSING_ARG       =  6;
    public static final int ERROR_NOT_A_VAR         =  7;
    public static final int ERROR_MISSING_PARAM     =  8;
    public static final int ERROR_MISSING_EXPR      =  9;
    public static final int ERROR_RESERVED_WORD     = 10;
    public static final int ERROR_TOO_MANY_ARGS     = 11;
    public static final int ERROR_UNBALANCED_PARENS = 12;
    public static final int ERROR_PUTBACK           = 13;
    public static final int ERROR_UNSUPPORTED_OPER  = 14;
    public static final int ERROR_NO_CODE           = 20;
    public static final int ERROR_ILLEGAL_CODE      = 21;
    public static final int ERROR_INSUFFICIENT_ARGS = 22;
    public static final int ERROR_STACK_OVERFLOW    = 23;
    public static final int ERROR_DIVIDE_BY_ZERO    = 24;
    public static final int ERROR_ARG_NOT_NUMBER    = 25;
    public static final int ERROR_OTHER             = 33;

    /**----------------------------------------------------------------- Codeblock()
     */
    public Codeblock( ){
        lastError = Error.NONE;
        errDetail = "";
        optimizerEnabled = true;
//        if ( Mtelog.started == false )
//            Mtelog.start();
    }

    /**---------------------------------------------------------------- Initialize()
     * Initialize Codeblock
     *
     */
    public void Initialize() { }

    /**---------------------------------------------------------------- IsInitialize
     * Tests whether the object as been initialized
     *
     */
    public boolean getIsInitialize() {
        return (true);
    }


    /**------------------------------------------------------------------ Compile()
     * Compile expression into a Codeblock
     *
     * Example:  Dim cb as Codeblock
     *           cb.Initialize
     *           error = cb.Compile( "{||3+8}" )
     *
     *
     */
    public int Compile( String codeblockText ) {
        Error err;

        // Store codeblock text
        this.codeblockText = codeblockText;

        // Create code object
        code = new Code( codeblockText );

        // Compile the block
        err = Codegen.compileCodeBlock( this );

        return ( err.errCode );
    }

    /**---------------------------------------------------------------- Decompile()
     * Decompile a Codeblock
     *
     * Example:  Dim cb as CodeBlock
     *           Dim Decode as List
     *           cb.Initialize
     *           error = cb.Compile( "{|a,b|3*a+8*b}" )
     *           Decode = cb.Decompile
     *
     *
     */
    public List<String> Decompile() {

        List<String> codelist = new ArrayList<>();
        codelist = Run.dump(this);

        return ( codelist );
    }


    /**--------------------------------------------------------------------- Eval()
     * Evaulate a Codeblock
     *
     * Example:  Dim cb as Codeblock
     *           cb.Initialize
     *           error  = cb.Compile( "{||3+8}" )
     *           result = cb.Eval
     *
     */
    public double Eval() {
        double result;
        double args[] = {};

        result = Run.execute( this, args );

        return ( result );

    }

    /**-------------------------------------------------------------------- Eval2()
     * Evaulate a Codeblock with parameters
     *
     * Example:  Dim cb as CodeBlock
     *           cb.Initialize
     *           error = cb.Compile( "{|a,b|3*a+8*b}" )
     *           result = cb.Eval2( Array( 6, 10 ) )
     *
     */
    public double Eval2( Object Array[] ) {
        double result;
        double smallargs[];
        int i=0;

        // Convert big args to small
        smallargs = new double[ Array.length ];
        for ( Object obj : Array ) {
            if ( obj instanceof Double ) {
                smallargs[i++] = (Double)obj;
            }
            else if (obj instanceof Integer ) {
                smallargs[i++] = (Integer)obj;
            }
        }

        // Execute code
        result = Run.execute( this, smallargs );

        return ( result );
    }

    /**------------------------------------------------------------------------ Text
     * Codeblock expression text
     *
     */
    public String getText() {
        return ( this.errDetail );
    }


    /**---------------------------------------------------------------------- Error
     * Last error code
     *
     */
    public int getError() {
        return ( this.lastError.errCode );
    }

    /**------------------------------------------------------------------ ErrorDesc
     * Error description
     *
     */
    public String getErrorDesc() {
        return ( this.lastError.errDesc );
    }

    /**----------------------------------------------------------------- ErrorDetail
     * Error detail
     *
     */
    public String getErrorDetail() {
        return ( this.errDetail );
    }

    /**--------------------------------------------------------------------- Version
     * Version of the library
     *
     */
    public String getVersion() {
        return ( this.version );
    }

    /**-------------------------------------------------------- DisableOptimizations
     * Optimizer status
     *
     */
    public boolean getDisableOptimizations() {
        return ( !this.optimizerEnabled );
    }

    /**-------------------------------------------------------- DisableOptimizations
     * Disable or enable the optimizer
     *
     */
    public void setDisableOptimizations( boolean disable ) {
        this.optimizerEnabled = !disable;
    }
}