#B4X Expression Compiler and Eval Library

MteEval is a library for compiling and evaluating expressions at runtime. Expressions are converted to bytecode and then executed on demand with a simple virtual machine.

There are three builds of the library available: Android (B4A), iOS (B4i), and Java (B4J).  

##Usage

MteEval adopts the "code block" format from the venerable 1990's xBase compiler Clipper 5.X.

```clipper
{|<parameters,>|<expression>}
```

Example 1: Codeblock without parameters

```vbnet
Dim cb as Codeblock
cb.Initialize
cb.Compile( "{||5 * 3}" )
Result = cb.Eval           'Result=8
```

Example2 : Codeblock with parameters.

```vbnet
Private cb as Codeblock
cb.Initialize
cb.Compile( "{|l,w,|l*w}" )
Area = cb.Eval2( Array( 5, 13 ) )    'Result=65
```
_When you evaluate a Codeblock with parameters, use the Eval2 method._

##Linking

* To use the Android or Java editions, add the .JAR and .XML files to your _Additional Libraries_ folder and check the MteEval library in the Libraries Manager of the IDE.  
* For iOS, copy the modules Codeblock.bas, Codegen.bas, PCODE.bas, and Run.bas to your project folder or place them in the _Shared Modules_ folder.  Then add the modules to the project through the IDE.








