package hscript.macros;

import haxe.macro.Expr;
import haxe.macro.Context;

using StringTools;

/**
	Macro class for compiling a list of all known classes and types at compile time
	to be used by the super-hscript interpreter.
**/
class PackageMacro
{
	/**
		Returns a list of all known classes and types at compile time.
	**/
	public static macro function getClassList()
	{
		return macro $v{allTypeSearch};
	}

	
	// INTERNAL

	static var allTypeSearch:Array<String> = [];
	private static macro function buildAll():Array<haxe.macro.Field>
	{
		var fields:Array<haxe.macro.Expr.Field> = haxe.macro.Context.getBuildFields();

		var cls:Dynamic = Context.getLocalClass();
		if (cls == null) return fields;

		var cls:haxe.macro.Type.ClassType = cls.get();
		if (cls == null) return fields;

		if (cls.name.endsWith("_Impl_"))
			return fields;

		var finalPack = "";

		for (p in cls.pack)
			finalPack = '$finalPack.$p';

		finalPack += ".";

		finalPack += cls.name;

		allTypeSearch.push(finalPack.substr(1));
		return fields;
	}
}