package com.cloudchewie.otp.widget;

import android.annotation.SuppressLint;
import android.app.Activity;
import android.content.Context;
import android.os.Bundle;
import android.text.Editable;
import android.text.InputFilter;
import android.text.TextUtils;
import android.text.TextWatcher;
import android.view.View;
import android.widget.Button;
import android.widget.EditText;
import android.widget.TextView;
import android.widget.Toast;

import androidx.annotation.NonNull;

import com.blankj.utilcode.util.KeyboardUtils;
import com.cloudchewie.otp.R;
import com.cloudchewie.ui.custom.IToast;
import com.cloudchewie.ui.general.BottomSheet;
import com.cloudchewie.ui.item.InputLayout;

public class InputBottomSheet extends BottomSheet {
    Context context;
    String title;
    String content;
    String hint;
    boolean isRequired;
    int maxLines = -1;
    int minLines = -1;
    int maxLength = -1;
    EditText editText;
    InputLayout inputLayout;
    Button confirmButton;
    Button cancelButton;
    TextView countView;
    OnConfirmClickedListener onConfirmClickedListener;

    public InputBottomSheet(@NonNull Context context, String title, String content, int maxLength, boolean isRequired) {
        super(context);
        this.context = context;
        this.title = title;
        this.content = content;
        this.maxLength = maxLength;
        this.isRequired = isRequired;
        initView();
    }

    public InputBottomSheet(@NonNull Context context, String title, String content, String hint, int maxLength, boolean isRequired) {
        super(context);
        this.context = context;
        this.title = title;
        this.hint = hint;
        this.content = content;
        this.maxLength = maxLength;
        this.isRequired = isRequired;
        initView();
    }

    public InputBottomSheet(@NonNull Context context, String title, String content, int maxLength, boolean isRequired, int minLines) {
        super(context);
        this.context = context;
        this.title = title;
        this.content = content;
        this.maxLength = maxLength;
        this.isRequired = isRequired;
        this.minLines = minLines;
        initView();
    }

    public InputBottomSheet(@NonNull Context context, Bundle bundle) {
        super(context);
        this.context = context;
        if (bundle != null) {
            title = bundle.getString("title", "");
            content = bundle.getString("content");
            hint = bundle.getString("hint");
            maxLines = bundle.getInt("maxlines");
            minLines = bundle.getInt("minlines");
            maxLength = bundle.getInt("maxlength");
            isRequired = bundle.getBoolean("isrequired", false);
        }
        initView();
    }

    public OnConfirmClickedListener getOnConfirmClickedListener() {
        return onConfirmClickedListener;
    }

    public void setOnConfirmClickedListener(OnConfirmClickedListener onConfirmClickedListener) {
        this.onConfirmClickedListener = onConfirmClickedListener;
    }

    @SuppressLint("SetTextI18n")
    void initView() {
        setOnShowListener(dialog -> {
            KeyboardUtils.showSoftInput((Activity) context);
            editText.requestFocus();
        });
        setTitle(title);
        setDragBarVisible(false);
        leftButton.setVisibility(View.GONE);
        rightButton.setVisibility(View.GONE);
        setBackGroundTint(R.color.card_background);
        setTitleBarBackGroundTint(R.color.card_background);
        setMainLayout(R.layout.layout_input_bottom_sheet);
        confirmButton = mainView.findViewById(R.id.layout_input_bottom_sheet_confirm);
        inputLayout = mainView.findViewById(R.id.layout_input_bottom_sheet_input);
        countView = mainView.findViewById(R.id.layout_input_bottom_sheet_count);
        cancelButton = mainView.findViewById(R.id.layout_input_bottom_sheet_cancel);
        editText = inputLayout.getEditText();
        editText.setText(content);
        editText.setHint(hint);
        editText.setSelection(editText.getText().toString().length());
        if (maxLines > 0) editText.setMaxLines(maxLines);
        if (minLines > 0) editText.setMaxLines(minLines);
        if (maxLength > 0) {
            editText.setMaxLines(maxLength);
            editText.setFilters(new InputFilter[]{new InputFilter.LengthFilter(maxLength)});
            countView.setVisibility(View.VISIBLE);
            countView.setText((content != null ? content.length() : 0) + "/" + maxLength);
            editText.addTextChangedListener(new TextWatcher() {
                @Override
                public void beforeTextChanged(CharSequence s, int start, int count, int after) {

                }

                @Override
                public void onTextChanged(CharSequence s, int start, int before, int count) {
                    countView.setText(s.length() + "/" + maxLength);
                }

                @Override
                public void afterTextChanged(Editable s) {

                }
            });
        }
        confirmButton.setOnClickListener(v -> {
            if (isRequired && TextUtils.isEmpty(inputLayout.getText())) {
                IToast.makeTextTop(getContext(), title + context.getString(R.string.cannot_be_null), Toast.LENGTH_SHORT).show();
            } else {
                if (onConfirmClickedListener != null)
                    onConfirmClickedListener.OnConfirmClicked(inputLayout.getText());
                dismiss();
            }
        });
        cancelButton.setOnClickListener(v -> dismiss());
    }

    public void hideKeyBoard() {
        KeyboardUtils.hideSoftInput((Activity) context);
    }

    public interface OnConfirmClickedListener {
        void OnConfirmClicked(String content);
    }

    public void setHint(String hint) {
        this.hint = hint;
        this.editText.setHint(hint);
    }
}