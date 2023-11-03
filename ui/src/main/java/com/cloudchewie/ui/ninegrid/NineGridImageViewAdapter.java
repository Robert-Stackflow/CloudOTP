package com.cloudchewie.ui.ninegrid;

import android.content.Context;
import android.widget.ImageView;

import java.util.List;

public abstract class NineGridImageViewAdapter<T> {
    protected Context context;
    protected int radius = 3;
    private List<T> imageInfo;

    public NineGridImageViewAdapter(Context context, List<T> imageInfo) {
        this.context = context;
        this.imageInfo = imageInfo;
    }

    public NineGridImageViewAdapter() {

    }

    public void setRadius(int radius) {
        this.radius = radius;
    }

    protected abstract void onDisplayImage(Context context, ImageView imageView, int count, int index, T t);

    protected void onItemImageClick(Context context, ImageView imageView, int index, List<T> list) {
    }

    protected boolean onItemImageLongClick(Context context, ImageView imageView, int index, List<T> list) {
        return false;
    }

    protected ImageView generateImageView(int count, int index, Context context) {
        GridImageView imageView = new GridImageView(context, radius);
        imageView.setScaleType(ImageView.ScaleType.CENTER_CROP);
        return imageView;
    }
}