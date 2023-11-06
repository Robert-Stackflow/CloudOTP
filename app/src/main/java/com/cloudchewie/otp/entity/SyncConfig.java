package com.cloudchewie.otp.entity;

import androidx.annotation.NonNull;
import androidx.room.Entity;
import androidx.room.Ignore;
import androidx.room.PrimaryKey;

import java.io.Serializable;

@Entity(tableName = "sync_config")
public class SyncConfig implements Serializable {
    @NonNull
    @PrimaryKey()
    String name = "";
    String accessToken;
    Long lastPushed;

    public SyncConfig() {
    }

    @Ignore
    public SyncConfig(@NonNull String name) {
        this.name = name;
    }

    @NonNull
    @Override
    public String toString() {
        return "SyncConfig{" + "name='" + name + '\'' + ", apiKey='" + accessToken + '\'' + ", lastPushed=" + lastPushed + '}';
    }

    @NonNull
    public String getName() {
        return name;
    }

    public void setName(@NonNull String name) {
        this.name = name;
    }

    public String getAccessToken() {
        return accessToken;
    }

    public void setAccessToken(String accessToken) {
        this.accessToken = accessToken;
    }

    public Long getLastPushed() {
        return lastPushed;
    }

    public void setLastPushed(Long lastPushed) {
        this.lastPushed = lastPushed;
    }
}
