/*
 * Project Name: Worthy
 * Author: Ruida
 * Last Modified: 2022/12/18 13:13:37
 * Copyright(c) 2022 Ruida https://cloudchewie.com
 */

package com.cloudchewie.otp.activity;

import android.annotation.SuppressLint;
import android.content.Intent;
import android.content.pm.ActivityInfo;
import android.os.Bundle;
import android.os.Handler;
import android.os.Message;
import android.view.View;
import android.widget.ImageButton;
import android.widget.RelativeLayout;

import androidx.annotation.NonNull;
import androidx.appcompat.widget.AppCompatButton;
import androidx.core.view.GravityCompat;
import androidx.drawerlayout.widget.DrawerLayout;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;
import androidx.recyclerview.widget.StaggeredGridLayoutManager;

import com.blankj.utilcode.util.ThreadUtils;
import com.cloudchewie.otp.R;
import com.cloudchewie.otp.adapter.AbstractTokenListAdapter;
import com.cloudchewie.otp.adapter.SmallTokenListAdapter;
import com.cloudchewie.otp.adapter.TokenListAdapter;
import com.cloudchewie.otp.entity.OtpToken;
import com.cloudchewie.otp.util.database.AppDatabase;
import com.cloudchewie.otp.util.database.AppSharedPreferenceUtil;
import com.cloudchewie.otp.util.database.LocalStorage;
import com.cloudchewie.otp.util.decoration.SpacingItemDecoration;
import com.cloudchewie.otp.util.enumeration.Direction;
import com.cloudchewie.otp.util.enumeration.EventBusCode;
import com.cloudchewie.otp.util.enumeration.ViewType;
import com.cloudchewie.ui.ThemeUtil;
import com.cloudchewie.ui.custom.IToast;
import com.cloudchewie.ui.general.BottomSheet;
import com.cloudchewie.ui.item.EntryItem;
import com.cloudchewie.util.system.SharedPreferenceCode;
import com.cloudchewie.util.system.SharedPreferenceUtil;
import com.cloudchewie.util.ui.StatusBarUtil;
import com.jeremyliao.liveeventbus.LiveEventBus;
import com.scwang.smart.refresh.header.MaterialHeader;
import com.scwang.smart.refresh.layout.api.RefreshLayout;
import com.wei.android.lib.fingerprintidentify.FingerprintIdentify;
import com.wei.android.lib.fingerprintidentify.base.BaseFingerprint;

import java.util.ArrayList;
import java.util.List;

import pub.devrel.easypermissions.AppSettingsDialog;
import pub.devrel.easypermissions.EasyPermissions;

public class MainActivity extends BaseActivity implements View.OnClickListener, EasyPermissions.PermissionCallbacks, BaseFingerprint.IdentifyListener, BaseFingerprint.ExceptionListener {
    private DrawerLayout mDrawerLayout;
    private RelativeLayout mDrawer;
    RefreshLayout swipeRefreshLayout;
    EntryItem addEntry;
    EntryItem qrcodeEntry;
    ImageButton lockButton;
    EntryItem settingEntry;
    ImageButton openDrawerButton;
    ImageButton changeViewButton;
    RecyclerView recyclerView;
    AbstractTokenListAdapter adapter;
    RelativeLayout lockLayout;
    RelativeLayout blankLayout;
    EntryItem themeEntry;
    EntryItem githubEntry;
    EntryItem blogEntry;
    EntryItem homeEntry;
    boolean isAuthed = false;
    FingerprintIdentify mFingerprintIdentify;
    BottomSheet bottomSheet;
    SpacingItemDecoration bottomSpacing;
    SpacingItemDecoration rightSpacing;
    AppCompatButton goToImportButton;
    @SuppressLint("HandlerLeak")
    Handler handler = new Handler() {
        @Override
        public void handleMessage(@NonNull Message msg) {
        }
    };
    Runnable getRefreshDatas = () -> {
        Message message = handler.obtainMessage();
        swipeRefreshLayout.finishRefresh();
        initRecyclerView(LocalStorage.getAppDatabase().otpTokenDao().getAll());
        isAuthed = true;
        refreshAuthState();
        handler.sendMessage(message);
    };

