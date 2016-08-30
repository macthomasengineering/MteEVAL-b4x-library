#B4X Expression Compiler and Eval Library

MteEval is a library for compiling and evaluating expressions at runtime. Expressions are converted to bytecode and then executed on demand with a simple virtual machine.

There are three editions of the library: Android (B4A), iOS (B4i), and Java (B4J).

See [Anywhere Software](https://www.b4x.com/) to learn more about the B4A, B4i, and B4J cross-platform development stacks.

##Usage

MteEval adopts the "code block" format from the venerable 1990's xBase compiler Clipper 5.  A codeblock is a compilable snippet of code.  Codeblocks begin with an open brace, followed by a optional parameter section couched between pipe symbols, the expression, then ends with a closing brace.

```clipper
{|<parameters>|<expression>}
```

You only need to compile the Codeblock once.  Once compiled you can evaluate it as many times as needed, all while supplying different parameters. 

Example 1: Codeblock without parameters

```vbnet
Dim cb as Codeblock
cb.Initialize
cb.Compile( "{||5 * 3}" )
Result = cb.Eval           'Result=8
```

Example 2 : Codeblock with parameters.

```vbnet
Dim cb as Codeblock
cb.Initialize
cb.Compile( "{|length,width|length*width}" )
Area = cb.Eval2( Array( 5, 13 ) )    'Area=65
```
_When you evaluate a Codeblock with parameters, use the Eval2 method._

##Linking to your project

* To use the Android or Java editions, add the .JAR and .XML files to your _Additional Libraries_ folder and check the MteEval library in the Libraries Manager of the IDE.  
* For iOS, copy the modules Codeblock.bas, Codegen.bas, PCODE.bas, and Run.bas to your project folder or place them in the _Shared Modules_ folder.  Then add the modules to the project through the IDE.








