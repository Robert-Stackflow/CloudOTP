package com.cloudchewie.ui.custom;

import android.annotation.SuppressLint;
import android.content.Context;
import android.content.Intent;
import android.graphics.Bitmap;
import android.net.Uri;
import android.os.Handler;
import android.os.Message;
import android.util.AttributeSet;
import android.util.Log;
import android.view.View;
import android.view.ViewGroup;
import android.webkit.WebChromeClient;
import android.webkit.WebResourceError;
import android.webkit.WebResourceRequest;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.TextView;

import com.cloudchewie.ui.R;

import java.net.URI;
import java.net.URISyntaxException;
import java.util.Timer;
import java.util.TimerTask;

public class ProgressWebView extends WebView {
    private final WebViewProgressBar progressBar;
    private final Handler handler;
    private final WebView mWebView;
    private TextView titleView;
    private TextView urlView;
    private Timer mTimer;
    private TimerTask mTimerTask;
    private final int TIMEOUT = 10000;
    private final int TIMEOUT_ERROR = 9527;
    @SuppressLint("HandlerLeak")
    private Handler mHandler = new Handler() {
        public void handleMessage(Message msg) {
            if (msg.what == TIMEOUT_ERROR) {
                IToast.showBottom(getContext(), "Error:Timeout");
            }
        }
    };

    public void setUrlView(TextView urlView) {
        this.urlView = urlView;
    }

    private final Runnable runnable = new Runnable() {
        @Override
        public void run() {
            progressBar.setVisibility(View.GONE);
        }
    };

    public void setCacheEnabled(boolean enabled) {
//        mWebView.getSettings().setCacheMode(enabled);
    }

    public interface OnErrorListener {
        void onError(WebView view, WebResourceRequest request, WebResourceError error);
    }

    OnErrorListener onErrorListener;

    public ProgressWebView(Context context, AttributeSet attrs) {
        super(context, attrs);
        progressBar = new WebViewProgressBar(context);
        progressBar.setLayoutParams(new ViewGroup.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT));
        progressBar.setVisibility(GONE);
        addView(progressBar);
        handler = new Handler();
        mWebView = this;
        initSettings();
    }

    public OnErrorListener getOnErrorListener() {
        return onErrorListener;
    }

    public void setOnErrorListener(OnErrorListener onErrorListener) {
        this.onErrorListener = onErrorListener;
    }

    @SuppressLint("SetJavaScriptEnabled")
    private void initSettings() {
        WebSettings mSettings = this.getSettings();
        mSettings.setJavaScriptEnabled(true);
        mSettings.setDomStorageEnabled(true);
        mSettings.setDefaultTextEncodingName("utf-8");
        mSettings.setAllowFileAccess(true);
        mSettings.setUseWideViewPort(true);
        mSettings.setLoadWithOverviewMode(true);
        mSettings.setDefaultZoom(WebSettings.ZoomDensity.FAR);
        mSettings.setRenderPriority(WebSettings.RenderPriority.HIGH);
        mSettings.setBlockNetworkImage(true);
        setWebViewClient(new MyWebViewClient());
        setWebChromeClient(new MyWebChromeClient());
        setVerticalScrollBarEnabled(false);
        setHorizontalScrollBarEnabled(false);
        setOverScrollMode(View.OVER_SCROLL_NEVER);
    }

    public void setTitleView(TextView titleView) {
        this.titleView = titleView;
    }

    public class MyWebChromeClient extends WebChromeClient {
        @Override
        public void onProgressChanged(WebView view, int newProgress) {
            if (newProgress == 100) {
                progressBar.setProgress(100);
                handler.postDelayed(runnable, 200);
            } else if (progressBar.getVisibility() == GONE) {
                progressBar.setVisibility(VISIBLE);
            }
            if (newProgress < 10) {
                newProgress = 10;
            }
            progressBar.setProgress(newProgress);
            super.onProgressChanged(view, newProgress);
        }
    }

    private void updateUrl(String url) {
        if (urlView != null) {
            try {
                URI uri = new URI(url);
                String host = uri.getHost();
                String text = getResources().getString(R.string.web_pagefrom) + " " + host;
                urlView.setText(text);
            } catch (URISyntaxException e) {
                throw new RuntimeException(e);
            }
        }
    }

    public class MyWebViewClient extends WebViewClient {
        @Override
        public boolean shouldOverrideUrlLoading(WebView view, String url) {
            updateUrl(url);
            if (!(url.startsWith("https://") || url.startsWith("http://"))) {
                Intent intent = new Intent(Intent.ACTION_VIEW, Uri.parse(url));
                getContext().startActivity(intent);
                return true;
            }
            mWebView.loadUrl(url);
            return true;
        }

        @Override
        public void onLoadResource(WebView view, String url) {
            super.onLoadResource(view, url);
        }

        @Override
        public void onReceivedError(WebView view, WebResourceRequest request, WebResourceError error) {
            super.onReceivedError(view, request, error);
            if (onErrorListener != null)
                onErrorListener.onError(view, request, error);
        }

        @Override
        public void onReceivedError(WebView view, int errorCode, String description, String failingUrl) {
            super.onReceivedError(view, errorCode, description, failingUrl);
        }

        @Override
        public void onPageStarted(WebView view, String url, Bitmap favicon) {
            super.onPageStarted(view, url, favicon);
            mTimer = new Timer();
            mTimerTask = new TimerTask() {
                @Override
                public void run() {
                    // 在TIMEOUT时间后,则很可能超时.
                    // 此时若webView进度小于100,则判断其超时
                    // 随后利用Handle发送超时的消息
                    Log.d("xuruida", "======> mWebView.getProgress()=" + mWebView.getProgress());
                    if (mWebView.getProgress() < 100) {
                        Message msg = new Message();
                        msg.what = TIMEOUT_ERROR;
                        mHandler.sendMessage(msg);
                        if (mTimer != null) {
                            mTimer.cancel();
                            mTimer.purge();
                        }
                    }
                    if (mWebView.getProgress() == 100) {
                        Log.d("xuruida", "======> 未超时");
                        if (mTimer != null) {
                            mTimer.cancel();
                            mTimer.purge();
                        }
                    }
                }
            };
            mTimer.schedule(mTimerTask, TIMEOUT, 1);
        }

        @Override
        public void onPageFinished(WebView view, String url) {
            super.onPageFinished(view, url);
            if (titleView != null) titleView.setText(view.getTitle());
            updateUrl(url);
            view.getSettings().setBlockNetworkImage(false);
            if (mTimer != null) {
                mTimer.cancel();
                mTimer.purge();
            }
        }

        @Override
        public void onScaleChanged(WebView view, float oldScale, float newScale) {
            super.onScaleChanged(view, oldScale, newScale);
            ProgressWebView.this.requestFocus();
            ProgressWebView.this.requestFocusFromTouch();
        }
    }
}