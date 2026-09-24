package com.thecofounderstudio.islami

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * Alarms are cleared on reboot, and need re-arming when the clock or the time
 * zone moves or when the user grants the exact-alarm permission. Each prayer
 * is re-armed at its next saved instant.
 *
 * Only what is saved is re-armed, and switching the adhan off clears the saved
 * schedule — so a prayer the user turned off never comes back.
 */
class AdhanBootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_MY_PACKAGE_REPLACED,
            Intent.ACTION_TIME_CHANGED,
            Intent.ACTION_TIMEZONE_CHANGED,
            // API 31+: the user allowed (or revoked) exact alarms.
            "android.app.action.SCHEDULE_EXACT_ALARM_PERMISSION_STATE_CHANGED",
            "android.intent.action.QUICKBOOT_POWERON",
            "com.htc.intent.action.QUICKBOOT_POWERON",
            -> AdhanScheduler.rescheduleAll(context)
        }
    }
}
