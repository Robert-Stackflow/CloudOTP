package com.cloudchewie.otp.activity;

import android.annotation.SuppressLint;
import android.app.Activity;
import android.content.Intent;
import android.content.pm.ActivityInfo;
import android.net.Uri;
import android.os.Bundle;
import android.view.View;
import android.widget.ImageButton;
import android.widget.RelativeLayout;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.appcompat.widget.AppCompatButton;
import androidx.constraintlayout.widget.ConstraintLayout;
import androidx.core.view.GravityCompat;
import androidx.drawerlayout.widget.DrawerLayout;
import androidx.recyclerview.widget.ItemTouchHelper;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;
import androidx.recyclerview.widget.StaggeredGridLayoutManager;

import com.blankj.utilcode.util.ThreadUtils;
import com.cloudchewie.otp.R;
import com.cloudchewie.otp.adapter.CustomItemHelpCallBack;
import com.cloudchewie.otp.adapter.CustomTokenListAdapter;
import com.cloudchewie.otp.adapter.DoubleColumnTokenListAdapter;
import com.cloudchewie.otp.adapter.SingleColumnTokenListAdapter;
import com.cloudchewie.otp.appwidget.SimpleRemoteViewsManager;
import com.cloudchewie.otp.database.AppSharedPreferenceUtil;
import com.cloudchewie.otp.database.LocalStorage;
import com.cloudchewie.otp.database.OtpTokenManager;
import com.cloudchewie.otp.database.PrivacyManager;
import com.cloudchewie.otp.entity.ImportAnalysis;
import com.cloudchewie.otp.entity.ListBottomSheetBean;
import com.cloudchewie.otp.entity.OtpToken;
import com.cloudchewie.otp.util.ExploreUtil;
import com.cloudchewie.otp.util.authenticator.ExportTokenUtil;
import com.cloudchewie.otp.util.authenticator.ImportTokenUtil;
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
import com.cloudchewie.ui.item.EntryItem;
import com.cloudchewie.ui.loadingdialog.view.LoadingDialog;
import com.cloudchewie.util.system.SharedPreferenceCode;
import com.cloudchewie.util.system.SharedPreferenceUtil;
import com.cloudchewie.util.system.UriUtil;
import com.cloudchewie.util.ui.StatusBarUtil;
import com.jeremyliao.liveeventbus.LiveEventBus;
import com.scwang.smart.refresh.header.MaterialHeader;
import com.scwang.smart.refresh.layout.api.RefreshLayout;

import java.security.GeneralSecurityException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Objects;

public class MainActivity extends BaseActivity implements View.OnClickListener, SecretBottomSheet.OnConfirmListener, CustomTokenListAdapter.ItemOperationListener {
    private static final int IMPORT_ENCRYPT_REQUEST_CODE = 42;
    private static final int EXPORT_ENCRYPT_REQUEST_CODE = 43;
    private static final int EXPORT_URI_REQUEST_CODE = 44;
    private static final int IMPORT_URI_REQUEST_CODE = 45;
    private static final int IMPORT_JSON_REQUEST_CODE = 46;
    private static final int EXPORT_JSON_REQUEST_CODE = 47;
    RefreshLayout swipeRefreshLayout;
    FloatingActionButton lockButton;
    ImageButton operationDoneButton;
    ImageButton operationDeleteButton;
    ImageButton operationExportButton;
    ImageButton operationSelectAllButton;
    TextView selectCountTextView;
    ImageButton openDrawerButton;
    ImageButton changeViewButton;
    ImageButton exportImportbutton;
    RecyclerView recyclerView;
    CustomTokenListAdapter<? extends RecyclerView.ViewHolder> adapter;
    RelativeLayout blankLayout;
    ConstraintLayout operationBar;
    ConstraintLayout titlebar;
    EntryItem addEntry;
    EntryItem eximportEntry;
    ImageButton scanEntry;
    EntryItem themeEntry;
    EntryItem settingEntry;
    EntryItem githubEntry;
    EntryItem blogEntry;
    EntryItem dropboxEntry;
    SpacingItemDecoration bottomSpacing;
    SpacingItemDecoration rightSpacing;
    AppCompatButton goToImportButton;
    LoadingDialog loadingDialog;
    List<OtpToken> otpTokens = new ArrayList<>();
    List<OtpToken> selectedOtpTokens = new ArrayList<>();
    private String EXPORT_PREFIX = "Token_";
    private boolean redirectToEximport = false;
    private Uri redirectUri;
    private DrawerLayout mDrawerLayout;
    private RelativeLayout mDrawer;
    private boolean isInSelectionMode = false;
    private boolean isAllSelected = false;

