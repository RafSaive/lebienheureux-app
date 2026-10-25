import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lebienheureux/services/wp_api.dart';

import 'fixtures.dart';

void main() {
  test('interroge /posts avec pagination, rubrique (et sous-rubriques) et recherche', () async {
    final requests = <Uri>[];
    final api = WpApi(
      client: fakeWordPress(
        const [],
        byCategory: {
          19: [wpPost(id: 1)],
        },
        requests: requests,
      ),
    );

    await api.fetchPosts(page: 1, categoryId: 19, search: 'été');

    final url = requests.single;
    expect(url.path, '/wp-json/wp/v2/posts');
    expect(url.host, 'lebienheureux.be');
    expect(url.queryParameters['page'], '1');
    expect(url.queryParameters['categories[terms]'], '19');
    expect(url.queryParameters['categories[include_children]'], '1');
    expect(url.queryParameters['search'], 'été');
    expect(url.queryParameters['_embed'], 'wp:featuredmedia,wp:term');
  });

  test('transforme les posts WordPress en articles', () async {
    final api = WpApi(
      client: fakeWordPress([
        [
          wpPost(
            id: 7,
            title: '🧪 L&#8217;&eacute;dito',
            imageUrl: 'https://img/x',
          ),
        ],
        [wpPost(id: 8)],
      ]),
    );

    final page = await api.fetchPosts();
    final a = page.items.single;

    expect(page.totalPages, 2);
    expect(a.id, 7);
    expect(a.title, 'L’édito');
    expect(a.mark, '🧪');
    expect(a.excerpt, 'Résumé de l’article 7');
    expect(a.contentHtml, contains('<strong>complet</strong>'));
    expect(a.imageUrl, 'https://img/x-une.jpg');
    expect(a.thumbUrl, 'https://img/x-cote.jpg');
    expect(a.imageCredit, 'Photo © Wikimedia');
    expect(a.imageAlt, 'Une photo');
    expect(a.rubrique, 'Actualités');
    expect(a.date, DateTime.utc(2026, 10, 20, 6, 30));
    expect(a.readingMinutes, 1);
  });

  test('une page au-delà de la dernière renvoie une liste vide', () async {
    final api = WpApi(
      client: fakeWordPress([
        [wpPost(id: 1)],
      ]),
    );
    final page = await api.fetchPosts(page: 2);
    expect(page.items, isEmpty);
    expect(page.totalPages, 1);
  });

  test('lit les rubriques avec slug et parent', () async {
    final api = WpApi(client: fakeWordPress(const []));
    final categories = await api.fetchCategories();
    expect(categories.first.name, 'Actualités');
    expect(categories.firstWhere((c) => c.slug == 'satellites').parent, 19);
  });

  test('lit une page du site', () async {
    final api = WpApi(client: fakeWordPress(const []));
    final page = await api.fetchPage('a-propos');
    expect(page.title, 'À propos');
    expect(page.contentHtml, contains('le temps d&#8217;une pause'));
    expect(api.fetchPage('inconnue'), throwsA(isA<ApiException>()));
  });

  test('une réponse HTML devient une ApiException', () async {
    final api = WpApi(
      client: MockClient(
        (_) async => http.Response('<html>Maintenance</html>', 200),
      ),
    );
    expect(api.fetchPosts(), throwsA(isA<ApiException>()));
  });

  test('une erreur réseau devient une ApiException', () async {
    final api = WpApi(
      client: MockClient(
        (_) async => throw const SocketException('hors-ligne'),
      ),
    );
    expect(api.fetchPosts(), throwsA(isA<ApiException>()));
  });

  test('un code HTTP inattendu devient une ApiException', () async {
    final api = WpApi(client: MockClient((_) async => http.Response('', 503)));
    expect(api.fetchCategories(), throwsA(isA<ApiException>()));
  });
}
