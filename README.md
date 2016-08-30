#B4X Expression Compiler and Eval Library

MteEval is a library for compiling and evaluating expressions at runtime. Expressions are converted to bytecode and then executed on demand with a simple virtual machine.

There are three editions of the library: Android (B4A), iOS (B4i), and Java (B4J).

See [Anywhere Software](https://www.b4x.com/) to learn more about the B4A, B4i, and B4J cross-platform development tools.

##Applications

The ability to create and evaluate expressions at runtime is a powerful tool and allows formulas and other calculations to be customized post installation, which otherwise would require a physical update or a custom build of an application.  For example, any application designed to manage a sales compensation plan could benefit from runtime compilation, where the sales manager may want to customize the plan formulas for their product mix and sales goals.  

##Usage

MteEval adopts the "code block" format for expressions from the venerable 1990's xBase compiler Clipper 5.  A codeblock is a compilable snippet of code.  Codeblocks begin with an open brace, followed by a optional parameter section couched between pipe symbols, the expression, then ends with a closing brace.

```clipper
{|<parameters>|<expression>}
```

##Example

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








