package com.route.islami

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import androidx.core.content.ContextCompat

/**
 * Fired by the alarm at a prayer time: plays the full adhan through the
 * foreground [AdhanService] and arms this prayer's next instant from the saved
 * schedule (alarms are one-shot), so the following day fires at that day's own
 * time rather than 24 hours later.
 */
class AdhanReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val prayer = intent.getStringExtra(AdhanScheduler.EXTRA_PRAYER) ?: "الصلاة"
        val isFajr = intent.getBooleanExtra(AdhanScheduler.EXTRA_IS_FAJR, false)
        val requestCode = intent.getIntExtra(AdhanScheduler.EXTRA_REQUEST_CODE, 0)

        // Arm the next day first: whatever happens below, the chain of alarms
        // must not break.
        AdhanScheduler.rescheduleAfterFiring(context, requestCode)

        val serviceIntent = Intent(context, AdhanService::class.java).apply {
            putExtra(AdhanScheduler.EXTRA_PRAYER, prayer)
            putExtra(AdhanScheduler.EXTRA_IS_FAJR, isFajr)
        }
        try {
            ContextCompat.startForegroundService(context, serviceIntent)
        } catch (e: Exception) {
            // Android 12+ only lets an alarm start a background service when
            // the alarm was exact (ForegroundServiceStartNotAllowedException).
            // Without that permission the adhan cannot play, so at least say
            // that it is time to pray.
            AdhanReminderNotification.show(context, prayer)
        }
    }
}
