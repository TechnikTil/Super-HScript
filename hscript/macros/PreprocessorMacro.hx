package hscript.macros;

import haxe.macro.Context;

/**
	PreprocessorMacro provides a list of preprocessor values passed to the compiler at compile time.
**/
class PreprocessorMacro
{
	/**
		Returns a list of preprocessor values
	**/
	public static macro function getPreprocessorValues()
	{
		var defines:Map<String, String> = Context.getDefines();
		return macro $v{defines};
	}
}