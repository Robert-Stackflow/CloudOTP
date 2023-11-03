package com.cloudchewie.otp.util.decoration;

import android.content.Context;
import android.graphics.Rect;
import android.view.View;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;

import com.cloudchewie.otp.R;

public class StaggerItemDecoration extends RecyclerView.ItemDecoration {
    int gap;
    Context context;

    public StaggerItemDecoration(@NonNull Context context) {
        this.context = context;
        gap = context.getResources().getDimensionPixelSize(R.dimen.dp5);
    }

    public StaggerItemDecoration(Context context, int gap) {
        this.context = context;
        this.gap = gap;
    }

    @Override
    public void getItemOffsets(@NonNull Rect outRect, @NonNull View view, @NonNull RecyclerView parent, @NonNull RecyclerView.State state) {
        super.getItemOffsets(outRect, view, parent, state);
        outRect.set(gap, 0, gap, -gap);
    }
}