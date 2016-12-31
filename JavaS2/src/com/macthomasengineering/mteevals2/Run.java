/**********************************************************************************
 '*
 '* Run.java - Executes the code
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

import java.text.NumberFormat;
import java.util.ArrayList;
import java.util.List;
import anywheresoftware.b4a.BA;

@BA.Hide
/**-------------------------------------------------------------------------- Run()
 * Run()
 */
public final class Run {

    private static final int STACK_SIZE=50;
    private static final int MEMORY_SIZE=20;
    private static final int CODE_HEADER_PARAMETER_COUNT = 0;
    private static final int CODE_STARTS_HERE = 1;

    private static Codeblock codeBlock;

    /**------------------------------------------------------------------ execute()
    */
    public static double execute( Codeblock cb, double args[] ) {
        double result;

        // Store local reference to codeblock
        codeBlock = cb;

        // If no code then return here
        if ( cb.code.byteCode.length == 0 ) {
            setError( Error.NO_CODE, "Check compile error." );
            return ( 0d );
        }

       // Execute
       result = executeCode( cb.code, args );

        return ( result );
    }

    /**-------------------------------------------------------------- executeCode()
    */
    private static double executeCode( Code cbCode, double args[] ) {
        final int CODE_HEADER_PARAMETER_COUNT = 0;
        final int CODE_STARTS_HERE = 1;
        int pcode;
        boolean run;
        double retval = 0d;
        double value;
        double radians;
        int index;
        int target;
        int paramcount;
        double ax=0d;                                    // Accumulator
        int ip=0;                                        // Instruction pointer
        int sp=0;                                        // Stack pointer
        double stack[]  = new double[ STACK_SIZE + 1 ];  // STACK_SIZE + 1 because our stack is one based.
        double varmemory[] = new double[ MEMORY_SIZE ];  // Variable memory

        // References to bytecode and constants
        int[] code;
        double[] constData;

        // Set to bytecode and constants data table
        code = cbCode.byteCode;
        constData = cbCode.constData;

        // get parameter count
        paramcount = code[ CODE_HEADER_PARAMETER_COUNT ];

        // Invalid number of parameters? Return error
        if ( paramcount > args.length ) {
            setError( Error.INSUFFICIENT_ARGS, "Expecting " + Integer.toString( paramcount ) + " arguments.");
            return ( 0d );
        }

        // Too many?
        if ( paramcount > MEMORY_SIZE ) {
            setError( Error.TOO_MANY_ARGS, "Max arguments=" + Integer.toString( MEMORY_SIZE ) +
                                      ", argcount=" + Integer.toString( paramcount ) );
            return ( 0d );
        }

        // Store parameters
        if ( paramcount > 0 ) {

            // Store parameter values in variable memory
            for (int i = 0; i < paramcount; i++) {
                varmemory[i] = args[i];
            }
        }

        // Set instruction pointer
        ip = CODE_STARTS_HERE;

        // Execute code
        run = true;
        while ( run ) {

            // get instruction
            pcode = code[ip];

            // Execute
            switch ( pcode ) {

                case Pcode.PUSH:

                    // Overflow?
                    if ( ++sp > STACK_SIZE ) {
                        stackOverflowError( ip, ax, sp );
                        return ( 0d );
                    }
                    stack[sp] = ax;
                    break;

                case Pcode.PUSHVAR:

                    // get index into memory block
                    index = code[ ++ip ];

                    // store on stack
                    stack[++sp] = varmemory[index];
                    break;

                case Pcode.PUSHCONST:

                    // get index into memory block
                    index = code[ ++ip ];

                    // store on stack
                    stack[++sp] = constData[index];
                    break;

                case Pcode.LOADCONST:

                    // get index into const data table
                    index = code[ ++ip ];

                    // Get value from constant data table
                    ax = constData[ index ];

                    break;

                case Pcode.LOADVAR:

                    // get index into memory for this var
                    index = code[ ++ip ];

                    // Get value from memory block
                    ax = varmemory[ index ];
                    break;

                case Pcode.STOREVAR:

                    // get index into memory for this var
                    index = code[ ++ip ];

                    // store value in memory block
                    varmemory[ index ] = ax;
                    break;

               case Pcode.NEG:

                    ax = -ax;
                    break;

                case Pcode.ADD:

                    ax = stack[sp] + ax;
                    sp--;                        // pop
                    break;

                case Pcode.SUBTRACT:

                    ax = stack[sp] - ax;
                    sp--;                        // pop
                    break;

                case Pcode.MULTIPLY:

                    ax = stack[sp] * ax;
                    sp--;                        // pop
                    break;

                case Pcode.DIVIDE:

                    // Check for devide by zero
                    if ( ax == 0d ) {
                        divideByZeroError( ip, ax, sp );
                        return ( 0d );
                    }

                    ax = stack[sp] / ax;
                    sp--;                        // pop
                    break;

                case Pcode.MODULO:

                    ax = (int)stack[sp] % (int)ax;
                    sp--;                        // pop
                    break;

                case Pcode.LOGICAL_OR:

                    // A > 0 or B > 0
                    ax = (stack[sp] > 0 || ax > 0 ) ? 1d : 0d;
                    sp--;                        // pop
                    break;

                // A > 0 and B > 0
                case Pcode.LOGICAL_AND:

                    ax = (stack[sp] > 0 && ax > 0 ) ? 1d : 0d;
                    sp--;                        // pop
                    break;

                // !(A)
                case Pcode.LOGICAL_NOT:

                    ax = (ax == 0) ? 1:0;
                    break;

                case Pcode.EQUAL:

                    ax = ( stack[sp] == ax ) ? 1 : 0;
                    sp--;
                    break;

                case Pcode.NOT_EQUAL:

                    ax = ( stack[sp] != ax ) ? 1 : 0;
                    sp--;
                    break;

                case Pcode.LESS_THAN:

                    ax = ( stack[sp] < ax ) ? 1 : 0;
                    sp--;
                    break;

                case Pcode.LESS_EQUAL:

                    ax = ( stack[sp] <= ax ) ? 1 : 0;
                    sp--;
                    break;

                case Pcode.GREATER_THAN:

                    ax = ( stack[sp] > ax ) ? 1 : 0;
                    sp--;
                    break;

                case Pcode.GREATER_EQUAL:

                    ax = ( stack[sp] >= ax ) ? 1 : 0;
                    sp--;
                    break;

                case Pcode.BIT_AND:

                    ax = (int)stack[sp] & (int)ax;
                    sp--;
                    break;

                case Pcode.BIT_OR:

                    ax = (int)stack[sp] | (int)ax;
                    sp--;
                    break;

                case Pcode.BIT_XOR:

                    ax = (int)stack[sp] ^ (int)ax;
                    sp--;
                    break;

                case Pcode.BIT_NOT:

                    ax = ~(int)ax;
                    break;

                case Pcode.BIT_SHIFT_LEFT:

                    ax = (int)stack[sp] << (int)ax;
                    sp--;
                    break;

                case Pcode.BIT_SHIFT_RIGHT:

                    ax = (int)stack[sp] >> (int)ax;
                    sp--;
                    break;

                case Pcode.JUMP_ALWAYS:

                    ip += code[ ip + 1 ];

                    break;

                case Pcode.JUMP_FALSE:

                    if ( ax == 0d ) ip += code[ ip + 1 ]; else ip++;
                    break;

                case Pcode.JUMP_TRUE:

                    if ( ax > 0d ) ip += code[ ip + 1 ]; else ip++;
                    break;

                case Pcode.FUNC_ABS:

                    ax = Math.abs( stack[sp] );
                    sp--;
                    break;

                case Pcode.FUNC_MAX:

                    ax = (stack[sp-1] > stack[sp]) ? stack[sp-1] : stack[sp];
                    sp-= 2;
                    break;

                case Pcode.FUNC_MIN:

                    ax = (stack[sp-1] < stack[sp]) ? stack[sp-1] : stack[sp];
                    sp -= 2;
                    break;

                case Pcode.FUNC_SQRT:

                    ax = Math.sqrt( stack[sp] );
                    sp--;
                    break;

                case Pcode.FUNC_POWER:

                    ax = Math.pow( stack[sp-1], stack[sp] );
                    sp -=2;
                    break;

                case Pcode.FUNC_ROUND:

                    ax = Math.round( stack[sp] );
                    sp--;
                    break;

                case Pcode.FUNC_FLOOR:

                    ax = Math.floor( stack[sp] );
                    sp--;
                    break;

                case Pcode.FUNC_CEIL:

                    ax = Math.ceil( stack[sp] );
                    sp--;
                    break;

                case Pcode.FUNC_COS:

                    ax = Math.cos( stack[sp]);
                    sp--;
                    break;

                case Pcode.FUNC_COSD:

                    radians = stack[sp] * Math.PI / 180.0d;
                    ax = Math.cos(radians);
                    sp--;
                    break;

                case Pcode.FUNC_SIN:

                    ax = Math.sin( stack[sp]);
                    sp--;
                    break;

                case Pcode.FUNC_SIND:

                    radians = stack[sp] * Math.PI / 180.0d;
                    ax = Math.sin(radians);
                    sp--;
                    break;

                case Pcode.FUNC_TAN:

                    ax = Math.tan( stack[sp]);
                    sp--;
                    break;

                case Pcode.FUNC_TAND:

                    radians = stack[sp] * Math.PI / 180.0d;
                    ax = Math.tan(radians);
                    sp--;
                    break;

                case Pcode.FUNC_ACOS:

                    ax = Math.acos( stack[sp]);
                    sp--;
                    break;

                case Pcode.FUNC_ACOSD:

                    radians = Math.acos(stack[sp]);
                    ax = radians / Math.PI * 180.0d;   // convert to degrees
                    sp--;
                    break;

                case Pcode.FUNC_ASIN:

                    ax = Math.asin( stack[sp]);
                    sp--;
                    break;

                case Pcode.FUNC_ASIND:

                    radians = Math.asin(stack[sp]);
                    ax = radians / Math.PI * 180.0d;   // convert to degrees
                    sp--;
                    break;

                case Pcode.FUNC_ATAN:

                    ax = Math.atan( stack[sp]);
                    sp--;
                    break;

                case Pcode.FUNC_ATAND:

                    radians = Math.atan(stack[sp]);
                    ax = radians / Math.PI * 180.0d;   // convert to degrees
                    sp--;
                    break;

                case Pcode.FUNC_NUMBER_FORMAT:

                    NumberFormat nf = NumberFormat.getInstance();
                    nf.setMaximumFractionDigits((int)stack[sp]);        // arg3
                    nf.setMinimumIntegerDigits((int)stack[sp-1]);       // arg2
                    ax = Double.parseDouble(nf.format(stack[sp-2]));    // arg1
                    sp-=3;
                    break;

                case Pcode.FUNC_AVG:

                    ax = (stack[sp-1] + stack[sp])/2.0d;
                    sp-=2;
                    break;

                case Pcode.ENDCODE:

                    run = false;
                    retval = ax;
                    break;

                default:

                    setError( Error.ILLEGAL_CODE, "Pcode=" + Integer.toString(pcode) );
                    return ( 0 );
            }

            // Advance to next instruction
            ip++;
        }

        return ( retval );
    }



