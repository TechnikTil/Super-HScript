package hscript;

import hscript.macros.PreprocessorMacro;
import hscript.Expr.ModuleDecl;

class SuperParser extends ReParser
{
	private static var _preprocessorDefinitions:Map<String, String> = PreprocessorMacro.getPreprocessorValues();
	public function new() {super(); this.preprocesorValues = _preprocessorDefinitions;}

	override function parseStructure(id:String):Null<Expr> {
		switch(id)
		{
			case "import":
				var path = parsePath();
				return null;
			case "package":
				if (maybe(TSemicolon))
					return null;
				var path = parsePath();
				return null;
			case "class":
				var name = getIdent();
				var params = parseParams();
				var extend = null;
				var implement = [];

				while( true ) {
					var t = token();
					switch( t ) {
					case TId("extends"):
						extend = parseType();
					case TId("implements"):
						implement.push(parseType());
					default:
						push(t);
						break;
					}
				}

				var fields = [];
				ensure(TBrOpen);
				while( !maybe(TBrClose) )
					fields.push(parseField());

				//mk()
				return null;
		}
		return super.parseStructure(id);
	}

	override function parseModuleDecl() : ModuleDecl {
		var meta = parseMetadata();
		var ident = getIdent();
		var isPrivate = false, isExtern = false;
		while( true ) {
			switch( ident ) {
			case "private":
				isPrivate = true;
			case "extern":
				isExtern = true;
			default:
				break;
			}
			ident = getIdent();
		}
		switch( ident ) {
		case "package":
			var path = parsePath();
			ensure(TSemicolon);
			return DPackage(path);
		case "import":
			var path = [getIdent()];
			var star = false;
			while( true ) {
				var t = token();
				if( t != TDot ) {
					push(t);
					break;
				}
				t = token();
				switch( t ) {
				case TId(id):
					path.push(id);
				case TOp("*"):
					star = true;
				default:
					unexpected(t);
				}
			}
			ensure(TSemicolon);
			return DImport(path, star);
		case "class":
			var name = getIdent();
			var params = parseParams();
			var extend = null;
			var implement = [];

			while( true ) {
				var t = token();
				switch( t ) {
				case TId("extends"):
					extend = parseType();
				case TId("implements"):
					implement.push(parseType());
				default:
					push(t);
					break;
				}
			}

			var fields = [];
			ensure(TBrOpen);
			while( !maybe(TBrClose) )
				fields.push(parseField());

			return DClass({
				name : name,
				meta : meta,
				params : params,
				extend : extend,
				implement : implement,
				fields : fields,
				isPrivate : isPrivate,
				isExtern : isExtern,
			});
		case "typedef":
			var name = getIdent();
			var params = parseParams();
			ensureToken(TOp("="));
			var t = parseType();
			return DTypedef({
				name : name,
				meta : meta,
				params : params,
				isPrivate : isPrivate,
				t : t,
			});
		default:
			//unexpected(TId(ident));
		}
		return null;
	}

	override function parseExpr() {
		var tk = token();
		switch( tk ) {
		case TId(id):
			var e = parseStructure(id);
			if( e == null)
			{
				if (id == "package" || id == "class" || id == "import")
					return null;

				e = mk(EIdent(id));
			}

			return parseExprNext(e);
		case _:
		}

		push(tk);
		return super.parseExpr();
	}
}