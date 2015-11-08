package com.apns.service;

import android.content.Context;
import android.net.wifi.ScanResult;
import android.net.wifi.WifiConfiguration;
import android.net.wifi.WifiInfo;
import android.net.wifi.WifiManager;

public class WifiStat {
	private WifiManager mWifiManager;  
    private WifiInfo mWifiInfo; 
    
	public WifiStat(Context mCtx) {
		mWifiManager = (WifiManager) mCtx.getSystemService(Context.WIFI_SERVICE);  
        mWifiInfo = mWifiManager.getConnectionInfo(); 
	}
	 
    public String GetMacAddress()  {  
        return (mWifiInfo == null) ? "NULL" : mWifiInfo.getMacAddress();  
    }
    
    /** TODO **/
    public int ChanneNum()  { 
    	 if (mWifiInfo == null || mWifiInfo.getBSSID() == null){
         	return -1;
         }else{
        	 int speed = mWifiInfo.getLinkSpeed();
        	 String units = WifiInfo.LINK_SPEED_UNITS;
        	 return 0;
         } 
    }
    
    /** TODO **/
    public int SNR()  { 
    	return 0;
    }
    
    public int SS()  {  
        if (mWifiInfo == null || mWifiInfo.getBSSID() == null){
        	return 0;
        }else{
        	return WifiManager.calculateSignalLevel(mWifiInfo.getRssi(), 5);
        }
    }
    
}
