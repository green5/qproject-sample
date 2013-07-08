package hxqp;

interface Data implements Dynamic<Data>
{
  public function query(req:String, arg:Array<Dynamic>=null, style:Int=-1, nrow:Int=-1):Dynamic; //List|Array 
	public function connection():sys.db.Connection;
}

@:multiType
abstract Sql(Data) from Data
{
	public static function pdo(db:String)
	{
		return new hxqp.data.PDO2(db); /// ?delete pdo2, fetch style
	}
	public static function sdb(db:String)
	{
		return new hxqp.data.SysDB(db);
	}
}
