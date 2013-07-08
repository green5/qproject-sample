package hxqp;

#if js
import js.Lib.alert;
#end

@:expose("hxqp.Project") class Project // rename to hxqpProject => no
{
	static var url_:String=null;
	static var package_:String = "hxqp"; // const, else rename this dir,change package keyword,@:expose
	static public function packageName():String
	{
		return package_;
	}
	static public function setURL(url:String):Void
	{
		url_ = url;		
	}
	static public function URL(name:String=null):String
	{
		if(name==null) name="";
#if js
		if(url_==null) url_ = root().attr("url");
		if(url_==null) alert("hxqp: no root url"); 
#end
#if php
		if(url_==null) 
		{
			if(XLib.isget(false,"_SERVER","SERVER_NAME")) untyped url_ = "http://"+__var__("_SERVER","SERVER_NAME")+":"+__var__("_SERVER","SERVER_PORT")+__var__("_SERVER","REQUEST_URI");
		}
#end
		if(url_==null) url_ = "";
		if(name.charAt(0)=='?') // ?param
		{
			var q = url_.indexOf('?');
			if(q<0) return url_ + name;		
			return url_ + '&' + name.substring(1); 
		}
		if(name.charAt(0)=='/') // /[path]
		{
	 		var q = url_.indexOf('?');
			if(q<0) return url_ + name;		
			return url_.substring(0,q) + name + url_.substring(q);
		}
 		var q = url_.indexOf('?');
		if(q<0) return url_ + (url_.substr(-1)=='/'?name:"/"+name);
	  return url_.substring(0,q) + name + url_.substring(q);
	}
#if php
	public static function root():Tag
	{
		return Tag.root();
	}
#end
#if js
	public static function root():js.JQuery
	{
		return untyped $("#"+package_+",div[url]");
	}
#end
}