    /**------------------------------------------------------- stackOverflowError()
     */
    private static Error stackOverflowError( int ip, double ax, int sp ) {


        String detail = "IP=" + Integer.toString( ip ) +
                      ", AX=" + Double.toString( ax ) +
                      ", SP=" + Integer.toString( sp );

        return (setError( Error.STACK_OVERFLOW, detail) );
    }

    /**-------------------------------------------------------- divideByZeroError()
    */
    private static Error divideByZeroError( int ip, double ax, int sp ) {

        String detail = "IP=" + Integer.toString( ip ) +
                ", AX=" + Double.toString( ax ) +
                ", SP=" + Integer.toString( sp );

        return (setError( Error.DIVIDE_BY_ZERO, detail) );
    }

    /**----------------------------------------------------------------- setError()
     */
    private static Error setError( Error err, String errDetail ) {

        // Store last error and detail
        codeBlock.lastError = err;
        codeBlock.errDetail = errDetail;

        return ( err );
    }

    //***************************************************************************
    //*
    //* Decompiler
    //*
    //***************************************************************************

    /**--------------------------------------------------------------------- dump()
     */
    public static List<String> dump( Codeblock cb ) {

        List<String> decode = new ArrayList<>();

        // Store local reference to codeblock
        codeBlock = cb;

        // If no code then return here
        if ( cb.code.byteCode.length == 0 ) {
            return ( decode );
        }


        // Create list to store output
        decode = new ArrayList<>();

        // Dump instructions to the list
        dumpCode( cb.code, decode );

        return ( decode );
    }


