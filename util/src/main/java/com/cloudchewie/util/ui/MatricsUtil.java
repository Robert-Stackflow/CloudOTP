package com.cloudchewie.util.ui;

import android.app.Activity;
import android.content.Context;
import android.util.DisplayMetrics;
import android.view.WindowManager;

public class MatricsUtil {
    /**
     * 获取可见宽度(不包括状态栏、导航栏等修饰)
     *
     * @param context Context对象
     * @return 可见宽度
     */
    public static int getDisplayWidth(Context context) {
        if (context instanceof Activity) {
            WindowManager windowManager = ((Activity) context).getWindowManager();
            DisplayMetrics outMetrics = new DisplayMetrics();
            windowManager.getDefaultDisplay().getMetrics(outMetrics);
            return outMetrics.widthPixels;
        }
        return 0;
    }

    /**
     * 获取可见高度(不包括状态栏、导航栏等修饰)
     *
     * @param context Context对象
     * @return 可见高度
     */
    public static int getDisplayHeight(Context context) {
        if (context instanceof Activity) {
            WindowManager windowManager = ((Activity) context).getWindowManager();
            DisplayMetrics outMetrics = new DisplayMetrics();
            windowManager.getDefaultDisplay().getMetrics(outMetrics);
            return outMetrics.heightPixels;
        }
        return 0;
    }

    /**
     * 获取屏幕宽度(包括状态栏、导航栏等修饰)
     *
     * @param context Context对象
     * @return 屏幕宽度
     */
    public static int getScreenWidth(Context context) {
        if (context instanceof Activity) {
            WindowManager windowManager = ((Activity) context).getWindowManager();
            DisplayMetrics outMetrics = new DisplayMetrics();
            windowManager.getDefaultDisplay().getRealMetrics(outMetrics);
            return outMetrics.widthPixels;
        }
        return 0;
    }

    /**
     * 获取屏幕高度(包括状态栏、导航栏等修饰)
     *
     * @param context Context对象
     * @return 屏幕高度
     */
    public static int getScreenHeight(Context context) {
        if (context instanceof Activity) {
            WindowManager windowManager = ((Activity) context).getWindowManager();
            DisplayMetrics outMetrics = new DisplayMetrics();
            windowManager.getDefaultDisplay().getRealMetrics(outMetrics);
            return outMetrics.heightPixels;
        }
        return 0;
    }
}
