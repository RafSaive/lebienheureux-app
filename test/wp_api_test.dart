import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lebienheureux/services/wp_api.dart';

import 'fixtures.dart';

void main() {
  test('interroge /posts avec pagination, rubrique et recherche', () async {
    final requests = <Uri>[];
    final api = WpApi(
      client: fakeWordPress([
        [wpPost(id: 1)],
      ], requests: requests),
    );

    await api.fetchPosts(page: 1, categoryId: 3, search: 'été');

    final url = requests.single;
    expect(url.toString(), startsWith('https://lebienheureux.be/wp-json/wp/v2/posts?'));
    expect(url.queryParameters['page'], '1');
    expect(url.queryParameters['categories'], '3');
    expect(url.queryParameters['search'], 'été');
    expect(url.queryParameters['_embed'], contains('wp:featuredmedia'));
  });

  test('transforme les posts WordPress en articles', () async {
    final api = WpApi(
      client: fakeWordPress([
        [wpPost(id: 7, title: 'L&#8217;&eacute;dito', imageUrl: 'https://img/x')],
        [wpPost(id: 8)],
      ]),
    );

    final page = await api.fetchPosts();
    final a = page.items.single;

    expect(page.totalPages, 2);
    expect(a.id, 7);
    expect(a.title, 'L’édito');
    expect(a.excerpt, 'Résumé de l’article 7');
    expect(a.contentHtml, contains('<strong>complet</strong>'));
    expect(a.imageUrl, 'https://img/x-large.jpg');
    expect(a.author, 'Rédaction');
    expect(a.categories, ['Société']);
    expect(a.date, DateTime.utc(2026, 10, 20, 6, 30).toLocal());
  });

  test('une page au-delà de la dernière renvoie une liste vide', () async {
    final api = WpApi(client: fakeWordPress([[wpPost(id: 1)]]));
    final page = await api.fetchPosts(page: 2);
    expect(page.items, isEmpty);
    expect(page.totalPages, 1);
  });

  test('lit les rubriques', () async {
    final api = WpApi(client: fakeWordPress(const []));
    final categories = await api.fetchCategories();
    expect(categories.map((c) => c.name), ['Société', 'Culture']);
  });

  test('une réponse HTML devient une ApiException', () async {
    final api = WpApi(
      client: MockClient((_) async => http.Response('<html>Maintenance</html>', 200)),
    );
    expect(api.fetchPosts(), throwsA(isA<ApiException>()));
  });

  test('une erreur réseau devient une ApiException', () async {
    final api = WpApi(
      client: MockClient((_) async => throw const SocketException('hors-ligne')),
    );
    expect(api.fetchPosts(), throwsA(isA<ApiException>()));
  });

  test('un code HTTP inattendu devient une ApiException', () async {
    final api = WpApi(client: MockClient((_) async => http.Response('', 503)));
    expect(api.fetchCategories(), throwsA(isA<ApiException>()));
  });
}
