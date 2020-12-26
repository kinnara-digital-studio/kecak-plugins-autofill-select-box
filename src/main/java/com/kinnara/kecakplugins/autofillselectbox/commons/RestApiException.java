package com.kinnara.kecakplugins.autofillselectbox.commons;

public class RestApiException extends Exception {
    private final int errorCode;

    public RestApiException(int errorCode, String message) {
        super(message);
        this.errorCode = errorCode;
    }

    public RestApiException(int errorCode, Throwable cause) {
        super(cause);
        this.errorCode = errorCode;
    }

    public int getErrorCode() {
        return errorCode;
    }
}
