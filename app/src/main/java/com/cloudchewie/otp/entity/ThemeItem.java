package com.cloudchewie.otp.entity;

import androidx.annotation.NonNull;

public class ThemeItem {
    public String title;
    public String description;
    public int colorId;
    public int layoutId;
    public int themeId;

    public ThemeItem(String title, String description, int colorId, int layoutId, int themeId) {
        this.title = title;
        this.description = description;
        this.colorId = colorId;
        this.layoutId = layoutId;
        this.themeId = themeId;
    }

    public int getThemeId() {
        return themeId;
    }

    public void setThemeId(int themeId) {
        this.themeId = themeId;
    }

    public int getLayoutId() {
        return layoutId;
    }

    public void setLayoutId(int layoutId) {
        this.layoutId = layoutId;
    }

    @NonNull
    @Override
    public String toString() {
        return "ThemeItem{" + "title='" + title + '\'' + ", description='" + description + '\'' + ", colorId=" + colorId + ", id=" + layoutId + '}';
    }

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public int getColorId() {
        return colorId;
    }

    public void setColorId(int colorId) {
        this.colorId = colorId;
    }
}
