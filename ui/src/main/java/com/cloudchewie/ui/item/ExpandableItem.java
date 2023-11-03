package com.cloudchewie.ui.item;

import android.content.Context;
import android.content.res.ColorStateList;
import android.content.res.TypedArray;
import android.graphics.Color;
import android.util.AttributeSet;
import android.util.TypedValue;
import android.view.LayoutInflater;
import android.view.View;
import android.widget.ImageView;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.constraintlayout.widget.ConstraintLayout;

import com.cloudchewie.ui.R;
import com.cloudchewie.ui.ThemeUtil;
import com.cloudchewie.ui.general.ExpandLayout;

public class ExpandableItem extends ConstraintLayout {
    private ImageView iconView;
    private TextView titleView;
    private TextView tagView;
    private TextView contentView;
    private View divider;
    private ConstraintLayout titleLayout;
    private ConstraintLayout mainLayout;
    private ExpandLayout expandLayout;
    private int iconId;
    private int expandIconId;

    public ExpandableItem(@NonNull Context context) {
        super(context);
        initView(context, null);
    }

    public ExpandableItem(@NonNull Context context, @Nullable AttributeSet attrs) {
        super(context, attrs);
        initView(context, attrs);
    }

    public ExpandableItem(@NonNull Context context, @Nullable AttributeSet attrs, int defStyleAttr) {
        super(context, attrs, defStyleAttr);
        initView(context, attrs);
    }

    public ExpandableItem(@NonNull Context context, @Nullable AttributeSet attrs, int defStyleAttr, int defStyleRes) {
        super(context, attrs, defStyleAttr, defStyleRes);
        initView(context, attrs);
    }

    private void initView(Context context, AttributeSet attrs) {
        LayoutInflater.from(context).inflate(R.layout.widget_expandable_item, this, true);
        mainLayout = findViewById(R.id.widget_expandable_item_layout);
        expandLayout = findViewById(R.id.widget_expandable_item_expand_layout);
        iconView = findViewById(R.id.widget_expandable_item_icon);
        titleView = findViewById(R.id.widget_expandable_item_title);
        tagView = findViewById(R.id.widget_expandable_item_tag);
        contentView = findViewById(R.id.widget_expandable_item_content);
        divider = findViewById(R.id.widget_expandable_item_divider);
        titleLayout = findViewById(R.id.widget_expandable_item_title_layout);
        TypedArray attr = context.obtainStyledAttributes(attrs, R.styleable.ExpandableItem);
        if (attr != null) {
            boolean iconVisible = attr.getBoolean(R.styleable.ExpandableItem_expandable_item_icon_visibility, true);
            iconId = attr.getResourceId(R.styleable.ExpandableItem_expandable_item_icon, R.drawable.ic_light_arrow_down);
            expandIconId = attr.getResourceId(R.styleable.ExpandableItem_expandable_item_expand_icon, R.drawable.ic_light_arrow_up);
            int iconBackgroundColor = attr.getColor(R.styleable.ExpandableItem_expandable_item_icon_background, Color.TRANSPARENT);
            setIcon(iconId);
            setIconBackground(iconBackgroundColor);
            setExpandIcon(expandIconId);
            setIconVisibility(iconVisible);
            String title = attr.getString(R.styleable.ExpandableItem_expandable_item_title);
            int titleSize = (int) attr.getDimension(R.styleable.ExpandableItem_expandable_item_title_size, getResources().getDimension(R.dimen.sp15));
            int titleColor = attr.getColor(R.styleable.ExpandableItem_expandable_item_title_color, getResources().getColor(R.color.color_accent, getResources().newTheme()));
            String tag = attr.getString(R.styleable.ExpandableItem_expandable_item_tag);
            int tagSize = (int) attr.getDimension(R.styleable.ExpandableItem_expandable_item_tag_size, getResources().getDimension(R.dimen.sp12));
            int tagColor = attr.getColor(R.styleable.ExpandableItem_expandable_item_tag_color, getResources().getColor(R.color.text_color_white, getResources().newTheme()));
            int tagBackgroundId = attr.getResourceId(R.styleable.ExpandableItem_expandable_item_tag_background, R.drawable.shape_round_dp5);
            int tagBackgroundTint = attr.getColor(R.styleable.ExpandableItem_expandable_item_tag_background_tint, ThemeUtil.getPrimaryColor(context));
            int contentColor = attr.getColor(R.styleable.ExpandableItem_expandable_item_content_color, getResources().getColor(R.color.color_gray, getResources().newTheme()));
            int contentSize = (int) attr.getDimension(R.styleable.ExpandableItem_expandable_item_content_size, getResources().getDimension(R.dimen.sp14));
            setTitle(title);
            setTitleSize(titleSize);
            setTitleColor(titleColor);
            setTagText(tag);
            setTagSize(tagSize);
            setTagColor(tagColor);
            setTagBackground(tagBackgroundId, tagBackgroundTint);
            setContentColor(contentColor);
            setContentSize(contentSize);
            attr.recycle();
        }
        setDividerVisible(false);
        titleLayout.setOnClickListener(v -> toggle());
        expandLayout.initExpand(false);
    }

    public TextView getTagView() {
        return tagView;
    }

    public void toggle() {
        expandLayout.toggle();
        setIconStatus(expandLayout.isExpand());
    }

    public void setDividerVisible(boolean visible) {
        if (visible) divider.setVisibility(VISIBLE);
        else divider.setVisibility(GONE);
    }

    private void setIconStatus(boolean isExpand) {
        if (isExpand) {
            iconView.animate().rotation(-180f);
        } else {
            iconView.animate().rotation(0f);
        }
    }

    private void setIcon(int iconId) {
        this.iconId = iconId;
    }

    private void setExpandIcon(int iconId) {
        this.expandIconId = iconId;
    }

    private void setIconVisibility(boolean visibility) {
        if (visibility) iconView.setVisibility(View.VISIBLE);
        else iconView.setVisibility(View.GONE);
    }

    private void setIconBackground(int backgroundColor) {
        iconView.setBackgroundColor(backgroundColor);
    }

    public void setTitle(String title) {
        titleView.setText(title);
    }

    public void setContent(String content) {
        contentView.setText(content);
    }

    public void setTitleColor(int titleColor) {
        titleView.setTextColor(titleColor);
    }

    public void setTitleSize(int size) {
        titleView.setTextSize(TypedValue.COMPLEX_UNIT_PX, size);
    }

    public void setTagText(String tag) {
        tagView.setText(tag);
        if (tag == null || tag.trim().equals("")) {
            tagView.setVisibility(GONE);
        } else {
            tagView.setVisibility(VISIBLE);
        }
    }

    public void setTagColor(int titleColor) {
        tagView.setTextColor(titleColor);
    }

    public void setTagSize(int size) {
        tagView.setTextSize(TypedValue.COMPLEX_UNIT_PX, size);
    }

    public void setTagBackground(int backgroundId, int backgroundTint) {
        tagView.setBackgroundResource(backgroundId);
        tagView.setBackgroundTintList(ColorStateList.valueOf(backgroundTint));
    }

    public void setContentColor(int contentColor) {
        contentView.setTextColor(contentColor);
    }

    public void setContentSize(int size) {
        contentView.setTextSize(TypedValue.COMPLEX_UNIT_PX, size);
    }
}
