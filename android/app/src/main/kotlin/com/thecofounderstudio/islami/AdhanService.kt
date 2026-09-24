package com.thecofounderstudio.islami

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.media.AudioAttributes
import android.media.AudioManager
import android.media.MediaPlayer
import android.os.Build
import android.util.Log
import android.os.IBinder
import androidx.core.app.NotificationCompat

/**
 * Foreground service that plays the full adhan when a prayer time fires, even
 * with the app closed. Fajr uses adhan_fajr.mp3; every other prayer uses
 * adhan.mp3. Shows an ongoing notification with a Stop action and stops itself
 * when playback completes.
 *
 * The audio is played by MediaPlayer (full length + a working Stop action), so
 * the notification channels are intentionally SILENT — a channel sound would
 * play a second, uncontrollable adhan on top of the MediaPlayer one.
 */
class AdhanService : Service() {
    private var player: MediaPlayer? = null

    companion object {
        const val ACTION_STOP = "com.thecofounderstudio.islami.ACTION_STOP_ADHAN"
        private const val CHANNEL_REGULAR = "adhan_regular_v2"
        private const val CHANNEL_FAJR = "adhan_fajr_v2"
        private const val OLD_CHANNEL = "adhan_channel"
        private const val NOTIF_ID = 7001
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP) {
            stopEverything()
            return START_NOT_STICKY
        }

        val prayer = intent?.getStringExtra(AdhanScheduler.EXTRA_PRAYER) ?: "الصلاة"
        val isFajr = intent?.getBooleanExtra(AdhanScheduler.EXTRA_IS_FAJR, false) ?: false

        ensureChannels()
        val channelId = if (isFajr) CHANNEL_FAJR else CHANNEL_REGULAR
        startInForeground(channelId, prayer)
        playAdhan(isFajr)
        return START_NOT_STICKY
    }

    private fun startInForeground(channelId: String, prayer: String) {
        val stopIntent = Intent(this, AdhanService::class.java).apply {
            action = ACTION_STOP
        }
        val stopPending = PendingIntent.getService(
            this,
            1,
            stopIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        val notification = NotificationCompat.Builder(this, channelId)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle("الأذان")
            .setContentText("حان وقت صلاة $prayer")
            .setOngoing(true)
            .setSilent(true)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .addAction(0, "إيقاف", stopPending)
            .build()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            startForeground(
                NOTIF_ID,
                notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK,
            )
        } else {
            startForeground(NOTIF_ID, notification)
        }
    }

    private fun playAdhan(isFajr: Boolean) {
        player?.release()
        val resId = if (isFajr) R.raw.adhan_fajr else R.raw.adhan
        Log.i("AdhanService", "playing ${if (isFajr) "fajr" else "regular"} adhan")
        // Alarm attributes must be set before prepare(), so use the create()
        // overload that takes them (MediaPlayer.create() already prepares).
        val attrs = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_ALARM)
            .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
            .build()
        player = MediaPlayer.create(
            this,
            resId,
            attrs,
            AudioManager.AUDIO_SESSION_ID_GENERATE,
        )?.apply {
            setOnCompletionListener { stopEverything() }
            setOnErrorListener { _, _, _ ->
                stopEverything()
                true
            }
            start()
        }
        if (player == null) stopEverything()
    }

    private fun stopEverything() {
        player?.let {
            if (it.isPlaying) it.stop()
            it.release()
        }
        player = null
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
    }

    private fun ensureChannels() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        // The old channel baked in the default sound and can never be changed —
        // drop it and use fresh, silent v2 channels.
        nm.deleteNotificationChannel(OLD_CHANNEL)
        for ((id, name) in listOf(
            CHANNEL_REGULAR to "Adhan",
            CHANNEL_FAJR to "Adhan (Fajr)",
        )) {
            val channel = NotificationChannel(
                id,
                name,
                NotificationManager.IMPORTANCE_HIGH,
            ).apply {
                description = "Adhan playback notification"
                setSound(null, null)
                enableVibration(false)
            }
            nm.createNotificationChannel(channel)
        }
    }

    override fun onDestroy() {
        player?.release()
        player = null
        super.onDestroy()
    }
}
