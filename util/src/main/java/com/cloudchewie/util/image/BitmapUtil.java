package com.cloudchewie.util.image;

import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Canvas;
import android.graphics.drawable.BitmapDrawable;
import android.graphics.drawable.Drawable;
import android.util.Base64;
import android.widget.ImageView;

import androidx.annotation.NonNull;
import androidx.core.graphics.ColorUtils;
import androidx.palette.graphics.Palette;

import org.jetbrains.annotations.Contract;

import java.io.ByteArrayOutputStream;
import java.io.UnsupportedEncodingException;
import java.net.URLDecoder;

public class BitmapUtil {
    /**
     * 获取本地图片的高宽比
     *
     * @param path 本地图片路径
     * @return 图片高宽比
     */
    public static double getAspectRatio(String path) {
        try {
            path = URLDecoder.decode(path, "UTF-8");
        } catch (UnsupportedEncodingException e) {
            e.printStackTrace();
        }
        Bitmap bitmap = BitmapFactory.decodeFile(path);
        if (bitmap == null)
            return 1.0;
        int height = bitmap.getHeight();
        int width = bitmap.getWidth();
        return height * 1.0 / width;
    }

    /**
     * 获取ImageView的bitmap
     *
     * @param imageView ImageView对象
     * @return ImageView对象的bitmap
     */
    public static Bitmap getBitmap(@NonNull ImageView imageView) {
        return ((BitmapDrawable) imageView.getDrawable()).getBitmap();
    }

    /**
     * Bitmap对象转Base64字符串
     *
     * @param bitmap Bitmap对象
     * @return Base64编码后的字符串
     */
    public static String bitmapToBase64(@NonNull Bitmap bitmap) {
        ByteArrayOutputStream outputStream = new ByteArrayOutputStream();
        bitmap.compress(Bitmap.CompressFormat.PNG, 100, outputStream);
        byte[] bytes = outputStream.toByteArray();
        return Base64.encodeToString(bytes, Base64.NO_WRAP);
    }

    /**
     * Drawble对象转Bitmap对象
     *
     * @param drawable Drawable对象
     * @return 转换后的Bitmap对象
     */
    public static Bitmap drawableToBitmap(Drawable drawable) {
        if (drawable instanceof BitmapDrawable) {
            return ((BitmapDrawable) drawable).getBitmap();
        }
        int width = drawable.getIntrinsicWidth();
        width = width > 0 ? width : 1;
        int height = drawable.getIntrinsicHeight();
        height = height > 0 ? height : 1;
        Bitmap bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888);
        Canvas canvas = new Canvas(bitmap);
        drawable.setBounds(0, 0, canvas.getWidth(), canvas.getHeight());
        drawable.draw(canvas);
        return bitmap;
    }

    /**
     * Bitmap对象转Drawble对象
     *
     * @param bitmap Bitmap对象
     * @return 转换后的Drawable对象
     */
    @NonNull
    @Contract("_, _ -> new")
    public static Drawable bitmapToDrawble(@NonNull Context context, Bitmap bitmap) {
        return new BitmapDrawable(context.getResources(), bitmap);
    }

    /**
     * 根据资源ID获取Bitmap对象
     *
     * @param context Context对象
     * @param resId   资源ID
     * @return 获取到的Bitmap对象
     */
    public static Bitmap decodeResource(@NonNull Context context, int resId) {
        return BitmapFactory.decodeResource(context.getResources(), resId);
    }

    /**
     * 返回Bitmap对象是否为深色图片
     *
     * @param bitmap 图片
     * @param left   左边界
     * @param top    上边界
     * @param right  右边界
     * @param bottom 下边界
     * @return -1表示不确定；0表示不是深色；1表示是深色
     */
    public static int isDarkBitmap(Bitmap bitmap, int left, int top, int right, int bottom) {
        final int[] isDark = {1};
        Palette.from(bitmap).setRegion(left, top, right, bottom).generate(palette -> {
            Palette.Swatch mostPopularSwatch = null;
            for (Palette.Swatch swatch : palette.getSwatches())
                if (mostPopularSwatch == null || mostPopularSwatch.getPopulation() < swatch.getPopulation())
                    mostPopularSwatch = swatch;
            if (mostPopularSwatch != null)
                isDark[0] = ColorUtils.calculateLuminance(mostPopularSwatch.getRgb()) < 0.5 ? 1 : 0;
        });
        return isDark[0];
    }
}
