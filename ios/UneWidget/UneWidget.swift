import SwiftUI
import WidgetKit

// Widget « La une » : les derniers articles du Bien Heureux sur l'écran
// d'accueil et l'écran verrouillé. Il va chercher la une lui-même sur le site
// (environ toutes les 45 minutes, ou quand l'app vient de la recharger) et
// garde la dernière version pour l'affichage hors-ligne.

// MARK: - Couleurs et polices du journal

private enum Journal {
    static let papier = Color(red: 0xFA / 255, green: 0xF8 / 255, blue: 0xF3 / 255)
    static let rouge = Color(red: 0xA7 / 255, green: 0x00 / 255, blue: 0x03 / 255)
    static let encre = Color(red: 0x10 / 255, green: 0x18 / 255, blue: 0x28 / 255)
    static let filet = Color(red: 0xD1 / 255, green: 0xD5 / 255, blue: 0xDC / 255)

    static func titre(_ size: CGFloat) -> Font {
        .custom("CrimsonText-SemiBold", size: size, relativeTo: .headline)
    }

    static let signe = Font.system(size: 9.5, weight: .regular)
}

// MARK: - Données

struct UneArticle: Hashable, Identifiable {
    let id: Int
    let title: String
    let mark: String
    let rubrique: String
    let date: Date
    let imageURL: URL?

    /// « 🛰️ ACTUALITÉS • 25 OCTOBRE 2026 », comme dans l'app.
    var signe: String {
        let head = [mark, rubrique.uppercased(with: UneLoader.french)]
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        let day = UneLoader.signeDate.string(from: date).uppercased(with: UneLoader.french)
        return head.isEmpty ? day : "\(head)  •  \(day)"
    }

    /// Ouvre l'article dans l'app (lien reconnu par le paquet home_widget).
    var url: URL { URL(string: "lebienheureux://article/\(id)?homeWidget")! }
}

struct UneEntry: TimelineEntry {
    let date: Date
    let articles: [UneArticle]
    let image: UIImage?

    static let placeholder = UneEntry(
        date: Date(),
        articles: [
            UneArticle(
                id: 0, title: "La une du Bien Heureux arrive dès que le réseau est là.",
                mark: "📰", rubrique: "Le Bien Heureux", date: Date(), imageURL: nil),
        ],
        image: nil)
}

enum UneLoader {
    static let endpoint = URL(
        string: "https://lebienheureux.be/wp-json/wp/v2/posts?per_page=3"
            + "&_embed=wp:featuredmedia,wp:term&_fields=id,title,date_gmt,_links,_embedded")!

    static let french = Locale(identifier: "fr_BE")

    static let signeDate: DateFormatter = {
        let f = DateFormatter()
        f.locale = french
        f.dateFormat = "d MMMM yyyy"
        return f
    }()

