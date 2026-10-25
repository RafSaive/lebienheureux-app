package be.lebienheureux.lebienheureux

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.text.Html
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.net.HttpURLConnection
import java.net.URL
import java.text.SimpleDateFormat
import java.util.Locale
import java.util.TimeZone

data class UneArticle(
    val id: Int,
    val title: String,
    val mark: String,
    val rubrique: String,
    val date: String,
) {
    /** « 🛰️ ACTUALITÉS • 25 OCTOBRE 2026 », comme dans l'app. */
    val signe: String
        get() = listOf(mark, rubrique.uppercase(Locale.FRENCH))
            .filter { it.isNotBlank() }
            .joinToString(" ")
            .let { if (it.isEmpty()) date else "$it  •  $date" }
}

data class Une(val articles: List<UneArticle>, val image: File?)

/** Récupère les trois derniers articles sur le site et garde la dernière
 *  réponse (et la photo de une) pour l'affichage hors-ligne. */
object UneRepository {
    private const val API = "https://lebienheureux.be/wp-json/wp/v2/posts" +
        "?per_page=3&_embed=wp:featuredmedia,wp:term" +
        "&_fields=id,title,date_gmt,_links,_embedded"
    private const val PREFS = "une_widget"
    private const val KEY = "posts"
    private const val TIMEOUT_MS = 5000
    private const val IMAGE_WIDTH = 480

    private val leadingMark = Regex("""^\s*([^\p{L}\p{N}\p{P}\s]+)\s+""")

    fun load(context: Context): Une? {
        val json = prefs(context).getString(KEY, null) ?: return null
        val articles = parse(json) ?: return null
        return Une(articles, imageFile(context).takeIf { it.exists() })
    }

    /** À appeler hors du thread principal. Renvoie null sans réseau. */
    fun fetch(context: Context): Une? {
        val body = get(API)?.toString(Charsets.UTF_8) ?: return null
        val articles = parse(body) ?: return null
        val file = imageFile(context)
        val imageUrl = firstImageUrl(body)
        if (imageUrl == null || !downloadImage(imageUrl, file)) file.delete()
        prefs(context).edit().putString(KEY, body).apply()
        return Une(articles, file.takeIf { it.exists() })
    }

    internal fun parse(json: String): List<UneArticle>? = try {
        val posts = JSONArray(json)
        (0 until posts.length()).map { article(posts.getJSONObject(it)) }
    } catch (e: Exception) {
        null
    }

    private fun article(post: JSONObject): UneArticle {
        val raw = decode(post.getJSONObject("title").optString("rendered"))
        val match = leadingMark.find(raw)
        return UneArticle(
            id = post.getInt("id"),
            title = if (match != null) raw.substring(match.range.last + 1).trim() else raw,
            mark = match?.groupValues?.get(1) ?: "",
            rubrique = rubrique(post),
            date = formatDate(post.optString("date_gmt")),
        )
    }

    /** `wp:term` : liste de listes, les catégories d'abord. */
    private fun rubrique(post: JSONObject): String {
        val terms = post.optJSONObject("_embedded")?.optJSONArray("wp:term") ?: return ""
        for (g in 0 until terms.length()) {
            val group = terms.optJSONArray(g) ?: continue
            for (t in 0 until group.length()) {
                val term = group.optJSONObject(t) ?: continue
                if (term.optString("taxonomy") == "category") return decode(term.optString("name"))
            }
        }
        return ""
    }

    private fun firstImageUrl(json: String): String? = try {
        val media = JSONArray(json).getJSONObject(0)
            .optJSONObject("_embedded")?.optJSONArray("wp:featuredmedia")?.optJSONObject(0)
        val sizes = media?.optJSONObject("media_details")?.optJSONObject("sizes")
        listOf("lbn_cote", "medium_large", "large")
            .firstNotNullOfOrNull { sizes?.optJSONObject(it)?.optString("source_url")?.ifEmpty { null } }
            ?: media?.optString("source_url")?.ifEmpty { null }
    } catch (e: Exception) {
        null
    }

    private fun formatDate(gmt: String): String = try {
        val parser = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss", Locale.ROOT)
        parser.timeZone = TimeZone.getTimeZone("UTC")
        val date = parser.parse(gmt) ?: return ""
        SimpleDateFormat("d MMMM yyyy", Locale.FRENCH).format(date).uppercase(Locale.FRENCH)
    } catch (e: Exception) {
        ""
    }

    private fun decode(html: String): String =
        Html.fromHtml(html, Html.FROM_HTML_MODE_LEGACY).toString().trim()

    private fun get(url: String): ByteArray? {
        val connection = URL(url).openConnection() as HttpURLConnection
        return try {
            connection.connectTimeout = TIMEOUT_MS
            connection.readTimeout = TIMEOUT_MS
            connection.setRequestProperty("Accept", "application/json, image/*")
            if (connection.responseCode != HttpURLConnection.HTTP_OK) null
            else connection.inputStream.use { it.readBytes() }
        } catch (e: Exception) {
            null
        } finally {
            connection.disconnect()
        }
    }

    /** Télécharge la photo de une, réduite à la taille du widget. */
    private fun downloadImage(url: String, file: File): Boolean {
        val bytes = get(url) ?: return false
        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        BitmapFactory.decodeByteArray(bytes, 0, bytes.size, bounds)
        var sample = 1
        while (bounds.outWidth / (sample * 2) >= IMAGE_WIDTH) sample *= 2
        val bitmap = BitmapFactory.decodeByteArray(
            bytes, 0, bytes.size, BitmapFactory.Options().apply { inSampleSize = sample },
        ) ?: return false
        val tmp = File(file.parentFile, "${file.name}.tmp")
        tmp.outputStream().use { bitmap.compress(Bitmap.CompressFormat.JPEG, 85, it) }
        bitmap.recycle()
        return tmp.renameTo(file)
    }

    private fun imageFile(context: Context) = File(context.filesDir, "une_widget.jpg")

    private fun prefs(context: Context) =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
}
