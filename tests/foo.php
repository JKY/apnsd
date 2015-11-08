<?php
/* make sure you have installed the peb extation */
require(dirname(__FILE__). '/../if/apns.lib.php');
if(sizeof($argv) != 4){
	echo "usage: php foo.php ch dev message";
}else{
	/* 
 	 * connect service, with cname: apnsd, cookie: 123 
 	 * NOTES: the cname and cookie is the same with erlang start command 
 	 */
	$agent = new APNSAgent("apnsd@127.0.0.1","123");
	/* 
     * push message to channel foo, device: dev 
     */
	echo $agent->push($argv[1], $argv[2], $argv[3],array());
}
echo "\n";
?>
