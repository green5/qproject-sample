package hxqp;

#if php 
import php.Lib;
#end

#if js 
import js.Lib;
import js.Lib.alert;
#end

interface TagIterator
{
	function hasNext():Bool;
	function next(parent:Tag):Tag;
}

#if 1
/// rewrite to both
interface ITag 
{
	function render(parent:Tag):Void;
}
#else
typedef ITag =
{
	function render(parent:Tag):Void;
	//var title_:String;
}
#end

class TagCommon
{
	static var nocache_:Bool = #if TagNoCache true #else false #end;
	static var id_ = 0;
	public function nextid():String
	{
		return "temp"+(++id_);
	}	
#if TEST
	static var kid_ = new Map<String,String>();
	static function testid(id:String,info:String)
	{
		if(kid_[id]!=null)
		{
			trace(XLib.callFrom());
			throw id + ":" + info + "<=" + kid_[id];
		}
		kid_[id] = info;		
	}
#end
}

@:build(hxqp.MyMacro.phpClass())
@:build(hxqp.TagMacro.remake())
@:expose("hxqp.Tag") 
class Tag extends TagCommon //implements ITag
{
	var parent_:Tag; // parentNode
	var tag_:String; // tagName
	var attr_:Dynamic; // js attributes
	var text_:String; // no match, html or text, ?parentNode.childNodes[nodeType=3]
	var children_:Array<Tag>; // childNodes 
	var from_:String; // internal, dump only
	private function new(parent:Tag,tag:String,attr:Dynamic=null,text:String=null,from:String=null)
	{
	  parent_ = parent;
	  tag_ = tag;
	  attr_ = attr==null ? {} : attr;
		from_ = from == null ? XLib.callFrom(3) : from;
	  text_ = text;
	  children_ = new Array<Tag>();
#if TEST2
		if(XLib.isget(false,attr,"id")) TagCommon.testid(attr.id,from_);
#end
	}
	public function id():String //non-const
	{
	  if(attr_.id==null) 
	  {
			// setParent,insert change childen index => commented
	    attr_.id = parent_!=null? (parent_.id() + "_" + parent_.indexOf(this)) : super.nextid();
	  }
	  return attr_.id;
	}
/*
	private function insert(pos:Int,tag:String,attr:Dynamic=null,text:String=null):Tag
	{
	  children_.insert(pos,new Tag(this,tag,attr,text));
	  return children_[pos];
	}
	private function setParent(parent:Tag,pos:Int=-1)
	{
		if(parent_!=null)
		{
			parent_.children_.remove(this);
			while(parent_.children_.remove(this)) trace(this);
		}
		if(parent!=null) parent.children_.insert(pos,this);
		parent_ = parent;
	}
*/
	public function top():Tag 
	{
		var t = this;
		while(t.parent_!=null) 
		{
			t=t.parent_;
		}
		return t; 
	}
	public function parents():Array<Tag>
	{
		var tt= [];
		var t = this;
		while(t.parent_!=null) 
		{
			tt.push(t=t.parent_);
		}
		return tt;		
	}
	static var root_:Tag = null;
	public static function root():Tag
	{
		if(root_==null) 
		{
			root_ = new Tag(null,"div",{url:Project.URL(),id:Project.packageName()});
			root_.talert("Dialog:"+Project.URL());
		}
		return root_;
	}
	public function tag(tag:String,attr:Dynamic=null,text:String=null):Tag
	{
	  children_.push(new Tag(this,tag,attr,text));
	  return children_[children_.length-1];
	}
	public function utag(tag:String,attr:Dynamic=null,text:String=null):Tag // unique tag
	{
		var t = new Tag(this,tag,attr,text); 
	  if(Lambda.indexOf(children_,t)==-1) children_.push(t);
	  return children_[children_.length-1];
	}
	public function find(tag:String):Tag
	{
	  for(c in children_)   	
	  {
	    if(c.tag_==tag) return c;
	  }
		return null;
	}
	private function indexOf(children:Tag):Int
	{
	  var i:Int = 0;
	  for(c in children_)   	
	  {
	    if(c==children) return i;
	    i++;
	  }
	  return -1;
	}
	public function html(html:String):Tag
	{
	  return tag("_html",null,html);
	}
	public static function addClass(a:Dynamic,x:String):Dynamic
	{
		var c = "class";
		var y:String = Reflect.field(a,c);
		Reflect.setField(a,c,(y==null?"":y+" ")+x);
		return a;
	}
	public function dump(h:String=""):String
	{
		var ret:String = h;
		ret += tag_==null ? "NULL" : tag_ == "" ? "Null" : tag_;
		ret += attr_.id==null ? "" : "[" + attr_.id + "]";
		ret += from_==null ? "" : " :" + from_;
		ret += "\n";
	  for(c in children_) 
	  {
	    ret += c.dump(h+" ");
	  }
		return ret;
	}
	public function str(h:String=""):String
	{
		var ret:String = h;
		if(tag_!=null && tag_.indexOf('_')<0) 
		{
			var attr:String="";
			///	check id unique
	  	for(a in Reflect.fields(attr_))
	  	{
#if 0
				if(a.indexOf('_')>=0) 
					continue;
#end
				if(XLib._typeof(a)!="string") 
				{
					/// json_encode?
					trace(XLib._typeof(a));
					continue;
				}
				attr+=XLib.sprintf(" %s='%s'"
					,a=="c"?"class":a,StringTools.replace(Reflect.field(attr_,a),"'","\\'")); 
	  	}
			ret += XLib.sprintf("<%s%s>",tag_,attr);
		}
		if(text_!=null) ret += text_;
	  for(c in children_) 
	  {
	    ret += c.str(h+" ");
	  }
		if(tag_!=null && tag_.indexOf('_')<0)
		{
			ret += XLib.sprintf("</%s>",tag_); //// input,br close => figny 
		}
	  ret += "\n";
		return ret;
	}
	public function print():Tag
	{
	  XLib.print(str());
	  return this;
	}
	public function fixPath(a:String):String
	{
		if(TagCommon.nocache_) a += '?' + XLib.microtime();
		return a;
	}
	public function include(path:String):Void /// add prio, try found .min.js, wp-include?
	{ 
		path = Project.URL(path);
		if(path.indexOf(".js")>0) 
		{
			path = fixPath(path);
			return includeJS(top(),path);
		}
		if(path.indexOf(".css")>0) 
		{
			return includeCSS(top(),path);
		}
		trace("include: "+path);
	}		
	static macro public function pathExists(path:String):haxe.macro.Expr
	{
		if(!sys.FileSystem.exists(path)) Context.error(path+": not exists",Context.currentPos());
		return macro {};
	}
	public dynamic static function includeCSS(tag:Tag,path:String)
	{ 
		var e=new EReg("(.*/)*(.*)\\.css",null);
		if(!e.match(path)) return trace("includeCSS: "+path);
		var h = StringTools.replace(e.matched(2),'.','-');
		tag.utag("link",{href:path,rel:"stylesheet",type:"text/css",media:"all"});
	}
	public dynamic static function includeJS(tag:Tag,path:String)
	{ 
		var e=new EReg("(.*/)*(.*)\\.js",null);
		if(!e.match(path)) return trace("includeJS: "+path);
		var h = StringTools.replace(e.matched(2),'.','-');
		tag.utag("script",{src:path});
	}
	@js public dynamic static function includeJS(path:String):Void untyped
	{
  	if($.browser && $.browser.safari) return $.ajax({url:path,dataType:'script',async:false,cache:true});
		var html = "<script charset='utf-8' type='text/javascript' src='"+path+"'></script>";
		if($.browser && $.browser.msie) return document.write(html);
    $('head').append(html);
	}
	@js public dynamic static function includeCSS(path:String):Void untyped
	{
		var html = "<link rel='stylesheet' type='text/css' href='"+path+"' media='all'/>";
		if($.browser && $.browser.msie) return document.write(html);
    $('head').append(html);
	}
	public function input(type:String,attr:Dynamic):Tag
	{
		if(attr_.type==null) attr_.type='text'; // null-patterns are not allowed, when it?
	  switch(type)
	  {
	    case 'text': 
	     attr.type=type;	
	     Reflect.setField(attr,"class","regular-text");
	     attr.value=StringTools.htmlEscape(attr.value);
	     return this.tag("input",attr);
/*
			case 'textarea': attr_.rows=3; attr_.cols=50;
	  	case 'select': // +option
			case 'radio':
			case 'checkbox':
			case 'checkboxes':
			case 'color':
			case 'file':
			case 'editor':
			case 'date':
			case 'datetime':
			case 'datetime-local':
			case 'email':
			case 'month':
			case 'number':
			case 'range':
			case 'search':
			case 'tel':
			case 'time':
			case 'url':
			case 'week':
*/		
	  }
	  attr.type=type;	
	  attr.value=StringTools.htmlEscape(attr.value);
	  return this.tag("input",attr);
	}
	public inline function div(attr:Dynamic=null,text:String=null):Tag
	{
		var t = tag("div",attr,text);
		t.id();
		return t;
	}
	public inline function span(attr:Dynamic=null,text:String=null):Tag
	{
		var t = tag("span",attr,text);
		t.id();
		return t;
	}
	public function tabs(hh:Iterator<ITag>,hrender:Tag->ITag->Void=null):Tag //hrender is temp fix, remove later
	{
		// http://jqueryui.com/tabs/
	  var ul = this.tag('ul');	
	  for(h in hh)
	  {
			var id = nextid();
			var href = XLib.isget(null,h,"href_"); // kakto ne tak
			var a = ul.tag('li').tag('a');
	    a.attr_.href = href == null ? '#' + id : href;
			a.text_ = Reflect.field(h,"title_");
			if(a.text_ == null) a.text_ = "Title";
			hrender==null?h.render(tag('div',{id:id})):hrender(tag('div',{id:id}),h);
	  }   
	  include("/ext/jquery.js");
	  include("/ext/themes/base/jquery.ui.all.css"); 
	  include("/ext/ui/jquery.ui.core.js");
	  include("/ext/ui/jquery.ui.widget.js");
	  include("/ext/ui/jquery.ui.tabs.js");
	  top().tag('script',{},XLib.sprintf("$(function(){hxqp.Tag.tabsReady('#%s')})",this.id())); 
	  return ul;	
	}
	@js public static function tabsReady(id)
	{
		var beforeLoad=function(event,ui)
		{
	   	ui.jqXHR.error(function(){ui.panel.html("Couldn\'t load this tab");});
		};
		untyped $(id).tabs({
			active:js.Cookie.get(id),
			beforeLoad:beforeLoad,
			activate:function(event,ui){js.Cookie.set(id,$(id).tabs("option","active"));} 
		});
	}
	// http://www.trirand.com/blog/jqgrid/jqgrid.html
	// jqGrid is good but raw jquery.ajax, big (although backbone,undescore too, is no small)
	public function jqGrid(src:String,id:String=null):Tag
	{
	  include("/ext/jquery.js");
		include("/index.js");
		//include("/ext/jqGrid/css/themes/redmond/jquery-ui-custom.css");
		include("/ext/jqGrid/css/ui.jqgrid.css");
	  include("/ext/jqGrid/jquery.jqGrid.js"); // fix path in jquery.jqGrid.js
		var t = tag("table",{id:"list",c:"scroll"});
		t.tag("div",{id:t.attr_.id+"-pager",c:"scroll",style:"text-align:center"});
		tag("script",{},XLib.sprintf("$(document).ready(function(){hxqp.Tag.jqGrid('%s','%s')})",src,t.attr_.id));
		return t;
	}
	@js public static function jqGrid(src:String,id:String=null)
	{
		untyped __js__("
		if($.fn.jqGrid==undefined) jqGridInclude();
	  $('#'+id).jqGrid(
		{
	    url:hxqp.Project.URL(src),
	    datatype: 'json',
	    colNames:['ID','Name','Group','State'],
	    colModel :[ 
	      {name:'pid', index:'pid'}, 
	      {name:'name', index:'name'}, 
	      {name:'group', index:'group'},
	      {name:'state', index:'state'}, 
			],
  	}); 
		");		
	}
	function bbModel(url:String,level:Int):Array<Dynamic>
	{
		// [collection.url]/[id], http://backbonejs.org/#Model-url
		var mm:Dynamic = new Remote().bbModel(url);
		var t = new Array<Dynamic>();
		for(m in Reflect.fields(mm))
		{
			var title = XLib.ucfirst(m);
			t.push({title:title,name:m,index:true,filter:true,filterType:'input'});
		}
		return t;
	}
	//@:overload(function(data:Data):Tag {})
	public function bbGrid(url:String,v:Dynamic=null):Tag /// Dynamic->bbGrid typeof
	{
		// http://direct-fuel-injection.github.com/bbGrid/
	  include("/ext/jquery.js");
	  include("/ext/bootstrap/bootstrap.css"); //include("/ext/bootstrap/bootstrap-combined.css");
	  include("/ext/bootstrap/bootstrap-responsive.css"); 
	  include("/ext/bootstrap/bootstrap.js");  /// min,combined->include()
		include("/ext/underscore.js");
		include("/ext/backbone.js");
		include("/ext/bbGrid.css");			
		include("/ext/bbGrid.js");
		var level = 0;
		if(attr_.level_!=null) level++;
		for(i in parents()) 
		{
			if(i.attr_.level_==null) break;
			level++;
		}
		var model = bbModel(url,level);
		v = XLib.extend({
			colModel: model,
			loadDynamic: true,
			enableSearch: true,
			rows: 5,
			lang: "ru",
			multiselect: true,
			useRemote_: true,
			url_: hxqp.Project.URL(url),
			id_: model[0].name, ///MID assume first field
		},v);
		var t;
		if(level>0) 
		{
			t = span({param:XLib.serialize(v),level_:level});
			attr_.subid = t.attr_.id; //? to v
		}
		else
		{
			t = div({c:"container",param:XLib.serialize(v),level_:level});
			t.div({c:"row"});
			t.tag("script",{},XLib.sprintf("$(document).ready(function(){hxqp.Tag.bbGrid($('#'+%s)[0],null,-1)})"
				,XLib.q(t.attr_.id)));
			t.attr_.formid = bbForm(model);
		}
		return t;
	}
	@js public static function bbGrid(el:Dynamic,ec:Dynamic,rowid:String)
	{
		/// min, serialize?
		var v = {};
		if(el.attributes && el.attributes.param) 
		{
			if(XLib._typeof(el.attributes.param.value)=="string") v = XLib.unserialize(el.attributes.param.value);
		}
		untyped __js__("
	  var a = _.extend(Backbone,{
			ajax:function(o) {
				if(typeof o !== 'object') {alert('bjax.param:'+typeof(o));throw o;}
				//console.log('bjax',v.useRemote_,o.url,o);
				if(typeof o.data == 'string') o.data = JSON.parse(o.data); //dataType=json
				//if(typeof o.data !== 'object') {alert('bjax.data:'+typeof(o.data));}
				if(!v.useRemote_) 
					return Backbone.$.ajax.apply(Backbone.$,arguments);
				try
				{
					o.data = o.data || {};
					if(o.wait) 
					{
						var ret = hxqp.Remote.call('bbGrid',[o.type,o.url,rowid,o.data]);
						if(o.success) setTimeout(function(){o.success(ret);},1); // fix call order
					}
					else
					{
						hxqp.Remote.acall('bbGrid',[o.type,o.url,rowid,o.data],o.success);
					}
				} catch(x)
				{
					if(o.error) o.error(x);
				}
				return {}; //xHdr
			},
		}).Collection.extend({
			model: Backbone.Model.extend({
				idAttribute:v.id_?v.id_:'id',
				xurl: function() { 
					return v.url_; 
				} // dont backbone url/id
			}),
			url:v.url_,
			parse:function(data,options){
				//console.log(this.model.prototype.idAttribute,v.id_,data[0]);
				return data;
			},
		});
		a = new a();
		_.extend(v,{        
			container: ec==undefined?el:ec,        
			collection: a,
		});
		if(el.attributes.subid) _.extend(v,{        
			subgrid: true,
			subgridAccordion: true,
			onRowExpanded: function(ec, rowid)			
			{
				var em = $('#'+el.attributes.subid.value)[0];
        hxqp.Tag.bbGrid(em,ec,rowid);
			},
		});
		if(el.attributes.formid) _.extend(v,{buttons:[
				{title:'New',onClick:function(){hxqp.Tag.bbForm(el,this,'create')}},
				{title:'Remove',onClick:function(){hxqp.Tag.bbForm(el,this,'delete')}},
				{title:'Edit',onClick:function(){hxqp.Tag.bbForm(el,this,'update')}},
			]});
		new bbGrid.View(v);
		");
	}
	function bbForm(model:Array<Dynamic>):String
	{
	  include("/ext/bootstrap/bootstrap.css"); 
	  include("/ext/jquery.js");
	  include("/ext/ui/jquery-ui.js");
	  include("/ext/ui/jquery.ui.dialog.js");
		var f = top().div({style:"display:none"}); // top -> jqui remove node fromtree
		var t = f.tag("table",{c:"container span6"});
		for(a in model) t.tag("tr",{c:"row"})
			.tag("td",{c:"span1"},a.title) // bbModel()[]
			._tag("td").input("text",{name:a.name}); /// value:Default
		return f.id();
	}
	@js static function bbForm(el,t,m)
	{
		var title = hxqp.XLib.ucfirst(m);
   	var models = t.view.getSelectedModels();
		untyped __js__("
		var f = $('#'+el.attributes.formid.value);
		if(!f.length) return alert(el.id+': no edit form');
		var model = _.first(models);  
		if(!model)
		{
	   	if(m!='create') return alert('Select a row');
			model = new t.model();
		}
		if(m=='create' && t.view.id_) model.attributes[t.view.id_] = model.id = undefined;
		for(var i in model.attributes) $('input[name='+i+']',f).attr('value',model.attributes[i]);
		var bb = {};
		bb.Cancel = function(){$(this).dialog('close')};
		bb[title] = function(){
			if(m=='update'||m=='create') {
				for(var i in model.attributes) model.attributes[i] = $('input[name='+i+']',f).attr('value');
				model.save();
			}
			else if(m=='delete') {
				model.destroy();
			}
			$(this).dialog('close');
		};
		f.first().dialog({
			title:'Row:'+model.id,
			width: 80*6, /// 
			buttons:bb,
		});
		");
	}
	public function talert(title:String="Dialog"):Tag
	{
	  include("/ext/jquery.js");
	  include("/ext/ui/jquery-ui.js");
	  include("/ext/ui/jquery.ui.dialog.js");
		return top().utag("div",{
			id:'hxqp-Tag-talert',
			title:title,
			});
	}
	@js public static function talert(str:String)
	{
		untyped __js__("
			var j = $('#hxqp-Tag-talert');
			if(!j) return alert(str);
			j.text(typeof(str)+':'+str);
			j.dialog({
			modal:true,
			buttons:{OK:function(){$(this).dialog('close')}},
			})
		");
	}
}
