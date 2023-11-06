package com.cloudchewie.otp.util.authenticator;

import android.content.Context;
import android.net.Uri;

import com.cloudchewie.otp.entity.OtpToken;
import com.cloudchewie.otp.external.AESStringCypher;
import com.cloudchewie.otp.util.database.LocalStorage;
import com.cloudchewie.otp.util.enumeration.EventBusCode;
import com.cloudchewie.util.system.UriUtil;
import com.google.gson.Gson;
import com.google.gson.reflect.TypeToken;
import com.jeremyliao.liveeventbus.LiveEventBus;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.security.GeneralSecurityException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

public class ImportTokenUtil {

    private static Gson gson = new Gson();

    public static void importJsonFile(Context context, Uri fileUri) {
        try {
            InputStream inputStream = context.getContentResolver().openInputStream(fileUri);
            BufferedReader bufferedReader = new BufferedReader(new InputStreamReader(inputStream));
            List<OtpToken> otpTokens = Arrays.asList(new Gson().fromJson(bufferedReader.readLine(), OtpToken[].class));
            bufferedReader.close();
            inputStream.close();
            mergeTokens(otpTokens);
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    public static void importUriFile(Context context, Uri fileUri) {
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
            mergeTokens(otpTokens);
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    public static void importEncryptFile(Context context, Uri fileUri, String secret) throws GeneralSecurityException, IOException {
        File file = UriUtil.getFileFromURI(context, fileUri);
        if (file == null) throw new IOException();
        byte[] bytes = new byte[(int) file.length()];
        new FileInputStream(file).read(bytes);
        mergeTokens(ImportTokenUtil.jsonToTokenList(AESStringCypher.decryptString(new AESStringCypher.CipherTextIvMac(new String(bytes)), AESStringCypher.generateKeyFromPassword(secret, secret))));
    }

    public static List<OtpToken> jsonToTokenList(String json) {
        return gson.fromJson(json, new TypeToken<List<OtpToken>>() {
        }.getType());
    }

    public static void mergeTokens(List<OtpToken> tokenList) {
        List<OtpToken> already = LocalStorage.getAppDatabase().otpTokenDao().getAll();
        List<OtpToken> newTokenList = new ArrayList<>();
        for (OtpToken otpToken : tokenList) {
            if (!already.contains(otpToken)) {
                newTokenList.add(otpToken);
            }
        }
        LocalStorage.getAppDatabase().otpTokenDao().insertAll(newTokenList);
        LiveEventBus.get(EventBusCode.CHANGE_TOKEN.getKey()).post("change");
    }

}
