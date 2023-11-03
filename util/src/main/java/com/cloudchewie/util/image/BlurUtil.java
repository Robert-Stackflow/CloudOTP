/*
 * Project Name: Worthy
 * Author: Ruida
 * Last Modified: 2022/12/18 13:14:23
 * Copyright(c) 2022 Ruida https://cloudchewie.com
 */

package com.cloudchewie.util.image;

import static com.cloudchewie.util.image.BitmapUtil.bitmapToDrawble;

import android.annotation.SuppressLint;
import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.drawable.Drawable;
import android.renderscript.Allocation;
import android.renderscript.Element;
import android.renderscript.RenderScript;
import android.renderscript.ScriptIntrinsicBlur;
import android.view.View;

import androidx.annotation.NonNull;

public class BlurUtil {
    /**
     * 为控件View设置模糊背景图片
     *
     * @param context Context对象
     * @param view    待设置模糊背景的控件View
     * @param bitmap  待设置的背景图片
     * @param radius  模糊半径
     */
    public static void setBlurBackground(Context context, @NonNull View view, Bitmap bitmap, int radius) {
        final Bitmap blurredBitmap = fastBlur(context, bitmap, radius);
        final Drawable drawable = bitmapToDrawble(context, blurredBitmap);
        view.setBackgroundDrawable(drawable);
    }

    /**
     * 为图片设置模糊效果
     *
     * @param context Context对象
     * @param bitmap  图片
     * @param radius  模糊半径
     * @return 设置模糊效果后的图片
     */
    @SuppressLint("NewApi")
    public static Bitmap fastBlur(Context context, @NonNull Bitmap bitmap, int radius) {
        Bitmap copy = bitmap.copy(bitmap.getConfig(), true);
        final RenderScript rs = RenderScript.create(context);
        final Allocation input = Allocation.createFromBitmap(rs, bitmap, Allocation.MipmapControl.MIPMAP_NONE, Allocation.USAGE_SCRIPT);
        final Allocation output = Allocation.createTyped(rs, input.getType());
        final ScriptIntrinsicBlur script = ScriptIntrinsicBlur.create(rs, Element.U8_4(rs));
        script.setRadius(radius);
        script.setInput(input);
        script.forEach(output);
        output.copyTo(copy);
        return copy;
    }
}
