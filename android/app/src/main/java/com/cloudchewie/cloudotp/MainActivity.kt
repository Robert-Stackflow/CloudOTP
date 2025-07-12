package com.cloudchewie.cloudotp;

import io.flutter.embedding.android.FlutterFragmentActivity

import androidx.annotation.NonNull
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant.*
class MainActivity : FlutterFragmentActivity() {
    private val CHANNEL = "android/back/desktop"
    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        registerWith(flutterEngine);
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { methodCall, result ->
            if (methodCall.method == "backDesktop") {
                result.success(true)
                moveTaskToBack(false)
            }
        }
    }
}