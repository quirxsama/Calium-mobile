package com.calium.app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import android.content.Context

class MainActivity : FlutterActivity() {
    override fun provideFlutterEngine(context: Context): FlutterEngine =
        (application as CaliumApplication).flutterEngine

    override fun shouldDestroyEngineWithHost(): Boolean = false
}
