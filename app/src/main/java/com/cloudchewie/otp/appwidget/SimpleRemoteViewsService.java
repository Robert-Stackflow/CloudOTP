package com.cloudchewie.otp.appwidget;

import android.content.Intent;
import android.util.Log;
import android.widget.RemoteViewsService;

public class SimpleRemoteViewsService extends RemoteViewsService {
    @Override
    public RemoteViewsFactory onGetViewFactory(Intent intent) {
        Log.d("xuruida", intent.toString());
        return new SimpleRemoteViewsFactory(this.getApplicationContext(), intent);
    }
}
