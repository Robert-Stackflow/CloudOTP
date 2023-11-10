package com.cloudchewie.otp.util;

import android.content.Context;
import android.content.Intent;
import android.content.pm.ShortcutInfo;
import android.content.pm.ShortcutManager;
import android.graphics.drawable.Drawable;
import android.graphics.drawable.Icon;
import android.os.Build;

import androidx.annotation.DrawableRes;
import androidx.appcompat.content.res.AppCompatResources;

import com.cloudchewie.otp.R;
import com.cloudchewie.otp.activity.EximportActivity;
import com.cloudchewie.otp.activity.ScanActivity;
import com.cloudchewie.otp.activity.SettingsActivity;
import com.cloudchewie.util.image.BitmapUtil;

import java.util.ArrayList;
import java.util.List;

public class ShortcutUtil {
    private static Icon getIcon(Context context, @DrawableRes int resourceId) {
        Drawable drawable = AppCompatResources.getDrawable(context, resourceId);
        return Icon.createWithBitmap(BitmapUtil.drawableToBitmap(drawable));
    }

    public static void init(Context context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N_MR1) {
            ShortcutManager shortcutManager = context.getSystemService(ShortcutManager.class);
            List<ShortcutInfo> shortcutInfoList = new ArrayList<>();
            shortcutInfoList.add(new ShortcutInfo.Builder(context, "shortcut_scan")
                    .setShortLabel(context.getString(R.string.title_scan_token))
                    .setIcon(getIcon(context, R.drawable.ic_material_scanner))
                    .setIntent(new Intent(Intent.ACTION_DEFAULT, null, context, ScanActivity.class))
                    .build());
            shortcutInfoList.add(new ShortcutInfo.Builder(context, "shortcut_eximport")
                    .setShortLabel(context.getString(R.string.title_eximport))
                    .setIcon(getIcon(context, R.drawable.ic_material_eximport))
                    .setIntent(new Intent(Intent.ACTION_DEFAULT, null, context, EximportActivity.class))
                    .build());
            shortcutInfoList.add(new ShortcutInfo.Builder(context, "shortcut_settings")
                    .setShortLabel(context.getString(R.string.title_setting))
                    .setIcon(getIcon(context, R.drawable.ic_material_settings))
                    .setIntent(new Intent(Intent.ACTION_DEFAULT, null, context, SettingsActivity.class))
                    .build());
            shortcutManager.setDynamicShortcuts(shortcutInfoList);
        }
    }
}
