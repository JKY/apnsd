package org.apns.demo1;

import org.apns.demo1.R;

import android.app.Notification;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;

import com.apns.APNService;

public class MyBroadcastReceiver extends BroadcastReceiver {
	public void onReceive(Context context, Intent intent) {
		if (intent.getAction().equals(APNService.ON_NOTIFICATION)) {
			String str = intent.getStringExtra("data"); 
			showNotification(context,str);
		}
	}

	private void showNotification(Context context,String s) {
		NotificationManager mNotificationManager = (NotificationManager)context.getSystemService(Context.NOTIFICATION_SERVICE);
		long when = System.currentTimeMillis();
		Intent notificationIntent = new Intent(context,APNSDemo1.class);
		PendingIntent contentIntent = PendingIntent.getActivity(context, 0,
				notificationIntent, 0);
		Notification notification = new Notification(R.drawable.ic_launcher, "Received Notification", when);
		notification.defaults = Notification.DEFAULT_VIBRATE;
		notification.setLatestEventInfo(context, "Received Notification","example1:"+ s,
				contentIntent);
		notification.flags |= Notification.FLAG_AUTO_CANCEL;
		mNotificationManager.notify(0, notification);
	}
}
