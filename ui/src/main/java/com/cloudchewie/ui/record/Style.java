package com.cloudchewie.ui.record;

import android.content.Context;
import android.content.res.Resources;
import android.graphics.drawable.Drawable;
import android.util.AttributeSet;

import androidx.annotation.ColorRes;
import androidx.annotation.DimenRes;
import androidx.annotation.DrawableRes;
import androidx.annotation.NonNull;
import androidx.appcompat.content.res.AppCompatResources;
import androidx.core.content.ContextCompat;

public abstract class Style {

    protected Context mContext;
    protected Resources resources;
    protected AttributeSet attrs;

    protected Style(@NonNull Context context, AttributeSet attrs) {
        this.mContext = context;
        this.attrs = attrs;
        this.resources = context.getResources();
    }

    protected final int getDimension(@DimenRes int dimen) {
        return resources.getDimensionPixelSize(dimen);
    }

    protected final int getColor(@ColorRes int color) {
        return ContextCompat.getColor(mContext, color);
    }

    protected final Drawable getDrawable(@DrawableRes int drawable) {
        return ContextCompat.getDrawable(mContext, drawable);
    }

    protected final Drawable getVectorDrawable(@DrawableRes int drawable) {
        return AppCompatResources.getDrawable(mContext, drawable);
    }

}
