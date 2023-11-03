package com.cloudchewie.ui.shadow;

/**
 * 阴影工厂
 */
public interface ShadowFactory {

    /**
     * 判断是否支持此阴影key
     *
     * @param key 阴影key
     * @return true，支持此阴影key
     */
    boolean supportKey(Object key);

    /**
     * 复制阴影key
     *
     * @param key 阴影key
     * @return key的备份
     * @throws UnsupportedKeyException 不支持的阴影key
     */
    Object copyKey(Object key) throws UnsupportedKeyException;

    /**
     * 创建阴影
     *
     * @param key 阴影key
     * @return 阴影
     * @throws UnsupportedKeyException 不支持的阴影key
     */
    Shadow create(Object key) throws UnsupportedKeyException;

}
