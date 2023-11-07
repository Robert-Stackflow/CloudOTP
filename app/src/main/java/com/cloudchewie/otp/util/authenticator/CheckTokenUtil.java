package com.cloudchewie.otp.util.authenticator;

import com.cloudchewie.otp.entity.OtpToken;

import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class CheckTokenUtil {
    public static boolean checkToken(OtpToken token) {
        if (token.getSecret() == null || token.getSecret().isEmpty() || !isSecretLegal(token.getSecret()) || !isSecretLegal(token.getSecret())) {
            return false;
        }
//        if(isIntervalTooLong(token.getPeriod()){
//            return false;
//        }
        return true;
    }

    public static boolean isSecretLegal(String str) {
        Pattern p = Pattern.compile("[a-zA-Z|0-9]+");
        Matcher m = p.matcher(str);
        return m.matches();
    }

    public static boolean isSecretBase32(String str) {
        try {
            Base32String.decode(str);
        } catch (Base32String.DecodingException e) {
            return false;
        }
        return true;
    }

    public static boolean isIntervalTooLong(String str) {
        try {
            Integer i = Integer.parseInt(str);
        } catch (NumberFormatException e) {
            return true;
        }
        return false;
    }

    public static boolean isCounterTooLong(String str) {
        try {
            Long i = Long.parseLong(str);
        } catch (NumberFormatException e) {
            return true;
        }
        return false;
    }
}
