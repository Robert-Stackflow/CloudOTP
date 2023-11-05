/*
 * Project Name: Worthy
 * Author: Ruida
 * Last Modified: 2022/12/17 21:42:08
 * Copyright(c) 2022 Ruida https://cloudchewie.com
 */

package com.cloudchewie.ui.item;

import android.annotation.SuppressLint;
import android.content.Context;
import android.content.res.TypedArray;
import android.graphics.Color;
import android.util.AttributeSet;
import android.view.LayoutInflater;
import android.view.View;
import android.widget.ImageView;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.appcompat.content.res.AppCompatResources;
import androidx.constraintlayout.widget.ConstraintLayout;
import androidx.constraintlayout.widget.ConstraintSet;

import com.cloudchewie.ui.R;

public class EntryItem extends ConstraintLayout {
    private ImageView leftIcon;
    private ImageView rightIcon;
    private TextView titleView;
    private TextView tipView;
    private View divider;
    private ConstraintLayout mainLayout;
    private ImageView imageView;

    public EntryItem(@NonNull Context context) {
        super(context);
        initView(context, null);
    }

    public EntryItem(@NonNull Context context, @Nullable AttributeSet attrs) {
        super(context, attrs);
        initView(context, attrs);
    }

    public EntryItem(@NonNull Context context, @Nullable AttributeSet attrs, int defStyleAttr) {
        super(context, attrs, defStyleAttr);
        initView(context, attrs);
    }

    public EntryItem(@NonNull Context context, @Nullable AttributeSet attrs, int defStyleAttr, int defStyleRes) {
        super(context, attrs, defStyleAttr, defStyleRes);
        initView(context, attrs);
    }

    private void initView(Context context, AttributeSet attrs) {
        LayoutInflater.from(context).inflate(R.layout.widget_entry_item, this, true);
        mainLayout = findViewById(R.id.entry_item_layout);
        leftIcon = findViewById(R.id.entry_item_left_icon);
        rightIcon = findViewById(R.id.entry_item_right_icon);
        titleView = findViewById(R.id.entry_item_title);
        tipView = findViewById(R.id.entry_item_tip);
        divider = findViewById(R.id.entry_item_divider);
        imageView = findViewById(R.id.entry_item_image);
        TypedArray attr = context.obtainStyledAttributes(attrs, R.styleable.EntryItem);
        if (attr != null) {
            int titleBarBackground = attr.getResourceId(R.styleable.EntryItem_entry_item_background, Color.TRANSPARENT);
            setBackgroundResource(titleBarBackground);
            boolean leftButtonVisible = attr.getBoolean(R.styleable.EntryItem_entry_item_left_icon_visibility, true);
            int leftButtonIconId = attr.getResourceId(R.styleable.EntryItem_entry_item_left_icon, R.drawable.ic_light_settings);
            int leftButtonBackgroundColor = attr.getColor(R.styleable.EntryItem_entry_item_left_icon_background, Color.TRANSPARENT);
            setLeftButton(leftButtonVisible, leftButtonIconId, leftButtonBackgroundColor);
            boolean rightButtonVisible = attr.getBoolean(R.styleable.EntryItem_entry_item_right_icon_visibility, true);
            int rightButtonIconId = attr.getResourceId(R.styleable.EntryItem_entry_item_right_icon, R.drawable.ic_light_arrow_right);
            int rightButtonBackgroundColor = attr.getColor(R.styleable.EntryItem_entry_item_right_icon_background, Color.TRANSPARENT);
            setRightButton(rightButtonVisible, rightButtonIconId, rightButtonBackgroundColor);
            String title = attr.getString(R.styleable.EntryItem_entry_item_title);
            int titleColor = attr.getColor(R.styleable.EntryItem_entry_item_title_color, getResources().getColor(R.color.color_accent, getResources().newTheme()));
            setTitle(title, titleColor);
            String tip = attr.getString(R.styleable.EntryItem_entry_item_tip);
            int tipColor = attr.getColor(R.styleable.EntryItem_entry_item_tip_color, getResources().getColor(R.color.color_gray, getResources().newTheme()));
            setTip(tip, tipColor);
            boolean topRadiusEnable = attr.getBoolean(R.styleable.EntryItem_entry_item_top_radius_enable, false);
            boolean bottomRadiusEnable = attr.getBoolean(R.styleable.EntryItem_entry_item_bottom_radius_enable, false);
            setRadiusEnbale(topRadiusEnable, bottomRadiusEnable);
            boolean isSimpleMode = attr.getBoolean(R.styleable.EntryItem_entry_item_simple_mode, false);
            setSimpleMode(isSimpleMode);
            attr.recycle();
        }
    }

