/*
 * Project Name: Worthy
 * Author: Ruida
 * Last Modified: 2022/12/17 22:05:40
 * Copyright(c) 2022 Ruida https://cloudchewie.com
 */

package com.cloudchewie.ui.item;

import android.content.Context;
import android.content.res.ColorStateList;
import android.content.res.TypedArray;
import android.graphics.drawable.Drawable;
import android.util.AttributeSet;
import android.util.TypedValue;
import android.view.LayoutInflater;
import android.view.View;
import android.widget.ImageView;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.constraintlayout.widget.ConstraintLayout;
import androidx.constraintlayout.widget.Constraints;

import com.cloudchewie.ui.R;
import com.cloudchewie.ui.ThemeUtil;

public class HorizontalIconTextItem extends ConstraintLayout {
    private ConstraintLayout mainLayout;
    private ImageView icon;
    private ImageView rightIcon;
    private TextView textView;
    private boolean isChecked;
    private String text;
    private int iconId;
    private int textColor;
    private int iconColor;
    private int rightIconId;
    private int rightIconColor;
    private int checkedIconId;
    private int checkedIconColor;
    private IconTextItemMode mode;

    public HorizontalIconTextItem(@NonNull Context context) {
        super(context);
        init(context, null);
    }

    public HorizontalIconTextItem(@NonNull Context context, @Nullable AttributeSet attrs) {
        super(context, attrs);
        init(context, attrs);
    }

    public HorizontalIconTextItem(@NonNull Context context, @Nullable AttributeSet attrs, int defStyleAttr) {
        super(context, attrs, defStyleAttr);
        init(context, attrs);
    }

    public HorizontalIconTextItem(@NonNull Context context, @Nullable AttributeSet attrs, int defStyleAttr, int defStyleRes) {
        super(context, attrs, defStyleAttr, defStyleRes);
        init(context, attrs);
    }

    private void init(Context context, AttributeSet attrs) {
        LayoutInflater.from(context).inflate(R.layout.widget_icon_text_item, this, true);
        mainLayout = findViewById(R.id.horizontal_icon_text_item_layout);
        icon = findViewById(R.id.horizontal_icon_text_item_icon);
        rightIcon = findViewById(R.id.horizontal_icon_text_item_right_icon);
        textView = findViewById(R.id.horizontal_icon_text_item_text);
        TypedArray attr = context.obtainStyledAttributes(attrs, R.styleable.HorizontalIconTextItem);
        if (attr != null) {
            iconId = attr.getResourceId(R.styleable.HorizontalIconTextItem_horizontal_icon_text_item_icon, R.drawable.ic_material_add);
            iconColor = attr.getColor(R.styleable.HorizontalIconTextItem_horizontal_icon_text_item_icon_color, ThemeUtil.getPrimaryColor(context));
            rightIconId = attr.getResourceId(R.styleable.HorizontalIconTextItem_horizontal_icon_text_item_right_icon, R.drawable.ic_material_close);
            rightIconColor = attr.getColor(R.styleable.HorizontalIconTextItem_horizontal_icon_text_item_right_icon_color, ThemeUtil.getPrimaryColor(context));
            checkedIconId = attr.getResourceId(R.styleable.HorizontalIconTextItem_horizontal_icon_text_item_checked_icon, R.drawable.ic_material_add);
            checkedIconColor = attr.getColor(R.styleable.HorizontalIconTextItem_horizontal_icon_text_item_checked_icon_color,ThemeUtil.getPrimaryColor(context));
            int textMaxLength = attr.getInt(R.styleable.HorizontalIconTextItem_horizontal_icon_text_item_text_max_length, getResources().getInteger(R.integer.horizontal_icon_text_item_text_max_length));
            int iconSize = (int) attr.getDimension(R.styleable.HorizontalIconTextItem_horizontal_icon_text_item_icon_size, getResources().getDimension(R.dimen.horizontal_icon_text_item_default_icon_size));
            int rightIconSize = (int) attr.getDimension(R.styleable.HorizontalIconTextItem_horizontal_icon_text_item_right_icon_size, getResources().getDimension(R.dimen.horizontal_icon_text_item_default_icon_size));
            text = attr.getString(R.styleable.HorizontalIconTextItem_horizontal_icon_text_item_text);
            textColor = attr.getColor(R.styleable.HorizontalIconTextItem_horizontal_icon_text_item_text_color, ThemeUtil.getPrimaryColor(context));
            int textSize = (int) attr.getDimension(R.styleable.HorizontalIconTextItem_horizontal_icon_text_item_text_size, getResources().getDimension(R.dimen.horizontal_icon_text_item_default_text_size));
            int spacing = (int) attr.getDimension(R.styleable.HorizontalIconTextItem_horizontal_icon_text_item_spacing, getResources().getDimension(R.dimen.horizontal_icon_text_item_default_spacing));
            setIcon(iconId);
            setIconColor(iconColor);
            setIconSize(iconSize);
            setRightIconSize(rightIconSize);
            setRightIcon(rightIconId);
            setRightIconColor(rightIconColor);
            setText(text);
            setTextColor(textColor);
            setTextSize(textSize);
            setTextMaxLength(textMaxLength);
            attr.recycle();
        }
    }

