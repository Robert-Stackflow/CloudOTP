package com.cloudchewie.otp.appwidget;

import android.appwidget.AppWidgetManager;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;

public class SimpleRemoteViewsManager {
    public static void refresh(Context context) {
        refresh(context, MiniWidgetProvider.class);
        refresh(context, MiddleWidgetProvider.class);
        refresh(context, LargeWidgetProvider.class);
    }

    public static void refresh(Context context, Class<?> clazz) {
        AppWidgetManager appWidgetManager = AppWidgetManager.getInstance(context);
        int[] ids = appWidgetManager.getAppWidgetIds(new ComponentName(context, clazz));
        Intent updateIntent = new Intent(AppWidgetManager.ACTION_APPWIDGET_UPDATE);
        updateIntent.putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids);
        context.sendBroadcast(updateIntent);
    }
}
