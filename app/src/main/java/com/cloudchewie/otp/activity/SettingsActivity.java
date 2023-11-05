package com.cloudchewie.otp.activity;

import static com.cloudchewie.util.system.LanguageUtil.SP_LANGUAGE;

import android.annotation.SuppressLint;
import android.content.Intent;
import android.os.Bundle;
import android.os.Handler;
import android.view.View;
import android.widget.Toast;

import com.blankj.utilcode.util.ActivityUtils;
import com.blankj.utilcode.util.SPUtils;
import com.cloudchewie.otp.R;
import com.cloudchewie.otp.entity.ListBottomSheetBean;
import com.cloudchewie.otp.util.database.AppSharedPreferenceUtil;
import com.cloudchewie.otp.util.enumeration.EventBusCode;
import com.cloudchewie.otp.widget.ListBottomSheet;
import com.cloudchewie.ui.custom.IDialog;
import com.cloudchewie.ui.custom.IToast;
import com.cloudchewie.ui.custom.TitleBar;
import com.cloudchewie.ui.item.CheckBoxItem;
import com.cloudchewie.ui.item.EntryItem;
import com.cloudchewie.util.system.CacheUtil;
import com.cloudchewie.util.system.LanguageUtil;
import com.cloudchewie.util.system.SharedPreferenceCode;
import com.cloudchewie.util.system.SharedPreferenceUtil;
import com.cloudchewie.util.ui.DarkModeUtil;
import com.cloudchewie.util.ui.StatusBarUtil;
import com.jeremyliao.liveeventbus.LiveEventBus;
import com.scwang.smart.refresh.layout.api.RefreshLayout;

import java.util.Arrays;
import java.util.List;
import java.util.Objects;

public class SettingsActivity extends BaseActivity implements View.OnClickListener {
    RefreshLayout swipeRefreshLayout;
    CheckBoxItem longPressItem;
    CheckBoxItem clickItem;
    CheckBoxItem authItem;
    CheckBoxItem screenShotItem;
    EntryItem clearCacheEntry;
    EntryItem languageEntry;
    CheckBoxItem autoDaynightEntry;
    CheckBoxItem switchDaynightEntry;
    CheckBoxItem enableWebCacheEntry;
    EntryItem setPasscodeEntry;

