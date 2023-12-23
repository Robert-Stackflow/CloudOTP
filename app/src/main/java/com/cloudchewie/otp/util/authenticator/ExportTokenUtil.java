package com.cloudchewie.otp.util.authenticator;

import android.content.Context;
import android.net.Uri;

import com.cloudchewie.otp.database.OtpTokenManager;
import com.cloudchewie.otp.entity.OtpToken;
import com.cloudchewie.otp.external.AESStringCypher;
import com.google.gson.Gson;

import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.io.OutputStream;
import java.io.PrintWriter;
import java.io.UnsupportedEncodingException;
import java.security.GeneralSecurityException;
import java.util.List;

public class ExportTokenUtil {
    public static void exportJsonFile(Context context, Uri fileUri) {
        try {
            OutputStream outputStream = context.getContentResolver().openOutputStream(fileUri);
            List<OtpToken> tokens = OtpTokenManager.getTokens();
            PrintWriter printWriter = new PrintWriter(outputStream);
            printWriter.write(new Gson().toJson(tokens));
            printWriter.flush();
            outputStream.flush();
            printWriter.close();
            outputStream.close();
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    public static void exportUriFile(Context context, Uri fileUri) {
        try {
            OutputStream outputStream = context.getContentResolver().openOutputStream(fileUri);
            PrintWriter printWriter = new PrintWriter(outputStream);
            List<OtpToken> tokens = OtpTokenManager.getTokens();
            for (OtpToken token : tokens)
                printWriter.println(OtpTokenParser.toUri(token).toString());
            printWriter.flush();
            outputStream.flush();
            printWriter.close();
            outputStream.close();
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    public static void exportJsonFile(Context context, Uri fileUri, List<OtpToken> otpTokens) {
        try {
            OutputStream outputStream = context.getContentResolver().openOutputStream(fileUri);
            PrintWriter printWriter = new PrintWriter(outputStream);
            printWriter.write(new Gson().toJson(otpTokens));
            printWriter.flush();
            outputStream.flush();
            printWriter.close();
            outputStream.close();
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    public static void exportUriFile(Context context, Uri fileUri, List<OtpToken> otpTokens) {
        try {
            OutputStream outputStream = context.getContentResolver().openOutputStream(fileUri);
            PrintWriter printWriter = new PrintWriter(outputStream);
            for (OtpToken token : otpTokens)
                printWriter.println(OtpTokenParser.toUri(token).toString());
            printWriter.flush();
            outputStream.flush();
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
        String json = new Gson().toJson(OtpTokenManager.getTokens());
        AESStringCypher.SecretKeys keys = AESStringCypher.generateKeyFromPassword(password, password);
        AESStringCypher.CipherTextIvMac toencrypt = AESStringCypher.encrypt(json, keys);
        return toencrypt.toString();
    }

    public static void exportEncryptFile(Context context, Uri fileUri, String password) {
        try {
            OutputStream outputStream = context.getContentResolver().openOutputStream(fileUri);
            PrintWriter printWriter = new PrintWriter(outputStream);
            printWriter.write(getEncryptedData(password));
            printWriter.flush();
            outputStream.flush();
            printWriter.close();
            outputStream.close();
        } catch (IOException | GeneralSecurityException e) {
            e.printStackTrace();
        }
    }

    public static String getEncryptedData(String password, List<OtpToken> otpTokens) throws GeneralSecurityException, UnsupportedEncodingException {
        String json = new Gson().toJson(otpTokens);
        AESStringCypher.SecretKeys keys = AESStringCypher.generateKeyFromPassword(password, password);
        AESStringCypher.CipherTextIvMac toencrypt = AESStringCypher.encrypt(json, keys);
        return toencrypt.toString();
    }

    public static void exportEncryptFile(Context context, Uri fileUri, String password, List<OtpToken> otpTokens) {
        try {
            OutputStream outputStream = context.getContentResolver().openOutputStream(fileUri);
            PrintWriter printWriter = new PrintWriter(outputStream);
            printWriter.write(getEncryptedData(password, otpTokens));
            printWriter.flush();
            outputStream.flush();
            printWriter.close();
            outputStream.close();
        } catch (IOException | GeneralSecurityException e) {
            e.printStackTrace();
        }
    }
}
