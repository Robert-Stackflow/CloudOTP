package com.cloudchewie.ui.record;

import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.graphics.Path;
import android.graphics.Rect;
import android.util.AttributeSet;
import android.view.View;

import androidx.annotation.NonNull;

import com.cloudchewie.ui.R;
import com.cloudchewie.ui.ThemeUtil;
import com.cloudchewie.util.ui.DarkModeUtil;

import org.jetbrains.annotations.Contract;

public class RecordControllerView extends View {

    private final static String TAG = "RecordControllerView";
    private final static int INIT_STATE = 0;
    private final static int MOVING_LEFT = 1;
    private final static int MOVE_ON_LEFT = 2;
    private final static int MOVING_RIGHT = 3;
    private final static int MOVE_ON_RIGHT = 4;
    private final int MAX_RADIUS = 90;
    private int mWidth;
    private Path mPath;
    private Paint mPaint;
    private int mRecordBtnLeft;
    private int mRecordBtnRight;
    private int mRecordBtnTop;
    private int mRecordBtnBottom;
    private RecordVoiceButton mRecordVoiceBtn;
    private int mCurrentState = 0;
    private float mNowX;
    private Bitmap mCancelBmp;
    private Bitmap mPreviewBmp;
    private Bitmap mCancelPresBmp;
    private Bitmap mPreviewPresBmp;
    private Rect mLeftRect;
    private Rect mRightRect;
    //    private int getRectTop();
    private OnRecordActionListener mListener;

    public RecordControllerView(Context context) {
        super(context);
        init();
    }

    public RecordControllerView(Context context, AttributeSet attrs) {
        super(context, attrs);
        init();
    }

    @NonNull
    @Contract("_ -> new")
    private Rect getRect(@NonNull Bitmap bitmap) {
        return new Rect(0, 0, bitmap.getWidth(), bitmap.getHeight());
    }

    private void init() {
        mPath = new Path();
        mPaint = new Paint();
        mCancelBmp = BitmapFactory.decodeResource(getResources(), R.drawable.img_cancel_white);
        mPreviewBmp = BitmapFactory.decodeResource(getResources(), R.drawable.img_play_white);
        mCancelPresBmp = BitmapFactory.decodeResource(getResources(), R.drawable.img_cancel_white);
        mPreviewPresBmp = BitmapFactory.decodeResource(getResources(), R.drawable.img_play_white);
    }

    private int getCy() {
        return getTop() + 100;
    }

    private double getRadius() {
        return Math.sqrt(2) * 25;
    }

    public void setWidth(int width) {
        mWidth = width;
        mLeftRect = new Rect((int) (150 - getRadius()), (int) (getCy() - getRadius()), (int) (150 + getRadius()), (int) (getCy() + getRadius()));
        mRightRect = new Rect((int) (mWidth - 145 - getRadius()), (int) (getCy() - getRadius()), (int) (mWidth - 145 + getRadius()), (int) (getCy() + getRadius()));
    }

