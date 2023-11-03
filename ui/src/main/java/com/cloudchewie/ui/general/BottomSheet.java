/*
 * Project Name: Worthy
 * Author: Ruida
 * Last Modified: 2022/12/17 21:42:08
 * Copyright(c) 2022 Ruida https://cloudchewie.com
 */

package com.cloudchewie.ui.general;

import static com.google.android.material.bottomsheet.BottomSheetBehavior.STATE_EXPANDED;

import android.annotation.SuppressLint;
import android.content.Context;
import android.content.res.ColorStateList;
import android.view.Gravity;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.view.Window;
import android.view.WindowManager;
import android.widget.FrameLayout;
import android.widget.ImageButton;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.constraintlayout.widget.ConstraintLayout;

import com.cloudchewie.ui.R;
import com.google.android.material.bottomsheet.BottomSheetBehavior;
import com.google.android.material.bottomsheet.BottomSheetDialog;

public class BottomSheet extends BottomSheetDialog {
    protected ConstraintLayout mainLayout;
    protected View mainView;
    protected ImageButton leftButton;
    protected ImageButton rightButton;
    private BottomSheetBehavior bottomSheetBehavior;
    private TextView titleView;
    private ConstraintLayout titleBarLayout;
    private View dragBar;
    private Context context;

    public BottomSheet(@NonNull Context context) {
        super(context, R.style.BottomSheetDialog);
        initView(context);
    }

    public BottomSheet(@NonNull Context context, int theme) {
        super(context, theme);
        initView(context);
    }

    protected BottomSheet(@NonNull Context context, boolean cancelable, OnCancelListener cancelListener) {
        super(context, cancelable, cancelListener);
        initView(context);
    }

    public int getHeight() {
        Window window = getWindow();
        FrameLayout frameLayout = findViewById(R.id.design_bottom_sheet);
        BottomSheetBehavior behavior = BottomSheetBehavior.from(frameLayout);
        ViewGroup.LayoutParams layoutParams = frameLayout.getLayoutParams();
        if (layoutParams != null)
            return layoutParams.height;
        else
            return 0;
    }

    public void setHeight(int dpHeight) {
        Window window = getWindow();
        FrameLayout frameLayout = findViewById(R.id.design_bottom_sheet);
        BottomSheetBehavior behavior = BottomSheetBehavior.from(frameLayout);
        ViewGroup.LayoutParams layoutParams = frameLayout.getLayoutParams();
        if (layoutParams != null)
            layoutParams.height = dpHeight;
        frameLayout.setLayoutParams(layoutParams);
        behavior.setState(BottomSheetBehavior.STATE_EXPANDED);
    }

    public void setPeekHeight(int height) {
        BottomSheetBehavior behavior = BottomSheetBehavior.from(findViewById(R.id.design_bottom_sheet));
        behavior.setPeekHeight(height);
        behavior.setState(STATE_EXPANDED);
    }

    void initView(Context context) {
        this.context = context;
        @SuppressLint("InflateParams")
        View view = LayoutInflater.from(getContext()).inflate(R.layout.widget_bottom_sheet, null);
        setContentView(view);
        mainLayout = view.findViewById(R.id.bottom_sheet_layout);
        titleView = view.findViewById(R.id.bottom_sheet_titlebar_title);
        leftButton = view.findViewById(R.id.bottom_sheet_titlebar_left_button);
        rightButton = view.findViewById(R.id.bottom_sheet_titlebar_right_button);
        titleBarLayout = view.findViewById(R.id.bottom_sheet_titlebar_layout);
        dragBar = view.findViewById(R.id.bottom_sheet_dragbar);
        leftButton.setOnClickListener(v -> dismiss());
        setTitleBarVisible(false);
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

    public void setBackgroundColor(int color) {
        mainLayout.setBackgroundTintList(ColorStateList.valueOf(color));
    }

    public void setMainLayout(int mainLayoutId) {
        ConstraintLayout main_layout = findViewById(R.id.bottom_sheet_content);
        main_layout.removeAllViews();
        getBehavior().setState(STATE_EXPANDED);
        LayoutInflater inflater = LayoutInflater.from(context);
        ConstraintLayout.LayoutParams layoutParams = new ConstraintLayout.LayoutParams(ConstraintLayout.LayoutParams.MATCH_PARENT, ConstraintLayout.LayoutParams.WRAP_CONTENT);
        layoutParams.topToTop = ConstraintLayout.LayoutParams.PARENT_ID;
        layoutParams.bottomToBottom = ConstraintLayout.LayoutParams.PARENT_ID;
        main_layout.addView((mainView = inflater.inflate(mainLayoutId, null)), layoutParams);
    }

    public void setTitleBarVisible(boolean visible) {
        if (visible)
            titleBarLayout.setVisibility(View.VISIBLE);
        else
            titleBarLayout.setVisibility(View.GONE);
        setDragBarVisible(visible);
    }

    public void setBackGround(int resId) {
        if (mainLayout != null) mainLayout.setBackgroundResource(resId);
    }

    public void setTitleBarBackGroundTint(int resId) {
        if (titleBarLayout != null) {
            int color = getContext().getColor(resId);
            titleBarLayout.setBackgroundTintList(ColorStateList.valueOf(color));
        }
    }

    public void setBackGroundTint(int resId) {
        if (mainLayout != null) {
            int color = getContext().getColor(resId);
            mainLayout.setBackgroundTintList(ColorStateList.valueOf(color));
        }
    }

    public void setDragBarVisible(boolean visible) {
        if (visible)
            dragBar.setVisibility(View.VISIBLE);
        else
            dragBar.setVisibility(View.INVISIBLE);
    }

    public void setLeftButtonVisible(boolean visible) {
        if (visible)
            leftButton.setVisibility(View.VISIBLE);
        else
            leftButton.setVisibility(View.INVISIBLE);
    }

    public void setRightButtonVisible(boolean visible) {
        if (visible)
            rightButton.setVisibility(View.VISIBLE);
        else
            rightButton.setVisibility(View.INVISIBLE);
    }

    public void setTitle(String str) {
        setTitleBarVisible(true);
        titleView.setText(str);
    }

    public void setTitleColor(int color) {
        titleView.setTextColor(color);
    }
}
