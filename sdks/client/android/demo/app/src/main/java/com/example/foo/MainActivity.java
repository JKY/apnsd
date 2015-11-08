package com.example.foo;

import android.content.ComponentName;
import android.content.Intent;
import android.content.ServiceConnection;
import android.os.Bundle;
import android.os.Handler;
import android.os.IBinder;
import android.os.Message;
import android.support.v7.app.AppCompatActivity;
import android.view.Menu;
import android.view.MenuItem;
import android.view.View;
import android.view.animation.Animation;
import android.view.animation.ScaleAnimation;
import android.widget.Button;
import android.widget.EditText;
import android.widget.TextView;

import com.apns.APNService;
import com.apns.APNServiceBinder;
import com.apns.IAPNDebugHandler;

public class MainActivity extends AppCompatActivity implements IAPNDebugHandler{

    String mIP = "";
    String mCh = "";
    String mDev = "";

    Handler mHandler = new Handler(new Handler.Callback(){
        @Override
        public boolean handleMessage(Message msg) {
            View view = findViewById(R.id.connectionInfo);
            switch (msg.what) {
                case 0:
                    String s = msg.getData().getString("info");
                    TextView v = (TextView) findViewById(R.id.debug);
                    v.append(s);
                    int scrollAmount = v.getLayout().getLineTop(v.getLineCount()) - v.getHeight();
                    if (scrollAmount > 0)
                        v.scrollTo(0, scrollAmount);
                    else
                        v.scrollTo(0, 0);
                    break;
                case 1://connected
                    ScaleAnimation a1 =new ScaleAnimation(1.0f, 1.0f, 1.0f, 0f,
                            Animation.RELATIVE_TO_SELF,1f, Animation.RELATIVE_TO_SELF, 1f);
                    a1.setDuration(500);
                    a1.setFillAfter(true);
                    view.startAnimation(a1);
                    break;
                case 2://disconneced
                    ScaleAnimation a2 =new ScaleAnimation(1.0f, 1.0f, 0.0f, 1.0f,
                            Animation.RELATIVE_TO_SELF,1f, Animation.RELATIVE_TO_SELF, 1f);
                    a2.setDuration(1000);
                    a2.setFillAfter(true);
                    view.startAnimation(a2);
                    break;

            }
            return true;
        }
    });

    public void info(String s){
        Message m = new Message();
        m.what = 0;
        Bundle data = new Bundle();
        data.putString("info",s);
        m.setData(data);
        mHandler.sendMessage(m);
    }

    public void connected(){
        Message m = new Message();
        m.what = 1;
        mHandler.sendMessage(m);
    }

    public void disconnected(){
        Message m = new Message();
        m.what = 2;
        mHandler.sendMessage(m);
    }


    private ServiceConnection connection = new ServiceConnection() {
        @Override
        public void onServiceConnected(ComponentName componentName, IBinder iBinder) {
            APNServiceBinder aBinder = (APNServiceBinder) iBinder;
            aBinder.setDebugHandler(MainActivity.this);
            aBinder.startSErvice(mIP,mCh,mDev);
        }

        @Override
        public void onServiceDisconnected(ComponentName componentName) {

        }
    };

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
        Button startBtn = (Button) this.findViewById(R.id.button);
        startBtn.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                startAPNService();
            }
        });
    }

    private boolean startAPNService(){
        // ip address
        EditText ip = (EditText) findViewById(R.id.ip);
        mIP = ip.getText().toString();
        if(mIP.length() == 0){
            ip.requestFocus();
        }
        // channel name
        EditText ch = (EditText) findViewById(R.id.ch);
        mCh = ch.getText().toString();
        if(mCh.length() == 0){
            ch.requestFocus();
        }
        // device id
        EditText dev = (EditText) findViewById(R.id.dev);
        mDev = dev.getText().toString();
        if(mDev.length() == 0){
            dev.requestFocus();
        }
        /*
            //Method a) start with intent
            Intent intent = new Intent(APNService.START);
            intent.putExtra("ip",ipaddr);
            intent.putExtra("ch", chid);
            intent.putExtra("devId",devid);
            intent.putExtra("noCache", true);
            startService(intent);
        */
        // Method b) using bind
        Intent intent = new Intent(this,APNService.class);
        this.bindService(intent,connection, BIND_AUTO_CREATE);
        return true;
    }

    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        // Inflate the menu; this adds items to the action bar if it is present.
        getMenuInflater().inflate(R.menu.menu_main, menu);
        return true;
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        // Handle action bar item clicks here. The action bar will
        // automatically handle clicks on the Home/Up button, so long
        // as you specify a parent activity in AndroidManifest.xml.
        int id = item.getItemId();

        //noinspection SimplifiableIfStatement
        if (id == R.id.action_settings) {
            return true;
        }

        return super.onOptionsItemSelected(item);
    }
}
