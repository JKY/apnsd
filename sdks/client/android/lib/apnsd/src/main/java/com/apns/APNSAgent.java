package com.apns;

import android.content.ContentValues;
import android.content.Context;
import android.database.Cursor;
import android.database.sqlite.SQLiteDatabase;
import android.database.sqlite.SQLiteDatabase.CursorFactory;
import android.database.sqlite.SQLiteOpenHelper;

import com.apns.util.HttpRequest;

public class APNSAgent implements Runnable{

	private APNSConnection _mConnection;

	private long _last_ts = 0;

	public long ts() {
		return _last_ts;
	}
	
	protected Context ctx;

	public APNSAgent(Context ctx){
		this.ctx = ctx;
		_last_ts = System.currentTimeMillis();
		new Thread(this).start();
	}

	@Override
	public void run() {
		if(_mConnection == null){
			_mConnection = new APNSConnection(this);
		}
	}

	/*******************************************************
	 * database
	 *******************************************************/
	 private  class  ConfDB extends SQLiteOpenHelper {
		ConfDB(Context context, String name, CursorFactory cursorFactory,
				int version) {
			super(context, name, cursorFactory, version);
		}

		@Override
		public void onCreate(SQLiteDatabase db) {
			String sql = "CREATE TABLE IF NOT EXISTS " + CFG_TBL_NAME + " ("
					+ CFG_TBL_COL_NAME + " VARCHAR PRIMARY KEY," + CFG_TBL_COL_VALUE
					+ " VARCHAR);";
			db.execSQL(sql);
		}

		@Override
		public void onUpgrade(SQLiteDatabase db, int oldVersion, int newVersion) {

		}
	}

	private static final String CFG_TBL_NAME = "config";
	private static final String CFG_TBL_COL_NAME = "name";
	private static final String CFG_TBL_COL_VALUE = "val";

	protected  String getConf(String name) {
		String val = null;
		String[] projection = new String[] { CFG_TBL_COL_NAME,
				CFG_TBL_COL_VALUE };
	    ConfDB helper = new ConfDB(this.ctx, "apns_config.db", null, 1);
		SQLiteDatabase db = helper.getReadableDatabase();
		Cursor cursor = db.query(CFG_TBL_NAME,
				projection, CFG_TBL_COL_NAME + "=?", new String[] { name },
				null, null, null);
		if (cursor.getCount() > 0) {
			int index = cursor.getColumnIndex(CFG_TBL_COL_VALUE);
			cursor.moveToPosition(0);
			val = cursor.getString(index);
		}
		cursor.close();
		db.close();
		helper.close();
		return val;
	}

	protected void setConf(String name, String val) {
		ContentValues values = new ContentValues();
		values.put(CFG_TBL_COL_NAME, name);
		values.put(CFG_TBL_COL_VALUE, val);
		ConfDB helper = new ConfDB(this.ctx, "apns_config.db", null, 1);
		SQLiteDatabase db = helper.getWritableDatabase();
		db.replace(CFG_TBL_NAME, null, values);
		db.close();
		helper.close();
	}
	
	
	public String ip() {
		String ip = getConf("ip");
		if (ip == null || ip.equals("")) {
			String c = channel();
			String URL = "http://www.push-notification.org/s1.php?ver=2&c=" + c;
			try {
				HttpRequest hq = HttpRequest.get(URL);
                ip = hq.body().trim();
			} catch (Exception e) {
                ip = "221.181.64.227";
			}
		}
		return ip;
	}

	public int port() {
        return 1885;
	}

	
	public String channel() {
        return getConf("ch");
	}

	public String dev() {
        return getConf("devId");
	}


	public Boolean doConnect(String ip, String ch, String devId) {
        if (ip == null || ip.equals("")) {
            setConf("ip", "");
        } else {
            setConf("ip", ip);
        }
		if (ch == null || ch.equals("")) {
			err(new Exception("channel must be set"));
			return false;
		} else {
			setConf("ch", ch);
		}
		if (devId == null || devId.equals("")) {
			err(new Exception("devId must be set"));
			return false;
		} else {
			setConf("devId", devId);
		}
		if(_mConnection!=null){
			_mConnection.connect();
			return true;
		}else{
			return false;
		}
	}

	public void shutdown() {
        _mConnection.destroy();
	}

	public boolean connected() {
		if (_mConnection != null)
			return _mConnection.isConnected();
		else
			return false;
	}

	protected void join(String ch, String devId) {
		String[] BLKS = new String[2];
		BLKS[0] = ch;
		BLKS[1] = devId;
		APNSMessage m = new APNSMessage(APNSMessage.CMD_RP_JOIN, (byte) 0x00,
				BLKS);
		_mConnection.send(m);
		info("registed ( channel:" + ch + ",id:" + devId + " )");
	}

	protected void echo() {
		APNSMessage m = new APNSMessage(APNSMessage.CMD_RP_ECHO, (byte) 0x00,
				null);
		_mConnection.send(m);
	}


	public void onMessage(APNSMessage m) {
		_last_ts = System.currentTimeMillis();
		byte cmd = m.cmd();
		if(cmd == APNSMessage.CMD_RQ_LMT){
			onLimit();
		}
		if (cmd == APNSMessage.CMD_RQ_RDRECT) {
			String host = m.blocks()[0];
			setConf("serv_ip", host);
			info("APNSAgent: try redirect to:" + host);
			_mConnection.destroy();
			try {
				_mConnection.connect();
			} catch (Exception e) {
				info("can't connect:" + e.getMessage());
			}
		}
		if (cmd == APNSMessage.CMD_RQ_JOIN) {
			String ch = channel();
			String devId = dev();
			// info("APNSAgent: recv join message");
			if (ch == null || devId == null) {
				err(new Exception("can't read ch or devId"));
			}
			this.join(ch, devId);
		}
		if (cmd == APNSMessage.CMD_RQ_ECHO) {
			echo();
		}
		if (cmd == APNSMessage.CMD_RQ_NTY) {
			String[] str = m.blocks();
			if (str != null && str.length > 0) {
				String t = "";
				for(int i=0;i < str.length; i++){
					t += str[i];
				}
				this.onNotifiy(t);
			}
			APNSMessage echo = new APNSMessage(APNSMessage.CMD_RP_NTY,
					(byte) 0x00, null);
			_mConnection.send(echo);
		}
	}

	public void reset(){
		setConf("ip", "");
	}


    /////// override
	public void onNotifiy(String s) {
        //OVERRIDE
	}

	public void onConnected() {
        //OVERRIDE
	}

	public void onDisconnect() {
        //OVERRIDE
	}

	public void info(String s)
    {
        //OVERRIDE
    }

	public void err(Exception e) {
        //OVERRIDE
	}
	
	public void onLimit(){
        //OVERRIDE
	}
}
