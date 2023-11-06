package com.cloudchewie.otp.util.database;

import static java.lang.Math.max;
import static java.lang.Math.min;

import android.content.Context;
import android.content.SharedPreferences;

import androidx.annotation.NonNull;

import com.cloudchewie.otp.util.enumeration.ViewType;
import com.cloudchewie.util.system.SharedPreferenceCode;
import com.cloudchewie.util.system.SharedPreferenceUtil;
import com.cloudchewie.util.ui.DarkModeUtil;

/**
 * SharedPreferences工具类
 */
public class AppSharedPreferenceUtil {
    private static final String NAME = "config";

    public static boolean isAutoDaynight(@NonNull Context context) {
        return SharedPreferenceUtil.getBoolean(context, SharedPreferenceCode.AUTO_DAYNIGHT.getKey(), true);
    }

    public static ViewType getViewType(@NonNull Context context) {
        SharedPreferences sp = context.getSharedPreferences(NAME, Context.MODE_PRIVATE);
        return ViewType.values()[min(ViewType.values().length, max(sp.getInt(SharedPreferenceCode.VIEW_TYPE.getKey(), 0), 0))];
    }

    public static void setViewType(@NonNull Context context, ViewType viewType) {
        SharedPreferenceUtil.putInt(context, SharedPreferenceCode.VIEW_TYPE.getKey(), viewType.ordinal());
    }

    public static boolean isNight(@NonNull Context context) {
        return SharedPreferenceUtil.getBoolean(context, SharedPreferenceCode.IS_NIGHT.getKey(), DarkModeUtil.isDarkMode(context));
    }

    public static void setAutoDaynight(@NonNull Context context, boolean isAutoDaynight) {
        SharedPreferenceUtil.putBoolean(context, SharedPreferenceCode.AUTO_DAYNIGHT.getKey(), isAutoDaynight);
    }

    public static void setNight(@NonNull Context context, boolean isNight) {
        SharedPreferenceUtil.putBoolean(context, SharedPreferenceCode.IS_NIGHT.getKey(), isNight);
    }
}
