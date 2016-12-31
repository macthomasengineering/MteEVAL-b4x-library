/**********************************************************************************
 '*
 '* Error.java - Error codes
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

import anywheresoftware.b4a.BA;

@BA.Hide
/**------------------------------------------------------------------------ Error()
 * Error()
 */
public enum Error {

    NONE(                  0, "None" ),
    SYNTAX(                1, "Syntax Error"),
    MISSING_BRACKET(       2, "{} bracket not found" ),
    MISSING_PIPE(          3, "|| pipe not found"),
    MISSING_PAREN(         4, "Missing parenthesis"),
    MISSING_COMMA(         5, "Missing comma"),
    MISSING_ARG(           6, "Missing argument"),
    NOT_A_VAR(             7, "Unknown parameter"),
    MISSING_PARAM(         8, "Missing parameter"),
    MISSING_EXPR(          9, "Missing expression"),
    RESERVED_WORD(        10, "Reserved word"),
    TOO_MANY_ARGS(        11, "Too many arguments"),
    UNBALANCED_PARENS(    12, "Unbalanced parens"),
    PUTBACK(              13, "Internal parser error"),
    UNSUPPORTED_OPER(     14, "Unsupported operator"),
    NO_CODE(              20, "No code to execute"),
    ILLEGAL_CODE(         21, "Illegal instruction"),
    INSUFFICIENT_ARGS(    22, "Insufficient arguments"),
    STACK_OVERFLOW(       23, "Stack overflow"),
    DIVIDE_BY_ZERO(       24, "Divide by zero"),
    ARG_NOT_NUMBER(       25, "Not a number"),
    OTHER(                33, "Other error");

    int errCode;
    String errDesc;

    Error( int errCode, String errDesc ) {

        this.errCode = errCode;
        this.errDesc = errDesc;
    }

    @Override
    public String toString() {
        return (errDesc);
    }
}

