package com.cloudchewie.otp.util.authenticator;

import android.content.Context;
import android.net.Uri;

import com.cloudchewie.otp.entity.OtpToken;
import com.cloudchewie.otp.util.database.LocalStorage;
import com.google.gson.Gson;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

public class ImportTokenUtil {
    public static void importJsonFile(Context context, Uri fileUri) {
        try {
            InputStream inputStream = context.getContentResolver().openInputStream(fileUri);
            BufferedReader bufferedReader = new BufferedReader(new InputStreamReader(inputStream));
            List<OtpToken> otpTokens = Arrays.asList(new Gson().fromJson(bufferedReader.readLine(), OtpToken[].class));
            bufferedReader.close();
            inputStream.close();
            LocalStorage.getAppDatabase().otpTokenDao().insertAll(otpTokens);
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    public static void importKeyUriFile(Context context, Uri fileUri) {
        long currentLastOrdinal = LocalStorage.getAppDatabase().otpTokenDao().getLastOrdinal() != null ? LocalStorage.getAppDatabase().otpTokenDao().getLastOrdinal() : 0L;
        try {
            InputStream inputStream = context.getContentResolver().openInputStream(fileUri);
            BufferedReader bufferedReader = new BufferedReader(new InputStreamReader(inputStream));
            String line;
            int index = 0;
            List<OtpToken> otpTokens = new ArrayList<>();
            while ((line = bufferedReader.readLine()) != null) {
                OtpToken token = OtpTokenParser.createFromUri(Uri.parse((line.trim())));
                token.setOrdinal(currentLastOrdinal + index + 1);
                otpTokens.add(token);
                index++;
            }
            bufferedReader.close();
            inputStream.close();
            LocalStorage.getAppDatabase().otpTokenDao().insertAll(otpTokens);
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

}
