package com.cloudchewie.ui.passcode;

import android.annotation.SuppressLint;
import android.content.Context;
import android.content.res.ColorStateList;
import android.content.res.TypedArray;
import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.graphics.Paint;
import android.graphics.Rect;
import android.graphics.Typeface;
import android.graphics.drawable.Drawable;
import android.os.Vibrator;
import android.text.TextPaint;
import android.util.AttributeSet;
import android.util.Log;
import android.view.HapticFeedbackConstants;
import android.view.MotionEvent;
import android.view.View;

import androidx.appcompat.content.res.AppCompatResources;

import com.cloudchewie.ui.R;
import com.cloudchewie.ui.ThemeUtil;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.Map;

public class PassCodeView extends View {
    private boolean DEBUG = false;
    private final int KEYS_COUNT = 12;
    private final String eraseChar = "\u232B";
    private final int KEY_PAD_COLS = 3;
    private final int KEY_PAD_ROWS = 4;
    private int digits;
    private int filledCount = 0;
    private Bitmap filledDrawable;
    private Bitmap emptyDrawable;
    private Paint paint;
    private int DEFAULT_DRAWABLE_DIM;
    private int DEFAULT_VIEW_HEIGHT = 200;
    private int digitVerticalPadding;
    private int drawableWidth;
    private int drawableHeight;
    private int drawableStartX;
    private int drawableStartY;
    private int digitHorizontalPadding;
    private int kpStartX;
    private int kpStartY;
    private ArrayList<KeyRect> keyRects = new ArrayList<>();
    private int keyWidth;
    private int keyHeight;
    private String passCodeText = "";
    private TextChangeListener textChangeListener;
    private boolean skipKeyDraw = false;
    private int touchSlope = 5;

    private Map<Integer, Integer> touchXMap = new HashMap<>();
    private Map<Integer, Integer> touchYMap = new HashMap<>();
    private Typeface typeFace;
    private TextPaint textPaint;
    private float keyTextSize;
    private long animDuration = 200;
    private Paint circlePaint;
    private boolean dividerVisible;
    private float dividerStartX;
    private float dividerStartY;
    private float dividerEndX;
    private float dividerEndY;
    private Context context;

    public PassCodeView(Context context) {
        super(context);
        init(context, null, 0, 0);
    }

    public PassCodeView(Context context, AttributeSet attrs) {
        super(context, attrs);
        init(context, attrs, 0, 0);
    }

    public PassCodeView(Context context, AttributeSet attrs, int defStyleAttr) {
        super(context, attrs, defStyleAttr);
        init(context, attrs, defStyleAttr, 0);
    }

    public PassCodeView(Context context, AttributeSet attrs, int defStyleAttr, int defStyleRes) {
        super(context, attrs, defStyleAttr, defStyleRes);
        init(context, attrs, defStyleAttr, defStyleRes);
    }

    private void init(Context context, AttributeSet attrs, int defStyleAttr, int defStyleRes) {
        this.context = context;
        TypedArray values = context.getTheme()
                .obtainStyledAttributes(attrs, R.styleable.PassCodeView, defStyleAttr, defStyleRes);
        try {
            digits = values.getInteger(R.styleable.PassCodeView_digits, 4);
            float digitSize = values.getDimension(R.styleable.PassCodeView_digit_size,
                    getResources().getDimension(R.dimen.dp30));
            keyTextSize = values.getDimension(R.styleable.PassCodeView_key_text_size,
                    getResources().getDimension(R.dimen.sp24));
            dividerVisible = values.getBoolean(R.styleable.PassCodeView_divider_visible, false);
            digitHorizontalPadding = (int) values.getDimension(R.styleable.PassCodeView_digit_spacing,
                    getResources().getDimension(R.dimen.dp15));
            digitVerticalPadding =
                    (int) values.getDimension(R.styleable.PassCodeView_digit_vertical_padding,
                            getResources().getDimension(R.dimen.dp20));

            drawableWidth = (int) digitSize; //DEFAULT_DRAWABLE_DIM;
            drawableHeight = (int) digitSize; //DEFAULT_DRAWABLE_DIM;
            setFilledDrawable(values.getResourceId(R.styleable.PassCodeView_filled_drawable, -1));
            setEmptyDrawable(values.getResourceId(R.styleable.PassCodeView_empty_drawable, -1));
        } catch (Exception e) {
            e.printStackTrace();
        }
        values.recycle();
        preparePaint();
    }

