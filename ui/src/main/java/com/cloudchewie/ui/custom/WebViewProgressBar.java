package com.cloudchewie.ui.custom;

import android.content.Context;
import android.graphics.Canvas;
import android.graphics.Paint;
import android.util.AttributeSet;
import android.view.View;

import androidx.annotation.NonNull;

import com.cloudchewie.ui.ThemeUtil;

public class WebViewProgressBar extends View {
    private final static int HEIGHT = 5;
    private static int[] colors;
    private int progress = 1;
    private Paint paint;

    public WebViewProgressBar(Context context) {
        this(context, null);
    }

    public WebViewProgressBar(Context context, AttributeSet attrs) {
        this(context, attrs, 0);
    }

    public WebViewProgressBar(Context context, AttributeSet attrs, int defStyleAttr) {
        super(context, attrs, defStyleAttr);
        initPaint(context);
    }

    private void initPaint(@NonNull Context context) {
        colors = new int[3];
        colors[0] = ThemeUtil.getPrimaryColor(context);
        colors[1] = ThemeUtil.getPrimaryColor(context);
        colors[2] = ThemeUtil.getPrimaryColor(context);
        paint = new Paint(Paint.DITHER_FLAG);
        paint.setStyle(Paint.Style.STROKE);
        paint.setStrokeWidth(HEIGHT);
        paint.setAntiAlias(true);
        paint.setDither(true);
        paint.setColor(ThemeUtil.getPrimaryColor(context));
    }

    public void setProgress(int progress) {
        this.progress = progress;
        invalidate();
    }

    @Override
    protected void onDraw(@NonNull Canvas canvas) {
        canvas.drawRect(0, 0, getWidth() * progress / 100.0F, HEIGHT, paint);
    }
}