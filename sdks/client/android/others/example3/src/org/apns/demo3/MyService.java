package org.apns.demo3;

import android.content.Intent;

import com.apns.APNService;

public class MyService extends APNService {
	public static final String ON_NTY = "org.apns.demo.MyService.ON_NTY";
	public static final String START = "org.apns.demo.MyService.START";
	public static final String STOP = "org.apns.demo.MyService.STOP";
	
	
	@Override
	public void onStart(Intent intent, int startId) {
		Intent i = null;
		if(intent!=null){
			if (intent.getAction().equals(MyService.START) == true) {
				i = new Intent(APNService.START);
				String dev = intent.getStringExtra("devId");
				String ch = intent.getStringExtra("ch");
				i.putExtra("ch", ch);  
				i.putExtra("devId", dev); 
			}else if(intent.getAction().equals(MyService.STOP) == true){
				i = new Intent(APNService.STOP);
			}else{
				i = intent;
			}
		}
		super.onStart(i, startId);
	}


	@Override
	protected void onRecvNty(String str) {
		Intent intent = new Intent(ON_NTY);
		intent.putExtra("data", str);
		sendBroadcast(intent);
	}
	
}
