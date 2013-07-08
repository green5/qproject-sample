<?php
/*  Copyright 2013 Rustem (email : r-green@mail.ru)

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License, version 2, as 
    published by the Free Software Foundation.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
*/
/*
Plugin Name: qproject-sample
Plugin URI: http://localhost/qproject-sample
Description: qProject Simple Manager
Author: Rustem Valeev
License: GPL2
Tags: wordpress plugin haxe
Version: 1.20130708
slug: qproject-sample
last_updated: 2013-07-08 18:28:18
rating: 90
num_ratings: 1
downloaded: 1
*/

$dir = plugin_dir_path(__FILE__);
if(is_dir($dir.'plugin-updates'))
{
	require_once $dir.'plugin-updates/plugin-update-checker.php';
	new PluginUpdateChecker(plugins_url('qproject-sample/info.json'),__FILE__,'qproject-sample'); // slug
}
require_once 'Mail.php';
require_once dirname(__FILE__).'/index.php';	

?>
