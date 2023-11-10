package com.cloudchewie.otp.database;

import com.cloudchewie.otp.entity.OtpToken;

import java.util.List;

public class OtpTokenManager {
    public static List<OtpToken> getTokens() {
        List<OtpToken> otpTokens = LocalStorage.getAppDatabase().otpTokenDao().getAll();
        int initOrdinal = 0;
        for (OtpToken otpToken : otpTokens) {
            if (otpToken.getOrdinal() > 1000000000) {
                otpToken.setOrdinal(initOrdinal++);
                LocalStorage.getAppDatabase().otpTokenDao().updateOrdinal(otpToken.getId(), otpToken.getOrdinal());
            }
        }
        return otpTokens;
    }
}
