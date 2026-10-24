package com.example.farm_flutter

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            SUPABASE_CONFIG_CHANNEL,
        ).setMethodCallHandler { call, result ->
            if (call.method == "getSupabaseConfig") {
                result.success(
                    mapOf(
                        "url" to BuildConfig.SUPABASE_URL,
                        "anonKey" to BuildConfig.SUPABASE_ANON_KEY,
                    ),
                )
            } else {
                result.notImplemented()
            }
        }
    }

    private companion object {
        const val SUPABASE_CONFIG_CHANNEL = "com.example.farm_flutter/supabase_config"
    }
}
