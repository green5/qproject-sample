package hxqp.cms;

#if !php
Context.error("php");
#end

private class Tag2
{
	static public function includeCSS(Tag,path:String)
	{ 
	  var h:String=StringTools.replace(XLib.x2('basename',path,'.css'),'.','-');
		if(XLib.x1("wp_style_is",h)) return;
	  XLib.x1('wp_deregister_style', h);
	  XLib.x2('wp_register_style',h, path);
	  XLib.x1('wp_enqueue_style', h );
	}
	static public function includeJS(Tag,path:String)
	{ 
		//// call before render, at print time too later => make page at admin_menu
	  var h:String=StringTools.replace(XLib.x2('basename',path,'.js'),'.','-');
		if(XLib.x2("wp_script_is",h,"enqueued")) return;
	  XLib.x2('wp_enqueue_script',h,path);
	}
}

class Option extends hxqp.Options.Option
{
	public static dynamic function _new(parent:hxqp.Options.HavingName,name:String,title:String,attr:Dynamic,render:Dynamic=null)
	{
		// too lazy to do a template, ...
		return new Option(parent,name,title,attr,render);
	}
	override public function value():String
	{
		var x = XLib.x1('get_option',parent_.name1()+"_options");
		return XLib.isget(attr_.value,x,name_);
	}
}

private class Options extends hxqp.Options implements hxqp.Tag.ITag
{
	var page_ = "qproject-sample";    
	public function new()
	{
		super();
	}
	function validate(input:php.NativeArray):php.NativeArray // from sanitize_option
	{
	  var name:String = null;
	  var value:String = null;
	  untyped __php__("if(is_array($input)) foreach($input as $name=>$value){");
	    var o = getOption(name);
	    if(o!=null) 
	    {
	      var nvalue = o.validate(value);
	      if(nvalue!=null) untyped input[name] = nvalue;
	    }
	  untyped __php__("}");
	  return untyped __php__("$input");
	}  
  function hrender(parent:Tag,tab:Tag.ITag) /// fix later, cms and ...
	{
		var section = cast(tab,hxqp.Options.Section);
		if(section!=null && section.title_=="Options")
		{
		  var form = parent.tag("form",{action:'options.php',method:'post'});
		  form.html(XLib.ob_vcall('settings_fields',[name1()+"_options"]));
			tab.render(form);
		  form.tag('br').input('submit',{name:'Submit',value:'Save Changes'});
		}
		else
			tab.render(parent);
	}
	override public function render(page:Tag):Void
	{
	  page.include("/ext/jquery.js");
		// http://ottopress.com/2009/wordpress-settings-api-tutorial/
		for(s in sections_)
		{
		  XLib.x4('add_settings_section', s.title_, s.title_, null, page_);
			for(o in s.options_)
			{
		    XLib.x5('add_settings_field',o.name_, o.title_, o.print.bind(), page_, s.title_);
			}
		}
	  page.tag('div',{id:name1()+"-tabs"}).tabs(this.sections_.iterator(),hrender);
	}  
}

private class Remote
{
	var options_:Map.IMap<String,String>;
	public function new(options:Map.IMap<String,String>)
	{
		options_ = options;
	}
	function mail(to:String,subject:String,body:String):String
	{
		var o = {
			from:options_.get("replyTo"),
	 		host:options_.get("smtp"),
			username:options_.get("user"),
 			password:options_.get("password"),
		};
		return hxqp.Remote.mail(to,subject,body,o);
	}
}

class WP implements CMS
{
	static public function __init__()
	{
		hxqp.Options.Option._new = hxqp.cms.WP.Option._new;
	}
	var options_:Options;
	var page_:String="qproject-sample";
	var name_:String="qproject_sample";
	public function remote():Dynamic
	{
		return new Remote(options_);
	}
	public function new()
	{
		XLib.vcallException_ = false;
		//hxqp.Option._new = hxqp.cms.WP.Option._new;
		options_ = new Options();
	  options_.section("Options")
			.option("smtp",{value:"localhost:25",title:"mail server[:port=25]"})
	  	.option("user",{value:"www-data",title:"optional"})
	  	.option("password",{type:"password"})
	  	.option("replyTo",{value:"root@localhost",title:"your email address"},function(paren:Tag):Void
			{
				paren.tag('input',{type:'button',value:'TestMail',onclick:'hxqp.Remote.mail()'});	
			})
		  .option("localDSN",{value:haxe.macro.Compiler.getDefine("LOCALDB")});
	}
	public function hooks()
	{
		if(!XLib.x1("function_exists","plugins_url")) return;
		Project.setURL(XLib.x1("plugins_url",page_));
		untyped __php__("
 		global $wp_filter;
		if(isset($wp_filter)) foreach($wp_filter as $a=>$x) 
			if(method_exists($this,$a)) add_filter($a,array($this,$a));
		");
    XLib.x2('add_filter','plugin_row_meta', plugin_row_meta);
	}
	public function options():Options
	{
		return options_;
	}
	public function admin_init() //2
	{
		if(1==0) untyped __php__("
 		global $wp_filter;
		if(isset($wp_filter)) foreach($wp_filter as $a=>$x) 
			syslog(LOG_DEBUG,$a);
		");
	  XLib.x3('register_setting',name_+"_options",name_+"_options",XLib.aa([options_,'validate']));
	}
	public function plugin_row_meta(links:php.NativeArray)
	{
	  if(XLib.x1("isset",links[2]) && links[2].indexOf("qproject-sample")>0)
		{
	    XLib.x2('array_push',links,'<a href="admin.php?page='+page_+'">Settings</a>');
		}
	  return links;	
	}
	public function admin_menu() //1
	{
	  XLib.x5('add_options_page',name_,name_,'manage_options',page_, print_page.bind());  // [ this, 'print_page']
		hxqp.Tag.includeJS=Tag2.includeJS;
		hxqp.Tag.includeCSS=Tag2.includeCSS;
		options_.render(Project.root()); // here because of includes
	  Project.root().include("/index.js"); // last include after render
	}
	function print_page()
	{		
		Project.root().print();		
	}
}
