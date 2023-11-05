/*
 * Project Name: Worthy
 * Author: Ruida
 * Last Modified: 2022/12/19 14:25:09
 * Copyright(c) 2022 Ruida https://cloudchewie.com
 */

package com.cloudchewie.otp.activity;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.pm.ActivityInfo;
import android.content.res.Configuration;
import android.content.res.Resources;
import android.net.ConnectivityManager;
import android.os.Bundle;
import android.view.WindowManager;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.appcompat.app.AppCompatActivity;

import com.cloudchewie.otp.R;
import com.cloudchewie.otp.util.NetWorkStateReceiver;
import com.cloudchewie.otp.util.enumeration.EventBusCode;
import com.cloudchewie.util.system.SharedPreferenceCode;
import com.cloudchewie.util.system.SharedPreferenceUtil;
import com.cloudchewie.util.ui.DarkModeUtil;
import com.cloudchewie.util.ui.FontUtil;
import com.cloudchewie.util.ui.StatusBarUtil;
import com.jeremyliao.liveeventbus.LiveEventBus;

import java.util.Objects;

public class BaseActivity extends AppCompatActivity {
    static float fontScale = 1f;
    BroadcastReceiver broadcastReceiver;
    NetWorkStateReceiver netWorkStateReceiver;
    private Configuration mConfiguration;

    @Override
    public Resources getResources() {
        Resources resources = super.getResources();
        return FontUtil.getResources(this, resources, fontScale);
    }

    @Override
    protected void attachBaseContext(Context newBase) {
        super.attachBaseContext(FontUtil.attachBaseContext(newBase, fontScale));
    }

    public void setFontScale(float fontScale) {
        BaseActivity.fontScale = fontScale;
        FontUtil.recreate(this);
    }

    public void initSafeMode() {
        if (SharedPreferenceUtil.getBoolean(this, SharedPreferenceCode.TOKEN_DISBALE_SCREENSHOT.getKey(), true)) {
            getWindow().setFlags(WindowManager.LayoutParams.FLAG_SECURE, WindowManager.LayoutParams.FLAG_SECURE);
        } else {
            getWindow().clearFlags(WindowManager.LayoutParams.FLAG_SECURE);
        }
    }

    @Override
    public void onConfigurationChanged(@NonNull Configuration newConfig) {
        super.onConfigurationChanged(newConfig);
        if ((mConfiguration.diff(newConfig) & ActivityInfo.CONFIG_UI_MODE) != 0) {
            if (DarkModeUtil.isDarkMode(this)) DarkModeUtil.switchToAlwaysLightMode();
            else DarkModeUtil.switchToAlwaysDarkMode();
        }
    }

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        setTheme(SharedPreferenceUtil.getThemeId(this, R.style.AppTheme_Color1));
        initSafeMode();
        LiveEventBus.get(EventBusCode.CHANGE_TOKEN_DISABLE_SCREENSHOT.getKey(), String.class).observe(this, s -> initSafeMode());
        super.onCreate(savedInstanceState);
        mConfiguration = new Configuration(getResources().getConfiguration());
        StatusBarUtil.setStatusBarTransparent(this);
        StatusBarUtil.setStatusBarTextColor(this, DarkModeUtil.isDarkMode(getApplicationContext()));
        new BroadcastReceiver() {
            @Override
            public void onReceive(Context context, @NonNull Intent intent) {
                if (Objects.equals(intent.getStringExtra("msg"), "EVENT_REFRESH_LANGUAGE")) {
                    recreate();
                }
            }
        };
    }

    @Override
    protected void onResume() {
        if (netWorkStateReceiver == null) netWorkStateReceiver = new NetWorkStateReceiver();
        IntentFilter filter = new IntentFilter();
        filter.addAction(ConnectivityManager.CONNECTIVITY_ACTION);
        registerReceiver(netWorkStateReceiver, filter);
        super.onResume();
    }

    @Override
    protected void onPause() {
        unregisterReceiver(netWorkStateReceiver);
        super.onPause();
    }
}
