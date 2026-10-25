import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config.dart';
import '../models/article.dart';
import '../models/category.dart';

class ApiException implements Exception {
  ApiException(this.message);
  final String message;

  @override
  String toString() => message;
}

class ArticlePage {
  const ArticlePage(this.items, this.totalPages);
  final List<Article> items;
  final int totalPages;
}

/// Client minimal de l'API REST WordPress (`/wp-json/wp/v2`).
class WpApi {
  WpApi({http.Client? client, String apiRoot = AppConfig.apiRoot})
      : _client = client ?? http.Client(),
        _root = Uri.parse(apiRoot);

  final http.Client _client;
  final Uri _root;

  static const _timeout = Duration(seconds: 20);

  Future<ArticlePage> fetchPosts({
    int page = 1,
    int perPage = AppConfig.perPage,
    int? categoryId,
    String? search,
  }) async {
    final uri = _endpoint('posts', {
      '_embed': 'author,wp:featuredmedia,wp:term',
      'page': '$page',
      'per_page': '$perPage',
      if (categoryId != null) 'categories': '$categoryId',
      if (search != null && search.isNotEmpty) 'search': search,
    });
    final res = await _get(uri);

    // WordPress répond 400 quand on demande une page au-delà de la dernière.
    if (res.statusCode == 400 &&
        res.body.contains('rest_post_invalid_page_number')) {
      return ArticlePage(const [], page - 1);
    }
    _check(res);

    final items = _decodeList(res.body, Article.fromWp);
    final totalPages = int.tryParse(res.headers['x-wp-totalpages'] ?? '') ??
        (items.length < perPage ? page : page + 1);
    return ArticlePage(items, totalPages);
  }

  Future<List<Category>> fetchCategories() async {
    final res = await _get(_endpoint('categories', {
      'per_page': '100',
      'hide_empty': 'true',
      'orderby': 'count',
      'order': 'desc',
      '_fields': 'id,name,count',
    }));
    _check(res);
    return _decodeList(res.body, Category.fromWp);
  }

  /// Un pare-feu ou une page de maintenance peut renvoyer du HTML au lieu du
  /// JSON attendu : on le signale comme une erreur du site.
  List<T> _decodeList<T>(
    String body,
    T Function(Map<String, dynamic>) parse,
  ) {
    try {
      return (jsonDecode(body) as List)
          .cast<Map<String, dynamic>>()
          .map(parse)
          .toList();
    } on FormatException {
      throw ApiException('Réponse inattendue du site.');
    } on TypeError {
      throw ApiException('Réponse inattendue du site.');
    }
  }

  Uri _endpoint(String path, Map<String, String> query) => _root.replace(
        path: '${_root.path}/$path',
        queryParameters: query,
      );

  Future<http.Response> _get(Uri uri) async {
    try {
      return await _client
          .get(uri, headers: const {'Accept': 'application/json'})
          .timeout(_timeout);
    } on Exception {
      throw ApiException('Connexion impossible. Vérifiez votre accès internet.');
    }
  }

  void _check(http.Response res) {
    if (res.statusCode != 200) {
      throw ApiException('Le site a répondu avec une erreur (${res.statusCode}).');
    }
  }
}
