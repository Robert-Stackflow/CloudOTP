package com.cloudchewie.otp.util.authenticator;

import android.content.Context;
import android.net.Uri;

import com.cloudchewie.otp.entity.OtpToken;
import com.cloudchewie.otp.external.AESStringCypher;
import com.cloudchewie.otp.util.database.LocalStorage;
import com.google.gson.Gson;

import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.io.OutputStream;
import java.io.PrintWriter;
import java.io.UnsupportedEncodingException;
import java.nio.charset.StandardCharsets;
import java.security.GeneralSecurityException;
import java.util.List;

public class ExportTokenUtil {
    public static void exportJsonFile(Context context, Uri fileUri) {
        try {
            OutputStream outputStream = context.getContentResolver().openOutputStream(fileUri, "w");
            List<OtpToken> tokens = LocalStorage.getAppDatabase().otpTokenDao().getAll();
            outputStream.write(new Gson().toJson(tokens.toArray()).getBytes(StandardCharsets.UTF_8));
            outputStream.close();
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    public static void exportUriFile(Context context, Uri fileUri) {
        try {
            OutputStream outputStream = context.getContentResolver().openOutputStream(fileUri, "w");
            PrintWriter printWriter = new PrintWriter(outputStream);
            List<OtpToken> tokens = LocalStorage.getAppDatabase().otpTokenDao().getAll();
            for (OtpToken token : tokens)
                printWriter.println(OtpTokenParser.toUri(token).toString());
            printWriter.flush();
            printWriter.close();
            outputStream.close();
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    public static File createCachedFileFromEncryptString(String text,
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

    public static String getEncryptedData(String password) throws GeneralSecurityException, UnsupportedEncodingException {
        String json = new Gson().toJson(LocalStorage.getAppDatabase().otpTokenDao().getAll());
        AESStringCypher.SecretKeys keys = AESStringCypher.generateKeyFromPassword(password, password);
        AESStringCypher.CipherTextIvMac toencrypt = AESStringCypher.encrypt(json, keys);
        return toencrypt.toString();
    }

    public static void exportEncryptFile(Context context, Uri fileUri,String password) {
        try {
            OutputStream outputStream = context.getContentResolver().openOutputStream(fileUri, "w");
            PrintWriter printWriter = new PrintWriter(outputStream);
            printWriter.write(getEncryptedData(password));
            printWriter.flush();
            printWriter.close();
            outputStream.close();
        } catch (IOException | GeneralSecurityException e) {
            e.printStackTrace();
        }
    }
}
