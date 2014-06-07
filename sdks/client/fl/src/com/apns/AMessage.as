package com.apns
{
	import flash.utils.ByteArray;

	public class AMessage
	{
		public static const  M_START_FLAG:uint = 0x05;
		
		public static const  CMD_RQ_JOIN:uint =  0x01;
		public static const  CMD_RQ_ECHO:uint =  0x02;
		public static const  CMD_RQ_NTY:uint =  0x03;
		public static const  CMD_RQ_LMT:uint = 0x05;
		public static const  CMD_RQ_RDRECT:uint =  0x0f;
		
		public static const  CMD_RP_JOIN:uint =  0xf1;
		public static const  CMD_RP_ECHO:uint =  0xf2;
		public static const  CMD_RP_NTY:uint =  0xf3;
		public static const  CMD_RP_RDRECT:uint =  0xff;
		
		private var _cmd:uint;
		public function get cmd():uint { return _cmd;}
		
		private var _opt:uint;
		public function get opt():uint { return _opt;}
		
		private var _blocks:Array;
		public function get blocks():Array { return _blocks; }
		
		
		
		public function AMessage(cmd:uint, opt:uint, content:Array) {
			_cmd = cmd;
			_opt = opt;
			_blocks = content;
		}
		
		protected function blen():int {
			if (this._blocks != null)
				return this._blocks.length;
			else
				return 0;
		}
		
		protected function clen():int {
			var rs:int = 0;
			var bl:int = blen();
			for (var i:int = 0; i < bl; i++) {
				rs += this._blocks[i].length();
			}
			return rs;
		}
		
		public function pack_size():int {
			if (this._blocks == null) {
				return 4;
			}
			return 4 + this._blocks.length + clen();
		}
		
		public function pack( buff:ByteArray ):void {
			var bl:int = blen();
			buff.writeByte(M_START_FLAG);
			buff.writeByte(this.cmd);
			buff.writeByte(this.opt);
			buff.writeByte(bl&0xff);
			var offset:int = 4;
			for (var i:int = 0; i < bl; i++) {
				var tmp:String = this._blocks[i];
				var len:int = tmp.length;
				buff.writeByte(len&0xff);
				buff.writeUTFBytes(tmp); 
			}
		}
	}
}