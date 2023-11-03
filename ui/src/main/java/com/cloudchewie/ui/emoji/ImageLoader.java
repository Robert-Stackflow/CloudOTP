package com.cloudchewie.ui.emoji;

import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.widget.ImageView;

import androidx.annotation.NonNull;

import com.cloudchewie.ui.emoji.listener.ImageBase;

import java.io.File;
import java.io.IOException;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * use XhsEmotionsKeyboard(https://github.com/w446108264/XhsEmoticonsKeyboard)
 * author: sj
 */
public class ImageLoader implements ImageBase {

    private volatile static ImageLoader instance;
    private volatile static Pattern NUMBER_PATTERN = Pattern.compile("[0-9]*");
    protected final Context context;

    public ImageLoader(@NonNull Context context) {
        this.context = context.getApplicationContext();
    }

    public static ImageLoader getInstance(Context context) {
        if (instance == null) {
            synchronized (ImageLoader.class) {
                if (instance == null) {
                    instance = new ImageLoader(context);
                }
            }
        }
        return instance;
    }

    /**
     * @param uriStr
     * @param imageView
     * @throws IOException
     */
    @Override
    public void displayImage(String uriStr, ImageView imageView) throws IOException {
        switch (ImageBase.Scheme.ofUri(uriStr)) {
            case FILE:
                displayImageFromFile(uriStr, imageView);
                return;
            case ASSETS:
                displayImageFromAssets(uriStr, imageView);
                return;
            case DRAWABLE:
                displayImageFromDrawable(uriStr, imageView);
                return;
            case HTTP:
            case HTTPS:
                displayImageFromNetwork(uriStr, imageView);
                return;
            case CONTENT:
                displayImageFromContent(uriStr, imageView);
                return;
            case UNKNOWN:
            default:
                Matcher m = NUMBER_PATTERN.matcher(uriStr);
                if (m.matches()) {
                    displayImageFromResource(Integer.parseInt(uriStr), imageView);
                    return;
                }
                displayImageFromOtherSource(uriStr, imageView);
        }
    }

    /**
     * From File
     *
     * @param imageUri
     * @param imageView
     */
    protected void displayImageFromFile(String imageUri, ImageView imageView) {
        String filePath = Scheme.FILE.crop(imageUri);
        File file = new File(filePath);
        if (!file.exists()) {
            return;
        }
        Bitmap bitmap;
        try {
            bitmap = BitmapFactory.decodeFile(filePath);
        } catch (Exception e) {
            e.printStackTrace();
            return;
        }
        if (imageView != null) {
            imageView.setImageBitmap(bitmap);
        }
    }

    /**
     * From Assets
     *
     * @param imageUri
     * @param imageView
     */
    protected void displayImageFromAssets(String imageUri, ImageView imageView) {
        String filePath = Scheme.ASSETS.crop(imageUri);
        Bitmap bitmap;
        try {
            bitmap = BitmapFactory.decodeStream(context.getAssets().open(filePath));
        } catch (IOException e) {
            e.printStackTrace();
            return;
        }
        if (imageView != null) {
            imageView.setImageBitmap(bitmap);
        }
    }

    /**
     * From Drawable
     *
     * @param imageUri
     * @param imageView
     * @throws IOException
     */
    protected void displayImageFromDrawable(String imageUri, ImageView imageView) {
        String drawableIdString = Scheme.DRAWABLE.crop(imageUri);
        int resID = context.getResources().getIdentifier(drawableIdString, "mipmap", context.getPackageName());
        if (resID <= 0) {
            resID = context.getResources().getIdentifier(drawableIdString, "drawable", context.getPackageName());
        }
        if (resID > 0 && imageView != null) {
            imageView.setImageResource(resID);
        }
    }

    /**
     * From Resource
     *
     * @param resID
     * @param imageView
     */
    protected void displayImageFromResource(int resID, ImageView imageView) {
        if (resID > 0 && imageView != null) {
            imageView.setImageResource(resID);
        }
    }

    /**
     * From Net
     *
     * @param imageUri
     * @param extra
     */
    protected void displayImageFromNetwork(String imageUri, Object extra) {
    }


    /**
     * From Content
     *
     * @param imageUri
     * @param imageView
     */
    protected void displayImageFromContent(String imageUri, ImageView imageView) {
    }

    /**
     * From OtherSource
     *
     * @param imageUri
     * @param imageView
     */
    protected void displayImageFromOtherSource(String imageUri, ImageView imageView) {
    }

}
