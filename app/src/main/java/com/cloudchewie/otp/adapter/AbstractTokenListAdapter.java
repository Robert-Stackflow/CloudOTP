package com.cloudchewie.otp.adapter;

import com.cloudchewie.otp.entity.OtpToken;

import java.util.List;

public interface AbstractTokenListAdapter{
    void setData(List<OtpToken> contentList);
}
