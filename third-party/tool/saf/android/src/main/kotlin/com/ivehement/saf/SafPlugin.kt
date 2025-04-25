package com.ivehement.saf

import com.ivehement.saf.api.StorageAccessFramework

import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import android.os.*
import android.os.Build.VERSION
import android.util.Log
import android.content.Context
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.PluginRegistry
import io.flutter.plugin.common.BinaryMessenger

const val ROOT_CHANNEL = "com.ivehement.plugins/saf"

class SafPlugin: FlutterPlugin, ActivityAware {
  
    /**
     * `DocumentFile` API channel
     */
    private val storageAccessFrameworkApi = StorageAccessFramework(this)
  
    lateinit var context: Context
    var binding: ActivityPluginBinding? = null
  
    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
      context = flutterPluginBinding.applicationContext
      /** Setup `StorageAccessFramework` API */
      storageAccessFrameworkApi.startListening(flutterPluginBinding.binaryMessenger)
    }
  
    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
      this.binding = binding
  
      storageAccessFrameworkApi.startListeningToActivity()
    }
  
    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
      storageAccessFrameworkApi.stopListening()
    }
  
    override fun onDetachedFromActivityForConfigChanges() {
      storageAccessFrameworkApi.stopListeningToActivity()
    }
  
    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
      this.binding = binding
    }
  
    override fun onDetachedFromActivity() {
      binding = null
    }
}