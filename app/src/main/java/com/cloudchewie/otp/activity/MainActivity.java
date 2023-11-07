/*
 * Project Name: Worthy
 * Author: Ruida
 * Last Modified: 2022/12/18 13:13:37
 * Copyright(c) 2022 Ruida https://cloudchewie.com
 */

package com.cloudchewie.otp.activity;

import android.annotation.SuppressLint;
import android.app.Activity;
import android.content.Intent;
import android.content.pm.ActivityInfo;
import android.net.Uri;
import android.os.Bundle;
import android.os.Handler;
import android.view.View;
import android.widget.ImageButton;
import android.widget.ImageView;
import android.widget.RelativeLayout;
import android.widget.TextView;

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
import com.cloudchewie.otp.entity.ListBottomSheetBean;
import com.cloudchewie.otp.entity.OtpToken;
import com.cloudchewie.otp.util.ExploreUtil;
import com.cloudchewie.otp.util.authenticator.ExportTokenUtil;
import com.cloudchewie.otp.util.authenticator.ImportTokenUtil;
import com.cloudchewie.otp.util.database.AppDatabase;
import com.cloudchewie.otp.util.database.AppSharedPreferenceUtil;
import com.cloudchewie.otp.util.database.LocalStorage;
import com.cloudchewie.otp.util.database.PrivacyManager;
import com.cloudchewie.otp.util.decoration.SpacingItemDecoration;
import com.cloudchewie.otp.util.enumeration.Direction;
import com.cloudchewie.otp.util.enumeration.EventBusCode;
import com.cloudchewie.otp.util.enumeration.ViewType;
import com.cloudchewie.otp.widget.ListBottomSheet;
import com.cloudchewie.otp.widget.SecretBottomSheet;
import com.cloudchewie.ui.ThemeUtil;
import com.cloudchewie.ui.custom.IDialog;
import com.cloudchewie.ui.custom.IToast;
import com.cloudchewie.ui.fab.FloatingActionButton;
import com.cloudchewie.ui.general.BottomSheet;
import com.cloudchewie.ui.item.EntryItem;
import com.cloudchewie.ui.loadingdialog.view.LoadingDialog;
import com.cloudchewie.ui.passcode.PassCodeView;
import com.cloudchewie.util.system.SharedPreferenceCode;
import com.cloudchewie.util.system.SharedPreferenceUtil;
import com.cloudchewie.util.system.UriUtil;
import com.cloudchewie.util.ui.StatusBarUtil;
import com.jeremyliao.liveeventbus.LiveEventBus;
import com.scwang.smart.refresh.header.MaterialHeader;
import com.scwang.smart.refresh.layout.api.RefreshLayout;
import com.wei.android.lib.fingerprintidentify.FingerprintIdentify;
import com.wei.android.lib.fingerprintidentify.base.BaseFingerprint;

import java.security.GeneralSecurityException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Objects;

public class MainActivity extends BaseActivity implements View.OnClickListener, BaseFingerprint.IdentifyListener, BaseFingerprint.ExceptionListener, SecretBottomSheet.OnConfirmListener {
    private static final int IMPORT_ENCRYPT_REQUEST_CODE = 42;
    private static final int IMPORT_URI_REQUEST_CODE = 43;
    private static final int IMPORT_JSON_REQUEST_CODE = 44;
    private String EXPORT_PREFIX = "Token_";
    private boolean redirectToEximport = false;
    private Uri redirectUri;
    private DrawerLayout mDrawerLayout;
    private RelativeLayout mDrawer;
    RefreshLayout swipeRefreshLayout;
    PassCodeView passCodeView;
    FloatingActionButton lockButton;
    ImageButton openDrawerButton;
    ImageButton changeViewButton;
    ImageButton exportImportbutton;
    RecyclerView recyclerView;
    AbstractTokenListAdapter adapter;
    RelativeLayout lockLayout;
    RelativeLayout blankLayout;
    EntryItem addEntry;
    EntryItem eximportEntry;
    ImageButton scanEntry;
    EntryItem themeEntry;
    EntryItem settingEntry;
    EntryItem githubEntry;
    EntryItem blogEntry;
    EntryItem homeEntry;
    EntryItem dropboxEntry;
    boolean isAuthed = false;
    FingerprintIdentify mFingerprintIdentify;
    BottomSheet bottomSheet;
    SpacingItemDecoration bottomSpacing;
    SpacingItemDecoration rightSpacing;
    AppCompatButton goToImportButton;
    TextView passcodeTipView;
    ImageView passcodeIconView;
    Integer passcodeTip;
    LoadingDialog loadingDialog;

