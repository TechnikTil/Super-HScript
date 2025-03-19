package hscript;

class ReInterp extends Interp
{
	override function initOps()
	{
		super.initOps();
		var me = this;
		binops.set("??",function(e1,e2) return me.expr(e1) ?? me.expr(e2));
		assignOp("??=",function(v1,v2) return v1 ?? v2);
	}
	override function expr(e:Expr):Dynamic
	{
		if (e == null)
			return null;
		return super.expr(e);
	}
}