    private void preparePaint() {
        paint = new Paint(TextPaint.ANTI_ALIAS_FLAG);
        textPaint = new TextPaint(TextPaint.ANTI_ALIAS_FLAG);
        circlePaint = new Paint(Paint.ANTI_ALIAS_FLAG);
        circlePaint.setStyle(Paint.Style.FILL);
        circlePaint.setColor(ThemeUtil.getPrimaryColor(context));
        paint.setStyle(Paint.Style.FILL);
        textPaint.setStyle(Paint.Style.FILL);
        textPaint.setColor(getResources().getColor(R.color.color_accent, null));
        textPaint.density = getResources().getDisplayMetrics().density;
        textPaint.setTextSize(keyTextSize);
        textPaint.setTextAlign(Paint.Align.CENTER);
    }

    public void setTypeFace(Typeface typeFace) {
        if (this.typeFace != typeFace) {
            this.typeFace = typeFace;
            textPaint.setTypeface(typeFace);
            requestLayout();
            invalidate();
        }
    }

    /**
     * Set color for the keypad text
     *
     * @param color - Resource id of the color to be set
     */
    public void setKeyTextColor(int color) {
        ColorStateList colorStateList = ColorStateList.valueOf(color);
        textPaint.setColor(colorStateList.getColorForState(getDrawableState(), 0));
        invalidate();
    }

    /**
     * Set size of keypad text
     *
     * @param size - Text size value to be set
     */
    public void setKeyTextSize(float size) {
        textPaint.setTextSize(size);
        requestLayout();
        invalidate();
    }

    /**
     * Compute the start point(x, y) to draw drawables showing filled and empty
     * pin code digits.
     */
    private void computeDrawableStartXY() {
        int totalDrawableWidth = digits * drawableWidth;
        int totalPaddingWidth = digitHorizontalPadding * (digits - 1);
        int totalReqWidth = totalDrawableWidth + totalPaddingWidth;
        drawableStartX = getMeasuredWidth() / 2 - totalReqWidth / 2;
        drawableStartY = (drawableHeight + digitVerticalPadding) / 2 - drawableHeight / 2;
        computeKeyboardStartXY();
    }

    /**
     * Compute the start point(x, y) to draw keyboard keys
     */
    private void computeKeyboardStartXY() {
        kpStartX = 0;
        kpStartY = drawableHeight + digitVerticalPadding;
        keyWidth = getMeasuredWidth() / KEY_PAD_COLS;
        keyHeight = (getMeasuredHeight() - (drawableHeight + digitVerticalPadding)) / KEY_PAD_ROWS;
        initialiseKeyRects();
        if (dividerVisible) {
            computeDividerPos();
        }
    }

    private void computeDividerPos() {
        float widthFactor = 10;
        dividerStartX = (float) keyWidth / 2 - widthFactor;
        dividerStartY = drawableHeight + digitVerticalPadding;
        dividerEndX = (getMeasuredWidth() - (float) keyWidth / 2) + widthFactor;
        dividerEndY = dividerStartY;
    }

    /**
     * Initialise a {@link KeyRect} for each key in keyboard which holds details
     * of key like position, value etc.
     */
    private void initialiseKeyRects() {
        keyRects.clear();
        int x = kpStartX, y = kpStartY;
        for (int i = 1; i <= KEYS_COUNT; i++) {
            keyRects.add(
                    new KeyRect(this, new Rect(x, y, x + keyWidth, y + keyHeight), String.valueOf(i)));
            x = x + keyWidth;
            if (i % 3 == 0) {
                y = y + keyHeight;
                x = kpStartX;
            }
        }
        keyRects.get(9).setValue("");
        keyRects.get(10).setValue("0");
        keyRects.get(11).setValue(eraseChar);
    }

    /**
     * Create a {@link Bitmap} for the given @param resId
     *
     * @param resId - The resource id of the drawable for which the bitmap should be
     *              created
     * @return {@link Bitmap} of the drawable whose resource id is passed in
     */
    private Bitmap getBitmap(int resId) {
        Drawable drawable = AppCompatResources.getDrawable(getContext(), resId);
        Canvas canvas = new Canvas();
        Bitmap bitmap = Bitmap.createBitmap(drawableWidth, drawableHeight, Bitmap.Config.ARGB_8888);
        canvas.setBitmap(bitmap);
        drawable.setBounds(0, 0, drawableWidth, drawableHeight);
        drawable.draw(canvas);
        return bitmap;
    }

    @Override
    protected void onDraw(Canvas canvas) {
        super.onDraw(canvas);
        drawDigitDrawable(canvas);
        if (dividerVisible) {
            drawDivider(canvas);
        }
        drawKeyPad(canvas);
    }

    private void drawDivider(Canvas canvas) {
        paint.setAlpha(40);
        paint.setColor(getResources().getColor(R.color.color_divider, null));
        canvas.drawLine(dividerStartX, dividerStartY, dividerEndX, dividerEndY, paint);
    }

