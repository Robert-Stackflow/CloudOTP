package com.cloudchewie.util.view;

import android.view.MotionEvent;
import android.view.View;
import android.view.ViewGroup;

/**
 * 拦截滑动辅助器（用于{@link ViewGroup#onInterceptTouchEvent(MotionEvent) ViewGroup.onInterceptTouchEvent}）
 * <br>使用方法：<br>
 * public boolean onInterceptTouchEvent(MotionEvent ev)&nbsp;{<br>
 * &nbsp;&nbsp;&nbsp;&nbsp;boolean result = super.onInterceptTouchEvent(ev);<br>
 * &nbsp;&nbsp;&nbsp;&nbsp;boolean ext = interceptTouchHelper.onInterceptTouchEvent(ev);<br>
 * &nbsp;&nbsp;&nbsp;&nbsp;return result && ext;<br>
 * }
 */
public class InterceptTouchHelper {

    private ViewGroup parent;
    private GestureHelper gestureHelper;

    public InterceptTouchHelper(ViewGroup parent, GestureHelper gestureHelper) {
        this.parent = parent;
        this.gestureHelper = gestureHelper;
    }

    public InterceptTouchHelper(ViewGroup parent) {
        this(parent, GestureHelper.createDefault(parent.getContext()));
    }

    /**
     * 判定是否拦截触摸事件
     *
     * @param event 触摸事件
     * @return true，拦截
     */
    public boolean onInterceptTouchEvent(MotionEvent event) {
        gestureHelper.onTouchEvent(event);
        switch (gestureHelper.getGesture()) {
            case GestureHelper.GESTURE_LEFT:
                return !canChildrenScrollHorizontally(event, 1)
                        && canParentScrollHorizontally(parent, 1);
            case GestureHelper.GESTURE_RIGHT:
                return !canChildrenScrollHorizontally(event, -1)
                        && canParentScrollHorizontally(parent, -1);
            case GestureHelper.GESTURE_UP:
                return !canChildrenScrollVertically(event, 1)
                        && canParentScrollVertically(parent, 1);
            case GestureHelper.GESTURE_DOWN:
                return !canChildrenScrollVertically(event, -1)
                        && canParentScrollVertically(parent, -1);
        }
        return false;
    }

    /**
     * 判断子视图是否可以垂直滑动
     *
     * @param event     滑动事件
     * @param direction 方向：负数表示ScrollY值变小的方向；整数表示ScrollY值变大的方向
     * @return true，子View可以滑动
     */
    protected boolean canChildrenScrollVertically(MotionEvent event, int direction) {
        for (int i = 0; i < parent.getChildCount(); i++) {
            int index = parent.getChildCount() - 1 - i;
            View child = parent.getChildAt(index);
            if (child.getVisibility() == View.VISIBLE && child.isEnabled()) {
                float x = event.getX();
                float y = event.getY();
                if (x >= child.getLeft() && x <= child.getRight() &&
                        y >= child.getTop() && y <= child.getBottom()) {
                    if (canChildScrollVertically(child, direction)) {
                        return true;
                    }
                }
            }
        }
        return false;
    }

    /**
     * 判断子View是否可以垂直滑动
     *
     * @param child     子View
     * @param direction 方向：负数表示ScrollY值变小的方向；整数表示ScrollY值变大的方向
     * @return true，可以滑动
     */
    protected boolean canChildScrollVertically(View child, int direction) {
        return child.canScrollVertically(direction);
    }

    /**
     * 判断子视图是否可以水平滑动
     *
     * @param event     滑动事件
     * @param direction 方向：负数表示ScrollX值变小的方向；整数表示ScrollX值变大的方向
     * @return true，子View可以滑动
     */
    protected boolean canChildrenScrollHorizontally(MotionEvent event, int direction) {
        for (int i = 0; i < parent.getChildCount(); i++) {
            int index = parent.getChildCount() - 1 - i;
            View child = parent.getChildAt(index);
            if (child.getVisibility() == View.VISIBLE && child.isEnabled()) {
                float x = event.getX();
                float y = event.getY();
                if (x >= child.getLeft() && x <= child.getRight() &&
                        y >= child.getTop() && y <= child.getBottom()) {
                    if (canChildScrollHorizontally(child, direction)) {
                        return true;
                    }
                }
            }
        }
        return false;
    }

    /**
     * 判断子View是否可以水平滑动
     *
     * @param child     子View
     * @param direction 方向：负数表示ScrollX值变小的方向；整数表示ScrollX值变大的方向
     * @return true，可以滑动
     */
    protected boolean canChildScrollHorizontally(View child, int direction) {
        return child.canScrollHorizontally(direction);
    }

    /**
     * 判断父视图是否可以水平滑动
     *
     * @param parent    父视图
     * @param direction 方向
     * @return true，可以水平滑动
     */
    protected boolean canParentScrollHorizontally(ViewGroup parent, int direction) {
        return parent.canScrollHorizontally(direction);
    }

    /**
     * 判断父视图是否可以垂直滑动
     *
     * @param parent    父视图
     * @param direction 方向
     * @return true，可以水平滑动
     */
    protected boolean canParentScrollVertically(ViewGroup parent, int direction) {
        return parent.canScrollVertically(direction);
    }
}
