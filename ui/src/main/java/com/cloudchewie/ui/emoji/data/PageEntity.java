package com.cloudchewie.ui.emoji.data;

import android.view.View;
import android.view.ViewGroup;

import com.cloudchewie.ui.emoji.listener.PageViewInstantiateListener;


/**
 * use XhsEmotionsKeyboard(https://github.com/w446108264/XhsEmoticonsKeyboard)
 * author: sj
 */
public class PageEntity<T extends PageEntity> implements PageViewInstantiateListener<T> {

    protected View mRootView;

    protected PageViewInstantiateListener mPageViewInstantiateListener;

    public PageEntity() {
    }

    public PageEntity(View view) {
        this.mRootView = view;
    }

    public void setIPageViewInstantiateItem(PageViewInstantiateListener pageViewInstantiateListener) {
        this.mPageViewInstantiateListener = pageViewInstantiateListener;
    }

    public View getRootView() {
        return mRootView;
    }

    public void setRootView(View rootView) {
        this.mRootView = rootView;
    }

    @Override
    public View instantiateItem(ViewGroup container, int position, T pageEntity) {
        if (mPageViewInstantiateListener != null) {
            return mPageViewInstantiateListener.instantiateItem(container, position, this);
        }
        return getRootView();
    }
}
