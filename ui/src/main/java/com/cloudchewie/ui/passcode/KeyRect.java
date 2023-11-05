package com.cloudchewie.ui.passcode;

import android.animation.Animator;
import android.animation.ValueAnimator;
import android.graphics.Rect;
import android.util.Log;
import android.view.View;
import android.view.animation.CycleInterpolator;

import androidx.annotation.NonNull;

public class KeyRect {
    private final View view;
    public Rect rect;
    public String value;
    public int rippleRadius = 0;
    public int requiredRadius;
    public int circleAlpha;
    private final Rect tempRect;
    public boolean hasRippleEffect = true;
    public ValueAnimator animator;
    private final int MAX_RIPPLE_ALPHA = 180;
    private InterpolatedValueListener interpolatedValueListener;
    private int animationLeftRepeatCount = 2;
    private int animationRightRepeatCount = 2;
    private int cycleCount = 4;
    private RippleAnimListener rippleAnimListener;

    public KeyRect(View view, Rect rect, String value) {
        this.view = view;
        this.rect = rect;
        this.tempRect = new Rect(rect);
        this.value = value;
        requiredRadius = (this.rect.right - this.rect.left) / 4;
        setUpAnimator();
    }

    /**
     * Initialise the filed and listener for ripple effect animator
     */
    private void setUpAnimator() {
        animator = ValueAnimator.ofFloat(0, requiredRadius);
        animator.setDuration(400);
        final int circleAlphaOffset = MAX_RIPPLE_ALPHA / requiredRadius;
        animator.addUpdateListener(animation -> {
            if (hasRippleEffect) {
                float animatedValue = (float) animation.getAnimatedValue();
                rippleRadius = (int) animatedValue;
                circleAlpha = (int) (MAX_RIPPLE_ALPHA - (animatedValue * circleAlphaOffset));
                interpolatedValueListener.onValueUpdated();
            }
        });

        animator.addListener(new ValueAnimator.AnimatorListener() {
            @Override
            public void onAnimationStart(@NonNull Animator animation) {
                hasRippleEffect = true;
            }

            @Override
            public void onAnimationEnd(@NonNull Animator animation) {
                hasRippleEffect = false;
                rippleRadius = 0;
                rippleAnimListener.onEnd();
            }

            @Override
            public void onAnimationCancel(@NonNull Animator animation) {

            }

            @Override
            public void onAnimationRepeat(@NonNull Animator animation) {

            }
        });
    }

    /**
     * Set the valued of this Key
     *
     * @param value - Value to be set for this key
     */
    public void setValue(String value) {
        this.value = value;
    }

    /**
     * Show animation indicated invalid pincode
     */
    public void setError() {
        ValueAnimator goLeftAnimator = ValueAnimator.ofInt(0, 5);
        goLeftAnimator.setInterpolator(new CycleInterpolator(2));
        goLeftAnimator.addUpdateListener(animation -> {
            rect.left += (int) animation.getAnimatedValue();
            rect.right += (int) animation.getAnimatedValue();
            view.invalidate();
        });
        goLeftAnimator.start();
    }

    public interface InterpolatedValueListener {
        void onValueUpdated();
    }

    public void setOnValueUpdateListener(InterpolatedValueListener listener) {
        this.interpolatedValueListener = listener;
    }

    /**
     * Start Playing ripple animation and notify listener accordingly
     */
    public void playRippleAnim(RippleAnimListener listener) {
        this.rippleAnimListener = listener;
        setOnValueUpdateListener(() -> view.invalidate(rect));
        rippleAnimListener.onStart();
        animator.start();
    }

    /**
     * Interface to get notified on ripple animation status
     */
    public interface RippleAnimListener {
        void onStart();

        void onEnd();
    }
}
