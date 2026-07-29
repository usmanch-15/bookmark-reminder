package com.example.bookmark_reminder

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

class ReminderWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        val widgetData = HomeWidgetPlugin.getData(context)
        for (widgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.reminder_widget)
            views.setTextViewText(R.id.title_0, widgetData.getString("reminder_title_0", ""))
            views.setTextViewText(R.id.title_1, widgetData.getString("reminder_title_1", ""))
            views.setTextViewText(R.id.title_2, widgetData.getString("reminder_title_2", ""))
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}