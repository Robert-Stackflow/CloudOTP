package com.cloudchewie.ui.emoji.widget;

import android.content.Context;
import android.graphics.Color;
import android.graphics.drawable.ColorDrawable;
import android.util.AttributeSet;
import android.view.LayoutInflater;
import android.view.View;
import android.widget.GridView;
import android.widget.RelativeLayout;

import com.cloudchewie.ui.R;


public class EmoticonPageView extends RelativeLayout {

    private GridView mGvEmotion;

    public EmoticonPageView(Context context) {
        this(context, null);
    }

    public EmoticonPageView(Context context, AttributeSet attrs) {
        super(context, attrs);
        LayoutInflater inflater = (LayoutInflater) context.getSystemService(Context.LAYOUT_INFLATER_SERVICE);
        View view = inflater.inflate(R.layout.item_emoji_iconpage, this);
        mGvEmotion = view.findViewById(R.id.gv_emotion);
        mGvEmotion.setMotionEventSplittingEnabled(false);
        mGvEmotion.setStretchMode(GridView.STRETCH_COLUMN_WIDTH);
        mGvEmotion.setCacheColorHint(0);
        mGvEmotion.setSelector(new ColorDrawable(Color.TRANSPARENT));
    }

    public GridView getEmoticonsGridView() {
        return mGvEmotion;
    }

    public void setNumColumns(int row) {
        mGvEmotion.setNumColumns(row);
    }
}
