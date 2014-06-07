package com.apns
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLVariables;
	import flash.utils.ByteArray;
	
	public class AAgent extends EventDispatcher{
		
		private var _ch:String,_id:String;
		private var _conn:AConn;
		private var _addr:String = "221.181.64.227";
		
		public static const NOTIFICATION:String = "com.apns.NOTIFICATION";
		public var data:Object;
		
		private function getAddr():String {
			var loader:URLLoader = new URLLoader();
			loader.addEventListener(Event.COMPLETE,onHttpComplete);
			loader.addEventListener(IOErrorEvent.IO_ERROR,onErr);
			var request:URLRequest = new URLRequest("http://push-notification.org/s1.php");
			var param:URLVariables = new URLVariables();
			param.m = 'fl';
			request.data = param;
			loader.load(request);
			return _addr;	
		}
		
		
		private function onHttpComplete(e:Event):void{
			var loader:URLLoader = e.currentTarget as URLLoader;
			loader.removeEventListener(Event.COMPLETE,onHttpComplete);
			loader.removeEventListener(IOErrorEvent.IO_ERROR,onErr);
			var ip:String = loader.data;
			_addr = ip;
			this.connect();
		}
		
		public function get port():int { 
			return 1885;
		}
		
		public function AAgent(conn:AConn){
			_conn = conn;
			_conn.agent = this;
			
		}

		
		public function setId(ch:String , id:String):void{
			_ch = ch;
			_id = id;
		}
		
		public function get connected():Boolean {
			return _conn.connected;
		}
		
		
		public function connect():void {
			if(this._addr != ""){
				_conn.connect(_addr,this.port);
			}else{
				this.getAddr();
			}
		}
		
		public function shutdown():void{
			if(_conn.connected)
				this._conn.close();
		}
		
		/******************************/
		public function onConnected():void {
			
		}
		
		public function onErr():void {
			
		}
		
		public function onClosed():void {
			
		}
		
		public function onNotifiy(str:String):void{
			this.data = str;
			this.dispatchEvent(new Event(NOTIFICATION));
		}
		
		
		public function onLimit():void{
			_conn.close();
		}
		
		
		public function onMessage(m:AMessage):void {
			var cmd:uint = m.cmd;
			if(cmd == AMessage.CMD_RQ_LMT){
				//onLimit();
			}
			if (cmd == AMessage.CMD_RQ_JOIN) {
				this.join(_ch, _id);
			}
			if (cmd == AMessage.CMD_RQ_ECHO) {
				echo();
			}
			if (cmd == AMessage.CMD_RQ_NTY) {
				var str:Array = m.blocks;
				if (str != null && str.length > 0) {
					this.onNotifiy(str[0]);
				}
				var echo:AMessage = new AMessage(AMessage.CMD_RP_NTY, 0x00, null);
				_conn.send(echo);
			}
		}
		
		
		
	    /****************************/
		protected function echo():void{
			var m:AMessage = new AMessage(AMessage.CMD_RP_ECHO, 0x00, null);
			_conn.send(m);
		}
		
		protected function join(ch:String,id:String):void{
			var BLKS:Array = [];
			BLKS[0] = ch;
			BLKS[1] = id;
			var m:AMessage = new AMessage(AMessage.CMD_RP_JOIN, 0x00,
				BLKS);
			_conn.send(m);
		}
	}
}