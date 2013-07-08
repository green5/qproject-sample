package hxqp;

@:build(hxqp.MyMacro.phpClass())
@:expose("hxqp.XLib") 
class XLib
{
	@js public static inline function _typeof(x:Dynamic):String
	{
		return (untyped __js__("typeof"))(x);
	}
	@php public static inline function _typeof(x:Dynamic):String untyped
	{
		var t:String = __call__("gettype",x);
		if(t=="object") t = __call__("get_class",x);
		return t;
	}	
	static public function aa(a:Array<Dynamic>=null):php.NativeArray
	{
		if(a==null) return XLib.x0("array");
		return untyped __field__(a, 'a'); // toPhpArray
	} 
	public static var trace_:Dynamic->?haxe.PosInfos->Void = haxe.Log.trace;
	public static function syslog(t:String)
	{
		untyped __php__("
		  openlog('X',1,128); 
			foreach(explode(\"\n\",$t) as $m) syslog(7, $m);
			closelog();
		");
	}
	public static function syserr(t:String)
	{
		untyped __php__("
		  global $ferr; 
			if($ferr==null) $ferr = fopen('php://stderr', 'w');
			fprintf($ferr, '%s\n', $t); 
		");
	}
	public static function xtrace(x:Dynamic,?i:haxe.PosInfos)
	{
	  var h:String = i == null ? "" : i.fileName + "." + i.lineNumber + ':';
	  h += _typeof(x) + "=>" + Type.getClass(x) + ':';
		1==0 && php.Lib.isCli() ? trace_(x,i) : syserr(h+x);
	}
	@js public static function xtrace(x:Dynamic,?i:haxe.PosInfos)
	{
	  var h:String = i == null ? "" : i.fileName + "." + i.lineNumber + ':';
	  h += _typeof(x) + "=>" + Type.getClass(x) + ':';
		untyped console.log(h+x);
	}
  static public var vcallException_:Bool = true;
	static public function xcheck(func:Dynamic):Bool
	{
		//xtrace("xcheck: "+func);
#if 1
		if(untyped __call__("is_callable",func)) return true;
		if(vcallException_) throw "uncallable: "+func;
		//trace("uncallable: "+func);
		return false;
#else
		return true;
#end
	}
#if 0
	static public inline function x0(func:Dynamic):Dynamic untyped {return xcheck(func)?__call__(func):false;}
	static public inline function x1(func:Dynamic,a1:Dynamic):Dynamic untyped {return xcheck(func)?__call__(func,a1):false;}
	static public inline function x2(func:Dynamic,a1:Dynamic,a2:Dynamic):Dynamic untyped {return xcheck(func)?__call__(func,a1,a2):false;}
	static public inline function x3(func:Dynamic,a1:Dynamic,a2:Dynamic,a3:Dynamic):Dynamic untyped {return xcheck(func)?__call__(func,a1,a2,a3):false;}
	static public inline function x4(func:Dynamic,a1:Dynamic,a2:Dynamic,a3:Dynamic,a4:Dynamic):Dynamic untyped {return xcheck(func)?__call__(func,a1,a2,a3,a4):false;}
	static public inline function x5(func:Dynamic,a1:Dynamic,a2:Dynamic,a3:Dynamic,a4:Dynamic,a5:Dynamic):Dynamic untyped {return xcheck(func)?__call__(func,a1,a2,a3,a4,a5):false;}
#else
	// not or inline badly generated, but kakto work
	static public inline function x0(func:Dynamic):Dynamic untyped {return __call__(func);}
	static public inline function x1(func:Dynamic,a1:Dynamic):Dynamic untyped {return __call__(func,a1);}
	static public inline function x2(func:Dynamic,a1:Dynamic,a2:Dynamic):Dynamic untyped {return __call__(func,a1,a2);}
	static public inline function x3(func:Dynamic,a1:Dynamic,a2:Dynamic,a3:Dynamic):Dynamic untyped {return __call__(func,a1,a2,a3);}
	static public inline function x4(func:Dynamic,a1:Dynamic,a2:Dynamic,a3:Dynamic,a4:Dynamic):Dynamic untyped {return __call__(func,a1,a2,a3,a4);}
	static public inline function x5(func:Dynamic,a1:Dynamic,a2:Dynamic,a3:Dynamic,a4:Dynamic,a5:Dynamic):Dynamic untyped {return __call__(func,a1,a2,a3,a4,a5);}
#end
	static public function vcall(func:Dynamic,arg:Array<Dynamic>):Dynamic 
	{
		/// problem with losing references
		if(xcheck(func)) return untyped __call__("call_user_func_array",func,arg.a);
		return false; // check result carefully
	}
	public static function ob_vcall(func:Dynamic,arg:Array<Dynamic>):String
	{
	  XLib.x0("ob_start");
		XLib.x1("ob_implicit_flush",false);
		vcall(func,arg);
	  return XLib.x0('ob_get_clean');
	}
	static public function printf(fmt:String,?Dynamic,?Dynamic,?Dynamic,?Dynamic,?Dynamic,?Dynamic,?Dynamic,?Dynamic,?Dynamic):Dynamic
	{
	  return untyped __php__("call_user_func_array('printf',func_get_args())");
	}
	static public function sprintf(fmt:String,?Dynamic,?Dynamic,?Dynamic,?Dynamic,?Dynamic,?Dynamic,?Dynamic,?Dynamic,?Dynamic):String
	{
	  return untyped __php__("call_user_func_array('sprintf',func_get_args())");
	}
	@js static public function sprintf(format:String
		,?Dynamic,?Dynamic,?Dynamic,?Dynamic,?Dynamic,?Dynamic,?Dynamic,?Dynamic,?Dynamic
	):String untyped 
	{
	  var arg = arguments;
		if(typeof(format)!="string") return sprintf("%o",arg);
	  var i = 1;
	  return format.replace(__js__("/%((%)|[soc])/g"),function(f,b1,b2) 
		{ 
	    if(b2) return b2;
			var a:Dynamic = arg[i++]; 
			var s:String = "" + a;
		  if(b1=='o') return str(a); 
		  if(b1=='c') return s.charAt(0); 
	  	return s;
	  });
	}
	static public function isget(z:Dynamic,o:Dynamic,prop:String=null):Dynamic
	{
		untyped __php__("
			if(is_string($o) && isset($GLOBALS[$o]))
			{
				$o = $GLOBALS[$o];
			}
			$arg = func_get_args();
			for($i=2;$i<count($arg) && $arg[$i];$i++)	
			{
				$n = $arg[$i];
		    if(is_object($o) && isset($o->$n)) $o=$o->$n;
		  	else if(is_array($o) && isset($o[$n])) $o=$o[$n];
				else { $o=$z; break; }
			}
		");
		return o;
	}
	public static inline function print(t:String):Void
	{
		untyped __call__("echo", ""+t);
	}
	@js public static function print(t:Dynamic):Void 
	{
		(untyped __js__("console.log"))(t);
	}
	@any public static inline function println(t:String):Void
	{
	  print(t+"\n");
	}
	public static function exit(ret:Int=0)
	{
	  XLib.x1("exit",ret);
	}
	@js public static function exit(ret:Int=0)
	{
		(untyped __js__("quit"))(ret);
	}
	public static function count(a:php.NativeArray):Int
	{
	  return XLib.x1("count",a);
	}
	public static function hx_object(a : Dynamic, recursive:Bool=false) : Dynamic
	{
		untyped __php__("
			if(is_array($a)) $o = new _hx_array($a);
			{
				$o = _hx_anonymous();
				foreach($a as $k => $x)
					$o->$k = is_array($x) ? hxqp_XLib::hx_object($x) : $x;
				return $o;
			}
			return (object)$a;
		");		
		return a;
	}
	static public function microtime(n=0):Float 
	{
		return XLib.x2("round",XLib.x1("microtime",true),n);
	}
	@any public static function extend(t:Dynamic,o:Dynamic):Dynamic
	{
		if(t==null) t={};
		if(o==null) o={};
		for(i in Reflect.fields(o)) Reflect.setField(t,i,Reflect.field(o,i));
		return t;
	}
	@any public static inline function q(s:String):String
	{
		return "'"+StringTools.replace(s,"'","\\'") +"'";		
	}
	@any public static inline function qq(s:String):String
	{
		return '"'+StringTools.replace(s,'"','\\"') +'"';		
	}
  @any public static function serialize(o:Dynamic,q:Int=0):String
	{
		var t = new haxe.Serializer();
		t.serialize(o);
    var s = t.toString();
		if(q==1) s=XLib.q(s);
		if(q==2) s=XLib.qq(s);
		return s;
	}
  @any public static function unserialize(s:String):Dynamic
	{
		return new haxe.Unserializer(s).unserialize();
	}
  public static function pserialize(o:Dynamic):String
	{
		var s:String = XLib.x1("json_encode",o);
		return s;
	}
  public static function punserialize(s:String):Dynamic
	{
		return XLib.x1("json_decode",s);
	}
#if debug
	@any private static function stackToString(b:StringBuf, s:haxe.CallStack.StackItem ) // from CallStack.hx
	{
		switch( s ) 
		{
		case CFunction:
			b.add("a C function");
		case Module(m):
			b.add("module ");
			b.add(m);
		case FilePos(s,file,line):
			if( s != null ) 
			{
				stackToString(b,s);
				b.add(" (");
			}
			b.add(file);
			b.add(" line ");
			b.add(line);
			if( s != null ) b.add(")");
		case Method(cname,meth):
			b.add(cname);
			b.add(".");
			b.add(meth);
		case Lambda(n):
			b.add("local function #");
			b.add(n);
		}
	}
	@any public static function callFrom(n:Int=1):String
	{
		var b = new StringBuf();
		var ss = haxe.CallStack.callStack();
		if(n==0) return haxe.CallStack.toString(ss);
		if(n<0) n=ss.length+n;
		if(n>0 && ss.length>0) stackToString(b,ss[n%ss.length]);
		return b.toString();
	}
#else
	private static function stackToString(b:StringBuf,s:Dynamic)
	{
		for(i in ["file","line","class","function","object","type"])
		{
			if(Reflect.field(s,i)) b.add(i+"="+Reflect.field(s,i)+";");
		}
	}
	public static function phpStack():Array<String>
	{
		var tt = new Array<String>();			
		untyped __php__("
		$ss = debug_backtrace();
		array_shift($ss);
		foreach($ss as $s) 
		{
			if(isset($s['file'])) $s['file'] = basename($s['file']);
			$t = array();
			foreach(array('file','line','function','class','_object','type','_args') as $k)
			{
				if(isset($s[$k])) $t[$k] = $s[$k];
			}
			$tt->push(_hx_anonymous($t));
		}
		");
		return tt;		
	}
	public static function callFrom(n:Int=2):String
	{
		var b = new StringBuf();
		var ss = XLib.phpStack();
		if(n<0) n=ss.length+n;
		if(n>=0 && ss.length>0) stackToString(b,ss[n%ss.length]);
		return b.toString();
	}
	@js public static function callFrom(n:Int=1):String
	{
		return ""; ///
	}
#end
	@js public static function ucfirst(m:String):String
	{
	  return m.substr(0,1).toUpperCase()+m.substr(1);
	}
	@php public static function ucfirst(m:String):String
	{
	  return XLib.x1("ucfirst",m);
	}
}

#if TEST
class XLibTest extends haxe.unit.TestCase
{
	public function testStack()
	{
		XLib.callFrom();
    assertEquals(1,1);
	}
}
#end

