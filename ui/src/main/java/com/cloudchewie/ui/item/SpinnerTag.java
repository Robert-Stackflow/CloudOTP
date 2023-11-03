package com.cloudchewie.ui.item;

import android.content.Context;
import android.content.res.ColorStateList;
import android.content.res.TypedArray;
import android.graphics.drawable.Drawable;
import android.util.AttributeSet;
import android.util.TypedValue;
import android.view.LayoutInflater;
import android.widget.ImageView;
import android.widget.RelativeLayout;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.cloudchewie.ui.R;

import org.jetbrains.annotations.Contract;

import java.util.ArrayList;
import java.util.List;

public class SpinnerTag extends RelativeLayout {
    TextView textView;
    ImageView iconView;
    RelativeLayout mainLayout;
    String text;
    int textSize;
    int textColor;
    int textCheckedColor;
    int iconSize;
    Drawable icon;
    Drawable checkedIcon;
    int iconColor;
    int iconCheckedColor;
    Drawable background;
    int backgroundTint;
    int backgroundCheckedTint;
    boolean isChecked;
    List<String> dataSource;
    int currentIndex = -1;
    onCheckStateChangedListener listener;

    public SpinnerTag(@NonNull Context context) {
        super(context);
        init(context, null);
    }

    public SpinnerTag(@NonNull Context context, @Nullable AttributeSet attrs) {
        super(context, attrs);
        init(context, attrs);
    }

    public SpinnerTag(@NonNull Context context, @Nullable AttributeSet attrs, int defStyleAttr) {
        super(context, attrs, defStyleAttr);
        init(context, attrs);
    }

    public SpinnerTag(@NonNull Context context, @Nullable AttributeSet attrs, int defStyleAttr, int defStyleRes) {
        super(context, attrs, defStyleAttr, defStyleRes);
        init(context, attrs);
    }

    public int getCurrentIndex() {
        return currentIndex;
    }

    public void setCurrentIndex(int currentIndex) {
        if (dataSource == null || dataSource.size() == 0) {
            this.currentIndex = -1;
        } else if (currentIndex < 0) {
            this.currentIndex = 0;
        } else if (currentIndex > dataSource.size()) {
            this.currentIndex = dataSource.size() - 1;
        } else {
            this.currentIndex = currentIndex;
        }
        setText(currentIndex == -1 ? "" : dataSource.get(currentIndex));
    }

    public List<String> getDataSource() {
        return dataSource == null ? new ArrayList<>() : dataSource;
    }

    public void setEntry(@NonNull List<String> dataSource) {
        this.dataSource = dataSource == null ? new ArrayList<>() : dataSource;
        this.currentIndex = dataSource.size() == 0 ? -1 : 0;
        setText(currentIndex == -1 ? "" : dataSource.get(currentIndex));
    }

    public void setEntry(@NonNull CharSequence[] dataSource) {
        List<String> stringList = new ArrayList<>();
        for (CharSequence sequence : dataSource) {
            stringList.add((String) sequence);
        }
        setEntry(stringList);
    }

    public int getItemCount() {
        return dataSource == null ? 0 : dataSource.size();
    }

    public int getTextSize() {
        return textSize;
    }

    public void setTextSize(int textSize) {
        this.textSize = textSize;
        updateView();
    }

    public int getIconSize() {
        return iconSize;
    }

    public void setIconSize(int iconSize) {
        this.iconSize = iconSize;
        updateView();
    }

    public Drawable getIcon() {
        return icon;
    }

    public void setIcon(Drawable icon) {
        this.icon = icon;
        updateView();
    }

    public Drawable getCheckedIcon() {
        return checkedIcon;
    }

    public void setCheckedIcon(Drawable iconChecked) {
        this.checkedIcon = iconChecked;
        updateView();
    }

    @Override
    public Drawable getBackground() {
        return background;
    }

    @Override
    public void setBackground(Drawable background) {
        this.background = background;
        updateView();
    }

    public String getText() {
        return text;
    }

    public void setText(String text) {
        this.text = text;
        updateView();
    }

    public int getBackgroundTint() {
        return backgroundTint;
    }

    public void setBackgroundTint(int backgroundTint) {
        this.backgroundTint = backgroundTint;
        updateView();
    }

    public int getBackgroundCheckedTint() {
        return backgroundCheckedTint;
    }

    public void setBackgroundCheckedTint(int backgroundCheckedTint) {
        this.backgroundCheckedTint = backgroundCheckedTint;
        updateView();
    }

    public TextView getTextView() {
        return textView;
    }

    public ImageView getIconView() {
        return iconView;
    }

    public int getTextColor() {
        return textColor;
    }

    public void setTextColor(int textColor) {
        this.textColor = textColor;
        updateView();
    }

    public int getTextCheckedColor() {
        return textCheckedColor;
    }

    public void setTextCheckedColor(int textCheckedColor) {
        this.textCheckedColor = textCheckedColor;
        updateView();
    }

