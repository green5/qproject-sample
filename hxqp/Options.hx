package hxqp;

#if php

import hxqp.XLib.*;
import php.NativeArray;

interface HavingName
{
	public function name1():String;
}

class Option //implements Tag.ITag
{
	public var name_:String;
	public var title_:String;
	var parent_:HavingName;
	var attr_:Dynamic;
	public var render_:Tag->Void;
	function new(parent:HavingName,name:String,title:String,attr:Dynamic,render:Dynamic=null)
	{
	  parent_ = parent;
	  name_ = name;
	  attr_ = attr;
		title_ = title;
		render_ = render;
	}
	public static dynamic function _new(parent:HavingName,name:String,title:String,attr:Dynamic,render:Dynamic=null)
	{
		// make macro for such t. (_new,parent_.__init__)
		return new Option(parent,name,title,attr,render); 
	}
	public function render(parent:/*out*/Tag):Void
	{
		attr_.size = 40;
		attr_.id = name_;
		attr_.name = XLib.sprintf('%s[%s]',parent_.name1()+"_options",name_);
	  attr_.value = value();
	  parent.input("text",attr_);
		if(render_!=null) render_(parent); // next td	
	}
	public function print():Void
	{
		var temp = Tag.root();
		render(temp);
		temp.print();
	}
	public function value():String
	{
		return attr_.value;
	} 
	public function setValue(v:String):Void
	{
		attr_.value = v; ///
	} 
	public function validate(value:String):String
	{
	  return null;
	}
}

class Section implements Tag.ITag
{
	public var parent_:HavingName;
	public var options_:Map<String,Option>;
	public var title_:String;
	public var render_:Dynamic; // function, >havingRender
	public var href_:String;
	public function new(parent:Options,title:String,render:Dynamic=null,href:String=null)
	{
		parent_ = parent;
		options_ = new Map<String,Option>();
		title_ = title;
		render_ = render;
		href_ = href;
	}
	public function option(name:String,attr:Dynamic=null,render:Dynamic=null):Section
	{
		var title:String = XLib.x1("ucfirst",name); ///
		name = parent_.name1() + "_" + name; //fix.
		if(attr==null) attr={};
		options_[name] = Option._new(parent_,name,title,attr,render); // ?check old[name]
		return this;
	}
	public function render(parent:Tag):Void
	{
	  var tab = parent.tag("table",{"class":"form-table"});
	  Lambda.iter(options_,function(o:Option)
		{
			var tr = tab.tag("tr",{valign:"top"}).tag("th",{scope:"row"},o.title_);
			o.render(tr.tag("td"));
		});
		if(render_) render_(parent); // next tr	
	}
}

class Options implements Tag.ITag implements Map.IMap<String,String> implements HavingName
{
	var sections_:Array<Section>;
	public function getOption(k:String):Null<Option>
	{
	  for(s in sections_) 
			if(s.options_.exists(k)) return s.options_.get(k);
		return null;
	}
	public function get(k:String):Null<String>
	{
	  for(s in sections_) 
			if(s.options_.exists(k)) return s.options_.get(k).value();
		return null;
	}
	public function set(k:String, v:String):Void
	{
	  for(s in sections_) 
			if(s.options_.exists(k)) s.options_.get(k).setValue(v);
	}
	public function exists(k:String):Bool
	{
	  for(s in sections_) 
			if(s.options_.exists(k)) return true;
		return false;
	}
	public function remove(k:String):Bool
	{
		var ret = false;
	  for(s in sections_) 
			ret = s.options_.remove(k) || ret;
		return ret;
	}
	public function keys():Iterator<String>
	{
		return null; ///	
	}
	public function iterator():Iterator<String>
	{
		return null; ///		
	}
	public function toString():String
	{
		return "[Options]";
	}
  public function name1()
	{
		return "qproject_sample"; 
	}
	public function new()
	{
	  sections_ = new Array<Section>();
	}
	public function section(title:String,render:Tag->Void=null,href:String=null):Section
	{
		var ss = sections_.filter(function(s){return s.title_==title;});
		if(ss.length > 0) return ss[0];
		var n = sections_.push(new Section(this,title,render,href));
		return sections_[n-1];
	}	
	public function render(page:Tag):Void
	{
	  page.include("/ext/jquery.js"); /// ... to CDN, minimaze /ext 
	  page.tag('div',{id:name1()+"-tabs"}).tabs(this.sections_.iterator());
	  page.tag('br')
			.input('button',{value:'Home',onclick:'location.href=hxqp.Project.URL()+"/index.php"'});
	}
}
#end
