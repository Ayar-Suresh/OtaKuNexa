package com.watch.otakunexa

import android.content.Intent
import android.content.pm.ApplicationInfo
import android.net.Uri
import android.provider.Settings
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity: FlutterActivity() {
    // 1. Channel for Sharing APK
    private val SHARE_CHANNEL = "com.watch.otakunexa/share"

    // 2. Channel for Opening App Info (Cache Clear)
    private val SETTINGS_CHANNEL = "app.settings/cache_clear"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // ---------------------------------------------------------
        // 🔹 HANDLER 1: APK Sharing Logic
        // ---------------------------------------------------------
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SHARE_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getApkPath") {
                try {
                    val appInfo: ApplicationInfo = context.applicationInfo
                    val apkPath = appInfo.sourceDir
                    result.success(apkPath)
                } catch (e: Exception) {
                    result.error("UNAVAILABLE", "Could not fetch APK path.", null)
                }
            } else {
                result.notImplemented()
            }
        }

        // ---------------------------------------------------------
        // 🔹 HANDLER 2: App Settings / Clear Cache Logic
        // ---------------------------------------------------------
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SETTINGS_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "openAppInfo") {
                try {
                    val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
                    val uri = Uri.fromParts("package", packageName, null)
                    intent.data = uri
                    startActivity(intent)
                    result.success(null)
                } catch (e: Exception) {
                    result.error("UNAVAILABLE", "Could not open App Info", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }
}