    void setSimpleMode(boolean simpleMode) {
        if (simpleMode) {
            leftIcon.setVisibility(GONE);
            rightIcon.setVisibility(GONE);
            tipView.setVisibility(GONE);
            ConstraintSet set = new ConstraintSet();
            set.clone(mainLayout);
            set.constrainWidth(titleView.getId(), LayoutParams.MATCH_PARENT);
            set.centerHorizontally(titleView.getId(), ConstraintSet.PARENT_ID);
            set.applyTo(mainLayout);
            titleView.setTextSize(17);
        }
    }

    private void setLeftButton(boolean visibility, int iconId, int backgroundColor) {
        if (visibility)
            leftIcon.setVisibility(View.VISIBLE);
        else {
            leftIcon.setVisibility(View.GONE);
            setTitlePadding(0, 0, 0, 0);
        }
        leftIcon.setImageResource(iconId);
        leftIcon.setBackgroundColor(backgroundColor);
    }

    @SuppressLint("UseCompatLoadingForDrawables")
    public void setRadiusEnbale(boolean top, boolean bottom) {
        if (!top && !bottom) {
            divider.setVisibility(VISIBLE);
            mainLayout.setBackground(AppCompatResources.getDrawable(getContext(), R.drawable.shape_rect));
        } else if (top && bottom) {
            divider.setVisibility(GONE);
            mainLayout.setBackground(AppCompatResources.getDrawable(getContext(), R.drawable.shape_round_dp10));
        } else if (!top && bottom) {
            divider.setVisibility(GONE);
            mainLayout.setBackground(AppCompatResources.getDrawable(getContext(), R.drawable.shape_round_bottom_dp10));
        } else if (top && !bottom) {
            divider.setVisibility(VISIBLE);
            mainLayout.setBackground(AppCompatResources.getDrawable(getContext(), R.drawable.shape_round_top_dp10));
        }
    }

    private void setRightButton(boolean visibility, int iconId, int backgroundColor) {
        if (visibility)
            rightIcon.setVisibility(View.VISIBLE);
        else
            rightIcon.setVisibility(View.GONE);
        rightIcon.setImageResource(iconId);
        rightIcon.setBackgroundColor(backgroundColor);
    }

    public void setTitle(String title, int titleColor) {
        titleView.setText(title);
        titleView.setTextColor(titleColor);
    }

    public void setTitle(String title) {
        titleView.setText(title);
    }

    public String getTitle() {
        return titleView.getText().toString();
    }

    public void showImage() {
        tipView.setVisibility(GONE);
        imageView.setVisibility(VISIBLE);
    }

    public void showTip() {
        tipView.setVisibility(VISIBLE);
        imageView.setVisibility(GONE);
    }

    public ImageView getImageView() {
        return imageView;
    }

    public void setTip(String tip, int tipColor) {
        tipView.setVisibility(VISIBLE);
        imageView.setVisibility(GONE);
        tipView.setText(tip);
        tipView.setTextColor(tipColor);
    }

    public void setTitlePadding(int left, int top, int right, int bottom) {
        titleView.setPadding(left, top, right, bottom);
    }

    public String getTip() {
        return tipView.getText().toString();
    }

    public void setTipText(String tip) {
        tipView.setText(tip);
    }
}
