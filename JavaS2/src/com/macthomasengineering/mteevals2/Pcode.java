/**********************************************************************************
 '*
 '* Pcode.java - Op codes
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
/**------------------------------------------------------------------------ Pcode()
 * Pcode()
 */
public class  Pcode {

    // Null pcode
    public static final int NONE                =  0;

    // Stack
    public static final int PUSH                =  1;
    public static final int PUSHVAR             =  2;
    public static final int PUSHCONST           =  3;

    // Load and store
    public static final int LOADCONST           =  4;
    public static final int LOADVAR             =  5;
    public static final int STOREVAR            =  6;

    // Math
    public static final int NEG                 =  7;
    public static final int ADD                 =  8;
    public static final int SUBTRACT            =  9;
    public static final int DIVIDE              = 10;
    public static final int MULTIPLY            = 11;
    public static final int MODULO              = 12;

    // Logical
    public static final int LOGICAL_OR          = 13;
    public static final int LOGICAL_AND         = 14;
    public static final int LOGICAL_NOT         = 15;

    // Relational
    public static final int EQUAL               = 16;
    public static final int NOT_EQUAL           = 17;
    public static final int LESS_THAN           = 18;
    public static final int LESS_EQUAL          = 19;
    public static final int GREATER_THAN        = 20;
    public static final int GREATER_EQUAL       = 21;

    // Bitwise
    public static final int BIT_AND             = 22;
    public static final int BIT_OR              = 23;
    public static final int BIT_XOR             = 24;
    public static final int BIT_NOT             = 25;
    public static final int BIT_SHIFT_LEFT      = 26;
    public static final int BIT_SHIFT_RIGHT     = 27;

    // Jumps
    public static final int JUMP_ALWAYS         = 28;
    public static final int JUMP_FALSE          = 29;
    public static final int JUMP_TRUE           = 30;

    // Internal functions
    public static final int FUNC_ABS            = 31;
    public static final int FUNC_IIF            = 32;
    public static final int FUNC_MAX            = 33;
    public static final int FUNC_MIN            = 34;
    public static final int FUNC_SQRT           = 35;
    public static final int FUNC_POWER          = 36;
    public static final int FUNC_ROUND          = 37;
    public static final int FUNC_FLOOR          = 38;
    public static final int FUNC_CEIL           = 39;
    public static final int FUNC_COS            = 40;
    public static final int FUNC_COSD           = 41;
    public static final int FUNC_SIN            = 42;
    public static final int FUNC_SIND           = 43;
    public static final int FUNC_TAN            = 44;
    public static final int FUNC_TAND           = 45;
    public static final int FUNC_ACOS           = 46;
    public static final int FUNC_ACOSD          = 47;
    public static final int FUNC_ASIN           = 48;
    public static final int FUNC_ASIND          = 49;
    public static final int FUNC_ATAN           = 50;
    public static final int FUNC_ATAND          = 51;
    public static final int FUNC_NUMBER_FORMAT  = 52;
    public static final int FUNC_AVG            = 53;

    public static final int ENDCODE             = 54;
}
