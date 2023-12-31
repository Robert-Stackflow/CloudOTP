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
import com.cloudchewie.otp.appwidget.SimpleRemoteViewsManager;
import com.cloudchewie.otp.database.AppDatabase;
import com.cloudchewie.otp.database.LocalStorage;
import com.cloudchewie.otp.database.PrivacyManager;
import com.cloudchewie.otp.util.enumeration.EventBusCode;
import com.cloudchewie.otp.util.enumeration.PasscodeMode;
import com.cloudchewie.ui.custom.IDialog;
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

    void goToVerify() {
        goToVerify(false);
    }

    void goToVerify(boolean showDialog) {
        if (!SharedPreferenceUtil.getBoolean(this, SharedPreferenceCode.TOKEN_NEED_AUTH.getKey(), true) || PrivacyManager.isVerified())
            return;
        if (PrivacyManager.havePasscode()) {
            Bundle bundle = new Bundle();
            bundle.putSerializable("mode", PasscodeMode.VERIFY.ordinal());
            startActivity(new Intent(this, PasscodeActivity.class).setAction(Intent.ACTION_DEFAULT).putExtras(bundle));
        } else if (showDialog) {
            IDialog dialog = new IDialog(this);
            dialog.setTitle(getString(R.string.dialog_title_none_passcode));
            dialog.setMessage(getString(R.string.dialog_content_none_passcode));
            dialog.setOnClickBottomListener(new IDialog.OnClickBottomListener() {
                @Override
                public void onPositiveClick() {
                    Intent intent = new Intent(BaseActivity.this, PasscodeActivity.class).setAction(Intent.ACTION_DEFAULT);
                    startActivity(intent);
                }

                @Override
                public void onNegtiveClick() {

                }
            });
            dialog.show();
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
        LocalStorage.init(AppDatabase.getInstance(getApplicationContext()));
        PrivacyManager.init();
        LiveEventBus.get(EventBusCode.CHANGE_PASSCODE.getKey()).observe(this, s -> SimpleRemoteViewsManager.refresh(this));
        LiveEventBus.get(EventBusCode.CHANGE_TOKEN_NEED_AUTH.getKey()).observe(this, s -> SimpleRemoteViewsManager.refresh(this));
        LiveEventBus.get(EventBusCode.CHANGE_VERIFY_STATE.getKey()).observe(this, s -> SimpleRemoteViewsManager.refresh(this));
        LiveEventBus.get(EventBusCode.CHANGE_TOKEN.getKey()).observe(this, s -> SimpleRemoteViewsManager.refresh(this));
    }

    @Override
    protected void onResume() {
        IntentFilter filter = new IntentFilter();
        filter.addAction(ConnectivityManager.CONNECTIVITY_ACTION);
        super.onResume();
    }
}

