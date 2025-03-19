package hscript;

import haxe.Exception;
import hscript.SuperInterp;
import hscript.HScriptClass;

/**
	AbstractHScriptClass can be interpreted as a wrapper for the HScriptClass.
	It allows easy comunication with hscript classes, as well as provides some useful functions.

	To get or set a field from the hscript class, simply use the field access ``(a.b)`` operator or
	the array access ``(a[b])`` operator to resolve the field, both work exactly the same.

	``createInstance(...args)`` and ``createEmptyInstance()`` create an instanced object of the static class,
	these, however, cannot be called on already instanced objects, throwing an exception.
**/
@:allow(SuperInterp)
@:forward(superInstance)
@:forward(superConstructor)
@:forward(variables)
abstract AbstractHScriptClass(HScriptClass) from HScriptClass
{
	public function createInstance(...args:Dynamic):HScriptClass
	{
		@:privateAccess
		{
			if (!this._isStatic)
				throw "Cannot create class instance on a class instance";
	
			var inst:AbstractHScriptClass = createEmptyInstance();
			inst["new"](args[0], args[1], args[2], args[3], args[4], args[5], args[6], args[7], args[8], args[9]); // "error: Binding new is only allowed on class types", this is why i had to include the @:arrayAccess meta
			return cast(inst, HScriptClass);
		}
	}

	public function createEmptyInstance():HScriptClass
	{
		@:privateAccess
		{
			if (!this._isStatic)
				throw "Cannot create class instance on a class instance";
	
			var inst = new HScriptClass(this._classDecl, this.superClass, this._interp, false);
			return inst;
		}
	}

	private function resolve(name:String):Dynamic
		return solveGet(name)();

	private function assign(name:String, value:Dynamic)
		return solveSet(name)(value);



	// TODO: Make solvers search for fields in the super instance on instance classes
	private function solveGet(name:String):Void->Dynamic
	@:privateAccess
	{
		switch(name)
		{
			case "superClass":
				return () -> this.superClass;
			case "superInstance" | "super":
				return () -> this.superInstance;
			case "superConstructor":
				return () -> this.superConstructor;
			case "_classDecl":
				return () -> this._classDecl;
			case "_interp":
				return () -> this._interp;
			case "_variables":
				return () -> this.variables;
			case _:
		}

		if (this.variables.exists(name))
		{
			if (this.fieldSolvers.exists(name))
				if (this.fieldSolvers[name].get != null)
					return () -> this.fieldSolvers[name].get();

			return () -> this.variables.get(name);
		}

		if (this.superInstance != null)
		{
			if (this.superInstance is HScriptClass)
			{
				var inst:AbstractHScriptClass = cast(this.superInstance, AbstractHScriptClass);
				if (inst.has(name))
					return () -> inst.read(name);
			}
			else
			{
				var inst:Dynamic = this.superInstance;

				// FIXME: Add support for rest arguments. Maybe try adding a Reflect.makeVarAgrs() here?
				if (Reflect.isFunction(Reflect.getProperty(inst, name)))
					return () -> Reflect.getProperty(inst, name);

				if (Reflect.hasField(inst, name))
					return () -> Reflect.field(inst, name);

				if (Type.getInstanceFields(Type.getClass(inst)).contains(name))
					return () -> Reflect.field(inst, name);

			}
		}

		// this should never happen, and if it does, something went horribly wrong
		for (field in this._classDecl.fields)
		{
			if (field.name != name) continue;
			if (field.access.contains(AStatic) != this._isStatic) continue;

			trace('warning: ${this._isStatic ? "static" : ""} hscript class is trying to access a $name field from the interpreter, this should not happen!');

			switch(field.kind)
			{
				case KVar(v):
					return function()
					{
						var oldProxy = this._interp._proxy;
						this._interp._proxy = this;
						var _res = this._interp.expr(v.expr);
						this._interp._proxy = oldProxy;
						//this._interp._proxy = null;
						return _res;
					}
				case KFunction(f):
					return function()
					{
						var oldProxy = this._interp._proxy;
						this._interp._proxy = this;
						var _res = this._interp.expr(f.expr);
						this._interp._proxy = oldProxy;
						//this._interp._proxy = null;
						return _res;
					}
			}
		}

		if (this._isStatic)
			throw new Exception('Class<${this._classDecl.name}>(HScript) has no field $name');
		else
			throw new Exception('${this._classDecl.name}(HScript) has no field $name');

		return () -> null; // present to prevent issues and potential errors with macros
	}

	private function solveSet(name:String):Dynamic->Void
	@:privateAccess
	{
		if (this.fieldSolvers.exists(name))
			if (this.fieldSolvers[name].set != null)
				return (value:Dynamic) -> this.fieldSolvers[name].set(value);

		if (this.superInstance != null)
		{
			if (this.superInstance is HScriptClass)
			{
				var inst:AbstractHScriptClass = cast(this.superInstance, AbstractHScriptClass);
				if (inst.has(name))
					return (value:Dynamic) -> inst.write(name, value);
			}
			else
			{
				var inst:Dynamic = this.superInstance;
	
				if (Reflect.isFunction(Reflect.getProperty(inst, name)))
					return (value:Dynamic) -> Reflect.setProperty(inst, name, value);
	
				if (Reflect.hasField(inst, name))
					return (value:Dynamic) -> Reflect.setProperty(inst, name, value);
	
				if (Type.getInstanceFields(Type.getClass(inst)).contains(name))
					return (value:Dynamic) -> Reflect.setProperty(inst, name, value);
			}
		}

		var has:Bool = false;
	
		for (field in this._classDecl.fields)
		{
			if (field.name != name) continue;
			if (field.access.contains(AStatic) != this._isStatic) continue;
	
			has = true;
			break;
		}
	
		if (!has)
			if (this._isStatic)
				throw new Exception('Class<${this._classDecl.name}>(HScript) has no field $name');
			else
				throw new Exception('${this._classDecl.name}(HScript) has no field $name');
	
		return (value:Dynamic) -> this.variables.set(name, value);
	}

	public function has(name:String):Bool
	{
		@:privateAccess
		{
			if (this.variables.exists(name))
				return true;

			if (this.superInstance != null)
			{
				if (this.superInstance is HScriptClass)
				{
					var inst:AbstractHScriptClass = cast(this.superInstance, AbstractHScriptClass);
					if (inst.has(name))
						return true;
				}
				else
				{
					var inst:Dynamic = this.superInstance;
		
					// FIXME: Add support for rest arguments. Maybe try adding a Reflect.makeVarAgrs() here?
					if (Reflect.isFunction(Reflect.getProperty(inst, name)))
						return true;
		
					if (Reflect.hasField(inst, name))
						return true;
		
					if (Type.getInstanceFields(Type.getClass(inst)).contains(name))
						return true;
		
				}
			}
	
			for (field in this._classDecl.fields)
			{
				if (field.name != name) continue;
				if (field.access.contains(AStatic) != this._isStatic) continue;
		
				return true;
			}
	
			return false;
		}
	}
	
	
	@:op(a.b)
	private function fieldRead(name:String):Dynamic
		return resolve(name);
		
	@:op(a.b)
	private function fieldWrite(name:String, value:Dynamic)
		return assign(name, value);

	@:arrayAccess
	public function read(name:String):Dynamic
		return resolve(name);

	@:arrayAccess
	public function write(name:String, value:Dynamic)
		return assign(name, value);
}