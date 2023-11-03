package com.cloudchewie.otp.adapter;

import android.annotation.SuppressLint;
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
import com.cloudchewie.otp.entity.OtpToken;
import com.cloudchewie.otp.entity.TokenCode;
import com.cloudchewie.otp.util.authenticator.TokenCodeUtil;
import com.cloudchewie.otp.util.database.LocalStorage;
import com.cloudchewie.otp.util.enumeration.OtpTokenType;
import com.cloudchewie.otp.widget.TokenLayout;
import com.cloudchewie.ui.custom.IToast;
import com.cloudchewie.util.system.ClipBoardUtil;
import com.cloudchewie.util.system.SharedPreferenceCode;
import com.cloudchewie.util.system.SharedPreferenceUtil;

import java.util.List;
import java.util.Map;

public class TokenListAdapter extends RecyclerView.Adapter<TokenListAdapter.MyViewHolder> implements AbstractTokenListAdapter {
    private final Context context;
    private List<OtpToken> contentList;
    private Map<Long, TokenCode> tokenCodes;

    public TokenListAdapter(Context context, List<OtpToken> contentList) {
        this.contentList = contentList;
        this.context = context;
        tokenCodes = new ArrayMap<>();
    }

    @NonNull
    @Override
    public MyViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View view = LayoutInflater.from(parent.getContext()).inflate(R.layout.item_token, parent, false);
        return new MyViewHolder(view);
    }

    @SuppressLint("NotifyDataSetChanged")
    @Override
    public void setData(List<OtpToken> contentList) {
        this.contentList = contentList;
        notifyDataSetChanged();
    }

    @Override
    public void onBindViewHolder(@NonNull MyViewHolder holder, int position) {
        if (null == contentList) {
            return;
        }
        if (position < 0 || position >= contentList.size()) {
            return;
        }
        if (null == holder) {
            return;
        }
        final OtpToken token = contentList.get(position);
        if (null == token) {
            return;
        }
        ((TokenLayout) holder.mItemView).bind(token);
        holder.mItemView.setOnClickListener(view -> {
            TokenCode codes = new TokenCodeUtil().generateTokenCode(token);
            if (token.getTokenType() == OtpTokenType.HOTP) {
                LocalStorage.getAppDatabase().otpTokenDao().incrementCounter(token.getId());
            }
            if (SharedPreferenceUtil.getBoolean(context, SharedPreferenceCode.TOKEN_CLICK_COPY.getKey(), false)) {
                ClipBoardUtil.copy(codes.getCurrentCode());
                IToast.showBottom(context, context.getString(R.string.copy_success));
            }
            tokenCodes.put(token.getId(), codes);
            ((TokenLayout) holder.mItemView).start(token.getTokenType(), codes, true);
        });
        holder.mItemView.setOnLongClickListener(view -> {
            if (SharedPreferenceUtil.getBoolean(context, SharedPreferenceCode.TOKEN_LONG_CLICK_COPY.getKey(), true)) {
                TokenCode codes = new TokenCodeUtil().generateTokenCode(token);
                if (token.getTokenType() == OtpTokenType.HOTP) {
                    LocalStorage.getAppDatabase().otpTokenDao().incrementCounter(token.getId());
                }
                ClipBoardUtil.copy(codes.getCurrentCode());
                IToast.showBottom(context, context.getString(R.string.copy_success));
            }
            return false;
        });
        {
            TokenCode codes = new TokenCodeUtil().generateTokenCode(token);
            if (token.getTokenType() == OtpTokenType.HOTP) {
                LocalStorage.getAppDatabase().otpTokenDao().incrementCounter(token.getId());
            }
            tokenCodes.put(token.getId(), codes);
            ((TokenLayout) holder.mItemView).start(token.getTokenType(), codes, true);
        }
    }

    @Override
    public int getItemCount() {
        return contentList == null ? 0 : contentList.size();
    }

    static class MyViewHolder extends RecyclerView.ViewHolder {
        public View mItemView;
        public ImageView imageView;

        public TextView codeView;
        public TextView issuerView;
        public TextView accountView;


        public MyViewHolder(View view) {
            super(view);
            mItemView = view;
            imageView = mItemView.findViewById(R.id.item_token_image);
            codeView = mItemView.findViewById(R.id.item_token_code);
            issuerView = mItemView.findViewById(R.id.item_token_issuer);
            accountView = mItemView.findViewById(R.id.item_token_account);
        }
    }
}
