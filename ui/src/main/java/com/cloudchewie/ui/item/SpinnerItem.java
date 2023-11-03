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
import android.widget.ArrayAdapter;
import android.widget.CompoundButton;
import android.widget.Spinner;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.appcompat.content.res.AppCompatResources;
import androidx.constraintlayout.widget.ConstraintLayout;

import com.cloudchewie.ui.R;

import java.util.ArrayList;
import java.util.List;

public class SpinnerItem extends ConstraintLayout {
    private Spinner spinner;
    private TextView title_view;
    private ConstraintLayout mainLayout;
    private View divider;
    private Boolean isTouched = false;
    private OnCheckedChangedListener onCheckedChangedListener;

    public void setOnCheckedChangedListener(OnCheckedChangedListener onCheckedChangedListener) {
        this.onCheckedChangedListener = onCheckedChangedListener;
    }

    @SuppressLint("ClickableViewAccessibility")
    private void initView(Context context, AttributeSet attrs) {
        LayoutInflater.from(context).inflate(R.layout.widget_spinner_item, this, true);
        spinner = findViewById(R.id.spinner_item_spinner);
        title_view = findViewById(R.id.spinner_item_title);
        mainLayout = findViewById(R.id.spinner_item_layout);
        divider = findViewById(R.id.spinner_item_divider);
        @SuppressLint("CustomViewStyleable") TypedArray attr = context.obtainStyledAttributes(attrs, R.styleable.SpinnerItem);
        if (attr != null) {
            int titleBarBackground = attr.getResourceId(R.styleable.SpinnerItem_spinner_item_background, Color.TRANSPARENT);
            setBackgroundResource(titleBarBackground);
            String title = attr.getString(R.styleable.SpinnerItem_spinner_item_title);
            int titleColor = attr.getColor(R.styleable.SpinnerItem_spinner_item_title_color, getResources().getColor(R.color.color_accent, getResources().newTheme()));
            CharSequence[] strings = attr.getTextArray(R.styleable.SpinnerItem_spinner_item_array);
            setRadios(strings);
            setTitle(title, titleColor);
            boolean topRadiusEnable = attr.getBoolean(R.styleable.SpinnerItem_spinner_item_top_radius_enable, false);
            boolean bottomRadiusEnable = attr.getBoolean(R.styleable.SpinnerItem_spinner_item_bottom_radius_enable, false);
            setRadiusEnbale(topRadiusEnable, bottomRadiusEnable);
            attr.recycle();
        }
        spinner.setOnTouchListener((OnTouchListener) (view, motionEvent) -> {
            isTouched = true;
            return false;
        });
        spinner.setTag(title_view.getText().toString());
    }

    public Spinner getSpinner() {
        return spinner;
    }
    public void setRadios(CharSequence[] sequences) {
        List<String> strings=new ArrayList<>();
        for(CharSequence sequence:sequences)
            strings.add((String) sequence);
        spinner.setAdapter(new ArrayAdapter<>(getContext(), R.layout.widget_spinner_bean, strings));
    }
    public void setRadios(List<String> stringList) {
        spinner.setAdapter(new ArrayAdapter<>(getContext(), R.layout.widget_spinner_bean, stringList));
    }

    public void setSpinner(Spinner spinner) {
        this.spinner = spinner;
    }

    public SpinnerItem(@NonNull Context context) {
        super(context);
    }

    public SpinnerItem(@NonNull Context context, @Nullable AttributeSet attrs) {
        super(context, attrs);
        initView(context, attrs);
    }

    public SpinnerItem(@NonNull Context context, @Nullable AttributeSet attrs, int defStyleAttr) {
        super(context, attrs, defStyleAttr);
        initView(context, attrs);
    }

    public SpinnerItem(@NonNull Context context, @Nullable AttributeSet attrs, int defStyleAttr, int defStyleRes) {
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

    public interface OnCheckedChangedListener {
        void onChanged(CompoundButton buttonView, boolean isChecked);
    }

    public void setTitlePadding(int left, int top, int right, int bottom) {
        title_view.setPadding(left, top, right, bottom);
    }

    private void setTitle(String title, int titleColor) {
        title_view.setText(title);
        title_view.setTextColor(titleColor);
    }
}