    /**----------------------------------------------------------------- dumpCode()
    */
    private static void dumpCode( Code cbCode, List<String> decode ) {
        final int CODE_HEADER_PARAMETER_COUNT=0;
        final int CODE_STARTS_HERE=1;
        int pcode;
        boolean run;
        double retval;
        double value;
        int index;
        int target;
        int paramcount;
        int ip;

        // References to array bytecode and constants
        int[] code;
        double[] constData;

        // Set reference to bytecode and constants data table
        code = cbCode.byteCode;
        constData = cbCode.constData;

        // Get parameter count
        paramcount = code[ CODE_HEADER_PARAMETER_COUNT ];

        decode.add( "-- Header --");
        decode.add( "Parameters=" + paramcount );
        decode.add( "-- Code --");

        // Set instruction pointer
        ip = CODE_STARTS_HERE;

        // List code
        run = true;
        while ( run ) {

            // get instruction
            pcode = code[ip];

            // Decode
            switch ( pcode ) {

                case Pcode.PUSH:

                    decode.add(pad( ip, "push", "ax" ));
                    break;

                case Pcode.PUSHVAR:

                    // Next instruction has offset into const table
                    ip++;

                    // get index into memory block
                    index = code[ ip ];

                    decode.add( pad( ip-1, "pushv", "varmem[" + Integer.toString(index) + "]"));

                    break;

                case Pcode.PUSHCONST:

                    // Next instruction has offset into const table
                    ip++;

                    // get index into const data table
                    index = code[ ip ];

                    // Get value from constant data table
                    value = constData[ index ];

                    decode.add( pad( ip-1, "pushc", Double.toString(value)));

                    break;

                case Pcode.LOADCONST:

                    // Next instruction has offset into const table
                    ip++;

                    // get index into const data table
                    index = code[ ip ];

                    // Get value from constant data table
                    // value = constData.get( index );
                    value = constData[ index ];

                    decode.add(pad( ip-1, "loadc", "ax, " + value));
                    break;

                case Pcode.LOADVAR:

                    ip++;
                    // index = code.get( ip );
                    index = code[ ip ];
                    decode.add(pad( ip-1, "loadv", "ax, varmem[" + index + "]"));
                    break;

                case Pcode.STOREVAR:

                    ip++;
                    // index = code.get( ip );
                    index = code[ ip ];
                    decode.add(pad( ip-1, "storev", "varmem[" + index + "], ax"));
                    break;

                case Pcode.NEG:

                    decode.add(pad( ip, "neg", "ax"));
                    break;

                case Pcode.ADD:

                    decode.add(pad( ip, "add", "stack[sp] + ax" ));
                    decode.add(pad( ip, "pop", ""));
                    break;

                case Pcode.SUBTRACT:
                    
                    decode.add(pad( ip, "sub", "stack[sp] - ax"));
                    decode.add(pad( ip, "pop", ""));
                    break;

                case Pcode.MULTIPLY:
                        
                    decode.add(pad( ip, "mul", "stack[sp] * ax"));
                    decode.add(pad( ip, "pop", ""));
                    break;

                case Pcode.DIVIDE:

                    decode.add(pad( ip, "div", "stack[sp] / ax"));
                    decode.add(pad( ip, "pop", ""));
                    break;

                case Pcode.MODULO:

                    decode.add(pad( ip, "mod", "stack[sp] % ax"));
                    decode.add(pad( ip, "pop", ""));
                    break;

                case Pcode.LOGICAL_OR:

                    decode.add(pad( ip, "or", "stack[sp] || ax"));
                    decode.add(pad( ip, "pop", ""));
                    break;

                case Pcode.LOGICAL_AND:

                    decode.add(pad( ip, "and", "stack[sp] && ax"));
                    decode.add(pad( ip, "pop", ""));
                    break;

                case Pcode.LOGICAL_NOT:

                    decode.add(pad( ip, "not", "ax"));
                    break;

                case Pcode.EQUAL:

                    decode.add(pad( ip, "eq", "stack[sp] == ax"));
                    decode.add(pad( ip, "pop", ""));
                    break;

                case Pcode.NOT_EQUAL:

                    decode.add(pad( ip, "neq", "stack[sp] != ax"));
                    decode.add(pad( ip, "pop", ""));
                    break;

                case Pcode.LESS_THAN:

                    decode.add(pad( ip, "lt", "stack[sp] < ax"));
                    decode.add(pad( ip, "pop", ""));
                    break;

                case Pcode.LESS_EQUAL:

                    decode.add(pad( ip, "le", "stack[sp] <= ax"));
                    decode.add(pad( ip, "pop", ""));
                    break;

                case Pcode.GREATER_THAN:

                    decode.add(pad( ip, "gt", "stack[sp] > ax"));
                    decode.add(pad( ip, "pop", ""));
                    break;

                case Pcode.GREATER_EQUAL:

                    decode.add(pad( ip, "ge", "stack[sp] >= ax"));
                    decode.add(pad( ip, "pop", ""));
                    break;

                case Pcode.BIT_AND:

                    decode.add(pad( ip, "bitand", "stack[sp] & ax"));
                    decode.add(pad( ip, "pop", ""));
                    break;

                case Pcode.BIT_OR:

                    decode.add(pad( ip, "bitor", "stack[sp] | ax"));
                    decode.add(pad( ip, "pop", ""));
                    break;

                case Pcode.BIT_XOR:

                    decode.add(pad( ip, "bitxor", "stack[sp] ^ ax"));
                    decode.add(pad( ip, "pop", ""));
                    break;

                case Pcode.BIT_NOT:

                    decode.add(pad( ip, "bitnot", "~ ax"));
                    break;

                case Pcode.BIT_SHIFT_LEFT:

                    decode.add(pad( ip, "bitlft", "stack[sp] << ax"));
                    decode.add(pad( ip, "pop", ""));
                    break;

                case Pcode.BIT_SHIFT_RIGHT:

                    decode.add(pad( ip, "bitrgt", "stack[sp] >> ax"));
                    decode.add(pad( ip, "pop", ""));
                    break;

                case Pcode.JUMP_ALWAYS:

                    target = ip +  code[ ip + 1 ]  + 1;   //  + 1 needed for correct location

                    decode.add(pad( ip, "jump", Integer.toString(target)));
                    ip++;
                    break;

                case Pcode.JUMP_FALSE:

                    target = ip +  code[ ip + 1 ]  + 1;   //  + 1 needed for correct location
                    decode.add(pad( ip, "jumpf", Integer.toString(target)));
                    ip++;
                    break;

                case Pcode.JUMP_TRUE:

                    target = ip +  code[ ip + 1 ]  + 1;   //  + 1 needed for correct location
                    decode.add(pad( ip, "jumpt", Integer.toString(target)));
                    ip++;
                    break;

                case Pcode.FUNC_ABS:

                    decode.add(pad( ip, "call", "abs"));
                    decode.add(pad( ip, "pop", ""));
                    break;

                case Pcode.FUNC_MAX:

                    decode.add(pad( ip, "call", "max"));
                    decode.add(pad( ip, "pop", "2"));
                    break;

                case Pcode.FUNC_MIN:

                    decode.add(pad( ip, "call", "min"));
                    decode.add(pad( ip, "pop", "2"));
                    break;

                case Pcode.FUNC_SQRT:

                    decode.add(pad( ip, "call", "sqrt"));
                    decode.add(pad( ip, "pop", ""));
                    break;

                case Pcode.FUNC_POWER:

                    decode.add(pad( ip, "call", "power"));
                    decode.add(pad( ip, "pop", "2"));
                    break;

                case Pcode.FUNC_ROUND:

                    decode.add(pad( ip, "call", "round"));
                    decode.add(pad( ip, "pop", ""));
                    break;

                case Pcode.FUNC_FLOOR:

                    decode.add(pad( ip, "call", "floor"));
                    decode.add(pad( ip, "pop", ""));
                    break;

                case Pcode.FUNC_CEIL:

                    decode.add(pad( ip, "call", "ceil"));
                    decode.add(pad( ip, "pop", ""));
                    break;

                case Pcode.FUNC_COS:

                    decode.add(pad( ip, "call", "cos"));
                    decode.add(pad( ip, "pop", ""));
                    break;

                case Pcode.FUNC_COSD:

                    decode.add(pad( ip, "call", "cosd"));
                    decode.add(pad( ip, "pop", ""));
                    break;

                case Pcode.FUNC_SIN:

                    decode.add(pad( ip, "call", "sin"));
                    decode.add(pad( ip, "pop", ""));
                    break;

                case Pcode.FUNC_SIND:

                    decode.add(pad( ip, "call", "sind"));
                    decode.add(pad( ip, "pop", ""));
                    break;

                case Pcode.FUNC_TAN:

                    decode.add(pad( ip, "call", "tan"));
                    decode.add(pad( ip, "pop", ""));
                    break;

                case Pcode.FUNC_TAND:

                    decode.add(pad( ip, "call", "tand"));
                    decode.add(pad( ip, "pop", ""));
                    break;

                case Pcode.FUNC_ACOS:

                    decode.add(pad( ip, "call", "acos"));
                    decode.add(pad( ip, "pop", ""));
                    break;

                case Pcode.FUNC_ACOSD:

                    decode.add(pad( ip, "call", "acosd"));
                    decode.add(pad( ip, "pop", ""));
                    break;

                case Pcode.FUNC_ASIN:

                    decode.add(pad( ip, "call", "asin"));
                    decode.add(pad( ip, "pop", ""));
                    break;

                case Pcode.FUNC_ASIND:

                    decode.add(pad( ip, "call", "asind"));
                    decode.add(pad( ip, "pop", ""));
                    break;

                case Pcode.FUNC_ATAN:

                    decode.add(pad( ip, "call", "atan"));
                    decode.add(pad( ip, "pop", ""));
                    break;

                case Pcode.FUNC_ATAND:

                    decode.add(pad( ip, "call", "atand"));
                    decode.add(pad( ip, "pop", ""));
                    break;

                case Pcode.FUNC_NUMBER_FORMAT:

                    decode.add(pad( ip, "call", "numberformat"));
                    decode.add(pad( ip, "pop", "3"));
                    break;

                case Pcode.FUNC_AVG:

                    decode.add(pad( ip, "call", "avg"));
                    decode.add(pad( ip, "pop", "2"));
                    break;

                case Pcode.ENDCODE:

                    decode.add(pad( ip, "end", ""));
                    run = false;
                    break;

                default:

                    decode.add(pad( ip, "err", "pcode=" + pcode));
                    run=false;
            }

            // Advance to next instruction
            ip++;
        }

    }

    /**---------------------------------------------------------------------- pad()
     */
    private static String pad ( int ip, String instruct, String operands ) {
        String instructWithPad;
        String ipWithPad;
        String formatted;

        ipWithPad = Integer.toString( ip ) + ":          ";
        instructWithPad = instruct +  "          ";
        formatted = ipWithPad.substring(0,7) +  instructWithPad.substring(0,8) + operands;

        return ( formatted );

    }

}
