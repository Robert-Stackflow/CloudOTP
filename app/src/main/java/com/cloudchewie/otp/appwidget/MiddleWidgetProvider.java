package com.cloudchewie.otp.appwidget;

import android.app.AlarmManager;
import android.app.PendingIntent;
import android.appwidget.AppWidgetManager;
import android.appwidget.AppWidgetProvider;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.os.SystemClock;
import android.util.Log;
import android.widget.RemoteViews;

import com.cloudchewie.otp.R;

public class MiddleWidgetProvider extends AppWidgetProvider {

    public static final String CLICK_ACTION = "com.cloudchewie.otp.click";
    public static final String EXTRA_ITEM = "com.cloudchewie.otp.item";

    @Override
    public void onReceive(Context context, Intent intent) {
        super.onReceive(context, intent);
        AppWidgetManager appWidgetManager = AppWidgetManager.getInstance(context);
        ComponentName componentName = new ComponentName(context, MiddleWidgetProvider.class);
        if (intent.getAction().equals(AppWidgetManager.ACTION_APPWIDGET_UPDATE) || intent.getAction().equals(CLICK_ACTION)) {
            for (int appWidgetId : appWidgetManager.getAppWidgetIds(componentName)) {
//                updateWidget(context, appWidgetManager, appWidgetId);
                appWidgetManager.notifyAppWidgetViewDataChanged(appWidgetId, R.id.layout_widget_grid_view);
            }
        }
    }

    @Override
    public void onEnabled(Context context) {
        super.onEnabled(context);
    }

    @Override
    public void onAppWidgetOptionsChanged(Context context, AppWidgetManager appWidgetManager, int appWidgetId, Bundle newOptions) {
        updateWidget(context, appWidgetManager, appWidgetId);
        super.onAppWidgetOptionsChanged(context, appWidgetManager, appWidgetId, newOptions);
    }

    @Override
    public void onUpdate(Context context, AppWidgetManager appWidgetManager, int[] appWidgetIds) {
        for (int appWidgetId : appWidgetIds)
            updateWidget(context, appWidgetManager, appWidgetId);
        super.onUpdate(context, appWidgetManager, appWidgetIds);
    }

    private static int getCellsForSize(int size) {
        int n = 2;
        while (72 * n < size) {
            ++n;
        }
        return n - 1;
    }

    private static int getResponsiveLayoutId(int width) {
        if (width < 200) {
            return R.layout.layout_widget_single_column;
        } else {
            return R.layout.layout_widget_double_column;
        }
    }

    public static void updateWidget(Context context, AppWidgetManager appWidgetManager, int appWidgetId) {
        Bundle options = appWidgetManager.getAppWidgetOptions(appWidgetId);
        int minHeight = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT);
        int minWidth = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_WIDTH);
        int responsiveLayoutId = getResponsiveLayoutId(minWidth);
        int rows = getCellsForSize(minHeight);
        RemoteViews remoteViews = new RemoteViews(context.getPackageName(), responsiveLayoutId);
        //加载数据
        Intent serviceIntent = new Intent(context, SimpleRemoteViewsService.class);
        serviceIntent.putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId);
        serviceIntent.setData(Uri.parse(serviceIntent.toUri(Intent.URI_INTENT_SCHEME)));
        remoteViews.setRemoteAdapter(R.id.layout_widget_grid_view, serviceIntent);
        remoteViews.setEmptyView(R.id.layout_widget_grid_view, R.id.layout_widget_empty_view);
        //列表点击事件
        Intent clickIntent = new Intent(context, MiddleWidgetProvider.class).setAction(CLICK_ACTION);
        PendingIntent pendingIntent = PendingIntent.getBroadcast(context, 0, clickIntent, PendingIntent.FLAG_IMMUTABLE | PendingIntent.FLAG_UPDATE_CURRENT);
        remoteViews.setPendingIntentTemplate(R.id.layout_widget_grid_view, pendingIntent);
        appWidgetManager.updateAppWidget(appWidgetId, remoteViews);
        //定时刷新
        int interval = 60 * 1000;
        long triggerAtTime = SystemClock.elapsedRealtime() + interval;
        AlarmManager alarmMgr = (AlarmManager) context.getSystemService(Context.ALARM_SERVICE);
        alarmMgr.setRepeating(AlarmManager.RTC, triggerAtTime, interval, pendingIntent);
    }

    @Override
    public void onDeleted(Context context, int[] appWidgetIds) {
        super.onDeleted(context, appWidgetIds);
    }

    @Override
    public void onDisabled(Context context) {
        super.onDisabled(context);
    }
}