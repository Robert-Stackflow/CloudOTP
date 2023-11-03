package com.cloudchewie.ui.custom;

import android.annotation.SuppressLint;
import android.content.Context;
import android.view.Gravity;
import android.view.LayoutInflater;
import android.view.View;
import android.widget.TextView;
import android.widget.Toast;

import androidx.annotation.NonNull;

import com.cloudchewie.ui.R;
import com.cloudchewie.util.ui.SizeUtil;

import org.jetbrains.annotations.Contract;

public class IToast {
    private Context context;
    private TextView toastText;
    private Toast toast = null;

    private IToast(Context context) {
        this.context = context;
    }

    @NonNull
    public static IToast makeTextTop(Context context, String text, int time) {
        IToast toast = new IToast(context);
        toast.init();
        toast.setText(text);
        toast.setShowTime(time);
        toast.setGravity(Gravity.TOP);
        return toast;
    }

    @NonNull
    public static IToast makeTextCenter(Context context, String text, int time) {
        IToast toast = new IToast(context);
        toast.init();
        toast.setText(text);
        toast.setShowTime(time);
        toast.setGravity(Gravity.CENTER);
        return toast;
    }

    @NonNull
    public static IToast makeTextBottom(Context context, String text, int time) {
        IToast toast = new IToast(context);
        toast.init();
        toast.setText(text);
        toast.setShowTime(time);
        toast.setGravity(Gravity.BOTTOM);
        return toast;
    }

    @Contract(pure = true)
    public static void showTop(Context context, String text) {
        IToast.makeTextTop(context, text, Toast.LENGTH_SHORT).show();
    }

    @Contract(pure = true)
    public static void showCenter(Context context, String text) {
        IToast.makeTextCenter(context, text, Toast.LENGTH_SHORT).show();
    }

    @Contract(pure = true)
    public static void showBottom(Context context, String text) {
        IToast.makeTextBottom(context, text, Toast.LENGTH_SHORT).show();
    }

    public void init() {
        if (toast == null) {
            toast = new Toast(context);
            @SuppressLint("InflateParams")
            View view = LayoutInflater.from(context).inflate(R.layout.widget_toast, null, false);
            toastText = view.findViewById(R.id.toast_content);
            toast.setView(view);
        }
    }

    private void setGravity(int gravity) {
        if (gravity == Gravity.TOP) {
            toast.setGravity(gravity, 0, SizeUtil.dp2px(context, 150));
        } else if (gravity == Gravity.BOTTOM) {
            toast.setGravity(gravity, 0, SizeUtil.dp2px(context, 150));
        } else {
            toast.setGravity(gravity, 0, 0);
        }
    }

    public void setText(String text) {
        toastText.setText(text);
    }

    public void show() {
        toast.show();
    }

    public void setShowTime(int time) {
        toast.setDuration(time);
    }

    public void setTextColor(int color) {
        toastText.setTextColor(context.getResources().getColor(color));
    }

    public void cancel() {
        toast.cancel();
    }

    public void setTextSize(float size) {
        toastText.setTextSize(size);
    }
}
