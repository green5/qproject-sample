package hxqp.data;

import sys.db.Connection;
import sys.db.RecordInfos.RecordType;
import sys.db.ResultSet;
import php.db.PDO;

@:build(hxqp.MyMacro.build())
class SysDB implements Data implements Dynamic<Data> implements sys.db.Connection
{
	@import public var cnx:Connection;
	public function connection():Connection { return this; }
#if 0
	public function request( s : String ) : ResultSet
	{
		var t:ResultSet = cnx.request(s);
		return t;
	}
#end
  public function new(dsn:String=haxe.macro.Compiler.getDefine("LOCALDB")
		,?user:String,?password:String,?options:Dynamic)
  {
		var tt = dsn.split(":");
		var t1 = tt.shift();
		var t2 = tt.join(":");
		if(t1=="sys.sqlite") cnx = sys.db.Sqlite.open(t2); 
		else if(t1=="sys.mysql") cnx = sys.db.Mysql.connect({host:"localhost",user:user,pass:password,database:t2});
		else cnx = PDO.open(dsn,user,password,options); // sqlite:file
	}
  public function query(sql:String, arg:Array<Dynamic>=null, style=-1, nrow:Int=-1):Array<Dynamic> 
	{
		// you want List? use ResultSet
		var t:ResultSet = cnx.request(sql);
		var l:List<Dynamic> = t.results(); // HList serialize/unserialize
		var ret = [];
		for(i in l) ret.push(i);		
		return ret;
	}
}
