import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Un `post` au format de l'API REST WordPress avec `_embed`, calqué sur
/// les réponses de lebienheureux.be.
Map<String, dynamic> wpPost({
  required int id,
  String title = 'Titre',
  String category = 'Actualit&eacute;s',
  String? imageUrl,
}) => {
  'id': id,
  'date': '2026-10-20T08:30:00',
  'date_gmt': '2026-10-20T06:30:00',
  'link': 'https://lebienheureux.be/2026/10/article-$id/',
  'title': {'rendered': title},
  'excerpt': {
    'rendered': '<p>R&eacute;sum&eacute; de l&#8217;article $id</p>\n',
  },
  'content': {
    'rendered':
        '<p class="wp-block-paragraph">Contenu <strong>complet</strong> $id</p>'
        '<h2 class="wp-block-heading">Intertitre</h2><p>Suite.</p>',
  },
  '_embedded': {
    if (imageUrl != null)
      'wp:featuredmedia': [
        {
          'source_url': '$imageUrl-full.jpg',
          'alt_text': 'Une photo',
          'caption': {'rendered': '<p>Photo &copy; Wikimedia</p>\n'},
          'media_details': {
            'sizes': {
              'lbn_une': {'source_url': '$imageUrl-une.jpg'},
              'lbn_cote': {'source_url': '$imageUrl-cote.jpg'},
              'large': {'source_url': '$imageUrl-large.jpg'},
            },
          },
        },
      ],
    'wp:term': [
      [
        {'id': 1, 'name': category, 'taxonomy': 'category'},
      ],
      [
        {'id': 9, 'name': 'Bruxelles', 'taxonomy': 'post_tag'},
      ],
    ],
  },
};

const wpCategories = [
  {
    'id': 1,
    'name': 'Actualit&eacute;s',
    'slug': 'actualites',
    'count': 249,
    'parent': 0,
  },
  {
    'id': 4,
    'name': 'Bien expliqu&eacute;',
    'slug': 'bien-explique',
    'count': 75,
    'parent': 0,
  },
  {'id': 5, 'name': 'Pratique', 'slug': 'pratique', 'count': 61, 'parent': 0},
  {
    'id': 9,
    'name': 'IA, encore!',
    'slug': 'ia-encore',
    'count': 35,
    'parent': 0,
  },
  {'id': 19, 'name': 'Dossiers', 'slug': 'dossiers', 'count': 0, 'parent': 0},
  {
    'id': 20,
    'name': 'Satellites',
    'slug': 'satellites',
    'count': 4,
    'parent': 19,
  },
  {'id': 6, 'name': 'Vide', 'slug': 'vide', 'count': 0, 'parent': 0},
];

/// Faux serveur WordPress. `pages[n]` est la liste renvoyée pour la page n+1
/// du fil général ; [byCategory] donne les articles d'une rubrique.
MockClient fakeWordPress(
  List<List<Map<String, dynamic>>> pages, {
  Map<int, List<Map<String, dynamic>>> byCategory = const {},
  List<Uri>? requests,
}) {
  return MockClient((req) async {
    requests?.add(req.url);
    final q = req.url.queryParameters;
    if (req.url.path.endsWith('/categories')) {
      return _json(wpCategories);
    }
    if (req.url.path.endsWith('/pages')) {
      return _json([
        if (q['slug'] == 'a-propos')
          {
            'title': {'rendered': '&Agrave; propos'},
            'content': {
              'rendered': '<p>Un journal tech, le temps d&#8217;une pause.</p>',
            },
            'link': 'https://lebienheureux.be/a-propos/',
          },
      ]);
    }
    final category = int.tryParse(q['categories[terms]'] ?? '');
    final source = category == null
        ? pages
        : [byCategory[category] ?? const []];
    final page = int.parse(q['page'] ?? '1');
    if (page > source.length) {
      return http.Response(
        '{"code":"rest_post_invalid_page_number","data":{"status":400}}',
        400,
      );
    }
    return _json(source[page - 1], totalPages: source.length);
  });
}

http.Response _json(Object body, {int? totalPages}) => http.Response.bytes(
  utf8.encode(jsonEncode(body)),
  200,
  headers: {
    'content-type': 'application/json; charset=UTF-8',
    'x-wp-totalpages': '${totalPages ?? 1}',
  },
);
