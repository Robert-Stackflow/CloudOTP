package com.cloudchewie.otp.util;

import android.app.Activity;
import android.content.ActivityNotFoundException;
import android.content.Intent;

import com.cloudchewie.ui.custom.IToast;
import com.cloudchewie.util.basic.DateFormatUtil;

import java.util.Date;

public class ExploreUtil {
    public static void performFileSearch(Activity activity, int requestCode) {
        Intent intent = new Intent(Intent.ACTION_OPEN_DOCUMENT);
        intent.addCategory(Intent.CATEGORY_OPENABLE);
        intent.setType("*/*");
        try {
            activity.startActivityForResult(intent, requestCode);
        } catch (ActivityNotFoundException e) {
            IToast.showBottom(activity, activity.getString(com.cloudchewie.util.R.string.permission_fail_explorer));
        }
    }


    public static void createFile(Activity activity, String mimeType, String fileName, String fileExtension, int requestCode, boolean appendTimestamp) {
        Intent intent = new Intent(Intent.ACTION_CREATE_DOCUMENT);
        intent.addCategory(Intent.CATEGORY_OPENABLE);
        String fullName = fileName;
        if (appendTimestamp) {
            fullName += DateFormatUtil.getSimpleDateFormat(DateFormatUtil.FULL_FORMAT).format(new Date());
        }
        fullName += ".";
        fullName += fileExtension;
        intent.setType(mimeType);
        intent.putExtra(Intent.EXTRA_TITLE, fullName);
        try {
            activity.startActivityForResult(intent, requestCode);
        } catch (ActivityNotFoundException e) {
            IToast.showBottom(activity, activity.getString(com.cloudchewie.util.R.string.permission_fail_explorer));
        }
    }
}
