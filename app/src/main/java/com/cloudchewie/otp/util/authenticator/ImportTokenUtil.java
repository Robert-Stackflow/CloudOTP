package com.cloudchewie.otp.util.authenticator;

import android.content.Context;
import android.net.Uri;

import com.cloudchewie.otp.entity.ImportAnalysis;
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
import java.util.Collections;
import java.util.List;

public class ImportTokenUtil {

    private static Gson gson = new Gson();

    public static ImportAnalysis importJsonFile(Context context, Uri fileUri) {
        ImportAnalysis importAnalysis = new ImportAnalysis();
        try {
            InputStream inputStream = context.getContentResolver().openInputStream(fileUri);
            BufferedReader bufferedReader = new BufferedReader(new InputStreamReader(inputStream));
            StringBuilder content = new StringBuilder();
            String line;
            while ((line = bufferedReader.readLine()) != null)
                content.append(line.trim());
            List<OtpToken> otpTokens = jsonToTokenList(content.toString());
            bufferedReader.close();
            inputStream.close();
            importAnalysis.setFoundTokenCount(otpTokens.size());
            importAnalysis.setRealAddTokenCount(mergeTokens(otpTokens));
        } catch (IOException e) {
            e.printStackTrace();
        }
        return importAnalysis;
    }

    public static ImportAnalysis importUriFile(Context context, Uri fileUri) {
        ImportAnalysis importAnalysis = new ImportAnalysis();
        try {
            InputStream inputStream = context.getContentResolver().openInputStream(fileUri);
            BufferedReader bufferedReader = new BufferedReader(new InputStreamReader(inputStream));
            String line;
            int index = 0;
            List<OtpToken> otpTokens = new ArrayList<>();
            while ((line = bufferedReader.readLine()) != null) {
                try {
                    OtpToken token = OtpTokenParser.createFromUri(Uri.parse((line.trim())));
                    importAnalysis.increseFoundTokenCount();
                    otpTokens.add(token);
                    index++;
                } catch (Exception ignored) {
                    importAnalysis.increseSkipLineCount();
                }
            }
            bufferedReader.close();
            inputStream.close();
            importAnalysis.setRealAddTokenCount(mergeTokens(otpTokens));
        } catch (IOException e) {
            e.printStackTrace();
        }
        return importAnalysis;
    }

    public static ImportAnalysis importEncryptFile(Context context, Uri fileUri, String secret) throws GeneralSecurityException, IOException {
        ImportAnalysis importAnalysis = new ImportAnalysis();
        File file = UriUtil.getFileFromURI(context, fileUri);
        if (file == null) throw new IOException();
        byte[] bytes = new byte[(int) file.length()];
        new FileInputStream(file).read(bytes);
        List<OtpToken> otpTokens = ImportTokenUtil.jsonToTokenList(AESStringCypher.decryptString(new AESStringCypher.CipherTextIvMac(new String(bytes)), AESStringCypher.generateKeyFromPassword(secret, secret)));
        importAnalysis.setFoundTokenCount(otpTokens.size());
        importAnalysis.setRealAddTokenCount(mergeTokens(otpTokens));
        return importAnalysis;
    }

    public static List<OtpToken> jsonToTokenList(String json) {
        return gson.fromJson(json, new TypeToken<List<OtpToken>>() {
        }.getType());
    }

    public static void mergeToken(OtpToken token) {
        mergeTokens(Collections.singletonList(token));
    }

    public static int mergeTokens(List<OtpToken> tokenList) {
        List<OtpToken> already = LocalStorage.getAppDatabase().otpTokenDao().getAll();
        List<OtpToken> newTokenList = new ArrayList<>();
        for (OtpToken otpToken : tokenList) {
            if (!already.contains(otpToken) && !newTokenList.contains(otpToken)) {
                newTokenList.add(otpToken);
            }
        }
        LocalStorage.getAppDatabase().otpTokenDao().insertAll(newTokenList);
        LiveEventBus.get(EventBusCode.CHANGE_TOKEN.getKey()).post("change");
        return newTokenList.size();
    }

}