    private static let gmtDate: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(identifier: "UTC")
        f.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return f
    }()

    private static var cacheDir: URL {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
    }
    private static var cacheJSON: URL { cacheDir.appendingPathComponent("une.json") }
    private static var cacheImage: URL { cacheDir.appendingPathComponent("une.jpg") }

    static func load() async -> UneEntry {
        var request = URLRequest(url: endpoint, timeoutInterval: 10)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        guard let (data, response) = try? await URLSession.shared.data(for: request),
            (response as? HTTPURLResponse)?.statusCode == 200
        else { return cached() }

        let articles = parse(data)
        guard !articles.isEmpty else { return cached() }
        try? data.write(to: cacheJSON, options: .atomic)

        var image: UIImage?
        if let url = articles.first?.imageURL,
            let result = try? await URLSession.shared.data(from: url),
            let full = UIImage(data: result.0)
        {
            image = full.preparingThumbnail(of: CGSize(width: 480, height: 300)) ?? full
            if let jpeg = image?.jpegData(compressionQuality: 0.85) {
                try? jpeg.write(to: cacheImage, options: .atomic)
            }
        } else {
            try? FileManager.default.removeItem(at: cacheImage)
        }
        return UneEntry(date: Date(), articles: articles, image: image)
    }

    /// Dernière une enregistrée, pour l'affichage sans réseau.
    static func cached() -> UneEntry {
        guard let data = try? Data(contentsOf: cacheJSON) else { return .placeholder }
        let articles = parse(data)
        guard !articles.isEmpty else { return .placeholder }
        return UneEntry(
            date: Date(), articles: articles,
            image: UIImage(contentsOfFile: cacheImage.path))
    }

    static func parse(_ data: Data) -> [UneArticle] {
        guard let posts = (try? JSONSerialization.jsonObject(with: data)) as? [[String: Any]]
        else { return [] }
        return posts.compactMap(article)
    }

    private static func article(_ post: [String: Any]) -> UneArticle? {
        guard let id = post["id"] as? Int,
            let rendered = (post["title"] as? [String: Any])?["rendered"] as? String
        else { return nil }
        let (mark, title) = HTMLText.splitMark(HTMLText.plain(rendered))
        let embedded = post["_embedded"] as? [String: Any]
        return UneArticle(
            id: id,
            title: title,
            mark: mark,
            rubrique: rubrique(embedded),
            date: gmtDate.date(from: post["date_gmt"] as? String ?? "") ?? Date(),
            imageURL: imageURL(embedded))
    }

    /// `wp:term` : liste de listes, les catégories d'abord.
    private static func rubrique(_ embedded: [String: Any]?) -> String {
        let groups = embedded?["wp:term"] as? [[[String: Any]]] ?? []
        for term in groups.joined() where term["taxonomy"] as? String == "category" {
            return HTMLText.plain(term["name"] as? String ?? "")
        }
        return ""
    }

    private static func imageURL(_ embedded: [String: Any]?) -> URL? {
        guard let media = (embedded?["wp:featuredmedia"] as? [[String: Any]])?.first else {
            return nil
        }
        let sizes = (media["media_details"] as? [String: Any])?["sizes"] as? [String: Any]
        for key in ["lbn_cote", "medium_large", "large"] {
            if let url = (sizes?[key] as? [String: Any])?["source_url"] as? String {
                return URL(string: url)
            }
        }
        return (media["source_url"] as? String).flatMap(URL.init(string:))
    }
}

/// Texte des titres WordPress : entités HTML et pictogramme de tête.
enum HTMLText {
    private static let named: [String: String] = [
        "amp": "&", "lt": "<", "gt": ">", "quot": "\"", "apos": "'", "nbsp": "\u{00A0}",
        "hellip": "…", "ndash": "–", "mdash": "—", "lsquo": "‘", "rsquo": "’",
        "ldquo": "“", "rdquo": "”", "laquo": "«", "raquo": "»", "euro": "€",
        "eacute": "é", "egrave": "è", "ecirc": "ê", "agrave": "à", "acirc": "â",
        "ccedil": "ç", "ocirc": "ô", "ucirc": "û", "icirc": "î", "iuml": "ï",
        "Eacute": "É", "oelig": "œ",
    ]
    private static let entity = try! NSRegularExpression(
        pattern: "&(#x[0-9a-fA-F]+|#[0-9]+|[a-zA-Z][a-zA-Z0-9]*);")
    private static let tag = try! NSRegularExpression(pattern: "<[^>]*>")
    private static let leadingMark = try! NSRegularExpression(
        pattern: "^\\s*([^\\p{L}\\p{N}\\p{P}\\s]+)\\s+")

    static func plain(_ html: String) -> String {
        let noTags = tag.stringByReplacingMatches(
            in: html, range: NSRange(html.startIndex..., in: html), withTemplate: "")
        var result = ""
        var last = noTags.startIndex
        for match in entity.matches(in: noTags, range: NSRange(noTags.startIndex..., in: noTags)) {
            guard let whole = Range(match.range, in: noTags),
                let body = Range(match.range(at: 1), in: noTags)
            else { continue }
            result += noTags[last..<whole.lowerBound]
            result += decode(String(noTags[body])) ?? String(noTags[whole])
            last = whole.upperBound
        }
        result += noTags[last...]
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func decode(_ body: String) -> String? {
        var code: UInt32?
        if body.hasPrefix("#x") || body.hasPrefix("#X") {
            code = UInt32(body.dropFirst(2), radix: 16)
        } else if body.hasPrefix("#") {
            code = UInt32(body.dropFirst())
        } else {
            return named[body]
        }
        guard let code, let scalar = Unicode.Scalar(code) else { return nil }
        return String(Character(scalar))
    }

    /// « 🛰️ Starlink… » → ("🛰️", "Starlink…")
    static func splitMark(_ title: String) -> (String, String) {
        let range = NSRange(title.startIndex..., in: title)
        guard let match = leadingMark.firstMatch(in: title, range: range),
            let mark = Range(match.range(at: 1), in: title),
            let whole = Range(match.range, in: title)
        else { return ("", title) }
        return (String(title[mark]), String(title[whole.upperBound...]))
    }
}

// MARK: - Fournisseur de chronologie

struct UneProvider: TimelineProvider {
    func placeholder(in context: Context) -> UneEntry { .placeholder }

