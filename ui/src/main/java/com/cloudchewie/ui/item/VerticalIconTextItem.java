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
import android.view.Gravity;
import android.view.LayoutInflater;
import android.widget.ImageView;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.appcompat.content.res.AppCompatResources;
import androidx.constraintlayout.widget.ConstraintLayout;

import com.cloudchewie.ui.R;
import com.cloudchewie.ui.ThemeUtil;

public class VerticalIconTextItem extends ConstraintLayout {
    private ConstraintLayout mainLayout;
    private ImageView iconView;
    private TextView textView;
    private boolean isChecked;
    private int iconId;
    private int iconColor;
    private int checkedIconId;
    private int checkedIconColor;

    public VerticalIconTextItem(@NonNull Context context) {
        super(context);
        init(context, null);
    }

    public VerticalIconTextItem(@NonNull Context context, @Nullable AttributeSet attrs) {
        super(context, attrs);
        init(context, attrs);
    }

    public VerticalIconTextItem(@NonNull Context context, @Nullable AttributeSet attrs, int defStyleAttr) {
        super(context, attrs, defStyleAttr);
        init(context, attrs);
    }

    public VerticalIconTextItem(@NonNull Context context, @Nullable AttributeSet attrs, int defStyleAttr, int defStyleRes) {
        super(context, attrs, defStyleAttr, defStyleRes);
        init(context, attrs);
    }

    private void init(Context context, AttributeSet attrs) {
        LayoutInflater.from(context).inflate(R.layout.widget_vertical_icon_text_item, this, true);
        mainLayout = findViewById(R.id.vertical_icon_text_item_layout);
        iconView = findViewById(R.id.vertical_icon_text_item_icon);
        textView = findViewById(R.id.vertical_icon_text_item_text);
        TypedArray attr = context.obtainStyledAttributes(attrs, R.styleable.VerticalIconTextItem);
        iconView.setOnClickListener(v -> this.performClick());
        if (attr != null) {
            iconId = attr.getResourceId(R.styleable.VerticalIconTextItem_vertical_icon_text_item_icon, R.drawable.ic_light_map);
            iconColor = attr.getColor(R.styleable.VerticalIconTextItem_vertical_icon_text_item_icon_color, getResources().getColor(R.color.color_icon, getResources().newTheme()));
            checkedIconId = attr.getResourceId(R.styleable.VerticalIconTextItem_vertical_icon_text_item_checked_icon, R.drawable.ic_light_map_fill);
            checkedIconColor = attr.getColor(R.styleable.VerticalIconTextItem_vertical_icon_text_item_checked_icon_color, ThemeUtil.getPrimaryColor(context));
            int iconSize = (int) attr.getDimension(R.styleable.VerticalIconTextItem_vertical_icon_text_item_icon_size, getResources().getDimension(R.dimen.vertical_icon_text_item_default_icon_size));
            String text = attr.getString(R.styleable.VerticalIconTextItem_vertical_icon_text_item_text);
            int textColor = attr.getColor(R.styleable.VerticalIconTextItem_vertical_icon_text_item_text_color, getResources().getColor(R.color.color_gray, getResources().newTheme()));
            int textSize = (int) attr.getDimension(R.styleable.VerticalIconTextItem_vertical_icon_text_item_text_size, getResources().getDimension(R.dimen.vertical_icon_text_item_default_text_size));
            int spacing = (int) attr.getDimension(R.styleable.VerticalIconTextItem_vertical_icon_text_item_spacing, 3);
            int iconBackgroundId = attr.getResourceId(R.styleable.VerticalIconTextItem_vertical_icon_text_item_icon_background, R.drawable.shape_round_dp10);
            int backgroundTintId = attr.getResourceId(R.styleable.VerticalIconTextItem_vertical_icon_text_item_icon_background_tint, R.color.color_selector_content);
            boolean backgroundEnable = attr.getBoolean(R.styleable.VerticalIconTextItem_vertical_icon_text_item_icon_background_enable, false);
            int iconScaleType = attr.getInt(R.styleable.VerticalIconTextItem_vertical_icon_text_item_icon_scale_type, 0);
            int backgroundId = attr.getResourceId(R.styleable.VerticalIconTextItem_vertical_icon_text_item_background, R.drawable.shape_round_dp5);
            int padding_v = (int) attr.getDimension(R.styleable.VerticalIconTextItem_vertical_icon_text_item_padding_v, getResources().getDimension(R.dimen.dp20));
            int padding_h = (int) attr.getDimension(R.styleable.VerticalIconTextItem_vertical_icon_text_item_padding_h, getResources().getDimension(R.dimen.dp30));
            textView.setMinLines(attr.getInt(R.styleable.VerticalIconTextItem_vertical_icon_text_item_min_lines, 1));
            textView.setGravity(Gravity.TOP | Gravity.CENTER_HORIZONTAL);
            setPadding(padding_v, padding_h);
            setBackground(backgroundId);
            setScaleType(iconScaleType);
            setIcon(iconId);
            setIconColor(iconColor);
            setIconSize(iconSize);
            setText(text);
            setTextColor(textColor);
            setTextSize(textSize);
            setSpacing(spacing);
            if (backgroundEnable) {
                setIconBackground(iconBackgroundId);
                setIconBackgroundTint(backgroundTintId);
            }
            attr.recycle();
        }
    }

