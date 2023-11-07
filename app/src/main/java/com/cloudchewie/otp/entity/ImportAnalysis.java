package com.cloudchewie.otp.entity;

import androidx.annotation.NonNull;

public class ImportAnalysis {
    int skipLineCount;
    int foundTokenCount;
    int realAddTokenCount;

    public ImportAnalysis() {
    }

    public ImportAnalysis(int skipLineCount, int foundTokenCount, int realAddTokenCount) {
        this.skipLineCount = skipLineCount;
        this.foundTokenCount = foundTokenCount;
        this.realAddTokenCount = realAddTokenCount;
    }

    @NonNull
    @Override
    public String toString() {
        return "ImportAnalysis{" +
                "skipLineCount=" + skipLineCount +
                ", foundTokenCount=" + foundTokenCount +
                ", realAddTokenCount=" + realAddTokenCount +
                '}';
    }

    public int getSkipLineCount() {
        return skipLineCount;
    }

    public void increseSkipLineCount() {
        this.skipLineCount++;
    }

    public void increseFoundTokenCount() {
        this.foundTokenCount++;
    }

    public void setSkipLineCount(int skipLineCount) {
        this.skipLineCount = skipLineCount;
    }

    public int getFoundTokenCount() {
        return foundTokenCount;
    }

    public void setFoundTokenCount(int foundTokenCount) {
        this.foundTokenCount = foundTokenCount;
    }

    public int getRealAddTokenCount() {
        return realAddTokenCount;
    }

    public void setRealAddTokenCount(int realAddTokenCount) {
        this.realAddTokenCount = realAddTokenCount;
    }
}
