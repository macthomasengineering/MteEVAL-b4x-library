#B4X Expression Compiler and Eval Library

MteEval is a library for compiling and evaluating expressions at runtime. Expressions are converted to bytecode and then executed on demand with a simple virtual machine.

There are three builds of the library available: Android (B4A), iOS (B4i), and Java (B4J).  

##Usage

MteEval adopts the "code block" format from the venerable 1990's xBase compiler Clipper 5.X.

```clipper
{|<parameters,>|<expression>}
```

To use a code block: 

*1 Declare a Codeblock instance
*2 Initialize
+ Specify the expression and optional parameters
+ Compile
+ Evaluate with or without parameters.


```vbnet
Private cb as Codeblock
cb.Initialize
cb.Compile( "{||5 * 3}" )
Result = cb.Eval           'Result=8
```

##Linking

* To use the Android or Java editions, add the .JAR and .XML files to your _Additional Libraries_ folder and check the library through the Libraries Manager.  
* For iOS, copy the modules Codeblock.bas, Codegen.bas, PCODE.bas, and Run.bas to your project folder or place them in the _Shared Modules_ folder.








