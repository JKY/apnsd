<?php
require(dirname(__FILE__). '/../if/apns.lib.php');
/* 
 * connect service, with cname: apnsd, cookie: 123 
 * NOTES: the cname and cookie is the same with erlang start command 
 */
$agent = new APNSAgent("apnsd@127.0.0.1","123");
/* 
 * push message to channel foo, device: dev 
 */
$result = $agent->push("foo", "dev", "hello world....");
print_r($result);
?>