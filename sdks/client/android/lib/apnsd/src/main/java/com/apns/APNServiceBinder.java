package com.apns;

import android.os.Binder;


public class APNServiceBinder extends Binder{

    APNService mService = null;
    public APNServiceBinder(APNService service){
        mService = service;
    }

    /**
     * set debug handler
     * @param
     */
    public void setDebugHandler(IAPNDebugHandler handler){
        mService.setDebugHandler(handler);
    }

    /**
     * start apns service
     * @param ip, ip address
     * @param ch, channel name
     * @param dev, device id
     */
    public void startSErvice(String ip, String ch, String dev){
        mService.start(ip,ch,dev);
    }

    /**
     * stop apns service
     */
    public void stopService(){
        mService.stop();
    }
}
