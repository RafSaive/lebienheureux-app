import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:lebienheureux/services/local_store.dart';
import 'package:lebienheureux/services/wp_api.dart';
import 'package:lebienheureux/state/articles_controller.dart';
import 'package:lebienheureux/state/favorites_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fixtures.dart';

Future<LocalStore> _emptyStore() async {
  SharedPreferences.setMockInitialValues({});
  return LocalStore(await SharedPreferences.getInstance());
}

void main() {
  test('charge la une, puis les pages suivantes sans doublon', () async {
    final store = await _emptyStore();
    final c = ArticlesController(
      WpApi(
        client: fakeWordPress([
          [wpPost(id: 1), wpPost(id: 2)],
          [wpPost(id: 2), wpPost(id: 3)],
        ]),
      ),
      store,
    );

    await c.init();
    expect(c.articles.map((a) => a.id), [1, 2]);
    expect(c.categories, hasLength(2));
    expect(c.hasMore, isTrue);

    await c.loadMore();
    expect(c.articles.map((a) => a.id), [1, 2, 3]);
    expect(c.hasMore, isFalse);

    await c.loadMore();
    expect(c.articles, hasLength(3));
  });

  test('sans réseau, affiche la dernière une enregistrée', () async {
    final store = await _emptyStore();
    await ArticlesController(
      WpApi(client: fakeWordPress([[wpPost(id: 42)]])),
      store,
    ).refresh();

    final offline = ArticlesController(
      WpApi(client: MockClient((_) async => throw const SocketException('x'))),
      store,
    );
    await offline.refresh();

    expect(offline.offline, isTrue);
    expect(offline.error, isNull);
    expect(offline.articles.single.id, 42);
  });

  test('sans réseau ni cache, expose un message d\'erreur', () async {
    final c = ArticlesController(
      WpApi(client: MockClient((_) async => throw const SocketException('x'))),
      await _emptyStore(),
    );
    await c.refresh();

    expect(c.articles, isEmpty);
    expect(c.error, isNotNull);
  });

  test('la recherche relance la requête avec le terme', () async {
    final requests = <Uri>[];
    final c = ArticlesController(
      WpApi(client: fakeWordPress([[wpPost(id: 1)]], requests: requests)),
      await _emptyStore(),
    );

    await c.search('  climat ');
    expect(c.query, 'climat');
    expect(requests.last.queryParameters['search'], 'climat');
  });

  test('les favoris persistent entre deux lancements', () async {
    final store = await _emptyStore();
    final page = await WpApi(client: fakeWordPress([[wpPost(id: 5)]])).fetchPosts();
    final article = page.items.single;

    final favorites = FavoritesController(store);
    await favorites.toggle(article);
    expect(favorites.contains(5), isTrue);

    final reloaded = FavoritesController(store);
    expect(reloaded.items.single.title, article.title);
    expect(reloaded.items.single.contentHtml, article.contentHtml);

    await reloaded.toggle(article);
    expect(FavoritesController(store).items, isEmpty);
  });
}
