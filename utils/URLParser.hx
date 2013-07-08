// http://haxe.org/doc/snip/uri_parser

package utils;
//import haxe.Http;

// http://medialize.github.io/URI.js/about-uris.html
// URI = URL | URN // http://tools.ietf.org/html/rfc3986
// IRI (Internationalized Resource Identifier) // http://tools.ietf.org/html/rfc3987
// URN = "urn:" <NID> ":" <NSS> // http://tools.ietf.org/html/rfc2141
//			urn:mpeg:mpeg7:cs:VideoDomainCS:2001 // http://tools.ietf.org/html/rfc3614
// URL = scheme ":" hier-part [ "?" query ] [ "#" fragment ]
// Data Source Name, or DSN = ?URN


class URLParser 
{
    public var url : String;
  	public var ok:Bool;

    public var source : String;
     public var protocol : String;
     public var authority : String;
      public var userInfo : String;
       public var user : String;
       public var password : String;
      public var host : String;
      public var port : String;
     public var relative : String;
      public var path : String;
       public var directory : String;
       public var file : String;
      public var query : String;
      public var anchor : String;

	  static public var _parts(default,null) : Array<String>;

		static function __init__()
		{
			 _parts = ["source","protocol","authority","userInfo","user","password","host","port","relative","path","directory","file","query","anchor"];
		}

    public function new(url:String)
    {
        // Save for 'ron
        this.url = url;
 
        // The almighty regexp (courtesy of http://blog.stevenlevithan.com/archives/parseuri)
        var r : EReg = ~/^(?:(?![^:@]+:[^:@\/]*@)([^:\/?#.]+):)?(?:\/\/)?((?:(([^:@]*)(?::([^:@]*))?)?@)?([^:\/?#]*)(?::(\d*))?)(((\/(?:[^?#](?![^?#\/]*\.[^?#\/.]+(?:[?#]|$)))*\/?)?([^?#\/]*))(?:\?([^#]*))?(?:#(.*))?)/;

        // Match the regexp to the url
        this.ok = r.match(url);
 
        // Use reflection to set each part
        for (i in 0..._parts.length)
        {
            Reflect.setField(this, _parts[i],  r.matched(i));
        }
		}
				
		public function desplit(key:String="query"):Dynamic
		{
			var	ret = {};
			var str:String = Reflect.field(this,key);
			if(str!=null) for(pp in str.split("&"))
			{
				var i = pp.indexOf("=");
				if(i<0)
				{
						Reflect.setField(ret,pp,true);
						continue;
				}
				var k = pp.substring(0,i);
				var v = pp.substring(i+1);
				k = StringTools.urlDecode(k);
				v = StringTools.urlDecode(v);
				Reflect.setField(ret,k,v);
			}
			return ret;
		}
		 
		public function toString() : String
		{
			return this.source;
		}

    public function test() : String
    {
        var s : String = "For Url -> " + url + "\n";
        for (i in 0..._parts.length)
        {
            s += _parts[i] + ":[" + Reflect.field(this, _parts[i]) + "]\n";
        }
				s += "query:" + desplit("query") + "\n";
				s += "anchor:" + desplit("anchor") + "\n";
        return s;
    }
 
    public static function parse(url:String) : URLParser
    {
        return new URLParser(url);
    }

}

#if TEST
class Test extends haxe.unit.TestCase
{
	static var u1 = [
	"/hello/world/there.html?name=ferret#foo"
  ,"foo://username:password@www.example.com:123/hello/world/there.html?name=ferret#foo"
	,"mailto::a@x"
	,"?a=1&b=2"
	,"?a=1&b=2?c=3&d=4"
	,"?T=TLink[pid=:1].user()"
	];
	static var u2 = [
	"http://a.com?a=1#c=2&b=2"
	,"?a=1&b=2/3"
	];
	public function testParse()
	{
		for(u in u1) assertEquals(u,URLParser.parse(u).toString());
		for(u in u2) assertEquals(u,URLParser.parse(u).toString());
	}
	public function testtest()
	{
		var err = "";
		for(u in u2) try 
		{
			trace(URLParser.parse(u).test());
		} catch(x:Test) { err=""+x; }
		assertEquals("",err);
	}
}
#end
