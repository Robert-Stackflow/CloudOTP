package com.ivehement.saf.plugin

import android.os.Build
import io.flutter.plugin.common.MethodChannel

fun MethodChannel.Result.notSupported(
  method: String,
  minSdk: Int,
  debug: Map<String, String> = emptyMap()
) {
  error(
    EXCEPTION_NOT_SUPPORTED,
    "Unsupported API. Current API: ${Build.VERSION.SDK_INT} | Required: $minSdk",
    mapOf("method" to method, *debug.toList().toTypedArray())
  )
}