    @Override
    @SuppressLint("SourceLockedOrientationActivity")
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
        setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_PORTRAIT);
        initView();
        initEvent();
        initSwipeRefresh();
        refresh();
        SimpleRemoteViewsManager.refresh(this);
        goToVerify();
    }

    void initEvent() {
        LiveEventBus.get(EventBusCode.CHANGE_THEME.getKey(), String.class).observe(this, s -> recreate());
        LiveEventBus.get(EventBusCode.CHANGE_VIEW_TYPE.getKey(), String.class).observe(this, s -> setRecyclerViewData(OtpTokenManager.getTokens()));
        LiveEventBus.get(EventBusCode.CHANGE_TOKEN.getKey()).observe(this, s -> swipeRefreshLayout.autoRefresh());
        LiveEventBus.get(EventBusCode.CHANGE_TOKEN_NEED_AUTH.getKey()).observe(this, s -> {
            lockButton.setVisibility(SharedPreferenceUtil.getBoolean(this, SharedPreferenceCode.TOKEN_NEED_AUTH.getKey(), true) ? View.VISIBLE : View.GONE);
            refresh();
        });
        LiveEventBus.get(EventBusCode.CHANGE_PASSCODE.getKey()).observe(this, s -> lockButton.setOnClickListener(view -> {
            PrivacyManager.lock();
            goToVerify(true);
        }));
    }

    void initView() {
        bottomSpacing = new SpacingItemDecoration(this, (int) getResources().getDimension(R.dimen.dp3), Direction.BOTTOM);
        rightSpacing = new SpacingItemDecoration(this, (int) getResources().getDimension(R.dimen.dp3), Direction.RIGHT);
        StatusBarUtil.setStatusBarMarginTop(findViewById(R.id.activity_main_logo), 0, StatusBarUtil.getStatusBarHeight(this), 0, 0);
        StatusBarUtil.setStatusBarMarginTop(findViewById(R.id.activity_main_bar_layout), 0, StatusBarUtil.getStatusBarHeight(this), 0, 0);
        mDrawerLayout = findViewById(R.id.activity_main);
        mDrawer = findViewById(R.id.activity_main_drawer);
        operationBar = findViewById(R.id.activity_main_operation_bar);
        titlebar = findViewById(R.id.activity_main_titlebar);
        operationSelectAllButton = findViewById(R.id.activity_main_operation_select_all);
        operationExportButton = findViewById(R.id.activity_main_operation_export);
        operationDeleteButton = findViewById(R.id.activity_main_operation_delete);
        operationDoneButton = findViewById(R.id.activity_main_operation_done);
        selectCountTextView = findViewById(R.id.activity_main_select_count);
        operationBar.setVisibility(View.GONE);
        blankLayout = findViewById(R.id.activity_main_blank_layout);
        addEntry = findViewById(R.id.activity_main_entry_add);
        scanEntry = findViewById(R.id.activity_main_scan);
        dropboxEntry = findViewById(R.id.activity_main_entry_dropbox);
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
        operationSelectAllButton.setOnClickListener(this);
        operationDeleteButton.setOnClickListener(this);
        operationExportButton.setOnClickListener(this);
        operationDoneButton.setOnClickListener(this);
        dropboxEntry.setOnClickListener(this);
        exportImportbutton.setOnClickListener(this);
        goToImportButton.setOnClickListener(this);
        eximportEntry.setOnClickListener(this);
        addEntry.setOnClickListener(this);
        scanEntry.setOnClickListener(this);
        settingEntry.setOnClickListener(this);
        openDrawerButton.setOnClickListener(this);
        changeViewButton.setOnClickListener(this);
        themeEntry.setOnClickListener(this);
        githubEntry.setOnClickListener(this);
        blogEntry.setOnClickListener(this);
        lockButton.setOnClickListener(view -> {
            PrivacyManager.lock();
            goToVerify(true);
        });
        loadingDialog = new LoadingDialog(this);
        lockButton.setVisibility(SharedPreferenceUtil.getBoolean(this, SharedPreferenceCode.TOKEN_NEED_AUTH.getKey(), true) ? View.VISIBLE : View.GONE);
        recyclerView.addOnScrollListener(new RecyclerView.OnScrollListener() {
            @Override
            public void onScrolled(@NonNull RecyclerView recyclerView, int dx, int dy) {
                if (SharedPreferenceUtil.getBoolean(MainActivity.this, SharedPreferenceCode.TOKEN_NEED_AUTH.getKey(), true)) {
                    if (dy > 0 || dy < 0 && lockButton.isShown()) {
                        lockButton.hide(true);
                    }
                    if (isSlideToBottom(recyclerView) && adapter instanceof SingleColumnTokenListAdapter) {
                        lockButton.hide(true);
                    }
                }
            }

            @Override
            public void onScrollStateChanged(@NonNull RecyclerView recyclerView, int newState) {
                if (SharedPreferenceUtil.getBoolean(MainActivity.this, SharedPreferenceCode.TOKEN_NEED_AUTH.getKey(), true)) {
                    if (newState == RecyclerView.SCROLL_STATE_IDLE && !(isSlideToBottom(recyclerView) && adapter instanceof SingleColumnTokenListAdapter)) {
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
        otpTokens = tokenList;
        switch (AppSharedPreferenceUtil.getViewType(this)) {
            case singleColumn:
                adapter = new SingleColumnTokenListAdapter(this, tokenList);
                adapter.setItemOperationListener(this);
                recyclerView.setAdapter(adapter);
                recyclerView.setLayoutManager(new LinearLayoutManager(this));
                recyclerView.removeItemDecoration(bottomSpacing);
                recyclerView.addItemDecoration(bottomSpacing);
                recyclerView.setItemViewCacheSize(500);
                new ItemTouchHelper(new CustomItemHelpCallBack(adapter)).attachToRecyclerView(recyclerView);
                break;
            case doubleColumn:
                adapter = new DoubleColumnTokenListAdapter(this, tokenList);
                recyclerView.setAdapter(adapter);
                recyclerView.setLayoutManager(new StaggeredGridLayoutManager(2, RecyclerView.VERTICAL));
                recyclerView.removeItemDecoration(bottomSpacing);
                recyclerView.removeItemDecoration(rightSpacing);
                recyclerView.addItemDecoration(bottomSpacing);
                recyclerView.addItemDecoration(rightSpacing);
                recyclerView.setItemViewCacheSize(500);
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
                return OtpTokenManager.getTokens();
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

    public void refresh() {
        refreshData();
        if (SharedPreferenceUtil.getBoolean(this, SharedPreferenceCode.TOKEN_NEED_AUTH.getKey(), true))
            lockButton.setVisibility(View.VISIBLE);
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
    }

    void initSwipeRefresh() {
        swipeRefreshLayout = findViewById(R.id.activity_main_swipe_refresh);
        swipeRefreshLayout.setRefreshHeader(new MaterialHeader(this).setColorSchemeColors(ThemeUtil.getPrimaryColor(this)).setProgressBackgroundColorSchemeColor(getColor(R.color.card_background)).setProgressBackgroundColorSchemeColor(getColor(R.color.card_background)));
        swipeRefreshLayout.setEnableOverScrollDrag(true);
        swipeRefreshLayout.setEnableOverScrollBounce(true);
        swipeRefreshLayout.setEnableLoadMore(false);
        swipeRefreshLayout.setOnRefreshListener(v -> {
            swipeRefreshLayout.finishRefresh();
            SimpleRemoteViewsManager.refresh(MainActivity.this);
            setRecyclerViewData(OtpTokenManager.getTokens());
        });
    }

    @Override
    public void onClick(View view) {
        if (view == addEntry) {
            Intent intent = new Intent(this, TokenDetailActivity.class).setAction(Intent.ACTION_DEFAULT);
            startActivity(intent);
        } else if (view == eximportEntry) {
            Intent intent = new Intent(this, MainActivity.class).setAction(Intent.ACTION_DEFAULT);
            startActivity(intent);
        } else if (view == settingEntry) {
            Intent intent = new Intent(this, SettingsActivity.class).setAction(Intent.ACTION_DEFAULT);
            startActivity(intent);
        } else if (view == scanEntry) {
            Intent intent = new Intent(this, ScanActivity.class).setAction(Intent.ACTION_DEFAULT);
            startActivity(intent);
        } else if (view == openDrawerButton) {
            mDrawerLayout.openDrawer(GravityCompat.START);
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
        } else if (view == dropboxEntry) {
            Intent intent = new Intent(this, DropboxActivity.class).setAction(Intent.ACTION_DEFAULT);
            startActivity(intent);
        } else if (view == changeViewButton) {
            AppSharedPreferenceUtil.setViewType(this, ViewType.values()[(AppSharedPreferenceUtil.getViewType(this).ordinal() + 1) % ViewType.values().length]);
            LiveEventBus.get(EventBusCode.CHANGE_VIEW_TYPE.getKey()).post("");
        } else if (view == exportImportbutton || view == goToImportButton) {
            List<String> strings = Arrays.asList(getResources().getStringArray(R.array.import_operation));
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
        } else if (view == operationSelectAllButton) {
            isAllSelected = !isAllSelected;
            refreshSelectAllState(true);
        } else if (view == operationExportButton) {
            List<String> strings = Arrays.asList(getResources().getStringArray(R.array.export_operation));
            ListBottomSheet bottomSheet = new ListBottomSheet(this, ListBottomSheetBean.strToBean(strings));
            bottomSheet.setOnItemClickedListener(position -> {
                if (position == 0) {
                    ExploreUtil.createFile(this, "application/octet-stream", EXPORT_PREFIX, "db", EXPORT_ENCRYPT_REQUEST_CODE, true);
                } else if (position == 1) {
                    IDialog dialog = new IDialog(this);
                    dialog.setTitle(getString(R.string.dialog_title_warning_text_export));
                    dialog.setMessage(getString(R.string.dialog_content_warning_text_export));
                    dialog.setOnClickBottomListener(new IDialog.OnClickBottomListener() {
                        @Override
                        public void onPositiveClick() {
                            ExploreUtil.createFile(MainActivity.this, "text/plain", EXPORT_PREFIX, "txt", EXPORT_URI_REQUEST_CODE, true);
                        }

                        @Override
                        public void onNegtiveClick() {

                        }
                    });
                    dialog.show();
                } else if (position == 2) {
                    IDialog dialog = new IDialog(this);
                    dialog.setTitle(getString(R.string.dialog_title_warning_text_export));
                    dialog.setMessage(getString(R.string.dialog_content_warning_text_export));
                    dialog.setOnClickBottomListener(new IDialog.OnClickBottomListener() {
                        @Override
                        public void onPositiveClick() {
                            ExploreUtil.createFile(MainActivity.this, "application/json", EXPORT_PREFIX, "json", EXPORT_JSON_REQUEST_CODE, true);
                        }

                        @Override
                        public void onNegtiveClick() {

                        }
                    });
                    dialog.show();
                }
                bottomSheet.dismiss();
            });
            bottomSheet.show();
        } else if (view == operationDeleteButton) {
            IDialog dialog = new IDialog(this);
            dialog.setTitle(getString(R.string.dialog_title_delete_token));
            dialog.setMessage(getString(R.string.dialog_content_delete_token));
            dialog.setOnClickBottomListener(new IDialog.OnClickBottomListener() {
                @Override
                public void onPositiveClick() {
                    adapter.delete();
                    if (isAllSelected) {
                        isInSelectionMode = false;
                        isAllSelected = false;
                        refreshSelectAllState(false);
                        refresh();
                    }
                    IToast.showBottom(MainActivity.this, getString(R.string.delete_token_success));
                    refreshSelectionState(true);
                }

                @Override
                public void onNegtiveClick() {
                }

            });
            dialog.show();
        } else if (view == operationDoneButton) {
            isInSelectionMode = false;
            isAllSelected = false;
            refreshSelectAllState(false);
            refreshSelectionState(true);
        }
    }

    @Override
    public void onActivityResult(int requestCode, int resultCode, Intent resultData) {
        super.onActivityResult(requestCode, resultCode, resultData);
        if (resultCode != Activity.RESULT_OK) return;
        Uri uri = resultData.getData();
        IDialog dialog = new IDialog(this);
        if (uri == null) return;
        switch (requestCode) {
            case EXPORT_ENCRYPT_REQUEST_CODE:
                if (PrivacyManager.haveSecret()) {
                    exportEncryptFile(uri, PrivacyManager.getSecret());
                } else {
                    redirectToEximport = true;
                    redirectUri = uri;
                    SecretBottomSheet bottomSheet = new SecretBottomSheet(this, SecretBottomSheet.MODE.PUSH);
                    bottomSheet.setOnConfirmListener(this);
                    bottomSheet.show();
                }
                break;
            case EXPORT_URI_REQUEST_CODE:
                try {
                    loadingDialog.setLoadingText(getString(R.string.loading_export)).show();
                    ExportTokenUtil.exportUriFile(MainActivity.this, uri, selectedOtpTokens);
                    loadingDialog.close();
                    IToast.showBottom(MainActivity.this, getString(R.string.export_success));
                } catch (Exception e) {
                    loadingDialog.close();
                    IToast.showBottom(MainActivity.this, getString(R.string.export_fail));
                }
                break;
            case EXPORT_JSON_REQUEST_CODE:
                try {
                    loadingDialog.setLoadingText(getString(R.string.loading_export)).show();
                    ExportTokenUtil.exportJsonFile(MainActivity.this, uri, selectedOtpTokens);
                    loadingDialog.close();
                    IToast.showBottom(MainActivity.this, getString(R.string.export_success));
                } catch (Exception e) {
                    e.printStackTrace();
                    loadingDialog.close();
                    IToast.showBottom(MainActivity.this, getString(R.string.export_fail));
                }
                break;
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
                            ImportAnalysis importAnalysis = ImportTokenUtil.importUriFile(MainActivity.this, uri);
                            loadingDialog.close();
                            IToast.showBottom(MainActivity.this, importAnalysis.toToast(MainActivity.this));
                        } catch (Exception e) {
                            loadingDialog.close();
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
                            ImportAnalysis importAnalysis = ImportTokenUtil.importJsonFile(MainActivity.this, uri);
                            loadingDialog.close();
                            IToast.showBottom(MainActivity.this, importAnalysis.toToast(MainActivity.this));
                        } catch (Exception e) {
                            e.printStackTrace();
                            loadingDialog.close();
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
            loadingDialog.setLoadingText(getString(R.string.loading_export)).show();
            if (isInSelectionMode) {
                ExportTokenUtil.exportEncryptFile(MainActivity.this, uri, secret, selectedOtpTokens);
            } else {
                ExportTokenUtil.exportEncryptFile(MainActivity.this, uri, secret);
            }
            loadingDialog.close();
            IToast.showBottom(this, getString(R.string.export_success));
            askToSaveSecret(secret);
        } catch (Exception e) {
            loadingDialog.close();
            IToast.showBottom(this, getString(R.string.export_fail));
        }
    }

    void importEncryptFile(Uri uri, String secret) {
        try {
            loadingDialog.setLoadingText(getString(R.string.loading_import)).show();
            ImportAnalysis importAnalysis = ImportTokenUtil.importEncryptFile(MainActivity.this, uri, secret);
            loadingDialog.close();
            IToast.showBottom(MainActivity.this, importAnalysis.toToast(this));
            askToSaveSecret(secret);
        } catch (GeneralSecurityException e) {
            e.printStackTrace();
            loadingDialog.close();
            askToRetry(uri);
        } catch (Exception e) {
            e.printStackTrace();
            loadingDialog.close();
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

    @Override
    public void onBackPressed() {
        if (isInSelectionMode) {
            isInSelectionMode = false;
            isAllSelected = false;
            refreshSelectAllState(false);
            refreshSelectionState(true);
        } else super.onBackPressed();
    }

    private void refreshSelectAllState(boolean subjective) {
        if (isAllSelected) {
            if (subjective && adapter != null) adapter.selectAll();
            operationSelectAllButton.setImageResource(R.drawable.ic_material_checkbox_checked);
        } else {
            if (subjective && adapter != null) adapter.unSelectAll();
            operationSelectAllButton.setImageResource(R.drawable.ic_material_checkbox_unchecked);
        }
    }

    private void refreshSelectionState(boolean subjective) {
        if(selectedOtpTokens.size()==0){
            operationExportButton.setEnabled(false);
            operationDeleteButton.setEnabled(false);
            operationExportButton.setActivated(false);
            operationDeleteButton.setActivated(false);
        }else{
            operationExportButton.setEnabled(true);
            operationDeleteButton.setEnabled(true);
            operationExportButton.setActivated(true);
            operationDeleteButton.setActivated(true);
        }
        if (isInSelectionMode) {
            titlebar.setVisibility(View.GONE);
            operationBar.setVisibility(View.VISIBLE);
            lockButton.setVisibility(View.GONE);
            selectCountTextView.setText(String.format(getString(R.string.select_count), selectedOtpTokens.size()));
            swipeRefreshLayout.setEnableRefresh(false);
            mDrawerLayout.setDrawerLockMode(DrawerLayout.LOCK_MODE_LOCKED_CLOSED);
            adapter.setInSelectionMode(true, subjective);
        } else {
            titlebar.setVisibility(View.VISIBLE);
            operationBar.setVisibility(View.GONE);
            lockButton.setVisibility(SharedPreferenceUtil.getBoolean(this, SharedPreferenceCode.TOKEN_NEED_AUTH.getKey(), true) ? View.VISIBLE : View.GONE);
            swipeRefreshLayout.setEnableRefresh(true);
            mDrawerLayout.setDrawerLockMode(DrawerLayout.LOCK_MODE_UNLOCKED);
            adapter.setInSelectionMode(false, subjective);
            selectedOtpTokens = new ArrayList<>();
        }
    }

    @Override
    public void onItemLongCick(OtpToken otpToken) {
        if (!isInSelectionMode) {
            isInSelectionMode = true;
            refreshSelectionState(true);
        }
    }

    @Override
    public void onItemSelectStateChanged() {
        selectedOtpTokens = new ArrayList<>();
        for (OtpToken otpToken : otpTokens) {
            if (otpToken.isSelected())
                selectedOtpTokens.add(otpToken);
        }
        isAllSelected = selectedOtpTokens.size() == otpTokens.size();
        refreshSelectAllState(false);
        refreshSelectionState(false);
    }

}