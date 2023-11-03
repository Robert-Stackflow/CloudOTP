package com.cloudchewie.ui.shadow;

import android.graphics.Canvas;
import android.graphics.Paint;
import android.graphics.Rect;

/**
 * 表示一种阴影
 */
public abstract class Shadow {

    protected Object key;
    private int usedCount;

    /**
     * 如果有地方引用此对象，需要调用此方法
     *
     * @deprecated 已过时，不用主动绑定
     */
    public void bind() {
        synchronized (this) {
            usedCount++;
        }
    }

    /**
     * 如果不需要引用此对象，调用此方法
     *
     * @deprecated 已过时，不用主动释放对象
     */
    public void unbind() {
        synchronized (this) {
            if (usedCount > 0) {
                usedCount--;
            }
            if (usedCount == 0) {
                onDestroy();
            }
        }
    }

    /**
     * 判断此阴影对象是否被引用
     *
     * @return true，被引用
     * @deprecated 已失效，主要对象存在，就可用
     */
    public boolean isUsed() {
        return usedCount > 0;
    }

    /**
     * 获取阴影key
     *
     * @return 阴影key
     */
    public Object getKey() {
        return key;
    }

    /**
     * 释放阴影对象
     */
    protected abstract void onDestroy();

    /**
     * 将阴影对象画在画布上
     *
     * @param canvas 画布
     * @param rect   位置和大小
     * @param paint  额外画笔
     */
    public abstract void draw(Canvas canvas, Rect rect, Paint paint);
}
