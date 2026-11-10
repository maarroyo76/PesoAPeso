package cl.pesoapeso.app

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * RF39: widget de inicio con hasta cuatro accesos rápidos y un botón para
 * registrar. Tocar un acceso abre la app y lo registra (un toque); los datos
 * los escribe la app en `core/home_widget/quick_widget.dart`.
 */
class QuickAccessWidgetProvider : HomeWidgetProvider() {

  private val slots = intArrayOf(R.id.quick_0, R.id.quick_1, R.id.quick_2, R.id.quick_3)

  override fun onUpdate(
      context: Context,
      appWidgetManager: AppWidgetManager,
      appWidgetIds: IntArray,
      widgetData: SharedPreferences,
  ) {
    for (widgetId in appWidgetIds) {
      val views = RemoteViews(context.packageName, R.layout.quick_access_widget)

      views.setOnClickPendingIntent(
          R.id.widget_register,
          HomeWidgetLaunchIntent.getActivity(
              context, MainActivity::class.java, Uri.parse("pesoapeso://registrar")))

      var shown = 0
      for ((i, slot) in slots.withIndex()) {
        val id = widgetData.getString("quick_${i}_id", null)
        val label = widgetData.getString("quick_${i}_label", null)
        val amount = widgetData.getString("quick_${i}_amount", null)
        if (id == null || label == null || amount == null) {
          views.setViewVisibility(slot, View.INVISIBLE)
          continue
        }
        shown++
        views.setViewVisibility(slot, View.VISIBLE)
        views.setTextViewText(slot, "$label\n$amount")
        views.setContentDescription(slot, context.getString(R.string.widget_quick_description, label, amount))
        views.setOnClickPendingIntent(
            slot,
            HomeWidgetLaunchIntent.getActivity(
                context, MainActivity::class.java, Uri.parse("pesoapeso://quick?id=$id")))
      }

      // Las filas vacías no ocupan espacio; sin accesos, se explica cómo crearlos.
      views.setViewVisibility(R.id.row_0, if (shown > 0) View.VISIBLE else View.GONE)
      views.setViewVisibility(R.id.row_1, if (shown > 2) View.VISIBLE else View.GONE)
      views.setViewVisibility(R.id.widget_empty, if (shown == 0) View.VISIBLE else View.GONE)
      if (shown == 0) {
        views.setOnClickPendingIntent(
            R.id.widget_empty,
            HomeWidgetLaunchIntent.getActivity(
                context, MainActivity::class.java, Uri.parse("pesoapeso://registrar")))
      }

      appWidgetManager.updateAppWidget(widgetId, views)
    }
  }
}
