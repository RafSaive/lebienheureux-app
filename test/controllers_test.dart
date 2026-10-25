import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:lebienheureux/services/local_store.dart';
import 'package:lebienheureux/services/wp_api.dart';
import 'package:lebienheureux/state/favorites_controller.dart';
import 'package:lebienheureux/state/feed_controller.dart';
import 'package:lebienheureux/state/journal_controller.dart';
import 'package:lebienheureux/state/speech_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fixtures.dart';

Future<LocalStore> _emptyStore() async {
  SharedPreferences.setMockInitialValues({});
  return LocalStore(await SharedPreferences.getInstance());
}

WpApi _offlineApi() =>
    WpApi(client: MockClient((_) async => throw const SocketException('x')));

void main() {
  group('FeedController', () {
    test('charge la une, puis les pages suivantes sans doublon', () async {
      final c = FeedController(
        WpApi(
          client: fakeWordPress([
            [wpPost(id: 1), wpPost(id: 2)],
            [wpPost(id: 2), wpPost(id: 3)],
          ]),
        ),
        await _emptyStore(),
      );

      await c.start();
      expect(c.articles.map((a) => a.id), [1, 2]);
      expect(c.hasMore, isTrue);

      await c.loadMore();
      expect(c.articles.map((a) => a.id), [1, 2, 3]);
      expect(c.hasMore, isFalse);

      await c.loadMore();
      expect(c.articles, hasLength(3));
    });

    test('sans réseau, affiche la dernière liste enregistrée', () async {
      final store = await _emptyStore();
      await FeedController(
        WpApi(
          client: fakeWordPress([
            [wpPost(id: 42)],
          ]),
        ),
        store,
        cacheKey: 'home',
      ).start();

      final offline = FeedController(_offlineApi(), store, cacheKey: 'home');
      await offline.start();

      expect(offline.offline, isTrue);
      expect(offline.error, isNull);
      expect(offline.articles.single.id, 42);
    });

    test('sans réseau ni cache, expose un message d\'erreur', () async {
      final c = FeedController(_offlineApi(), await _emptyStore());
      await c.start();

      expect(c.articles, isEmpty);
      expect(c.error, isNotNull);
    });

    test(
      'la recherche relance la requête ; une recherche vide efface',
      () async {
        final requests = <Uri>[];
        final c = FeedController(
          WpApi(
            client: fakeWordPress([
              [wpPost(id: 1)],
            ], requests: requests),
          ),
          await _emptyStore(),
        );

        await c.search('  climat ');
        expect(c.query, 'climat');
        expect(requests.last.queryParameters['search'], 'climat');
        expect(c.articles, hasLength(1));

        await c.search('');
        expect(c.articles, isEmpty);
        expect(c.loading, isFalse);
      },
    );
  });

  group('JournalController', () {
    test('charge les rubriques et les blocs de la une', () async {
      final journal = JournalController(
        WpApi(
          client: fakeWordPress(
            const [],
            byCategory: {
              4: [wpPost(id: 40), wpPost(id: 41)],
              9: [wpPost(id: 90)],
            },
          ),
        ),
        await _emptyStore(),
      );

      await journal.init();

      expect(journal.bySlug('pratique')?.id, 5);
      expect(journal.section('bien-explique').map((a) => a.id), [40, 41]);
      expect(journal.section('ia-encore').map((a) => a.id), [90]);
      expect(journal.section('pratique'), isEmpty);
      // « Dossiers » n'a que des sous-rubriques : il reste dans le menu.
      final menu = journal.rubriques.map((c) => c.slug);
      expect(menu, containsAll(['actualites', 'dossiers']));
      expect(menu, isNot(contains('vide')));
      expect(menu, isNot(contains('satellites')));
    });

    test('garde rubriques et blocs hors-ligne', () async {
      final store = await _emptyStore();
      await JournalController(
        WpApi(
          client: fakeWordPress(
            const [],
            byCategory: {
              4: [wpPost(id: 40)],
            },
          ),
        ),
        store,
      ).init();

      final offline = JournalController(_offlineApi(), store);
      await offline.init();

      expect(offline.categories, isNotEmpty);
      expect(offline.section('bien-explique').single.id, 40);
    });
  });

  test('les favoris persistent entre deux lancements', () async {
    final store = await _emptyStore();
    final page = await WpApi(
      client: fakeWordPress([
        [wpPost(id: 5, title: '🔑 Cl&eacute;s')],
      ]),
    ).fetchPosts();
    final article = page.items.single;

    final favorites = FavoritesController(store);
    await favorites.toggle(article);
    expect(favorites.contains(5), isTrue);

    final reloaded = FavoritesController(store);
    final saved = reloaded.items.single;
    expect(saved.title, 'Clés');
    expect(saved.mark, '🔑');
    expect(saved.contentHtml, article.contentHtml);
    expect(saved.date, article.date);

    await reloaded.toggle(article);
    expect(FavoritesController(store).items, isEmpty);
  });

  test('la lecture à voix haute découpe le texte en blocs', () async {
    final long = List.filled(40, '<p>${'mot ' * 20}</p>').join();
    final page = await WpApi(
      client: fakeWordPress([
        [wpPost(id: 1)],
      ]),
    ).fetchPosts();
    final article = page.items.single;

    final chunks = SpeechController.chunksFor(article);
    expect(chunks.first, startsWith('Titre'));
    expect(chunks.join(' '), contains('Intertitre'));

    final big = SpeechController.chunksFor(
      (await WpApi(
        client: fakeWordPress([
          [
            {
              ...wpPost(id: 2),
              'content': {'rendered': long},
            },
          ],
        ]),
      ).fetchPosts()).items.single,
    );
    expect(big.length, greaterThan(1));
    expect(big.every((c) => c.length <= 1600), isTrue);
  });
}
