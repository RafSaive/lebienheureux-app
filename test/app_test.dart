import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lebienheureux/main.dart';
import 'package:lebienheureux/services/wp_api.dart';
import 'package:lebienheureux/widgets/nav_strip.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fixtures.dart';

void main() {
  setUpAll(() => initializeDateFormatting('fr_FR'));

  Future<void> launch(WidgetTester tester, {List<Uri>? requests}) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    mockHomeWidget();
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final api = WpApi(
      client: fakeWordPress(
        [
          [
            wpPost(id: 1, title: '🛰️ Premier article'),
            wpPost(id: 2, title: 'Second article'),
            wpPost(id: 3, title: 'Troisième article'),
          ],
        ],
        byCategory: {
          4: [
            wpPost(
              id: 40,
              title: '🔑 La clé valait 4',
              category: 'Bien expliqu&eacute;',
            ),
            wpPost(
              id: 41,
              title: 'Voyager 1',
              category: 'Bien expliqu&eacute;',
            ),
          ],
        },
        requests: requests,
      ),
    );

    await tester.pumpWidget(LebienheureuxApp(api: api, prefs: prefs));
    await tester.pumpAndSettle();
  }

  testWidgets('la une reprend la mise en page du journal', (tester) async {
    await launch(tester);

    expect(find.text('Le Bien Heureux'), findsOneWidget);
    expect(find.text('.be'), findsOneWidget);
    for (final rubrique in ['À LA UNE', 'ACTUALITÉS', 'BIEN EXPLIQUÉ']) {
      expect(
        find.descendant(
          of: find.byType(NavStrip),
          matching: find.text(rubrique),
        ),
        findsOneWidget,
        reason: rubrique,
      );
    }

    expect(find.text('Premier article'), findsOneWidget);
    expect(find.text('🛰️ ACTUALITÉS  •  20 OCTOBRE 2026'), findsOneWidget);
    expect(find.text('Résumé de l’article 1'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('La clé valait 4'),
      300,
      scrollable: find.descendant(
        of: find.byKey(const PageStorageKey('une')),
        matching: find.byType(Scrollable),
      ),
    );
    expect(find.text('TOUT VOIR ›'), findsOneWidget);
    expect(find.text('🔑 BIEN EXPLIQUÉ  •  20 OCTOBRE 2026'), findsOneWidget);
  });

  testWidgets('on lit un article, on le garde et on passe au suivant', (
    tester,
  ) async {
    await launch(tester);

    await tester.tap(find.text('Premier article'));
    await tester.pumpAndSettle();

    expect(find.text('🛰️  ACTUALITÉS'), findsOneWidget);
    expect(
      find.text('MARDI 20 OCTOBRE  ·  ≈ 1 MIN DE LECTURE'),
      findsOneWidget,
    );
    expect(find.text('ÉCOUTER L\'ARTICLE'), findsOneWidget);
    expect(find.text('Intertitre', findRichText: true), findsOneWidget);

    await tester.tap(find.byTooltip('Garder pour la prochaine pause'));
    await tester.pump();
    expect(find.byTooltip('Retirer des favoris'), findsOneWidget);

    // Lecture fluide : on glisse vers l'article suivant.
    await tester.fling(find.byType(PageView), const Offset(-300, 0), 1500);
    await tester.pumpAndSettle();
    expect(find.text('Second article'), findsWidgets);
    expect(find.byTooltip('Garder pour la prochaine pause'), findsOneWidget);

    // Fin d'article : la newsletter est clairement gratuite.
    await tester.scrollUntilVisible(
      find.text('NEWSLETTER GRATUITE'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('M’INSCRIRE — C’EST GRATUIT'), findsOneWidget);
    expect(find.textContaining('abonnement'), findsNothing);

    await tester.tap(find.byTooltip('Retour'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('MES FAVORIS'));
    await tester.pumpAndSettle();
    expect(find.text('Premier article'), findsOneWidget);
  });

  testWidgets('un retour rapide dans l\'app ne recharge rien', (tester) async {
    await launch(tester);
    final binding = tester.binding;

    // Retour rapide : rien ne bouge.
    binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.text('Premier article'), findsOneWidget);
  });

  testWidgets('une rubrique s\'ouvre depuis le bandeau', (tester) async {
    await launch(tester);

    final tab = find.descendant(
      of: find.byType(NavStrip),
      matching: find.text('BIEN EXPLIQUÉ'),
    );
    await tester.ensureVisible(tab);
    await tester.pumpAndSettle();
    await tester.tap(tab);
    await tester.pumpAndSettle();
    expect(find.text('Voyager 1'), findsOneWidget);
    expect(find.text('La clé valait 4'), findsOneWidget);
  });
}
