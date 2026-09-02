package com.antigravity.file_manager

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val fileBridge = FileBridge(applicationContext)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, FileBridge.CHANNEL)
            .setMethodCallHandler(fileBridge)
    }
}
