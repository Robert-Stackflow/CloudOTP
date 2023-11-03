package com.cloudchewie.ui.emoji.listener;

import android.view.ViewGroup;

import com.cloudchewie.ui.emoji.adapter.EmoticonsAdapter;


public interface EmoticonDisplayListener<T> {

    void onBindView(int position, ViewGroup parent, EmoticonsAdapter.ViewHolder viewHolder, T t, boolean isDelBtn);
}