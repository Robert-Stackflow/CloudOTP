package com.cloudchewie.util.system;

import android.content.Context;
import android.content.Intent;
import android.net.Uri;

import androidx.annotation.NonNull;

import java.util.HashMap;
import java.util.Map;

public class ShareUtil {
    private static String BAIDUMAP = "com.baidu.BaiduMap";

    /**
     * 获取受支持的分享应用包名列表
     *
     * @return 应用包名列表
     */
    @NonNull
    public static Map<String, String> getSupportedPackages() {
        Map<String, String> appPackageNameMap = new HashMap<>();
        appPackageNameMap.put("微信", "com.tencent.mm");
        appPackageNameMap.put("QQ", "com.tencent.mobileqq");
        appPackageNameMap.put("QQ空间", "com.qzone");
        appPackageNameMap.put("微博", "com.sina.weibo");
        appPackageNameMap.put("TIM", "com.tencent.tim");
        return appPackageNameMap;
    }

    public static String getBaiduMapPackageName() {
        return BAIDUMAP;
    }

    public static void shareText(Context context, String text, String tip) {
        Intent sendIntent = new Intent();
        sendIntent.setAction(Intent.ACTION_SEND);
        sendIntent.putExtra(Intent.EXTRA_TEXT, text);
        sendIntent.setType("text/plain");
        context.startActivity(Intent.createChooser(sendIntent, tip));
    }

    public static void shareFile(Context context, Uri uri, String mimeType, String tip) {
        Intent sendIntent = new Intent();
        sendIntent.setAction(Intent.ACTION_SEND);
        sendIntent.putExtra(Intent.EXTRA_STREAM, uri);
        sendIntent.setType(mimeType);
        context.startActivity(Intent.createChooser(sendIntent, tip));
    }
}
