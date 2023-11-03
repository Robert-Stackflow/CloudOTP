package com.cloudchewie.util.ui;

import android.text.TextUtils;

import androidx.annotation.NonNull;

import java.util.ArrayList;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class RichEditorUtil {

    /**
     * 获取富文本中的图片链接
     */
    @NonNull
    public static ArrayList<String> getImageUrls(String html) {
        ArrayList<String> imageSrcList = new ArrayList<>();
        if (TextUtils.isEmpty(html))
            return imageSrcList;
        Pattern p = Pattern.compile("<img\\b[^>]*\\bsrc\\b\\s*=\\s*(['\"])?([^'\"\n\r\f>]+(\\.jpg|\\.bmp|\\.eps|\\.gif|\\.mif|\\.miff|\\.png|\\.tif|\\.tiff|\\.svg|\\.wmf|\\.jpe|\\.jpeg|\\.dib|\\.ico|\\.tga|\\.cut|\\.pic|\\b)\\b)[^>]*>", Pattern.CASE_INSENSITIVE);
        Matcher m = p.matcher(html);
        String quote;
        String src;
        while (m.find()) {
            quote = m.group(1);
            src = (quote == null || quote.trim().length() == 0) ? m.group(2).split("//s+")[0] : m.group(2);
            imageSrcList.add(src);
        }
        return imageSrcList;
    }

    /**
     * 获取富文本中的纯文本内容
     */
    @NonNull
    public static String getPlainText(String html) {
        if (TextUtils.isEmpty(html)) {
            return "";
        } else {
            String regFormat = "\\s*|\t|\r|\n";
            String regTag = "<[^>]*>";
            String text = html.replaceAll(regFormat, "").replaceAll(regTag, "");
            text = text.replace("&nbsp;", "");
            return text;
        }
    }

    /**
     * 判断富文本的实际显示内容是否为空
     */
    public static boolean isEmpty(String html) {
        return TextUtils.isEmpty(getPlainText(html)) && getImageUrls(html).size() == 0;
    }
}