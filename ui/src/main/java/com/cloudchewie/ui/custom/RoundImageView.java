package com.cloudchewie.ui.custom;

import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.graphics.PorterDuff;
import android.graphics.PorterDuffXfermode;
import android.graphics.RectF;
import android.util.AttributeSet;
import android.util.TypedValue;

import com.cloudchewie.ui.general.BaseImageView;
import com.cloudchewie.util.ui.SizeUtil;


public class RoundImageView extends BaseImageView {

    private int mRadius;
    private int mMaskColor;

    public RoundImageView(Context context) {
        this(context, null);
    }

    public RoundImageView(Context context, AttributeSet attrs) {
        this(context, attrs, 0);
    }

    public RoundImageView(Context context, AttributeSet attrs, int defStyle) {
        super(context, attrs, defStyle);
        mRadius = SizeUtil.dp2px(getContext(), 5);
    }

    public Bitmap getBitmap(int width, int height) {
        Bitmap bitmap = Bitmap.createBitmap(width, height,
                Bitmap.Config.ARGB_8888);
        Canvas canvas = new Canvas(bitmap);
        Paint paint = new Paint(Paint.ANTI_ALIAS_FLAG);
        paint.setColor(Color.BLACK);
        canvas.drawRoundRect(new RectF(0.0f, 0.0f, width, height), mRadius, mRadius, paint);
        if (mMaskColor != 0) {
            paint.setXfermode(new PorterDuffXfermode(PorterDuff.Mode.DARKEN));
            paint.setStyle(Paint.Style.FILL);
            paint.setColor(mMaskColor);
            canvas.drawRoundRect(new RectF(0.0f, 0.0f, width, height), mRadius, mRadius, paint);
        }
        return bitmap;
    }

    @Override
    public Bitmap getBitmap() {
        return getBitmap(getWidth(), getHeight());
    }

    public void setBorderRadius(int typedValue, int avatarRadius) {
        if (typedValue == TypedValue.COMPLEX_UNIT_DIP)
            mRadius = SizeUtil.dp2px(getContext(), avatarRadius);
        else
            mRadius = avatarRadius;
        invalidate();
    }

    public void updateRadius() {
        setBorderRadius(TypedValue.COMPLEX_UNIT_PX, mRadius);
    }

    public void setMaskColor(int maskColor) {
        this.mMaskColor = maskColor;
        invalidate();
        updateRadius();
    }
}
