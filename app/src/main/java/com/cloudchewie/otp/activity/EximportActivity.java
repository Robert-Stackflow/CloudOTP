package com.cloudchewie.otp.activity;

import android.annotation.SuppressLint;
import android.app.Activity;
import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.view.View;

import com.cloudchewie.otp.R;
import com.cloudchewie.otp.entity.ImportAnalysis;
import com.cloudchewie.otp.util.ExploreUtil;
import com.cloudchewie.otp.util.authenticator.ExportTokenUtil;
import com.cloudchewie.otp.util.authenticator.ImportTokenUtil;
import com.cloudchewie.otp.util.database.PrivacyManager;
import com.cloudchewie.otp.widget.SecretBottomSheet;
import com.cloudchewie.ui.custom.IDialog;
import com.cloudchewie.ui.custom.IToast;
import com.cloudchewie.ui.custom.TitleBar;
import com.cloudchewie.ui.item.EntryItem;
import com.cloudchewie.ui.loadingdialog.view.LoadingDialog;
import com.cloudchewie.util.system.UriUtil;
import com.cloudchewie.util.ui.StatusBarUtil;
import com.scwang.smart.refresh.layout.api.RefreshLayout;

import java.security.GeneralSecurityException;
import java.util.Objects;

public class EximportActivity extends BaseActivity implements View.OnClickListener, SecretBottomSheet.OnConfirmListener {
    private static final int IMPORT_ENCRYPT_REQUEST_CODE = 42;
    private static final int EXPORT_ENCRYPT_REQUEST_CODE = 43;
    private static final int EXPORT_URI_REQUEST_CODE = 44;
    private static final int IMPORT_URI_REQUEST_CODE = 45;
    private static final int IMPORT_JSON_REQUEST_CODE = 46;
    private static final int EXPORT_JSON_REQUEST_CODE = 47;
    RefreshLayout swipeRefreshLayout;
    EntryItem setSecretEntry;
    EntryItem importEncryptEntry;
    EntryItem importUriEntry;
    EntryItem importJsonEntry;
    EntryItem exportEncryptEntry;
    EntryItem exportUriEntry;
    EntryItem exportJsonEntry;
    LoadingDialog loadingDialog;
    private String EXPORT_PREFIX = "Token_";
    private boolean redirectToEximport = false;
    private Uri redirectUri;

