package com.cloudchewie.util.system;

import android.content.ClipData;
import android.content.ClipDescription;
import android.content.ClipboardManager;
import android.content.Context;

import androidx.annotation.NonNull;

import com.blankj.utilcode.util.Utils;

public class ClipBoardUtil {

    public static void copy(final CharSequence text) {
        ClipboardManager cm = (ClipboardManager) Utils.getApp().getSystemService(Context.CLIPBOARD_SERVICE);
        cm.setPrimaryClip(ClipData.newPlainText(Utils.getApp().getPackageName(), text));
    }

    public static void copy(final CharSequence label, final CharSequence text) {
        ClipboardManager cm = (ClipboardManager) Utils.getApp().getSystemService(Context.CLIPBOARD_SERVICE);
        cm.setPrimaryClip(ClipData.newPlainText(label, text));
    }

    public static void clear() {
        ClipboardManager cm = (ClipboardManager) Utils.getApp().getSystemService(Context.CLIPBOARD_SERVICE);
        cm.setPrimaryClip(ClipData.newPlainText(null, ""));
    }

    @NonNull
    public static CharSequence getLabel() {
        ClipboardManager cm = (ClipboardManager) Utils.getApp().getSystemService(Context.CLIPBOARD_SERVICE);
        ClipDescription des = cm.getPrimaryClipDescription();
        if (des == null)
            return "";
        CharSequence label = des.getLabel();
        if (label == null)
            return "";
        return label;
    }

    @NonNull
    public static CharSequence getText() {
        ClipboardManager cm = (ClipboardManager) Utils.getApp().getSystemService(Context.CLIPBOARD_SERVICE);
        ClipData clip = cm.getPrimaryClip();
        if (clip != null && clip.getItemCount() > 0) {
            CharSequence text = clip.getItemAt(0).coerceToText(Utils.getApp());
            if (text != null) {
                return text;
            }
        }
        return "";
    }

    public static void addChangedListener(final ClipboardManager.OnPrimaryClipChangedListener listener) {
        ClipboardManager cm = (ClipboardManager) Utils.getApp().getSystemService(Context.CLIPBOARD_SERVICE);
        cm.addPrimaryClipChangedListener(listener);
    }

    public static void removeChangedListener(final ClipboardManager.OnPrimaryClipChangedListener listener) {
        ClipboardManager cm = (ClipboardManager) Utils.getApp().getSystemService(Context.CLIPBOARD_SERVICE);
        cm.removePrimaryClipChangedListener(listener);
    }
}
