package com.cloudchewie.ui.emoji;

import android.content.Context;
import android.text.Editable;
import android.text.TextUtils;
import android.view.KeyEvent;
import android.widget.EditText;

import androidx.annotation.NonNull;

import com.cloudchewie.ui.R;
import com.cloudchewie.ui.emoji.adapter.EmoticonsAdapter;
import com.cloudchewie.ui.emoji.adapter.PageSetAdapter;
import com.cloudchewie.ui.emoji.data.EmoticonEntity;
import com.cloudchewie.ui.emoji.data.EmoticonPageEntity;
import com.cloudchewie.ui.emoji.data.EmoticonPageSetEntity;
import com.cloudchewie.ui.emoji.listener.EmoticonClickListener;
import com.cloudchewie.ui.emoji.listener.EmoticonDisplayListener;
import com.cloudchewie.ui.emoji.listener.ImageBase;
import com.cloudchewie.ui.emoji.listener.PageViewInstantiateListener;
import com.cloudchewie.ui.emoji.widget.EmoticonPageView;
import com.cloudchewie.ui.emoji.widget.EmoticonsEditText;

import java.io.IOException;
import java.lang.reflect.Constructor;
import java.util.ArrayList;
import java.util.Collections;

public class SimpleCommonUtils {

    public static PageSetAdapter sCommonPageSetAdapter;

    public static void initEmoticonsEditText(EmoticonsEditText etContent) {
        etContent.addEmoticonFilter(new EmojiFilter());
    }

    public static EmoticonClickListener getCommonEmoticonClickListener(final EditText editText) {
        return (o, actionType, isDelBtn) -> {
            if (isDelBtn) {
                SimpleCommonUtils.delClick(editText);
            } else {
                if (o == null) {
                    return;
                }
                if (actionType == Constants.EMOTICON_CLICK_TEXT) {
                    String content = null;
                    if (o instanceof EmojiBean) {
                        content = ((EmojiBean) o).emoji;
                    } else if (o instanceof EmoticonEntity) {
                        content = ((EmoticonEntity) o).getContent();
                    }

                    if (TextUtils.isEmpty(content)) {
                        return;
                    }
                    int index = editText.getSelectionStart();
                    Editable editable = editText.getText();
                    editable.insert(index, content);
                }
            }
        };
    }

    public static PageSetAdapter getCommonAdapter(Context context, EmoticonClickListener emoticonClickListener) {

        if (sCommonPageSetAdapter != null) {
            return sCommonPageSetAdapter;
        }

        PageSetAdapter pageSetAdapter = new PageSetAdapter();

        addEmojiPageSetEntity(pageSetAdapter, context, emoticonClickListener);

        return pageSetAdapter;
    }

    /**
     * 插入emoji表情集
     *
     * @param pageSetAdapter
     * @param context
     * @param emoticonClickListener
     */
    public static void addEmojiPageSetEntity(@NonNull PageSetAdapter pageSetAdapter, Context context, final EmoticonClickListener emoticonClickListener) {
        ArrayList<EmojiBean> emojiArray = new ArrayList<>();
        Collections.addAll(emojiArray, DefEmoticons.sEmojiArray);
        EmoticonPageSetEntity emojiPageSetEntity
                = new EmoticonPageSetEntity.Builder()
                .setLine(3)
                .setRow(7)
                .setEmoticonList(emojiArray)
                .setIPageViewInstantiateItem(getDefaultEmoticonPageViewInstantiateItem((position, parent, viewHolder, object, isDelBtn) -> {
                    final EmojiBean emojiBean = (EmojiBean) object;
                    if (emojiBean == null && !isDelBtn) {
                        return;
                    }

                    viewHolder.ly_root.setBackgroundResource(R.drawable.shape_round_dp10);

                    if (isDelBtn) {
                        viewHolder.iv_emoticon.setImageResource(R.drawable.ic_light_fallback);
                    } else {
                        viewHolder.iv_emoticon.setImageResource(emojiBean.icon);
                    }

                    viewHolder.rootView.setOnClickListener(v -> {
                        if (emoticonClickListener != null) {
                            emoticonClickListener.onEmoticonClick(emojiBean, Constants.EMOTICON_CLICK_TEXT, isDelBtn);
                        }
                    });
                }))
                .setShowDelBtn(EmoticonPageEntity.DelBtnStatus.LAST)
                .setIconUri(ImageBase.Scheme.DRAWABLE.toUri("icon_emoji"))
                .build();
        pageSetAdapter.add(emojiPageSetEntity);
    }


