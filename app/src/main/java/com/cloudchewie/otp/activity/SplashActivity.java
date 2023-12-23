/*
 * Project Name: Worthy
 * Author: Ruida
 * Last Modified: 2022/12/19 14:29:32
 * Copyright(c) 2022 Ruida https://cloudchewie.com
 */

package com.cloudchewie.otp.activity;

import android.annotation.SuppressLint;
import android.content.Intent;
import android.os.Bundle;

import androidx.annotation.Nullable;

import com.cloudchewie.otp.R;
import com.cloudchewie.otp.util.ShortcutUtil;
import com.cloudchewie.otp.database.AppSharedPreferenceUtil;
import com.cloudchewie.ui.loadingdialog.manager.StyleManager;
import com.cloudchewie.ui.loadingdialog.view.LoadingDialog;
import com.cloudchewie.util.system.SharedPreferenceUtil;
import com.cloudchewie.util.ui.DarkModeUtil;

@SuppressLint("CustomSplashScreen")
public class SplashActivity extends BaseActivity {
    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_splash);
        initApp();
        jumpToMainActivity();
    }

    void initApp() {
        if (SharedPreferenceUtil.getThemeId(this, 0) == 0)
            SharedPreferenceUtil.setThemeId(this, R.style.AppTheme_Color1);
        boolean isAutoDaynight = AppSharedPreferenceUtil.isAutoDaynight(this);
        boolean isNight = AppSharedPreferenceUtil.isNight(this);
        if (!isAutoDaynight && isNight) {
            DarkModeUtil.switchToAlwaysDarkMode();
        } else if (!isAutoDaynight && !isNight) {
            DarkModeUtil.switchToAlwaysLightMode();
        } else if (isAutoDaynight) {
            DarkModeUtil.switchToAlwaysSystemMode();
        }
        StyleManager s = new StyleManager();
        s.Anim(true).repeatTime(0).contentSize(-1).intercept(true);
        LoadingDialog.initStyle(s);
        ShortcutUtil.init(this);
    }

    void jumpToMainActivity() {
        Thread thread = new Thread() {
            @Override
            public void run() {
                try {
                    startActivity(new Intent(getApplicationContext(), MainActivity.class).setAction(Intent.ACTION_DEFAULT));
                    finish();
                } catch (Exception e) {
                    e.printStackTrace();
                }
            }
        };
        thread.start();
    }
}
