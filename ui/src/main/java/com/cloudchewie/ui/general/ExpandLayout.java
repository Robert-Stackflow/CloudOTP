package com.cloudchewie.ui.general;

import android.animation.ValueAnimator;
import android.content.Context;
import android.util.AttributeSet;
import android.view.View;
import android.view.ViewGroup;
import android.widget.RelativeLayout;

import androidx.annotation.NonNull;

public class ExpandLayout extends RelativeLayout {

    private View layoutView;
    private int viewHeight;
    private boolean isExpand;
    private long animationDuration;
    private boolean lock;
    private int collapseHeight = 1;
    private OnStateChangedListener onStateChangedListener;

    public ExpandLayout(Context context) {
        this(context, null);
    }

    public ExpandLayout(Context context, AttributeSet attrs) {
        this(context, attrs, 0);
    }

    public ExpandLayout(Context context, AttributeSet attrs, int defStyle) {
        super(context, attrs, defStyle);
        initView();
    }

    public static void setViewHeight(@NonNull View view, int height) {
        final ViewGroup.LayoutParams params = view.getLayoutParams();
        params.height = height;
        view.requestLayout();
    }

    public void setOnStateChangedListener(OnStateChangedListener onStateChangedListener) {
        this.onStateChangedListener = onStateChangedListener;
    }

    private void initView() {
        layoutView = this;
        isExpand = true;
        animationDuration = 300;
        setViewDimensions();
    }

    /**
     * @param isExpand 初始状态是否折叠
     */
    public void initExpand(boolean isExpand) {
        this.isExpand = isExpand;
        setViewDimensions();
    }

    /**
     * 设置动画时间
     *
     * @param animationDuration 动画时间
     */
    public void setAnimationDuration(long animationDuration) {
        this.animationDuration = animationDuration;
    }

    /**
     * 获取subView的总高度
     * View.post()的runnable对象中的方法会在View的measure、layout等事件后触发
     */
    public void setViewDimensions() {
        layoutView.post(() -> {
//            if (viewHeight <= collapseHeight) {
            viewHeight = layoutView.getMeasuredHeight();
//            }
            setViewHeight(layoutView, isExpand ? viewHeight : collapseHeight);
        });
    }

    /**
     * 切换动画实现
     */
    private void animateToggle(long animationDuration) {
        ValueAnimator heightAnimation = isExpand ? ValueAnimator.ofFloat(collapseHeight, viewHeight) : ValueAnimator.ofFloat(viewHeight, collapseHeight);
        heightAnimation.setDuration(animationDuration / 2);
        heightAnimation.setStartDelay(animationDuration / 2);
        heightAnimation.addUpdateListener(animation -> {
            int value = (int) (float) animation.getAnimatedValue();
            setViewHeight(layoutView, value);
            if (value == viewHeight || value == collapseHeight) {
                lock = false;
            }
        });

        heightAnimation.start();
        lock = true;
    }

    public boolean isExpand() {
        return isExpand;
    }

    /**
     * 折叠view
     */
    public void collapse() {
        if (isExpand) {
            isExpand = false;
            if (onStateChangedListener != null)
                onStateChangedListener.OnStateChanged(isExpand);
            animateToggle(animationDuration);
        }
    }

    /**
     * 展开view
     */
    public void expand() {
        if (!isExpand) {
            isExpand = true;
            if (onStateChangedListener != null)
                onStateChangedListener.OnStateChanged(isExpand);
            animateToggle(animationDuration);
        }
    }

    public void toggle() {
        if (lock) {
            return;
        }
        if (isExpand) {
            collapse();
        } else {
            expand();
        }
    }

    public interface OnStateChangedListener {
        void OnStateChanged(boolean isExpand);
    }
}