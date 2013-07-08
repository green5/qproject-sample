package hxqp;

#if js
import hxqp.Project;
import hxqp.Remote;
import hxqp.Tag; /// expose, musora tam, change TagMacro [plat=def]
#end

#if php
import php.Web;
#end

@:build(hxqp.MyMacro.phpClass())
class Main
{
	@js static function __init__()
	{		
		// Testing
		untyped __js__("
		if(typeof window == 'undefined') window={};
		if(typeof print != 'function') no_print_function();
		if(typeof console == 'undefined') console={log:function(a){print(a)}};
		if(typeof alert != 'function') alert=function(a){print(a)};
		//if(typeof $ == 'undefined') alert('Main:no$');
		$hxClasses['XHList'] = List;
		");
	}
	@any public function new()
	{
		var h=new List<Int>();
	}
	@any static function main()
	{
		#if php var isCli:Bool = php.Lib.isCli(); #end
		#if js	var isCli:Bool = untyped __js__("window.isCli"); #end
		if(isCli) 
		{
			var a:Array<String> = ["","test"];
			#if php 	
				a = untyped __php__("new _hx_array($_SERVER['argv'])");
				if(a[1]=="db") new LocalDB().drop().create().testData(); 
			#end
			if(a[1]=="test") #if TEST TestMain.main() #end;
			return;
		}
#if php
	  haxe.Log.trace = XLib.xtrace;
		try
		{
			var req:Dynamic = {};
			if(!isCli) 
			{
				//trace(Web.getMethod()+":"+Web.getURI()+":"+Web.getParams());
				req.url = untyped __php__("$_SERVER['REQUEST_URI']");
				for(i in Web.getParams().keys()) req.$i=Web.getParams().get(i); 
			}
		  new Main().tmain(isCli,req);
	  }
		catch(x:Dynamic) 
		{
			trace("Main:"+x);
		}
#end
	}
	@js public function tmain(isCli:Bool,req:Dynamic)
	{
		if(isCli) throw "js: Not implemented for this platform";
	}
	@php public function tmain(isCli:Bool,req:Dynamic):Void
	{
		var c:hxqp.cms.CMS = new hxqp.cms.WP(); ///->cms.plug. and tcms
		makeOptionPage(c.options());		
		if(req.__x!=null) 
		{
			var ctx = new haxe.remoting.Context();
	    ctx.addObject("Remote",new Remote());
	    #if WP ctx.addObject("WP",c.remote()); #end
    	if(haxe.remoting.HttpConnection.handleRequest(ctx)) return;
		}
		if(Web.getMethod()=="GET" && req.loadData!=null) // load grid data, not remoting
		{
			var ret = [];
			if(req.loadData=="bbGrid") 
			{
				ret = new Remote().bbGrid("GET",req.url,"-1",{rowid:req.rowid});
				ret = untyped ret.a; // for json_encode native array 
			}
			if(req.loadData=="jqGrid") ret = new Remote().jqGrid(req);
			XLib.print(XLib.x1("json_encode",ret)); //utf8
		}
		c.hooks();
	}
	static public function makeOptionPage(o:Options)
	{
		/// => db, data and ui together
		if(1==1) o.section("Projects",function(parent:Tag):Void
		{
			parent.bbGrid("?T=TProject").bbGrid("?T=TLink#pid=:1").bbGrid("?T=TProject#pid=:1");
		});
		if(1==1) o.section("Users",function(parent:Tag):Void
		{
			parent.bbGrid("?T=TUser").bbGrid("?T=TLink#uid=:1");
		});
		if(1==1) o.section("Groups",function(parent:Tag):Void
		{
			parent.bbGrid("?T=TGroup").bbGrid("?T=TUser#gid=:1").bbGrid("?T=TLink#uid=:1");
		});
		if(1==1) o.section("Testing",function(parent:Tag):Void
		{
			parent.input("button",{onclick:'hxqp.Remote.tryadd()',value:"1+2"}); // Main@js
			//parent.div({},"jqGrid Example").jqGrid("?loadData=jqGrid&T=TProject");
			//parent.div({},"bbGrid Example").bbGrid("?loadData=bbGrid&T=TProject",{useRemote:false});
			//parent.div({},"bbGrid RemotingExample").bbGrid("?loadData=bbGrid&T=TProject",{useRemote:true});
		});
		//o.section("Help",null,hxqp.Project.URL("/help"));
	}
}

#if TEST
class TestMain extends haxe.unit.TestCase
{
	public static var print_:Dynamic->Void = haxe.unit.TestRunner.print;
	public static function jprint(v:Dynamic)
	{
		v = StringTools.rtrim(""+v);
		untyped __js__("print(v)");		
	}
  static function main()
	{
	  haxe.Log.trace = XLib.xtrace;
#if js
		haxe.unit.TestRunner.print = jprint;
#end
  	var r = new haxe.unit.TestRunner();
    r.add(new hxqp.XLib.XLibTest());
    r.add(new utils.URLParser.Test());
#if php
    r.add(new LocalDB.LocalDBTest());
    r.add(new Remote.RemoteTest());
    r.add(new hxqp.Main.MainTest());
#end
    r.run();
  }
}

@:build(hxqp.MyMacro.phpClass())
class MainTest extends haxe.unit.TestCase
{
	public function testTMAIN()
	{
		var c:hxqp.cms.CMS = new hxqp.cms.WP();
		Main.makeOptionPage(c.options());		
		c.options().render(Project.root());
		var str = Project.root().dump();
		//trace(str);
		XLib.xtrace("Done");
    assertEquals(1,1);
	}
	public function testPDO()
	{
		var x = Data.Sql.pdo(haxe.macro.Compiler.getDefine("LOCALDB"));
		var q = x.query("select pid id,name,gid 'group',state from TProject limit 2");
		//trace(q);
    assertEquals(2,q.length);
	}
	public function testSDB() // 1
	{
		//new LocalDB().drop().create().testData();
		var q = new LocalDB().data().query("select pid id,name,gid 'group',state from TProject limit 2");
    assertEquals(2,q.length);
	}
}
#end

