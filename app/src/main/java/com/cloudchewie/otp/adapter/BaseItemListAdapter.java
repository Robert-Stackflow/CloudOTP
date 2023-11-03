package com.cloudchewie.otp.adapter;

import android.annotation.SuppressLint;
import android.content.Context;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;

import com.cloudchewie.otp.R;
import com.cloudchewie.otp.entity.BaseItem;
import com.cloudchewie.ui.item.ExpandableItem;

import java.util.List;

public class BaseItemListAdapter extends RecyclerView.Adapter<BaseItemListAdapter.MyViewHolder> {
    private final Context context;
    private List<BaseItem> contentList;

    public BaseItemListAdapter(Context context, List<BaseItem> contentList) {
        this.contentList = contentList;
        this.context = context;
    }

    @NonNull
    @Override
    public BaseItemListAdapter.MyViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View view = LayoutInflater.from(parent.getContext()).inflate(R.layout.item_base, parent, false);
        return new BaseItemListAdapter.MyViewHolder(view);
    }

    @SuppressLint("NotifyDataSetChanged")
    public void setData(List<BaseItem> contentList) {
        this.contentList = contentList;
        notifyDataSetChanged();
    }

    @Override
    public void onBindViewHolder(@NonNull BaseItemListAdapter.MyViewHolder holder, int position) {
        if (null == contentList) {
            return;
        }
        if (position < 0 || position >= contentList.size()) {
            return;
        }
        if (null == holder) {
            return;
        }
        final BaseItem content = contentList.get(position);
        if (null == content) {
            return;
        }
        holder.expandableItem.setTitle(content.getTitle());
        holder.expandableItem.setContent(content.getContent());
        holder.expandableItem.setTagText(content.getTag());
    }

    @Override
    public int getItemCount() {
        return contentList == null ? 0 : contentList.size();
    }

    static class MyViewHolder extends RecyclerView.ViewHolder {
        public View mItemView;
        public ExpandableItem expandableItem;

        public MyViewHolder(View view) {
            super(view);
            mItemView = view;
            expandableItem = view.findViewById(R.id.item_base_expand_item);
        }
    }
}

