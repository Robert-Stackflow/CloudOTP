package com.cloudchewie.otp.entity;

import androidx.annotation.NonNull;

public class BaseItem {
    private String title;
    private String content;
    private String tag = "";

    public BaseItem(String title, String content, String tag) {
        this.title = title;
        this.content = content;
        this.tag = tag;
    }

    public BaseItem(String title, String content) {
        this.title = title;
        this.content = content;
    }

    @NonNull
    @Override
    public String toString() {
        return "BaseItem{" +
                "title='" + title + '\'' +
                ", content='" + content + '\'' +
                ", tag='" + tag + '\'' +
                '}';
    }

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public String getTag() {
        return tag;
    }

    public void setTag(String tag) {
        this.tag = tag;
    }

    public String getContent() {
        return content;
    }

    public void setContent(String content) {
        this.content = content;
    }
}
