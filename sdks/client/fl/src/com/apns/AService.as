package com.apns
{
	import com.adobe.crypto.MD5;
	
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.events.TimerEvent;
	import flash.net.Socket;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLVariables;
	import flash.utils.ByteArray;
	import flash.utils.Timer;
	
	import org.osmf.net.StreamingURLResource;
	
	public class AService extends EventDispatcher
	{
		private var _mTimer:Timer;
		private var _agent:AAgent;
		
		public static const NOTIFICATION:String = "com.apns.NOTIFICATION";
		public var data:Object;
		
		
		public function AService() {
			_agent = new AAgent(new AConn());
			_agent.addEventListener(AAgent.NOTIFICATION,function(e:Event):void {
				var a:AAgent = e.currentTarget as AAgent;
				data = a.data;
				dispatchEvent(new Event(NOTIFICATION));
			});
			_mTimer = new Timer(10000);
			_mTimer.addEventListener(TimerEvent.TIMER,check);
		}
		
		public function start(ch:String,id:String):void {
			_agent.setId(ch,id);
			if(_agent.connected){
				_agent.shutdown();
			}
			_agent.connect();
		}
		
		public function stop():void {
			if(_agent.connected){
				_agent.shutdown();
			}
		}
		
		private function check(e:Event = null):void{
			if(!_agent.connected){
				_agent.connect();
			}
		}
	}
}