    public static Object newInstance(Class _Class, Object... args) throws Exception {
        return newInstance(_Class, 0, args);
    }

    public static Object newInstance(Class _Class, int constructorIndex, Object... args) throws Exception {
        Constructor cons = _Class.getConstructors()[constructorIndex];
        return cons.newInstance(args);
    }

    public static PageViewInstantiateListener<EmoticonPageEntity> getDefaultEmoticonPageViewInstantiateItem(final EmoticonDisplayListener<Object> emoticonDisplayListener) {
        return getEmoticonPageViewInstantiateItem(EmoticonsAdapter.class, null, emoticonDisplayListener);
    }

    public static PageViewInstantiateListener<EmoticonPageEntity> getEmoticonPageViewInstantiateItem(final Class _class, EmoticonClickListener onEmoticonClickListener) {
        return getEmoticonPageViewInstantiateItem(_class, onEmoticonClickListener, null);
    }

    public static PageViewInstantiateListener<EmoticonPageEntity> getEmoticonPageViewInstantiateItem(final Class _class, final EmoticonClickListener onEmoticonClickListener, final EmoticonDisplayListener<Object> emoticonDisplayListener) {
        return (container, position, pageEntity) -> {
            if (pageEntity.getRootView() == null) {
                EmoticonPageView pageView = new EmoticonPageView(container.getContext());
                pageView.setNumColumns(pageEntity.getRow());
                pageEntity.setRootView(pageView);
                try {
                    EmoticonsAdapter adapter = new EmoticonsAdapter(container.getContext(), pageEntity, onEmoticonClickListener);
                    if (emoticonDisplayListener != null) {
                        adapter.setOnDisPlayListener(emoticonDisplayListener);
                    }
                    pageView.getEmoticonsGridView().setAdapter(adapter);
                } catch (Exception e) {
                    e.printStackTrace();
                }
            }
            return pageEntity.getRootView();
        };
    }

    public static EmoticonDisplayListener<Object> getCommonEmoticonDisplayListener(final EmoticonClickListener onEmoticonClickListener, final int type) {
        return (position, parent, viewHolder, object, isDelBtn) -> {

            final EmoticonEntity emoticonEntity = (EmoticonEntity) object;
            if (emoticonEntity == null && !isDelBtn) {
                return;
            }
            viewHolder.ly_root.setBackgroundResource(R.drawable.shape_round_dp10);

            if (isDelBtn) {
                viewHolder.iv_emoticon.setImageResource(R.drawable.ic_light_fallback);
            } else {
                try {
                    ImageLoader.getInstance(viewHolder.iv_emoticon.getContext()).displayImage(emoticonEntity.getIconUri(), viewHolder.iv_emoticon);
                } catch (IOException e) {
                    e.printStackTrace();
                }
            }

            viewHolder.rootView.setOnClickListener(v -> {
                if (onEmoticonClickListener != null) {
                    onEmoticonClickListener.onEmoticonClick(emoticonEntity, type, isDelBtn);
                }
            });
        };
    }

    public static void delClick(EditText editText) {
        int action = KeyEvent.ACTION_DOWN;
        int code = KeyEvent.KEYCODE_DEL;
        KeyEvent event = new KeyEvent(action, code);
        editText.onKeyDown(KeyEvent.KEYCODE_DEL, event);
    }

    //    public static void spannableEmoticonFilter(TextView tv_content, String content) {
//        SpannableStringBuilder spannableStringBuilder = new SpannableStringBuilder(content);
//
//        Spannable spannable = EmojiDisplay.spannableFilter(tv_content.getContext(),
//                spannableStringBuilder,
//                content,
//                EmoticonsKeyboardUtils.getFontHeight(tv_content));
//
//        tv_content.setText(spannable);
//    }
    public static String formatTag(String tag) {
        return "IMUI-" + tag;
    }

}
