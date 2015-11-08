/**
 * @version: 1.0.0
 */

package org.apns.demo1;
import android.app.Activity;
import android.content.Intent;
import android.os.Bundle;
import android.view.View;
import android.view.View.OnClickListener;
import android.widget.Button;
import android.widget.TextView;

import com.apns.APNService;

public class APNSDemo1 extends Activity {

	@Override
	protected void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		this.setContentView(R.layout.main);
		
		Button start = (Button) findViewById(R.id.start);
		start.setOnClickListener(new OnClickListener() {
			public void onClick(View v) {
				
				TextView devid = (TextView)findViewById(R.id.devid);
				String clientId = devid.getText().toString();
				if(clientId.equals(""))
					return;
				/* 启动服务 */
				Intent intent = new Intent(APNService.START); 
				intent.putExtra("ch", "test");
				intent.putExtra("devId", clientId);   
				intent.putExtra("noCache", true); 
				startService(intent);
				v.setEnabled(false);
				devid.setEnabled(false);
			}
		});
		
		Button stop = (Button) findViewById(R.id.stop);
		stop.setOnClickListener(new OnClickListener() {
			public void onClick(View v) {
				/* 停止 */
				Intent intent = new Intent(APNService.STOP); 
				startService(intent);
				finish();
			}
		});
	}
}
