package com.cloudchewie.util.system;

import static com.cloudchewie.util.basic.DateFormatUtil.MD_FORMAT_WITH_BAR;

import android.content.Context;

import com.cloudchewie.util.basic.DateFormatUtil;

import java.util.Date;

/**
 * APP启动判断工具类
 */
public class AppStartUpUtil {
    private static String DEFAULT_STARTUP_DAY = "2023-01-01";

    /**
     * 判断是否是首次启动
     */
    public static boolean isFirstStartApp(Context context) {
        boolean isFirst = SharedPreferenceUtil.getBoolean(context, SharedPreferenceCode.APP_FIRST_START.getKey(), true);
        if (isFirst) {
            SharedPreferenceUtil.putBoolean(context, SharedPreferenceCode.APP_FIRST_START.getKey(), false);
            return true;
        } else {
            return false;
        }
    }

    /**
     * 判断是否是今日首次启动APP
     */
    public static boolean isTodayFirstStartApp(Context context) {
        String defaultDay = SharedPreferenceUtil.getString(context, SharedPreferenceCode.START_UP_APP_TIME.getKey(), DEFAULT_STARTUP_DAY);
        String today = DateFormatUtil.getSimpleDateFormat(MD_FORMAT_WITH_BAR).format(new Date());
        if (!defaultDay.equals(today)) {
            SharedPreferenceUtil.putString(context, SharedPreferenceCode.START_UP_APP_TIME.getKey(), today);
            return true;
        } else {
            return false;
        }
    }
}
