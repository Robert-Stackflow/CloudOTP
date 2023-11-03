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
import android.view.View;
import android.view.Window;
import android.view.WindowManager;
import android.widget.ImageView;
import android.widget.TextView;

import androidx.appcompat.widget.AppCompatButton;
import androidx.constraintlayout.widget.ConstraintLayout;

import com.cloudchewie.ui.R;
import com.cloudchewie.util.ui.MatricsUtil;
import com.cloudchewie.util.ui.SizeUtil;

public class ImageDialog extends Dialog {
    public OnConfirmListener onConfirmListener;
    private TextView titleTv;
    private TextView tipTv;
    private ImageView imageView;
    private AppCompatButton confirmButton;
    private String tip;
    private String title = "消息提示";
    private String buttonText;
    private ConstraintLayout mainLayout;

    public ImageDialog(Context context) {
        super(context, R.style.MyDialog);
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.widget_image_dialog);
        setModal(false);
        initView();
        refreshView();
        initEvent();
    }

    private void initEvent() {
        confirmButton.setOnClickListener(v -> {
            if (onConfirmListener != null) {
                onConfirmListener.onConfirmClick();
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
        if (!TextUtils.isEmpty(tip)) {
            tipTv.setText(tip);
        }
        if (!TextUtils.isEmpty(buttonText)) {
            confirmButton.setText(buttonText);
        } else {
            confirmButton.setText(getContext().getString(R.string.confirm));
        }
    }

    @Override
    public void show() {
        super.show();
        refreshView();
    }

    private void initView() {
        confirmButton = findViewById(R.id.widget_image_dialog_confirm);
        titleTv = findViewById(R.id.widget_image_dialog_title);
        tipTv = findViewById(R.id.widget_image_dialog_tip);
        imageView = findViewById(R.id.widget_image_dialog_image);
        mainLayout = findViewById(R.id.widget_image_dialog_main_layout);
        confirmButton.setText(buttonText);
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

    public ImageDialog setOnClickBottomListener(OnConfirmListener onConfirmListener) {
        this.onConfirmListener = onConfirmListener;
        return this;
    }

    public String getTip() {
        return tip;
    }

    public ImageDialog setTip(String tip) {
        this.tip = tip;
        return this;
    }

    public String getTitle() {
        return title;
    }

    public ImageView getImageView() {
        return imageView;
    }

    public ImageDialog setTitle(String title) {
        this.title = title;
        return this;
    }

    public String getButtonText() {
        return buttonText;
    }

    public ImageDialog setButtonText(String buttonText) {
        this.buttonText = buttonText;
        return this;
    }

    public TextView getTipTv() {
        return tipTv;
    }

    public interface OnConfirmListener {
        void onConfirmClick();
    }

}