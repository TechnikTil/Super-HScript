# Super-HScript
An extension to the original [HaxeFoundation's HScript](https://github.com/HaxeFoundation/hscript) library for parsing and evaluating Haxe expressions at runtime.
<br>
Because it's an add-on, it does not overwrite the original classes' functionality; rather, it overrides them with its own code. This approach allows merging Super-HScript's features with HScript's official updates without much hassle.

## Table of Contents
- [Introduction](#super-hscript)
- [Features](#features)
- [To be added](#to-be-added)
- [Changelogs](#changelogs)
- [Showcase and Examples](#showcase-and-examples)
  - [String interpolation](#string-interpolation)
  - [Null safety](#null-safety)
  - [Classes and OOP](#classes-and-oop)
  - [Type blacklisting (Experimental)](#type-blacklisting-experimental)
  
- [Setup](#setup)
- [Usage](#usage)
- [Contributing](#contributing)


# Features
- Static and instanced classes
- Packages
- Imports
  - ~~Import type aliases~~
  - ~~Import static fields~~
  - ~~Import wildcards~~
- Inheritance
- Type blacklisting
- String interpolation
- Nullish coalesing
- Nullish assignment
- Ternary operators
- Optional chaining

# To be added
View [TODO.md](/TODO.md) for a list of features to be added to super-hscript.

# Changelogs
View [CHANGELOG.md](/CHANGELOG.md) for a list of updates.

# Showcase and Examples
## String interpolation
```haxe
var myVar:String = "world";
trace('Hello, $myVar!'); // Hello, world!
```
```haxe
var num:Int = 5;
trace('$num is an ${(num % 2 == 0) ? "even" : "odd"} number'); // 5 is an odd number
```

## Null safety
```haxe
var unknownVar:String = null;
trace("value: " + unknownVar ?? "UNKNOWN"); // UNKNOWN

unknownVar ??= "something";
trace("\"unknownVar is now \"" + unknownVar); // "unknownVar" is now something
```
```haxe
var myField = someType?.unknownField?.doesNotExist ?? "???";
trace(myField); // ???
```

## Classes and OOP
```haxe
package;

import Date;
import DateTools;

class MyHScriptClass extends somePackage.ExtendableClass
{
  public static function greet(name:String = "human")
  {
    trace('Hello, $name');
    var currentTime = DateTools.format(Date.now(), "%T");
    trace('\tThe time is: $currentTime');
  }

  var myPersonalNumber:Int;

  public function new()
  {
    super(1);
  }

  override function generateRandom(param:Float):Int
  {
    if (param == 0)
      return myPersonalNumber;

    return super.generateRandom(param+0.7e2);
  }
}
```

## Type blacklisting (Experimental)
Blacklisting types will make the interpreter throw an error whenever it resolves an expression that results in a blacklisted type. This can be useful for controlling what users can and can't use by limiting access to potentially dangerous APIs.

> [!WARNING]
> This is an experimental feature, and it's prone to issues and bypasses. Do not trust or rely solely on it!

```haxe
class Main
{
  static function main()
  {
    var parser = new hscript.SuperParser();
    var interp = new hscript.SuperInterp();

    // Adds the "SystemClass" class to the blacklist
    interp.blacklist.push(SystemClass);

    var script:String = File.getContent("TestHScript.hscript");

    var program = parser.parseString(script, "TestHScript.hscript");
    interp.execute(program);
  }
}

class SystemClass
{
  public static function dangerousFunction()
  {
    trace("uh oh, your system has been compromised");
  }
}
```

TestHScript.hscript
```haxe
import SystemClass; // ERROR: "Blacklisted import SystemClass"

var danger = Type.resolveClass("SystemClass") // ERROR: "Blacklisted expression SystemClass referenced"

Reflect.callMethod(null, ,Reflect.field(Type.resolveClass("SystemClass"), "dangerousFunction"), []); // ERROR: "Blacklisted expression SystemClass referenced"
```

# Setup
1. Installing the library:
  - haxelib: ``haxelib install super-hscript``
  - github: ``haxelib git super-hscript https://github.com/Davvex87/Super-HScript.git``
  - dev: ``haxelib git super-hscript https://github.com/Davvex87/Super-HScript.git dev``

2. Adding to project:
  - hxml: ``-lib super-hscript``
  - lime/openfl: ``<haxelib name="super-hscript"/>``

> [!NOTE]
> The hscript library should be installed first!

> [!NOTE]
> The hscript library is automatically imported with super-hscript, as well as the hscriptPos flag.

# Usage
Super-HScript provides two new parsers and two new interpreters.

## ReParser/ReInterp
These two are responsible for the language feature expansion and work pretty much just like the original parser and interpreter classes.

## SuperParser/SuperInterp
These extend ReParser and ReInterp; however, unlike those, they also provide OOP functionality and a simpler API.

## Steps
1. Initialize the parser and interpreter
```haxe
var parser = new hscript.SuperParser();
var interp = new hscript.SuperInterp();
```

2. Parse the AST of a script and it's modules
```haxe
// Write your script here or read it from a file
var script:String = "
package hscript;

class TestScript
{
  public static function greet()
  {
    trace('Hello, world!');
  }

  public var myVar:Float = 5;
  public function new() {}
}
";

var program = parser.parseString(script, "TestScript.hx", 0 );

parser.resumeErrors = true;
var declarations = parser.parseModule(script, "TestScript.hx", 0 );
parser.resumeErrors = false;
```

3. Execute and register all available modules
```haxe
interp.execute(program);
interp.registerStructures(declarations);
```

4. Using the generated HScript classes
```haxe
var cls:hscript.AbstractHScriptClass = hscript.SuperInterp.resolveClass("hscript.TestScript");

// cls is now bound to an hscript class, you can get, set and call fields just like a normal class or object.
cls.greet(); // Hello, world!

// To create an instance, simply call ``createInstance(...args)``
var obj = cls.createInstance();
trace(obj.myVar); // 5
```

> [!TIP]
> Programs parsed with the HScript parser can be executed by SuperInterp and ReInterp, but note that although programs parsed with SuperParser or ReParser can be run by the HScript interpreter, they may throw unexpected errors.

# Contributing
Contributions are highly welcome, both in the form of issues and pull requests. It is recommended that you clone the master branch for PRs, as the development branch may be unstable.