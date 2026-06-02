package com.morbansi.nitya

import android.appwidget.AppWidgetManager
import android.content.Context
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONArray
import android.content.SharedPreferences
import android.net.Uri
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * Android home-screen widget. Extends HomeWidgetProvider (from the home_widget
 * package), which hands us the SAME SharedPreferences the Flutter app writes to.
 * We read "habits_json", render up to 3 rows, and wire each checkmark to a
 * background intent that wakes the Dart interactivity callback.
 */
class NityaWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        val raw = widgetData.getString("habits_json", null)
        val habits = parse(raw)

        for (id in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.streak_widget)
            val rows = listOf(
                Triple(R.id.row0, R.id.label0, Triple(R.id.streak0, R.id.check0, R.id.emoji0)),
                Triple(R.id.row1, R.id.label1, Triple(R.id.streak1, R.id.check1, R.id.emoji1)),
                Triple(R.id.row2, R.id.label2, Triple(R.id.streak2, R.id.check2, R.id.emoji2)),
            )

            for (i in rows.indices) {
                val (rowId, labelId, rest) = rows[i]
                val (streakId, checkId, emojiId) = rest
                if (i < habits.size) {
                    val h = habits[i]
                    views.setViewVisibility(rowId, android.view.View.VISIBLE)
                    views.setTextViewText(emojiId, h.emoji)
                    views.setTextViewText(labelId, h.name)
                    views.setTextViewText(streakId, "🔥 ${h.streak}")
                    views.setImageViewResource(
                        checkId,
                        if (h.doneToday) R.drawable.ic_check_filled else R.drawable.ic_check_empty
                    )
                    val intent = HomeWidgetBackgroundIntent.getBroadcast(
                        context, Uri.parse("streak://toggle?id=${h.id}")
                    )
                    views.setOnClickPendingIntent(checkId, intent)
                } else {
                    views.setViewVisibility(rowId, android.view.View.GONE)
                }
            }
            appWidgetManager.updateAppWidget(id, views)
        }
    }

    private data class WHabit(
        val id: String, val name: String, val emoji: String,
        val doneToday: Boolean, val streak: Int
    )

    private fun parse(raw: String?): List<WHabit> {
        if (raw.isNullOrEmpty()) return emptyList()
        val today = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date())
        val out = mutableListOf<WHabit>()
        val arr = JSONArray(raw)
        for (i in 0 until arr.length()) {
            val o = arr.getJSONObject(i)
            val daysArr = o.optJSONArray("days") ?: JSONArray()
            val days = HashSet<String>()
            for (d in 0 until daysArr.length()) days.add(daysArr.getString(d))
            out.add(
                WHabit(
                    id = o.getString("id"),
                    name = o.getString("name"),
                    emoji = o.optString("emoji", "🔥"),
                    doneToday = days.contains(today),
                    streak = currentStreak(days)
                )
            )
        }
        return out
    }

    private fun currentStreak(days: Set<String>): Int {
        if (days.isEmpty()) return 0
        val f = SimpleDateFormat("yyyy-MM-dd", Locale.US)
        val cal = java.util.Calendar.getInstance()
        if (!days.contains(f.format(cal.time))) {
            cal.add(java.util.Calendar.DAY_OF_YEAR, -1)
            if (!days.contains(f.format(cal.time))) return 0
        }
        var count = 0
        while (days.contains(f.format(cal.time))) {
            count++
            cal.add(java.util.Calendar.DAY_OF_YEAR, -1)
        }
        return count
    }
}
