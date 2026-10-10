package com.sakk.app

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * Home screen widget showing the next warranty to end. The Flutter side
 * (HomeWidgetSync) saves already-translated texts, so this only draws them.
 * Tapping it opens the app.
 */
class WarrantyWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        for (id in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.warranty_widget).apply {
                setTextViewText(R.id.widget_header, widgetData.getString("header", null) ?: "Sakk")
                setTextViewText(
                    R.id.widget_title,
                    widgetData.getString("title", null) ?: "Open Sakk to see your warranties",
                )
                val subtitle = widgetData.getString("subtitle", null).orEmpty()
                setTextViewText(R.id.widget_subtitle, subtitle)
                setViewVisibility(R.id.widget_subtitle, if (subtitle.isEmpty()) View.GONE else View.VISIBLE)
                setOnClickPendingIntent(
                    R.id.widget_root,
                    HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java),
                )
            }
            appWidgetManager.updateAppWidget(id, views)
        }
    }
}
