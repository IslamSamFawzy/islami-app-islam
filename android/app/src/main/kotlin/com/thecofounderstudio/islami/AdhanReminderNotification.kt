package com.thecofounderstudio.islami

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.RingtoneManager
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat

/**
 * What the user gets when the full adhan cannot play: a high-priority
 * notification with the device's own notification sound, saying it is time to
 * pray. Tapping it opens the app.
 *
 * Unlike [AdhanService]'s silent channels, this one carries a sound — it is
 * all there is to hear in this case.
 */
object AdhanReminderNotification {
    private const val CHANNEL_ID = "adhan_reminder"
    private const val NOTIF_ID = 7002

    fun show(context: Context, prayer: String) {
        ensureChannel(context)

        val open = PendingIntent.getActivity(
            context,
            2,
            Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_CLEAR_TOP
            },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle("الأذان")
            .setContentText("حان وقت صلاة $prayer")
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            // Pre-O devices take the sound from the notification itself.
            .setSound(RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION))
            .setAutoCancel(true)
            .setContentIntent(open)
            .build()

        try {
            NotificationManagerCompat.from(context).notify(NOTIF_ID, notification)
        } catch (e: SecurityException) {
            // Notifications are not permitted; there is nothing further to try.
        }
    }

    private fun ensureChannel(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val nm = context.getSystemService(Context.NOTIFICATION_SERVICE)
            as NotificationManager
        val channel = NotificationChannel(
            CHANNEL_ID,
            "Prayer time reminder",
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = "Shown when the adhan itself cannot be played"
            setSound(
                RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION),
                AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_NOTIFICATION)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                    .build(),
            )
            enableVibration(true)
        }
        nm.createNotificationChannel(channel)
    }
}
