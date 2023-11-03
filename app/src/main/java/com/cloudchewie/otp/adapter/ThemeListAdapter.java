package com.cloudchewie.otp.adapter;

import android.content.Context;
import android.content.res.ColorStateList;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.appcompat.content.res.AppCompatResources;
import androidx.recyclerview.widget.RecyclerView;

import com.cloudchewie.otp.R;
import com.cloudchewie.otp.entity.ThemeItem;
import com.cloudchewie.util.system.SharedPreferenceUtil;

import java.util.List;

public class ThemeListAdapter extends RecyclerView.Adapter<ThemeListAdapter.MyViewHolder> {
    List<ThemeItem> themeItemList;
    Context context;
    View.OnClickListener listener;

    public ThemeListAdapter(Context context, List<ThemeItem> themeItemList) {
        this.themeItemList = themeItemList;
        this.context = context;
    }

    @NonNull
    @Override
    public MyViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View view = LayoutInflater.from(parent.getContext()).inflate(R.layout.item_theme, parent, false);
        return new MyViewHolder(view);
    }

    public View.OnClickListener getListener() {
        return listener;
    }

    public void setListener(View.OnClickListener listener) {
        this.listener = listener;
    }

    @Override
    public void onBindViewHolder(@NonNull MyViewHolder holder, int position) {
        if (null == themeItemList) {
            return;
        }
        if (position < 0 || position >= themeItemList.size()) {
            return;
        }
        if (null == holder) {
            return;
        }
        final ThemeItem themeItem = themeItemList.get(position);
        if (null == themeItem) {
            return;
        }
        holder.mItemView.setId(themeItem.layoutId);
        holder.titleView.setText(themeItem.title);
        holder.descriptionView.setText(themeItem.description);
        holder.colorView.setBackgroundColor(context.getColor(themeItem.colorId));
        holder.checkboxView.setTag(R.id.id_theme_item_key, themeItem);
        holder.checkboxView.setImageTintList(ColorStateList.valueOf(context.getColor(themeItem.colorId)));
        holder.checkboxView.setOnClickListener(listener);
        if (SharedPreferenceUtil.getThemeId(context, R.style.AppTheme) == themeItem.themeId) {
            ColorStateList colorStateList = holder.checkboxView.getImageTintList();
            holder.checkboxView.setImageDrawable(AppCompatResources.getDrawable(context, R.drawable.ic_light_checkbox_checked));
            holder.checkboxView.setImageTintList(colorStateList);
        }
    }

    @Override
    public int getItemCount() {
        return themeItemList == null ? 0 : themeItemList.size();
    }

    public interface onItemClickedListener {
        void onItemClicked(int position);
    }

    static class MyViewHolder extends RecyclerView.ViewHolder {
        public View mItemView;
        public TextView titleView;
        public TextView descriptionView;
        public View colorView;
        public ImageView checkboxView;

        public MyViewHolder(View view) {
            super(view);
            mItemView = view;
            titleView = view.findViewById(R.id.item_theme_title);
            descriptionView = view.findViewById(R.id.item_theme_description);
            colorView = view.findViewById(R.id.item_theme_color);
            checkboxView = view.findViewById(R.id.item_theme_checkbox);
        }
    }
}
