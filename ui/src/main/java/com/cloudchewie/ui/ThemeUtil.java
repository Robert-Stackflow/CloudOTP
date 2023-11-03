package com.cloudchewie.ui;

import android.content.Context;
import android.content.res.TypedArray;

public class ThemeUtil {
    public static int getPrimaryColor(Context context) {
        TypedArray attr = context.getTheme().obtainStyledAttributes(new int[]{R.attr.colorPrimary});
        return attr.getColor(0, context.getColor(R.color.color_prominent));
    }
}
