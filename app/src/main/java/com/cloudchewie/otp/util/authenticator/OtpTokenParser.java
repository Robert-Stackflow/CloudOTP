package com.cloudchewie.otp.util.authenticator;

import android.net.Uri;
import android.text.TextUtils;

import com.cloudchewie.otp.entity.OtpToken;
import com.cloudchewie.otp.util.enumeration.EncryptionType;
import com.cloudchewie.otp.util.enumeration.OtpTokenType;

import java.security.NoSuchAlgorithmException;
import java.util.Locale;
import java.util.Objects;

import javax.crypto.Mac;

public class OtpTokenParser {
    public static Uri toUri(OtpToken token) {
        String labelAndIssuer;
        if (!TextUtils.isEmpty(token.getIssuer())) {
            labelAndIssuer = token.getIssuer() + ":" + token.getAccount();
        } else {
            labelAndIssuer = token.getAccount();
        }
        Uri.Builder builder = new Uri.Builder().scheme("otpauth").path(labelAndIssuer).appendQueryParameter("secret", token.getSecret()).appendQueryParameter("algorithm", token.getAlgorithm()).appendQueryParameter("digits", token.getDigits().toString()).appendQueryParameter("period", token.getPeriod().toString());
        switch (token.getTokenType()) {
            case HOTP:
                builder.authority("hotp");
                builder.appendQueryParameter("counter", String.valueOf((token.getCounter() + 1)));
                break;
            case TOTP:
                builder.authority("totp");
                break;
        }
        return builder.build();
    }

    public static OtpToken createFromUri(Uri uri) {
        if (!Objects.equals(uri.getScheme(), "otpauth"))
            throw new IllegalArgumentException("URI does not starts with otpauth");
        OtpTokenType type;
        switch (Objects.requireNonNull(uri.getAuthority())) {
            case "totp":
                type = OtpTokenType.TOTP;
                break;
            case "hotp":
                type = OtpTokenType.HOTP;
                break;
            default:
                throw new IllegalArgumentException("URI does not contain totp or hotp type");
        }
        if (uri.getPath() == null) {
            throw new IllegalArgumentException("Token path is null");
        }
        String path = uri.getPath();
        int j = 0;
        while (path.charAt(j) == '/') {
            j++;
        }
        path = path.substring(j);
        if (path.isEmpty()) {
            throw new IllegalArgumentException("Token path is empty");
        }
        int i = path.indexOf(':');
        String issuerExt;
        if (i < 0) issuerExt = "";
        else issuerExt = path.substring(0, i);
        String issuerInt = uri.getQueryParameter("issuer");
        String issuer;
        if (!TextUtils.isEmpty(issuerInt)) issuer = issuerInt;
        else issuer = issuerExt;
        String label;
        if (i >= 0) label = path.substring(i + 1);
        else label = path;

        String algo = uri.getQueryParameter("algorithm");
        if (algo == null) algo = "sha1";
        algo = algo.toUpperCase(Locale.getDefault());

        try {
            Mac.getInstance("Hmac$algo");
        } catch (NoSuchAlgorithmException ignored) {
        }

        String d = uri.getQueryParameter("digits");
        if (d == null) {
            if (issuerExt.equals("Steam")) d = "5";
            else d = "6";
        }
        int digits = Integer.parseInt(d);
        if (!issuerExt.equals("Steam") && digits != 6 && digits != 7 && digits != 8 && digits != 5)
            throw new IllegalArgumentException("Digits must be 5 to 8");

        String p = uri.getQueryParameter("period");
        if (p == null) p = "30";
        int period = Integer.parseInt(p);

        long counter;
        if (type == OtpTokenType.HOTP) {
            String c = uri.getQueryParameter("counter");
            if (c == null) c = "0";
            counter = Long.parseLong(c) - 1;
        } else {
            counter = 0;
        }
        String secret = uri.getQueryParameter("secret");
        if (secret == null) {
            throw new IllegalArgumentException("Secret is null");
        }
        String image = uri.getQueryParameter("image");
        return new OtpToken(null, -System.currentTimeMillis(), issuer, label, image, type, algo, secret, digits, counter, period, EncryptionType.PLAIN_TEXT);
    }
}
