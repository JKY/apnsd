package com.apns;

public class APNSMessage {

	public static final byte M_START_FLAG = 0x05;

	public static final byte CMD_RQ_JOIN = (byte) 0x01;
	public static final byte CMD_RQ_ECHO = (byte) 0x02;
	public static final byte CMD_RQ_NTY = (byte) 0x03;
	public static final byte CMD_RQ_LMT = (byte) 0x05;
	public static final byte CMD_RQ_RDRECT = (byte) 0x0f;

	public static final byte CMD_RP_JOIN = (byte) 0xf1;
	public static final byte CMD_RP_ECHO = (byte) 0xf2;
	public static final byte CMD_RP_NTY = (byte) 0xf3;
	public static final byte CMD_RP_RDRECT = (byte) 0xff;

	private byte _cmd;

	public byte cmd() {
		return _cmd;
	}

	private byte _opt;

	public byte opt() {
		return _opt;
	}

	private String[] _blocks;

	public String[] blocks() {
		return _blocks;
	}

	public APNSMessage(byte cmd, byte opt, String[] content) {
		this._cmd = cmd;
		this._opt = opt;
		this._blocks = content;
	}

	public int pack_size() {
		if (this._blocks == null) {
			return 4;
		}
		return 4 + this._blocks.length + clen();
	}

	protected int blen() {
		if (this._blocks != null)
			return this._blocks.length;
		else
			return 0;
	}

	protected int clen() {
		int rs = 0;
		int bl = blen();
		for (int i = 0; i < bl; i++) {
			rs += this._blocks[i].length();
		}
		return rs;
	}

	public void pack(byte buff[]) {
		int bl = blen();
		buff[0] = M_START_FLAG;
		buff[1] = this.cmd();
		buff[2] = this.opt();
		buff[3] = (byte)bl;
		int offset = 4;
		for (int i = 0; i < bl; i++) {
			byte[] tmp = this._blocks[i].getBytes();
			byte len = (byte) tmp.length;
			buff[offset++] = len;
			System.arraycopy(tmp, 0, buff, offset, len);
			offset += len;
		}
	}
}
