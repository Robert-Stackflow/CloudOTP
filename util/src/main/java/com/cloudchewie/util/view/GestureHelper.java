package com.cloudchewie.util.view;

import android.content.Context;
import android.util.TypedValue;
import android.view.MotionEvent;

/**
 * 手势辅助器
 */
public class GestureHelper {

    /**
     * 无手势，还不能确定手势
     */
    public static final int GESTURE_NONE = 0;
    /**
     * 手势：按住
     */
    public static final int GESTURE_PRESSED = 1;
    /**
     * 手势：点击
     */
    public static final int GESTURE_CLICK = 2;
    /**
     * 手势：长按
     */
    public static final int GESTURE_LONG_CLICK = 3;
    /**
     * 手势：左滑
     */
    public static final int GESTURE_LEFT = 4;
    /**
     * 手势：上滑
     */
    public static final int GESTURE_UP = 5;
    /**
     * 手势：右滑
     */
    public static final int GESTURE_RIGHT = 6;
    /**
     * 手势：下滑
     */
    public static final int GESTURE_DOWN = 7;

    /**
     * 默认的点大小，单位：dip
     */
    public static final float DEFAULT_FONT_SIZE_DP = 5;
    /**
     * 默认的长按时间
     */
    public static final int DEFAULT_LONG_CLICK_TIME = 800;

    private float pointSize; // 点的大小
    private int longClickTime; // 长按判定时间
    private float xyScale;

    private int gesture = GESTURE_NONE; // 手势
    private long downTime;
    private float downX = 0f;
    private float downY = 0f;
    private float preX = 0f;
    private float preY = 0f;

    /**
     * 创建一个手势帮助器
     *
     * @param pointSize     点的大小，超出此大小的滑动手势会被判定为非点击手势
     * @param longClickTime 长按点击时间，超过或等于此时间的按住手势算长按点击事件
     * @param xyScale       X轴与Y轴比例，影响方向手势的判定，默认是1；
     *                      越小，手势判定越偏重于水平方向；
     *                      越大，手势判定偏重于垂直方向；
     *                      1，不偏重任何方向；
     *                      如果是专注于水平方向，可以将此值设置小于1的数，
     *                      如果是专注于垂直方向，可以将此值设置大于1的数；
     *                      如果是垂直与水平同等重要，将此值设置成1
     */
    public GestureHelper(float pointSize, int longClickTime, float xyScale) {
        if (pointSize <= 0) {
            throw new IllegalArgumentException("Illegal:pointSize <= 0");
        }
        if (longClickTime <= 0) {
            throw new IllegalArgumentException("Illegal:longClickTime <= 0");
        }
        if (xyScale == 0) {
            throw new IllegalArgumentException("Illegal:xyScale equals 0");
        }
        this.pointSize = pointSize;
        this.longClickTime = longClickTime;
        this.xyScale = xyScale;
    }

    /**
     * 创建默认的手势辅助器
     *
     * @param context 上下文对象
     * @return 手势器
     */
    public static GestureHelper createDefault(Context context) {
        float pointSize = TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP,
                DEFAULT_FONT_SIZE_DP, context.getResources().getDisplayMetrics());
        return new GestureHelper(pointSize, DEFAULT_LONG_CLICK_TIME, 1f);
    }

    /**
     * 触发触摸滑动事件
     *
     * @param event 事件
     */
    public void onTouchEvent(MotionEvent event) {
//        System.out.println("onTouchEvent:action=" + event.getAction());
        switch (event.getAction()) {
            case MotionEvent.ACTION_DOWN: // 按下
                touchDown(event);
                break;
            case MotionEvent.ACTION_MOVE: // 移动
                touchMove(event);
                break;
            case MotionEvent.ACTION_CANCEL: // 取消
            case MotionEvent.ACTION_UP: // 抬起
                touchFinish(event);
                break;
        }
//        System.out.println("onTouchEvent:" + gesture);
    }

    /**
     * 获取手势
     *
     * @return 手势
     */
    public int getGesture() {
        return gesture;
    }

    /**
     * 判定是否为水平滑动手势
     *
     * @return true，水平滑动手势
     */
    public boolean isHorizontalGesture() {
        return gesture == GESTURE_LEFT || gesture == GESTURE_RIGHT;
    }

    /**
     * 判定是否为垂直滑动手势
     *
     * @return true，垂直滑动手势
     */
    public boolean isVerticalGesture() {
        return gesture == GESTURE_UP || gesture == GESTURE_DOWN;
    }

    private void touchDown(MotionEvent event) {
        downTime = System.currentTimeMillis();
        downX = preX = event.getRawX();
        downY = preY = event.getRawY();
        gesture = GESTURE_PRESSED;
    }

    private void touchMove(MotionEvent event) {
        float rangeX = event.getRawX() - downX;
        float rangeY = event.getRawY() - downY;
//        System.out.println(String.format("touchMove:rangeX=%f,rangeY=%f,pointSize=%f",
//                rangeX, rangeY, pointSize));
        if (gesture == GESTURE_NONE || gesture == GESTURE_PRESSED) { // 未确定手势或正在长按
            if (Math.abs(rangeX) > pointSize || Math.abs(rangeY) > pointSize) {
                // 超出点的范围，不算点击、按住手势，应该是滑动手势
                float ox = event.getRawX() - preX;
                float oy = event.getRawY() - preY;
                if (Math.abs(ox) > xyScale * Math.abs(oy)) {
                    // 水平方向滑动
                    if (ox < 0) {
                        gesture = GESTURE_LEFT;
                    } else {
                        gesture = GESTURE_RIGHT;
                    }
                } else {
                    // 垂直方向滑动
                    if (oy < 0) {
                        gesture = GESTURE_UP;
                    } else {
                        gesture = GESTURE_DOWN;
                    }
                }
            } else {
                gesture = GESTURE_PRESSED; // 按住手势
            }
        }
        if (gesture == GESTURE_PRESSED) { // 按住中
            if (System.currentTimeMillis() - downTime >= longClickTime) { // 按住超过长按时间，算长按时间
                gesture = GESTURE_LONG_CLICK;
            }
        }
        preX = event.getRawX();
        preY = event.getRawY();
    }

    private void touchFinish(MotionEvent event) {
        if (gesture == GESTURE_PRESSED) { // 按住到释放，应该算点击手势
            if (System.currentTimeMillis() - downTime >= longClickTime) { // 按住超过长按时间，算长按时间
                gesture = GESTURE_LONG_CLICK;
            } else {
                gesture = GESTURE_CLICK;
            }
        }
    }
}