    public int getIconColor() {
        return iconColor;
    }

    public void setIconColor(int iconColor) {
        this.iconColor = iconColor;
        updateView();
    }

    public int getIconCheckedColor() {
        return iconCheckedColor;
    }

    public void setIconCheckedColor(int iconCheckedColor) {
        this.iconCheckedColor = iconCheckedColor;
        updateView();
    }

    public boolean isChecked() {
        return isChecked;
    }

    public void setChecked(boolean checked) {
        if (listener != null && isChecked != checked) {
            isChecked = checked;
            listener.onCheckStateChanged(this, isChecked);
        }
        updateView();
    }

    public void setOnCheckStateChangedListener(onCheckStateChangedListener listener) {
        this.listener = listener;
    }

    public void toggle() {
        setChecked(!isChecked);
    }

    @Contract(pure = true)
    private void updateView() {
        textView.setTextSize(TypedValue.COMPLEX_UNIT_PX, textSize);
        textView.setText(text);
        mainLayout.setBackground(background);
//        RelativeLayout.LayoutParams layoutParams = new RelativeLayout.LayoutParams(iconView.getLayoutParams());
//        layoutParams.height = iconSize;
//        layoutParams.width = iconSize;
//        iconView.setLayoutParams(layoutParams);
        if (isChecked) {
            textView.setTextColor(textCheckedColor);
            iconView.setImageDrawable(checkedIcon);
            iconView.setColorFilter(iconCheckedColor);
            mainLayout.setBackgroundTintList(ColorStateList.valueOf(backgroundCheckedTint));
        } else {
            textView.setTextColor(textColor);
            iconView.setImageDrawable(icon);
            iconView.setColorFilter(iconColor);
            mainLayout.setBackgroundTintList(ColorStateList.valueOf(backgroundTint));
        }
    }

    private void init(Context context, AttributeSet attrs) {
        LayoutInflater.from(context).inflate(R.layout.widget_spinner, this, true);
        textView = findViewById(R.id.widget_spinner_text);
        iconView = findViewById(R.id.widget_spinner_icon);
        mainLayout = findViewById(R.id.widget_spinner_layout);
        TypedArray attr = context.obtainStyledAttributes(attrs, R.styleable.SpinnerTag);
        if (attr != null) {
            text = attr.getString(R.styleable.SpinnerTag_spinner_tag_text);
            textSize = attr.getDimensionPixelSize(R.styleable.SpinnerTag_spinner_tag_text_size, getResources().getDimensionPixelSize(R.dimen.sp12));
            textColor = attr.getColor(R.styleable.SpinnerTag_spinner_tag_text_color, getResources().getColor(R.color.color_accent));
            textCheckedColor = attr.getColor(R.styleable.SpinnerTag_spinner_tag_text_checked_color, getResources().getColor(R.color.color_accent));
            icon = attr.getDrawable(R.styleable.SpinnerTag_spinner_tag_icon);
            checkedIcon = attr.getDrawable(R.styleable.SpinnerTag_spinner_tag_checked_icon);
            iconSize = attr.getDimensionPixelSize(R.styleable.SpinnerTag_spinner_tag_icon_size, getResources().getDimensionPixelSize(R.dimen.dp15));
            iconColor = attr.getColor(R.styleable.SpinnerTag_spinner_tag_icon_color, getResources().getColor(R.color.color_gray));
            iconCheckedColor = attr.getColor(R.styleable.SpinnerTag_spinner_tag_icon_checked_color, getResources().getColor(R.color.color_gray));
            background = attr.getDrawable(R.styleable.SpinnerTag_spinner_tag_background);
            backgroundTint = attr.getColor(R.styleable.SpinnerTag_spinner_tag_background_tint, getResources().getColor(R.color.tag_background));
            backgroundCheckedTint = attr.getColor(R.styleable.SpinnerTag_spinner_tag_background_checked_tint, getResources().getColor(R.color.tag_background));
            CharSequence[] array = attr.getTextArray(R.styleable.SpinnerTag_spinner_tag_array);
            setEntry(array);
            setBackground(background);
            setBackgroundTint(backgroundTint);
            setBackgroundCheckedTint(backgroundCheckedTint);
            setText(text);
            setTextSize(textSize);
            setTextColor(textColor);
            setTextSize(textSize);
            setTextCheckedColor(textCheckedColor);
            setIcon(icon);
            setIconSize(iconSize);
            setIconColor(iconColor);
            setCheckedIcon(checkedIcon);
            setIconCheckedColor(iconCheckedColor);
            setChecked(false);
            attr.recycle();
        }
        this.setOnClickListener(v -> {
            if (listener != null) {
                listener.onClicked(this);
            }
        });
    }

    public interface onCheckStateChangedListener {
        void onCheckStateChanged(SpinnerTag spinner, boolean isChecked);

        void onClicked(SpinnerTag spinner);
    }
}
