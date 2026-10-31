package com.cjcdev.systemmonitor

import android.content.pm.ActivityInfo
import android.hardware.SensorManager
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.view.MotionEvent
import android.view.OrientationEventListener
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {

    private val mainHandler = Handler(Looper.getMainLooper())
    private var orientationListener: OrientationEventListener? = null

    private fun neutralizeMouseCursor() {
        flutterEngine?.let { engine ->
            engine.mouseCursorChannel.channel.setMethodCallHandler { _, result ->
                result.success(true)
            }
            engine.mouseCursorChannel.setMethodHandler(null)
        }
    }

    private fun setupOrientationListener() {
        orientationListener = object : OrientationEventListener(this, SensorManager.SENSOR_DELAY_NORMAL) {
            override fun onOrientationChanged(orientation: Int) {
                if (orientation == ORIENTATION_UNKNOWN) return

                // 45° a 135° -> Aparelho deitado com o topo para a direita (Reverse Landscape / Seascape)
                // 225° a 315° -> Aparelho deitado com o topo para a esquerda (Landscape Normal)
                if (orientation in 60..120) {
                    if (requestedOrientation != ActivityInfo.SCREEN_ORIENTATION_REVERSE_LANDSCAPE) {
                        requestedOrientation = ActivityInfo.SCREEN_ORIENTATION_REVERSE_LANDSCAPE
                    }
                } else if (orientation in 240..300) {
                    if (requestedOrientation != ActivityInfo.SCREEN_ORIENTATION_LANDSCAPE) {
                        requestedOrientation = ActivityInfo.SCREEN_ORIENTATION_LANDSCAPE
                    }
                }
            }
        }
        if (orientationListener?.canDetectOrientation() == true) {
            orientationListener?.enable()
        }
    }

    override fun setRequestedOrientation(requestedOrientation: Int) {
        // Impede o Flutter de enviar USER_LANDSCAPE (11) ou LANDSCAPE (0) que desativa o sensor no Android 5.0.1
        if (requestedOrientation == 11 || requestedOrientation == ActivityInfo.SCREEN_ORIENTATION_LANDSCAPE) {
            super.setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_SENSOR_LANDSCAPE)
        } else {
            super.setRequestedOrientation(requestedOrientation)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        neutralizeMouseCursor()
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        requestedOrientation = ActivityInfo.SCREEN_ORIENTATION_SENSOR_LANDSCAPE
        setupOrientationListener()

        mainHandler.post { neutralizeMouseCursor() }
        mainHandler.postDelayed({ neutralizeMouseCursor() }, 300)
        mainHandler.postDelayed({ neutralizeMouseCursor() }, 1000)
    }

    override fun onResume() {
        super.onResume()
        neutralizeMouseCursor()
        orientationListener?.enable()
    }

    override fun onPause() {
        super.onPause()
        orientationListener?.disable()
    }

    override fun onDestroy() {
        super.onDestroy()
        orientationListener?.disable()
    }

    override fun onPostResume() {
        super.onPostResume()
        neutralizeMouseCursor()
    }

    override fun onFlutterUiDisplayed() {
        super.onFlutterUiDisplayed()
        neutralizeMouseCursor()
    }

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
