package com.sayegh.move_to_background;

import android.app.Activity;
import android.content.Context;
import android.util.Log;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;

/** MoveToBackgroundPlugin */
public class MoveToBackgroundPlugin implements FlutterPlugin, MethodCallHandler, ActivityAware {
  private static final String CHANNEL_NAME = "move_to_background";
  private MethodChannel channel;
  private static Activity activity;

  /** Plugin registration. */
  public static void registerWith(Registrar registrar) {
    if (registrar.activity() != null) {
      MoveToBackgroundPlugin.activity = registrar.activity();
    }
    MoveToBackgroundPlugin plugin = new MoveToBackgroundPlugin();
    plugin.setupChannel(registrar.messenger(), registrar.context());
  }

  @Override
  @SuppressWarnings("deprecation")
  public void onAttachedToEngine(FlutterPluginBinding binding) {
    setupChannel(binding.getFlutterEngine().getDartExecutor(), binding.getApplicationContext());
  }

  @Override
  public void onDetachedFromEngine(FlutterPluginBinding binding) {
    teardownChannel();
  }


  private void setupChannel(BinaryMessenger messenger, Context context) {
    channel = new MethodChannel(messenger, CHANNEL_NAME);
    channel.setMethodCallHandler(this);

  }

  private void teardownChannel() {
    channel.setMethodCallHandler(null);
    channel = null;
  }

  @Override
  public void onMethodCall(MethodCall call, Result result) {
    if (call.method.equals("moveTaskToBack")) {
      if (MoveToBackgroundPlugin.activity != null) {
        MoveToBackgroundPlugin.activity.moveTaskToBack(true);
      } else {
        Log.e("MoveToBackgroundPlugin", "moveTaskToBack failed: activity=null");
      }
      result.success(true);
    } else {
      result.notImplemented();
    }
  }


  @Override
  public void onAttachedToActivity(ActivityPluginBinding binding)
  {
    MoveToBackgroundPlugin.activity = binding.getActivity();
  }

  @Override
  public void onDetachedFromActivityForConfigChanges() {
    MoveToBackgroundPlugin.activity = null;
  }

  @Override
  public void onReattachedToActivityForConfigChanges(ActivityPluginBinding binding) {
    MoveToBackgroundPlugin.activity = binding.getActivity();
  }

  @Override
  public void onDetachedFromActivity() {
    MoveToBackgroundPlugin.activity = null;
  }

}
