package com.cjcdev.systemmonitor

import android.content.Context
import android.content.pm.ActivityInfo
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.view.MotionEvent
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity(), SensorEventListener {

    private val mainHandler = Handler(Looper.getMainLooper())
    private var sensorManager: SensorManager? = null
    private var orientationSensor: Sensor? = null
    private var isReverseLandscape = true

    companion object {
        private const val ORIENTATION_CHANNEL = "com.cjcdev.systemmonitor/orientation"
    }

    private fun neutralizeMouseCursor() {
        flutterEngine?.let { engine ->
            engine.mouseCursorChannel.channel.setMethodCallHandler { _, result ->
                result.success(true)
            }
            engine.mouseCursorChannel.setMethodHandler(null)
        }
    }

    private fun setupOrientationMethodChannel(flutterEngine: FlutterEngine) {
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ORIENTATION_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "setReverseLandscape" -> {
                    val reverse = call.argument<Boolean>("reverse") ?: true
                    setScreenOrientation(reverse)
                    result.success(true)
                }
                "toggleOrientation" -> {
                    isReverseLandscape = !isReverseLandscape
                    setScreenOrientation(isReverseLandscape)
                    result.success(isReverseLandscape)
                }
                "isReverseLandscape" -> {
                    result.success(isReverseLandscape)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun setScreenOrientation(reverse: Boolean) {
        isReverseLandscape = reverse
        val target = if (reverse) {
            ActivityInfo.SCREEN_ORIENTATION_REVERSE_LANDSCAPE
        } else {
            ActivityInfo.SCREEN_ORIENTATION_LANDSCAPE
        }
        if (requestedOrientation != target) {
            requestedOrientation = target
        }
    }

    private fun setupOrientationSensor() {
        sensorManager = getSystemService(Context.SENSOR_SERVICE) as? SensorManager
        // No LG Leon (Android 5.0.1), o sensor primário é o TYPE_ORIENTATION (tipo 3)
        orientationSensor = sensorManager?.getDefaultSensor(Sensor.TYPE_ORIENTATION)
            ?: sensorManager?.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)

        orientationSensor?.let { sensor ->
            sensorManager?.registerListener(this, sensor, SensorManager.SENSOR_DELAY_UI)
        }
    }

    override fun onSensorChanged(event: SensorEvent?) {
        if (event == null) return
        if (event.sensor.type == Sensor.TYPE_ORIENTATION) {
            val roll = event.values[2] // Roll inclinação lateral (-90 a 90)
            if (roll > 45 && !isReverseLandscape) {
                setScreenOrientation(true)
            } else if (roll < -45 && isReverseLandscape) {
                setScreenOrientation(false)
            }
        }
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}

    override fun setRequestedOrientation(requestedOrientation: Int) {
        // Permite rotação bidirecional livre em modo horizontal
        if (requestedOrientation == 11) {
            super.setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_SENSOR_LANDSCAPE)
        } else {
            super.setRequestedOrientation(requestedOrientation)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        neutralizeMouseCursor()
        setupOrientationMethodChannel(flutterEngine)
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Mantém a tela do smartphone permanentemente ligada enquanto o monitor estiver em primeiro plano
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)

        // Padrão inicial no Galaxy A71: Sensor Landscape (orientação natural nos dois sentidos)
        requestedOrientation = ActivityInfo.SCREEN_ORIENTATION_SENSOR_LANDSCAPE
        setupOrientationSensor()

        mainHandler.post { neutralizeMouseCursor() }
        mainHandler.postDelayed({ neutralizeMouseCursor() }, 300)
    }

    override fun onResume() {
        super.onResume()
        neutralizeMouseCursor()
        orientationSensor?.let {
            sensorManager?.registerListener(this, it, SensorManager.SENSOR_DELAY_UI)
        }
    }

    override fun onPause() {
        super.onPause()
        sensorManager?.unregisterListener(this)
    }

    override fun onDestroy() {
        super.onDestroy()
        sensorManager?.unregisterListener(this)
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
