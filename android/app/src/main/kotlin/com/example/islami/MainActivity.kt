package com.example.islami

import android.hardware.GeomagneticField
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    // Exposes the magnetic declination so the Qibla compass can convert the
    // magnetometer's magnetic-north heading to true north. GeomagneticField is
    // Android's own WMM implementation — no extra dependency, no data table.
    private val channelName = "islami/geomagnetic"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                if (call.method == "getDeclination") {
                    val lat = call.argument<Double>("lat")
                    val lng = call.argument<Double>("lng")
                    if (lat == null || lng == null) {
                        result.error("ARG", "lat/lng required", null)
                        return@setMethodCallHandler
                    }
                    val altitude = call.argument<Double>("altitude") ?: 0.0
                    val field = GeomagneticField(
                        lat.toFloat(),
                        lng.toFloat(),
                        altitude.toFloat(),
                        System.currentTimeMillis()
                    )
                    result.success(field.declination.toDouble())
                } else {
                    result.notImplemented()
                }
            }
    }
}
