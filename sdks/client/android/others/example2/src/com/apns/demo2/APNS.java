/**
 * APNS.java
 * If you can't run this demo,
 * try to modify android:minSdkVersion in AndroidManifest.xml 
 * to right level.
 */

package com.apns.demo2;

import android.app.Activity;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.graphics.Color;
import android.os.Bundle;
import android.text.SpannableString;
import android.text.style.ForegroundColorSpan;
import android.view.View;
import android.view.View.OnClickListener;
import android.widget.Button;
import android.widget.TextView;

import com.apns.APNService;
import com.apns.demo2.R;

public class APNS extends Activity {

	private BroadcastReceiver mReceiver = new BroadcastReceiver() {
		public void onReceive(Context context, Intent intent) {
			String action = intent.getAction();
			String str = intent.getStringExtra("data");
			SpannableString text = null;
			if (action.equals(APNService.ON_NOTIFICATION)) {
				text =  new SpannableString("Notification: "+str);
				text.setSpan(new ForegroundColorSpan(Color.GREEN), 0, text.length(), 0);
			} else if (action.equals(APNService.ON_INFO)) {
				text =  new SpannableString("Info: "+str);
				text.setSpan(new ForegroundColorSpan(Color.WHITE), 0, text.length(), 0);
			} else if (action.equals(APNService.ON_ERR)) {
				text =  new SpannableString("Error: " + str);
				text.setSpan(new ForegroundColorSpan(Color.RED), 0, text.length(), 0);
			}
			TextView tv = (TextView) findViewById(R.id.txt_box);
			tv.append(text);
			tv.append("\n");
		}
	};


	@Override
	public void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		setContentView(R.layout.main);

		IntentFilter filter = new IntentFilter();
		filter.addAction(APNService.ON_NOTIFICATION);
		filter.addAction(APNService.ON_INFO);
		filter.addAction(APNService.ON_ERR);
		registerReceiver(mReceiver, filter);
	
		Button start = (Button) findViewById(R.id.start_btn);
		start.setOnClickListener(new OnClickListener() {
			public void onClick(View v) {
				// start apns service
				Intent intent = new Intent(APNService.START);
				intent.putExtra("ch", "test");   // channel name, 登录开发者页面查看
				intent.putExtra("devId", "pad"); // 请确保 devId 不为空, devId 可为任何标识此用户的
												 // String
				startService(intent);
				v.setEnabled(false);
			}
		});
	}

	
	@Override
	protected void onDestroy() {
		unregisterReceiver(mReceiver);
		//stop apns service
		Intent intent = new Intent(APNService.STOP);
		startService(intent);
		super.onDestroy();
	}
}