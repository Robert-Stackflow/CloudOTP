package com.cloudchewie.otp.database;

import com.cloudchewie.otp.entity.Privacy;
import com.cloudchewie.otp.util.enumeration.EventBusCode;
import com.jeremyliao.liveeventbus.LiveEventBus;

public class PrivacyManager {
    private static boolean inited = false;

    public static void init() {
        if (inited) return;
        if (LocalStorage.getAppDatabase().privacyDao().get() == null)
            LocalStorage.getAppDatabase().privacyDao().insert(new Privacy());
        Privacy privacy = LocalStorage.getAppDatabase().privacyDao().get();
        privacy.setVerified(null);
        LocalStorage.getAppDatabase().privacyDao().update(privacy);
        inited = true;
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

    public static boolean isVerified() {
        Boolean b = LocalStorage.getAppDatabase().privacyDao().getVerified();
        return b != null ? b : false;
    }

    public static void unlock() {
        Privacy privacy = LocalStorage.getAppDatabase().privacyDao().get();
        privacy.setVerified(true);
        LocalStorage.getAppDatabase().privacyDao().update(privacy);
        LiveEventBus.get(EventBusCode.CHANGE_VERIFY_STATE.getKey()).post("");
    }

    public static void lock() {
        Privacy privacy = LocalStorage.getAppDatabase().privacyDao().get();
        privacy.setVerified(false);
        LocalStorage.getAppDatabase().privacyDao().update(privacy);
        LiveEventBus.get(EventBusCode.CHANGE_VERIFY_STATE.getKey()).post("");
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
