package com.route.islami

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import androidx.core.content.ContextCompat

/**
 * Fired by the alarm at a prayer time. Starts the foreground [AdhanService] to
 * play the full adhan, then arms this prayer's next instant from the saved
 * schedule (alarms are one-shot), so the following day fires at that day's own
 * time rather than 24 hours later.
 */
class AdhanReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val prayer = intent.getStringExtra(AdhanScheduler.EXTRA_PRAYER) ?: "الصلاة"
        val isFajr = intent.getBooleanExtra(AdhanScheduler.EXTRA_IS_FAJR, false)
        val requestCode = intent.getIntExtra(AdhanScheduler.EXTRA_REQUEST_CODE, 0)

        val serviceIntent = Intent(context, AdhanService::class.java).apply {
            putExtra(AdhanScheduler.EXTRA_PRAYER, prayer)
            putExtra(AdhanScheduler.EXTRA_IS_FAJR, isFajr)
        }
        ContextCompat.startForegroundService(context, serviceIntent)

        AdhanScheduler.rescheduleAfterFiring(context, requestCode)
    }
}
