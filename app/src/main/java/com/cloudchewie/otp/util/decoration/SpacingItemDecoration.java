package com.cloudchewie.otp.util.decoration;

import android.content.Context;
import android.graphics.Rect;
import android.view.View;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;

import com.cloudchewie.otp.util.enumeration.Direction;
import com.cloudchewie.util.ui.SizeUtil;

public class SpacingItemDecoration extends RecyclerView.ItemDecoration {
    private Direction direction;
    private int spacing;

    public SpacingItemDecoration(Context context, int spacing, Direction direction) {
        this.spacing = SizeUtil.dp2px(context, spacing);
        this.direction = direction;
    }

    @Override
    public void getItemOffsets(@NonNull Rect outRect, @NonNull View view, @NonNull RecyclerView parent, @NonNull RecyclerView.State state) {
        super.getItemOffsets(outRect, view, parent, state);
        switch (direction) {
            case LEFT:
                outRect.left = spacing;
                break;
            case TOP:
                outRect.top = spacing;
                break;
            case RIGHT:
                outRect.right = spacing;
                break;
            case BOTTOM:
                outRect.bottom = spacing;
                break;
        }
    }
}