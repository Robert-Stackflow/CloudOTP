package com.cloudchewie.util.system;

import org.jetbrains.annotations.Contract;

public enum SharedPreferenceCode {
    APP_FIRST_START("app_first_start", "首次打开APP"),
    START_UP_APP_TIME("start_up_app_time", "打开APP时间"),
    PASSCODE("passcode", "密码锁"),
    THEME_ID("theme_id", "主题ID"),
    AUTO_DAYNIGHT("auto_daynight", "深色模式跟随系统"),
    IS_NIGHT("is_night", "是否为深色模式"),
    ENABLE_WEB_CACHE("enable_web_cache", "是否允许网站缓存"),
    TOKEN_CLICK_COPY("token_click_copy", "点击卡片复制令牌"),
    TOKEN_LONG_CLICK_COPY("token_long_click_copy", "长按卡片复制令牌"),
    TOKEN_NEED_AUTH("token_need_auth", "需要身份验证"),
    VIEW_TYPE("view_type", "视图"),
    TOKEN_DISBALE_SCREENSHOT("token_disable_screenshot", "禁止屏幕截图");
    private final String key;
    private final String describe;

    SharedPreferenceCode(String key, String describe) {
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
