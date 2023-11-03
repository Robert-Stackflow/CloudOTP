/*
 * Project Name: Worthy
 * Author: Ruida
 * Last Modified: 2022/12/17 22:05:40
 * Copyright(c) 2022 Ruida https://cloudchewie.com
 */

package com.cloudchewie.ui.custom;

import android.app.Dialog;
import android.content.Context;
import android.os.Bundle;
import android.text.TextUtils;
import android.view.Gravity;
import android.view.LayoutInflater;
import android.view.View;
import android.view.Window;
import android.view.WindowManager;
import android.widget.TextView;

import androidx.appcompat.widget.AppCompatButton;
import androidx.constraintlayout.widget.ConstraintLayout;

import com.cloudchewie.ui.R;
import com.cloudchewie.util.ui.MatricsUtil;
import com.cloudchewie.util.ui.SizeUtil;

public class IDialog extends Dialog {
    public OnClickBottomListener onClickBottomListener;
    protected View diyView;
    private TextView titleTv;
    private TextView messageTv;
    private AppCompatButton negtiveBn, positiveBn;
    private String message;
    private String title = "消息提示";
    private String positive, negtive;
    private int imageResId = -1;
    private ConstraintLayout mainLayout;
    private boolean isSingle = false;

    public IDialog(Context context) {
        super(context, R.style.MyDialog);
    }

    public void setMainLayout(int mainLayoutId) {
        findViewById(R.id.widget_dialog_main_layout).setVisibility(View.GONE);
        ConstraintLayout diyLayout = findViewById(R.id.widget_dialog_diy_layout);
        diyLayout.removeAllViews();
        LayoutInflater inflater = LayoutInflater.from(getContext());
        ConstraintLayout.LayoutParams layoutParams = new ConstraintLayout.LayoutParams(ConstraintLayout.LayoutParams.MATCH_PARENT, ConstraintLayout.LayoutParams.WRAP_CONTENT);
        layoutParams.topToTop = ConstraintLayout.LayoutParams.PARENT_ID;
        layoutParams.bottomToBottom = ConstraintLayout.LayoutParams.PARENT_ID;
        diyLayout.addView((diyView = inflater.inflate(mainLayoutId, null)), layoutParams);
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.widget_dialog);
        setModal(false);
        initView();
        refreshView();
        initEvent();
    }

    private void initEvent() {
        positiveBn.setOnClickListener(v -> {
            if (onClickBottomListener != null) {
                onClickBottomListener.onPositiveClick();
            }
            dismiss();
        });
        negtiveBn.setOnClickListener(v -> {
            if (onClickBottomListener != null) {
                onClickBottomListener.onNegtiveClick();
            }
            dismiss();
        });
    }

    public void setModal(boolean isModal) {
        setCanceledOnTouchOutside(!isModal);
        setCancelable(!isModal);
    }

    private void refreshView() {
        if (!TextUtils.isEmpty(title)) {
            titleTv.setText(title);
            titleTv.setVisibility(View.VISIBLE);
        } else {
            titleTv.setVisibility(View.GONE);
        }
        if (!TextUtils.isEmpty(message)) {
            messageTv.setText(message);
        }
        if (!TextUtils.isEmpty(positive)) {
            positiveBn.setText(positive);
        } else {
            positiveBn.setText(getContext().getString(R.string.confirm));
        }
        if (!TextUtils.isEmpty(negtive)) {
            negtiveBn.setText(negtive);
        } else {
            negtiveBn.setText(getContext().getString(R.string.cancel));
        }
        if (isSingle) {
            negtiveBn.setVisibility(View.GONE);
        } else {
            negtiveBn.setVisibility(View.VISIBLE);
        }
    }

    @Override
    public void show() {
        super.show();
        refreshView();
    }

    private void initView() {
        negtiveBn = findViewById(R.id.widget_dialog_negtive);
        positiveBn = findViewById(R.id.widget_dialog_positive);
        titleTv = findViewById(R.id.widget_dialog_title);
        messageTv = findViewById(R.id.widget_dialog_message);
        mainLayout = findViewById(R.id.widget_dialog_main_layout);
        mainLayout.setMinWidth(SizeUtil.dp2px(getContext(), MatricsUtil.getScreenWidth(getContext()) - 10));
        Window window = getWindow();
        if (window != null) {
            WindowManager.LayoutParams lp = window.getAttributes();
            lp.height = WindowManager.LayoutParams.WRAP_CONTENT;
            lp.width = WindowManager.LayoutParams.MATCH_PARENT;
            lp.gravity = Gravity.BOTTOM;
            window.setAttributes(lp);
            window.setDimAmount(0.4f);
        }
    }

    public IDialog setOnClickBottomListener(OnClickBottomListener onClickBottomListener) {
        this.onClickBottomListener = onClickBottomListener;
        return this;
    }

    public String getMessage() {
        return message;
    }

    public IDialog setMessage(String message) {
        this.message = message;
        return this;
    }

    public String getTitle() {
        return title;
    }

    public IDialog setTitle(String title) {
        this.title = title;
        return this;
    }

    public String getPositive() {
        return positive;
    }

    public IDialog setPositive(String positive) {
        this.positive = positive;
        return this;
    }

    public String getNegtive() {
        return negtive;
    }

    public IDialog setNegtive(String negtive) {
        this.negtive = negtive;
        return this;
    }

    public boolean isSingle() {
        return isSingle;
    }

    public IDialog setSingle(boolean single) {
        isSingle = single;
        return this;
    }

    public IDialog setImageResId(int imageResId) {
        this.imageResId = imageResId;
        return this;
    }

    public enum MyDialogMode {
        QUESTION, PROMPT, DIY
    }

    public interface OnClickBottomListener {
        void onPositiveClick();

        void onNegtiveClick();

        void onCloseClick();
    }

}