package com.cloudchewie.otp.external;

import android.content.Context;
import android.content.SharedPreferences;

import com.google.gson.Gson;
import com.google.gson.reflect.TypeToken;

import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.io.UnsupportedEncodingException;
import java.lang.reflect.Type;
import java.security.GeneralSecurityException;
import java.util.HashMap;

public class Utils {
    private static Gson gson = new Gson();

    public static File createCachedFileFromTokenString(String text,
                                                       String fileName,
                                                       Context context)
            throws IOException {
        File file = new File(context.getCacheDir(), fileName);
        FileWriter fw = new FileWriter(file);
        fw.write(text);
        fw.flush();
        fw.close();
        return file;
    }

    public static String encryptStringWithAES(String toEncrypt, String password)
            throws GeneralSecurityException, UnsupportedEncodingException {
        AESStringCypher.SecretKeys keys = AESStringCypher.generateKeyFromPassword(password, password);
        AESStringCypher.CipherTextIvMac encrypted = AESStringCypher.encrypt(toEncrypt, keys);
        return "";
    }

    public static String transformStringHashMapToJson(HashMap<String, String> hashmap) {
        Type hashmapStringType = new TypeToken<HashMap<String, String>>(){}.getType();
        return gson.toJson(hashmap, hashmapStringType);
    }

    public static HashMap<String, String> transformJsonToStringHashMap(String json) {
        Type hashmapStringType = new TypeToken<HashMap<String, String>>(){}.getType();
        return gson.fromJson(json, hashmapStringType);
    }

    public static void overwriteAndroidSharedPrefereces(HashMap<String, String> hashmap,
                                                        SharedPreferences prefs) {
        SharedPreferences.Editor editor = prefs.edit();
        editor.clear();
        for (String s : hashmap.keySet()) {
            editor.putString(s, hashmap.get(s));
        }
        editor.apply();
    }

    public static boolean isRemoteDateNewer(long localDate, long remoteDate) {
        return remoteDate > localDate;
    }
}
