package com.cloudchewie.util.system;

import android.content.Context;
import android.content.res.AssetManager;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;

import androidx.annotation.NonNull;

import org.jetbrains.annotations.Contract;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;

public class AssetsUtil {
    /**
     * 获取assets目录下的图片
     *
     * @param context  上下文
     * @param fileName 文件名
     * @return Bitmap图片
     */
    public static Bitmap getImageFromAssetsFile(@NonNull Context context, String fileName) {
        Bitmap bitmap = null;
        AssetManager assetManager = context.getAssets();
        try {
            InputStream is = assetManager.open(fileName);
            bitmap = BitmapFactory.decodeStream(is);
            is.close();
        } catch (IOException e) {
            e.printStackTrace();
        }

        return bitmap;
    }

    /**
     * 获取assets目录下的单个文件
     * 这种方式只能用于webview加载读取文件夹，不能直接取路径
     *
     * @param context  上下文
     * @param fileName 文件夹名
     * @return File
     */
    @NonNull
    @Contract("_, _ -> new")
    public static File getFileFromAssetsFile(Context context, String fileName) {
        String path = "file:///android_asset/" + fileName;
        return new File(path);
    }

    /**
     * 获取assets目录下所有文件
     *
     * @param context 上下文
     * @param path    文件地址
     * @return 文件列表
     */
    public static String[] getFilesFromAssets(@NonNull Context context, String path) {
        AssetManager assetManager = context.getAssets();
        String[] files = null;
        try {
            files = assetManager.list(path);
        } catch (IOException e) {
            e.printStackTrace();
        }

        return files;
    }

    /**
     * 将assets下的文件放到sd指定目录下
     *
     * @param context    上下文
     * @param assetsPath assets下的路径
     */
    public static void putAssetsToSDCard(Context context, String assetsPath) {
        putAssetsToSDCard(context, assetsPath, context.getExternalFilesDir(null).getAbsolutePath());
    }

    /**
     * 将assets下的文件放到sd指定目录下
     *
     * @param context    上下文
     * @param assetsPath assets下的路径
     * @param sdCardPath sd卡的路径
     */
    public static void putAssetsToSDCard(@NonNull Context context, String assetsPath, String sdCardPath) {
        AssetManager assetManager = context.getAssets();
        try {
            String[] files = assetManager.list(assetsPath);
            if (files.length == 0) {
                InputStream is = assetManager.open(assetsPath);
                byte[] mByte = new byte[1024];
                int bt;
                File file = new File(sdCardPath + File.separator
                        + assetsPath.substring(assetsPath.lastIndexOf('/')));
                if (!file.exists()) {
                    boolean __ = file.createNewFile();
                } else {
                    return;
                }
                FileOutputStream fos = new FileOutputStream(file);
                while ((bt = is.read(mByte)) != -1) {
                    fos.write(mByte, 0, bt);
                }
                fos.flush();
                is.close();
                fos.close();
            } else {
                sdCardPath = sdCardPath + File.separator + assetsPath;
                File file = new File(sdCardPath);
                if (!file.exists()) {
                    boolean __ = file.mkdirs();
                }
                for (String stringFile : files)
                    putAssetsToSDCard(context, assetsPath + File.separator + stringFile, sdCardPath);
            }
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    /**
     * 获取纯文本文件的内容
     *
     * @param context  Context对象
     * @param fileName 文件路径
     * @return 文件内容
     */
    @NonNull
    public static String getTextFileContent(@NonNull Context context, String fileName) {
        StringBuilder stringBuilder = new StringBuilder();
        AssetManager assetManager = context.getAssets();
        try {
            BufferedReader bufferedReader = new BufferedReader(new InputStreamReader(assetManager.open(fileName),
                    StandardCharsets.UTF_8));
            String line;
            while ((line = bufferedReader.readLine()) != null)
                stringBuilder.append(line);
        } catch (IOException e) {
            e.printStackTrace();
        }
        return stringBuilder.toString();
    }
}
