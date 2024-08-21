package com.linusu.flutter_web_auth_2

import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import androidx.browser.customtabs.CustomTabsClient
import androidx.browser.customtabs.CustomTabsIntent

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class FlutterWebAuth2Plugin(
    private var context: Context? = null,
    private var channel: MethodChannel? = null
) : MethodCallHandler, FlutterPlugin {
    companion object {
        val callbacks = mutableMapOf<String, Result>()
    }

    private fun initInstance(messenger: BinaryMessenger, context: Context) {
        this.context = context
        channel = MethodChannel(messenger, "flutter_web_auth_2")
        channel?.setMethodCallHandler(this)
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        initInstance(binding.binaryMessenger, binding.applicationContext)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = null
        channel = null
    }

    override fun onMethodCall(call: MethodCall, resultCallback: Result) {
        when (call.method) {
            "authenticate" -> {
                val url = Uri.parse(call.argument("url"))
                val callbackUrlScheme = call.argument<String>("callbackUrlScheme")!!
                val options = call.argument<Map<String, Any>>("options")!!

                callbacks[callbackUrlScheme] = resultCallback
                val intent = CustomTabsIntent.Builder().build()
                val keepAliveIntent = Intent(context, KeepAliveService::class.java)

                intent.intent.addFlags(options["intentFlags"] as Int)
                intent.intent.putExtra("android.support.customtabs.extra.KEEP_ALIVE", keepAliveIntent)

                val targetPackage = findTargetBrowserPackageName(options)
                if (targetPackage != null) {
                    intent.intent.setPackage(targetPackage)
                }
                intent.launchUrl(context!!, url)
            }

            "cleanUpDanglingCalls" -> {
                callbacks.forEach { (_, danglingResultCallback) ->
                    danglingResultCallback.error("CANCELED", "User canceled login", null)
                }
                callbacks.clear()
                resultCallback.success(null)
            }

            else -> resultCallback.notImplemented()
        }
    }

    /**
     * Find Support CustomTabs Browser.
     *
     * Priority:
     * 1. Chrome
     * 2. Custom Browser Order
     * 3. default Browser
     * 4. Installed Browser
     */
    private fun findTargetBrowserPackageName(options: Map<String, Any>): String? {
        val chromePackage = "com.android.chrome"
        //if installed chrome, use chrome at first
        if (isSupportCustomTabs(chromePackage)) {
            return chromePackage
        }

        @Suppress("UNCHECKED_CAST")
        val customTabsPackageOrder = (options["customTabsPackageOrder"] as Iterable<String>?) ?: emptyList()
        //check target browser
        var targetPackage = customTabsPackageOrder.firstOrNull { isSupportCustomTabs(it) }
        if (targetPackage != null) {
            return targetPackage
        }

        //check default browser
        val defaultBrowserSupported = CustomTabsClient.getPackageName(context!!, emptyList<String>()) != null
        if (defaultBrowserSupported) {
            return null;
        }
        //check installed browser
        val allBrowsers = getInstalledBrowsers()
        targetPackage = allBrowsers.firstOrNull { isSupportCustomTabs(it) }

        return targetPackage
    }

    private fun getInstalledBrowsers(): List<String> {
        // Get all apps that can handle VIEW intents
        val activityIntent = Intent(Intent.ACTION_VIEW, Uri.parse("http://"))
        val packageManager = context!!.packageManager
        val viewIntentHandlers = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            packageManager.queryIntentActivities(activityIntent, PackageManager.MATCH_ALL)
        } else {
            packageManager.queryIntentActivities(activityIntent, 0)
        }

        val allBrowser = viewIntentHandlers.map { it.activityInfo.packageName }.sortedWith(compareBy {
            if (setOf(
                    "com.android.chrome",
                    "com.chrome.beta",
                    "com.chrome.dev",
                    "com.microsoft.emmx"
                ).contains(it)
            ) {
                return@compareBy -1
            }

            //FireFox default is not enable ,must enable in the browser settings.
            if (setOf("org.mozilla.firefox").contains(it)) {
                return@compareBy 1
            }
            return@compareBy 0
        })

        return allBrowser
    }

    private fun isSupportCustomTabs(packageName: String): Boolean {
        val value = CustomTabsClient.getPackageName(
            context!!,
            arrayListOf(packageName),
            true
        )
        return value == packageName
    }

}
