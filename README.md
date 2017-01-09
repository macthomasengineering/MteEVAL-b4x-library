[![Stories in Ready](https://badge.waffle.io/macthomasengineering/mteeval-b4x-library.png?label=ready&title=Ready)](https://waffle.io/macthomasengineering/mteeval-b4x-library)
#MteEVAL - B4X Expression Compiler and Eval Library

MteEVAL is a library for compiling and evaluating expressions at runtime. Expressions are converted to bytecode and then executed on demand with a simple virtual machine.

There are four editions of the library: Android (B4A), iOS (B4i), Java (B4J), JavaS2 (B4A/B4J).

   *JavaS2 is our stage 2 performance edition of the library in native Java.*

See [Anywhere Software](https://www.idevaffiliate.com/33168/16-0-3-1.html) to learn more about B4A, B4i, and B4J cross-platform development tools.

##Application

Creating expressions at runtime is a powerful tool allowing calculations and program flow to be modified after installation, which otherwise would require a physical update or a custom build of an application. For example, any application designed to manage a sales compensation plan could benefit from runtime expressions, where the end-user may want to customize the plan's formulas by team members, product mixes and sales goals.

##Codeblocks

MteEVAL implements a single class named Codeblock. MteEVAL's codeblock adopts the syntax from the venerable 1990's xBase compiler [Clipper 5](https://en.wikipedia.org/wiki/Clipper_(programming_language)) where the construct began. Codeblocks start with an open brace, followed by an optional parameter list between pipes, then the expression, and end with a closing brace.

```clipper
{|<parameters>|<expression>}
```

##Examples

You only need to compile a Codeblock once.  Once compiled you can evaluate it as many times as needed, all while supplying different arguments. 

Example 1: Codeblock without parameters

```vbnet
Dim cb as Codeblock
cb.Initialize
cb.Compile( "{||5 + 3}" )
Result = cb.Eval           'Result=8
```

Example 2: Codeblock with parameters

```vbnet
Dim cb as Codeblock
cb.Initialize
cb.Compile( "{|length,width|length*width}" )
Area = cb.Eval2( Array( 3, 17 ) )    'Area=51
```
_When evaluating a Codeblock with parameters, use the Eval2 method._

Example 3: Codeblock compile, eval and repeat

```vbnet
Dim cb as Codeblock
cb.Initialize
cb.Compile( "{|sales,r1,r2| r1*sales + iif( sales > 100000, (sales-100000)*r2, 0 ) }" )
Commission1 = cb.Eval2( Array( 152000, .08, .05 ) )    'Commission1=14760
Commission2 = cb.Eval2( Array( 186100, .08, .07 ) )    'Commission2=20915
Commission3 = cb.Eval2( Array( 320000, .08, .05 ) )    'Commission3=36600
```
##Operator support

The library supports C/Java style operators along side a growing list of B4X native functions.

* Math operators: +-*/%
* Relational: > < >= <= != ==
* Logical: || && !
* Bitwise: << >> & ^ |
* Assignment: =
* Functions: abs(), ceil(), floor(), iif(), if(), min(), max(), sqrt(), power(), round()
* Trig Functions: acos(), acosd(), asin(), asind(), atan(), atand(), cos(), cosd(), sin(), sind(), tan(), tand()

##Linking to your project

* To use the Android or Java editions, add the .JAR and .XML files to your _Additional Libraries_ folder and check the MteEVAL library in the Libraries Manager of the IDE.  
* For iOS, copy the modules Codeblock.bas, Codegen.bas, PCODE.bas, and Run.bas to your project folder or place them in the _Shared Modules_ folder.  Then add the modules to the project through the IDE.








