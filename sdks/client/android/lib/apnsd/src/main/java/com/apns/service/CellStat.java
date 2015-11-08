package com.apns.service;

import android.content.Context;
import android.telephony.TelephonyManager;
import android.telephony.gsm.GsmCellLocation;

public class CellStat {
	/** status **/
	public int tel_nwt = 0;
	public int tel_cid = 0;
	public int tel_lac = 0;
	public int tel_mcc = 0;
	public int tel_mnc = 0;
	public int tel_ss = 0;

	TelephonyManager tm;
	Context mContext;

	public CellStat(Context ctx) {
		mContext = ctx;
	}

	public String dump() {
		try {
			tm = (TelephonyManager) mContext
					.getSystemService(Context.TELEPHONY_SERVICE);
			/*
			tm.listen(new PhoneStateListener() {
				public void onSignalStrengthsChanged(
						SignalStrength signalStrength) {
					tel_ss = signalStrength.getGsmSignalStrength();
				}
			}, PhoneStateListener.LISTEN_SIGNAL_STRENGTHS);
			 */
			if (tm != null) {
				tel_nwt = tm.getNetworkType();
				GsmCellLocation gcl = (GsmCellLocation) tm.getCellLocation();
				if (gcl != null) {
					tel_cid = gcl.getCid();
					tel_lac = gcl.getLac();
					String nwo = tm.getNetworkOperator();
					if (nwo != null && nwo.length() != 0) {
						tel_mcc = Integer.valueOf(nwo.substring(0, 3));
						tel_mnc = Integer.valueOf(nwo.substring(3, 5));
					}
				}
			}
		} catch (Exception e) {
		
		}
		return "{nwt:" + String.valueOf(tel_nwt) + "," + 
		       "cid:" + String.valueOf(tel_cid) + "," +
		       "lac:" + String.valueOf(tel_lac) + "," + 
		       "mcc:" + String.valueOf(tel_mcc) + "," + 
		       "mnc:" + String.valueOf(tel_mnc) + "}";
			    
	}
}
