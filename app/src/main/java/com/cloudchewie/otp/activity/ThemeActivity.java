/*
 * Project Name: Worthy
 * Author: Ruida
 * Last Modified: 2022/12/19 14:29:32
 * Copyright(c) 2022 Ruida https://cloudchewie.com
 */

package com.cloudchewie.otp.activity;

import android.annotation.SuppressLint;
import android.content.Context;
import android.content.res.ColorStateList;
import android.os.Bundle;
import android.view.View;
import android.widget.ImageView;

import androidx.appcompat.content.res.AppCompatResources;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.cloudchewie.otp.R;
import com.cloudchewie.otp.activity.BaseActivity;
import com.cloudchewie.otp.adapter.ThemeListAdapter;
import com.cloudchewie.otp.entity.ThemeItem;
import com.cloudchewie.otp.util.decoration.SpacingItemDecoration;
import com.cloudchewie.otp.util.enumeration.Direction;
import com.cloudchewie.otp.util.enumeration.EventBusCode;
import com.cloudchewie.ui.custom.IToast;
import com.cloudchewie.ui.custom.TitleBar;
import com.cloudchewie.util.system.SharedPreferenceUtil;
import com.cloudchewie.util.ui.StatusBarUtil;
import com.jeremyliao.liveeventbus.LiveEventBus;
import com.scwang.smart.refresh.layout.api.RefreshLayout;

import java.util.ArrayList;
import java.util.List;

public class ThemeActivity extends BaseActivity implements View.OnClickListener {

    RecyclerView recyclerView;
    ThemeListAdapter adapter;

    RefreshLayout swipeRefreshLayout;

    public static List<ThemeItem> getThemeList(Context context) {
        List<ThemeItem> themeItemList = new ArrayList<>();
        themeItemList.add(new ThemeItem(context.getString(R.string.theme_title_1), context.getString(R.string.theme_content_1), R.color.custom_color_app_accent_1, R.id.id_theme_item_1, R.style.AppTheme_Color1));
        themeItemList.add(new ThemeItem(context.getString(R.string.theme_title_2), context.getString(R.string.theme_content_2), R.color.custom_color_app_accent_2, R.id.id_theme_item_2, R.style.AppTheme_Color2));
        themeItemList.add(new ThemeItem(context.getString(R.string.theme_title_3), context.getString(R.string.theme_content_3), R.color.custom_color_app_accent_3, R.id.id_theme_item_3, R.style.AppTheme_Color3));
        themeItemList.add(new ThemeItem(context.getString(R.string.theme_title_4), context.getString(R.string.theme_content_4), R.color.custom_color_app_accent_4, R.id.id_theme_item_4, R.style.AppTheme_Color4));
        themeItemList.add(new ThemeItem(context.getString(R.string.theme_title_5), context.getString(R.string.theme_content_5), R.color.custom_color_app_accent_5, R.id.id_theme_item_5, R.style.AppTheme_Color5));
        themeItemList.add(new ThemeItem(context.getString(R.string.theme_title_6), context.getString(R.string.theme_content_6), R.color.custom_color_app_accent_6, R.id.id_theme_item_6, R.style.AppTheme_Color6));
        themeItemList.add(new ThemeItem(context.getString(R.string.theme_title_7), context.getString(R.string.theme_content_7), R.color.custom_color_app_accent_7, R.id.id_theme_item_7, R.style.AppTheme_Color7));
        themeItemList.add(new ThemeItem(context.getString(R.string.theme_title_8), context.getString(R.string.theme_content_8), R.color.custom_color_app_accent_8, R.id.id_theme_item_8, R.style.AppTheme_Color8));
        themeItemList.add(new ThemeItem(context.getString(R.string.theme_title_9), context.getString(R.string.theme_content_9), R.color.custom_color_app_accent_9, R.id.id_theme_item_9, R.style.AppTheme_Color9));
        return themeItemList;
    }

    @SuppressLint("SetTextI18n")
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        StatusBarUtil.setStatusBarMarginTop(this);
        setContentView(R.layout.activity_theme);
        ((TitleBar) findViewById(R.id.activity_theme_titlebar)).setLeftButtonClickListener(v -> finishAfterTransition());
        recyclerView = findViewById(R.id.activity_theme_recycler_view);
        loadThemes();
        initSwipeRefresh();
    }

    void initSwipeRefresh() {
        swipeRefreshLayout = findViewById(R.id.activity_theme_swipe_refresh);
        swipeRefreshLayout.setEnableOverScrollDrag(true);
        swipeRefreshLayout.setEnableOverScrollBounce(true);
        swipeRefreshLayout.setEnableLoadMore(false);
        swipeRefreshLayout.setEnablePureScrollMode(true);
    }

    void loadThemes() {
        List<ThemeItem> themeItemList = getThemeList(this);
        adapter = new ThemeListAdapter(this, themeItemList);
        adapter.setListener(this);
        recyclerView.setAdapter(adapter);
        recyclerView.setLayoutManager(new LinearLayoutManager(this));
        recyclerView.addItemDecoration(new SpacingItemDecoration(this, (int) getResources().getDimension(R.dimen.dp5), Direction.BOTTOM));
    }

    @Override
    public void onClick(View view) {
        if (recyclerView == null) return;
        Object o = view.getTag(R.id.id_theme_item_key);
        if (o instanceof ThemeItem) {
            ThemeItem themeItem = (ThemeItem) o;
            if (themeItem.themeId == SharedPreferenceUtil.getThemeId(this, R.style.AppTheme))
                return;
            for (int i = 0; i < recyclerView.getChildCount(); i++) {
                View childView = recyclerView.getChildAt(i);
                ImageView checkBox = childView.findViewById(R.id.item_theme_checkbox);
                if (childView.getId() == themeItem.layoutId) {
                    ColorStateList colorStateList = checkBox.getImageTintList();
                    checkBox.setImageDrawable(AppCompatResources.getDrawable(this, R.drawable.ic_light_checkbox_checked));
                    checkBox.setImageTintList(colorStateList);
                    SharedPreferenceUtil.setThemeId(this, themeItem.themeId);
                    IToast.showBottom(this, getString(R.string.change_theme_success));
                    LiveEventBus.get(EventBusCode.CHANGE_THEME.getKey(), String.class).post("");
                } else {
                    ColorStateList colorStateList = checkBox.getImageTintList();
                    checkBox.setImageDrawable(AppCompatResources.getDrawable(this, R.drawable.ic_light_checkbox_unchecked));
                    checkBox.setImageTintList(colorStateList);
                }
            }
        }
    }
}
