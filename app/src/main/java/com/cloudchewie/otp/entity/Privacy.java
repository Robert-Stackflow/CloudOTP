package com.cloudchewie.otp.entity;

import androidx.annotation.NonNull;
import androidx.room.Entity;
import androidx.room.PrimaryKey;

@Entity(tableName = "privacy")
public class Privacy {
    @PrimaryKey
    Integer id = 0;
    String passcode;
    String secret;
    Boolean verified;

    public Boolean getVerified() {
        return verified;
    }

    public void setVerified(Boolean verified) {
        this.verified = verified;
    }

    @NonNull
    @Override
    public String toString() {
        return "Privacy{" +
                "passcode='" + passcode + '\'' +
                ", secret='" + secret + '\'' +
                '}';
    }

    public String getPasscode() {
        return passcode;
    }

    public void setPasscode(String passcode) {
        this.passcode = passcode;
    }

    public String getSecret() {
        return secret;
    }

    public void setSecret(String secret) {
        this.secret = secret;
    }

    public Integer getId() {
        return id;
    }

    public void setId(Integer id) {
        this.id = id;
    }
}
