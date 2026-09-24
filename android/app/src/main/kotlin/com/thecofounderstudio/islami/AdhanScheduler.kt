package com.thecofounderstudio.islami

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import org.json.JSONArray
import org.json.JSONObject
import java.util.Calendar
import java.util.concurrent.TimeUnit

/**
 * Sets and cancels the exact daily alarms that fire the adhan, and persists the
 * schedule in the app's own prefs (separate from Flutter's SharedPreferences)
 * so it survives a reboot.
 *
 * Each prayer carries the real instant of every day the app has downloaded
 * (prayer times move by up to a minute a day). An alarm that fires arms the
 * same prayer's next instant from that list; only once the list runs out does
 * it fall back to "same time tomorrow".
 */
object AdhanScheduler {
    const val EXTRA_PRAYER = "prayer"
    const val EXTRA_IS_FAJR = "is_fajr"
    const val EXTRA_REQUEST_CODE = "request_code"

    private const val PREFS = "adhan_prefs"
    private const val KEY_SCHEDULE = "schedule"
    private val ONE_DAY_MS = TimeUnit.DAYS.toMillis(1)

    /**
     * One prayer and every instant it is due, in ascending order.
     *
     * [name] identifies it in the saved schedule; [displayName] is what the
     * notifications show, which is Arabic like the rest of their text.
     */
    data class Adhan(
        val name: String,
        val displayName: String,
        val isFajr: Boolean,
        val times: List<Long>,
    ) {
        /** The first instant after [from], or null when the list is used up. */
        fun nextAfter(from: Long): Long? = times.firstOrNull { it > from }

        /**
         * What to arm when the list is used up: the last known instant moved
         * forward a day at a time until it is in the future. Keeps the adhan
         * roughly right if the app is never opened again.
         */
        fun fallbackAfter(from: Long): Long? {
            var time = times.lastOrNull() ?: return null
            while (time <= from) time += ONE_DAY_MS
            return time
        }
    }

    /** Persists [adhans] and arms each at its next instant. */
    fun schedule(context: Context, adhans: List<Adhan>) {
        // Cancel whatever was armed before so a changed prayer set leaves no
        // orphaned alarms.
        cancelArmed(context)
        persist(context, adhans)
        adhans.forEachIndexed { i, adhan -> arm(context, i, adhan) }
    }

    /**
     * Re-arms every saved prayer at its next instant. Used after a reboot, a
     * clock or time-zone change, and when the exact-alarm permission changes.
     */
    fun rescheduleAll(context: Context) {
        read(context).forEachIndexed { i, adhan -> arm(context, i, adhan) }
    }

    /** Arms the prayer that just fired at its following instant. */
    fun rescheduleAfterFiring(context: Context, requestCode: Int) {
        val adhans = read(context)
        adhans.getOrNull(requestCode)?.let { arm(context, requestCode, it) }
    }

    /** Cancels all pending alarms and forgets the saved schedule. */
    fun cancel(context: Context) {
        cancelArmed(context)
        prefs(context).edit().remove(KEY_SCHEDULE).apply()
    }

    /**
     * Whether the device lets this app set exact alarms. Android 12 introduced
     * the permission; Android 14 stopped granting it to new installs.
     */
    fun canScheduleExact(context: Context): Boolean {
        val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        return if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.S) {
            am.canScheduleExactAlarms()
        } else {
            true
        }
    }

    private fun arm(context: Context, requestCode: Int, adhan: Adhan) {
        val now = System.currentTimeMillis()
        val at = adhan.nextAfter(now) ?: adhan.fallbackAfter(now) ?: return
        val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = pendingIntent(context, requestCode, adhan)

        // Without the exact-alarm permission an inexact alarm still plays the
        // adhan, just not to the minute — far better than crashing.
        try {
            if (canScheduleExact(context)) {
                am.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at, intent)
            } else {
                am.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at, intent)
            }
        } catch (e: SecurityException) {
            am.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at, intent)
        }
    }

    private fun cancelArmed(context: Context) {
        val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        read(context).forEachIndexed { i, adhan ->
            am.cancel(pendingIntent(context, i, adhan))
        }
    }

    fun read(context: Context): List<Adhan> {
        val raw = prefs(context).getString(KEY_SCHEDULE, null) ?: return emptyList()
        return try {
            val arr = JSONArray(raw)
            (0 until arr.length()).map { i -> parse(arr.getJSONObject(i)) }
        } catch (e: Exception) {
            emptyList()
        }
    }

    /**
     * Reads one saved prayer. Entries written before the app stored instants
     * carry an hour and a minute instead, so those are turned into today's (or
     * tomorrow's) instant — an update must not silence the adhan.
     */
    private fun parse(o: JSONObject): Adhan {
        val name = o.getString("name")
        // Older saved schedules have no display name; the plain one will do
        // until the app next writes the schedule.
        val displayName = o.optString("displayName", name).ifEmpty { name }
        val isFajr = o.optBoolean("fajr", false)

        val stored = o.optJSONArray("times")
        if (stored != null) {
            return Adhan(
                name,
                displayName,
                isFajr,
                (0 until stored.length()).map { stored.getLong(it) },
            )
        }
        return Adhan(
            name,
            displayName,
            isFajr,
            listOf(nextTrigger(o.getInt("hour"), o.getInt("minute"))),
        )
    }

    private fun persist(context: Context, adhans: List<Adhan>) {
        val arr = JSONArray()
        adhans.forEach { adhan ->
            val times = JSONArray()
            adhan.times.forEach { times.put(it) }
            arr.put(
                JSONObject()
                    .put("name", adhan.name)
                    .put("displayName", adhan.displayName)
                    .put("fajr", adhan.isFajr)
                    .put("times", times),
            )
        }
        prefs(context).edit().putString(KEY_SCHEDULE, arr.toString()).apply()
    }

    private fun prefs(context: Context) =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    /** Only used to migrate a schedule saved as an hour and a minute. */
    private fun nextTrigger(hour: Int, minute: Int): Long {
        val cal = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, hour)
            set(Calendar.MINUTE, minute)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }
        if (cal.timeInMillis <= System.currentTimeMillis()) {
            cal.add(Calendar.DAY_OF_YEAR, 1)
        }
        return cal.timeInMillis
    }

    private fun pendingIntent(context: Context, requestCode: Int, adhan: Adhan): PendingIntent {
        val intent = Intent(context, AdhanReceiver::class.java).apply {
            // The receiver and the service only ever show this, so it carries
            // the name as the user should read it.
            putExtra(EXTRA_PRAYER, adhan.displayName)
            putExtra(EXTRA_IS_FAJR, adhan.isFajr)
            putExtra(EXTRA_REQUEST_CODE, requestCode)
        }
        return PendingIntent.getBroadcast(
            context,
            requestCode,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }
}
