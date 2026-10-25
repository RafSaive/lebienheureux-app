package be.lebienheureux.lebienheureux

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.graphics.BitmapFactory
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import java.util.concurrent.Executors

/** Widget « La une » : les derniers articles du Bien Heureux sur l'écran
 *  d'accueil. Il se met à jour seul (toutes les heures, ou quand l'app vient
 *  de charger la une) et affiche la dernière version connue sans réseau. */
class UneWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        render(context, manager, ids, UneRepository.load(context))
        val pending = goAsync()
        executor.execute {
            try {
                UneRepository.fetch(context)?.let { render(context, manager, ids, it) }
            } catch (e: Exception) {
                // Le widget garde la dernière une affichée.
            } finally {
                pending.finish()
            }
        }
    }

    private fun render(context: Context, manager: AppWidgetManager, ids: IntArray, une: Une?) {
        val views = buildViews(context, une)
        ids.forEach { manager.updateAppWidget(it, views) }
    }

    internal fun buildViews(context: Context, une: Une?): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.une_widget)
        val articles = une?.articles.orEmpty()
        val first = articles.firstOrNull()

        views.setOnClickPendingIntent(R.id.widget_root, open(context, first?.id))
        if (first == null) return views

        views.setTextViewText(R.id.une_signe, first.signe)
        views.setTextViewText(R.id.une_title, first.title)

        val bitmap = une?.image?.let { BitmapFactory.decodeFile(it.path) }
        if (bitmap != null) {
            views.setImageViewBitmap(R.id.une_image, bitmap)
            views.setViewVisibility(R.id.une_image, View.VISIBLE)
        } else {
            views.setViewVisibility(R.id.une_image, View.GONE)
        }

        listOf(
            Triple(R.id.titre_2, R.id.filet_2, articles.getOrNull(1)),
            Triple(R.id.titre_3, R.id.filet_3, articles.getOrNull(2)),
        ).forEach { (text, filet, article) ->
            val visibility = if (article != null) View.VISIBLE else View.GONE
            views.setViewVisibility(text, visibility)
            views.setViewVisibility(filet, visibility)
            if (article != null) {
                views.setTextViewText(text, article.title)
                views.setOnClickPendingIntent(text, open(context, article.id))
            }
        }
        return views
    }

    /** Ouvre l'app sur l'article (ou sur la une si [id] est null). */
    private fun open(context: Context, id: Int?): PendingIntent {
        val uri = id?.let { Uri.parse("lebienheureux://article/$it?homeWidget") }
        return HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java, uri)
    }

    companion object {
        private val executor = Executors.newSingleThreadExecutor()
    }
}