    @SuppressLint("SetTextI18n")
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        StatusBarUtil.setStatusBarMarginTop(this);
        setContentView(R.layout.activity_settings);
        ((TitleBar) findViewById(R.id.authenticator_settings_titlebar)).setLeftButtonClickListener(v -> finishAfterTransition());
        longPressItem = findViewById(R.id.entry_long_press_copy);
        clickItem = findViewById(R.id.entry_click_copy);
        authItem = findViewById(R.id.entry_need_auth);
        screenShotItem = findViewById(R.id.entry_disable_screenshot);
        setPasscodeEntry = findViewById(R.id.entry_set_passcode);
        clearCacheEntry = findViewById(R.id.entry_clear_cache);
        clearCacheEntry.setTipText(CacheUtil.getTotalCacheSize(this));
        clearCacheEntry.setOnClickListener(this);
        languageEntry = findViewById(R.id.entry_language);
        languageEntry.setOnClickListener(this);
        autoDaynightEntry = findViewById(R.id.switch_auto_daynight);
        switchDaynightEntry = findViewById(R.id.switch_daynight);
        enableWebCacheEntry = findViewById(R.id.entry_enable_web_cache);
        loadSettings();
        bindEvent();
        initSwipeRefresh();
    }

    void loadSettings() {
        longPressItem.setChecked(SharedPreferenceUtil.getBoolean(SettingsActivity.this, SharedPreferenceCode.TOKEN_LONG_CLICK_COPY.getKey(), true));
        clickItem.setChecked(SharedPreferenceUtil.getBoolean(SettingsActivity.this, SharedPreferenceCode.TOKEN_CLICK_COPY.getKey(), false));
        authItem.setChecked(SharedPreferenceUtil.getBoolean(SettingsActivity.this, SharedPreferenceCode.TOKEN_NEED_AUTH.getKey(), true));
        screenShotItem.setChecked(SharedPreferenceUtil.getBoolean(SettingsActivity.this, SharedPreferenceCode.TOKEN_DISBALE_SCREENSHOT.getKey(), true));
        if (!Objects.equals(SPUtils.getInstance().getString(SP_LANGUAGE, ""), ""))
            languageEntry.setTipText(LanguageUtil.getAppLanguage(this));
        else languageEntry.setTipText(getString(R.string.language_default));
        //加载是否自动跟随或深色模式
        if (AppSharedPreferenceUtil.isAutoDaynight(this)) {
            AppSharedPreferenceUtil.setNight(this, DarkModeUtil.isDarkMode(this));
        }
        autoDaynightEntry.setRadiusEnbale(true, AppSharedPreferenceUtil.isAutoDaynight(this));
        switchDaynightEntry.setVisibility(AppSharedPreferenceUtil.isAutoDaynight(this) ? View.GONE : View.VISIBLE);
        new Handler().postDelayed(() -> {
            switchDaynightEntry.setChecked(AppSharedPreferenceUtil.isNight(this));
            autoDaynightEntry.setChecked(AppSharedPreferenceUtil.isAutoDaynight(this));
        }, 100);
        enableWebCacheEntry.setChecked(SharedPreferenceUtil.getBoolean(this, SharedPreferenceCode.ENABLE_WEB_CACHE.getKey(), true));
        if (AppSharedPreferenceUtil.havePasscode(this)) {
            setPasscodeEntry.setTitle(getString(R.string.change_passcode));
        } else {
            setPasscodeEntry.setTitle(getString(R.string.set_passcode));
        }
        LiveEventBus.get(EventBusCode.CHANGE_PASSCODE.getKey()).observe(this, s -> {
            if (AppSharedPreferenceUtil.havePasscode(this)) {
                setPasscodeEntry.setTitle(getString(R.string.change_passcode));
            } else {
                setPasscodeEntry.setTitle(getString(R.string.set_passcode));
            }
        });
    }

    void bindEvent() {
        autoDaynightEntry.setOnCheckedChangedListener((buttonView, isChecked) -> {
            AppSharedPreferenceUtil.setAutoDaynight(this, isChecked);
            LiveEventBus.get(EventBusCode.CHANGE_AUTO_DAYNIGHT.getKey()).post("change");
            if (isChecked) {
                DarkModeUtil.switchToAlwaysSystemMode();
                autoDaynightEntry.setRadiusEnbale(true, true);
            } else {
                autoDaynightEntry.setRadiusEnbale(true, false);
                if (AppSharedPreferenceUtil.isNight(this)) {
                    DarkModeUtil.switchToAlwaysDarkMode();
                } else {
                    DarkModeUtil.switchToAlwaysLightMode();
                }
            }
            switchDaynightEntry.setVisibility(AppSharedPreferenceUtil.isAutoDaynight(this) ? View.GONE : View.VISIBLE);
        });
        switchDaynightEntry.setOnCheckedChangedListener((buttonView, isChecked) -> {
            AppSharedPreferenceUtil.setNight(this, isChecked);
            if (isChecked) {
                DarkModeUtil.switchToAlwaysDarkMode();
            } else {
                DarkModeUtil.switchToAlwaysLightMode();
            }
        });
        enableWebCacheEntry.setOnCheckedChangedListener((buttonView, isChecked) -> SharedPreferenceUtil.putBoolean(this, SharedPreferenceCode.ENABLE_WEB_CACHE.getKey(), isChecked));
        longPressItem.setOnCheckedChangedListener((buttonView, isChecked) -> SharedPreferenceUtil.putBoolean(SettingsActivity.this, SharedPreferenceCode.TOKEN_LONG_CLICK_COPY.getKey(), isChecked));
        clickItem.setOnCheckedChangedListener((buttonView, isChecked) -> SharedPreferenceUtil.putBoolean(SettingsActivity.this, SharedPreferenceCode.TOKEN_CLICK_COPY.getKey(), isChecked));
        authItem.setOnCheckedChangedListener((buttonView, isChecked) -> {
            SharedPreferenceUtil.putBoolean(SettingsActivity.this, SharedPreferenceCode.TOKEN_NEED_AUTH.getKey(), isChecked);
            LiveEventBus.get(EventBusCode.CHANGE_TOKEN_NEED_AUTH.getKey()).post("");
            if (isChecked) {
                setPasscodeEntry.setVisibility(View.VISIBLE);
                authItem.setRadiusEnbale(false, false);
            } else {
                setPasscodeEntry.setVisibility(View.GONE);
                authItem.setRadiusEnbale(false, true);
            }
        });
        screenShotItem.setOnCheckedChangedListener((buttonView, isChecked) -> {
            SharedPreferenceUtil.putBoolean(SettingsActivity.this, SharedPreferenceCode.TOKEN_DISBALE_SCREENSHOT.getKey(), isChecked);
            LiveEventBus.get(EventBusCode.CHANGE_TOKEN_DISABLE_SCREENSHOT.getKey()).post("");
        });
        setPasscodeEntry.setOnClickListener(view -> {
            Intent intent = new Intent(SettingsActivity.this, PasscodeActivity.class).setAction(Intent.ACTION_DEFAULT);
            startActivity(intent);
        });
    }

    void initSwipeRefresh() {
        swipeRefreshLayout = findViewById(R.id.authenticator_settings_swipe_refresh);
        swipeRefreshLayout.setEnableOverScrollDrag(true);
        swipeRefreshLayout.setEnableOverScrollBounce(true);
        swipeRefreshLayout.setEnableLoadMore(false);
        swipeRefreshLayout.setEnablePureScrollMode(true);
    }

    @Override
    public void onClick(View view) {
        if (view == languageEntry) {
            List<String> strings = Arrays.asList(getResources().getStringArray(R.array.edit_language));
            ListBottomSheet bottomSheet = new ListBottomSheet(this, ListBottomSheetBean.strToBean(strings));
            bottomSheet.setOnItemClickedListener(position -> {
                if (position == 0) LanguageUtil.changeLanguage(this, "zh", "CN");
                else if (position == 1) LanguageUtil.changeLanguage(this, "zh", "TW");
                else if (position == 2) LanguageUtil.changeLanguage(this, "en", "US");
                else if (position == 3) LanguageUtil.changeLanguage(this, "ja", "JP");
                if (languageEntry.getTip().equals(strings.get(position))) {
                    bottomSheet.dismiss();
                } else {
                    languageEntry.setTipText(strings.get(position));
                    ActivityUtils.finishAllActivities();
                    ActivityUtils.startActivity(new Intent(this, MainActivity.class).setAction(Intent.ACTION_DEFAULT));
                }
            });
            bottomSheet.show();
        } else if (view == clearCacheEntry) {
            if (!CacheUtil.getTotalCacheSize(this).equals(getString(R.string.zero_cache))) {
                IDialog dialog = new IDialog(this);
                dialog.setTitle(getString(R.string.dialog_title_clear_cache));
                dialog.setMessage(getString(R.string.dialog_content_clear_cache));
                dialog.setOnClickBottomListener(new IDialog.OnClickBottomListener() {
                    @Override
                    public void onPositiveClick() {
                        CacheUtil.clearAllCache(SettingsActivity.this);
                        clearCacheEntry.setTipText(CacheUtil.getTotalCacheSize(SettingsActivity.this));
                        IToast.makeTextBottom(SettingsActivity.this, getString(R.string.clear_cache_success), Toast.LENGTH_SHORT).show();
                    }

                    @Override
                    public void onNegtiveClick() {
                    }

                    @Override
                    public void onCloseClick() {
                    }
                });
                dialog.show();
            } else {
                IToast.makeTextBottom(this, getString(R.string.no_need_to_clear_cache), Toast.LENGTH_SHORT).show();
            }
        }
    }
}