    /**
     * Draw the keys of keypad on the canvas starting from the previously computed start
     * point if keyboard
     *
     * @param canvas - {@link Canvas} on which the keypad should be drawn
     */
    private void drawKeyPad(Canvas canvas) {
        float centerHalf = (textPaint.descent() + textPaint.ascent()) / 2;
        for (KeyRect rect : keyRects) {
            canvas.drawText(rect.value, rect.rect.exactCenterX(), rect.rect.exactCenterY() - centerHalf,
                    textPaint);
            if (rect.hasRippleEffect) {
                circlePaint.setAlpha(rect.circleAlpha);
                canvas.drawCircle(rect.rect.exactCenterX(), rect.rect.exactCenterY(), rect.rippleRadius,
                        circlePaint);
            }
            if (DEBUG) {
                canvas.drawLine(rect.rect.left, rect.rect.centerY(), rect.rect.right, rect.rect.centerY(),
                        textPaint);
                canvas.drawLine(rect.rect.centerX(), rect.rect.top, rect.rect.centerX(), rect.rect.bottom,
                        textPaint);
                canvas.drawRect(rect.rect, textPaint);
            }
        }
    }

    /**
     * Draw the {@link Bitmap} of the drawable which indicated filled and empty
     * passcode digits
     *
     * @param canvas - {@link Canvas} on which the drawable should be drawn
     */
    private void drawDigitDrawable(Canvas canvas) {
        paint.setAlpha(255);
        int x = drawableStartX, y = drawableStartY;
        int totalContentWidth = drawableWidth + digitHorizontalPadding;
        for (int i = 1; i <= filledCount; i++) {
            canvas.drawBitmap(filledDrawable, x, y, paint);
            x += totalContentWidth;
        }
        for (int i = 1; i <= (digits - filledCount); i++) {
            canvas.drawBitmap(emptyDrawable, x, y, paint);
            x += totalContentWidth;
        }
    }

    @Override
    protected void onMeasure(int widthMeasureSpec, int heightMeasureSpec) {
        int widthMode = MeasureSpec.getMode(widthMeasureSpec);
        int heightMode = MeasureSpec.getMode(heightMeasureSpec);
        int paddingLeft = getPaddingLeft();
        int paddingRight = getPaddingRight();
        int paddingTop = getPaddingTop();
        int paddingBottom = getPaddingBottom();
        int measuredWidth = 0, measuredHeight = 0;
        if (widthMode == MeasureSpec.EXACTLY || widthMode == MeasureSpec.AT_MOST) {
            measuredWidth = MeasureSpec.getSize(widthMeasureSpec);
        }

        if (heightMode == MeasureSpec.EXACTLY) {
            measuredHeight = MeasureSpec.getSize(heightMeasureSpec);
        } else if (heightMode == MeasureSpec.AT_MOST) {
            double height = MeasureSpec.getSize(heightMeasureSpec) * 0.8;
            measuredHeight = (int) height;// + paddingTop + paddingBottom;
        }
        measuredHeight =
                (int) Math.max(measuredHeight, getResources().getDimension(R.dimen.dp300));
        setMeasuredDimension(measuredWidth, measuredHeight);
        computeDrawableStartXY();
    }

    /**
     * Set the count of digits entered by user
     *
     * @param count - {@link int} value of the digits filled
     */
    private void setFilledCount(int count) {
        filledCount = Math.min(count, digits);
        /*invalidate(drawableStartX,
                drawableStartX,
                drawableStartX + getMeasuredWidth(),
                drawableStartY + getMeasuredHeight());*/
        /* The coordinates passed to `invalidate` method above is wrong
            which makes the View not be drawn correctly
        		hence calling the default invalidate method */
        invalidate();
    }

    @SuppressLint("ClickableViewAccessibility")
    @Override
    public boolean onTouchEvent(MotionEvent event) {
        return processTouch(event);
    }

    /**
     * Process the {@link MotionEvent} and detect the key pressed and perform
     * appropriate action
     *
     * @param event - {@link MotionEvent} triggered by user action
     * @return {code boolean} whether event is consumed or not
     */
    private boolean processTouch(MotionEvent event) {
        switch (event.getActionMasked()) {
            case MotionEvent.ACTION_DOWN:
                int pointerDownId = event.getPointerId(event.getActionIndex());
                touchXMap.put(pointerDownId, (int) event.getX());
                touchYMap.put(pointerDownId, (int) event.getY());
                break;

            case MotionEvent.ACTION_UP:
                int pointerUpId = event.getPointerId(event.getActionIndex());
                int pointerUpIndex = event.findPointerIndex(pointerUpId);
                int eventX = (int) event.getX(pointerUpIndex);
                int eventY = (int) event.getY(pointerUpIndex);
                findKeyPressed(touchXMap.get(pointerUpId), touchYMap.get(pointerUpId), eventX, eventY);
                break;

            case MotionEvent.ACTION_POINTER_DOWN:
                int pointerActionDownId = event.getPointerId(event.getActionIndex());
                touchXMap.put(pointerActionDownId, (int) event.getX(event.getActionIndex()));
                touchYMap.put(pointerActionDownId, (int) event.getY(event.getActionIndex()));
                break;

            case MotionEvent.ACTION_POINTER_UP:
                int pointerActionUpIndex = event.getActionIndex();
                int pointerActionUpId = event.getPointerId(pointerActionUpIndex);
                int eventPointerX = (int) event.getX(pointerActionUpIndex);
                int eventPointerY = (int) event.getY(pointerActionUpIndex);
                findKeyPressed(touchXMap.get(pointerActionUpId), touchYMap.get(pointerActionUpId),
                        eventPointerX, eventPointerY);
                break;

            case MotionEvent.ACTION_MOVE:
            case MotionEvent.ACTION_CANCEL:
                return false;
        }
        return true;
    }

