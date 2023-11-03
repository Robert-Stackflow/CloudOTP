package com.cloudchewie.util.ui;

import androidx.annotation.ColorInt;
import androidx.annotation.IntRange;
import androidx.core.graphics.ColorUtils;

public class ColorUtil {
    /**
     * 判断某个颜色是否为深色
     *
     * @param color 待判断颜色
     * @return 是否为深色
     */
    public static boolean isDarkColor(@ColorInt int color) {
        return ColorUtils.calculateLuminance(color) < 0.5;
    }

    @ColorInt
    public static int setAlphaComponent(@ColorInt int color, @IntRange(from = 0L, to = 255L) int alpha) {
        if (alpha >= 0 && alpha <= 255) {
            return color & 16777215 | alpha << 24;
        } else {
            throw new IllegalArgumentException("alpha must be between 0 and 255.");
        }
    }
}
