package com.apns;


public interface IAPNDebugHandler {
    void info(String s);

    void connected();

    void disconnected();
}
