package com.cloudchewie.otp.external;

import android.content.Context;

import com.cloudchewie.otp.util.database.AppSharedPreferenceUtil;

public class AccessTokenManager {
    private Context mContext;

    public AccessTokenManager(Context aContext) {
        this.mContext = aContext;
    }

    public boolean haveToken() {
        return AppSharedPreferenceUtil.haveDropxboxAccessToken(mContext);
    }

    public String getToken() {
        return AppSharedPreferenceUtil.getDropxboxAccessToken(mContext);
    }

    public void setToken(String theToken) {
        AppSharedPreferenceUtil.setDropxboxAccessToken(mContext, theToken);
    }
}
