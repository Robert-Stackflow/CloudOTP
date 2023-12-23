package com.cloudchewie.otp.entity;

import androidx.annotation.NonNull;
import androidx.room.Entity;
import androidx.room.Ignore;
import androidx.room.PrimaryKey;

import com.cloudchewie.otp.util.enumeration.EncryptionType;
import com.cloudchewie.otp.util.enumeration.OtpTokenType;

import java.io.Serializable;
import java.util.Objects;

@Entity(tableName = "otp_tokens")
public class OtpToken implements Serializable {
    @PrimaryKey(autoGenerate = true)
    Long id;
    Integer ordinal;
    String issuer;
    String secret;
    String account;
    String imagePath;
    OtpTokenType tokenType;
    String algorithm;
    Integer digits;
    Long counter;
    Integer period;
    EncryptionType encryptionType;
    boolean pinned;

    @Ignore
    boolean selected = false;

    @Ignore
    public OtpToken(Long id, Integer ordinal, String issuer, String account, String imagePath, OtpTokenType tokenType, String algorithm, String secret, Integer digits, Long counter, Integer period, EncryptionType encryptionType) {
        this.id = id;
        this.ordinal = ordinal;
        this.issuer = issuer;
        this.account = account;
        this.imagePath = imagePath;
        this.tokenType = tokenType;
        this.algorithm = algorithm;
        this.secret = secret;
        this.digits = digits;
        this.counter = counter;
        this.period = period;
        this.encryptionType = encryptionType;
    }

    public OtpToken() {
    }

    @NonNull
    @Override
    public String toString() {
        return "OtpToken{" + "id=" + id + ", ordinal=" + ordinal + ", issuer='" + issuer + '\'' + ", account='" + account + '\'' + ", imagePath='" + imagePath + '\'' + ", tokenType=" + tokenType + ", algorithm='" + algorithm + '\'' + ", secret='" + secret + '\'' + ", digits=" + digits + ", counter=" + counter + ", period=" + period + ", encryptionType=" + encryptionType + '}';
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public Integer getOrdinal() {
        return ordinal;
    }

    public void setOrdinal(Integer ordinal) {
        this.ordinal = ordinal;
    }

    public String getIssuer() {
        return issuer;
    }

    public void setIssuer(String issuer) {
        this.issuer = issuer;
    }

    public String getAccount() {
        return account;
    }

    public void setAccount(String account) {
        this.account = account;
    }

    public String getImagePath() {
        return imagePath;
    }

    public void setImagePath(String imagePath) {
        this.imagePath = imagePath;
    }

    public OtpTokenType getTokenType() {
        return tokenType;
    }

    public void setTokenType(OtpTokenType tokenType) {
        this.tokenType = tokenType;
    }

    public String getAlgorithm() {
        return algorithm;
    }

    public void setAlgorithm(String algorithm) {
        this.algorithm = algorithm;
    }

    public String getSecret() {
        return secret;
    }

    public void setSecret(String secret) {
        this.secret = secret;
    }

    public Integer getDigits() {
        return digits;
    }

    public void setDigits(Integer digits) {
        this.digits = digits;
    }

    public Long getCounter() {
        return counter;
    }

    public void setCounter(Long counter) {
        this.counter = counter;
    }

    public Integer getPeriod() {
        return period;
    }

    public void setPeriod(Integer period) {
        this.period = period;
    }

    public EncryptionType getEncryptionType() {
        return encryptionType;
    }

    public void setEncryptionType(EncryptionType encryptionType) {
        this.encryptionType = encryptionType;
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        OtpToken otpToken = (OtpToken) o;
        return Objects.equals(issuer, otpToken.issuer) && Objects.equals(secret, otpToken.secret) && Objects.equals(account, otpToken.account);
    }

    public boolean isPinned() {
        return pinned;
    }

    public boolean isSelected() {
        return selected;
    }

    public void setSelected(boolean selected) {
        this.selected = selected;
    }

    public void setPinned(boolean pinned) {
        this.pinned = pinned;
    }
}