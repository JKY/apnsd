package com.apns;

import android.app.AlarmManager;
import android.app.PendingIntent;
import android.app.Service;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.net.ConnectivityManager;
import android.net.NetworkInfo;
import android.os.IBinder;
import android.util.Log;

import com.apns.service.APNHandler;

/* 
 * PushNotificationService that does all of the work.
 * Most of the logic is borrowed from KeepAliveService.
 */
public class APNService extends Service {

	public static final String ON_NOTIFICATION = "com.apns.APNService.NOTIFICATION";
	public static final String ON_CONNECTED = "com.apns.APNService.CONNECTED";
	public static final String ON_DISCONNECTED = "com.apns.APNService.DISCONNECTED";
	public static final String START = "com.apns.APNService.START";
	public static final String STOP = "com.apns.APNService.STOP";
	protected static final String RECONNECT = "com.apns.APNService.RECONNECT";
	private static final String TAG = "com.apns.Service";
	private static final long CHECK_INTERVAL = 6*10000; // 1 min
	private static final long PING_TIMEOUT = 6 * CHECK_INTERVAL;

    // Check if we are online
	private ConnectivityManager mConnMan = null;
    private boolean isNetworkAvailable() {
        if (mConnMan == null) {
            mConnMan = (ConnectivityManager) getSystemService(CONNECTIVITY_SERVICE);
        }
        NetworkInfo info = mConnMan.getActiveNetworkInfo();
        if (info == null) {
            return false;
        }
        return info.isConnected();
    }
    /**
     * monitor network stat changed
     */
    private BroadcastReceiver mConnectivityChanged = new BroadcastReceiver() {
        @Override
        public void onReceive(Context context, Intent intent) {
            // Get network info
            NetworkInfo info = intent
                    .getParcelableExtra(ConnectivityManager.EXTRA_NETWORK_INFO);
            // Is there connectivity?
            boolean hasConnectivity = (info != null && info.isConnected()) ? true
                    : false;
            if (hasConnectivity) {
                startSupervisor();
            }
        }
    };
    /**
     * state checking ....
     */
    private Boolean mChecking = false;
    private void startSupervisor() {
        if (mAgent.channel() == null || mAgent.dev() == null) {
            mAgent.info("exit with channel or dev is null...");
            stop();
            return;
        }
        long now = System.currentTimeMillis();
        if (!mAgent.connected() && (now - mAgent.ts() > PING_TIMEOUT) && isNetworkAvailable()) {
            // reconnect
            mAgent.doConnect(mAgent.ip(), mAgent.channel(), mAgent.dev());
        }
        Intent i = new Intent();
        i.setClass(this, this.getClass());
        i.setAction(RECONNECT);
        PendingIntent pi = PendingIntent.getService(this, 0, i, 0);
        AlarmManager alarmMgr = (AlarmManager) getSystemService(ALARM_SERVICE);
        alarmMgr.set(AlarmManager.RTC_WAKEUP, now + CHECK_INTERVAL, pi);
        mChecking = true;
    }

    // Remove the scheduled reconnect
    private void stopSupervisor() {
        Intent i = new Intent();
        i.setClass(this, APNService.class);
        i.setAction(RECONNECT);
        PendingIntent pi = PendingIntent.getService(this, 0, i, 0);
        AlarmManager alarmMgr = (AlarmManager) getSystemService(ALARM_SERVICE);
        alarmMgr.cancel(pi);
        mChecking = false;
    }





    private APNSAgent mAgent;
	private APNHandler mHandler;
    private IAPNDebugHandler mDebugHandler = null;
    public void setDebugHandler(IAPNDebugHandler d){
        mDebugHandler = d;
    }

	@Override
	public void onCreate() {
		super.onCreate();
		this.mAgent = new APNSAgent(this.getApplicationContext()) {
			@Override
			public void onNotifiy(String s) {
                if(mDebugHandler!=null){
                    mDebugHandler.info("message:"+s+"\n");
                }
                onReceived(s);
			}
			private boolean connected = false;

			@Override
			public void onConnected() {
				connected = true;
				//startSupervisor();
				Intent intent = new Intent(ON_CONNECTED);
				sendBroadcast(intent);
                if(mDebugHandler!=null){
                    mDebugHandler.connected();
                }
			}

			@Override
			public void onDisconnect() {
				if (connected)
					info("disconnected");
				if (mChecking)
					info("reconnect after "
							+ String.valueOf(PING_TIMEOUT) + "ms");
				Intent intent = new Intent(ON_DISCONNECTED);
				sendBroadcast(intent);
				super.onDisconnect();
				connected = false;
                if(mDebugHandler!=null){
                    mDebugHandler.disconnected();
                }
			}

			@Override
			public void info(String s) {
                if(mDebugHandler!=null){
                    mDebugHandler.info(s+"\n");
                }
				Log.i(TAG, s);
			}

			@Override
			public void err(Exception e) {
                if(mDebugHandler!=null){
                    mDebugHandler.info("error:" + e.getMessage()+"\n");
                }
                Log.e(TAG, e.getMessage());
			}

			@Override
			public void onLimit() {
				Log.i(TAG, "reach channel limits");
				stop();
				stopSelf();
			}
		};
        mConnMan = (ConnectivityManager) getSystemService(CONNECTIVITY_SERVICE);
        registerReceiver(mConnectivityChanged, new IntentFilter(
                ConnectivityManager.CONNECTIVITY_ACTION));

		// keep cpu no sleep
		/*
		 * if (wakeLock == null && _mOption == OPT_NO_SLEEP_MODE) { PowerManager
		 * pm = (PowerManager) getSystemService(Context.POWER_SERVICE); wakeLock
		 * = pm.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, this
		 * .getClass().getCanonicalName()); wakeLock.acquire(); }
		 */
	}

	protected void onReceived(String str) {
		if(mHandler == null){
			mHandler = new APNHandler(this.getApplicationContext(),mAgent);
		}
		if(!mHandler.process(str)){
			Intent intent = new Intent(ON_NOTIFICATION);
			intent.putExtra("data", str);
			sendBroadcast(intent);
		}
	}

    @Override
    public int onStartCommand(Intent intent, int flags, int startId){
        super.onStartCommand(intent, flags, startId);
        if (intent == null) {
            startSupervisor();
        } else {
            if (intent.getAction().equals(STOP) == true) {
                stop();
            } else if (intent.getAction().equals(START) == true) {
                String ip = intent.getStringExtra("ip");
                String ch = intent.getStringExtra("ch");
                String dev = intent.getStringExtra("devId");
                start(ip,ch,dev);
            } else if (intent.getAction().equals(RECONNECT) == true) {
                //if (isNetworkAvailable()) {
                startSupervisor();
                //}
            }
        }
        return Service.START_REDELIVER_INTENT;
    }

    /**
     *
     * @param ip
     * @param ch
     * @param devid
     */
    public synchronized boolean start(String ip,String ch, String devid){
        if (!mAgent.doConnect(ip, ch, devid)) {
            mAgent.err(new Exception("start failed"));
            return false;
        }else{
            startSupervisor();
        }
        return true;
    }

    /**
     *  stop service
     */
    public synchronized void stop() {
        stopSupervisor();
        if (mAgent.connected()) {
            mAgent.info("stopping ...");
            mAgent.shutdown();
        }
        if (this.mConnMan != null)
            unregisterReceiver(mConnectivityChanged);
        stopSelf();
    }

    @Override
    public IBinder onBind(Intent intent) {
        return new APNServiceBinder(this);
    }


    @Override
	public void onDestroy() {
		super.onDestroy();

	}
}
