package com.cloudchewie.util.system;

import android.content.Context;
import android.content.SharedPreferences;

import androidx.annotation.NonNull;
import androidx.annotation.StyleRes;

import com.alibaba.fastjson.JSON;

import org.jetbrains.annotations.Contract;

import java.util.List;

/**
 * SharedPreferences工具类
 */
public class SharedPreferenceUtil {
    private static final String NAME = "config";

    public static int getThemeId(@NonNull Context context, int defaultId) {
        int id = SharedPreferenceUtil.getInt(context, SharedPreferenceCode.THEME_ID.getKey(), -1);
        if (id == -1) {
            setThemeId(context, defaultId);
            return defaultId;
        } else {
            return id;
        }
    }

    public static void setThemeId(@NonNull Context context, @StyleRes int themeId) {
        SharedPreferenceUtil.putInt(context, SharedPreferenceCode.THEME_ID.getKey(), themeId);
    }

    public static void putBoolean(@NonNull Context context, String key, boolean value) {
        SharedPreferences sp = context.getSharedPreferences(NAME, Context.MODE_PRIVATE);
        sp.edit().putBoolean(key, value).apply();
    }

    public static boolean getBoolean(@NonNull Context context, String key, boolean defValue) {
        SharedPreferences sp = context.getSharedPreferences(NAME, Context.MODE_PRIVATE);
        return sp.getBoolean(key, defValue);
    }

    public static void putString(@NonNull Context context, String key, String value) {
        SharedPreferences sp = context.getSharedPreferences(NAME, Context.MODE_PRIVATE);
        sp.edit().putString(key, value).apply();
    }

    @Contract("null, _, _ -> !null")
    public static String getString(Context context, String key, String defValue) {
        if (context != null) {
            SharedPreferences sp = context.getSharedPreferences(NAME, Context.MODE_PRIVATE);
            return sp.getString(key, defValue);
        }
        return "";
    }

    public static void putInt(@NonNull Context context, String key, int value) {
        SharedPreferences sp = context.getSharedPreferences(NAME, Context.MODE_PRIVATE);
        sp.edit().putInt(key, value).apply();
    }

    public static int getInt(@NonNull Context context, String key, int defValue) {
        SharedPreferences sp = context.getSharedPreferences(NAME, Context.MODE_PRIVATE);
        return sp.getInt(key, defValue);
    }

    public static void remove(@NonNull Context context, String key) {
        SharedPreferences sp = context.getSharedPreferences(NAME, Context.MODE_PRIVATE);
        sp.edit().remove(key).apply();
    }

    public static void putObject(@NonNull Context context, String key, Object object) {
        putString(context, key, JSON.toJSONString(object));
    }

    public static Object getObject(@NonNull Context context, String key, Class<?> clazz) {
        return JSON.parseObject(getString(context, key, ""), clazz);
    }

    public static void putArray(@NonNull Context context, String key, List<Object> objects) {
        putString(context, key, JSON.toJSONString(objects));
    }

    public static List<Object> getArray(@NonNull Context context, String key, Class<Object> clazz) {
        return JSON.parseArray(getString(context, key, ""), clazz);
    }

    public static void putStringArray(@NonNull Context context, String key, List<String> strings) {
        putString(context, key, JSON.toJSONString(strings));
    }

    public static List<String> getStringArray(@NonNull Context context, String key) {
        return JSON.parseArray(getString(context, key, ""), String.class);
    }
}
