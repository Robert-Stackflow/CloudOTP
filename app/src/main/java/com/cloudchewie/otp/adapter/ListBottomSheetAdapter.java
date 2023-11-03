package com.cloudchewie.otp.adapter;

import android.annotation.SuppressLint;
import android.content.Context;
import android.util.TypedValue;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;

import com.cloudchewie.otp.R;
import com.cloudchewie.otp.entity.ListBottomSheetBean;
import com.cloudchewie.otp.widget.ListBottomSheet;
import com.cloudchewie.util.ui.SizeUtil;

import java.util.List;

public class ListBottomSheetAdapter extends RecyclerView.Adapter<ListBottomSheetAdapter.MyViewHolder> {
    List<ListBottomSheetBean> beans;
    ListBottomSheet.OnItemClickedListener listener;
    Context context;
    boolean checkable;
    int checkIndex;

    public ListBottomSheetAdapter(Context context, List<ListBottomSheetBean> beans) {
        this.beans = beans;
        this.context = context;
    }

    public void setCheckIndex(int checkIndex) {
        this.checkIndex = checkIndex;
    }

    public void setCheckable(boolean checkable) {
        this.checkable = checkable;
    }

    @SuppressLint("NotifyDataSetChanged")
    public void setListBottomSheetBeans(List<ListBottomSheetBean> beans) {
        this.beans = beans;
        notifyDataSetChanged();
    }

    @NonNull
    @Override
    public MyViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View view = LayoutInflater.from(parent.getContext()).inflate(R.layout.list_view_item, parent, false);
        return new MyViewHolder(view);
    }

    public ListBottomSheetAdapter setOnItemClickedListener(ListBottomSheet.OnItemClickedListener listener) {
        this.listener = listener;
        return this;
    }

    public List<ListBottomSheetBean> getCityListBeans() {
        return beans;
    }

    @Override
    public void onBindViewHolder(@NonNull MyViewHolder holder, int position) {
        if (null == beans) {
            return;
        }
        if (position < 0 || position >= beans.size()) {
            return;
        }
        if (null == holder) {
            return;
        }
        final ListBottomSheetBean cityBean = beans.get(position);
        if (null == cityBean) {
            return;
        }
        if (position == 0) {
            holder.mItemView.setBackgroundResource(R.drawable.shape_round_top_dp10);
            holder.textView.setBackgroundTintList(context.getColorStateList(R.color.color_selector_card));
        } else {
            holder.mItemView.setBackgroundResource(R.drawable.shape_rect);
            holder.textView.setBackgroundTintList(context.getColorStateList(R.color.color_selector_card));
        }
        holder.textView.setText(cityBean.getText());
        holder.mItemView.setOnClickListener(v -> {
            if (listener != null)
                listener.onItemClicked(position);
        });
        holder.textView.setTextSize(TypedValue.COMPLEX_UNIT_SP, 15);
        holder.textView.setPadding(0, SizeUtil.dp2px(context, 15), 0, SizeUtil.dp2px(context, 15));
        if (checkable && checkIndex >= 0 && checkIndex < getItemCount() && position == checkIndex)
            holder.checkView.setVisibility(View.VISIBLE);
    }

    @Override
    public int getItemCount() {
        return beans == null ? 0 : beans.size();
    }

    public static class MyViewHolder extends RecyclerView.ViewHolder {
        public View mItemView;
        public TextView textView;
        public ImageView checkView;

        public MyViewHolder(View view) {
            super(view);
            mItemView = view;
            textView = view.findViewById(R.id.list_view_item_text);
            checkView = view.findViewById(R.id.list_view_item_check);
            textView.setTextAlignment(View.TEXT_ALIGNMENT_CENTER);
        }

        public String getText() {
            return textView.getText().toString();
        }
    }
}
