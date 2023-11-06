package com.cloudchewie.otp.activity;

import android.Manifest;
import android.content.pm.PackageManager;
import android.net.Uri;
import android.os.Bundle;
import android.view.Surface;
import android.view.View;
import android.widget.ImageView;
import android.widget.ProgressBar;

import androidx.annotation.NonNull;
import androidx.camera.core.AspectRatio;
import androidx.camera.core.CameraSelector;
import androidx.camera.core.ImageAnalysis;
import androidx.camera.core.ImageProxy;
import androidx.camera.core.Preview;
import androidx.camera.lifecycle.ProcessCameraProvider;
import androidx.camera.view.PreviewView;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;

import com.cloudchewie.otp.R;
import com.cloudchewie.otp.entity.OtpToken;
import com.cloudchewie.otp.util.authenticator.OtpTokenParser;
import com.cloudchewie.otp.util.authenticator.QrCodeParser;
import com.cloudchewie.otp.util.database.LocalStorage;
import com.cloudchewie.otp.util.enumeration.EventBusCode;
import com.cloudchewie.ui.custom.IDialog;
import com.cloudchewie.ui.custom.IToast;
import com.google.common.util.concurrent.ListenableFuture;
import com.google.zxing.qrcode.QRCodeReader;
import com.jeremyliao.liveeventbus.LiveEventBus;

import java.util.concurrent.ExecutionException;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

public class ScanActivity extends BaseActivity implements ImageAnalysis.Analyzer {

    private int REQUEST_CODE_PERMISSIONS = 10;

    private String[] REQUIRED_PERMISSIONS = new String[]{Manifest.permission.CAMERA};

    private boolean foundToken = false;
    private ImageView imageView;
    private ProgressBar progressBar;
    private PreviewView previewView;
    private ExecutorService executorService;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_scan);
        imageView = findViewById(R.id.activity_authenticator_image);
        progressBar = findViewById(R.id.activity_authenticator_progress);
        previewView = findViewById(R.id.activity_authenticator_scan_view_finder);
        executorService = Executors.newSingleThreadExecutor();
        if (allPermissionsGranted()) {
            previewView.post(this::startCamera);
        } else {
            ActivityCompat.requestPermissions(this, REQUIRED_PERMISSIONS, REQUEST_CODE_PERMISSIONS);
        }
    }

    private void startCamera() {
        ListenableFuture<ProcessCameraProvider> cameraProviderFuture = ProcessCameraProvider.getInstance(this);
        CameraSelector cameraSelector = new CameraSelector.Builder().requireLensFacing(CameraSelector.LENS_FACING_BACK).build();
        cameraProviderFuture.addListener(() -> {
            Preview preview = new Preview.Builder().setTargetAspectRatio(AspectRatio.RATIO_16_9).setTargetRotation(Surface.ROTATION_0).build();
            preview.setSurfaceProvider(previewView.getSurfaceProvider());

            ImageAnalysis imageAnalysis = new ImageAnalysis.Builder().setBackgroundExecutor(executorService).setTargetRotation(Surface.ROTATION_0).setTargetAspectRatio(AspectRatio.RATIO_16_9).build();
            imageAnalysis.setAnalyzer(executorService, this::analyzeImage);

            ProcessCameraProvider cameraProvider;
            try {
                cameraProvider = cameraProviderFuture.get();
            } catch (ExecutionException | InterruptedException e) {
                throw new RuntimeException(e);
            }

            cameraProvider.unbindAll();
            cameraProvider.bindToLifecycle(ScanActivity.this, cameraSelector, preview, imageAnalysis);
        }, ContextCompat.getMainExecutor(this));
    }

    @Override
    public void onRequestPermissionsResult(int requestCode, @NonNull String[] permissions, @NonNull int[] grantResults) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults);
        if (requestCode == REQUEST_CODE_PERMISSIONS) {
            if (allPermissionsGranted()) {
                previewView.post(this::startCamera);
            } else {
                IToast.showBottom(this, getString(R.string.permission_fail_camera));
                finish();
            }
        }
    }

    private Boolean allPermissionsGranted() {
        for (String permission : REQUIRED_PERMISSIONS) {
            if (ContextCompat.checkSelfPermission(this, permission) != PackageManager.PERMISSION_GRANTED) {
                return false;
            }
        }
        return true;
    }

    private void analyzeImage(ImageProxy imageProxy) {
        if (foundToken) {
            return;
        }
        String tokenString;
        tokenString = new QrCodeParser(new QRCodeReader()).parseQRCode(imageProxy);
        if (tokenString == null) {
            imageProxy.close();
            return;
        }
        foundToken = true;
        try {
            OtpToken t = OtpTokenParser.createFromUri((Uri.parse(tokenString)));
            OtpToken exist = LocalStorage.getAppDatabase().otpTokenDao().get(t.getIssuer(), t.getAccount());
            runOnUiThread(() -> {
                progressBar.setVisibility(View.GONE);
                if (exist != null) {
                    IDialog dialog = new IDialog(ScanActivity.this);
                    dialog.setTitle(getString(R.string.dialog_title_replace_token));
                    dialog.setMessage(String.format(getString(R.string.dialog_content_replace_token), t.getIssuer(), t.getAccount()));
                    dialog.setOnCancelListener(dialogInterface -> finish());
                    dialog.setOnClickBottomListener(new IDialog.OnClickBottomListener() {
                        @Override
                        public void onPositiveClick() {
                            exist.setSecret(t.getSecret());
                            LocalStorage.getAppDatabase().otpTokenDao().update(exist);
                            IToast.showBottom(ScanActivity.this, getString(R.string.edit_token_success));
                            LiveEventBus.get(EventBusCode.CHANGE_TOKEN.getKey()).post("");
                            finish();
                        }

                        @Override
                        public void onNegtiveClick() {
                            finish();
                        }

//                        @Override
//                        public void onCloseClick() {
//                            finish();
//                        }
                    });
                    dialog.show();
                } else {
                    LocalStorage.getAppDatabase().otpTokenDao().insert(t);
                    IToast.showBottom(ScanActivity.this, getString(R.string.add_token_success));
                    LiveEventBus.get(EventBusCode.CHANGE_TOKEN.getKey()).post("");
                    finish();
                }
            });
        } catch (Throwable e) {
            runOnUiThread(() -> {
                IToast.showBottom(this, getString(R.string.parse_token_fail));
                finish();
            });
        }
    }

    @Override
    public void analyze(@NonNull ImageProxy image) {

    }
}
