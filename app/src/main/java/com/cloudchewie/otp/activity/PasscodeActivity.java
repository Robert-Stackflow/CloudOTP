package com.cloudchewie.otp.activity;

import android.os.Bundle;
import android.os.Handler;
import android.view.View;
import android.widget.ImageView;
import android.widget.TextView;

import androidx.annotation.Nullable;

import com.cloudchewie.otp.R;
import com.cloudchewie.otp.database.PrivacyManager;
import com.cloudchewie.otp.util.enumeration.EventBusCode;
import com.cloudchewie.otp.util.enumeration.PasscodeMode;
import com.cloudchewie.ui.custom.IToast;
import com.cloudchewie.ui.general.BottomSheet;
import com.cloudchewie.ui.passcode.PassCodeView;
import com.jeremyliao.liveeventbus.LiveEventBus;
import com.wei.android.lib.fingerprintidentify.FingerprintIdentify;
import com.wei.android.lib.fingerprintidentify.base.BaseFingerprint;

public class PasscodeActivity extends BaseActivity implements View.OnClickListener, BaseFingerprint.IdentifyListener, BaseFingerprint.ExceptionListener {
    ImageView passcodeIconView;
    TextView passcodeTipView;
    PassCodeView passCodeView;
    PasscodeMode mode;
    String firstPasscode;
    BottomSheet bottomSheet;
    Boolean isVerified = false;
    int passcodeTip;
    FingerprintIdentify mFingerprintIdentify;

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_passcode);
        int modeIndex = getIntent().getIntExtra("mode", -1);
        if (modeIndex == -1) {
            if (PrivacyManager.havePasscode()) mode = PasscodeMode.CHANGE;
            else mode = PasscodeMode.SET;
        } else {
            mode = PasscodeMode.values()[modeIndex];
        }
        passcodeIconView = findViewById(R.id.activity_passcode_lock_icon);
        passcodeTipView = findViewById(R.id.activity_passcode_lock_text);
        passCodeView = findViewById(R.id.activity_passcode_passcode_view);
        passcodeIconView.setOnClickListener(this);
        passcodeIconView.setOnClickListener(this);
        switch (mode) {
            case VERIFY:
                initBiometrics();
                passCodeView.setOnTextChangeListener(this::verifyPasscodeListener);
                startVerify();
                break;
            case CHANGE:
                passcodeTipView.setText(R.string.input_old_passcode);
                passCodeView.setOnTextChangeListener(this::changePasscodeListener);
                break;
            case SET:
                passcodeTipView.setText(R.string.input_passcode);
                passCodeView.setOnTextChangeListener(this::setPasscodeListener);
                break;
        }
    }

    void verifyPasscodeListener(String text) {
        if (text.length() == 4) {
            if (text.equals(PrivacyManager.getPasscode())) {
                passCodeView.reset();
                success();
            } else {
                passCodeView.setError(true);
                passcodeTipView.setText(R.string.wrong_passcode);
                passcodeTipView.setTextColor(getColor(R.color.text_color_red));
            }
        }
    }

    void setPasscodeListener(String text) {
        if (text.length() == 4) {
            if (firstPasscode == null) {
                firstPasscode = text;
                passCodeView.reset();
                passcodeTipView.setText(R.string.confirm_passcode);
            } else if (!text.equals(firstPasscode)) {
                passCodeView.reset();
                passcodeTipView.setText(R.string.mismatch_passcode);
                passcodeTipView.setTextColor(getColor(R.color.text_color_red));
            } else {
                PrivacyManager.setPasscode(firstPasscode);
                IToast.showBottom(this, getString(R.string.set_passcode_success));
                LiveEventBus.get(EventBusCode.CHANGE_PASSCODE.getKey()).post("change");
                finish();
            }
        } else if (text.length() > 0 && firstPasscode != null) {
            passcodeTipView.setText(R.string.confirm_passcode);
            passcodeTipView.setTextColor(getColor(R.color.color_accent));
        }
    }

    void changePasscodeListener(String text) {
        if (text.length() == 4) {
            if (!isVerified) {
                if (text.equals(PrivacyManager.getPasscode())) {
                    isVerified = true;
                    passCodeView.reset();
                    passcodeTipView.setText(R.string.input_new_passcode);
                } else {
                    passCodeView.setError(true);
                    passcodeTipView.setText(R.string.wrong_old_passcode);
                    passcodeTipView.setTextColor(getColor(R.color.text_color_red));
                }
            } else {
                if (firstPasscode == null) {
                    firstPasscode = text;
                    passCodeView.reset();
                    passcodeTipView.setText(R.string.confirm_passcode);
                } else if (!text.equals(firstPasscode)) {
                    passCodeView.reset();
                    passcodeTipView.setText(R.string.mismatch_passcode);
                    passcodeTipView.setTextColor(getColor(R.color.text_color_red));
                } else {
                    PrivacyManager.setPasscode(firstPasscode);
                    IToast.showBottom(this, getString(R.string.change_passcode_success));
                    finish();
                }
            }
        } else if (text.length() > 0) {
            if (!isVerified) {
                passcodeTipView.setText(R.string.input_old_passcode);
                passcodeTipView.setTextColor(getColor(R.color.color_accent));
            } else if (firstPasscode != null) {
                passcodeTipView.setText(R.string.confirm_passcode);
                passcodeTipView.setTextColor(getColor(R.color.color_accent));
            }
        }
    }

    public void initBiometrics() {
        mFingerprintIdentify = new FingerprintIdentify(this);
        mFingerprintIdentify.setSupportAndroidL(true);
        mFingerprintIdentify.setExceptionListener(this);
        mFingerprintIdentify.init();
        if (mFingerprintIdentify.isFingerprintEnable()) {
            passcodeTip = R.string.tap_to_use_biometrics;
            passcodeIconView.setImageResource(R.drawable.ic_material_fingerprint);
        } else {
            passcodeTip = R.string.unpin_to_show_code;
        }
        passcodeTipView.setText(passcodeTip);
    }

    @Override
    public void onPause() {
        super.onPause();
        if (mFingerprintIdentify != null) mFingerprintIdentify.cancelIdentify();
    }

    @Override
    public void onStop() {
        super.onStop();
        if (mFingerprintIdentify != null) mFingerprintIdentify.cancelIdentify();
    }

    @Override
    public void onBackPressed() {
        if (mode != PasscodeMode.VERIFY) super.onBackPressed();
    }

    @Override
    public void onDestroy() {
        super.onDestroy();
        if (mFingerprintIdentify != null) mFingerprintIdentify.cancelIdentify();
    }

    @Override
    public void onCatchException(Throwable exception) {

    }

    @Override
    public void onSucceed() {
        if (mFingerprintIdentify != null) mFingerprintIdentify.cancelIdentify();
        if (bottomSheet != null) bottomSheet.cancel();
        success();
    }

    private void success() {
        PrivacyManager.unlock();
        finish();
    }

    @Override
    public void onNotMatch(int availableTimes) {
        bottomSheet.setTitle(getString(R.string.verify_finger_fail));
        bottomSheet.setDragBarVisible(false);
        bottomSheet.setTitleColor(getColor(R.color.text_color_red));
        new Handler().postDelayed(() -> {
            bottomSheet.setTitle(getString(R.string.verify_finger));
            bottomSheet.setDragBarVisible(false);
            bottomSheet.setTitleColor(getColor(R.color.color_accent));
        }, 500);
    }

    @Override
    public void onFailed(boolean isDeviceLocked) {
        IToast.showBottom(this, getString(R.string.verify_finger_error));
        if (bottomSheet != null) bottomSheet.cancel();
    }

    @Override
    public void onStartFailedByDeviceLocked() {

    }

    @Override
    public void onClick(View view) {
        if ((view == passcodeTipView || view == passcodeIconView) && mode == PasscodeMode.VERIFY) {
            startVerify();
        }
    }

    void startVerify() {
        if (mFingerprintIdentify.isFingerprintEnable()) {
            bottomSheet = new BottomSheet(this);
            bottomSheet.setTitle(getString(R.string.verify_finger));
            bottomSheet.setDragBarVisible(false);
            bottomSheet.setLeftButtonVisible(false);
            bottomSheet.setRightButtonVisible(false);
            bottomSheet.setBackgroundColor(getColor(R.color.card_background));
            bottomSheet.setMainLayout(R.layout.layout_fingerprint);
            bottomSheet.show();
            bottomSheet.setOnCancelListener(dialogInterface -> mFingerprintIdentify.cancelIdentify());
            mFingerprintIdentify.resumeIdentify();
            mFingerprintIdentify.startIdentify(5, this);
        }
    }
}
