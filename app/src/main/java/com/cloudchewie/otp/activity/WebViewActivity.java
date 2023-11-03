package com.cloudchewie.otp.activity;

import android.annotation.SuppressLint;
import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.view.KeyEvent;
import android.view.View;
import android.webkit.WebSettings;
import android.widget.ImageView;
import android.widget.RelativeLayout;
import android.widget.TextView;
import android.widget.Toast;

import com.cloudchewie.otp.R;
import com.cloudchewie.ui.custom.IToast;
import com.cloudchewie.ui.custom.ProgressWebView;
import com.cloudchewie.ui.general.BottomSheet;
import com.cloudchewie.ui.item.VerticalIconTextItem;
import com.cloudchewie.util.system.ClipBoardUtil;
import com.cloudchewie.util.system.LanguageUtil;
import com.cloudchewie.util.system.SharedPreferenceCode;
import com.cloudchewie.util.system.SharedPreferenceUtil;
import com.cloudchewie.util.ui.StatusBarUtil;

public class WebViewActivity extends BaseActivity implements View.OnClickListener {
    ProgressWebView webView;
    ImageView closeButton;
    ImageView backButton;
    ImageView moreButton;
    TextView titleView;
    TextView bgTextView;
    RelativeLayout titleLayout;
    String originUrl;
    boolean enabledCache;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        StatusBarUtil.setStatusBarMarginTop(this);
        setContentView(R.layout.activity_webview);
        Intent intent = getIntent();
        originUrl = intent.getStringExtra("url");
        if (intent.getStringExtra("enabledCache") == null) {
            enabledCache = SharedPreferenceUtil.getBoolean(this, SharedPreferenceCode.ENABLE_WEB_CACHE.getKey(), true);
        } else {
            enabledCache = Boolean.parseBoolean(intent.getStringExtra("enabledCache"));
        }
        if (originUrl == null) {
            IToast.makeTextBottom(this, getString(R.string.fail_to_resolve_url), Toast.LENGTH_SHORT).show();
            finish();
        }
        backButton = findViewById(R.id.activity_webview_back);
        closeButton = findViewById(R.id.activity_webview_close);
        bgTextView = findViewById(R.id.activity_webview_slidingLayout).findViewById(R.id.layout_webview_bg_text);
        bgTextView.setText(getString(com.cloudchewie.ui.R.string.web_loading));
        moreButton = findViewById(R.id.activity_webview_more);
        titleView = findViewById(R.id.activity_webview_title);
        webView = findViewById(R.id.activity_webview_webview);
        titleLayout = findViewById(R.id.activity_webview_titlebar);
        backButton.setOnClickListener(this);
        closeButton.setOnClickListener(this);
        moreButton.setOnClickListener(this);
        initWebview();
    }

    @SuppressLint("SetJavaScriptEnabled")
    void initWebview() {
        webView.setTitleView(titleView);
        webView.setUrlView(bgTextView);
        webView.getSettings().setJavaScriptEnabled(true);
        webView.getSettings().setDomStorageEnabled(true);
        webView.getSettings().setUseWideViewPort(true);
        webView.getSettings().setLoadWithOverviewMode(true);
        webView.getSettings().setDefaultZoom(WebSettings.ZoomDensity.FAR);
        webView.getSettings().setRenderPriority(WebSettings.RenderPriority.HIGH);
        webView.getSettings().setBlockNetworkImage(true);
        webView.loadUrl(originUrl);
    }

    @Override
    public void onClick(View v) {
        if (v == backButton) {
            if (webView.canGoBack()) {
                webView.goBack();
            } else {
                finish();
            }
        }
        if (v == closeButton) {
            finish();
        } else if (v == moreButton) {
            BottomSheet bottomSheet = new BottomSheet(this);
            bottomSheet.setMainLayout(R.layout.layout_webview_more);
            VerticalIconTextItem copyUrlItem = bottomSheet.findViewById(R.id.webview_more_copy_url);
            VerticalIconTextItem refreshItem = bottomSheet.findViewById(R.id.webview_more_refresh);
            VerticalIconTextItem browserItem = bottomSheet.findViewById(R.id.webview_more_browser);
            TextView cancelView = bottomSheet.findViewById(R.id.webview_more_cancel);
            if (cancelView == null || copyUrlItem == null || refreshItem == null || browserItem == null) {
                IToast.showBottom(this, getString(R.string.fail_to_resolve_url));
                return;
            }
            if (LanguageUtil.getAppLanguage(WebViewActivity.this).equals(getString(R.string.language_english)) || LanguageUtil.getAppLanguage(WebViewActivity.this).equals(getString(R.string.language_japanese))) {
                browserItem.setMinLines(2);
                refreshItem.setMinLines(2);
                copyUrlItem.setMinLines(2);
            }
            bottomSheet.show();
            refreshItem.setOnClickListener(v1 -> {
                webView.reload();
                bottomSheet.dismiss();
            });
            browserItem.setOnClickListener(v1 -> {
                Intent intent = new Intent(Intent.ACTION_VIEW, Uri.parse(webView.getUrl()));
                startActivity(intent);
                bottomSheet.dismiss();
            });
            copyUrlItem.setOnClickListener(v1 -> {
                ClipBoardUtil.copy(webView.getUrl());
                IToast.makeTextBottom(WebViewActivity.this, getString(R.string.copy_success), Toast.LENGTH_SHORT).show();
                bottomSheet.dismiss();
            });
            cancelView.setOnClickListener(v1 -> bottomSheet.cancel());
        }
    }

    public void refresh() {
        webView.reload();
    }

    public void clearCache() {
        webView.clearCache(true);
    }

    public void clearData() {
        webView.clearCache(true);
        webView.clearFormData();
        webView.clearHistory();
        webView.clearMatches();
        deleteDatabase("WebView.db");
        deleteDatabase("WebViewCache.db");
        boolean deleted = getCacheDir().delete();
    }

    @Override
    public boolean onKeyDown(int keyCode, KeyEvent event) {
        if (keyCode == KeyEvent.KEYCODE_BACK && webView.canGoBack()) {
            webView.goBack();
            return true;
        }
        return super.onKeyDown(keyCode, event);
    }
}
