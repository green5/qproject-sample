package hxqp;

#if macro

import haxe.macro.Expr;
import haxe.macro.Context;
import haxe.macro.Printer;
import haxe.macro.Compiler;
import haxe.macro.Type;
import haxe.macro.TypeTools;
import sys.FileSystem;

class MyMacro 
{
	public var log_:Int = 0;
	public static var trace_:Dynamic->?haxe.PosInfos->Void = haxe.Log.trace;
	public static function xtrace(x:Dynamic,?i:haxe.PosInfos)
	{
		var t="";
		try { t = untyped Type.getClass(x).__name__; } catch(x:Dynamic) {}
		trace_(t+x,i);
	  //haxe.Log.trace = MyMacro.xtrace;
	}
	function escapeExpr(e:Expr):Expr
	{
		return { 
			expr:EUntyped( 
			{ 
				expr:ECall( 
					{ expr:EConst(CIdent(escapeFunc_)), pos:e.pos }
					,[ { expr:EConst(CString(print_.printExpr(e))),pos:e.pos } ]
				) 
				,pos:e.pos
			})
			,pos:e.pos
		};
	}
	function addEscapeFunction(a:Field,b:Function):Field
	{
		var e:Expr = b.expr;
		if(ftype(b)=="Void")
		{
			e = escapeExpr(e);
		}
		else 
		{
			var ret = Context.parse(Util.sprintf("return null",escapeFunc_),e.pos);
			switch(e.expr)
			{
				default: 
					e = { expr:EBlock([escapeExpr(e),ret]), pos:e.pos };
				case EBlock(exprs): 
					if(1==1) 
					{
						for(i in 0...exprs.length) exprs[i] = escapeExpr(exprs[i]);				
						exprs.push(ret);
					}
					else
					{
						e = { expr:EBlock([escapeExpr(e),ret]), pos:e.pos };
					}
			}
		}
		var f = 
		{
			name:a.name 
			,access:a.access 
			,kind:FFun
			({
				args : b.args
				,params : b.params 
				,ret : b.ret
				,expr : e
			})
			,pos:a.pos
			,doc:a.doc
		};
		//trace(print_.printExpr(b.expr));
		trace(print_.printExpr(e));
		return f;
	}
	static public function ftype(b:Function)
	{
		if(b.ret==null) return "Void";
		return switch(b.ret)
		{
			default: 
				"some";
			case TPath(ret):
				return ret.name;
		}
	}
	function toComplexTypes(a:Array<Type>):Array<ComplexType>
	{
		var ret = new Array<ComplexType>();
		for(i in a) ret.push(TypeTools.toComplexType(i));
		return ret;
	}
	function makeTFun(field:Field
		,classtype
		,isStatic:Bool
		,f:haxe.macro.Type.ClassField
		,arg:Array<{name:String,opt:Bool,t:Type}>
		,ret:Type):Field
	{
		//now tested intefaces. class? @import(?regex), ?static
		var str = "{if(%1==null) throw 'TFun:%1.%2 is null';return %1.%2(%3);}";
		var fname = field.name;
		if(isStatic)
		{
			str = "{return %1.%2(%3);}";
			fname = classtype.module;
		}
		var fi = 
		{
			name:f.name
			,access:[AInline].concat(field.access)
			,kind:FFun
			({
				args : arg.map(function(a){return untyped{name:a.name,opt:a.opt,type:TypeTools.toComplexType(a.t)};})
				,ret : TypeTools.toComplexType(ret)
				,expr : Context.parse(Util.sprintf(str
						,fname,f.name,arg.map(function(a){return a.name;}).join(",")	
					),field.pos)
				,params : []
			})
			,pos:field.pos
		};
		if(log_>0) trace(print_.printField(fi));
		return fi;
	}
	function doVarFun(field,classtype,isStatic,f,type:Type)
	{
		switch(type)
		{
		default:
		case TLazy(ft):
			doVarFun(field,classtype,isStatic,f,ft());
		case TFun(arg,ret):
			newFields_.push(makeTFun(field,classtype,isStatic,f,arg,ret));
		}
	}
	function doVar(field:Field,t:Null<ComplexType>,?e:Null<Expr>)
	{
		if(field.name=="this_") 
		{
			return;
		}
		var m = mymeta(field,vMetaFixs_);
		if(m.length==1 && m[0]=="import")
		{
			var s = print_.printComplexType(t).split("<")[0];
			var type:Type = Context.getType(s);
			var classtype:haxe.macro.Type.ClassType =  haxe.macro.TypeTools.getClass(type);
			for(f in classtype.statics.get()) 
			{
				//var x:haxe.macro.Type.ClassField = f;
				if(!f.isPublic) continue;
				if(isField(f.name))
				{
					Context.warning("skip static field "+f.name,field.pos);
					continue;
				}
				doVarFun(field,classtype,true,f,f.type);
			}
			var fields = classtype.fields.get();
			if(fields.length==0)
			{
				//Context.warning("drop "+Context.getLocalClass()+"."+field.name+", because "+s+" methods are static",field.pos);
				return;
			}
			for(f in fields) 
			{
				if(!f.isPublic) continue;
				if(isField(f.name))
				{
					Context.warning("skip field "+f.name,field.pos);
					continue;
				}
				doVarFun(field,classtype,false,f,f.type);
			}
		}
		newFields_.push(field);
	}
	function doFun(field:Field,b:Function)
	{
 		//if(target_=="js") field=addEscapeFunction(field,b); // does not make sense, lex inveigh
		newFields_.push(field);
	}
	function isField(name:String):Bool
	{
		if(oldFields_.filter(function(f){return f.name==name;}).length>0) return true;
		if(newFields_.filter(function(f){return f.name==name;}).length>0) return true;
		return false;
	}
	var newFields_:Array<Field>;
	var oldFields_:Array<Field>;
	var classPlatform_:String;
	inline function dotrace(field:Field, ?infos : haxe.PosInfos)
	{
		var type:Null<ComplexType>;
		switch(field.kind)
		{                        
			case FProp(get,set,t,e):                
				type = t;
				case FVar(t,e):
				type = t;
			case FFun(f):
	  		type = f.ret;
		}
		trace(infos.fileName+"."+infos.lineNumber+": "
		+ (field.meta.map(print_.printMetadata).join(" ")+(field.meta.length>0?" ":""))
		+ (field.access.map(print_.printAccess).join(" ")+(field.access.length>0?" ":""))
		+ Context.getLocalClass() + "." + field.name
		+ (type==null?"":":"+print_.printComplexType(type))
		+ (field.doc==null?"":(" /**"+field.doc+"**/"))
		);
	}	
	function dobuild()
	{
	  haxe.Log.trace = MyMacro.xtrace;
		newFields_ = new Array<Field>();
		oldFields_ = Context.getBuildFields();
		for(field in oldFields_)
		{ 
			var m = mymeta(field,pMetaFixs_);
			if(m.length>=2) Context.error("too many @"+m,field.pos);
			if(m.length==0) m.push(classPlatform_); // no @js generate for phpClass
			var g = m[0]=="any" || m[0]==target_;
			if(!g)
			{
				if(log_>1) trace("drop "+field.name+" "+[target_,classPlatform_,m[0]].join(";"));
				continue;
			}
			switch(field.kind)
			{                        
				case FProp(get,set,t,e):                
					newFields_.push(field);
				case FVar(t,e):
					doVar(field,t,e);
				case FFun(f):
		  		doFun(field,f);
			}
		}
		if(log_>1) for(field in newFields_) trace(print_.printField(field));
		return this;
	}
	function mymeta(field:Field,metaFixs:Array<String>):Array<String>
	{
		var x = new Array<String>();
		if(field.meta != null) for(m in field.meta) for(i in metaFixs) if(m.name==i)
		{
			x.push(i);
		}
		return x;
	}
  var pMetaFixs_:Array<String>; // metaFixs=php,js: look only @php,@js metas
  var vMetaFixs_:Array<String>; 
	var print_:Printer;
	var escapeFunc_:String;
	var target_:String; // current haxe target
	function new(log:Int,classPlatform:String)
	{
		log_ = log;
		classPlatform_ = classPlatform;
		//trace(classPlatform+" "+Context.getLocalClass());
		pMetaFixs_="php,js,any".split(",");
		vMetaFixs_="import".split(","); //?export
		if(Context.defined("php")) target_="php";
		else if(Context.defined("js")) target_="js";
		else Context.error("can't determine platform",Context.currentPos());
		if(target_=="js") escapeFunc_ = "__js__";
		if(target_=="php") escapeFunc_ = "__php__";
		if(escapeFunc_==null) Context.error("unknown platform "+target_,Context.currentPos());		
		print_ = new haxe.macro.Printer("");
	}
	static function build(?classPlatform:String="any",?log:Int=0):Array<Field> 
	{		
		return new MyMacro(log,classPlatform).dobuild().newFields_;
	}    
	static public function phpClass(?log:Int=0):Array<Field> 
	{
		return build("php",log);
	}
	static public function jsClass(?log:Int=0):Array<Field> 
	{
		return build("js",log);
	}
	static macro public function str(a:Expr,q:Int=0):Expr
	{
		var s = new Printer("").printExpr(a);
		//if(q==1) s = "'"+StringTools.replace(s,"'","\\'") +"'";		
		//if(q==2) s = '"'+StringTools.replace(s,'"','\\"') +'"';
		return { expr: EConst(CString(s)), pos: Context.currentPos() };
	}
	public static function lineno(str:String=null):Expr
	{
		var pos:Position = Context.currentPos();
		var where:String = ("" + pos).split(" ")[0].split("(")[1];
		if(str!=null) where += " " + str;
		//return {expr:EConst(CString(where)), pos:pos};
		return macro 1;
	}    
	static public function include(path:String):haxe.macro.Expr
	{
		if(1==1||!sys.FileSystem.exists(path)) Context.error(path+": not exists",Context.currentPos());
		return macro {};
	}
}

class Util
{
	static public function sprintf(fmt:String
	  ,?a1:String=null
	  ,?a2:String=null
	  ,?a3:String=null
	  ,?a4:String=null
	  ,?a5:String=null
	  ,?a6:String=null
	  ,?a7:String=null
	  ,?a8:String=null
	  ,?a9:String=null
	)
	{
	  var t = fmt;
		if(a1!=null) t=StringTools.replace(t,"%1",a1);
		if(a2!=null) t=StringTools.replace(t,"%2",a2);
		if(a3!=null) t=StringTools.replace(t,"%3",a3);
		if(a4!=null) t=StringTools.replace(t,"%4",a4);
		if(a5!=null) t=StringTools.replace(t,"%5",a5);
		if(a6!=null) t=StringTools.replace(t,"%6",a6);
		if(a7!=null) t=StringTools.replace(t,"%7",a7);
		if(a8!=null) t=StringTools.replace(t,"%8",a8);
		if(a9!=null) t=StringTools.replace(t,"%9",a9);
	  return t;
	}
}

#else

// You cannot use @:build inside a macro 

//@:build(hxqp.MyMacro.build())
class MyMacro 
{
	public static macro function lineno():String; 
	static macro public function str(a):String;
}

#end
