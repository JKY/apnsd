/**
 * @version: 1.0.0
 * 
 */

package org.apns.demo3;
import org.apns.demo3.R;

import com.apns.APNService;

import android.app.Activity;
import android.content.Intent;
import android.os.Bundle;
import android.view.View;
import android.view.View.OnClickListener;
import android.widget.Button;

public class APNSDemo3 extends Activity {

	@Override
	protected void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		this.setContentView(R.layout.main);
		
		Button start = (Button) findViewById(R.id.start);
		start.setOnClickListener(new OnClickListener() {
			public void onClick(View v) {
				/* 启动服务 */
				Intent intent = new Intent(MyService.START);
				// channel name, 登录开发者页面查看
				intent.putExtra("ch", "C50a5aa51dd4af");  
				// 请确保 devId 不为空, devId 可为任何标识此用户的 String
				intent.putExtra("devId", "355067045224706");    
				startService(intent);
				/* 停止服务 */
				//Intent intent = new Intent(MyService.STOP);
				//startService(intent);
				v.setEnabled(false);
			}
		});
		
		Button stop = (Button) findViewById(R.id.stop);
		stop.setOnClickListener(new OnClickListener() {
			public void onClick(View v) {
				/* 停止 */
				//Intent intent = new Intent(MyService.STOP); 
				//startService(intent);
				finish();
			}
		});
	}
	

}
