/*
 * Project Name: Worthy
 * Author: Ruida
 * Last Modified: 2022/12/17 21:42:08
 * Copyright(c) 2022 Ruida https://cloudchewie.com
 */

package com.cloudchewie.ui.custom;

import android.content.Context;
import android.content.res.TypedArray;
import android.graphics.Color;
import android.util.AttributeSet;
import android.view.LayoutInflater;
import android.view.View;
import android.widget.ImageButton;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.constraintlayout.widget.ConstraintLayout;

import com.cloudchewie.ui.R;

public class TitleBar extends ConstraintLayout implements View.OnClickListener {
    private ImageButton left_button;
    private ImageButton right_button;
    private TextView title_view;

    public TitleBar(@NonNull Context context) {
        super(context);
    }

    public TitleBar(@NonNull Context context, @Nullable AttributeSet attrs) {
        super(context, attrs);
        initView(context, attrs);
    }

    public TitleBar(@NonNull Context context, @Nullable AttributeSet attrs, int defStyleAttr) {
        super(context, attrs, defStyleAttr);
        initView(context, attrs);
    }

    public TitleBar(@NonNull Context context, @Nullable AttributeSet attrs, int defStyleAttr, int defStyleRes) {
        super(context, attrs, defStyleAttr, defStyleRes);
        initView(context, attrs);
    }

    private void initView(Context context, AttributeSet attrs) {
        LayoutInflater.from(context).inflate(R.layout.widget_titlebar, this, true);
        left_button = findViewById(R.id.titlebar_left_button);
        right_button = findViewById(R.id.titlebar_right_button);
        title_view = findViewById(R.id.titlebar_title);
        TypedArray attr = context.obtainStyledAttributes(attrs, R.styleable.TitleBar);
        if (attr != null) {
            int titleBarBackground = attr.getColor(R.styleable.TitleBar_titlebar_background, Color.TRANSPARENT);
            findViewById(R.id.titlebar_main_layout).setBackgroundColor(titleBarBackground);
            boolean leftButtonVisible = attr.getBoolean(R.styleable.TitleBar_left_button_visibility, true);
            int leftButtonIconId = attr.getResourceId(R.styleable.TitleBar_left_button_icon, R.drawable.ic_light_arrow_left);
            int leftButtonBackgroundColor = attr.getColor(R.styleable.TitleBar_left_button_background, Color.TRANSPARENT);
            setLeftButton(leftButtonVisible, leftButtonIconId, leftButtonBackgroundColor);
            boolean rightButtonVisible = attr.getBoolean(R.styleable.TitleBar_right_button_visibility, true);
            int rightButtonIconId = attr.getResourceId(R.styleable.TitleBar_right_button_icon, R.drawable.ic_light_ellipsis);
            int rightButtonBackgroundColor = attr.getColor(R.styleable.TitleBar_right_button_background, Color.TRANSPARENT);
            setRightButton(rightButtonVisible, rightButtonIconId, rightButtonBackgroundColor);
            String title = attr.getString(R.styleable.TitleBar_title);
            int titleColor = attr.getColor(R.styleable.TitleBar_title_color, getResources().getColor(R.color.color_accent, getResources().newTheme()));
            setTitle(title, titleColor);
            attr.recycle();
        }
    }

    public ImageButton getRightButton() {
        return right_button;
    }

    public ImageButton getLeftButton() {
        return left_button;
    }

    public void setLeftButtonClickListener(LeftButtonClickListener listener) {
        left_button.setOnClickListener(listener);
    }

    public void setRightButtonClickListener(LeftButtonClickListener listener) {
        right_button.setOnClickListener(listener);
    }

    private void setLeftButton(boolean visibility, int iconId, int backgroundColor) {
        if (visibility)
            left_button.setVisibility(View.VISIBLE);
        else
            left_button.setVisibility(View.INVISIBLE);
        left_button.setImageResource(iconId);
        left_button.setBackgroundColor(backgroundColor);
    }

    private void setRightButton(boolean visibility, int iconId, int backgroundColor) {
        if (visibility)
            right_button.setVisibility(View.VISIBLE);
        else
            right_button.setVisibility(View.INVISIBLE);
        right_button.setImageResource(iconId);
        right_button.setBackgroundColor(backgroundColor);
    }

    private void setTitle(String title, int titleColor) {
        title_view.setText(title);
        title_view.setTextColor(titleColor);
    }

    public void setTitle(String title) {
        title_view.setText(title);
    }

    @Override
    public void onClick(View view) {

    }

    public interface LeftButtonClickListener extends OnClickListener {
        @Override
        void onClick(View view);
    }

    public interface RightButtonClickListener extends OnClickListener {
        @Override
        void onClick(View view);
    }
}