    /**
     * Find the key which is pressed by find the {@link Rect} which container the
     * passed in touch event points
     *
     * @param downEventX - X co-ordinate of the pointer down event
     * @param downEventY - Y co-ordinate of the pointer down event
     * @param upEventX   - X co-ordinate of the pointer up event
     * @param upEventY   - Y co-ordinate of the pointer up event
     */
    private void findKeyPressed(int downEventX, int downEventY, int upEventX, int upEventY) {
        for (final KeyRect keyRect : keyRects) {
            if (keyRect.rect.contains(downEventX, downEventY) && keyRect.rect.contains(upEventX,
                    upEventY)) {
                keyRect.playRippleAnim(new KeyRect.RippleAnimListener() {
                    @Override
                    public void onStart() {
                        performHapticFeedback(HapticFeedbackConstants.CONTEXT_CLICK);
                        int length = passCodeText.length();
                        if (keyRect.value.equals(eraseChar)) {
                            if (length > 0) {
                                passCodeText = passCodeText.substring(0, passCodeText.length() - 1);
                                setFilledCount(passCodeText.length());
                            }
                        } else if (!keyRect.value.isEmpty() && length < digits) {
                            passCodeText = passCodeText + keyRect.value;
                            setFilledCount(passCodeText.length());
                        }
                    }

                    @Override
                    public void onEnd() {
                        if (!keyRect.value.isEmpty()) {
                            notifyListener();
                        }
                    }
                });
            }
        }
    }

    public void setEmptyDrawable(int resId) {
        emptyDrawable = getBitmap(resId);
    }


    public void setFilledDrawable(int resId) {
        filledDrawable = getBitmap(resId);
    }

    /**
     * Reset the code to empty and redraw the view
     */
    public void reset() {
        this.passCodeText = "";
        invalidateAndNotifyListener();
    }

    /**
     * Interface to get notified on text change
     */
    public interface TextChangeListener {
        void onTextChanged(String text);
    }

    /**
     * Set the filled count of the passcode view and
     * redraw based on the new value and notify the
     * attached listener of the change
     */
    private void invalidateAndNotifyListener() {
        setFilledCount(passCodeText.length());
        Log.i("New text", passCodeText);
        if (textChangeListener != null) {
            textChangeListener.onTextChanged(passCodeText);
        }
    }

    private void notifyListener() {
        if (textChangeListener != null) {
            textChangeListener.onTextChanged(passCodeText);
        }
    }

    /**
     * Attach {@link TextChangeListener} to get notified on text changes
     *
     * @param listener - {@link TextChangeListener} object to be attached and notified
     */
    public void setOnTextChangeListener(TextChangeListener listener) {
        this.textChangeListener = listener;
    }

    /**
     * Remove the attached {@code TextChangeListener}
     */
    public void removeOnTextChangeListener() {
        this.textChangeListener = null;
    }

    /**
     * Show error feedback to the user
     *
     * @param reset - {@code boolean} value whether to reset the pass code before showing
     *              error feedback
     */
    public void setError(boolean reset) {
        if (reset) {
            reset();
        }
        Vibrator vibrator = (Vibrator) context.getSystemService(Context.VIBRATOR_SERVICE);
        vibrator.vibrate(150);
        for (KeyRect keyRect : keyRects) {
            keyRect.setError();
        }
    }

    /**
     * Set passcode digit length
     *
     * @param length - {@code int} digit length to be set
     */
    public void setDigitLength(int length) {
        this.digits = length;
        invalidate();
    }

    /**
     * get digit length
     *
     * @return - {@code int} current length of passcode
     */
    public int getDigitLength() {
        return digits;
    }

    /**
     * Set current passcode text
     *
     * @param code - {@code String} passcode string to be set
     */
    public void setPassCode(String code) {
        this.passCodeText = code;
        setFilledCount(code.length());
        invalidate();
    }

    /**
     * Get current passcode entered
     *
     * @return - {@code String} current passcode entered
     */
    public String getPassCodeText() {
        return passCodeText;
    }
}
