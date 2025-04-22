package;

import utest.ITest;
import utest.Assert;
import hscript.*;

class Test
{
	static function main()
	{
		var runner = new utest.Runner();

		runner.addCase(new TestHScriptFeatures());
		runner.addCase(new TestHScriptOOP());

		utest.ui.Report.create(runner);
		runner.run();
	}
}

class TestHScriptFeatures implements ITest
{
	public function new() {}

	private function evalExpr(expr:String, ?params:Array<Dynamic>):Dynamic
	{
		var parser = new SuperParser();
		var interp = new SuperInterp();

		var program = parser.parseString(expr, '<eval>', 0);

		if (params != null)
			interp.variables.set("params", params);

		return interp.execute(program);
	}

	function testArithmetic()
	{
		Assert.equals(7, evalExpr('3 + 4;'));
		Assert.equals(14, evalExpr('3 * 4 + 2;'));
		Assert.equals(4, evalExpr('16 / (7 - 3);'));
	}

	function testConditions()
	{
		Assert.isTrue(evalExpr("3 > 1;"));
		Assert.isTrue(evalExpr("3 >= 3;"));
		Assert.isFalse(evalExpr("4 < 7 && 1 + 2 == 4;"));
		Assert.isTrue(evalExpr("false || 1 % 2 == 1;"));
		Assert.equals("I am at work", evalExpr("if (true == false) 'I am here'; else 'I am at work';"));
		Assert.equals(3, evalExpr("false ? 10 : 3;"));
	}

	function testStringInterpolation()
	{
		Assert.equals("Hello, World!", evalExpr("'Hello, ${params[0]}!';", ["World"]));
		Assert.equals("I have 5 coins", evalExpr("'I have ${3+2} coins';"));
		Assert.equals("OneTwoThree", evalExpr("'${params[0]}${params[1]}${params[2]}';", ["One","Two","Three"]));
	}

	function testAssignment()
	{
		Assert.equals(7, evalExpr('var a = 5; a += 2;'));
		Assert.equals('foo', evalExpr("var a:String = null; a ??= 'foo'; a;"));
	}

	function testOptionalChaining()
	{
        Assert.equals('ok', evalExpr('var a = { f: "ok" }; a?.f;'));
        Assert.isNull(evalExpr('var a = null; a?.f;'));
    }
}

class TestHScriptOOP
{
	public function new() {}
}