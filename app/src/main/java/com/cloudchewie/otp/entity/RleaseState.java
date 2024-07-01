package com.cloudchewie.otp.entity;

import java.io.IOException;

/**
 * State of the release asset.
 */
public enum RleaseState {
    OPEN, UPLOADED;

    public String toValue() {
        switch (this) {
            case OPEN:
                return "open";
            case UPLOADED:
                return "uploaded";
        }
        return null;
    }

    public static RleaseState forValue(String value) throws IOException {
        if (value.equals("open")) return OPEN;
        if (value.equals("uploaded")) return UPLOADED;
        throw new IOException("Cannot deserialize State");
    }
}
