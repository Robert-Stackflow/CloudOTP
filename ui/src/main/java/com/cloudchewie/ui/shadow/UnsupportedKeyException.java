package com.cloudchewie.ui.shadow;

public class UnsupportedKeyException extends RuntimeException {

    public UnsupportedKeyException() {
    }

    public UnsupportedKeyException(String message) {
        super(message);
    }

    public UnsupportedKeyException(String message, Throwable cause) {
        super(message, cause);
    }

    public UnsupportedKeyException(Throwable cause) {
        super(cause);
    }
}
