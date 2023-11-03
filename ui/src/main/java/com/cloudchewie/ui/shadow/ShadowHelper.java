package com.cloudchewie.ui.shadow;

import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Matrix;
import android.graphics.NinePatch;
import android.graphics.Paint;
import android.graphics.Path;
import android.graphics.PorterDuff;
import android.graphics.Rect;
import android.view.View;

import java.nio.ByteBuffer;
import java.nio.ByteOrder;

/**
 * 阴影辅助器
 */
public class ShadowHelper {

    private Rect childRect = new Rect();

    /**
     * 创建.9图对象
     *
     * @param bitmap 位图
     * @param x1     可以缩放的区间X轴开始
     * @param x2     可以缩放的区间X轴结束
     * @param y1     可以缩放的区间Y轴开始
     * @param y2     可以缩放的区间Y轴结束
     * @return .9对象
     */
    static NinePatch createNinePatch(Bitmap bitmap, int x1, int x2, int y1, int y2) {
        ByteBuffer buffer = ByteBuffer.allocate(84).order(ByteOrder.nativeOrder());
        buffer.put((byte) 1) // 开始不能为0
                .put((byte) 2) // 表示在X方向取2个点，即X方向有3部分
                .put((byte) 2) // 表示在Y方向取2个点，即Y方向有3部分
                .put((byte) 9); // 表示每部分的缩放形式，X有3部分，Y有3部分，总共9部分，因此这里是9
        buffer.putInt(0).putInt(0) // 跳过8字节，填0即可
                // 结下了4字节表示padding值，这里无需设置，所以填0
                .putInt(0)
                .putInt(0)
                .putInt(0)
                .putInt(0)
                // 这个字节可以跳过，填0
                .putInt(0);
        buffer.putInt(x1).putInt(x2).putInt(y1).putInt(y2);
        buffer.putInt(1).putInt(1).putInt(1)
                .putInt(1).putInt(1).putInt(1)
                .putInt(1).putInt(1).putInt(1);
        byte[] chunk = buffer.array();
        return new NinePatch(bitmap, chunk);
    }

    /**
     * 在位图上画阴影
     *
     * @param bitmap       位图
     * @param path         阴影路径
     * @param solidColor   填充颜色
     * @param shadowRadius 阴影半径
     * @param shadowColor  阴影颜色
     * @param noSolid      无填充色（去除填充色）
     */
    static void draw(Bitmap bitmap,
                     Path path,
                     int solidColor,
                     float shadowRadius,
                     int shadowColor,
                     boolean noSolid) {
        Canvas canvas = new Canvas(bitmap);
        Paint paint = new Paint();
        paint.setAntiAlias(true);
        paint.setStyle(Paint.Style.FILL);
        paint.setColor(solidColor);
        if (noSolid) {
            boolean[] clears = new boolean[bitmap.getWidth() * bitmap.getHeight()];
            canvas.drawPath(path, paint);
            for (int y = 0; y < bitmap.getHeight(); y++) {
                int offset = y * bitmap.getWidth();
                for (int x = 0; x < bitmap.getWidth(); x++) {
                    int color = bitmap.getPixel(x, y);
                    clears[offset + x] = color != Color.TRANSPARENT;
                }
            }
            paint.setShadowLayer(shadowRadius, 0, 0, shadowColor);
            canvas.drawColor(Color.TRANSPARENT, PorterDuff.Mode.CLEAR);
            canvas.drawPath(path, paint);
            for (int y = 0; y < bitmap.getHeight(); y++) {
                int offset = y * bitmap.getWidth();
                for (int x = 0; x < bitmap.getWidth(); x++) {
                    if (clears[offset + x]) {
                        bitmap.setPixel(x, y, Color.TRANSPARENT);
                    }
                }
            }
        } else {
            paint.setShadowLayer(shadowRadius, 0, 0, shadowColor);
            canvas.drawPath(path, paint);
        }
    }

    /**
     * 使用默认的{@link ShadowManager#getDefault()} ShadowManager.getDefault}创建阴影
     *
     * @param key 阴影key
     * @return 阴影对象，不再使用时，需要调用{@link #destroyShadow(Shadow)} destroyShadow}方法或者
     * {@link ShadowManager#unbind(Shadow) ShadowManager.unbind}方法，
     * 也可以自行调用{@link Shadow#unbind() Shadow.unbind}方法（不推荐，shadow对象不会被回收，
     * 只是释放了shadow内部需要释放的对象，shadow对象会被ShadowManager缓存）
     * @deprecated 已过时，改用{@link #getShadow(Object) getShadow}方法
     */
    public static Shadow createShadow(Object key) {
        try {
            return ShadowManager.getDefault().bind(key);
        } catch (Exception e) {
            e.printStackTrace();
            return null;
        }
    }

    /**
     * 释放阴影对象
     *
     * @param shadow 阴影对象
     * @return true，释放成功
     */
    public static boolean destroyShadow(Shadow shadow) {
        return ShadowManager.getDefault().unbind(shadow);
    }

    /**
     * 获取阴影对象
     *
     * @param key 阴影key
     * @return 阴影对象
     */
    public static Shadow getShadow(Object key) {
        try {
            return ShadowManager.getDefault().get(key);
        } catch (Exception e) {
            // e.printStackTrace();
            return null;
        }
    }

    /**
     * 将阴影画在画布上
     *
     * @param canvas 画布
     * @param rect   阴影位置和大小
     * @param shadow 阴影对象
     * @param matrix 阴影转换矩阵
     * @param paint  画笔
     */
    public void drawShadow(
            Canvas canvas,
            Rect rect,
            Shadow shadow,
            Matrix matrix,
            Paint paint) {
        if (null == matrix) {
            shadow.draw(canvas, rect, paint);
        } else {
            int sc = canvas.save();
            // 转换画布
            int x = rect.left;
            int y = rect.top;
            canvas.translate(x, y);
            canvas.concat(matrix);
            // 矩形的位置必须偏移到原点
            rect.offsetTo(0, 0);
            shadow.draw(canvas, rect, paint);
            // 恢复矩形的位置
            rect.offsetTo(x, y);
            canvas.restoreToCount(sc);
        }
    }

    /**
     * 绘制子视图阴影
     *
     * @param canvas  画布
     * @param child   子视图
     * @param shadow  阴影
     * @param shadowX 阴影偏移量：X
     * @param shadowY 阴影偏移量：Y
     */
    public void drawChildShadow(
            Canvas canvas,
            View child,
            Shadow shadow,
            float shadowX,
            float shadowY) {
        childRect.set(child.getLeft(), child.getTop(), child.getRight(), child.getBottom());
        childRect.offset((int) shadowX, (int) shadowY);
        drawShadow(canvas, childRect, shadow, child.getMatrix(), null);
    }
}