    @Override
    @SuppressLint("SourceLockedOrientationActivity")
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        LocalStorage.init(AppDatabase.getInstance(getApplicationContext()));
        setContentView(R.layout.activity_main);
        setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_PORTRAIT);
        PrivacyManager.init();
        initBiometrics();
        initView();
        initEvent();
        initSafeMode();
        initSwipeRefresh();
        refreshAuthState();
    }

    void initEvent() {
        LiveEventBus.get(EventBusCode.CHANGE_THEME.getKey(), String.class).observe(this, s -> recreate());
        LiveEventBus.get(EventBusCode.CHANGE_VIEW_TYPE.getKey(), String.class).observe(this, s -> setRecyclerViewData(LocalStorage.getAppDatabase().otpTokenDao().getAll()));
        LiveEventBus.get(EventBusCode.CHANGE_TOKEN.getKey()).observe(this, s -> swipeRefreshLayout.autoRefresh());
        LiveEventBus.get(EventBusCode.CHANGE_TOKEN_NEED_AUTH.getKey()).observe(this, s -> {
            isAuthed = !SharedPreferenceUtil.getBoolean(this, SharedPreferenceCode.TOKEN_NEED_AUTH.getKey(), true);
            lockButton.setVisibility(SharedPreferenceUtil.getBoolean(this, SharedPreferenceCode.TOKEN_NEED_AUTH.getKey(), true) ? View.VISIBLE : View.GONE);
            refreshAuthState();
        });
        LiveEventBus.get(EventBusCode.CHANGE_PASSCODE.getKey()).observe(this, s -> lockButton.setOnClickListener(this::goToVerify));
        passCodeView.setOnTextChangeListener(text -> {
            if (text.length() == 4) {
                if (text.equals(PrivacyManager.getPasscode())) {
                    isAuthed = true;
                    refreshAuthState();
                } else {
                    passCodeView.setError(true);
                    passcodeTipView.setText(R.string.wrong_passcode);
                    passcodeTipView.setTextColor(getColor(R.color.text_color_red));
                }
            } else if (text.length() > 0) {
                passcodeTipView.setText(passcodeTip);
                passcodeTipView.setTextColor(getColor(R.color.color_accent));
            }
        });
    }

    void goToVerify(View v) {
        if (PrivacyManager.havePasscode()) {
            isAuthed = false;
            refreshAuthState();
        } else {
            IDialog dialog = new IDialog(this);
            dialog.setTitle(getString(R.string.dialog_title_none_passcode));
            dialog.setMessage(getString(R.string.dialog_content_none_passcode));
            dialog.setOnClickBottomListener(new IDialog.OnClickBottomListener() {
                @Override
                public void onPositiveClick() {
                    Intent intent = new Intent(MainActivity.this, PasscodeActivity.class).setAction(Intent.ACTION_DEFAULT);
                    startActivity(intent);
                }

                @Override
                public void onNegtiveClick() {

                }
            });
            dialog.show();
        }
    }

    void initView() {
        bottomSpacing = new SpacingItemDecoration(this, (int) getResources().getDimension(R.dimen.dp3), Direction.BOTTOM);
        rightSpacing = new SpacingItemDecoration(this, (int) getResources().getDimension(R.dimen.dp3), Direction.RIGHT);
        StatusBarUtil.setStatusBarMarginTop(findViewById(R.id.activity_main_logo), 0, StatusBarUtil.getStatusBarHeight(this), 0, 0);
        StatusBarUtil.setStatusBarMarginTop(findViewById(R.id.activity_main_titlebar), 0, StatusBarUtil.getStatusBarHeight(this), 0, 0);
        mDrawerLayout = findViewById(R.id.activity_main);
        mDrawer = findViewById(R.id.activity_main_drawer);
        blankLayout = findViewById(R.id.activity_main_blank_layout);
        addEntry = findViewById(R.id.activity_main_entry_add);
        scanEntry = findViewById(R.id.activity_main_scan);
        dropboxEntry = findViewById(R.id.activity_main_entry_dropbox);
        lockLayout = findViewById(R.id.activity_main_lock_layout);
        eximportEntry = findViewById(R.id.activity_main_entry_eximport);
        openDrawerButton = findViewById(R.id.activity_main_open_drawer);
        settingEntry = findViewById(R.id.activity_main_entry_settings);
        lockButton = findViewById(R.id.activity_main_lock);
        goToImportButton = findViewById(R.id.activity_main_go_to_import);
        exportImportbutton = findViewById(R.id.activity_main_more);
        changeViewButton = findViewById(R.id.activity_main_change_view);
        recyclerView = findViewById(R.id.activity_main_recyclerview);
        themeEntry = findViewById(R.id.activity_main_entry_theme);
        githubEntry = findViewById(R.id.activity_main_entry_github);
        blogEntry = findViewById(R.id.activity_main_entry_blog);
        homeEntry = findViewById(R.id.activity_main_entry_home);
        passCodeView = findViewById(R.id.activity_main_passcode_view);
        passcodeIconView = findViewById(R.id.activity_main_lock_icon);
        passcodeTipView = findViewById(R.id.activity_main_lock_text);
        dropboxEntry.setOnClickListener(this);
        exportImportbutton.setOnClickListener(this);
        goToImportButton.setOnClickListener(this);
        eximportEntry.setOnClickListener(this);
        addEntry.setOnClickListener(this);
        scanEntry.setOnClickListener(this);
        settingEntry.setOnClickListener(this);
        lockLayout.setOnClickListener(this);
        openDrawerButton.setOnClickListener(this);
        changeViewButton.setOnClickListener(this);
        themeEntry.setOnClickListener(this);
        githubEntry.setOnClickListener(this);
        blogEntry.setOnClickListener(this);
        homeEntry.setOnClickListener(this);
        passcodeIconView.setOnClickListener(this);
        passcodeTipView.setOnClickListener(this);
        lockButton.setOnClickListener(this::goToVerify);
        loadingDialog = new LoadingDialog(this);
        isAuthed = LocalStorage.getAppDatabase().otpTokenDao().count() <= 0 || !SharedPreferenceUtil.getBoolean(this, SharedPreferenceCode.TOKEN_NEED_AUTH.getKey(), true);
        lockButton.setVisibility(SharedPreferenceUtil.getBoolean(this, SharedPreferenceCode.TOKEN_NEED_AUTH.getKey(), true) ? View.VISIBLE : View.GONE);
        recyclerView.addOnScrollListener(new RecyclerView.OnScrollListener() {
            @Override
            public void onScrolled(@NonNull RecyclerView recyclerView, int dx, int dy) {
                if (SharedPreferenceUtil.getBoolean(MainActivity.this, SharedPreferenceCode.TOKEN_NEED_AUTH.getKey(), true)) {
                    if (dy > 0 || dy < 0 && lockButton.isShown()) {
                        lockButton.hide(true);
                    }
                    if (isSlideToBottom(recyclerView) && adapter instanceof TokenListAdapter) {
                        lockButton.hide(true);
                    }
                }
            }

            @Override
            public void onScrollStateChanged(@NonNull RecyclerView recyclerView, int newState) {
                if (SharedPreferenceUtil.getBoolean(MainActivity.this, SharedPreferenceCode.TOKEN_NEED_AUTH.getKey(), true)) {
                    if (newState == RecyclerView.SCROLL_STATE_IDLE && !(isSlideToBottom(recyclerView) && adapter instanceof TokenListAdapter)) {
                        lockButton.show(true);
                    }
                }
                super.onScrollStateChanged(recyclerView, newState);
            }
        });
    }

    boolean isSlideToBottom(RecyclerView recyclerView) {
        if (recyclerView == null) return false;
        return recyclerView.computeVerticalScrollExtent() + recyclerView.computeVerticalScrollOffset() >= recyclerView.computeVerticalScrollRange();
    }

    void setRecyclerViewData(List<OtpToken> tokenList) {
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
        if (LocalStorage.getAppDatabase().otpTokenDao().count() <= 0) {
            blankLayout.setVisibility(View.VISIBLE);
            changeViewButton.setVisibility(View.GONE);
        } else {
            blankLayout.setVisibility(View.GONE);
            changeViewButton.setVisibility(View.VISIBLE);
        }
    }

    public void refreshData() {
        ThreadUtils.executeBySingle(new ThreadUtils.SimpleTask<List<OtpToken>>() {
            @Override
            public List<OtpToken> doInBackground() {
                return LocalStorage.getAppDatabase().otpTokenDao().getAll();
            }

            @Override
            public void onSuccess(List<OtpToken> result) {
                if (adapter != null) {
                    adapter.setData(result);
                } else {
                    setRecyclerViewData(result);
                }
            }
        });
    }

    public void refreshAuthState() {
        if (!PrivacyManager.havePasscode() || isAuthed) {
            refreshData();
            if (SharedPreferenceUtil.getBoolean(this, SharedPreferenceCode.TOKEN_NEED_AUTH.getKey(), true))
                lockButton.setVisibility(View.VISIBLE);
            lockLayout.setVisibility(View.GONE);
            findViewById(R.id.activity_main_titlebar).setVisibility(View.VISIBLE);
            ((View) swipeRefreshLayout).setVisibility(View.VISIBLE);
            mDrawerLayout.setDrawerLockMode(DrawerLayout.LOCK_MODE_UNLOCKED);
            if (LocalStorage.getAppDatabase().otpTokenDao().count() <= 0) {
                blankLayout.setVisibility(View.VISIBLE);
                changeViewButton.setVisibility(View.GONE);
            } else {
                blankLayout.setVisibility(View.GONE);
                changeViewButton.setVisibility(View.VISIBLE);
            }
        } else {
            setRecyclerViewData(new ArrayList<>());
            findViewById(R.id.activity_main_titlebar).setVisibility(View.INVISIBLE);
            lockButton.setVisibility(View.GONE);
            lockLayout.setVisibility(View.VISIBLE);
            ((View) swipeRefreshLayout).setVisibility(View.GONE);
            passCodeView.reset();
            mDrawerLayout.setDrawerLockMode(DrawerLayout.LOCK_MODE_LOCKED_CLOSED);
        }
    }

    void initSwipeRefresh() {
        swipeRefreshLayout = findViewById(R.id.activity_main_swipe_refresh);
        swipeRefreshLayout.setRefreshHeader(new MaterialHeader(this).setColorSchemeColors(ThemeUtil.getPrimaryColor(this)).setProgressBackgroundColorSchemeColor(getColor(R.color.card_background)).setProgressBackgroundColorSchemeColor(getColor(R.color.card_background)));
        swipeRefreshLayout.setEnableOverScrollDrag(true);
        swipeRefreshLayout.setEnableOverScrollBounce(true);
        swipeRefreshLayout.setEnableLoadMore(false);
        swipeRefreshLayout.setOnRefreshListener(v -> {
            swipeRefreshLayout.finishRefresh();
            setRecyclerViewData(LocalStorage.getAppDatabase().otpTokenDao().getAll());
        });
    }

    public void initBiometrics() {
        mFingerprintIdentify = new FingerprintIdentify(this);
        mFingerprintIdentify.setSupportAndroidL(true);
        mFingerprintIdentify.setExceptionListener(this);
        mFingerprintIdentify.init();
        if (mFingerprintIdentify.isFingerprintEnable()) {
            passcodeTip = R.string.tap_to_use_biometrics;
        } else {
            passcodeTip = R.string.unpin_to_show_code;
        }
        ((TextView) findViewById(R.id.activity_main_lock_text)).setText(passcodeTip);
    }

    @Override
    public void onClick(View view) {
        if (view == addEntry) {
            Intent intent = new Intent(this, TokenDetailActivity.class).setAction(Intent.ACTION_DEFAULT);
            startActivity(intent);
        } else if (view == eximportEntry) {
            Intent intent = new Intent(this, EximportActivity.class).setAction(Intent.ACTION_DEFAULT);
            startActivity(intent);
        } else if (view == settingEntry) {
            Intent intent = new Intent(this, SettingsActivity.class).setAction(Intent.ACTION_DEFAULT);
            startActivity(intent);
        } else if (view == scanEntry) {
            Intent intent = new Intent(this, ScanActivity.class).setAction(Intent.ACTION_DEFAULT);
            startActivity(intent);
        } else if (view == openDrawerButton) {
            mDrawerLayout.openDrawer(GravityCompat.START);
        } else if (view == passcodeTipView || view == passcodeIconView) {
            if (mFingerprintIdentify.isFingerprintEnable()) {
                bottomSheet = new BottomSheet(this);
                bottomSheet.setTitle(getString(R.string.verify_finger));
                bottomSheet.setDragBarVisible(false);
                bottomSheet.setLeftButtonVisible(false);
                bottomSheet.setRightButtonVisible(false);
                bottomSheet.setBackgroundColor(getColor(R.color.card_background));
                bottomSheet.setMainLayout(R.layout.layout_fingerprint);
                bottomSheet.show();
                bottomSheet.setOnCancelListener(dialogInterface -> mFingerprintIdentify.cancelIdentify());
                mFingerprintIdentify.resumeIdentify();
                mFingerprintIdentify.startIdentify(5, this);
            }
        } else if (view == themeEntry) {
            Intent intent = new Intent(this, ThemeActivity.class).setAction(Intent.ACTION_DEFAULT);
            startActivity(intent);
        } else if (view == githubEntry) {
            Intent intent = new Intent(this, WebViewActivity.class).setAction(Intent.ACTION_DEFAULT);
            intent.putExtra("url", getString(R.string.url_github));
            startActivity(intent);
        } else if (view == blogEntry) {
            Intent intent = new Intent(this, WebViewActivity.class).setAction(Intent.ACTION_DEFAULT);
            intent.putExtra("url", getString(R.string.url_blog));
            startActivity(intent);
        } else if (view == homeEntry) {
            Intent intent = new Intent(this, WebViewActivity.class).setAction(Intent.ACTION_DEFAULT);
            intent.putExtra("url", getString(R.string.url_home));
            startActivity(intent);
        } else if (view == dropboxEntry) {
            Intent intent = new Intent(this, DropboxActivity.class).setAction(Intent.ACTION_DEFAULT);
            startActivity(intent);
        } else if (view == changeViewButton) {
            AppSharedPreferenceUtil.setViewType(this, ViewType.values()[(AppSharedPreferenceUtil.getViewType(this).ordinal() + 1) % ViewType.values().length]);
            LiveEventBus.get(EventBusCode.CHANGE_VIEW_TYPE.getKey()).post("");
        } else if (view == exportImportbutton || view == goToImportButton) {
            List<String> strings = Arrays.asList(getResources().getStringArray(R.array.export_import_operation));
            ListBottomSheet bottomSheet = new ListBottomSheet(this, ListBottomSheetBean.strToBean(strings));
            bottomSheet.setOnItemClickedListener(position -> {
                if (position == 0) {
                    ExploreUtil.performFileSearch(this, IMPORT_ENCRYPT_REQUEST_CODE);
                } else if (position == 1) {
                    ExploreUtil.performFileSearch(this, IMPORT_URI_REQUEST_CODE);
                } else if (position == 2) {
                    ExploreUtil.performFileSearch(this, IMPORT_JSON_REQUEST_CODE);
                }
                bottomSheet.dismiss();
            });
            bottomSheet.show();
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
        if (bottomSheet != null) bottomSheet.cancel();
        isAuthed = true;
        refreshAuthState();
    }

    @Override
    public void onNotMatch(int availableTimes) {
        bottomSheet.setTitle(getString(R.string.verify_finger_fail));
        bottomSheet.setDragBarVisible(false);
        bottomSheet.setTitleColor(getColor(R.color.text_color_red));
        new Handler().postDelayed(() -> {
            bottomSheet.setTitle(getString(R.string.verify_finger));
            bottomSheet.setDragBarVisible(false);
            bottomSheet.setTitleColor(getColor(R.color.color_accent));
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

    @Override
    public void onActivityResult(int requestCode, int resultCode, Intent resultData) {
        super.onActivityResult(requestCode, resultCode, resultData);
        if (resultCode != Activity.RESULT_OK) return;
        Uri uri = resultData.getData();
        IDialog dialog = new IDialog(this);
        if (uri == null) return;
        switch (requestCode) {
            case IMPORT_ENCRYPT_REQUEST_CODE:
                dialog.setTitle(getString(R.string.dialog_title_import_encrypt_token));
                dialog.setMessage(String.format(getString(R.string.dialog_content_import_encrypt_token), UriUtil.getFileAbsolutePath(this, uri)));
                dialog.setOnClickBottomListener(new IDialog.OnClickBottomListener() {
                    @Override
                    public void onPositiveClick() {
                        if (PrivacyManager.haveSecret()) {
                            importEncryptFile(uri, PrivacyManager.getSecret());
                        } else {
                            redirectToEximport = true;
                            redirectUri = uri;
                            SecretBottomSheet bottomSheet = new SecretBottomSheet(MainActivity.this, SecretBottomSheet.MODE.PULL);
                            bottomSheet.setOnConfirmListener(MainActivity.this);
                            bottomSheet.show();
                        }
                    }

                    @Override
                    public void onNegtiveClick() {

                    }

                });
                dialog.show();
                break;
            case IMPORT_URI_REQUEST_CODE:
                dialog.setTitle(getString(R.string.dialog_title_import_uri_token));
                dialog.setMessage(String.format(getString(R.string.dialog_content_import_uri_token), UriUtil.getFileAbsolutePath(this, uri)));
                dialog.setOnClickBottomListener(new IDialog.OnClickBottomListener() {
                    @Override
                    public void onPositiveClick() {
                        try {
                            loadingDialog.setLoadingText(getString(R.string.loading_import)).show();
                            ImportTokenUtil.importUriFile(MainActivity.this, uri);
                            loadingDialog.close();
                            IToast.showBottom(MainActivity.this, getString(R.string.import_success));
                        } catch (Exception e) {
                            IToast.showBottom(MainActivity.this, getString(R.string.import_fail));
                        }
                    }

                    @Override
                    public void onNegtiveClick() {

                    }

                });
                dialog.show();
                break;
            case IMPORT_JSON_REQUEST_CODE:
                dialog.setTitle(getString(R.string.dialog_title_import_json_token));
                dialog.setMessage(String.format(getString(R.string.dialog_content_import_json_token), UriUtil.getFileAbsolutePath(this, uri)));
                dialog.setOnClickBottomListener(new IDialog.OnClickBottomListener() {
                    @Override
                    public void onPositiveClick() {
                        try {
                            loadingDialog.setLoadingText(getString(R.string.loading_import)).show();
                            ImportTokenUtil.importJsonFile(MainActivity.this, uri);
                            loadingDialog.close();
                            IToast.showBottom(MainActivity.this, getString(R.string.import_success));
                        } catch (Exception e) {
                            e.printStackTrace();
                            IToast.showBottom(MainActivity.this, getString(R.string.import_fail));
                        }
                    }

                    @Override
                    public void onNegtiveClick() {

                    }

                });
                dialog.show();
                break;
        }
    }

    void exportEncryptFile(Uri uri, String secret) {
        try {
            ExportTokenUtil.exportEncryptFile(MainActivity.this, uri, secret);
            IToast.showBottom(this, getString(R.string.export_success));
            askToSaveSecret(secret);
        } catch (Exception e) {
            IToast.showBottom(this, getString(R.string.export_fail));
        }
    }

    void importEncryptFile(Uri uri, String secret) {
        try {
            loadingDialog.setLoadingText(getString(R.string.loading_import)).show();
            ImportTokenUtil.importEncryptFile(MainActivity.this, uri, secret);
            loadingDialog.close();
            IToast.showBottom(MainActivity.this, getString(R.string.import_success));
            askToSaveSecret(secret);
        } catch (GeneralSecurityException e) {
            e.printStackTrace();
            askToRetry(uri);
        } catch (Exception e) {
            e.printStackTrace();
            IToast.showBottom(MainActivity.this, getString(R.string.import_fail));
        }
    }

    @Override
    public void onPushConfirmed(String secret) {
        if (redirectToEximport) {
            exportEncryptFile(redirectUri, secret);
            redirectUri = null;
            redirectToEximport = false;
        }
    }

    @Override
    public void onPullConfirmed(String secret) {
        if (redirectToEximport) {
            importEncryptFile(redirectUri, secret);
            redirectUri = null;
            redirectToEximport = false;
        }
    }

    @Override
    public void onSetSecretConfirmed(String secret) {
    }

    private void askToRetry(Uri uri) {
        IDialog dialog = new IDialog(this);
        dialog.setTitle(getString(R.string.dialog_title_wrong_secret));
        dialog.setMessage(getString(R.string.dialog_content_wrong_secret));
        dialog.setOnClickBottomListener(new IDialog.OnClickBottomListener() {
            @Override
            public void onPositiveClick() {
                redirectToEximport = true;
                redirectUri = uri;
                SecretBottomSheet bottomSheet = new SecretBottomSheet(MainActivity.this, SecretBottomSheet.MODE.PULL);
                bottomSheet.setOnConfirmListener(MainActivity.this);
                bottomSheet.show();
            }

            @Override
            public void onNegtiveClick() {

            }
        });
        dialog.show();
    }

    private void askToSaveSecret(String secret) {
        if (!PrivacyManager.haveSecret() || (!Objects.equals(PrivacyManager.getSecret(), secret))) {
            IDialog dialog = new IDialog(this);
            dialog.setTitle(getString(R.string.dialog_title_save_secret));
            dialog.setMessage(getString(R.string.dialog_content_save_secret));
            dialog.setOnClickBottomListener(new IDialog.OnClickBottomListener() {
                @Override
                public void onPositiveClick() {
                    PrivacyManager.setSecret(secret);
                }

                @Override
                public void onNegtiveClick() {

                }
            });
            dialog.show();
        }
    }
}