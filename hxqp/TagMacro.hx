package hxqp;

#if macro

import haxe.macro.Expr;
import haxe.macro.Context;
import haxe.macro.Printer;

class TagMacro 
{
	static function addTagFunction(a:Field,b:Function):Field
	{
		if(a.access.filter(function(a:Access):Bool
		{
			switch(a)
			{
				default: return false;
				case AStatic: return true; // skip static func
			}
		}).length>0) return null;
		if(MyMacro.ftype(b)=="Tag") return makeTagFun(a,b);
		return null;
	}
	static function makeTagFun(a:Field,b:Function):Field
	{        
		var pos = Context.makePosition({file:"makeTagFun",min:1,max:2});
		var f = 
		{
			name:"_"+a.name // __tag, _tag_(return parent_)
			,access:a.access //[APublic]
			,kind:FFun
			({
				args : b.args
				,params : b.params //[]
				,ret : TPath({name:"Tag",pack:[],params:[]})
				,expr :
					//Context.parse(MyMacro.Util.sprintf("{parent_.%1(%2);return this;}"
					Context.parse(MyMacro.Util.sprintf("{return parent_.%1(%2);}"
						,a.name
						,b.args.map(function(a:FunctionArg){return a.name;}).join(","))
				,pos)
			})
			,pos:a.pos
			,doc:a.doc
		};
		//trace("make "+f.name);
		return f;
	}
	static public function remakeFunction(a:Field,b:Function):Field
	{
		if(b.ret!=null) switch(b.ret)
		{
			default:
			case TPath(ret):
				if(a.access.filter(function(a:Access):Bool
				{
					switch(a)
					{
						default: return false;
						case AStatic: return true; // skip static func
					}
				}).length>0) return null;
				if(ret.name=="Tag") return makeTagFun(a,b);
		}
		return null;
	}
	public static function remake():Array<Field> 
	{
		var newFields = new Array<Field>();
		for (field in Context.getBuildFields())
		{ 
			switch(field.kind)
			{                        
				default:                
					newFields.push(field);
				case FFun(kind):
					newFields.push(field);
					var f = remakeFunction(field,kind); 
					if(f!=null) newFields.push(f);
			}
		}
	  return newFields;
	}    
}

#end
