package com.cloudchewie.otp.adapter;

import android.annotation.SuppressLint;
import android.content.Context;

import androidx.recyclerview.widget.RecyclerView;

import com.cloudchewie.otp.database.LocalStorage;
import com.cloudchewie.otp.entity.OtpToken;
import com.cloudchewie.otp.entity.TokenCode;

import java.util.Collections;
import java.util.Iterator;
import java.util.List;
import java.util.Map;

public abstract class CustomTokenListAdapter<T extends RecyclerView.ViewHolder> extends RecyclerView.Adapter<T> {
    protected Context context;
    protected List<OtpToken> otpTokens;
    protected Map<Long, TokenCode> idToTokenCodeMap;
    protected boolean inSelectionMode = false;
    protected ItemOperationListener itemOperationListener;

    public void setItemOperationListener(ItemOperationListener listener) {
        this.itemOperationListener = listener;
    }

    @SuppressLint("NotifyDataSetChanged")
    public void setData(List<OtpToken> otpTokens) {
        this.otpTokens = otpTokens;
        notifyDataSetChanged();
    }

    @SuppressLint("NotifyDataSetChanged")
    public void setInSelectionMode(boolean inSelectionMode, boolean subjective) {
        this.inSelectionMode = inSelectionMode;
        if (subjective) {
            for (OtpToken otpToken : otpTokens) {
                otpToken.setSelected(false);
            }
            notifyDataSetChanged();
        }
    }

    public void onMove(int fromPosition, int toPosition) {
        notifyItemMoved(fromPosition, toPosition);
        Collections.swap(otpTokens, fromPosition, toPosition);
        int ordinal = 0;
        for (OtpToken otpToken : otpTokens) {
            otpToken.setOrdinal(ordinal);
            LocalStorage.getAppDatabase().otpTokenDao().update(otpToken);
            ordinal++;
        }
    }

    @SuppressLint("NotifyDataSetChanged")
    public void delete() {
        if (inSelectionMode) {
            Iterator<OtpToken> iterator = otpTokens.iterator();
            while (iterator.hasNext()) {
                OtpToken otpToken = iterator.next();
                if (otpToken.isSelected()) {
                    notifyItemRemoved(otpTokens.indexOf(otpToken));
                    LocalStorage.getAppDatabase().otpTokenDao().deleteById(otpToken.getId());
                    iterator.remove();
                }
            }
        }
    }

    @SuppressLint("NotifyDataSetChanged")
    public void selectAll() {
        if (inSelectionMode) {
            for (OtpToken otpToken : otpTokens) {
                otpToken.setSelected(true);
            }
        }
        notifyDataSetChanged();
        if (itemOperationListener != null) itemOperationListener.onItemSelectStateChanged();
    }

    @SuppressLint("NotifyDataSetChanged")
    public void unSelectAll() {
        if (inSelectionMode) {
            for (OtpToken otpToken : otpTokens) {
                otpToken.setSelected(false);
            }
        }
        notifyDataSetChanged();
        if (itemOperationListener != null) itemOperationListener.onItemSelectStateChanged();
    }

    public interface ItemOperationListener {
        void onItemLongCick(OtpToken otpToken);

        void onItemSelectStateChanged();
    }
}
