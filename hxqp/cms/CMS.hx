package hxqp.cms;

interface CMS
{
	public function options():Options;
	public function hooks():Void;
	public function remote():Dynamic;
}
