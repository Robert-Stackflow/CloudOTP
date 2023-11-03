package com.cloudchewie.ui.emoji;

import androidx.annotation.NonNull;

public class EmojiParse {
    public EmojiParse() {
    }

    @NonNull
    public static String fromChar(char ch) {
        return Character.toString(ch);
    }

    @NonNull
    public static String fromCodePoint(int codePoint) {
        return newString(codePoint);
    }

    @NonNull
    public static String newString(int codePoint) {
        return Character.charCount(codePoint) == 1 ? String.valueOf(codePoint) : new String(Character.toChars(codePoint));
    }
}