    func getSnapshot(in context: Context, completion: @escaping (UneEntry) -> Void) {
        if context.isPreview {
            completion(UneLoader.cached())
            return
        }
        Task { completion(await UneLoader.load()) }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<UneEntry>) -> Void) {
        Task {
            let entry = await UneLoader.load()
            let next = Calendar.current.date(byAdding: .minute, value: 45, to: Date())!
            completion(Timeline(entries: [entry], policy: .after(next)))
        }
    }
}

// MARK: - Vues

struct UneWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: UneEntry

    private var une: UneArticle { entry.articles.first ?? UneEntry.placeholder.articles[0] }
    private var suite: [UneArticle] { Array(entry.articles.dropFirst()) }

    var body: some View {
        switch family {
        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 1) {
                Text("LE BIEN HEUREUX")
                    .font(.system(size: 10, weight: .semibold))
                    .widgetAccentable()
                Text(une.title).font(.headline).lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .widgetURL(une.url)
            .widgetBackground(.clear, padded: false)
        case .systemSmall:
            VStack(alignment: .leading, spacing: 5) {
                manchette(height: 11)
                Text(une.signe).font(Journal.signe).foregroundStyle(Journal.rouge).lineLimit(1)
                Text(une.title)
                    .font(Journal.titre(15))
                    .foregroundStyle(Journal.encre)
                    .lineLimit(5)
                Spacer(minLength: 0)
            }
            .widgetURL(une.url)
            .widgetBackground(Journal.papier)
        case .systemLarge:
            VStack(alignment: .leading, spacing: 7) {
                manchette(height: 15)
                if let image = entry.image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity, minHeight: 120, maxHeight: 150)
                        .clipped()
                }
                Text(une.signe).font(Journal.signe).foregroundStyle(Journal.rouge).lineLimit(1)
                Text(une.title).font(Journal.titre(19)).foregroundStyle(Journal.encre).lineLimit(3)
                ForEach(suite) { article in
                    Rectangle().fill(Journal.filet).frame(height: 1)
                    Link(destination: article.url) {
                        Text(article.title)
                            .font(Journal.titre(14))
                            .foregroundStyle(Journal.encre)
                            .lineLimit(2)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                Spacer(minLength: 0)
            }
            .widgetURL(une.url)
            .widgetBackground(Journal.papier)
        default:
            VStack(alignment: .leading, spacing: 6) {
                manchette(height: 13)
                HStack(alignment: .top, spacing: 10) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(une.signe).font(Journal.signe).foregroundStyle(Journal.rouge)
                            .lineLimit(1)
                        Text(une.title).font(Journal.titre(15)).foregroundStyle(Journal.encre)
                            .lineLimit(3)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    if let image = entry.image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 92, height: 64)
                            .clipped()
                    }
                }
                Spacer(minLength: 0)
            }
            .widgetURL(une.url)
            .widgetBackground(Journal.papier)
        }
    }

    /// Manchette du journal, soulignée d'un filet noir comme sur le site.
    private func manchette(height: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Image("Manchette")
                .resizable()
                .scaledToFit()
                .frame(height: height)
                .accessibilityLabel("Le Bien Heureux")
            Rectangle().fill(Color.black).frame(height: 1)
        }
    }
}

extension View {
    /// Fond du widget : API iOS 17, ou fond et marges classiques avant.
    @ViewBuilder
    func widgetBackground(_ color: Color, padded: Bool = true) -> some View {
        if #available(iOSApplicationExtension 17.0, *) {
            containerBackground(color, for: .widget)
        } else if padded {
            padding().background(color)
        } else {
            background(color)
        }
    }
}

// MARK: - Déclaration

struct UneWidget: Widget {
    let kind = "UneWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: UneProvider()) { entry in
            UneWidgetView(entry: entry)
        }
        .configurationDisplayName("La une")
        .description("La une du Bien Heureux, mise à jour toute seule.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .accessoryRectangular])
    }
}

@main
struct UneWidgetBundle: WidgetBundle {
    var body: some Widget {
        UneWidget()
    }
}
