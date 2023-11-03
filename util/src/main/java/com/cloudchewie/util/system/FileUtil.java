package com.cloudchewie.util.system;

import android.annotation.SuppressLint;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.content.pm.ResolveInfo;
import android.net.Uri;
import android.os.Build;
import android.os.Environment;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.core.content.FileProvider;

import org.jetbrains.annotations.Contract;

import java.io.File;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.List;
import java.util.Locale;

public class FileUtil {
    public static boolean detectIntent(@NonNull Context ctx, Intent intent) {
        final PackageManager packageManager = ctx.getPackageManager();
        @SuppressLint("QueryPermissionsNeeded")
        List<ResolveInfo> list = packageManager.queryIntentActivities(
                intent, PackageManager.MATCH_DEFAULT_ONLY);
        return list.size() > 0;
    }

    @NonNull
    @Contract("_, _ -> new")
    public static File createFile(String prefix, String suffix) {
        File folder;
        if (FileUtil.existSDCard())
            folder = new File(Environment.getExternalStorageDirectory(), "/DCIM/camera/");
        else folder = Environment.getDataDirectory();
        if (!folder.exists() || !folder.isDirectory()) {
            boolean __ = folder.mkdirs();
        }
        SimpleDateFormat dateFormat = new SimpleDateFormat("yyyyMMdd_HHmmss", Locale.CHINA);
        String filename = prefix + dateFormat.format(new Date(System.currentTimeMillis())) + suffix;
        return new File(folder, filename);
    }

    @NonNull
    public static String getFileProviderName(@NonNull Context context) {
        return context.getPackageName() + ".provider";
    }

    @NonNull
    @Contract("_, _, _ -> new")
    public static File createFileInternal(@NonNull Context context, String prefix, String suffix) {
        File folder = new File(context.getFilesDir().getAbsolutePath());
        if (!folder.exists() || !folder.isDirectory()) {
            boolean __ = folder.mkdirs();
        }
        SimpleDateFormat dateFormat = new SimpleDateFormat("yyyyMMdd_HHmmss", Locale.CHINA);
        String filename = prefix + dateFormat.format(new Date(System.currentTimeMillis())) + suffix;
        return new File(folder, filename);
    }

    public static boolean existSDCard() {
        return Environment.getExternalStorageState().equals(Environment.MEDIA_MOUNTED);
    }

    @NonNull
    public static Intent getAllIntent(Uri uri) {
        Intent intent = new Intent(Intent.ACTION_VIEW);
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
        intent.setDataAndType(uri, "*/*");
        return intent;
    }

    @NonNull
    public static Intent getApkFileIntent(Uri uri) {
        Intent intent = new Intent(Intent.ACTION_VIEW);
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
        intent.setDataAndType(uri, "application/vnd.android.package-archive");
        return intent;
    }

    @NonNull
    public static Intent getVideoFileIntent(Uri uri) {
        Intent intent = new Intent(Intent.ACTION_VIEW);
        intent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP);
        intent.putExtra("oneshot", 0);
        intent.putExtra("configchange", 0);
        intent.setDataAndType(uri, "video/*");
        return intent;
    }

    @NonNull
    public static Intent getAudioFileIntent(Uri uri) {
        Intent intent = new Intent(Intent.ACTION_VIEW);
        intent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP);
        intent.putExtra("oneshot", 0);
        intent.putExtra("configchange", 0);
        intent.setDataAndType(uri, "audio/*");
        return intent;
    }

    @NonNull
    public static Intent getHtmlFileIntent(@NonNull Uri uri) {
        Uri uri1 = Uri.parse(uri.getPath()).buildUpon().encodedAuthority("com.android.htmlfileprovider").scheme("content").encodedPath(uri.getPath()).build();
        Intent intent = new Intent(Intent.ACTION_VIEW);
        intent.setDataAndType(uri1, "text/html");
        return intent;
    }

    @NonNull
    public static Intent getImageFileIntent(Uri uri) {
        Intent intent = new Intent(Intent.ACTION_VIEW);
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
        intent.setDataAndType(uri, "image/*");
        return intent;
    }

    @NonNull
    public static Intent getPptFileIntent(Uri uri) {
        Intent intent = new Intent(Intent.ACTION_VIEW);
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
        intent.setDataAndType(uri, "application/vnd.ms-powerpoint");
        return intent;
    }

    @NonNull
    public static Intent getExcelFileIntent(Uri uri) {
        Intent intent = new Intent(Intent.ACTION_VIEW);
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
        intent.setDataAndType(uri, "application/vnd.ms-excel");
        return intent;
    }

    @NonNull
    public static Intent getWordFileIntent(Uri uri) {
        Intent intent = new Intent(Intent.ACTION_VIEW);
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
        intent.setDataAndType(uri, "application/msword");
        return intent;
    }

    @NonNull
    public static Intent getChmFileIntent(Uri uri) {
        Intent intent = new Intent(Intent.ACTION_VIEW);
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
        intent.setDataAndType(uri, "application/x-chm");
        return intent;
    }

    @NonNull
    public static Intent getTextFileIntent(Uri uri) {
        Intent intent = new Intent(Intent.ACTION_VIEW);
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
        intent.setDataAndType(uri, "text/plain");
        return intent;
    }

    @NonNull
    public static Intent getPdfFileIntent(Uri uri) {
        Intent intent = new Intent(Intent.ACTION_VIEW);
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
        intent.setDataAndType(uri, "application/pdf");
        return intent;
    }

    @Nullable
    public static Intent openFile(Context context, String filePath, @NonNull String mimeType) {
        Intent intent = new Intent();
        Uri uri;
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            intent.setFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION);
            uri = FileProvider.getUriForFile(context, context.getApplicationContext().getPackageName() + ".provider", new File(filePath.replace("file://", "")));
        } else {
            uri = Uri.parse(filePath);
        }
        switch (mimeType.toLowerCase(Locale.getDefault())) {
            case "m4a":
            case "mp3":
            case "mid":
            case "xmf":
            case "ogg":
            case "wav":
                return getAudioFileIntent(uri);
            case "3gp":
            case "mp4":
                return getVideoFileIntent(uri);
            case "jpg":
            case "gif":
            case "png":
            case "jpeg":
            case "bmp":
                return getImageFileIntent(uri);
            case "apk":
                return getApkFileIntent(uri);
            case "ppt":
                return getPptFileIntent(uri);
            case "xls":
                return getExcelFileIntent(uri);
            case "doc":
                return getWordFileIntent(uri);
            case "pdf":
                return getPdfFileIntent(uri);
            case "chm":
                return getChmFileIntent(uri);
            case "txt":
                return getTextFileIntent(uri);
            default:
                return getAllIntent(uri);
        }
    }
}
