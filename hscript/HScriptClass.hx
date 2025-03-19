package hscript;

import hscript.Expr;
import hscript.SuperInterp;

@:allow(SuperInterp)
@:allow(AbstractHScriptClass)
class HScriptClass
{
	private var _isStatic:Bool = true;
	private var _interp:SuperInterp;
	private var _classDecl:ClassDecl;

	private var superClass:Dynamic = null;
	private var superConstructor:Dynamic = null;

	private var superInstance:Dynamic = null;

	private var variables:Map<String, Dynamic>;
	private var fieldSolvers:Map<String, {get:Null<Void->Dynamic>, set:Null<Dynamic->Dynamic>}>;

	public function new(decl:ClassDecl, superClass:Dynamic, interp:SuperInterp, ?isStatic:Bool = true)
	{
		this._classDecl = decl;
		this.superClass = superClass;
		this._interp = interp;
		this.variables = new Map();
		this.fieldSolvers = new Map();
		this._isStatic = isStatic;

		buildFields();

		if (!_isStatic)
		{
			this.superConstructor = Reflect.makeVarArgs(function(args:Array<Dynamic>)
			{
				var c = Type.createInstance(superClass, args);
				superInstance = c;
				return c;
			});
		}
	}

	private function buildFields()
	{
		@:privateAccess
		for (field in _classDecl.fields)
		{
			if (field == null)
				continue;

			if (field.access.contains(AStatic) != _isStatic) continue;

			var oldProxy = _interp._proxy;
			_interp._proxy = this;
			switch(field.kind)
			{
				case KVar(v):
					variables.set(field.name, _interp.expr(v.expr));
				case KFunction(f):
					var fn = function(args:Array<Dynamic>)
					{
						var oldProxy = _interp._proxy;
						_interp._proxy = this;

						var old = _interp.declared.length;

						for (i in 0...f.args.length)
						{
							var n = f.args[i].name;
							var e = args[i];

							if (e == null && f.args[i].value != null) 
								e = _interp.expr(f.args[i].value);

							_interp.declared.push({ n : n, old : _interp.locals.get(n) });
							_interp.locals.set(n,{ r : (e == null)?null:e });
						}

						var _ret = _interp.exprReturn(f.expr);
						_interp.restore(old);

						_interp._proxy = oldProxy;
						return _ret;
					}
					variables.set(field.name, Reflect.makeVarArgs(fn));
			}
			_interp._proxy = oldProxy;
		}
	}
}