    public void toggle() {
        isChecked = !isChecked;
        if (isChecked) {
            setIcon(checkedIconId);
            setIconColor(checkedIconColor);
        } else {
            setIcon(iconId);
            setIconColor(iconColor);
        }
    }

    public void setMode(IconTextItemMode mode) {
        this.mode = mode;
        switch (mode) {
            case DEFAULT:
                setIcon(iconId);
                textView.setText(text);
                setTextColor(textColor);
                setIconColor(iconColor);
                setRightIconVisibility(false);
                break;
            case CHECK:
                setIcon(checkedIconId);
                setIconColor(checkedIconColor);
                setTextColor(checkedIconColor);
                break;
            case DATA:
                setIcon(checkedIconId);
                setIconColor(checkedIconColor);
                setTextColor(checkedIconColor);
                setRightIconVisibility(true);
                break;
        }
    }

    public void setRightIcon(int iconId) {
        rightIcon.setImageResource(iconId);
    }

    public void setRightIconVisibility(boolean visibility) {
        if (visibility) rightIcon.setVisibility(VISIBLE);
        else rightIcon.setVisibility(GONE);
    }

    public void setRightIconColor(int color) {
        rightIcon.setImageTintList(ColorStateList.valueOf(color));
    }

    public void setRightIconClickListener(View.OnClickListener clickListener) {
        rightIcon.setOnClickListener(clickListener);
    }

    public boolean isChecked() {
        return isChecked;
    }

    public void setIcon(int iconId) {
        icon.setImageResource(iconId);
    }

    public void setIcon(Drawable drawable) {
        icon.setImageDrawable(drawable);
    }

    public void setIconVisible(boolean visible) {
        if (visible) icon.setVisibility(VISIBLE);
        else icon.setVisibility(GONE);
    }


    public void setIconColor(int color) {
        icon.setImageTintList(ColorStateList.valueOf(color));
    }

    public void setIconSize(int size) {
        ConstraintLayout.LayoutParams layoutParams = new Constraints.LayoutParams(size, size);
        layoutParams.topToTop = LayoutParams.PARENT_ID;
        layoutParams.bottomToBottom = LayoutParams.PARENT_ID;
        layoutParams.startToStart = LayoutParams.PARENT_ID;
        icon.setLayoutParams(layoutParams);
        rightIcon.setLayoutParams(layoutParams);
    }

    public void setRightIconSize(int size) {
        ConstraintLayout.LayoutParams layoutParams = new Constraints.LayoutParams(size, size);
        layoutParams.topToTop = LayoutParams.PARENT_ID;
        layoutParams.bottomToBottom = LayoutParams.PARENT_ID;
        layoutParams.startToEnd = R.id.horizontal_icon_text_item_text;
        rightIcon.setLayoutParams(layoutParams);
    }

    public void setTextMaxLength(int textMaxLength) {
        textView.setMaxEms(textMaxLength);
    }

    public String getText() {
        return (String) textView.getText();
    }

    public void setText(String text) {
        textView.setText(text);
    }

    public void setTextColor(int textColor) {
        textView.setTextColor(textColor);
    }

    public void setTextSize(int size) {
        textView.setTextSize(TypedValue.COMPLEX_UNIT_PX, size);
    }

    public void setTextSizeSp(int size) {
        textView.setTextSize(TypedValue.COMPLEX_UNIT_SP, size);
    }

    public void setSpacing(int spacing) {
        textView.setPadding(spacing, 0, 0, 0);
    }

    public enum IconTextItemMode {
        DEFAULT, CHECK, DATA
    }
}
