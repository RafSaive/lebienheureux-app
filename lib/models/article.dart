import '../util/html_text.dart';

class Article {
  Article({
    required this.id,
    required this.title,
    required this.excerpt,
    required this.contentHtml,
    required this.link,
    required this.date,
    this.mark = '',
    this.imageUrl,
    this.thumbUrl,
    this.imageCredit = '',
    this.imageAlt = '',
    this.categories = const [],
  });

  final int id;

  /// Titre sans le pictogramme de tête.
  final String title;

  /// Pictogramme de tête du titre (« 🛰️ »), affiché devant la rubrique.
  final String mark;
  final String excerpt;
  final String contentHtml;
  final String link;
  final DateTime date;

  /// Grande image (format « une » du site).
  final String? imageUrl;

  /// Image réduite pour les listes.
  final String? thumbUrl;
  final String imageCredit;
  final String imageAlt;
  final List<String> categories;

  String? get rubrique => categories.isEmpty ? null : categories.first;

  /// Durée de lecture estimée, comme « ≈ 3 min de lecture » sur le site.
  late final int readingMinutes = () {
    final words = htmlToPlainText(contentHtml).split(' ').length;
    return (words / 220).ceil().clamp(1, 999);
  }();

  /// Construit un article depuis un objet `post` de l'API REST WordPress
  /// (appelée avec `_embed`).
  factory Article.fromWp(Map<String, dynamic> json) {
    final embedded = json['_embedded'] as Map<String, dynamic>? ?? const {};
    final media = _firstMap(embedded['wp:featuredmedia']);
    final (mark, title) = splitLeadingMark(
      htmlToPlainText(_rendered(json['title'])),
    );
    return Article(
      id: json['id'] as int,
      title: title,
      mark: mark,
      excerpt: htmlToPlainText(_rendered(json['excerpt'])),
      contentHtml: _rendered(json['content']),
      link: json['link'] as String? ?? '',
      date:
          DateTime.tryParse('${json['date_gmt']}Z') ??
          DateTime.tryParse(json['date'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      imageUrl: _sizeUrl(media, const ['lbn_une', 'large', 'full']),
      thumbUrl: _sizeUrl(media, const ['lbn_cote', 'medium_large', 'large']),
      imageCredit: htmlToPlainText(_rendered(media?['caption'])),
      imageAlt: media?['alt_text'] as String? ?? '',
      categories: _categoryNames(embedded['wp:term']),
    );
  }

  factory Article.fromJson(Map<String, dynamic> json) => Article(
    id: json['id'] as int,
    title: json['title'] as String,
    mark: json['mark'] as String? ?? '',
    excerpt: json['excerpt'] as String? ?? '',
    contentHtml: json['contentHtml'] as String? ?? '',
    link: json['link'] as String? ?? '',
    date: DateTime.parse(json['date'] as String),
    imageUrl: json['imageUrl'] as String?,
    thumbUrl: json['thumbUrl'] as String?,
    imageCredit: json['imageCredit'] as String? ?? '',
    imageAlt: json['imageAlt'] as String? ?? '',
    categories: (json['categories'] as List? ?? const []).cast<String>(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'mark': mark,
    'excerpt': excerpt,
    'contentHtml': contentHtml,
    'link': link,
    'date': date.toUtc().toIso8601String(),
    'imageUrl': imageUrl,
    'thumbUrl': thumbUrl,
    'imageCredit': imageCredit,
    'imageAlt': imageAlt,
    'categories': categories,
  };

  static String _rendered(Object? field) =>
      field is Map ? (field['rendered'] as String? ?? '') : '';

  static Map<String, dynamic>? _firstMap(Object? list) =>
      list is List && list.isNotEmpty && list.first is Map<String, dynamic>
      ? list.first as Map<String, dynamic>
      : null;

  static String? _sizeUrl(Map<String, dynamic>? media, List<String> order) {
    if (media == null) return null;
    final sizes = (media['media_details'] as Map?)?['sizes'] as Map?;
    for (final key in order) {
      final url = (sizes?[key] as Map?)?['source_url'] as String?;
      if (url != null) return url;
    }
    return media['source_url'] as String?;
  }

  /// `wp:term` est une liste de listes : catégories d'abord, puis étiquettes.
  static List<String> _categoryNames(Object? terms) {
    if (terms is! List) return const [];
    final names = <String>[];
    for (final group in terms) {
      if (group is! List) continue;
      for (final term in group) {
        if (term is Map && term['taxonomy'] == 'category') {
          names.add(decodeEntities(term['name'] as String? ?? ''));
        }
      }
    }
    return names;
  }
}
