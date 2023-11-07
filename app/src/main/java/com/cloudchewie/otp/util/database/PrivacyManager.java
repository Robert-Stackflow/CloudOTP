package com.cloudchewie.otp.util.database;

import com.cloudchewie.otp.entity.Privacy;

public class PrivacyManager {

    public static void init() {
        if (LocalStorage.getAppDatabase().privacyDao().get() == null)
            LocalStorage.getAppDatabase().privacyDao().insert(new Privacy());
    }

    public static String getPasscode() {
        return LocalStorage.getAppDatabase().privacyDao().getPasscode();
    }

    public static void setPasscode(String passcode) {
        Privacy privacy = LocalStorage.getAppDatabase().privacyDao().get();
        privacy.setPasscode(passcode);
        LocalStorage.getAppDatabase().privacyDao().update(privacy);
    }

    public static boolean havePasscode() {
        String passcode = getPasscode();
        return passcode != null && !passcode.isEmpty();
    }

    public static String getSecret() {
        return LocalStorage.getAppDatabase().privacyDao().getSecret();
    }

    public static void setSecret(String secret) {
        Privacy privacy = LocalStorage.getAppDatabase().privacyDao().get();
        privacy.setSecret(secret);
        LocalStorage.getAppDatabase().privacyDao().update(privacy);
    }

    public static boolean haveSecret() {
        String secret = getSecret();
        return secret != null && !secret.isEmpty();
    }
}
