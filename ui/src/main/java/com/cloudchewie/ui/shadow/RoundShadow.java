package com.cloudchewie.ui.shadow;

import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.NinePatch;
import android.graphics.Paint;
import android.graphics.Path;
import android.graphics.Rect;
import android.graphics.RectF;

import androidx.annotation.NonNull;

import java.io.Serializable;
import java.util.Arrays;

/**
 * 圆角矩形阴影
 */
public class RoundShadow extends Shadow {

    private static final int FIXED_SIZE = 6;

    private Bitmap bitmap; // 缓存阴影的图像
    private NinePatch ninePatch; // 点9图对象，防止缩放
    private RectF rect; // 阴影矩形的位置和大小
    private Rect drawRect; // 画图时需要的矩形对象

    public RoundShadow(Key key) {
        key.check();
        this.key = key.clone();
        int minCornerSize = (int) key.shadowRadius; // 最小的角大小
        if (!key.hasRound()) { // 没有圆角
            // 计算阴影效果图的大小：
            // 可缩放部分大小（FIXED_SIZE）+角大小（minCornerSize）*2+阴影大小（shadowRadius）*2
            int width = (int) (FIXED_SIZE + key.shadowRadius * 2 + minCornerSize * 2);
            int height = (int) (FIXED_SIZE + key.shadowRadius * 2 + minCornerSize * 2);
            // 计算出阴影矩形的位置和大小
            rect = new RectF();
            rect.left = key.shadowRadius;
            rect.top = key.shadowRadius;
            rect.right = width - key.shadowRadius;
            rect.bottom = height - key.shadowRadius;
            // 创建矩形路径，用于绘制阴影
            Path path = new Path();
            path.addRect(rect, Path.Direction.CW);
            // 创建位图，用于缓存阴影效果
            bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888);
            // 在bitmap上绘制阴影效果
            ShadowHelper.draw(bitmap, path, key.solidColor,
                    key.shadowRadius, key.shadowColor, key.noSolid);
            // 计算.9图片缩放位置
            int x1 = (int) (rect.left + minCornerSize);
            int x2 = (int) (rect.right - minCornerSize);
            int y1 = (int) (rect.top + minCornerSize);
            int y2 = (int) (rect.bottom - minCornerSize);
            // 创建.9缩放对象
            ninePatch = ShadowHelper.createNinePatch(bitmap, x1, x2, y1, y2);
        } else { // 带有圆角
            // 计算左边部分大小
            float ls = Math.max(key.radii[0], key.radii[6]);
            if (ls == 0) ls = minCornerSize;
            // 计算右边部分大小
            float rs = Math.max(key.radii[2], key.radii[4]);
            if (rs == 0) rs = minCornerSize;
            // 计算上边部分大小
            float ts = Math.max(key.radii[1], key.radii[7]);
            if (ts == 0) ts = minCornerSize;
            // 计算下边部分大小
            float bs = Math.max(key.radii[3], key.radii[5]);
            if (bs == 0) bs = minCornerSize;
            // 计算阴影效果图的大小
            // 宽：可缩放部分大小（FIXED_SIZE）+左（ls）+右（ls）+阴影大小（shadowRadius）*2
            // 高：可缩放部分大小（FIXED_SIZE）+上（ls）+下（ls）+阴影大小（shadowRadius）*2
            int width = (int) (ls + rs + FIXED_SIZE + key.shadowRadius * 2);
            int height = (int) (ts + bs + FIXED_SIZE + key.shadowRadius * 2);
            // 计算出阴影矩形的位置和大小
            rect = new RectF();
            rect.left = key.shadowRadius;
            rect.top = key.shadowRadius;
            rect.right = width - key.shadowRadius;
            rect.bottom = height - key.shadowRadius;
            // 创建矩形路径，用于绘制阴影
            Path path = new Path();
            path.addRoundRect(rect, key.radii, Path.Direction.CW);
            // 创建位图，用于缓存阴影效果
            bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888);
            // 在bitmap上绘制阴影效果
            ShadowHelper.draw(bitmap, path, key.solidColor,
                    key.shadowRadius, key.shadowColor, key.noSolid);
            // 计算.9图片缩放位置
            int x1 = (int) (rect.left + ls);
            int x2 = (int) (rect.right - rs);
            int y1 = (int) (rect.top + ts);
            int y2 = (int) (rect.bottom - bs);
            // 创建.9缩放对象
            ninePatch = ShadowHelper.createNinePatch(bitmap, x1, x2, y1, y2);
        }
        drawRect = new Rect();
    }

    @Override
    protected void onDestroy() {
        synchronized (this) {
            if (null != bitmap) {
                if (!bitmap.isRecycled()) {
                    bitmap.recycle();
                }
                bitmap = null;
            }
            ninePatch = null;
        }
    }

    @Override
    public void draw(Canvas canvas, Rect rect, Paint paint) {
        synchronized (this) {
            // 外部传来的矩形对应阴影的矩形，因此实际绘制的位置应该加上阴影半径
            if (null != ninePatch && null != bitmap && !bitmap.isRecycled()) {
                drawRect.left = (int) (rect.left - this.rect.left);
                drawRect.top = (int) (rect.top - this.rect.top);
                drawRect.right = (int) (rect.right + (bitmap.getWidth() - this.rect.right));
                drawRect.bottom = (int) (rect.bottom + (bitmap.getHeight() - this.rect.bottom));
                ninePatch.draw(canvas, drawRect, paint);
            }
        }
    }

    @Override
    public Key getKey() {
        return (Key) super.getKey();
    }

    @Override
    protected void finalize() throws Throwable {
        super.finalize();
        onDestroy();
    }

    /**
     * 圆角矩形阴影的key，可以用来创建阴影对象和比较阴影对象是否一样
     */
    public static class Key implements Serializable, Cloneable {

        public int shadowColor;
        public float shadowRadius;
        public int solidColor;
        public float[] radii;
        public boolean noSolid;

        /**
         * 克隆此对象
         *
         * @return 此对象副本
         */
        @NonNull
        @Override
        public Key clone() {
            try {
                return (Key) super.clone();
            } catch (CloneNotSupportedException e) {
                throw new RuntimeException(e);
            }
        }

        @Override
        public int hashCode() {
            return shadowColor + solidColor +
                    Float.floatToIntBits(shadowRadius) +
                    Arrays.hashCode(radii) +
                    (noSolid ? 1 : 0);
        }

        @Override
        public boolean equals(Object obj) {
            if (obj == this) return true;
            if (obj instanceof Key) {
                Key other = (Key) obj;
                return shadowColor == other.shadowColor &&
                        shadowRadius == other.shadowRadius &&
                        solidColor == other.solidColor &&
                        Arrays.equals(radii, other.radii) &&
                        noSolid == other.noSolid;
            }
            return false;
        }

        /**
         * 检查阴影参数是否有效
         */
        public void check() {
            if (null != radii && radii.length != 8) {
                throw new IllegalArgumentException("radii must be null or length is 8!");
            }
            if (null != radii) {
                for (float v : radii) {
                    if (v < 0f) {
                        throw new IllegalArgumentException("Invalid radii value:" + v);
                    }
                }
            }
            if (shadowRadius <= 0) {
                throw new IllegalArgumentException("shadowRadius must more than 0!");
            }
            int alpha = Color.alpha(solidColor);
            if (alpha != 0xFF) {
                throw new IllegalArgumentException("solidColor has alpha!");
            }
        }

        /**
         * 判断是否含有圆角
         *
         * @return true，含有圆角
         */
        public boolean hasRound() {
            if (null != radii) {
                for (float v : radii) {
                    if (v > 0f) {
                        return true;
                    }
                }
            }
            return false;
        }
    }
}
