package com.route.islami

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import org.json.JSONArray
import org.json.JSONObject
import java.util.Calendar

/**
 * Sets and cancels the exact daily alarms that fire the adhan, and persists the
 * schedule in the app's own prefs (separate from Flutter's SharedPreferences)
 * so [AdhanBootReceiver] can restore it after a reboot.
 */
object AdhanScheduler {
    const val EXTRA_PRAYER = "prayer"
    const val EXTRA_IS_FAJR = "is_fajr"
    const val EXTRA_REQUEST_CODE = "request_code"
    const val EXTRA_HOUR = "hour"
    const val EXTRA_MINUTE = "minute"

    private const val PREFS = "adhan_prefs"
    private const val KEY_SCHEDULE = "schedule"

    data class Adhan(
        val name: String,
        val hour: Int,
        val minute: Int,
        val isFajr: Boolean,
    )

    /** Persists [adhans] and arms each at its next occurrence. */
    fun schedule(context: Context, adhans: List<Adhan>) {
        // Cancel whatever was armed before so a changed prayer set leaves no
        // orphaned alarms.
        cancelArmed(context)
        persist(context, adhans)
        val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        adhans.forEachIndexed { i, a ->
            am.setExactAndAllowWhileIdle(
                AlarmManager.RTC_WAKEUP,
                nextTrigger(a.hour, a.minute),
                pendingIntent(context, i, a),
            )
        }
    }

    /** Re-arms every saved prayer for its next occurrence (used after boot). */
    fun rescheduleAll(context: Context) {
        schedule(context, read(context))
    }

    /** Re-arms a single prayer for tomorrow (called right after it fires). */
    fun rescheduleNextDay(context: Context, requestCode: Int, a: Adhan) {
        val cal = atClock(a.hour, a.minute).apply { add(Calendar.DAY_OF_YEAR, 1) }
        val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        am.setExactAndAllowWhileIdle(
            AlarmManager.RTC_WAKEUP,
            cal.timeInMillis,
            pendingIntent(context, requestCode, a),
        )
    }

    /** Cancels all pending alarms and forgets the saved schedule (mute). */
    fun cancel(context: Context) {
        cancelArmed(context)
        prefs(context).edit().remove(KEY_SCHEDULE).apply()
    }

    private fun cancelArmed(context: Context) {
        val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        read(context).forEachIndexed { i, a ->
            am.cancel(pendingIntent(context, i, a))
        }
    }

    fun read(context: Context): List<Adhan> {
        val raw = prefs(context).getString(KEY_SCHEDULE, null) ?: return emptyList()
        return try {
            val arr = JSONArray(raw)
            (0 until arr.length()).map { i ->
                val o = arr.getJSONObject(i)
                Adhan(
                    o.getString("name"),
                    o.getInt("hour"),
                    o.getInt("minute"),
                    o.getBoolean("fajr"),
                )
            }
        } catch (e: Exception) {
            emptyList()
        }
    }

    private fun persist(context: Context, adhans: List<Adhan>) {
        val arr = JSONArray()
        adhans.forEach { a ->
            arr.put(
                JSONObject()
                    .put("name", a.name)
                    .put("hour", a.hour)
                    .put("minute", a.minute)
                    .put("fajr", a.isFajr),
            )
        }
        prefs(context).edit().putString(KEY_SCHEDULE, arr.toString()).apply()
    }

    private fun prefs(context: Context) =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    private fun atClock(hour: Int, minute: Int): Calendar =
        Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, hour)
            set(Calendar.MINUTE, minute)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }

    private fun nextTrigger(hour: Int, minute: Int): Long {
        val cal = atClock(hour, minute)
        if (cal.timeInMillis <= System.currentTimeMillis()) {
            cal.add(Calendar.DAY_OF_YEAR, 1)
        }
        return cal.timeInMillis
    }

    private fun pendingIntent(context: Context, requestCode: Int, a: Adhan): PendingIntent {
        val intent = Intent(context, AdhanReceiver::class.java).apply {
            putExtra(EXTRA_PRAYER, a.name)
            putExtra(EXTRA_IS_FAJR, a.isFajr)
            putExtra(EXTRA_REQUEST_CODE, requestCode)
            putExtra(EXTRA_HOUR, a.hour)
            putExtra(EXTRA_MINUTE, a.minute)
        }
        return PendingIntent.getBroadcast(
            context,
            requestCode,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }
}
