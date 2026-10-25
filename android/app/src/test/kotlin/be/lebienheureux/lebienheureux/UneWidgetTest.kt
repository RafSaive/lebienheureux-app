package be.lebienheureux.lebienheureux

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.view.View
import android.widget.FrameLayout
import android.widget.TextView
import androidx.test.core.app.ApplicationProvider
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import org.robolectric.annotation.GraphicsMode
import java.io.File
import java.util.TimeZone

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [35], qualifiers = "xxhdpi")
@GraphicsMode(GraphicsMode.Mode.NATIVE)
class UneWidgetTest {
    private val context: Context = ApplicationProvider.getApplicationContext()

    /** Même forme que la réponse de l'API du site (champs utiles seulement). */
    private val json = """
        [
          {"id": 2028, "date_gmt": "2026-10-25T21:43:01",
           "title": {"rendered": "🛰️ Starlink revenu sur le front ukrainien, Musk menace de couper le service"},
           "_embedded": {"wp:term": [[{"taxonomy": "category", "name": "Actualit&eacute;s"}], []]}},
          {"id": 1995, "date_gmt": "2026-10-25T20:00:00",
           "title": {"rendered": "💍 Les Knicks promettent une bague : c&rsquo;était un test d&rsquo;hameçonnage"},
           "_embedded": {"wp:term": [[{"taxonomy": "category", "name": "Actualit&eacute;s"}]]}},
          {"id": 2013, "date_gmt": "2026-10-25T17:56:05",
           "title": {"rendered": "Matignon et le DNS"}, "_embedded": {}}
        ]
    """.trimIndent()

    @Before
    fun bruxelles() {
        TimeZone.setDefault(TimeZone.getTimeZone("Europe/Brussels"))
    }

    @Test
    fun litLesArticlesDuSite() {
        val articles = UneRepository.parse(json)!!

        assertEquals(3, articles.size)
        with(articles[0]) {
            assertEquals(2028, id)
            assertEquals("🛰️", mark)
            assertEquals("Starlink revenu sur le front ukrainien, Musk menace de couper le service", title)
            assertEquals("Actualités", rubrique)
            assertEquals("🛰️ ACTUALITÉS  •  25 OCTOBRE 2026", signe)
        }
        assertEquals("Les Knicks promettent une bague : c’était un test d’hameçonnage", articles[1].title)
        assertEquals("", articles[2].mark)
        assertEquals("25 OCTOBRE 2026", articles[2].signe)
    }

    @Test
    fun ignoreUneReponseInvalide() {
        assertNull(UneRepository.parse("<html>Maintenance</html>"))
    }

    @Test
    fun sansDonneesAnnonceLaUne() {
        val view = inflate(null)
        assertEquals(
            context.getString(R.string.une_widget_attente),
            view.findViewById<TextView>(R.id.une_title).text.toString(),
        )
        assertEquals(View.GONE, view.findViewById<View>(R.id.titre_2).visibility)
    }

    @Test
    fun afficheLaUneLaPhotoEtLesTitres() {
        val photo = File("../../assets/brand/capybara.png")
        val view = inflate(Une(UneRepository.parse(json)!!, photo))

        assertEquals(
            "Starlink revenu sur le front ukrainien, Musk menace de couper le service",
            view.findViewById<TextView>(R.id.une_title).text.toString(),
        )
        assertEquals("🛰️ ACTUALITÉS  •  25 OCTOBRE 2026", view.findViewById<TextView>(R.id.une_signe).text.toString())
        assertEquals(View.VISIBLE, view.findViewById<View>(R.id.une_image).visibility)
        assertEquals(View.VISIBLE, view.findViewById<View>(R.id.titre_3).visibility)

        // Rendu du widget (4 × 2 cases) pour vérification visuelle.
        val density = context.resources.displayMetrics.density
        val width = (320 * density).toInt()
        val height = (190 * density).toInt()
        view.measure(
            View.MeasureSpec.makeMeasureSpec(width, View.MeasureSpec.EXACTLY),
            View.MeasureSpec.makeMeasureSpec(height, View.MeasureSpec.EXACTLY),
        )
        view.layout(0, 0, width, height)
        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        Canvas(bitmap).apply {
            drawColor(0xFF5B6B7A.toInt()) // fond d'écran fictif
            view.draw(this)
        }
        val out = File("build/widget-preview").apply { mkdirs() }
        File(out, "une_widget.png").outputStream().use {
            bitmap.compress(Bitmap.CompressFormat.PNG, 100, it)
        }
    }

    private fun inflate(une: Une?): View =
        UneWidgetProvider().buildViews(context, une).apply(context, FrameLayout(context))
}