    public void setMinLines(int minLines) {
        textView.setMinLines(minLines);
        textView.setGravity(Gravity.TOP | Gravity.CENTER_HORIZONTAL);
    }

    public void setMinLinesWithCenter(int minLines) {
        textView.setMinLines(minLines);
        textView.setGravity(Gravity.CENTER);
    }

    public void toggle() {
        setChecked(!isChecked);
    }

    public void setScaleType(int type) {
        switch (type) {
            case 0:
                iconView.setScaleType(ImageView.ScaleType.CENTER_INSIDE);
                break;
            case 1:
                iconView.setPadding(10, 10, 10, 10);
                iconView.setScaleType(ImageView.ScaleType.CENTER_CROP);
                break;
            case 2:
                iconView.setPadding(10, 10, 10, 10);
                iconView.setScaleType(ImageView.ScaleType.FIT_CENTER);
                break;
        }
    }

    public boolean isChecked() {
        return isChecked;
    }

    public void setChecked(boolean checked) {
        if (checked) {
            setIcon(checkedIconId);
            setIconColor(checkedIconColor);
        } else {
            setIcon(iconId);
            setIconColor(iconColor);
        }
    }

    public void setIcon(int iconId) {
        iconView.setImageResource(iconId);
    }

    public void setIcon(Drawable drawable) {
        iconView.setImageDrawable(drawable);
    }

    public void setIconColor(int color) {
        iconView.setImageTintList(ColorStateList.valueOf(color));
    }

    public void setIconSize(int size) {
        ConstraintLayout.LayoutParams layoutParams = new ConstraintLayout.LayoutParams(iconView.getLayoutParams());
        layoutParams.width = size;
        layoutParams.height = size;
        layoutParams.endToEnd = R.id.vertical_icon_text_item_text;
        layoutParams.startToStart = R.id.vertical_icon_text_item_text;
        iconView.setLayoutParams(layoutParams);
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

    public void setSpacing(int spacing) {
        textView.setPadding(0, spacing, 0, 0);
    }

    public void setBackground(int backgroundId) {
        mainLayout.setBackground(AppCompatResources.getDrawable(getContext(), backgroundId));
    }

    public void setPadding(int padding_v, int padding_h) {
        mainLayout.setPadding(padding_h, padding_v, padding_h, padding_v);
    }

    public void setIconBackground(int backgroundId) {
        iconView.setBackground(AppCompatResources.getDrawable(getContext(), backgroundId));
    }

    public void setIconBackgroundTint(int backgroundTintId) {
        iconView.setBackgroundTintList(getContext().getColorStateList(backgroundTintId));
    }

    public enum VerticalIconTextItemMode {
        ICON, TEXT
    }
}
