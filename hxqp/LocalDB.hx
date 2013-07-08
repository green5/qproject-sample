package hxqp;

import sys.db.Types;
import sys.db.TableCreate;
import sys.db.Object;

/// SPOD macros and --php-prefix => ok

interface TObject 
{
	public function id():Int;
  //public static function model(manager):Array<TModel>;
}

@:build(hxqp.MyMacro.build(1))
class TGroup extends Object implements TObject 
{
	public function id() { return gid; }
	var gid:SId;
	public var name:SString<767>;
	public function new(name_:String)
	{
		super();
		name = name_;
	}
	public static function group(name_:String)
	{
		var t = manager.select($name == name_);
		if(t==null) (t=new TGroup(name_)).insert();
		return t;
	}
}

class TUser extends Object implements TObject 
{
	public function id() { return uid; }
	var uid:SId;
	public var name:SString<767>;
 	@:relation(gid) public var group:TGroup;

	public var age:Null<String>;
	public var company:Null<String>;
	public var phone:Null<String>;
	public var email:Null<String>;
	public var address:Null<String>;
	public var about:Null<String>;
	public var country:Null<String> = 'ru';

	public function new(name_:String,group_:String=null)
	{
		super();
		name = name_;
		group = TGroup.group(group_==null?name_:group_);
	}
	public static function user(name_:String,group_:String=null)
	{
		var t = manager.select($name == name_);
		if(t==null) (t=new TUser(name_,group_)).insert();
		return t;
	}
}

class TProject extends Object implements TObject 
{
	public function id() { return pid; }
	public static function ui(?t:TProject):Dynamic
	{
		if(t==null) return {pid:"Pid",name:"Проект",state:"State",group:"Group"};
		return {pid:t.pid,name:t.name,state:t.state,group:t.group.name};			
	}
	var pid:SId;
	public var name:SText; /** =>unique **/
	public var state:SText;
	@:relation(gid) public var group:TGroup;
	public function new(name_:String,group_:String=null)
	{
		super();
		name = name_;
		state = "start";
		group = TGroup.group(group_==null?name_:group_);		
	}
	public static function project(name_:String,group_:String=null)
	{
		var t = manager.select($name == name_);
		if(t==null) (t=new TProject(name_,group_)).insert();
		return t;
	}
}

//?@:id(pid,uid)
class TLink extends Object implements TObject 
{
	public function id() { return lid; }
	public static function ui(?t:TLink):Dynamic
	{
		if(t==null) return {lid:"Id",user:"User",project:"Проект",state:"State",time:"Created"};
		return {lid:t.lid,user:t.user.name,project:t.project.name,state:"unknown",time:""+Date.fromTime(t.ltime*1000)};			
	}
	var lid:SId;
	var pid:SInt;	
	var uid:SInt;	
	@:relation(pid) public var project:TProject;
	@:relation(uid) public var user:TUser;
	var ltime : SFloat;
	function new(p:TProject,u:TUser)
	{
		super();
		pid = p.id();
		uid = u.id();
		#if php untyped __call__("date_default_timezone_set","GMT+0"); #end
		ltime = Date.now().getTime()/1000.;
	}
	public static function link(project_:String,user_:String)
	{
		var p = TProject.manager.select($name == project_);
		var u = TUser.manager.select($name == user_);
		if(p==null) throw 'link: bad project '+project_;
		if(u==null) throw 'link: bad user '+user_;
		var l = TLink.manager.select($pid==p.id() && $uid==u.id());
		if(l==null) (l=new TLink(p,u)).insert();
		return l;
	}
}

typedef TModel =
{
	manager:sys.db.Manager<Dynamic>,
	info:sys.db.RecordInfos,
	cols: Void -> Dynamic,
	ui: Object -> Dynamic,
}

@:build(hxqp.MyMacro.build())
class LocalDB 
{
	public static function model(table:String):Null<TModel>
	{
		new LocalDB(); // fix
		var c = Type.resolveClass("hxqp."+table);
		if(c==null) return null;
		var manager:sys.db.Manager<Dynamic> = Reflect.field(c,"manager");
		if(manager==null) return null;
		var ui:Object->Dynamic = Reflect.field(c,"ui");
		var info:sys.db.RecordInfos = manager.dbInfos();
		return
		{
			manager:manager,
			info:info,
			cols:ui==null?function():Dynamic /// ->macro
			{
				var ret:Dynamic = {}; 
				for(i in info.fields)
				{
					Reflect.setField(ret,i.name,i.name); 
				};
				return ret;
			}:cast ui,
			ui:ui==null?function(a:Object):Dynamic
			{
				var ret:Dynamic = {};
				for(i in info.fields)
				{
					Reflect.setField(ret,i.name,Reflect.field(a,i.name));
				};
				return ret;
			}:ui,			
		};
	}
	static var local_:Data = null;
	public function data()
	{
		return local_;
	}
	public function new()
	{
		if(local_==null) 
		{
			local_ = Data.Sql.sdb(haxe.macro.Compiler.getDefine("LOCALDB"));
			sys.db.Manager.cnx = local_.connection();
			sys.db.Manager.initialize();
			//sys.db.Manager.cleanup();
		}
	} 
	public function drop():LocalDB
	{
		local_.query("drop table if exists TLink");
		local_.query("drop table if exists TProject");
		local_.query("drop table if exists TUser");
		local_.query("drop table if exists TGroup");
		return this;
	}
	public function create():LocalDB
	{
		if(!TableCreate.exists(TGroup.manager)) TableCreate.create(TGroup.manager);		
		if(!TableCreate.exists(TUser.manager)) TableCreate.create(TUser.manager);		
		if(!TableCreate.exists(TProject.manager)) TableCreate.create(TProject.manager);		
		if(!TableCreate.exists(TLink.manager)) TableCreate.create(TLink.manager);		
		return this;
	}
	public function testData():LocalDB
	{
		TGroup.group("Translators");
		TGroup.group("Programmers");
		TUser.user("Igor","Translators");		
		TUser.user("Ivan","Translators");		
		TUser.user("Rustem","Programmers");
		TProject.project("Zero");
		TProject.project("Second","Translators");
		TProject.project("Third","Translators");
		TProject.project("Zero","Programmers");
		TLink.link("Zero","Rustem");
		TLink.link("Second","Ivan");
		TLink.link("Second","Igor");
		TLink.link("Third","Ivan");
		TLink.link("Third","Ivan");
		return this;
	}
}

#if TEST
class LocalDBTest extends haxe.unit.TestCase
{
	public function test1()
	{
		var z = TProject.project("Test");
		var u = TProject.manager.select($name=="Test");
		for(i in TProject.manager.search($name=="Test"))
		{
	    assertEquals(u,i);
		}
	}
  public function test2()	
	{
		new LocalDB();
		trace(TProject.manager);
		var t = TProject.manager.search(1==1);
    assertTrue(t.length>=3);
		for(i in t)
		{
			trace(Reflect.fields(i));
			trace(i.group);
			i.state = 'test1';
			i.update();			
		}
		var t = TProject.manager.dynamicSearch({"1":1});
    assertTrue(t.length>=3);
		var m = LocalDB.model("TProject");
		for(i in t)
		{
			trace(Reflect.fields(i));
			trace(i.group);
			i.state = 'test2';
			i.update();			
			trace(m.ui(i));
		}
		var r = t.first();
		XLib.trace_(TProject.ui(null));
		XLib.trace_(TProject.ui(r));
	}
}
#end


