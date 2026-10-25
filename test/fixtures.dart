import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Un `post` au format de l'API REST WordPress avec `_embed`.
Map<String, dynamic> wpPost({
  required int id,
  String title = 'Titre',
  String? imageUrl,
}) =>
    {
      'id': id,
      'date': '2026-10-20T08:30:00',
      'date_gmt': '2026-10-20T06:30:00',
      'link': 'https://lebienheureux.be/article-$id/',
      'title': {'rendered': title},
      'excerpt': {'rendered': '<p>R&eacute;sum&eacute; de l&#8217;article $id</p>\n'},
      'content': {'rendered': '<p>Contenu <strong>complet</strong> $id</p>'},
      '_embedded': {
        'author': [
          {'id': 1, 'name': 'R&eacute;daction'},
        ],
        if (imageUrl != null)
          'wp:featuredmedia': [
            {
              'source_url': '$imageUrl-full.jpg',
              'media_details': {
                'sizes': {
                  'large': {'source_url': '$imageUrl-large.jpg'},
                },
              },
            },
          ],
        'wp:term': [
          [
            {'id': 3, 'name': 'Soci&eacute;t&eacute;', 'taxonomy': 'category'},
          ],
          [
            {'id': 9, 'name': 'Bruxelles', 'taxonomy': 'post_tag'},
          ],
        ],
      },
    };

/// Faux serveur WordPress : `pages[n]` est la liste renvoyée pour la page n+1.
MockClient fakeWordPress(
  List<List<Map<String, dynamic>>> pages, {
  List<Uri>? requests,
}) {
  return MockClient((req) async {
    requests?.add(req.url);
    if (req.url.path.endsWith('/categories')) {
      return http.Response(
        jsonEncode([
          {'id': 3, 'name': 'Soci&eacute;t&eacute;', 'count': 12},
          {'id': 4, 'name': 'Culture', 'count': 7},
        ]),
        200,
      );
    }
    final page = int.parse(req.url.queryParameters['page'] ?? '1');
    if (page > pages.length) {
      return http.Response(
        '{"code":"rest_post_invalid_page_number","data":{"status":400}}',
        400,
      );
    }
    return http.Response(
      jsonEncode(pages[page - 1]),
      200,
      headers: {
        'x-wp-totalpages': '${pages.length}',
        'content-type': 'application/json; charset=UTF-8',
      },
    );
  });
}
