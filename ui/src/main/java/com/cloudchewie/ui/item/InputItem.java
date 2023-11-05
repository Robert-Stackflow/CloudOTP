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
import android.text.InputType;
import android.util.AttributeSet;
import android.util.TypedValue;
import android.view.LayoutInflater;
import android.view.View;
import android.view.inputmethod.EditorInfo;
import android.widget.CompoundButton;
import android.widget.EditText;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.appcompat.content.res.AppCompatResources;
import androidx.constraintlayout.widget.ConstraintLayout;

import com.cloudchewie.ui.R;

public class InputItem extends ConstraintLayout {
    private EditText editText;
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
        LayoutInflater.from(context).inflate(R.layout.widget_input_item, this, true);
        editText = findViewById(R.id.input_item_edit_text);
        title_view = findViewById(R.id.input_item_title);
        mainLayout = findViewById(R.id.input_item_layout);
        divider = findViewById(R.id.input_item_divider);
        @SuppressLint("CustomViewStyleable") TypedArray attr = context.obtainStyledAttributes(attrs, R.styleable.InputItem);
        if (attr != null) {
            int titleBarBackground = attr.getResourceId(R.styleable.InputItem_input_item_background, Color.TRANSPARENT);
            setBackgroundResource(titleBarBackground);
            String title = attr.getString(R.styleable.InputItem_input_item_title);
            int titleColor = attr.getColor(R.styleable.InputItem_input_item_title_color, getResources().getColor(R.color.color_accent, getResources().newTheme()));
            setTitle(title, titleColor);
            boolean topRadiusEnable = attr.getBoolean(R.styleable.InputItem_input_item_top_radius_enable, false);
            boolean bottomRadiusEnable = attr.getBoolean(R.styleable.InputItem_input_item_bottom_radius_enable, false);
            String hint = attr.getString(R.styleable.InputItem_input_item_hint);
            String text = attr.getString(R.styleable.InputItem_input_item_text);
            int mode = attr.getInt(R.styleable.InputItem_input_item_mode, 0);
            boolean editable = attr.getBoolean(R.styleable.InputItem_input_item_editable, true);
            int maxLines = attr.getInt(R.styleable.InputItem_input_item_max_lines, 20);
            boolean isSingleLine = attr.getBoolean(R.styleable.InputItem_input_item_single_line, false);
            int textSize = attr.getDimensionPixelSize(R.styleable.InputItem_input_item_text_size, getResources().getDimensionPixelSize(R.dimen.sp15));
            setRadiusEnbale(topRadiusEnable, bottomRadiusEnable);
            setMode(mode);
            setTextSize(textSize);
            setSingleLine(isSingleLine);
            setMaxLines(maxLines);
            setEditText(hint, text, editable);
            attr.recycle();
        }
        editText.setOnTouchListener((OnTouchListener) (view, motionEvent) -> {
            isTouched = true;
            return false;
        });
        editText.setTag(title_view.getText().toString());
    }

    public EditText getEditText() {
        return editText;
    }

    public void setDisabled(boolean disabled) {
        getEditText().setEnabled(!disabled);
    }

    private void setMode(int mode) {
        if (mode == 0) {
            editText.setInputType(InputType.TYPE_CLASS_TEXT);
            editText.setImeOptions(EditorInfo.IME_ACTION_DONE);
        } else if (mode == 1) {
            editText.setInputType(InputType.TYPE_TEXT_FLAG_MULTI_LINE);
            editText.setImeOptions(EditorInfo.IME_ACTION_NONE);
        } else if (mode == 2) {
            editText.setInputType(InputType.TYPE_CLASS_NUMBER);
            editText.setImeOptions(EditorInfo.IME_ACTION_DONE);
        } else if (mode == 3) {
            editText.setInputType(InputType.TYPE_CLASS_TEXT | InputType.TYPE_TEXT_VARIATION_PASSWORD);
            editText.setImeOptions(EditorInfo.IME_ACTION_NEXT);
        } else if (mode == 4) {
            editText.setInputType(InputType.TYPE_CLASS_PHONE);
            editText.setImeOptions(EditorInfo.IME_ACTION_DONE);
        } else if (mode == 5) {
            editText.setInputType(InputType.TYPE_TEXT_VARIATION_EMAIL_ADDRESS);
            editText.setImeOptions(EditorInfo.IME_ACTION_DONE);
        }
    }

    public void setMaxLines(int maxLines) {
        editText.setMaxLines(maxLines);
    }

    public void setSingleLine(boolean singleLine) {
        editText.setSingleLine(singleLine);
    }

    public void setHint(String hint) {
        editText.setHint(hint);
    }

    public String getText() {
        return editText.getText().toString();
    }

    public void setTextSize(int textSize) {
        editText.setTextSize(TypedValue.COMPLEX_UNIT_PX, textSize);
    }

    private void setEditText(String hint, String text, boolean editable) {
        editText.setText(text);
        editText.setHint(hint);
        if (!editable) {
            if (editText != null) {
                editText.setCursorVisible(false);
                editText.setFocusable(false);
                editText.setFocusableInTouchMode(false);
            }
        }
    }

    public void setEditText(EditText editText) {
        this.editText = editText;
    }

    public InputItem(@NonNull Context context) {
        super(context);
    }

    public InputItem(@NonNull Context context, @Nullable AttributeSet attrs) {
        super(context, attrs);
        initView(context, attrs);
    }

    public InputItem(@NonNull Context context, @Nullable AttributeSet attrs, int defStyleAttr) {
        super(context, attrs, defStyleAttr);
        initView(context, attrs);
    }

    public InputItem(@NonNull Context context, @Nullable AttributeSet attrs, int defStyleAttr, int defStyleRes) {
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