    @Override
    @SuppressLint("SourceLockedOrientationActivity")
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        LocalStorage.init(AppDatabase.getInstance(getApplicationContext()));
        setContentView(R.layout.activity_main);
        setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_PORTRAIT);
        initView();
        LiveEventBus.get(EventBusCode.CHANGE_THEME.getKey(), String.class).observe(this, s -> recreate());
        LiveEventBus.get(EventBusCode.CHANGE_VIEW_TYPE.getKey(), String.class).observe(this, s -> initRecyclerView(LocalStorage.getAppDatabase().otpTokenDao().getAll()));
    }

    void initView() {
        bottomSpacing = new SpacingItemDecoration(this, (int) getResources().getDimension(R.dimen.dp3), Direction.BOTTOM);
        rightSpacing = new SpacingItemDecoration(this, (int) getResources().getDimension(R.dimen.dp3), Direction.RIGHT);
        mDrawerLayout = findViewById(R.id.activity_main);
        mDrawer = findViewById(R.id.activity_main_drawer);
        blankLayout = findViewById(R.id.activity_main_blank_layout);
        loadEnableScreenShot();
        StatusBarUtil.setStatusBarMarginTop(findViewById(R.id.activity_main_titlebar), 0, StatusBarUtil.getStatusBarHeight(this), 0, 0);
        StatusBarUtil.setStatusBarMarginTop(findViewById(R.id.activity_main_logo), 0, StatusBarUtil.getStatusBarHeight(this), 0, 0);
        addEntry = findViewById(R.id.activity_main_entry_add);
        qrcodeEntry = findViewById(R.id.activity_main_entry_scan);
        lockLayout = findViewById(R.id.activity_main_lock_layout);
        openDrawerButton = findViewById(R.id.activity_main_open_drawer);
        settingEntry = findViewById(R.id.activity_main_entry_settings);
        lockButton = findViewById(R.id.activity_main_lock);
        goToImportButton = findViewById(R.id.activity_main_go_to_import);
        goToImportButton.setOnClickListener(this);
        changeViewButton = findViewById(R.id.activity_main_change_view);
        recyclerView = findViewById(R.id.activity_main_recyclerview);
        addEntry.setOnClickListener(this);
        qrcodeEntry.setOnClickListener(this);
        lockButton.setOnClickListener(this);
        settingEntry.setOnClickListener(this);
        lockLayout.setOnClickListener(this);
        openDrawerButton.setOnClickListener(this);
        changeViewButton.setOnClickListener(this);
        findViewById(R.id.activity_main_lock_icon).setOnClickListener(this);
        findViewById(R.id.activity_main_lock_text).setOnClickListener(this);
        themeEntry = findViewById(R.id.activity_main_entry_theme);
        githubEntry = findViewById(R.id.activity_main_entry_github);
        blogEntry = findViewById(R.id.activity_main_entry_blog);
        homeEntry = findViewById(R.id.activity_main_entry_home);
        themeEntry.setOnClickListener(this);
        githubEntry.setOnClickListener(this);
        blogEntry.setOnClickListener(this);
        homeEntry.setOnClickListener(this);
        initSwipeRefresh();
        LiveEventBus.get(EventBusCode.CHANGE_TOKEN.getKey()).observe(this, s -> swipeRefreshLayout.autoRefresh());
        LiveEventBus.get(EventBusCode.CHANGE_TOKEN_NEED_AUTH.getKey()).observe(this, s -> {
            isAuthed = !SharedPreferenceUtil.getBoolean(this, SharedPreferenceCode.TOKEN_NEED_AUTH.getKey(), true);
            lockButton.setVisibility(SharedPreferenceUtil.getBoolean(this, SharedPreferenceCode.TOKEN_NEED_AUTH.getKey(), true) ? View.VISIBLE : View.GONE);
            refreshAuthState();
        });
        isAuthed = LocalStorage.getAppDatabase().otpTokenDao().count() <= 0 || !SharedPreferenceUtil.getBoolean(this, SharedPreferenceCode.TOKEN_NEED_AUTH.getKey(), true);
        lockButton.setVisibility(SharedPreferenceUtil.getBoolean(this, SharedPreferenceCode.TOKEN_NEED_AUTH.getKey(), true) ? View.VISIBLE : View.GONE);
        refreshAuthState();
        initAuth();
        initRecyclerView(new ArrayList<>());
    }

    void initRecyclerView(List<OtpToken> tokenList) {
        switch (AppSharedPreferenceUtil.getViewType(this)) {
            case singleColumn:
                adapter = new TokenListAdapter(this, tokenList);
                recyclerView.setAdapter((TokenListAdapter) adapter);
                recyclerView.setLayoutManager(new LinearLayoutManager(this));
                recyclerView.removeItemDecoration(bottomSpacing);
                recyclerView.addItemDecoration(bottomSpacing);
                break;
            case doubleColumn:
                adapter = new SmallTokenListAdapter(this, tokenList);
                recyclerView.setAdapter((SmallTokenListAdapter) adapter);
                recyclerView.setLayoutManager(new StaggeredGridLayoutManager(2, RecyclerView.VERTICAL));
                recyclerView.removeItemDecoration(bottomSpacing);
                recyclerView.removeItemDecoration(rightSpacing);
                recyclerView.addItemDecoration(bottomSpacing);
                recyclerView.addItemDecoration(rightSpacing);
                recyclerView.setPadding((int) getResources().getDimension(R.dimen.dp10), 0, (int) getResources().getDimension(R.dimen.dp4), 0);
                break;
        }
    }

    @Override
    public void onRequestPermissionsResult(int requestCode, @NonNull String[] permissions, @NonNull int[] grantResults) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults);
        EasyPermissions.onRequestPermissionsResult(requestCode, permissions, grantResults, this);
    }

    @Override
    public void onPermissionsGranted(int requestCode, @NonNull List<String> perms) {

    }

    @Override
    public void onPermissionsDenied(int requestCode, @NonNull List<String> perms) {
        if (EasyPermissions.somePermissionPermanentlyDenied(this, perms)) {
            new AppSettingsDialog.Builder(this).build().show();
        }
    }

    @Override
    public void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
    }

    public void initData() {
        ThreadUtils.executeBySingle(new ThreadUtils.SimpleTask<List<OtpToken>>() {
            @Override
            public List<OtpToken> doInBackground() {
                return LocalStorage.getAppDatabase().otpTokenDao().getAll();
            }

            @Override
            public void onSuccess(List<OtpToken> result) {
                adapter.setData(result);
            }
        });
    }

    public void refreshAuthState() {
        if (isAuthed) {
            initData();
            lockLayout.setVisibility(View.GONE);
            openDrawerButton.setVisibility(View.VISIBLE);
            changeViewButton.setVisibility(View.VISIBLE);
            ((View) swipeRefreshLayout).setVisibility(View.VISIBLE);
            if (LocalStorage.getAppDatabase().otpTokenDao().count() <= 0) {
                blankLayout.setVisibility(View.VISIBLE);
            } else {
                blankLayout.setVisibility(View.GONE);
            }
            if (SharedPreferenceUtil.getBoolean(this, SharedPreferenceCode.TOKEN_NEED_AUTH.getKey(), true)) {
                lockButton.setVisibility(View.VISIBLE);
            }
            mDrawerLayout.setDrawerLockMode(DrawerLayout.LOCK_MODE_UNLOCKED);
        } else {
            lockLayout.setVisibility(View.VISIBLE);
            openDrawerButton.setVisibility(View.GONE);
            lockButton.setVisibility(View.GONE);
            changeViewButton.setVisibility(View.GONE);
            ((View) swipeRefreshLayout).setVisibility(View.GONE);
            blankLayout.setVisibility(View.GONE);
            mDrawerLayout.setDrawerLockMode(DrawerLayout.LOCK_MODE_LOCKED_CLOSED);
        }
    }

    @Override
    public void onPause() {
        super.onPause();
        mFingerprintIdentify.cancelIdentify();
    }

    @Override
    public void onStop() {
        super.onStop();
        mFingerprintIdentify.cancelIdentify();
    }

    void initSwipeRefresh() {
        swipeRefreshLayout = findViewById(R.id.activity_main_swipe_refresh);
        swipeRefreshLayout.setRefreshHeader(new MaterialHeader(this).setColorSchemeColors(ThemeUtil.getPrimaryColor(this)).setProgressBackgroundColorSchemeColor(getResources().getColor(R.color.card_background)).setProgressBackgroundColorSchemeColor(getResources().getColor(R.color.card_background)));
        swipeRefreshLayout.setEnableOverScrollDrag(true);
        swipeRefreshLayout.setEnableOverScrollBounce(true);
        swipeRefreshLayout.setEnableLoadMore(false);
        swipeRefreshLayout.setOnRefreshListener(v -> handler.post(getRefreshDatas));
    }

    public void initAuth() {
        mFingerprintIdentify = new FingerprintIdentify(this);
        mFingerprintIdentify.setSupportAndroidL(true);
        mFingerprintIdentify.setExceptionListener(this);
        mFingerprintIdentify.init();
    }

    @Override
    public void onClick(View v) {
        if (v == addEntry) {
            Intent intent = new Intent(this, TokenDetailActivity.class).setAction(Intent.ACTION_DEFAULT);
            startActivity(intent);
        } else if (v == settingEntry || v == goToImportButton) {
            Intent intent = new Intent(this, SettingsActivity.class).setAction(Intent.ACTION_DEFAULT);
            startActivity(intent);
        } else if (v == qrcodeEntry) {
            Intent intent = new Intent(this, ScanActivity.class).setAction(Intent.ACTION_DEFAULT);
            startActivity(intent);
        } else if (v == lockButton) {
            isAuthed = false;
            refreshAuthState();
        } else if (v == openDrawerButton) {
            mDrawerLayout.openDrawer(GravityCompat.START);
        } else if (v == lockLayout || v.getId() == R.id.activity_main_lock_icon || v.getId() == R.id.activity_main_lock_text) {
            if (mFingerprintIdentify.isFingerprintEnable()) {
                bottomSheet = new BottomSheet(this);
                bottomSheet.setTitle(getString(R.string.verify_finger));
                bottomSheet.setDragBarVisible(false);
                bottomSheet.setLeftButtonVisible(false);
                bottomSheet.setRightButtonVisible(false);
                bottomSheet.setBackgroundColor(getResources().getColor(R.color.card_background));
                bottomSheet.setMainLayout(R.layout.layout_fingerprint);
                bottomSheet.show();
                bottomSheet.setOnCancelListener(dialogInterface -> mFingerprintIdentify.cancelIdentify());
                mFingerprintIdentify.resumeIdentify();
                mFingerprintIdentify.startIdentify(5, this);
            }
        } else if (v == themeEntry) {
            Intent intent = new Intent(this, ThemeActivity.class).setAction(Intent.ACTION_DEFAULT);
            startActivity(intent);
        } else if (v == githubEntry) {
            Intent intent = new Intent(this, WebViewActivity.class).setAction(Intent.ACTION_DEFAULT);
            intent.putExtra("url", getString(R.string.url_github));
            startActivity(intent);
        } else if (v == blogEntry) {
            Intent intent = new Intent(this, WebViewActivity.class).setAction(Intent.ACTION_DEFAULT);
            intent.putExtra("url", getString(R.string.url_blog));
            startActivity(intent);
        } else if (v == homeEntry) {
            Intent intent = new Intent(this, WebViewActivity.class).setAction(Intent.ACTION_DEFAULT);
            intent.putExtra("url", getString(R.string.url_home));
            startActivity(intent);
        } else if (v == changeViewButton) {
            AppSharedPreferenceUtil.setViewType(this, ViewType.values()[(AppSharedPreferenceUtil.getViewType(this).ordinal() + 1) % ViewType.values().length]);
            LiveEventBus.get(EventBusCode.CHANGE_VIEW_TYPE.getKey()).post("");
        }
    }

    @Override
    public void onDestroy() {
        super.onDestroy();
        if (mFingerprintIdentify != null) mFingerprintIdentify.cancelIdentify();
    }

    @Override
    public void onCatchException(Throwable exception) {

    }

    @Override
    public void onSucceed() {
        if (mFingerprintIdentify != null) mFingerprintIdentify.cancelIdentify();
        isAuthed = true;
        if (bottomSheet != null) bottomSheet.cancel();
        refreshAuthState();
    }

    @Override
    public void onNotMatch(int availableTimes) {
        bottomSheet.setTitle(getString(R.string.verify_finger_fail));
        bottomSheet.setDragBarVisible(false);
        bottomSheet.setTitleColor(getResources().getColor(R.color.text_color_red));
        new Handler().postDelayed(() -> {
            bottomSheet.setTitle(getString(R.string.verify_finger));
            bottomSheet.setDragBarVisible(false);
            bottomSheet.setTitleColor(getResources().getColor(R.color.color_accent));
        }, 500);
    }

    @Override
    public void onFailed(boolean isDeviceLocked) {
        IToast.showBottom(this, getString(R.string.verify_finger_error));
        if (bottomSheet != null) bottomSheet.cancel();
    }

    @Override
    public void onStartFailedByDeviceLocked() {

    }
}