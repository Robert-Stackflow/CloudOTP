package com.cloudchewie.otp.util.enumeration;

import org.jetbrains.annotations.Contract;

public enum EventBusCode {
    CHANGE_THEME("change_theme", "更改主题颜色"),
    CHANGE_AUTO_DAYNIGHT("change_auto_daynight", "更改深色模式是否跟随系统"),
    CHANGE_TOKEN("change_token", "令牌更新"),
    CHANGE_VERIFY_STATE("change_verify_state", "验证状态更新"),
    CHANGE_PASSCODE("change_passcode", "密码更新"),
    CHANGE_TOKEN_NEED_AUTH("change_token_need_auth", "令牌身份验证"),
    CHANGE_TOKEN_DISABLE_SCREENSHOT("change_token_disable_screenshot", "令牌截图更新"),
    CHANGE_VIEW_TYPE("change_viw_type", "修改视图");
    private final String key;
    private final String describe;

    EventBusCode(String key, String describe) {
        this.key = key;
        this.describe = describe;
    }

    @Contract(pure = true)
    public String getKey() {
        return key;
    }

    @Contract(pure = true)
    public String getDescribe() {
        return describe;
    }
}
