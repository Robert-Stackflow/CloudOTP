package com.cloudchewie.ui.custom;

import android.content.Context;
import android.content.res.TypedArray;
import android.graphics.Color;
import android.util.AttributeSet;
import android.util.TypedValue;
import android.view.LayoutInflater;
import android.view.View;
import android.widget.ImageView;
import android.widget.RelativeLayout;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.constraintlayout.widget.ConstraintLayout;
import androidx.recyclerview.widget.RecyclerView;

import com.cloudchewie.ui.R;
import com.cloudchewie.ui.general.ExpandLayout;

public class ExpandableList extends RelativeLayout {
    private ImageView iconView;
    private TextView titleView;
    private TextView countView;
    private RecyclerView recyclerView;
    private View divider;
    private ConstraintLayout titleLayout;
    private RelativeLayout mainLayout;
    private ExpandLayout expandLayout;
    private int iconId;
    private int expandIconId;

    public ExpandableList(@NonNull Context context) {
        super(context);
        initView(context, null);
    }

    public ExpandableList(@NonNull Context context, @Nullable AttributeSet attrs) {
        super(context, attrs);
        initView(context, attrs);
    }

    public ExpandableList(@NonNull Context context, @Nullable AttributeSet attrs, int defStyleAttr) {
        super(context, attrs, defStyleAttr);
        initView(context, attrs);
    }

    public ExpandableList(@NonNull Context context, @Nullable AttributeSet attrs, int defStyleAttr, int defStyleRes) {
        super(context, attrs, defStyleAttr, defStyleRes);
        initView(context, attrs);
    }

    private void initView(Context context, AttributeSet attrs) {
        LayoutInflater.from(context).inflate(R.layout.widget_expandable_list, this, true);
        mainLayout = findViewById(R.id.widget_expandable_list_layout);
        expandLayout = findViewById(R.id.widget_expandable_list_expand_layout);
        iconView = findViewById(R.id.widget_expandable_list_icon);
        titleView = findViewById(R.id.widget_expandable_list_title);
        countView = findViewById(R.id.widget_expandable_list_count);
        recyclerView = findViewById(R.id.widget_expandable_list_recyclerview);
        divider = findViewById(R.id.widget_expandable_list_divider);
        titleLayout = findViewById(R.id.widget_expandable_list_title_layout);
        TypedArray attr = context.obtainStyledAttributes(attrs, R.styleable.ExpandableList);
        if (attr != null) {
            boolean iconVisible = attr.getBoolean(R.styleable.ExpandableList_expandable_list_icon_visibility, true);
            iconId = attr.getResourceId(R.styleable.ExpandableList_expandable_list_icon, R.drawable.ic_material_arrow_down);
            expandIconId = attr.getResourceId(R.styleable.ExpandableList_expandable_list_expand_icon, R.drawable.ic_material_arrow_up);
            int iconBackgroundColor = attr.getColor(R.styleable.ExpandableList_expandable_list_icon_background, Color.TRANSPARENT);
            setIcon(iconId);
            setIconBackground(iconBackgroundColor);
            setExpandIcon(expandIconId);
            setIconVisibility(iconVisible);
            String title = attr.getString(R.styleable.ExpandableList_expandable_list_title);
            int titleSize = (int) attr.getDimension(R.styleable.ExpandableList_expandable_list_title_size, getResources().getDimension(R.dimen.sp17));
            int titleColor = attr.getColor(R.styleable.ExpandableList_expandable_list_title_color, getResources().getColor(R.color.color_accent, getResources().newTheme()));
            setTitle(title);
            setTitleSize(titleSize);
            setTitleColor(titleColor);
            attr.recycle();
        }
        setDividerVisible(false);
        titleLayout.setOnClickListener(v -> toggle());
        expandLayout.initExpand(false);
    }

    public ExpandLayout getExpandLayout() {
        return expandLayout;
    }

    public void initExpand(boolean expand) {
        getExpandLayout().initExpand(expand);
        setIconStatus(expand);
    }

    public void toggle() {
        expandLayout.toggle();
        setIconStatus(expandLayout.isExpand());
    }

    public void setCount(int count) {
        countView.setText(String.valueOf(count));
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

    public void setTitleColor(int titleColor) {
        titleView.setTextColor(titleColor);
    }

    public void setTitleSize(int size) {
        titleView.setTextSize(TypedValue.COMPLEX_UNIT_PX, size);
    }

    public RecyclerView getRecyclerView() {
        return recyclerView;
    }
}
