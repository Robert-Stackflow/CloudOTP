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
import java.util.Map;

public class TokenListAdapter extends RecyclerView.Adapter<TokenListAdapter.MyViewHolder> implements AbstractTokenListAdapter {
    private final Context context;
    private List<OtpToken> contentList;
    private Map<Long, TokenCode> tokenCodes;
    private View.OnLongClickListener onItemLongClickListener;
    private OnStateChangeListener onStateChangeListener;
    private boolean editing = false;

    public interface OnStateChangeListener {
        void onSelectStateChanged(int selectedCount);
    }

    public void setOnItemLongClickListener(View.OnLongClickListener onItemLongClickListener) {
        this.onItemLongClickListener = onItemLongClickListener;
    }

    public void setOnStateChangeListener(OnStateChangeListener onStateChangeListener) {
        this.onStateChangeListener = onStateChangeListener;
    }

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

    @SuppressLint("NotifyDataSetChanged")
    public void setEditing(boolean editing) {
        this.editing = editing;
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
        holder.tokenView.bind(token);
        holder.tokenView.setEditing(editing);
        if (!editing) {
            holder.tokenView.setOnClickListener(view -> {
                TokenCode codes = new TokenCodeUtil().generateTokenCode(token);
                if (token.getTokenType() == OtpTokenType.HOTP) {
                    LocalStorage.getAppDatabase().otpTokenDao().incrementCounter(token.getId());
                }
                if (SharedPreferenceUtil.getBoolean(context, SharedPreferenceCode.TOKEN_CLICK_COPY.getKey(), false)) {
                    ClipBoardUtil.copy(codes.getCurrentCode());
                    IToast.showBottom(context, context.getString(R.string.copy_success));
                }
                tokenCodes.put(token.getId(), codes);
                holder.tokenView.start(token.getTokenType(), codes, true);
            });
            holder.tokenView.setOnLongClickListener(onItemLongClickListener);
            {
                TokenCode codes = new TokenCodeUtil().generateTokenCode(token);
                if (token.getTokenType() == OtpTokenType.HOTP) {
                    LocalStorage.getAppDatabase().otpTokenDao().incrementCounter(token.getId());
                }
                tokenCodes.put(token.getId(), codes);
                holder.tokenView.start(token.getTokenType(), codes, true);
            }
        } else {
            holder.tokenView.setClickable(false);
            holder.tokenView.setOnStateChangeListener(selected -> {
                int selectedCount = 0;
                for (OtpToken otpToken : contentList) {
                    if (otpToken.isSeleted()) selectedCount++;
                }
                if (onStateChangeListener != null)
                    onStateChangeListener.onSelectStateChanged(selectedCount);
            });
        }
    }

    @Override
    public int getItemCount() {
        return contentList == null ? 0 : contentList.size();
    }

    static class MyViewHolder extends RecyclerView.ViewHolder {
        public View itemView;
        public TokenLayout tokenView;
        public ImageView imageView;
        public TextView codeView;
        public TextView issuerView;
        public TextView accountView;

        public MyViewHolder(View view) {
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
