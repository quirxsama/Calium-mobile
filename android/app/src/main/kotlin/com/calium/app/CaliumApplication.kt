package com.calium.app

import android.app.Application
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel

class CaliumApplication : Application() {
    // Owned by the process, so closing the Activity does not cancel Dart transfers.
    // Lazy initialization avoids running the UI entrypoint for notification-only starts.
    val flutterEngine: FlutterEngine by lazy {
        FlutterEngine(this).also { engine ->
            val channel = MethodChannel(
                engine.dartExecutor.binaryMessenger, "com.calium.app/download_service"
            )
            downloadChannel = channel
            channel.setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        "startForeground", "updateProgress" -> {
                            DownloadForegroundService.startService(
                                this,
                                call.argument<String>("title") ?: "Anime İndiriliyor",
                                call.argument<String>("content") ?: "İndirme devam ediyor...",
                                call.argument<Int>("progress") ?: 0,
                                call.argument<String>("speed")
                            )
                            result.success(true)
                        }
                        "stopForeground" -> {
                            DownloadForegroundService.stopService(this)
                            result.success(true)
                        }
                        else -> result.notImplemented()
                    }
                } catch (e: Exception) {
                    result.error("DOWNLOAD_SERVICE_UNAVAILABLE", e.message, null)
                }
            }
            engine.dartExecutor.executeDartEntrypoint(DartExecutor.DartEntrypoint.createDefault())
        }
    }

    private var downloadChannel: MethodChannel? = null

    fun onDownloadTimeout() {
        downloadChannel?.invokeMethod("foregroundTimeout", null)
    }
}
