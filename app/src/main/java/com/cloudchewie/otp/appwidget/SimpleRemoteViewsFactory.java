package com.cloudchewie.otp.appwidget;

import static com.cloudchewie.otp.util.authenticator.TokenImageUtil.matchIssuerWithTokenThumbnail;

import android.appwidget.AppWidgetManager;
import android.content.Context;
import android.content.Intent;
import android.text.TextUtils;
import android.util.Log;
import android.widget.RemoteViews;
import android.widget.RemoteViewsService;

import com.cloudchewie.otp.R;
import com.cloudchewie.otp.database.LocalStorage;
import com.cloudchewie.otp.database.OtpTokenManager;
import com.cloudchewie.otp.database.PrivacyManager;
import com.cloudchewie.otp.entity.OtpToken;
import com.cloudchewie.otp.entity.TokenCode;
import com.cloudchewie.otp.util.authenticator.TokenCodeUtil;
import com.cloudchewie.otp.util.enumeration.OtpTokenType;
import com.cloudchewie.ui.ThemeUtil;
import com.cloudchewie.ui.textdrawable.ColorGenerator;
import com.cloudchewie.ui.textdrawable.TextDrawable;
import com.cloudchewie.util.image.BitmapUtil;
import com.cloudchewie.util.system.SharedPreferenceCode;
import com.cloudchewie.util.system.SharedPreferenceUtil;
import com.google.gson.Gson;

import java.util.ArrayList;
import java.util.List;

public class SimpleRemoteViewsFactory implements RemoteViewsService.RemoteViewsFactory {

    private final Context mContext;
    private int appWidgetId;
    private boolean showCode;
    public static List<OtpToken> otpTokens = new ArrayList<>();

    public SimpleRemoteViewsFactory(Context context, Intent intent) {
        mContext = context;
        appWidgetId = intent.getIntExtra(AppWidgetManager.EXTRA_APPWIDGET_ID,
                AppWidgetManager.INVALID_APPWIDGET_ID);
    }

    @Override
    public void onCreate() {
        if (SharedPreferenceUtil.getBoolean(mContext, SharedPreferenceCode.TOKEN_NEED_AUTH.getKey(), true) && PrivacyManager.havePasscode() && !PrivacyManager.isVerified())
            otpTokens = new ArrayList<>();
        else if (LocalStorage.getAppDatabase() != null)
            otpTokens = OtpTokenManager.getTokens();
    }

    @Override
    public void onDataSetChanged() {
        Log.d("xuruida", "notify");
        if (SharedPreferenceUtil.getBoolean(mContext, SharedPreferenceCode.TOKEN_NEED_AUTH.getKey(), true) && PrivacyManager.havePasscode() && !PrivacyManager.isVerified())
            otpTokens = new ArrayList<>();
        else if (LocalStorage.getAppDatabase() != null)
            otpTokens = OtpTokenManager.getTokens();
    }

    @Override
    public void onDestroy() {
        otpTokens.clear();
    }

    @Override
    public int getCount() {
        return otpTokens.size();
    }

    @Override
    public RemoteViews getViewAt(int position) {
        if (position < 0 || position >= otpTokens.size())
            return null;
        OtpToken otpToken = otpTokens.get(position);
        final RemoteViews rv = new RemoteViews(mContext.getPackageName(),
                R.layout.item_token_widget);
        rv.setTextViewText(R.id.item_token_widget_issuer, otpToken.getIssuer());
        if (!TextUtils.isEmpty(otpToken.getIssuer())) {
            Integer integer = matchIssuerWithTokenThumbnail(otpToken);
            if (integer != null) {
                rv.setImageViewResource(R.id.item_token_widget_image, integer);
            } else {
                String tokenText = otpToken.getIssuer() != null ? otpToken.getIssuer().substring(0, 1) : "";
                int color = ColorGenerator.MATERIAL.getColor(tokenText);
                TextDrawable tokenTextDrawable = TextDrawable.builder().buildRoundRect(tokenText, color, 10);
                rv.setImageViewBitmap(R.id.item_token_widget_image, BitmapUtil.drawableToBitmap(tokenTextDrawable));
            }
        } else {
            rv.setImageViewResource(R.id.item_token_widget_image, R.mipmap.ic_launcher_round);
        }
        TokenCode codes = new TokenCodeUtil().generateTokenCode(otpToken);
        if (otpToken.getTokenType() == OtpTokenType.HOTP) {
            LocalStorage.getAppDatabase().otpTokenDao().incrementCounter(otpToken.getId());
        }
        rv.setTextViewText(R.id.item_token_widget_code, codes.getCurrentCode());
        rv.setTextColor(R.id.item_token_widget_code, ThemeUtil.getPrimaryColor(mContext));
        Intent intent = new Intent();
        intent.putExtra(MiddleWidgetProvider.EXTRA_ITEM, new Gson().toJson(otpToken));
        rv.setOnClickFillInIntent(R.id.item_token_widget_layout, intent);
        return rv;
    }

    @Override
    public RemoteViews getLoadingView() {
        return null;
    }

    @Override
    public int getViewTypeCount() {
        return 1;
    }

    @Override
    public long getItemId(int position) {
        return position;
    }

    @Override
    public boolean hasStableIds() {
        return true;
    }

}