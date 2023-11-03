package com.cloudchewie.otp.util.authenticator;

import android.content.Context;
import android.net.Uri;

import com.cloudchewie.otp.entity.OtpToken;
import com.cloudchewie.otp.util.database.LocalStorage;
import com.google.gson.Gson;

import java.io.IOException;
import java.io.OutputStream;
import java.io.PrintWriter;
import java.nio.charset.StandardCharsets;
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

    public static void exportKeyUriFile(Context context, Uri fileUri) {
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
}
