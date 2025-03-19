package;

import hscript.AbstractHScriptClass;

class Test
{
	static function main()
	{
		// TODO: Make proper unit tests, this stinks

		var parser = new hscript.SuperParser();
		var interp = new hscript.SuperInterp();

		var script:String = "
		package hscript;

		import haxe.ds.StringMap;
		import haxe.io.Path;

		class TestClass extends TestClass
		{
			public static var hscriptStaticVar:Float = 2.7;

			static public function myStaticFunc(add:Float, mult:Float, div:Float = 1.3)
			{
				trace(hscriptStaticVar + add);
				trace(hscriptStaticVar / div);
				staticPrivateFunc();
				return hscriptStaticVar * mult;
			}




			public var hscriptVar:String = 'Hello World!';

			public function new(num:Int, str:String)
			{
				trace('instanced!');
				trace(super);
				super();
				trace(num);
				trace(str);
				trace(super);
			}

			public function hscriptFunc(add:Float)
			{
				trace('hscript function called');
				trace(super.myVar + add);
			}

			private function privateFunc()
			{
				trace('private func');
				trace(super.myFunc('bruh', 555555.5555));
			}

			private static function staticPrivateFunc()
			{
				mult = 10; // going to ignore this, should not happen;
				trace('called the private function from static class');
			}
		}
		";
		trace("created interp and parser");
		
		var program = parser.parseString(script, "TestScript.hx", 0 );
		trace("parsed script");
		parser.resumeErrors = true;
		var declarations = parser.parseModule(script, "TestScript.hx", 0 );
		parser.resumeErrors = false;
		trace("parsed modules");

		trace("executing");

		interp.execute(program);

		trace("registering structures");

		interp.registerStructures(declarations);

		trace("getting class");

		var cls:AbstractHScriptClass = hscript.SuperInterp.resolveClass("hscript.TestClass");
		trace("got the class");
		
		//try { trace(cls.hscriptStaticVar); } catch(e:Dynamic) { trace(e); } // works
		//try { trace(cls.myStaticFunc(5, 3)); } catch(e:Dynamic) { trace(e); } // works, need to test to see if function arguments remain in the local variables list
		//try { trace(cls.staticPrivateFunc()); } catch(e:Dynamic) { trace(e); } // works
		// dont need to test for class extensions because static classes do not need to extend other classes

		var inst:AbstractHScriptClass = cls.createInstance(85, "hi");

		try { trace(inst.hscriptVar); } catch(e:Dynamic) { trace(e); }
		try { trace(inst.hscriptFunc(2.5)); } catch(e:Dynamic) { trace(e); }
		try { trace(inst.privateFunc()); } catch(e:Dynamic) { trace(e); }
		try { trace(inst.myVar); } catch(e:Dynamic) { trace(e); }
		try { trace(inst.myFunc(123,456)); } catch(e:Dynamic) { trace(e); }
		try { trace(inst.super.myFunc(123,456)); } catch(e:Dynamic) { trace(e); }
		try { inst.myVar += 8; } catch(e:Dynamic) { trace(e); }
		try { trace(inst.myVar); } catch(e:Dynamic) { trace(e); }
		try { trace(inst.myPrivateFunc(1)); } catch(e:Dynamic) { trace(e); }

		trace("DONE!");
	}
}

class TestClass
{
	public static var staticVar:Float = 9.30;

	public var myVar:Int = 1;

	public function new()
	{
		trace("CONSTRUCTOR CALLED!!!");
	}

	public function myFunc(arg1:Dynamic, arg2:Dynamic, arg3:Dynamic)
	{
		trace('my function was called with args $arg1 $arg2 and $arg3');
		return 5;
	}

	private function myPrivateFunc()
	{
		trace('my private function was called');
		return 'hello!';
	}
}