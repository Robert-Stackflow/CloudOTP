package com.cloudchewie.ui.custom;

import android.content.Context;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.util.AttributeSet;
import android.view.MotionEvent;
import android.view.View;
import android.widget.TextView;

import androidx.annotation.NonNull;

import com.cloudchewie.ui.R;
import com.cloudchewie.ui.ThemeUtil;

import java.util.ArrayList;
import java.util.List;
import java.util.Objects;

public class QuickLocationBar extends View {
    public static String HOT_LABEL = "⬆";
    private static String HOT_STRING = "";
    private List<String> characters = new ArrayList<>();
    private int currentIndex = -1;
    private OnTouchLetterChangedListener mOnTouchLetterChangedListener;
    private TextView mTextDialog;
    /**
     * 选择的圆的半径
     */
    private Paint circlePaint;
    private Paint paint = new Paint();
    private String selectCharacter = HOT_LABEL;

    public QuickLocationBar(Context context, AttributeSet attrs, int defStyleAttr) {
        super(context, attrs, defStyleAttr);
    }

    public QuickLocationBar(Context context, AttributeSet attrs) {
        super(context, attrs);
        init();
    }

    public QuickLocationBar(Context context) {
        super(context);
    }

    public void setOnTouchLitterChangedListener(OnTouchLetterChangedListener onTouchLetterChangedListener) {
        this.mOnTouchLetterChangedListener = onTouchLetterChangedListener;
    }

    public void setTextDialog(TextView dialog) {
        this.mTextDialog = dialog;
    }

    private void init() {
        circlePaint = new Paint();
        circlePaint.setAntiAlias(true);
        circlePaint.setColor(ThemeUtil.getPrimaryColor(getContext()));
        circlePaint.setStyle(Paint.Style.FILL);
        paint.setColor(getResources().getColor(R.color.color_gray));
        paint.setAntiAlias(true);
    }

    @Override
    protected void onDraw(Canvas canvas) {
        super.onDraw(canvas);
        int width = getWidth();
        int height = getHeight();
        if (characters.size() > 0) {
            int singleHeight = height / characters.size();
            for (int i = 0; i < characters.size(); i++) {
                paint.setTextSize(150 * (float) width / 320);
                float xPos = width / 2.0F - paint.measureText(characters.get(i)) / 2;
                float yPos = singleHeight * i + singleHeight;
                if (selectCharacter.equals(characters.get(i))) {
                    canvas.drawCircle(xPos + paint.measureText(characters.get(i)) / 2, yPos - singleHeight / 5.0F, width / 3.0F, circlePaint);
                    paint.setColor(Color.WHITE);
                } else {
                    paint.setColor(getResources().getColor(R.color.color_gray));
                }
                canvas.drawText(characters.get(i), xPos, yPos, paint);
                paint.reset();
            }
        }
    }

    @Override
    public boolean dispatchTouchEvent(@NonNull MotionEvent event) {
        int action = event.getAction();
        float y = event.getY();
        int calculatedPosition = (int) (y / getHeight() * characters.size());
        switch (action) {
            case MotionEvent.ACTION_UP:
                currentIndex = -1;
                selectCharacter = characters.get(Math.max(0, Math.min(calculatedPosition, characters.size() - 1)));
                setBackgroundColor(0x0000);
                invalidate();
                if (mTextDialog != null) mTextDialog.setVisibility(View.GONE);
                break;
            case MotionEvent.ACTION_DOWN:
            case MotionEvent.ACTION_MOVE:
                setBackgroundColor(Color.TRANSPARENT);
                if (currentIndex != calculatedPosition) {
                    if (calculatedPosition >= 0 && calculatedPosition < characters.size()) {
                        if (mOnTouchLetterChangedListener != null)
                            mOnTouchLetterChangedListener.OnTouchLetterChanged(characters.get(calculatedPosition));
                        if (mTextDialog != null) {
                            String str = characters.get(calculatedPosition);
                            if (Objects.equals(str, HOT_LABEL)) mTextDialog.setText(HOT_STRING);
                            else mTextDialog.setText(str);
                            mTextDialog.setVisibility(View.VISIBLE);
                        }
                        currentIndex = calculatedPosition;
                        selectCharacter = characters.get(calculatedPosition);
                        invalidate();
                    }
                }
                break;
        }
        return true;
    }

    public void setCharacters(List<String> characters, @NonNull Boolean hasHot) {
        if (hasHot) this.characters.add(HOT_LABEL);
        this.characters.addAll(characters);
        invalidate();
    }

    public String getSelectCharacter() {
        return selectCharacter;
    }

    public void setSelectCharacter(String character) {
        selectCharacter = character;
        invalidate();
    }

    public interface OnTouchLetterChangedListener {
        void OnTouchLetterChanged(String s);
    }
}
