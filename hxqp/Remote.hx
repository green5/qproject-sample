package hxqp;

#if js
import js.JQuery;
import js.Lib.alert;
@:expose("hxqp.Remote") 
class Remote
{
	public function new()
	{
	}
	static function get_option(o):String
	{
		return new JQuery("#qproject_sample_"+o).attr("value");
	}
	static function mail():Void
	{
		//alert(call("WP.mail",[get_option("replyTo"),"mail from qproject","..."]));
		acall("WP.mail",[get_option("replyTo"),"mail from qproject","..."],function(a){alert(a);});
	} 
	static function tryadd()
	{
		alert(call("tryadd",[1,2]));
	}
	static function acall(proc:String,params:Array<Dynamic>=null,?onResult:Dynamic->Void=null):Void
	{
		if(params==null) params=[];
		try
		{
	    var cnx:haxe.remoting.AsyncConnection = haxe.remoting.HttpAsyncConnection.urlConnect(Project.URL());
			if(proc.indexOf(".")<0) proc="Remote."+proc;
			for(p in proc.split(".")) cnx = cnx.resolve(p);				
  	  cnx.setErrorHandler(function(err){
				js.Lib.alert("acall.Error:"+Std.string(err));
				throw err;
			});
	    cnx.call(params,onResult==null?function(data){alert(data);}:onResult);
		} catch(x:Dynamic) {alert("acall:"+x);throw x;}
	}
	static function call(proc:String,params:Array<Dynamic>=null):Dynamic
	{
		if(params==null) params=[];
		try
		{
	    var cnx:haxe.remoting.Connection = haxe.remoting.HttpConnection.urlConnect(Project.URL());
			if(proc.indexOf(".")<0) proc="Remote."+proc;
			for(p in proc.split(".")) cnx = cnx.resolve(p);				
	    var ret = cnx.call(params);
			return ret;
		} catch(x:Dynamic) {alert("call:"+x);throw x;}
	}
}
#end

#if php
class Remote
{
	public function new()
	{
	}
	function tryadd(x,y)
	{
		throw MyMacro.lineno("overflow");
		return x + y;
	}
	public static function mail(to:String,subject:String,body:String,o:Dynamic):String
	{
		var ret:String = "Message successfully sent"; 
		if(o.username==null)
		{
			ret = php.Lib.mail(to,subject,body)?
				to+": mail was successfully accepted for delivery"
				:"mail was failed";		
		}
		else
		{
			var from = o.replyTo;
		 	var host = o.smtp;
			var username = o.username;
	 		var password = o.password;
			untyped __php__("
			$headers = array (
				'From' => $from,
	 			'To' => $to,
	   		'Subject' => $subject);
 			$smtp = Mail::factory('smtp',
	 			array ('host' => $host,
	   		'auth' => true,
	   		'username' => $username,
	   		'password' => $password));
			$mail = $smtp->send($to, $headers, $body);
 			if(PEAR::isError($mail)) $ret = $mail->getMessage();
			");
		}
 		return ret;
 	}
	public function bbModel(url):Array<Dynamic>
	{
		var u = utils.URLParser.parse(url);
		var m = LocalDB.model(u.desplit().T);
		if(m==null) throw "bbModel: bad url "+url;
		return m.cols();
	}
	public function bbGrid(type:String,url:String,rowid:String,data:Dynamic):Array<Dynamic> // BackboneRemoting
 	{
		//trace([type,url,""+rowid].join(";"));trace(data);
		var u = utils.URLParser.parse(url);		
		if(1==1)
		{
			var bb = u.query.split("/");
			u.query = bb[0]; /// backbone url?x=1/id, fix later
			if(bb.length>1) rowid = bb[1];
		}
		var m:Dynamic = LocalDB.model(u.desplit().T);
		if(m==null) throw "bbGrid: bad url "+url;
		if(type=='GET')
		{
			var q = {};
			if(rowid!="-1" && u.anchor != null) /// page,rows
			{
				u.anchor = StringTools.replace(u.anchor,":1",rowid);
				q = u.desplit("anchor");
			}
			var ll:List<Dynamic> = m.manager.dynamicSearch(q);
			var aa = [];
			for(l in ll) aa.push(m.ui(l));	
			return aa;
		}
		else if(type=='PUT')
		{
			var id = Reflect.fields(data)[0]; ///MID assume first field
			var q = {};
			Reflect.setField(q,id,Reflect.field(data,id));
			var uu:List<Dynamic> = m.manager.dynamicSearch(q);
			if(uu.length!=1) throw "bad.id:["+id+"="+Reflect.field(data,id)+"]";
			var u = uu.first();
			// data.group = null; //Reflect.deleteField(data,"group"); /// fix group.name -> gid
			XLib.extend(u,data);
			u.update();
		}
		else if(type=='DELETE')
		{
			var q = {pid:rowid};
			var uu:List<Dynamic> = m.manager.dynamicSearch(q);
			if(uu.length!=1) throw "bad.id:"+rowid;
			var u = uu.first();
			u.delete();
		}
		else if(type=='POST')
		{
			var id = Reflect.fields(data)[0]; ///MID assume first field
			Reflect.setField(data,id,null);
			for(i in cast(m.info.relations,Array<Dynamic>)) Reflect.setField(data,i.key,1); /// poka ne rabotayt FK, dodelat
			m.manager.doInsert(data);
		}
		else throw "bbGrid.method:"+type;
		return [];
	}
	public function jqGrid(q:Dynamic):Dynamic
	{
		var ret = untyped __php__("new stdClass()");
		untyped __php__("
			$ret->page = 1;
			$ret->total = 1;
			$ret->records = 3;
			$ret->rows = array();
		");
		XLib.x2("array_push",ret.rows,untyped [10,"jqGridProject","","example"," "].a);
		return ret;
	}
}
#end

#if TEST
@:build(hxqp.MyMacro.phpClass())
class RemoteTest extends haxe.unit.TestCase
{
	function su(data:Dynamic)
	{
		try {
			return XLib.unserialize(XLib.serialize(data));
		} catch(x:Dynamic) {trace(x);}
		return data;
	} 
	public function testData()
	{
		trace(LocalDB.TProject.manager);
		new LocalDB();
		LocalDB.TProject.manager.search(1==1);
		//for(p in LocalDB.TProject.manager.search(1==1)) {trace(p);trace(p.group.id());}
		//var m = LocalDB.TProject.manager;trace(m.dbInfos().key[0]);trace(m.dynamicSearch({"1":1}));
		//var x = new Remote().bbModel("?T=TProject");trace(x);
		//var x = new Remote().bbModel("?T=TLink");trace(x);
		//var x = new Remote().bbGrid("?T=TLink#pid=:1",3)[0];trace(x);assertEquals(x,su(x));
    new Remote().bbGrid('PUT',"?T=TProject","-1",{pid:1,state:'testData1'});
		assertTrue(1>0);
	}
}
#end

