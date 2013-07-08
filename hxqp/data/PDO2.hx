package hxqp.data;

import php.db.PDO;
import sys.db.Connection;

@:build(hxqp.MyMacro.build())
class PDO2 implements Data implements Dynamic<Data> implements sys.db.Connection
{
  static public inline var FETCH_OBJ = 5;
  static public inline var FETCH_ASSOC = 2;
  static public inline var FETCH_BOTH = 4;
  static public inline var FETCH_BOUND = 6;
  static public inline var FETCH_CLASS = 8;
  static public inline var FETCH_INTO = 9;
  static public inline var FETCH_LAZY = 1;
  static public inline var FETCH_NUM = 3;
	static public function styles():Array<Int>
	{
		return [FETCH_ASSOC,FETCH_BOTH,FETCH_NUM];
	}
  @import public var cnx:sys.db.Connection;
  var pdo:PDOClass;
	public function connection() { return cnx; }
  public function new(dsn:String=haxe.macro.Compiler.getDefine("LOCALDB")
		,?user:String,?password:String,?options:Dynamic)
  {
    cnx = PDO.open(dsn,user,password,options);
		pdo = Reflect.field(cnx,"pdo"); 
		pdo.setAttribute(3,2); // PDO::ERRMODE_EXCEPTION
		//sys.db.Manager.cnx = cnx;
  }
  public function x0(sql:String, arg:Array<Dynamic>=null, style=-1):Dynamic
  {
    return nexecute(sql,arg,style,0);
  }
  public function x1(sql:String, arg:Array<Dynamic>=null, style=-1):Dynamic 
  {
    return nexecute(sql,arg,style,1);
  }
  public function query(sql:String, arg:Array<Dynamic>=null, style=-1, nrow:Int=-1):Dynamic 
  {
    return nexecute(sql,arg,style,nrow);
  }
	function error():String
	{
		return pdo.errorInfo()[2];
	}
	public static function pdoType(a:Dynamic):Int
	{
		var t = XLib._typeof(a);
		if(t=="string") return untyped __php__("PDO::PARAM_STR");
		if(t=="integr") return untyped __php__("PDO::PARAM_INT");
		return untyped __php__("PDO::PARAM_STR");
	}
  private function nexecute(sql:String, arg:Array<Dynamic>, style, nrow:Int):Array<Dynamic>
	{
		var ret = new Array<Dynamic>();
		if(style==-1) style = FETCH_ASSOC;
		try
		{
			var stm:PDOStatement = pdo.prepare(sql,untyped __php__("array()"));
			if(stm==null) throw MyMacro.lineno()+" "+error();
			if(arg!=null)
			{
				untyped arg = arg.a;
				if(sql.indexOf(":1")>0) stm.bindParam(":1",arg[0],pdoType(arg[0]));
				if(sql.indexOf(":2")>0) stm.bindParam(":2",arg[1],pdoType(arg[1]));
				if(sql.indexOf(":3")>0) stm.bindParam(":3",arg[2],pdoType(arg[2]));
				if(sql.indexOf(":4")>0) stm.bindParam(":4",arg[3],pdoType(arg[3]));
				if(sql.indexOf(":5")>0) stm.bindParam(":5",arg[4],pdoType(arg[4]));
				if(sql.indexOf(":6")>0) stm.bindParam(":6",arg[5],pdoType(arg[5]));
				if(sql.indexOf(":7")>0) stm.bindParam(":7",arg[6],pdoType(arg[6]));
				if(sql.indexOf(":8")>0) stm.bindParam(":8",arg[7],pdoType(arg[7]));
				if(sql.indexOf(":9")>0) stm.bindParam(":9",arg[8],pdoType(arg[8]));
				if(untyped __physeq__(stm, false)) throw MyMacro.lineno()+" "+error();
			}
    	var ret:Dynamic = stm.execute(untyped __php__("array()"));
			if(untyped __physeq__(ret, false)) throw MyMacro.lineno()+" "+error();
			if(nrow==-1) 
			{
				// use fetchAll?, pdo use do_fetch for fetch,fetchAll
				ret = stm.fetchAll(FETCH_NUM);
				if(untyped __physeq__(ret, false)) throw MyMacro.lineno()+" "+error();
				if(XLib.x1("is_array",ret)) ret=php.Lib.toHaxeArray(ret);
				return ret; /// what return type?
			}
			ret = [];
			while(true)
			{
				var row:Dynamic = stm.fetch(style);
				if(untyped __physeq__(row, false)) break; 
				if(style!=FETCH_NUM) row = XLib.x1("_hx_anonymous",row);
				ret.push(row);
			}
			return ret;
		}
		catch(e:Dynamic)
		{
			throw e;
			//if(ret.length==0) throw e;
			//return ret;
		}
	}
}
