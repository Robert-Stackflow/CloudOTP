package com.cloudchewie.ui.shadow;

import android.content.Context;
import android.content.res.TypedArray;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Rect;
import android.util.AttributeSet;
import android.view.Gravity;
import android.view.View;
import android.view.ViewGroup;
import android.widget.FrameLayout;

import com.cloudchewie.ui.R;
import com.cloudchewie.util.view.MeasureUtils;

/**
 * 阴影布局，其子视图可以设置阴影
 */
public class ShadowLayout extends FrameLayout {

    private Rect layoutContainer = new Rect();
    private Rect layoutOut = new Rect();
    private ShadowHelper shadowHelper = new ShadowHelper();

    public ShadowLayout(Context context) {
        super(context);
    }

    public ShadowLayout(Context context, AttributeSet attrs) {
        super(context, attrs);
    }

    public ShadowLayout(Context context, AttributeSet attrs, int defStyleAttr) {
        super(context, attrs, defStyleAttr);
    }

    @Override
    protected void onDetachedFromWindow() {
        super.onDetachedFromWindow();
        for (int i = 0; i < getChildCount(); i++) {
            View child = getChildAt(i);
            clearChildShadow(child);
        }
    }

    @Override
    public LayoutParams generateLayoutParams(AttributeSet attrs) {
        return new LayoutParams(getContext(), attrs);
    }

    @Override
    protected LayoutParams generateLayoutParams(ViewGroup.LayoutParams lp) {
        return new LayoutParams(lp);
    }

    @Override
    protected FrameLayout.LayoutParams generateDefaultLayoutParams() {
        return new LayoutParams(LayoutParams.WRAP_CONTENT, LayoutParams.WRAP_CONTENT);
    }

    @Override
    protected void onMeasure(int widthMeasureSpec, int heightMeasureSpec) {
        int paddingWidth = getPaddingLeft() + getPaddingRight();
        int paddingHeight = getPaddingTop() + getPaddingBottom();
        int cws = MeasureUtils.makeSelfMeasureSpec(widthMeasureSpec, paddingWidth);
        int chs = MeasureUtils.makeSelfMeasureSpec(heightMeasureSpec, paddingHeight);
        int contentWidth = 0;
        int contentHeight = 0;
        for (int i = 0; i < getChildCount(); i++) {
            View child = getChildAt(i);
            if (child.getVisibility() == GONE) continue;
            LayoutParams lp = (LayoutParams) child.getLayoutParams();
            float shadowRadius = lp.spaceShadow ? lp.shadowKey.shadowRadius : 0f;
            int hmar = (int) (lp.leftMargin + lp.rightMargin + shadowRadius * 2);
            int vmar = (int) (lp.topMargin + lp.bottomMargin + shadowRadius * 2);
            int ws = MeasureUtils.makeChildMeasureSpec(cws, lp.width, hmar);
            int hs = MeasureUtils.makeChildMeasureSpec(chs, lp.height, vmar);
            child.measure(ws, hs);
            int width = child.getMeasuredWidth() + hmar;
            int height = child.getMeasuredHeight() + vmar;
            if (width > contentWidth) contentWidth = width;
            if (height > contentHeight) contentHeight = height;
            Object key = lp.getShadowKey(isInEditMode());
            if (null == lp.shadow) {
                // lp.shadow = ShadowHelper.createShadow(lp.shadowKey);
                lp.shadow = ShadowHelper.getShadow(key);
            } else if (!key.equals(lp.shadow.getKey())) {
                // ShadowManager.getDefault().unbind(lp.shadow);
                // lp.shadow = ShadowHelper.createShadow(lp.shadowKey);
                lp.shadow = ShadowHelper.getShadow(key);
            }
        }
        int width = MeasureUtils.getMeasuredDimension(contentWidth, widthMeasureSpec);
        int height = MeasureUtils.getMeasuredDimension(contentHeight, heightMeasureSpec);
        setMeasuredDimension(width, height);
        layoutContainer.set(0, 0, width, height);
    }

    @Override
    protected void onLayout(boolean changed, int left, int top, int right, int bottom) {
        for (int i = 0; i < getChildCount(); i++) {
            View child = getChildAt(i);
            if (child.getVisibility() == GONE) continue;
            LayoutParams lp = (LayoutParams) child.getLayoutParams();
            float shadowRadius = 0f, shadowX = 0f, shadowY = 0f;
            if (lp.spaceShadow) {
                shadowRadius = lp.shadowKey.shadowRadius;
                shadowX = lp.shadowX;
                shadowY = lp.shadowY;
            }
            int gravity = lp.gravity == Gravity.NO_GRAVITY ? Gravity.START | Gravity.TOP : lp.gravity;
            int width = (int) (child.getMeasuredWidth() + lp.leftMargin +
                    lp.rightMargin + shadowRadius * 2);
            int height = (int) (child.getMeasuredHeight() + lp.topMargin +
                    lp.bottomMargin + shadowRadius * 2);
            Gravity.apply(gravity, width, height, layoutContainer, layoutOut);
            int cl = (int) (layoutOut.left + lp.leftMargin + shadowRadius + shadowX);
            int ct = (int) (layoutOut.top + lp.topMargin + shadowRadius + shadowY);
            int cr = cl + child.getMeasuredWidth();
            int cb = ct + child.getMeasuredHeight();
            child.layout(cl, ct, cr, cb);
        }
    }

