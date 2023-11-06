package com.cloudchewie.otp.external;

public enum SyncService {
    DROPBOX("dropbox"),
    PRIVACY("privacy");
    private final String key;

    SyncService(String key) {
        this.key = key;
    }

    public String getKey() {
        return key;
    }

}
