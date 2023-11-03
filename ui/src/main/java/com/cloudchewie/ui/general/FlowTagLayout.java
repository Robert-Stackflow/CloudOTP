/*
 * Project Name: Worthy
 * Author: Ruida
 * Last Modified: 2022/12/17 21:42:08
 * Copyright(c) 2022 Ruida https://cloudchewie.com
 */

package com.cloudchewie.ui.general;

import android.annotation.SuppressLint;
import android.content.Context;
import android.content.res.TypedArray;
import android.text.TextUtils;
import android.util.AttributeSet;
import android.util.Log;
import android.view.View;
import android.view.ViewGroup;

import com.cloudchewie.ui.R;

import java.util.ArrayList;
import java.util.List;

public class FlowTagLayout extends ViewGroup {

    private final List<List<View>> mChildViews;
    private final List<Integer> mLinesHeight;
    private int mHorizontalDiver, mVerticalDiver;

    public FlowTagLayout(Context context) {
        this(context, null);
    }

    public FlowTagLayout(Context context, AttributeSet attrs) {
        this(context, attrs, 0);
    }

    public FlowTagLayout(Context context, AttributeSet attrs, int defStyleAttr) {
        super(context, attrs, defStyleAttr);

        mChildViews = new ArrayList<>();
        mLinesHeight = new ArrayList<>();

        TypedArray a = context.getTheme().obtainStyledAttributes(attrs, R.styleable.FlowTagLayout, defStyleAttr, 0);
        int count = a.getIndexCount();
        for (int i = 0; i < count; i++) {
            int index = a.getIndex(i);
            if (index == R.styleable.FlowTagLayout_horizontal_diver) {
                mHorizontalDiver = (int) a.getDimension(i, 0);
            } else if (index == R.styleable.FlowTagLayout_vertical_diver) {
                mVerticalDiver = (int) a.getDimension(i, 0);
            }
        }
        a.recycle();
    }

    //只需要计算AT_MOST模式下的宽高；如果是EXACTLY模式，则直接根据ViewParent传进来的值进行设置就好
    @Override
    protected void onMeasure(int widthMeasureSpec, int heightMeasureSpec) {

        int widthMode = MeasureSpec.getMode(widthMeasureSpec);
        int widthSize = MeasureSpec.getSize(widthMeasureSpec);
        int heightMode = MeasureSpec.getMode(heightMeasureSpec);
        int heightSize = MeasureSpec.getSize(heightMeasureSpec);

        mChildViews.clear();
        mLinesHeight.clear();

        //AT_MOST模式下计算出来的宽和高
        int atmostWidth = 0, atmostHeight = 0;
        int lineWidth = 0, lineHeight = 0;
        @SuppressLint("DrawAllocation")
        List<View> lineChilds = new ArrayList<>();

        int childCount = getChildCount();
        for (int i = 0; i < childCount; i++) {

            View child = getChildAt(i);
            measureChild(child, widthMeasureSpec, heightMeasureSpec);
            int childWidth = child.getMeasuredWidth() + mHorizontalDiver;
            int childHeight = child.getMeasuredHeight() + mVerticalDiver;
            if (lineWidth + childWidth < widthSize) {

                //如果不需要换行,则直接将该child的宽度累加到改行的宽度中
                lineWidth += childWidth;
                //以高度最大的child的高度作为本行的高度
                lineHeight = Math.max(lineHeight, childHeight);
                lineChilds.add(child);
            } else {

                //如果需要换行，则计算出上一行的宽度跟上一行之前的宽度的较大值
                atmostWidth = Math.max(atmostWidth, lineWidth);
                //保存新行的第一个child的宽度
                lineWidth = childWidth;
                //叠加上一行的高度
                atmostHeight += lineHeight;
                //保存上一行的高度
                mLinesHeight.add(lineHeight);
                //保存上一行的所有child
                mChildViews.add(lineChilds);
                //新起一行
                lineChilds = new ArrayList<>();
                //保存新行的第一个child
                lineChilds.add(child);
            }
            //处理最后一个
            if (i == childCount - 1) {
                atmostWidth = Math.max(atmostWidth, lineWidth);
                atmostHeight += lineHeight;
                mLinesHeight.add(lineHeight);
                mChildViews.add(lineChilds);
            }
        }
        int finalWidth = widthMode == MeasureSpec.EXACTLY ? widthSize : atmostWidth;
        int finalHeight = heightMode == MeasureSpec.EXACTLY ? heightSize : atmostHeight;

        v(String.format("width=%s,height=%s", finalWidth, finalHeight));

        setMeasuredDimension(finalWidth, finalHeight);
    }

    @Override
    protected void onLayout(boolean changed, int l, int t, int r, int b) {

        int left = 0, top = 0;

        int lineCount = mChildViews.size();
        for (int i = 0; i < lineCount; i++) {

            List<View> childs = mChildViews.get(i);
            int childCount = childs.size();
            for (int j = 0; j < childCount; j++) {

                View child = childs.get(j);
                int childWidth = child.getMeasuredWidth();
                int childHeight = child.getMeasuredHeight();
                child.layout(left + mHorizontalDiver,
                        top + mVerticalDiver,
                        left + mHorizontalDiver + childWidth,
                        top + mVerticalDiver + childHeight);
                left += mHorizontalDiver + childWidth;
            }
            //重置left到最左
            left = 0;
            //累加每行的高度，不能重置
            top += mLinesHeight.get(i);
        }
    }

    protected void v(String msg) {
        if (!TextUtils.isEmpty(msg)) {
            Log.v(getClass().getCanonicalName(), msg);
        }
    }
}