    @Override
    protected boolean drawChild(Canvas canvas, View child, long drawingTime) {
        if (child.getVisibility() == VISIBLE) {
            LayoutParams lp = (LayoutParams) child.getLayoutParams();
            if (null != lp.shadow) {
                shadowHelper.drawChildShadow(canvas, child, lp.shadow, lp.shadowX, lp.shadowY);
            }
        }
        return super.drawChild(canvas, child, drawingTime);
    }

    @Override
    public void onViewRemoved(View child) {
        super.onViewRemoved(child);
        clearChildShadow(child);
    }

    private void clearChildShadow(View child) {
        LayoutParams lp = (LayoutParams) child.getLayoutParams();
        if (null != lp && null != lp.shadow) {
            // ShadowManager.getDefault().unbind(lp.shadow);
            lp.shadow = null;
        }
    }

    public static class LayoutParams extends FrameLayout.LayoutParams {

        /**
         * 阴影信息
         */
        private final RoundShadow.Key shadowKey = new RoundShadow.Key();
        /**
         * 阴影X轴偏移量
         */
        public float shadowX;
        /**
         * 阴影Y轴偏移量
         */
        public float shadowY;
        /**
         * 设置阴影是否影响视图位置，默认开启
         */
        public boolean spaceShadow = true;
        UnsupportedRoundShadow.Key editModeShadowKey;
        Shadow shadow;

        public LayoutParams(Context c, AttributeSet attrs) {
            super(c, attrs);
            TypedArray ta = c.obtainStyledAttributes(attrs, R.styleable.ShadowLayout_Layout);
            shadowX = ta.getDimension(R.styleable.ShadowLayout_Layout_layout_shadowX, 0f);
            shadowY = ta.getDimension(R.styleable.ShadowLayout_Layout_layout_shadowY, 0f);
            shadowKey.shadowRadius = ta.getDimension(R.styleable.ShadowLayout_Layout_layout_shadowRadius, 0f);
            shadowKey.shadowColor = ta.getColor(R.styleable.ShadowLayout_Layout_layout_shadowColor, Color.BLACK);
            float round = ta.getDimension(R.styleable.ShadowLayout_Layout_layout_roundRadius, 0f);
            float roundLT = ta.getDimension(R.styleable.ShadowLayout_Layout_layout_roundRadiusLT, round);
            float roundRT = ta.getDimension(R.styleable.ShadowLayout_Layout_layout_roundRadiusRT, round);
            float roundRB = ta.getDimension(R.styleable.ShadowLayout_Layout_layout_roundRadiusRB, round);
            float roundLB = ta.getDimension(R.styleable.ShadowLayout_Layout_layout_roundRadiusLB, round);
            if (roundLT > 0 || roundRT > 0 || roundRB > 0 || roundLB > 0) {
                shadowKey.radii = new float[]{
                        roundLT, roundLT,
                        roundRT, roundRT,
                        roundRB, roundRB,
                        roundLB, roundLB,
                };
            } else {
                shadowKey.radii = null;
            }
            shadowKey.solidColor = ta.getColor(R.styleable.ShadowLayout_Layout_layout_solidColor, Color.BLACK);
            spaceShadow = ta.getBoolean(R.styleable.ShadowLayout_Layout_layout_spaceShadow, true);
            shadowKey.noSolid = ta.getBoolean(R.styleable.ShadowLayout_Layout_layout_noSolid, false);
            ta.recycle();
        }

        public LayoutParams(int width, int height) {
            super(width, height);
        }

        public LayoutParams(int width, int height, int gravity) {
            super(width, height, gravity);
        }

        public LayoutParams(ViewGroup.LayoutParams source) {
            super(source);
        }

        public LayoutParams(ViewGroup.MarginLayoutParams source) {
            super(source);
        }

        public LayoutParams(FrameLayout.LayoutParams source) {
            super(source);
        }


        public RoundShadow.Key getShadowKey() {
            return shadowKey;
        }

        Object getShadowKey(boolean editMode) {
            if (editMode) {
                if (null == editModeShadowKey)
                    editModeShadowKey = new UnsupportedRoundShadow.Key();
                editModeShadowKey.set(shadowKey);
                return editModeShadowKey;
            }
            return shadowKey;
        }
    }

}
