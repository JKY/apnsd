package com.apns
{
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.events.TimerEvent;
	import flash.net.Socket;
	import flash.utils.ByteArray;
	
	public class AConn extends Socket {
		
		private var _agent:AAgent;
		
		public function set agent(a:AAgent):void {
			_agent = a;
		}
		
		public function AConn() {
			super();
			this.addEventListener(Event.CONNECT,onConnected);
			this.addEventListener(Event.CLOSE,onClosed);
			this.addEventListener(IOErrorEvent.IO_ERROR,onError);
			this.addEventListener(SecurityErrorEvent.SECURITY_ERROR,onError);
			this.addEventListener(ProgressEvent.SOCKET_DATA,onData);
		}
		
		public function send(m:AMessage):void {
			var buffer:ByteArray = new ByteArray();
			m.pack(buffer);
			this.writeBytes(buffer,0,buffer.length);
		}
		
		/**
		 * message state
		 */
		private static const  M_START:int = 0;
		private static const  M_CMD:int = 1;
		private static const  M_OPT:int = 2;
		private static const  M_BLK_C:int = 3;
		private static const  M_BLK_START:int = 4;
		private static const  M_BLK:int = 5;
		// current message state
		private var M_CURR_ST:int = M_START;
		
		private var cmd:uint = 0x00;
		private var opt:uint = 0x00;
		private var blk_len:int = 0x00;
		private var blk_readed:int = 0;
		private var blk_data_len:int = 0;
		private var blk_data_readed:int = 0;
		
		private function rst_state():void {
			cmd = 0x00;
			opt = 0x00;
			blk_len = 0x00;
			blk_readed = 0;
			blk_data_len = 0;
			blk_data_readed = 0;
			M_CURR_ST = M_START;
		}
		
		private function onData(e:ProgressEvent):void {
			var blk_data:ByteArray = new ByteArray();
			var blks:Array = null;	
			var buffer:ByteArray = new ByteArray();
			var n:uint = this.bytesAvailable;
			this.readBytes(buffer,0,n);
			//_mRecver.log("apns","recv data,length(" + n + ")");
			/*
			for(var i: int  = 0; i < n; i++){
			trace(tmp[i]);
			}
			*/
			var len:int = 0;
			var m_len:int = 0;
			var mStart:int = -1;
			var m:AMessage;
			for(var i: int  = 0; i < n; i++){
				switch (M_CURR_ST) {
					case M_START:
						if (buffer[i] == AMessage.M_START_FLAG) {
							M_CURR_ST = M_CMD;
						} else {
							rst_state();
						}
						break;
					case M_CMD:
						cmd = buffer[i];
						M_CURR_ST = M_OPT;
						break;
					case M_OPT:
						opt = buffer[i];
						M_CURR_ST = M_BLK_C;
						break;
					case M_BLK_C:
						blk_len = buffer[i] & 0xff;
						if (blk_len > 0) {
							blks = [];
							M_CURR_ST = M_BLK_START;
						} else {
							var m:AMessage = new AMessage(cmd, opt, null);
							_agent.onMessage(m);
							rst_state();
						}
						break;
					case M_BLK_START:
						blk_data_len =  buffer[i] & 0xff;
						blk_data_readed = 0;
						M_CURR_ST = M_BLK;
						break;
					case M_BLK:
						if (blk_data_readed < blk_data_len) {
							blk_data.writeBytes(buffer,i,1);
							blk_data_readed++;
						}
						if (blk_data_readed == blk_data_len) {
							blks[blk_readed] = blk_data.toString();
							blk_readed++;
							if (blk_readed < blk_len) {
								M_CURR_ST = M_BLK_START;
							} else {
								var m:AMessage = new AMessage(cmd, opt, blks);
								_agent.onMessage(m);
								rst_state();
							}
						}
						break;
					default:
						rst_state();
						break;
				}
			}
		}
		
		
		protected function onConnected(e:Event):void {
			_agent.onConnected();
		}
		
		protected function onClosed(e:Event):void {
			_agent.onClosed();
		}
		
		protected function onError(e:Event):void{
			_agent.onErr();
		}
	}
}