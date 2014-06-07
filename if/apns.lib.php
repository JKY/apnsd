<?php
if(!defined("__APNS_PHP_")){
	define("__APNS_PHP_",1);
	

	class APNSAgent {
		private $_link;
		
		public function APNSAgent($host,$cookie){
			$this->_link = peb_connect($host,$cookie,60000);
		}
	
		/**
		 * push message to dev
		 * @return 
		 *   ok/sent
		 *   offline
		 *   timeout
		 *   failed
		 *   err
		 *   not_connect
		 */ 
		public function push($ch,$dev,$data,$option) {
			if ($this->_link) {
				$method = 'push';
				if(is_array($option)){
					if(array_key_exists('sync',$option) && $option['sync'] == true) {
							$method = 'sync_push';
					}
				}
				try{
					$x = peb_vencode("{~p,~a,{~a,~a,~b}}", array(array($this->_link, $method,  array($ch,$dev,$data))));
					peb_send_byname("apnsd_daemon", $x, $this->_link);
					$reply = peb_receive($this->_link);
					if($reply === FALSE){
						return "timeout";
					}else{
						$rs= peb_vdecode($reply) ;
						return $rs[0];
					}
				}catch(Exception $e){
					return "err";
				}
			}else{
				return "not_connect";
			}
		}	
		
		
		/**
		 * get the channel stat
		 */ 
		public function stat($ch) {
			if ($this->_link) {
				try{
					$x = peb_vencode("{~p,~a,~a}", array(array($this->_link, 'stat', $ch)));
					peb_send_byname("apnsd_daemon", $x, $this->_link);
					$reply = peb_receive($this->_link);
					if($reply === FALSE){
						return false;
					}else{
						return peb_vdecode($reply) ;
					}
				}catch(Exception $e){
					return false;
				}
			}else{
				return "not_connect";
			}
		}	
				
		
		function __destruct(){
			if(is_resource($this->_link))
					peb_close($this->_link); 		
		}
	}
}



$agent  = new APNSAgent("a3@localhost","123");
echo $agent->push("test", "ttt", "hello world1", array('sync'=>true));
echo "\n";
//$stat = $agent->stat('test');
//print_r($stat);
?>