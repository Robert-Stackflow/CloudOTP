/*
 * Project Name: Worthy
 * Author: Ruida
 * Last Modified: 2022/12/18 13:13:37
 * Copyright(c) 2022 Ruida https://cloudchewie.com
 */

package com.cloudchewie.util.listener;

import static java.lang.Math.abs;

import com.google.android.material.appbar.AppBarLayout;

public abstract class AppBarStateChangeListener implements AppBarLayout.OnOffsetChangedListener {
    private int offset;
    private State mCurrentState = State.UPING;

    @Override
    public final void onOffsetChanged(AppBarLayout appBarLayout, int i) {
        if (i == 0) {
            if (mCurrentState != State.EXPANDED) {
                onStateChanged(appBarLayout, State.EXPANDED, i);
            }
            mCurrentState = State.EXPANDED;
            offset = i;
        } else if (abs(i) >= appBarLayout.getTotalScrollRange()) {
            if (mCurrentState != State.COLLAPSED) {
                onStateChanged(appBarLayout, State.COLLAPSED, i);
            }
            mCurrentState = State.COLLAPSED;
            offset = i;
        } else if (offset < i) {
            if (mCurrentState != State.DOWNING || ((abs(offset - i) > 50) && (mCurrentState == State.DOWNING))) {
                onStateChanged(appBarLayout, State.DOWNING, i);
                offset = i;
            }
            mCurrentState = State.DOWNING;
        } else {
            if (mCurrentState != State.UPING || ((abs(offset - i) > 200) && (mCurrentState == State.UPING))) {
                onStateChanged(appBarLayout, State.UPING, i);
                offset = i;
            }
            mCurrentState = State.UPING;
        }
    }

    public abstract void onStateChanged(AppBarLayout appBarLayout, State state, int offset);

    public enum State {
        EXPANDED,
        COLLAPSED,
        UPING,
        DOWNING
    }
}