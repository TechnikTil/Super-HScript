package hscript;

import haxe.ds.Either;
import hscript.Parser;

class ReParser extends Parser
{
	public function new()
	{
		super();
		allowJSON = false;
		allowTypes = true;
		allowMetadata = true;

		if (opChars.indexOf("?") < 0)
			opChars += "?";

		var priorities = [
			["%"],
			["*", "/"],
			["+", "-"],
			["<<", ">>", ">>>"],
			["|", "&", "^"],
			["==", "!=", ">", "<", ">=", "<="],
			["..."],
			["&&"],
			["||"],
			["??"],
			["=","+=","-=","*=","/=","%=","<<=",">>=",">>>=","|=","&=","^=","=>","??="],
			["->"]
		];
		opPriority = new Map();
		opRightAssoc = new Map();
		for( i in 0...priorities.length )
			for( x in priorities[i] ) {
				opPriority.set(x, i);
				if( i == 9 ) opRightAssoc.set(x, true);
			}
		for( x in ["!", "++", "--", "~"] ) // unary "-" handled in parser directly!
			opPriority.set(x, x == "++" || x == "--" ? -1 : -2);
	}
	
	override function initParser(origin:String, pos:Int)
	{
		line = 1;
		super.initParser(origin, pos);
	}

	
	#if hscriptPos
	override function _token():Token
	#else
	override function token():Token
	#end
	{
		#if !hscriptPos
		if( !tokens.isEmpty() )
			return tokens.pop();
		#end

		var initialCharPos:Int = readPos;

		var char;
		if( this.char < 0 )
		{
			char = readChar();
		}
		else {
			char = this.char;
			this.char = -1;
		}
		while( true ) {
			if( StringTools.isEof(char) ) {
				this.char = char;
				return TEof;
			}
			switch( char )
			{
				case 0:
					return TEof;
				case 32,9,13: // space, tab, CR
					#if hscriptPos
					tokenMin++;
					#end
				case 10: line++; // LF
					#if hscriptPos
					tokenMin++;
					#end
				case "'".code:
					return TApostr;
				case '"'.code:
					return TConst( CString(readString(char)) );
				case "?".code:
					char = readChar();
					switch(char)
					{
						case "?".code:
							char = readChar();
							if (char == "=".code)
								return TOp("??=");

							this.char = char;
							return TOp("??");
						case ".".code:
							return TQuestionDot;
					}
					
					this.char = char;
					return TQuestion;
				default:

					this.char = char;
					#if hscriptPos
					return super._token();
					#else
					return super.token();
					#end
			}
			char = readChar();
		}

		#if hscriptPos
		return super._token();
		#else
		return super.token();
		#end
	}

	override function parseExpr():Null<Expr>
	{
		var tk = token();
		switch(tk)
		{
			case TApostr:
				return parseExprNext(parseInterpolatedString());
			case _:
		}
		push(tk);
		return super.parseExpr();
	}

	function parseInterpolatedString():Expr
	{
		var c = 0;
		var esc = false;
		var d = false;
		var old = line;
		var s = input;
		var e = mk(EConst(CString("")));
		var parts:Array<Dynamic> = [];
		var curI:Int = 0;

		#if hscriptPos
		var p1 = currentPos - 1;
		#end

		while( true ) {
			if (this.char < 0)
				c = readChar();
			else
			{
				c = this.char;
				this.char = -1;
			}
	
			if( StringTools.isEof(c) ) {
				line = old;
				error(EUnterminatedString, p1, p1);
				break;
			}
			if( esc ) {
				esc = false;
				switch( c ) {
				case 'n'.code:
					parts[curI] += '\n'.code;
				case 'r'.code:
					parts[curI] += '\r'.code;
				case 't'.code:
					parts[curI] += '\t'.code;
				case "'".code, '"'.code, '\\'.code:
					parts[curI] += c;
				case '/'.code: if( allowJSON ) 
					parts[curI] += c; else invalidChar(c);
				case "u".code:
					if( !allowJSON ) invalidChar(c);
					var k = 0;
					for( i in 0...4 ) {
						k <<= 4;
						var char = readChar();
						switch( char ) {
						case 48,49,50,51,52,53,54,55,56,57: // 0-9
							k += char - 48;
						case 65,66,67,68,69,70: // A-F
							k += char - 55;
						case 97,98,99,100,101,102: // a-f
							k += char - 87;
						default:
							if( StringTools.isEof(char) ) {
								line = old;
								error(EUnterminatedString, p1, p1);
							}
							invalidChar(char);
						}
					}
					parts[curI] += String.fromCharCode(k);
				default: invalidChar(c);
				}
			} else if( c == 92 )
				esc = true;
			else if( c == "'".code )
				break;
			else if (c == '$'.code && !d)
				{
					var c = readChar();
					this.char = c;
					if (c == '$'.code)
						d = true;
					else
						switch (token())
						{
							case TBrOpen:
								curI = parts.push(parseExpr());
								ensure(TBrClose);
							case TId(s):
								curI = parts.push(mk(EIdent(s)));
							case TApostr:
								parts[curI] += String.fromCharCode(c);
								this.char = "'".code;
							default:
						}
				}
				else
				{
					if (c == 10) line++;
		
					parts[curI] ??= "";
					parts[curI] += String.fromCharCode(c);
				}
		}
	
		curI = 0;
		while (parts.length > curI)
		{
			var part:Dynamic = parts[curI++];
			if (part is String)
				part = mk(EConst(CString(cast part)));
			else
				switch (Tools.expr(part))
				{
					case EConst(c):
					default:
						part = mk(EParent(part));
				}
	
			if (e == null)
				e = part;
			else
				e = makeBinop('+', e, part);
		}
		return e;
	}
}