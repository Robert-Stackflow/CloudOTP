package com.cloudchewie.util.view;

import android.graphics.Rect;
import android.view.View;
import android.view.ViewGroup;

/**
 * 测量工具
 */
public final class MeasureUtils {

    private MeasureUtils() {
    }

    /**
     * 制作属于自己的测量规格，用于测量子视图在{@link ViewGroup#onMeasure(int, int) ViewGroup.onMeasure}
     * 中使用，得出一个自身测量规格，然后使用{@link #makeChildMeasureSpec(int, int, int) makeChildMeasureSpec}
     * 测量子视图规格
     *
     * @param parentMeasureSpec 父测量规格
     * @param padding           内间距
     * @return 自身测量规格
     */
    public static int makeSelfMeasureSpec(int parentMeasureSpec, int padding) {
        int mode = View.MeasureSpec.getMode(parentMeasureSpec);
        int size = View.MeasureSpec.getSize(parentMeasureSpec);
        size = Math.max(0, size - padding);
        return View.MeasureSpec.makeMeasureSpec(size, mode);
    }

    /**
     * 制作子测量规格
     *
     * @param parentMeasureSpec 父测量规格
     * @param layoutParamSize   LayoutParams的大小
     * @param margin            外边距
     * @return 子的测量规格
     */
    public static int makeChildMeasureSpec(int parentMeasureSpec, int layoutParamSize, int margin) {
        int size = View.MeasureSpec.getSize(parentMeasureSpec); // 获取父视图最大大小
        size = Math.max(size - margin, 0);
        if (layoutParamSize == ViewGroup.LayoutParams.MATCH_PARENT) { // 占满父视图
            // 返回固定大小的测量规格
            return View.MeasureSpec.makeMeasureSpec(size, View.MeasureSpec.EXACTLY);

        } else if (layoutParamSize == ViewGroup.LayoutParams.WRAP_CONTENT) { // 自适应大小
            int mode = View.MeasureSpec.getMode(parentMeasureSpec); // 父视图测量模式
            if (mode == View.MeasureSpec.EXACTLY || mode == View.MeasureSpec.AT_MOST) {
                // 父视图有固定大小或有最大大小
                // 返回有最大大小限制的测量规格
                return View.MeasureSpec.makeMeasureSpec(size, View.MeasureSpec.AT_MOST);
            } else { // 父视图可以无限大
                // 子视图也一样，可以无限大，返回无限大测量规格
                return View.MeasureSpec.makeMeasureSpec(size, View.MeasureSpec.UNSPECIFIED);
            }

        } else { // 子视图固定大小
            // 返回固定大小的测量规格
            return View.MeasureSpec.makeMeasureSpec(layoutParamSize, View.MeasureSpec.EXACTLY);
        }
    }

    /**
     * 测量子视图
     *
     * @param child                   子视图
     * @param parentWidthMeasureSpec  父视图宽测量规格
     * @param parentHeightMeasureSpec 父视图高测量规格
     */
    public static void measureChild(View child, int parentWidthMeasureSpec, int parentHeightMeasureSpec) {
        int horizontalMargin = 0;
        int verticalMargin = 0;
        ViewGroup.LayoutParams lp = child.getLayoutParams();
        if (lp instanceof ViewGroup.MarginLayoutParams) {
            horizontalMargin = ((ViewGroup.MarginLayoutParams) lp).leftMargin +
                    ((ViewGroup.MarginLayoutParams) lp).rightMargin;
            verticalMargin = ((ViewGroup.MarginLayoutParams) lp).topMargin +
                    ((ViewGroup.MarginLayoutParams) lp).bottomMargin;
        }
        int childWidthMeasureSpec =
                makeChildMeasureSpec(parentWidthMeasureSpec, lp.width, horizontalMargin);
        int childHeightMeasureSpec =
                makeChildMeasureSpec(parentHeightMeasureSpec, lp.height, verticalMargin);
        child.measure(childWidthMeasureSpec, childHeightMeasureSpec);
    }

    /**
     * 获取测量的尺寸
     *
     * @param contentSize       内容大小（保护padding）
     * @param parentMeasureSpec 父视图测量规格
     * @return 测量的尺寸，用于{@link ViewGroup#setMeasuredDimension(int, int) ViewGroup.setMeasuredDimension}
     */
    public static int getMeasuredDimension(int contentSize, int parentMeasureSpec) {
        int mode = View.MeasureSpec.getMode(parentMeasureSpec);
        int size = View.MeasureSpec.getSize(parentMeasureSpec);
        if (mode == View.MeasureSpec.AT_MOST) {
            return Math.min(size, contentSize);
        } else if (mode == View.MeasureSpec.EXACTLY) {
            return size;
        } else {
            return contentSize;
        }
    }

    /**
     * 计算视图占用的宽度
     *
     * @param view 视图
     * @return 视图占用的宽度
     */
    public static int getViewWidthSpace(View view) {
        int width = view.getMeasuredWidth();
        ViewGroup.LayoutParams lp = view.getLayoutParams();
        if (lp instanceof ViewGroup.MarginLayoutParams) {
            width += ((ViewGroup.MarginLayoutParams) lp).leftMargin +
                    ((ViewGroup.MarginLayoutParams) lp).rightMargin;
        }
        return width;
    }

    /**
     * 计算视图占用的高度
     *
     * @param view 视图占用的高度
     * @return 视图占用的高度
     */
    public static int getViewHeightSpace(View view) {
        int height = view.getMeasuredHeight();
        ViewGroup.LayoutParams lp = view.getLayoutParams();
        if (lp instanceof ViewGroup.MarginLayoutParams) {
            height += ((ViewGroup.MarginLayoutParams) lp).topMargin +
                    ((ViewGroup.MarginLayoutParams) lp).bottomMargin;
        }
        return height;
    }

    /**
     * 计算布局所需的值
     *
     * @param view      视图
     * @param layoutX   布局的位置X
     * @param layoutY   布局的位置Y
     * @param layoutOut 返回布局的位置
     * @param spaceOut  返回占用的位置
     */
    public static void computeLayout(View view, int layoutX, int layoutY, Rect layoutOut, Rect spaceOut) {
        ViewGroup.LayoutParams lp = view.getLayoutParams();
        spaceOut.left = layoutX;
        spaceOut.top = layoutY;
        if (lp instanceof ViewGroup.MarginLayoutParams) {
            layoutOut.left = layoutX + ((ViewGroup.MarginLayoutParams) lp).leftMargin;
            layoutOut.top = layoutY + ((ViewGroup.MarginLayoutParams) lp).topMargin;
            layoutOut.right = layoutOut.left + view.getMeasuredWidth();
            layoutOut.bottom = layoutOut.top + view.getMeasuredHeight();
            spaceOut.right = layoutOut.right + ((ViewGroup.MarginLayoutParams) lp).rightMargin;
            spaceOut.bottom = layoutOut.bottom + ((ViewGroup.MarginLayoutParams) lp).bottomMargin;
        } else {
            layoutOut.left = layoutX;
            layoutOut.top = layoutY;
            layoutOut.right = layoutOut.left + view.getMeasuredWidth();
            layoutOut.bottom = layoutOut.top + view.getMeasuredHeight();
            spaceOut.right = layoutOut.right;
            spaceOut.bottom = layoutOut.bottom;
        }
    }
}
