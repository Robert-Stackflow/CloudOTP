/*
 * Copyright (C) 2015 Baidu, Inc. All Rights Reserved.
 */

package com.cloudchewie.ui.general;

import android.content.Context;
import android.graphics.Canvas;
import android.util.AttributeSet;
import android.widget.FrameLayout;

/**
 * RotationLayout rotates the contents of the layout by multiples of 90 degrees.
 * <p/>
 * May not work with padding.
 */
public class RotationLayout extends FrameLayout {
    private int mRotation;

    public RotationLayout(Context context) {
        super(context);
    }

    public RotationLayout(Context context, AttributeSet attrs) {
        super(context, attrs);
    }

    public RotationLayout(Context context, AttributeSet attrs, int defStyle) {
        super(context, attrs, defStyle);
    }

    @Override
    protected void onMeasure(int widthMeasureSpec, int heightMeasureSpec) {
        if (mRotation == 1 || mRotation == 3) {
            super.onMeasure(widthMeasureSpec, heightMeasureSpec);
            setMeasuredDimension(getMeasuredHeight(), getMeasuredWidth());
        } else {
            super.onMeasure(widthMeasureSpec, heightMeasureSpec);
        }
    }

    /**
     * @param degrees the rotation, in degrees.
     */
    public void setViewRotation(int degrees) {
        mRotation = ((degrees + 360) % 360) / 90;
    }


    @Override
    public void dispatchDraw(Canvas canvas) {
        if (mRotation == 0) {
            super.dispatchDraw(canvas);
            return;
        }

        if (mRotation == 1) {
            canvas.translate(getWidth(), 0);
            canvas.rotate(90, getWidth() / 2.0F, 0);
            canvas.translate(getHeight() / 2.0F, getWidth() / 2.0F);
        } else if (mRotation == 2) {
            canvas.rotate(180, getWidth() / 2.0F, getHeight() / 2.0F);
        } else {
            canvas.translate(0, getHeight());
            canvas.rotate(270, getWidth() / 2.0F, 0);
            canvas.translate(getHeight() / 2.0F, -getWidth() / 2.0F);
        }

        super.dispatchDraw(canvas);
    }
}
