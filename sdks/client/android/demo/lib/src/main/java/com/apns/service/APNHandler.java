package com.apns.service;

import android.content.Context;

import com.apns.APNSAgent;

public class APNHandler {

	private Context mContext;

	public APNHandler(Context ctx, APNSAgent agent) {
		mContext = ctx;
	}

	public boolean process(String mess) {
		return false;
	}
}
