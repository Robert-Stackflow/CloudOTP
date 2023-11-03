package com.cloudchewie.ui.shadow;

import java.lang.ref.WeakReference;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.CopyOnWriteArrayList;

/**
 * 阴影管理器
 */
public class ShadowManager {

    private static ShadowManager defInstance;
    private List<ShadowFactory> factories;
    private Map<Object, Shadow> shadowMap;
    private Map<Object, WeakReference<Shadow>> weakShadowMap;
    public ShadowManager() {
        factories = new CopyOnWriteArrayList<>();
        factories.add(new RoundShadowFactory());
        weakShadowMap = new HashMap<>();
    }

    /**
     * 获取一个默认的阴影管理器
     *
     * @return 阴影管理器
     */
    public static ShadowManager getDefault() {
        if (null == defInstance) {
            defInstance = new ShadowManager();
        }
        return defInstance;
    }

    /**
     * 获取阴影对象
     *
     * @param key 阴影key
     * @return 阴影对象
     * @throws UnsupportedKeyException 不支持的阴影key
     */
    public Shadow get(Object key) throws UnsupportedKeyException {
        WeakReference<Shadow> weak = weakShadowMap.get(key);
        if (null != weak) {
            Shadow shadow = weak.get();
            if (null == shadow) {
                return createShadow(key);
            }
            return shadow;
        } else {
            return createShadow(key);
        }
    }

    private Shadow createShadow(Object key) {
        for (ShadowFactory factory : factories) {
            if (factory.supportKey(key)) {
                Shadow shadow = factory.create(key);
                Object copyKey = factory.copyKey(key);
                WeakReference<Shadow> weak = new WeakReference<>(shadow);
                weakShadowMap.put(copyKey, weak);
                return shadow;
            }
        }
        return null;
    }

    /**
     * 绑定一个阴影（阴影）
     *
     * @param key 阴影key
     * @return 阴影对象
     * @throws UnsupportedKeyException 不支持的阴影key
     * @deprecated 已过时，请改用{@link #get(Object) get}方法
     */
    public Shadow bind(Object key) throws UnsupportedKeyException {
        if (null != shadowMap) {
            Shadow shadow = shadowMap.get(key);
            if (null != shadow && shadow.isUsed()) {
                return shadow;
            }
        }
        for (ShadowFactory factory : factories) {
            if (factory.supportKey(key)) {
                Shadow shadow = factory.create(key);
                Object copyKey = factory.copyKey(key);
                if (null == shadowMap) shadowMap = new HashMap<>();
                shadowMap.put(copyKey, shadow);
                shadow.bind();
                return shadow;
            }
        }
        throw new UnsupportedKeyException("Key:" + key);
    }

    /**
     * 解绑一个阴影
     *
     * @param shadow 阴影对象
     * @return true，解绑成功
     * @deprecated 已过时，不用主动去释放阴影对象
     */
    public boolean unbind(Shadow shadow) {
        Object key = shadow.getKey();
        if (null != shadowMap && null != key) {
            Shadow temp = shadowMap.get(key);
            if (temp == shadow) {
                shadow.unbind();
                if (!shadow.isUsed()) {
                    shadowMap.remove(key);
                }
                return true;
            }
        }
        return false;
    }

    /**
     * 添加阴影工厂
     *
     * @param factory 阴影工厂
     */
    public void addFactory(ShadowFactory factory) {
        factories.add(factory);
    }

    /**
     * 移除阴影工厂
     *
     * @param factory 阴影工厂
     */
    public void removeFactory(ShadowFactory factory) {
        factories.remove(factory);
    }
}
