package com.route.islami

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import androidx.core.content.ContextCompat

/**
 * Fired by the exact AlarmManager alarm at a prayer time. Starts the foreground
 * [AdhanService] to play the full adhan, then re-arms this prayer for tomorrow
 * (exact alarms are one-shot). Drift from the +24h re-arm is corrected whenever
 * the app is opened and reschedules from fresh prayer times.
 */
class AdhanReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val prayer = intent.getStringExtra(AdhanScheduler.EXTRA_PRAYER) ?: "الصلاة"
        val isFajr = intent.getBooleanExtra(AdhanScheduler.EXTRA_IS_FAJR, false)
        val requestCode = intent.getIntExtra(AdhanScheduler.EXTRA_REQUEST_CODE, 0)
        val hour = intent.getIntExtra(AdhanScheduler.EXTRA_HOUR, 0)
        val minute = intent.getIntExtra(AdhanScheduler.EXTRA_MINUTE, 0)

        val serviceIntent = Intent(context, AdhanService::class.java).apply {
            putExtra(AdhanScheduler.EXTRA_PRAYER, prayer)
            putExtra(AdhanScheduler.EXTRA_IS_FAJR, isFajr)
        }
        ContextCompat.startForegroundService(context, serviceIntent)

        AdhanScheduler.rescheduleNextDay(
            context,
            requestCode,
            AdhanScheduler.Adhan(prayer, hour, minute, isFajr),
        )
    }
}
