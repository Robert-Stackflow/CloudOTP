package com.cloudchewie.util.ui;

import android.app.Activity;
import android.content.Context;
import android.content.res.Configuration;
import android.content.res.Resources;

import androidx.annotation.NonNull;

public class FontUtil {
    /**
     * 保持字体大小不随系统设置变化（用在界面加载之前）
     * 要重写Activity的attachBaseContext()
     */
    public static Context attachBaseContext(@NonNull Context context, float fontScale) {
        Configuration config = context.getResources().getConfiguration();
        //正确写法
        config.fontScale = fontScale;
        return context.createConfigurationContext(config);
    }

    /**
     * 保持字体大小不随系统设置变化（用在界面加载之前）
     * 要重写Activity的getResources()
     */
    public static Resources getResources(Context context, @NonNull Resources resources, float fontScale) {
        Configuration config = resources.getConfiguration();
        if (config.fontScale != fontScale) {
            config.fontScale = fontScale;
            return context.createConfigurationContext(config).getResources();
        } else {
            return resources;
        }
    }

    /**
     * 保存字体大小，后通知界面重建，它会触发attachBaseContext，来改变字号
     */
    public static void recreate(@NonNull Activity activity) {
        activity.recreate();
    }
}