package com.route.islami

import android.content.Intent
import android.hardware.GeomagneticField
import android.net.Uri
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    // Exposes the magnetic declination so the Qibla compass can convert the
    // magnetometer's magnetic-north heading to true north. GeomagneticField is
    // Android's own WMM implementation — no extra dependency, no data table.
    private val geomagneticChannel = "islami/geomagnetic"

    // Schedules/cancels the native adhan alarms (see AdhanScheduler).
    private val adhanChannel = "islami/adhan"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, geomagneticChannel)
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

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, adhanChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "schedule" -> {
                        val list = call.argument<List<Map<String, Any>>>("adhans")
                            ?: emptyList()
                        val adhans = list.map {
                            @Suppress("UNCHECKED_CAST")
                            val times = (it["times"] as? List<Number> ?: emptyList())
                                .map { time -> time.toLong() }
                            val name = it["name"] as String
                            AdhanScheduler.Adhan(
                                name,
                                it["displayName"] as? String ?: name,
                                it["fajr"] as Boolean,
                                times,
                            )
                        }
                        AdhanScheduler.schedule(applicationContext, adhans)
                        result.success(null)
                    }
                    "canScheduleExact" -> {
                        result.success(
                            AdhanScheduler.canScheduleExact(applicationContext),
                        )
                    }
                    "requestExactAlarms" -> {
                        // Opens the system screen for this app; there is no
                        // in-app dialog for this permission.
                        if (android.os.Build.VERSION.SDK_INT >=
                            android.os.Build.VERSION_CODES.S
                        ) {
                            startActivity(
                                Intent(
                                    Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM,
                                    Uri.parse("package:$packageName"),
                                ),
                            )
                        }
                        result.success(null)
                    }
                    "cancel" -> {
                        AdhanScheduler.cancel(applicationContext)
                        result.success(null)
                    }
                    "stopNow" -> {
                        startService(
                            Intent(this, AdhanService::class.java)
                                .apply { action = AdhanService.ACTION_STOP },
                        )
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
