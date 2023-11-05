package com.cloudchewie.otp.activity;

import android.os.Bundle;
import android.widget.ImageView;
import android.widget.TextView;

import androidx.annotation.Nullable;

import com.cloudchewie.otp.R;
import com.cloudchewie.otp.util.database.AppSharedPreferenceUtil;
import com.cloudchewie.otp.util.enumeration.EventBusCode;
import com.cloudchewie.ui.custom.IToast;
import com.cloudchewie.ui.passcode.PassCodeView;
import com.jeremyliao.liveeventbus.LiveEventBus;

enum PasscodeMode {
    SET, CHANGE
}

public class PasscodeActivity extends BaseActivity {
    ImageView iconView;
    TextView textView;
    PassCodeView passCodeView;
    PasscodeMode mode;
    String firstPasscode;
    Boolean isVerified = false;

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_passcode);
        iconView = findViewById(R.id.activity_passcode_lock_icon);
        textView = findViewById(R.id.activity_passcode_lock_text);
        passCodeView = findViewById(R.id.activity_passcode_passcode_view);
        if (AppSharedPreferenceUtil.havePasscode(this)) {
            mode = PasscodeMode.CHANGE;
            textView.setText(R.string.input_old_passcode);
            passCodeView.setOnTextChangeListener(this::changePasscodeListener);
        } else {
            mode = PasscodeMode.SET;
            textView.setText(R.string.input_passcode);
            passCodeView.setOnTextChangeListener(this::setPasscodeListener);
        }
    }

    void setPasscodeListener(String text) {
        if (text.length() == 4) {
            if (firstPasscode == null) {
                firstPasscode = text;
                passCodeView.reset();
                textView.setText(R.string.confirm_passcode);
            } else if (!text.equals(firstPasscode)) {
                passCodeView.reset();
                textView.setText(R.string.mismatch_passcode);
                textView.setTextColor(getColor(R.color.text_color_red));
            } else {
                AppSharedPreferenceUtil.setPasscode(this, firstPasscode);
                IToast.showBottom(this, getString(R.string.set_passcode_success));
                LiveEventBus.get(EventBusCode.CHANGE_PASSCODE.getKey()).post("change");
                finish();
            }
        } else if (text.length() > 0 && firstPasscode != null) {
            textView.setText(R.string.confirm_passcode);
            textView.setTextColor(getColor(R.color.color_accent));
        }
    }

    void changePasscodeListener(String text) {
        if (text.length() == 4) {
            if (!isVerified) {
                if (text.equals(AppSharedPreferenceUtil.getPasscode(this))) {
                    isVerified = true;
                    passCodeView.reset();
                    textView.setText(R.string.input_new_passcode);
                } else {
                    passCodeView.setError(true);
                    textView.setText(R.string.wrong_old_passcode);
                    textView.setTextColor(getColor(R.color.text_color_red));
                }
            } else {
                if (firstPasscode == null) {
                    firstPasscode = text;
                    passCodeView.reset();
                    textView.setText(R.string.confirm_passcode);
                } else if (!text.equals(firstPasscode)) {
                    passCodeView.reset();
                    textView.setText(R.string.mismatch_passcode);
                    textView.setTextColor(getColor(R.color.text_color_red));
                } else {
                    AppSharedPreferenceUtil.setPasscode(this, firstPasscode);
                    IToast.showBottom(this, getString(R.string.change_passcode_success));
                    finish();
                }
            }
        } else if (text.length() > 0) {
            if (!isVerified) {
                textView.setText(R.string.input_old_passcode);
                textView.setTextColor(getColor(R.color.color_accent));
            } else if (firstPasscode != null) {
                textView.setText(R.string.confirm_passcode);
                textView.setTextColor(getColor(R.color.color_accent));
            }
        }
    }
}
