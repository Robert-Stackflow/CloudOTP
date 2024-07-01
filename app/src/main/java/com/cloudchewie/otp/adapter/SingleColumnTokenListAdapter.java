package com.cloudchewie.otp.adapter;

import android.content.Context;
import android.util.ArrayMap;
import android.util.Log;
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
import com.cloudchewie.otp.widget.TokenLayout;
import com.cloudchewie.ui.custom.IToast;
import com.cloudchewie.util.system.ClipBoardUtil;
import com.cloudchewie.util.system.SharedPreferenceCode;
import com.cloudchewie.util.system.SharedPreferenceUtil;

import java.util.List;

public class SingleColumnTokenListAdapter extends CustomTokenListAdapter<SingleColumnTokenListAdapter.SingleColumnTokenViewHolder> {
    public SingleColumnTokenListAdapter(Context context, List<OtpToken> contentList) {
        this.otpTokens = contentList;
        this.context = context;
        idToTokenCodeMap = new ArrayMap<>();
    }

    @NonNull
    @Override
    public SingleColumnTokenViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View view = LayoutInflater.from(parent.getContext()).inflate(R.layout.item_token, parent, false);
        return new SingleColumnTokenViewHolder(view);
    }

    @Override
    public void onBindViewHolder(@NonNull SingleColumnTokenViewHolder holder, int position) {
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
        holder.tokenView.bind(token);
        holder.tokenView.setSelectionMode(inSelectionMode);
        if (!inSelectionMode) {
            //正常状态下
            holder.tokenView.setOnClickListener(view -> {
                TokenCode codes = new TokenCodeUtil().generateTokenCode(token);
                if (token.getTokenType() == OtpTokenType.HOTP) {
                    LocalStorage.getAppDatabase().otpTokenDao().incrementCounter(token.getId());
                }
                Log.d("xuruida", String.valueOf(codes.getCurrentProgress()));
                if (SharedPreferenceUtil.getBoolean(context, SharedPreferenceCode.TOKEN_CLICK_COPY.getKey(), false)) {
                    if (AppSharedPreferenceUtil.isAutoCopyNext(context) && codes.getCurrentProgress() < 200) {
                        ClipBoardUtil.copy(codes.getNextCode());
                    } else {
                        ClipBoardUtil.copy(codes.getCurrentCode());
                    }
                    IToast.showBottom(context, context.getString(R.string.copy_success));
                }
                idToTokenCodeMap.put(token.getId(), codes);
                holder.tokenView.start(token.getTokenType(), codes, true);
            });
            holder.tokenView.setOnLongClickListener((v) -> {
                if (itemOperationListener != null) itemOperationListener.onItemLongCick(token);
                return false;
            });
            //初始显示一次
            TokenCode codes = new TokenCodeUtil().generateTokenCode(token);
            if (token.getTokenType() == OtpTokenType.HOTP) {
                LocalStorage.getAppDatabase().otpTokenDao().incrementCounter(token.getId());
            }
            idToTokenCodeMap.put(token.getId(), codes);
            holder.tokenView.start(token.getTokenType(), codes, true);
        } else {
            holder.tokenView.setOnClickListener((view) -> holder.tokenView.toggleSelected());
            holder.tokenView.setOnSelectStateChangeListener(selected -> {
                if (itemOperationListener != null)
                    itemOperationListener.onItemSelectStateChanged();
            });
        }
    }

    @Override
    public int getItemCount() {
        return otpTokens == null ? 0 : otpTokens.size();
    }

    static class SingleColumnTokenViewHolder extends RecyclerView.ViewHolder {
        public View itemView;
        public TokenLayout tokenView;
        public ImageView imageView;
        public TextView codeView;
        public TextView issuerView;
        public TextView accountView;

        public SingleColumnTokenViewHolder(View view) {
            super(view);
            itemView = view;
            tokenView = itemView.findViewById(R.id.item_token_main_layout);
            imageView = itemView.findViewById(R.id.item_token_image);
            codeView = itemView.findViewById(R.id.item_token_code);
            issuerView = itemView.findViewById(R.id.item_token_issuer);
            accountView = itemView.findViewById(R.id.item_token_account);
        }
    }
}
