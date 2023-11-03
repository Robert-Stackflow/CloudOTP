package com.cloudchewie.ui.emoji;

import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.drawable.BitmapDrawable;
import android.graphics.drawable.Drawable;
import android.text.TextUtils;
import android.widget.EditText;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.appcompat.content.res.AppCompatResources;

import java.io.IOException;

/**
 * use XhsEmotionsKeyboard(https://github.com/w446108264/XhsEmoticonsKeyboard)
 * author: sj
 */
public abstract class EmoticonFilter {

    @Nullable
    public static Drawable getDrawableFromAssets(@NonNull Context context, String emoticonName) {
        Bitmap bitmap;
        try {
            bitmap = BitmapFactory.decodeStream(context.getAssets().open(emoticonName));
            return new BitmapDrawable(bitmap);
        } catch (IOException e) {
            e.printStackTrace();
        }

        return null;
    }

    @Nullable
    public static Drawable getDrawable(Context context, String emojiName) {
        if (TextUtils.isEmpty(emojiName)) {
            return null;
        }

        if (emojiName.contains(".")) {
            emojiName = emojiName.substring(0, emojiName.indexOf("."));
        }
        int resID = context.getResources().getIdentifier(emojiName, "mipmap", context.getPackageName());
        if (resID <= 0) {
            resID = context.getResources().getIdentifier(emojiName, "drawable", context.getPackageName());
        }

        try {
            return AppCompatResources.getDrawable(context, resID);
        } catch (Exception var4) {
            var4.printStackTrace();
            return null;
        }
    }

    @Nullable
    public static Drawable getDrawable(Context context, int emoticon) {
        if (emoticon <= 0) {
            return null;
        }
        try {
            return AppCompatResources.getDrawable(context, emoticon);
        } catch (Exception var4) {
            var4.printStackTrace();
            return null;
        }
    }

    public abstract void filter(EditText editText, CharSequence text, int start, int lengthBefore, int lengthAfter);
}
