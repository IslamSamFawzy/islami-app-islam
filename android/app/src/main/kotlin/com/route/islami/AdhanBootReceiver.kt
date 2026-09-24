package com.route.islami

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * Alarms are cleared on reboot and point at the wrong instant after the clock
 * or the time zone moves, so re-arm every saved adhan from the persisted
 * schedule (which holds each prayer as an hour and minute of the local day).
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
            "android.intent.action.QUICKBOOT_POWERON",
            "com.htc.intent.action.QUICKBOOT_POWERON",
            -> AdhanScheduler.rescheduleAll(context)
        }
    }
}
