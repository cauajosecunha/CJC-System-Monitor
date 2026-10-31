package com.cjcdev.systemmonitor

import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.view.MotionEvent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val mainHandler = Handler(Looper.getMainLooper())

    private fun neutralizeMouseCursor() {
        flutterEngine?.let { engine ->
            // 1. Substitui o handler de nível de canal MethodChannel para responder sucesso imediatamente
            engine.mouseCursorChannel.channel.setMethodCallHandler { call, result ->
                result.success(true)
            }
            // 2. Anula o MouseCursorMethodHandler interno da engine
            engine.mouseCursorChannel.setMethodHandler(null)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        neutralizeMouseCursor()
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Agenda neutralizações após a view ser anexada
        mainHandler.post { neutralizeMouseCursor() }
        mainHandler.postDelayed({ neutralizeMouseCursor() }, 300)
        mainHandler.postDelayed({ neutralizeMouseCursor() }, 1000)
    }

    override fun onResume() {
        super.onResume()
        neutralizeMouseCursor()
    }

    override fun onPostResume() {
        super.onPostResume()
        neutralizeMouseCursor()
    }

    override fun onFlutterUiDisplayed() {
        super.onFlutterUiDisplayed()
        neutralizeMouseCursor()
    }

    // Intercepta eventos de hover do mouse antes de chegarem à hierarquia do Flutter.
    // No Android 5.0.1 (API 21), eventos de hover do Scrcpy tentam invocar
    // PointerIcon e HashMap.getOrDefault() que inexistem no SO Lollipop.
    override fun dispatchGenericMotionEvent(event: MotionEvent): Boolean {
        val action = event.actionMasked
        if (action == MotionEvent.ACTION_HOVER_MOVE ||
            action == MotionEvent.ACTION_HOVER_ENTER ||
            action == MotionEvent.ACTION_HOVER_EXIT) {
            return true
        }
        return super.dispatchGenericMotionEvent(event)
    }
}