    @Override
    protected void onDraw(Canvas canvas) {
        super.onDraw(canvas);
        int color = DarkModeUtil.isDarkMode(getContext()) ? getResources().getColor(R.color.card_pressed_background) : getResources().getColor(R.color.color_light_gray);
        switch (mCurrentState) {
            case INIT_STATE:
                mPaint.setColor(color);
                mPaint.setStyle(Paint.Style.FILL);
                canvas.drawCircle(150, getCy(), 60, mPaint);
                canvas.drawCircle(mWidth - 155, getCy(), 60, mPaint);
                mPaint.setColor(Color.GRAY);
                canvas.drawBitmap(mCancelBmp, null, mLeftRect, mPaint);
                canvas.drawBitmap(mPreviewBmp, null, mRightRect, mPaint);
                break;
            case MOVING_LEFT:
                float radius;
                if (mNowX < 150 + MAX_RADIUS) {
                    radius = MAX_RADIUS;
                } else {
                    radius = 40.0f * (mRecordBtnLeft - mNowX) / (mRecordBtnLeft - 250.0f) + 60.0f;
                    if (radius > MAX_RADIUS) radius = MAX_RADIUS;
                }
                mPaint.setColor(color);
                canvas.drawCircle(150, getCy(), radius, mPaint);
                canvas.drawCircle(mWidth - 155, getCy(), 60, mPaint);
                mPaint.setColor(Color.GRAY);
                canvas.drawBitmap(mCancelBmp, null, mLeftRect, mPaint);
                canvas.drawBitmap(mPreviewBmp, null, mRightRect, mPaint);
                break;
            case MOVING_RIGHT:
                if (mNowX > mWidth - 150 - MAX_RADIUS) {
                    radius = MAX_RADIUS;
                } else {
                    radius = 60.0f * (mNowX - mRecordBtnRight) / (mWidth - mRecordBtnRight) + 60.0f;
                }
                mPaint.setColor(color);
                canvas.drawCircle(150, getCy(), 60, mPaint);
                canvas.drawCircle(mWidth - 155, getCy(), radius, mPaint);
                mPaint.setColor(Color.GRAY);
                canvas.drawBitmap(mCancelBmp, null, mLeftRect, mPaint);
                canvas.drawBitmap(mPreviewBmp, null, mRightRect, mPaint);
                break;
            case MOVE_ON_LEFT:
                mPaint.setColor(getResources().getColor(R.color.color_red));
                canvas.drawCircle(150, getCy(), MAX_RADIUS, mPaint);
                mPaint.setColor(color);
                canvas.drawBitmap(mCancelPresBmp, null, mLeftRect, mPaint);
                canvas.drawCircle(mWidth - 155, getCy(), 60, mPaint);
                canvas.drawBitmap(mPreviewBmp, null, mRightRect, mPaint);
                break;
            case MOVE_ON_RIGHT:
                mPaint.setColor(ThemeUtil.getPrimaryColor(getContext()));
                canvas.drawCircle(mWidth - 155, getCy(), MAX_RADIUS, mPaint);
                mPaint.setColor(color);
                canvas.drawCircle(150, getCy(), 60, mPaint);
                canvas.drawBitmap(mCancelBmp, null, mLeftRect, mPaint);
                canvas.drawBitmap(mPreviewPresBmp, null, mRightRect, mPaint);
                break;
        }
    }

    public void onActionDown() {
        if (mListener != null) mListener.onStart();
    }

    public void onActionMove(float x, float y) {
        mNowX = x;
        if (x <= 150 + MAX_RADIUS && y >= getCy() - mRecordBtnTop - MAX_RADIUS && y <= getCy() + MAX_RADIUS - mRecordBtnTop) {
            mCurrentState = MOVE_ON_LEFT;
            if (mListener != null) {
                mListener.onMovedLeft();
            }
        } else if (x > getCy() + MAX_RADIUS && x < mRecordBtnLeft) {
            mCurrentState = MOVING_LEFT;
            if (mListener != null) {
                mListener.onMoving();
            }
        } else if (mRecordBtnLeft < x && x < mRecordBtnRight) {
            mCurrentState = INIT_STATE;
            if (mListener != null) {
                mListener.onMoving();
            }
        } else if (x > mRecordBtnRight && x < mWidth - 150 - MAX_RADIUS) {
            mCurrentState = MOVING_RIGHT;
            if (mListener != null) {
                mListener.onMoving();
            }
        } else if (x >= mWidth - 150 - MAX_RADIUS && y > getCy() - mRecordBtnTop - MAX_RADIUS && y < getCy() + MAX_RADIUS - mRecordBtnTop) {
            mCurrentState = MOVE_ON_RIGHT;
            if (mListener != null) {
                mListener.onMovedRight();
            }
        }
        postInvalidate();
    }

    public void setRecordButton(@NonNull RecordVoiceButton button) {
        mRecordBtnLeft = button.getLeft();
        mRecordBtnRight = button.getRight();
        mRecordBtnTop = button.getTop();
        mRecordBtnBottom = button.getBottom();
        mRecordVoiceBtn = button;
    }

    public void onActionUp() {
        switch (mCurrentState) {
            case MOVE_ON_RIGHT:
                mRecordVoiceBtn.finishRecord(true);
                if (mListener != null) {
                    mListener.onRightUpTapped();
                }
                break;
            case MOVE_ON_LEFT:
                mRecordVoiceBtn.cancelRecord();
                if (mListener != null) {
                    mListener.onLeftUpTapped();
                }
                break;
            default:
                mRecordVoiceBtn.finishRecord(false);
                if (mListener != null) {
                    mListener.onFinish();
                }
        }
        mCurrentState = INIT_STATE;
        postInvalidate();
    }

    public void resetState() {
        mCurrentState = INIT_STATE;
        postInvalidate();
    }

    public void setOnControllerListener(OnRecordActionListener listener) {
        mListener = listener;
    }

    public interface OnRecordActionListener {

        void onStart();

        void onMoving();

        void onMovedLeft();

        void onMovedRight();

        void onRightUpTapped();

        void onLeftUpTapped();

        void onFinish();
    }
}
