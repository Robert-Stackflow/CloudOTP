package com.cloudchewie.otp.widget;

import android.content.Context;
import android.view.View;
import android.view.inputmethod.EditorInfo;

import androidx.annotation.NonNull;
import androidx.appcompat.widget.AppCompatButton;

import com.cloudchewie.otp.R;
import com.cloudchewie.otp.database.PrivacyManager;
import com.cloudchewie.ui.custom.IToast;
import com.cloudchewie.ui.general.BottomSheet;
import com.cloudchewie.ui.item.InputItem;

import java.util.Objects;

public class SecretBottomSheet extends BottomSheet {
    OnConfirmListener onConfirmListener;
    InputItem firstPasswdEdit;
    InputItem secondPasswdEdit;
    InputItem oldPasswdEdit;
    AppCompatButton cancelButton;
    AppCompatButton confirmButton;
    MODE mode;
    String oldSecret;
    public SecretBottomSheet(@NonNull Context context, MODE mode) {
        super(context);
        this.mode = mode;
        initView();
    }

    public SecretBottomSheet setOnConfirmListener(OnConfirmListener onConfirmListener) {
        this.onConfirmListener = onConfirmListener;
        return this;
    }

    void initView() {
        setBackGroundTint(R.color.card_background);
        setTitleBarBackGroundTint(R.color.content_background);
        setMainLayout(R.layout.layout_set_secret);
        oldPasswdEdit = mainView.findViewById(R.id.layout_set_secret_old_password);
        firstPasswdEdit = mainView.findViewById(R.id.layout_set_secret_first_password);
        secondPasswdEdit = mainView.findViewById(R.id.layout_set_secret_second_password);
        secondPasswdEdit.getEditText().setImeOptions(EditorInfo.IME_ACTION_DONE);
        cancelButton = mainView.findViewById(R.id.layout_set_secret_cancel_button);
        confirmButton = mainView.findViewById(R.id.layout_set_secret_confirm_button);
        confirmButton.setOnClickListener(v -> onConfirmed());
        cancelButton.setOnClickListener(v -> dismiss());
        if (mode == MODE.CHANGE_SECRET) {
            oldSecret = PrivacyManager.getSecret();
            oldPasswdEdit.getEditText().requestFocus();
            firstPasswdEdit.setTitle(getContext().getString(R.string.new_secret));
        } else {
            oldPasswdEdit.setVisibility(View.GONE);
            firstPasswdEdit.getEditText().requestFocus();
        }
        if (mode == MODE.PULL) {
            secondPasswdEdit.setVisibility(View.GONE);
            firstPasswdEdit.setRadiusEnbale(true, true);
        }
        secondPasswdEdit.getEditText().setOnEditorActionListener((textView, i, keyEvent) -> {
            if (i == EditorInfo.IME_ACTION_DONE) onConfirmed();
            return true;
        });
    }

    private void onConfirmed() {
        switch (mode) {
            case PULL:
                if (onConfirmListener != null)
                    onConfirmListener.onPullConfirmed(this.firstPasswdEdit.getText());
                dismiss();
                break;
            case PUSH:
                if (!Objects.equals(firstPasswdEdit.getText(), secondPasswdEdit.getText())) {
                    IToast.showBottom(getContext(), getContext().getString(R.string.mismatch_secret));
                } else {
                    if (onConfirmListener != null)
                        onConfirmListener.onPushConfirmed(this.firstPasswdEdit.getText());
                    dismiss();
                }
                break;
            case SET_SECRET:
                if (!Objects.equals(firstPasswdEdit.getText(), secondPasswdEdit.getText())) {
                    IToast.showBottom(getContext(), getContext().getString(R.string.mismatch_secret));
                } else {
                    if (onConfirmListener != null)
                        onConfirmListener.onSetSecretConfirmed(this.firstPasswdEdit.getText());
                    dismiss();
                }
                break;
            case CHANGE_SECRET:
                if (oldSecret == null || !Objects.equals(oldPasswdEdit.getText(), oldSecret)) {
                    IToast.showBottom(getContext(), getContext().getString(R.string.wrong_old_secret));
                } else if (!Objects.equals(firstPasswdEdit.getText(), secondPasswdEdit.getText())) {
                    IToast.showBottom(getContext(), getContext().getString(R.string.mismatch_secret));
                } else {
                    if (onConfirmListener != null)
                        onConfirmListener.onSetSecretConfirmed(this.firstPasswdEdit.getText());
                    dismiss();
                }
                break;
        }
    }

    public enum MODE {
        PULL, PUSH, SET_SECRET, CHANGE_SECRET
    }

    public interface OnConfirmListener {
        void onPushConfirmed(String password);

        void onPullConfirmed(String password);

        void onSetSecretConfirmed(String password);
    }
}
