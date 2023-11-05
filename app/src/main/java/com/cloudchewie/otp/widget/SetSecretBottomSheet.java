package com.cloudchewie.otp.widget;

import android.content.Context;
import android.view.KeyEvent;
import android.view.View;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.appcompat.widget.AppCompatButton;

import com.cloudchewie.otp.R;
import com.cloudchewie.ui.general.BottomSheet;
import com.cloudchewie.ui.item.InputItem;

public class SetSecretBottomSheet extends BottomSheet implements TextView.OnEditorActionListener {
    OnConfirmListener onConfirmListener;
    InputItem firstPasswdEdit;
    InputItem secondPasswdEdit;
    AppCompatButton cancelButton;
    boolean hasRemoteFile;

    public SetSecretBottomSheet(@NonNull Context context, boolean hasRemoteFile) {
        super(context);
        this.hasRemoteFile = hasRemoteFile;
        initView();
    }

    public SetSecretBottomSheet setOnCancelListener(OnConfirmListener onConfirmListener) {
        this.onConfirmListener = onConfirmListener;
        return this;
    }

    void initView() {
        setBackGroundTint(R.color.card_background);
        setTitleBarBackGroundTint(R.color.content_background);
        setMainLayout(R.layout.layout_set_secret);
        firstPasswdEdit = mainView.findViewById(R.id.layout_set_secret_first_password);
        secondPasswdEdit = mainView.findViewById(R.id.layout_set_secret_second_password);
        cancelButton = mainView.findViewById(R.id.layout_set_secret_cancel_button);
        if (hasRemoteFile) {
            secondPasswdEdit.setVisibility(View.GONE);
        }
    }

    public interface OnConfirmListener {
        void onPasswordSet(String password);
    }

    @Override
    public boolean onEditorAction(TextView textView, int i, KeyEvent keyEvent) {
        if (onConfirmListener != null)
            onConfirmListener.onPasswordSet(this.firstPasswdEdit.getText());
        dismiss();
        return true;
    }

//    private val dismissClickListener = View.OnClickListener {
//        if (!hasRemoteFile && db_password!!.text.toString() != db_password_verification!!.text.toString()) {
//            Toast.makeText(
//                    activity.applicationContext,
//                    R.string.mismatch_passcode,
//                    Toast.LENGTH_SHORT
//            ).show()
//        } else {
//            val activity = activity as DropboxFilePasswordListener
//            activity.onFinishPasswordDialog(db_password!!.text.toString())
//            dialog.dismiss()
//        }
//    }
}
