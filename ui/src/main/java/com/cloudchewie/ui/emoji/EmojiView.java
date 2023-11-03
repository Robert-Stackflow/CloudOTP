package com.cloudchewie.ui.emoji;

import android.content.Context;
import android.util.AttributeSet;

import androidx.annotation.AttrRes;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.cloudchewie.ui.R;
import com.cloudchewie.ui.emoji.adapter.PageSetAdapter;
import com.cloudchewie.ui.emoji.data.PageSetEntity;
import com.cloudchewie.ui.emoji.widget.AutoHeightLayout;
import com.cloudchewie.ui.emoji.widget.EmoticonsFuncView;
import com.cloudchewie.ui.emoji.widget.EmoticonsIndicatorView;
import com.cloudchewie.ui.emoji.widget.EmoticonsToolBarView;

import java.util.ArrayList;


public class EmojiView extends AutoHeightLayout implements EmoticonsFuncView.OnEmoticonsPageViewListener,
        EmoticonsToolBarView.OnToolBarItemClickListener {

    private Context mContext;
    private EmoticonsFuncView mEmoticonsFuncView;
    private EmoticonsIndicatorView mEmoticonsIndicatorView;
    private EmoticonsToolBarView mEmoticonsToolBarView;

    public EmojiView(Context context) {
        super(context, null);
        init(context, null);
    }

    public EmojiView(@NonNull Context context, @Nullable AttributeSet attrs) {
        super(context, attrs);
        init(context, attrs);
    }

    public EmojiView(@NonNull Context context, @Nullable AttributeSet attrs,
                     @AttrRes int defStyleAttr) {
        super(context, attrs);
        init(context, attrs);
    }

    @Override
    public void onSoftKeyboardHeightChanged(int i) {

    }

    private void init(Context context, AttributeSet attrs) {
        inflate(context, R.layout.layout_emoji, this);
        mContext = context;

        mEmoticonsFuncView = findViewById(R.id.view_epv);
        mEmoticonsIndicatorView = findViewById(R.id.view_eiv);
        mEmoticonsToolBarView = findViewById(R.id.view_etv);
        mEmoticonsFuncView.setOnIndicatorListener(this);
        mEmoticonsToolBarView.setOnToolBarItemClickListener(this);
    }

    public void setAdapter(PageSetAdapter pageSetAdapter) {
        if (pageSetAdapter != null) {
            ArrayList<PageSetEntity> pageSetEntities = pageSetAdapter.getPageSetEntityList();
            if (pageSetEntities != null) {
                for (PageSetEntity pageSetEntity : pageSetEntities) {
                    mEmoticonsToolBarView.addToolItemView(pageSetEntity);
                }
            }
        }
        mEmoticonsFuncView.setAdapter(pageSetAdapter);
    }

    @Override
    public void emoticonSetChanged(@NonNull PageSetEntity pageSetEntity) {
        mEmoticonsToolBarView.setToolBtnSelect(pageSetEntity.getUuid());
    }

    @Override
    public void playTo(int position, PageSetEntity pageSetEntity) {
        mEmoticonsIndicatorView.playTo(position, pageSetEntity);
    }

    @Override
    public void playBy(int oldPosition, int newPosition, PageSetEntity pageSetEntity) {
        mEmoticonsIndicatorView.playBy(oldPosition, newPosition, pageSetEntity);
    }

    @Override
    public void onToolBarItemClick(PageSetEntity pageSetEntity) {
        mEmoticonsFuncView.setCurrentPageSet(pageSetEntity);
    }

    public EmoticonsFuncView getEmoticonsFuncView() {
        return this.mEmoticonsFuncView;
    }
}
