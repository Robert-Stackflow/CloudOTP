package com.cloudchewie.otp.adapter;

import android.content.Context;
import android.util.ArrayMap;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;

import com.cloudchewie.otp.R;
import com.cloudchewie.otp.database.AppSharedPreferenceUtil;
import com.cloudchewie.otp.database.LocalStorage;
import com.cloudchewie.otp.entity.OtpToken;
import com.cloudchewie.otp.entity.TokenCode;
import com.cloudchewie.otp.util.authenticator.TokenCodeUtil;
import com.cloudchewie.otp.util.enumeration.OtpTokenType;
import com.cloudchewie.otp.widget.SmallTokenLayout;
import com.cloudchewie.ui.custom.IToast;
import com.cloudchewie.util.system.ClipBoardUtil;
import com.cloudchewie.util.system.SharedPreferenceCode;
import com.cloudchewie.util.system.SharedPreferenceUtil;

import java.util.List;

public class DoubleColumnTokenListAdapter extends CustomTokenListAdapter<DoubleColumnTokenListAdapter.DoubleColumnTokenViewHolder> {

    public DoubleColumnTokenListAdapter(Context context, List<OtpToken> contentList) {
        this.otpTokens = contentList;
        this.context = context;
        idToTokenCodeMap = new ArrayMap<>();
    }

    @NonNull
    @Override
    public DoubleColumnTokenViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View view = LayoutInflater.from(parent.getContext()).inflate(R.layout.item_token_small, parent, false);
        return new DoubleColumnTokenViewHolder(view);
    }

    @Override
    public void onBindViewHolder(@NonNull DoubleColumnTokenViewHolder holder, int position) {
        if (null == otpTokens) {
            return;
        }
        if (position < 0 || position >= otpTokens.size()) {
            return;
        }
        if (null == holder) {
            return;
        }
        final OtpToken token = otpTokens.get(position);
        if (null == token) {
            return;
        }
        ((SmallTokenLayout) holder.mItemView).bind(token);
        holder.mItemView.setOnClickListener(view -> {
            TokenCode codes = new TokenCodeUtil().generateTokenCode(token);
            if (token.getTokenType() == OtpTokenType.HOTP) {
                LocalStorage.getAppDatabase().otpTokenDao().incrementCounter(token.getId());
            }
            if (SharedPreferenceUtil.getBoolean(context, SharedPreferenceCode.TOKEN_CLICK_COPY.getKey(), false)) {
                if (AppSharedPreferenceUtil.isAutoCopyNext(context) && codes.getCurrentProgress() < 90) {
                    ClipBoardUtil.copy(codes.getNextCode());
                } else {
                    ClipBoardUtil.copy(codes.getCurrentCode());
                }
                IToast.showBottom(context, context.getString(R.string.copy_success));
            }
            idToTokenCodeMap.put(token.getId(), codes);
            ((SmallTokenLayout) holder.mItemView).start(token.getTokenType(), codes);
        });
        {
            TokenCode codes = new TokenCodeUtil().generateTokenCode(token);
            if (token.getTokenType() == OtpTokenType.HOTP) {
                LocalStorage.getAppDatabase().otpTokenDao().incrementCounter(token.getId());
            }
            idToTokenCodeMap.put(token.getId(), codes);
            ((SmallTokenLayout) holder.mItemView).start(token.getTokenType(), codes);
        }
    }

    @Override
    public int getItemCount() {
        return otpTokens == null ? 0 : otpTokens.size();
    }

    static class DoubleColumnTokenViewHolder extends RecyclerView.ViewHolder {
        public View mItemView;
        public ImageView imageView;
        public TextView codeView;
        public TextView issuerView;
        public TextView accountView;

        public DoubleColumnTokenViewHolder(View view) {
            super(view);
            mItemView = view;
            imageView = mItemView.findViewById(R.id.item_token_small_image);
            codeView = mItemView.findViewById(R.id.item_token_small_code);
            issuerView = mItemView.findViewById(R.id.item_token_small_issuer);
        }
    }
}
