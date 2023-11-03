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
import android.widget.LinearLayout;
import android.widget.RadioButton;
import android.widget.RadioGroup;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.appcompat.content.res.AppCompatResources;
import androidx.constraintlayout.widget.ConstraintLayout;

import com.cloudchewie.ui.R;

public class RadioItem extends ConstraintLayout {
    private RadioGroup radioGroup;
    private TextView title_view;
    private ConstraintLayout mainLayout;
    private View divider;
    private Integer initIndex;
    private Integer selectedIndex;
    private Boolean isTouched = false;
    private CharSequence[] array;
    private OnIndexChangedListener onIndexChangedListener;

    public void setOnIndexChangedListener(OnIndexChangedListener onIndexChangedListener) {
        this.onIndexChangedListener = onIndexChangedListener;
    }

    public interface OnIndexChangedListener {
        void onIndexChanged(RadioButton radioButton, int index);
    }

    @SuppressLint("ClickableViewAccessibility")
    private void initView(Context context, AttributeSet attrs) {
        LayoutInflater.from(context).inflate(R.layout.widget_radio_item, this, true);
        radioGroup = findViewById(R.id.radio_item_group);
        title_view = findViewById(R.id.radio_item_title);
        mainLayout = findViewById(R.id.radio_item_layout);
        divider = findViewById(R.id.radio_item_divider);
        @SuppressLint("CustomViewStyleable") TypedArray attr = context.obtainStyledAttributes(attrs, R.styleable.RadioItem);
        if (attr != null) {
            int titleBarBackground = attr.getResourceId(R.styleable.RadioItem_radio_item_background, Color.TRANSPARENT);
            setBackgroundResource(titleBarBackground);
            String title = attr.getString(R.styleable.RadioItem_radio_item_title);
            initIndex = attr.getInteger(R.styleable.RadioItem_radio_item_init_index, 0);
            int titleColor = attr.getColor(R.styleable.RadioItem_radio_item_title_color, getResources().getColor(R.color.color_accent, getResources().newTheme()));
            array = attr.getTextArray(R.styleable.RadioItem_radio_item_array);
            setRadios(array);
            setTitle(title, titleColor);
            boolean topRadiusEnable = attr.getBoolean(R.styleable.RadioItem_radio_item_top_radius_enable, false);
            boolean bottomRadiusEnable = attr.getBoolean(R.styleable.RadioItem_radio_item_bottom_radius_enable, false);
            setRadiusEnbale(topRadiusEnable, bottomRadiusEnable);
            attr.recycle();
        }
        radioGroup.setTag(title_view.getText().toString());
    }

    public RadioGroup getRadioGroup() {
        return radioGroup;
    }

    public void setRadios(CharSequence[] stringList) {
        radioGroup.removeAllViews();
        for (int i = 0; i < stringList.length; i++) {
            CharSequence str = stringList[i];
            radioGroup.addView(generateButton(str, i));
        }
        setSelectedIndex(initIndex);
    }

    public RadioButton generateButton(CharSequence str, Integer index) {
        RadioButton radioButton = new RadioButton(getContext());
        radioButton.setText(str);
        radioButton.setButtonDrawable(null);
        radioButton.setWidth(getResources().getDimensionPixelSize(R.dimen.dp70));
        radioButton.setTextAlignment(TEXT_ALIGNMENT_CENTER);
        radioButton.setTextColor(getContext().getColorStateList(R.color.color_selector_radio_text));
        radioButton.setBackground(AppCompatResources.getDrawable(getContext(), R.drawable.shape_radio));
        radioButton.setBackgroundTintList(getContext().getColorStateList(R.color.color_selector_radio));
        radioButton.post(() -> {
            LinearLayout.LayoutParams layoutParams = new LinearLayout.LayoutParams(radioButton.getLayoutParams());
            layoutParams.rightMargin = getResources().getDimensionPixelSize(R.dimen.dp10);
            layoutParams.topMargin = getResources().getDimensionPixelSize(R.dimen.dp3);
            layoutParams.bottomMargin = getResources().getDimensionPixelSize(R.dimen.dp3);
            radioButton.setLayoutParams(layoutParams);
        });
        radioButton.setOnClickListener(view -> {
            selectedIndex = index;
            if (onIndexChangedListener != null) {
                onIndexChangedListener.onIndexChanged(radioButton, index);
            }
        });
        return radioButton;
    }


    public void setRadioGroup(RadioGroup radioGroup) {
        this.radioGroup = radioGroup;
    }

    public Integer getSelectedIndex() {
        return selectedIndex;
    }

    public void setSelectedIndex(int index) {
        if (index >= 0 && index < radioGroup.getChildCount()) {
            selectedIndex = index;
        } else if (index < 0) {
            selectedIndex = 0;
        } else {
            selectedIndex = radioGroup.getChildCount() - 1;
        }
        ((RadioButton) radioGroup.getChildAt(selectedIndex)).setChecked(true);
    }


    public void setEnabled(boolean enabled) {
        for (int i = 0; i < radioGroup.getChildCount(); i++) {
            radioGroup.getChildAt(i).setEnabled(enabled);
        }
    }

    public RadioItem(@NonNull Context context) {
        super(context);
    }

    public RadioItem(@NonNull Context context, @Nullable AttributeSet attrs) {
        super(context, attrs);
        initView(context, attrs);
    }

    public RadioItem(@NonNull Context context, @Nullable AttributeSet attrs, int defStyleAttr) {
        super(context, attrs, defStyleAttr);
        initView(context, attrs);
    }

    public RadioItem(@NonNull Context context, @Nullable AttributeSet attrs, int defStyleAttr, int defStyleRes) {
        super(context, attrs, defStyleAttr, defStyleRes);
        initView(context, attrs);
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

    public void setTitlePadding(int left, int top, int right, int bottom) {
        title_view.setPadding(left, top, right, bottom);
    }

    private void setTitle(String title, int titleColor) {
        title_view.setText(title);
        title_view.setTextColor(titleColor);
    }
}
