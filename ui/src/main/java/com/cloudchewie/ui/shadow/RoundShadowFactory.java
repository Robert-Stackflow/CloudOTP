package com.cloudchewie.ui.shadow;

/**
 * 圆角矩形阴影工厂
 */
public class RoundShadowFactory implements ShadowFactory {

    @Override
    public boolean supportKey(Object key) {
        return key instanceof RoundShadow.Key;
    }

    @Override
    public Object copyKey(Object key) throws UnsupportedKeyException {
        if (!supportKey(key)) {
            throw new UnsupportedKeyException("Key:" + key);
        }
        return ((RoundShadow.Key) key).clone();
    }

    @Override
    public Shadow create(Object key) throws UnsupportedKeyException {
        if (!supportKey(key)) {
            throw new UnsupportedKeyException("Key:" + key);
        }
        if (key instanceof UnsupportedRoundShadow.Key) {
            return new UnsupportedRoundShadow((UnsupportedRoundShadow.Key) key);
        }
        return new RoundShadow((RoundShadow.Key) key);
    }
}