    @SuppressLint("SetTextI18n")
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        StatusBarUtil.setStatusBarMarginTop(this);
        setContentView(R.layout.activity_eximport);
        ((TitleBar) findViewById(R.id.activity_eximport_titlebar)).setLeftButtonClickListener(v -> finishAfterTransition());
        ((TitleBar) findViewById(R.id.activity_eximport_titlebar)).setRightButtonClickListener(v -> {
            IDialog dialog = new IDialog(this);
            dialog.setTitle(getString(R.string.dialog_title_unified_secret_info));
            dialog.setSingle(true);
            dialog.setMessage(getString(R.string.dialog_content_unified_secret_info));
            dialog.show();
        });
        exportJsonEntry = findViewById(R.id.entry_export_json);
        exportEncryptEntry = findViewById(R.id.entry_export_encrypt);
        exportUriEntry = findViewById(R.id.entry_export_uri);
        importJsonEntry = findViewById(R.id.entry_import_json);
        importEncryptEntry = findViewById(R.id.entry_import_encrypt);
        importUriEntry = findViewById(R.id.entry_import_uri);
        setSecretEntry = findViewById(R.id.entry_set_secret);
        exportJsonEntry.setOnClickListener(this);
        exportUriEntry.setOnClickListener(this);
        exportEncryptEntry.setOnClickListener(this);
        importEncryptEntry.setOnClickListener(this);
        importJsonEntry.setOnClickListener(this);
        importUriEntry.setOnClickListener(this);
        setSecretEntry.setOnClickListener(this);
        swipeRefreshLayout = findViewById(R.id.activity_eximport_swipe_refresh);
        swipeRefreshLayout.setEnableOverScrollDrag(true);
        swipeRefreshLayout.setEnableOverScrollBounce(true);
        swipeRefreshLayout.setEnableLoadMore(false);
        swipeRefreshLayout.setEnablePureScrollMode(true);
        loadingDialog = new LoadingDialog(this);
        refreshState();
    }

    @Override
    public void onClick(View view) {
        if (view == setSecretEntry) {
            if (PrivacyManager.haveSecret()) {
                SecretBottomSheet bottomSheet = new SecretBottomSheet(this, SecretBottomSheet.MODE.CHANGE_SECRET);
                bottomSheet.setOnConfirmListener(this);
                bottomSheet.show();
            } else {
                SecretBottomSheet bottomSheet = new SecretBottomSheet(this, SecretBottomSheet.MODE.SET_SECRET);
                bottomSheet.setOnConfirmListener(this);
                bottomSheet.show();
            }
        } else if (view == exportJsonEntry) {
            IDialog dialog = new IDialog(this);
            dialog.setTitle(getString(R.string.dialog_title_warning_text_export));
            dialog.setMessage(getString(R.string.dialog_content_warning_text_export));
            dialog.setOnClickBottomListener(new IDialog.OnClickBottomListener() {
                @Override
                public void onPositiveClick() {
                    ExploreUtil.createFile(EximportActivity.this, "application/json", EXPORT_PREFIX, "json", EXPORT_JSON_REQUEST_CODE, true);
                }

                @Override
                public void onNegtiveClick() {

                }
            });
            dialog.show();
        } else if (view == exportEncryptEntry) {
            ExploreUtil.createFile(this, "application/octet-stream", EXPORT_PREFIX, "db", EXPORT_ENCRYPT_REQUEST_CODE, true);
        } else if (view == exportUriEntry) {
            IDialog dialog = new IDialog(this);
            dialog.setTitle(getString(R.string.dialog_title_warning_text_export));
            dialog.setMessage(getString(R.string.dialog_content_warning_text_export));
            dialog.setOnClickBottomListener(new IDialog.OnClickBottomListener() {
                @Override
                public void onPositiveClick() {
                    ExploreUtil.createFile(EximportActivity.this, "text/plain", EXPORT_PREFIX, "txt", EXPORT_URI_REQUEST_CODE, true);
                }

                @Override
                public void onNegtiveClick() {

                }
            });
            dialog.show();
        } else if (view == importEncryptEntry) {
            ExploreUtil.performFileSearch(this, IMPORT_ENCRYPT_REQUEST_CODE);
        } else if (view == importUriEntry) {
            ExploreUtil.performFileSearch(this, IMPORT_URI_REQUEST_CODE);
        } else if (view == importJsonEntry) {
            ExploreUtil.performFileSearch(this, IMPORT_JSON_REQUEST_CODE);
        }
    }

    private void refreshState() {
        if (PrivacyManager.haveSecret()) {
            setSecretEntry.setTitle(getString(R.string.change_unified_secret));
        } else {
            setSecretEntry.setTitle(getString(R.string.set_unified_secret));
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
                            SecretBottomSheet bottomSheet = new SecretBottomSheet(EximportActivity.this, SecretBottomSheet.MODE.PULL);
                            bottomSheet.setOnConfirmListener(EximportActivity.this);
                            bottomSheet.show();
                        }
                    }

                    @Override
                    public void onNegtiveClick() {

                    }

                });
                dialog.show();
                break;
            case EXPORT_URI_REQUEST_CODE:
                try {
                    loadingDialog.setLoadingText(getString(R.string.loading_export)).show();
                    ExportTokenUtil.exportUriFile(EximportActivity.this, uri);
                    loadingDialog.close();
                    IToast.showBottom(EximportActivity.this, getString(R.string.export_success));
                } catch (Exception e) {
                    loadingDialog.close();
                    IToast.showBottom(EximportActivity.this, getString(R.string.export_fail));
                }
                break;
            case IMPORT_URI_REQUEST_CODE:
                dialog.setTitle(getString(R.string.dialog_title_import_uri_token));
                dialog.setMessage(String.format(getString(R.string.dialog_content_import_uri_token), UriUtil.getFileAbsolutePath(this, uri)));
                dialog.setOnClickBottomListener(new IDialog.OnClickBottomListener() {
                    @Override
                    public void onPositiveClick() {
                        try {
                            loadingDialog.setLoadingText(getString(R.string.loading_import)).show();
                            ImportAnalysis importAnalysis = ImportTokenUtil.importUriFile(EximportActivity.this, uri);
                            loadingDialog.close();
                            IToast.showBottom(EximportActivity.this, importAnalysis.toToast(EximportActivity.this));
                        } catch (Exception e) {
                            loadingDialog.close();
                            IToast.showBottom(EximportActivity.this, getString(R.string.import_fail));
                        }
                    }

                    @Override
                    public void onNegtiveClick() {

                    }

                });
                dialog.show();
                break;
            case EXPORT_JSON_REQUEST_CODE:
                try {
                    loadingDialog.setLoadingText(getString(R.string.loading_export)).show();
                    ExportTokenUtil.exportJsonFile(EximportActivity.this, uri);
                    loadingDialog.close();
                    IToast.showBottom(EximportActivity.this, getString(R.string.export_success));
                } catch (Exception e) {
                    e.printStackTrace();
                    loadingDialog.close();
                    IToast.showBottom(EximportActivity.this, getString(R.string.export_fail));
                }
                break;
            case IMPORT_JSON_REQUEST_CODE:
                dialog.setTitle(getString(R.string.dialog_title_import_json_token));
                dialog.setMessage(String.format(getString(R.string.dialog_content_import_json_token), UriUtil.getFileAbsolutePath(this, uri)));
                dialog.setOnClickBottomListener(new IDialog.OnClickBottomListener() {
                    @Override
                    public void onPositiveClick() {
                        try {
                            loadingDialog.setLoadingText(getString(R.string.loading_import)).show();
                            ImportAnalysis importAnalysis = ImportTokenUtil.importJsonFile(EximportActivity.this, uri);
                            loadingDialog.close();
                            IToast.showBottom(EximportActivity.this, importAnalysis.toToast(EximportActivity.this));
                        } catch (Exception e) {
                            e.printStackTrace();
                            loadingDialog.close();
                            IToast.showBottom(EximportActivity.this, getString(R.string.import_fail));
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
            ExportTokenUtil.exportEncryptFile(EximportActivity.this, uri, secret);
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
            ImportAnalysis importAnalysis = ImportTokenUtil.importEncryptFile(EximportActivity.this, uri, secret);
            loadingDialog.close();
            IToast.showBottom(EximportActivity.this, importAnalysis.toToast(EximportActivity.this));
            askToSaveSecret(secret);
        } catch (GeneralSecurityException e) {
            e.printStackTrace();
            loadingDialog.close();
            askToRetry(uri);
        } catch (Exception e) {
            e.printStackTrace();
            loadingDialog.close();
            IToast.showBottom(EximportActivity.this, getString(R.string.import_fail));
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
        PrivacyManager.setSecret(secret);
        refreshState();
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
                SecretBottomSheet bottomSheet = new SecretBottomSheet(EximportActivity.this, SecretBottomSheet.MODE.PULL);
                bottomSheet.setOnConfirmListener(EximportActivity.this);
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
                    refreshState();
                }

                @Override
                public void onNegtiveClick() {

                }
            });
            dialog.show();
        }
    }
}
