#B4X Expression Compiler and Eval Library

MteEval is a library for compiling and evaluating expressions at runtime. Expressions are converted to bytecode and then executed on demand with a simple virtual machine.

There are three builds of the library available: Android (B4A), iOS (B4i), and Java (B4J).  

##Usage

MteEval adopts the "code block" format from the venerable 1990's xBase compiler Clipper 5.X.

```clipper
{|<parameters,>|<expression>}
```

##Linking

* To use the Android or Java editions, add the .JAR to your project.  
* For iOS, add the modules Codeblock.bas, Codegen.bas, PCODE.bas, and Run.bas to your project.








