package com.apns;

import java.io.DataInputStream;
import java.io.DataOutputStream;
import java.io.IOException;
import java.net.InetSocketAddress;
import java.net.Socket;

public class APNSConnection implements Runnable {

	private Socket _sock;
	private DataInputStream _in;
	private DataOutputStream _out;
	private static boolean  _running = false;
	private APNSAgent _agent;


	public APNSConnection(APNSAgent agent) {
		_agent = agent;
	}

	synchronized public void connect() {
		if (_running){
			return;
		}
		_running = true;
		new Thread(this).start();
	}

	public Boolean isConnected() {
		if (_sock == null)
			return false;
		return _sock.isConnected();
	}

	/**
	 * message state
	 */
	private static final int M_START = 0;
	private static final int M_CMD = 1;
	private static final int M_OPT = 2;
	private static final int M_BLK_C = 3;
	private static final int M_BLK_START = 4;
	private static final int M_BLK = 5;
	// current message state
	private int M_CURR_ST = M_START;

	private byte cmd = 0x00;
	private byte opt = 0x00;
	private int blk_len = 0x00;
	private int blk_readed = 0;
	private int blk_data_len = 0;
	private int blk_data_readed = 0;

	private void rst_state() {
		cmd = 0x00;
		opt = 0x00;
		blk_len = 0x00;
		blk_readed = 0;
		blk_data_len = 0;
		blk_data_readed = 0;
		M_CURR_ST = M_START;
	}

	public void run() {
		byte blk_data[] = new byte[256];
		String[] blks = null;
		byte buffer[] = new byte[2<<16];
		try {
			String hostName = this._agent.ip();
			int port = this._agent.port();
			_agent.info("connecting to " + hostName + ":"
					+ String.valueOf(port) + "...");
			_sock = new Socket();
			_sock.connect(new InetSocketAddress(hostName, port), 20000); //
			_sock.setKeepAlive(true);
			_in = new DataInputStream(_sock.getInputStream());
			_out = new DataOutputStream(_sock.getOutputStream());
			_agent.info("connected");
			_agent.onConnected();
			while (_running) {
				int n = _in.read(buffer);
				if (n == -1) {
					break;
				}
				// _agent.info("APNSConnection:recv data:" + String.valueOf(n));
				for (int i = 0; i < n; i++) {
					switch (M_CURR_ST) {
					case M_START:
						if (buffer[i] == APNSMessage.M_START_FLAG) {
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
						blk_len = (int) buffer[i] & 0xff;
						if (blk_len > 0) {
							blks = new String[blk_len];
							M_CURR_ST = M_BLK_START;
						} else {
							APNSMessage m = new APNSMessage(cmd, opt, null);
							_agent.onMessage(m);
							rst_state();
						}
						break;
					case M_BLK_START:
						blk_data_len = (int) buffer[i] & 0xff;
						blk_data_readed = 0;
						M_CURR_ST = M_BLK;
						break;
					case M_BLK:
						if (blk_data_readed < blk_data_len) {
							blk_data[blk_data_readed++] = buffer[i];
						}
						if (blk_data_readed == blk_data_len) {
							blks[blk_readed] = new String(blk_data, 0,
									blk_data_len);
							blk_readed++;
							if (blk_readed < blk_len) {
								M_CURR_ST = M_BLK_START;
							} else {
								APNSMessage m = new APNSMessage(cmd, opt, blks);
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
		} catch (Exception e) {
			if(_running){
				_agent.reset();
				_agent.err(e);
			}
		}
		close();
		_agent.onDisconnect();
	}

	private void close() {
		_running = false;
		try {
			_in.close();
			_out.close();
			_sock.close();
		} catch (Exception e) {

		} finally {
			_sock = null;
		}
	}

	public void destroy() {
		close();
	}

	protected void send(APNSMessage m) {
		int sz = m.pack_size();
		byte[] buff = new byte[sz];
		m.pack(buff);
		try {
			_out.write(buff);
			// _agent.info("APNSConnection:ack data sended");
		} catch (IOException e) {
			_agent.err(e);
		}
	}
}
