package com.cloudchewie.otp.entity;

import android.os.Bundle;

import androidx.annotation.NonNull;

import java.util.ArrayList;
import java.util.List;

public class ListBottomSheetBean {
    String text;
    Bundle bundle;

    @NonNull
    public static List<ListBottomSheetBean> strToBean(@NonNull List<String> stringList) {
        if (stringList == null)
            return null;
        List<ListBottomSheetBean> beanList = new ArrayList<>();
        for (String str : stringList)
            beanList.add(new ListBottomSheetBean().setText(str));
        return beanList;
    }

    public String getText() {
        return text;
    }

    public ListBottomSheetBean setText(String text) {
        this.text = text;
        return this;
    }

    public Bundle getBundle() {
        return bundle;
    }

    public ListBottomSheetBean setBundle(Bundle bundle) {
        this.bundle = bundle;
        return this;
    }
}
