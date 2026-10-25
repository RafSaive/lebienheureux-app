import '../util/html_text.dart';

class Article {
  const Article({
    required this.id,
    required this.title,
    required this.excerpt,
    required this.contentHtml,
    required this.link,
    required this.date,
    this.imageUrl,
    this.author,
    this.categories = const [],
  });

  final int id;
  final String title;
  final String excerpt;
  final String contentHtml;
  final String link;
  final DateTime date;
  final String? imageUrl;
  final String? author;
  final List<String> categories;

  /// Construit un article depuis un objet `post` de l'API REST WordPress
  /// (appelée avec `_embed`).
  factory Article.fromWp(Map<String, dynamic> json) {
    final embedded = json['_embedded'] as Map<String, dynamic>? ?? const {};
    return Article(
      id: json['id'] as int,
      title: htmlToPlainText(_rendered(json['title'])),
      excerpt: htmlToPlainText(_rendered(json['excerpt'])),
      contentHtml: _rendered(json['content']),
      link: json['link'] as String? ?? '',
      date: DateTime.tryParse(json['date_gmt'] as String? ?? '') ??
          DateTime.tryParse(json['date'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      imageUrl: _imageUrl(embedded['wp:featuredmedia']),
      author: _authorName(embedded['author']),
      categories: _categoryNames(embedded['wp:term']),
    );
  }

  factory Article.fromJson(Map<String, dynamic> json) => Article(
        id: json['id'] as int,
        title: json['title'] as String,
        excerpt: json['excerpt'] as String,
        contentHtml: json['contentHtml'] as String,
        link: json['link'] as String,
        date: DateTime.parse(json['date'] as String),
        imageUrl: json['imageUrl'] as String?,
        author: json['author'] as String?,
        categories: (json['categories'] as List).cast<String>(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'excerpt': excerpt,
        'contentHtml': contentHtml,
        'link': link,
        'date': date.toIso8601String(),
        'imageUrl': imageUrl,
        'author': author,
        'categories': categories,
      };

  static String _rendered(Object? field) =>
      field is Map ? (field['rendered'] as String? ?? '') : '';

  static String? _imageUrl(Object? media) {
    if (media is! List || media.isEmpty || media.first is! Map) return null;
    final m = media.first as Map<String, dynamic>;
    final sizes = (m['media_details'] as Map?)?['sizes'] as Map?;
    for (final key in const ['large', 'medium_large', 'full']) {
      final url = (sizes?[key] as Map?)?['source_url'] as String?;
      if (url != null) return url;
    }
    return m['source_url'] as String?;
  }

  static String? _authorName(Object? authors) {
    if (authors is! List || authors.isEmpty || authors.first is! Map) {
      return null;
    }
    final name = (authors.first as Map)['name'] as String?;
    return name == null ? null : decodeEntities(name);
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
