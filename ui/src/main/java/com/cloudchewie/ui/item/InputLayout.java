/*
 * Project Name: Worthy
 * Author: Ruida
 * Last Modified: 2022/12/17 21:42:08
 * Copyright(c) 2022 Ruida https://cloudchewie.com
 */

package com.cloudchewie.ui.item;

import android.content.Context;
import android.content.res.ColorStateList;
import android.content.res.TypedArray;
import android.text.InputType;
import android.util.AttributeSet;
import android.util.TypedValue;
import android.view.LayoutInflater;
import android.view.View;
import android.view.inputmethod.EditorInfo;
import android.widget.EditText;
import android.widget.ImageButton;
import android.widget.ImageView;
import android.widget.RelativeLayout;

import com.cloudchewie.ui.R;

public class InputLayout extends RelativeLayout {
    View mainView;
    private ImageView leftIcon;
    private EditText editText;
    private ImageButton rightIcon;
    private RelativeLayout mainLayout;

    public InputLayout(Context context) {
        super(context);
    }

    public InputLayout(Context context, AttributeSet attrs) {
        super(context, attrs);
        initView(context, attrs);
    }

    public InputLayout(Context context, AttributeSet attrs, int defStyleAttr) {
        super(context, attrs, defStyleAttr);
        initView(context, attrs);
    }

    public InputLayout(Context context, AttributeSet attrs, int defStyleAttr, int defStyleRes) {
        super(context, attrs, defStyleAttr, defStyleRes);
        initView(context, attrs);
    }

    private void initView(Context context, AttributeSet attrs) {
        LayoutInflater.from(context).inflate(R.layout.widget_input_layout, this, true);
        mainLayout = findViewById(R.id.input_layout_layout);
        leftIcon = findViewById(R.id.input_layout_left_icon);
        rightIcon = findViewById(R.id.input_layout_right_icon);
        editText = findViewById(R.id.input_layout_edit);
        TypedArray attr = context.obtainStyledAttributes(attrs, R.styleable.InputLayout);
        if (attr != null) {
            String hint = attr.getString(R.styleable.InputLayout_input_layout_hint);
            String text = attr.getString(R.styleable.InputLayout_input_layout_text);
            int mode = attr.getInt(R.styleable.InputLayout_input_layout_mode, 0);
            boolean editable = attr.getBoolean(R.styleable.InputLayout_input_layout_editable, true);
            boolean leftIconVisibility = attr.getBoolean(R.styleable.InputLayout_input_layout_left_icon_visibility, false);
            int leftIconId = attr.getResourceId(R.styleable.InputLayout_input_layout_left_icon, R.drawable.ic_material_search);
            boolean rightIconVisibility = attr.getBoolean(R.styleable.InputLayout_input_layout_right_icon_visibility, false);
            int rightIconId = attr.getResourceId(R.styleable.InputLayout_input_layout_right_icon, R.drawable.ic_material_delete);
            int maxLines = attr.getInt(R.styleable.InputLayout_input_layout_max_lines, 20);
            boolean isSingleLine = attr.getBoolean(R.styleable.InputLayout_input_layout_single_line, false);
            int textSize = attr.getDimensionPixelSize(R.styleable.InputLayout_input_layout_text_size, getResources().getDimensionPixelSize(R.dimen.sp15));
            int backgroundId = attr.getResourceId(R.styleable.InputLayout_input_layout_background, R.drawable.shape_round_dp10);
            ColorStateList backgroundTintList = attr.getColorStateList(R.styleable.InputLayout_input_layout_backgroundTint);
            setMode(mode);
            setTextSize(textSize);
            setSingleLine(isSingleLine);
            setMaxLines(maxLines);
            setLeftButton(leftIconVisibility, leftIconId);
            setRightButton(rightIconVisibility, rightIconId);
            setEditText(hint, text, editable);
            setBackground(backgroundId);
            setBackgroundTint(backgroundTintList);
            attr.recycle();
        }
    }

    void setBackground(int id) {
        mainLayout.setBackgroundResource(id);
    }

    void setBackgroundTint(ColorStateList stateList) {
        mainLayout.setBackgroundTintList(stateList);
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
            rightIcon.setFocusable(true);
            rightIcon.setClickable(true);
            rightIcon.setSelected(false);
            setRightButton(true, R.drawable.ic_material_invisible);
            editText.setInputType(InputType.TYPE_CLASS_TEXT | InputType.TYPE_TEXT_VARIATION_PASSWORD);
            rightIcon.setOnClickListener(v -> {
                if (rightIcon.isSelected()) {
                    rightIcon.setSelected(false);
                    editText.setInputType(InputType.TYPE_CLASS_TEXT | InputType.TYPE_TEXT_VARIATION_PASSWORD);
                    setRightButton(true, R.drawable.ic_material_invisible);
                } else {
                    rightIcon.setSelected(true);
                    editText.setInputType(InputType.TYPE_TEXT_VARIATION_VISIBLE_PASSWORD);
                    setRightButton(true, R.drawable.ic_material_visible);
                }
            });
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
            if (editText instanceof android.widget.EditText) {
                editText.setCursorVisible(false);
                editText.setFocusable(false);
                editText.setFocusableInTouchMode(false);
            }
        }
    }

    public EditText getEditText() {
        return editText;
    }

    private void setLeftButton(boolean visibility, int iconId) {
        if (visibility) leftIcon.setVisibility(View.VISIBLE);
        else leftIcon.setVisibility(View.GONE);
        leftIcon.setImageResource(iconId);
    }

    private void setRightButton(boolean visibility, int iconId) {
        if (visibility) rightIcon.setVisibility(View.VISIBLE);
        else rightIcon.setVisibility(View.GONE);
        rightIcon.setImageResource(iconId);
    }
}
