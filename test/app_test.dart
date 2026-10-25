import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lebienheureux/main.dart';
import 'package:lebienheureux/services/local_store.dart';
import 'package:lebienheureux/services/wp_api.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fixtures.dart';

void main() {
  setUpAll(() => initializeDateFormatting('fr_FR'));

  testWidgets('affiche la une, les rubriques et ouvre un article',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = LocalStore(await SharedPreferences.getInstance());
    final api = WpApi(
      client: fakeWordPress([
        [
          wpPost(id: 1, title: 'Premier article'),
          wpPost(id: 2, title: 'Second article'),
        ],
      ]),
    );

    await tester.pumpWidget(LebienheureuxApp(api: api, store: store));
    await tester.pumpAndSettle();

    expect(find.text('Premier article'), findsOneWidget);
    expect(find.text('Second article'), findsOneWidget);
    expect(find.text('À la une'), findsOneWidget);
    expect(find.text('Société'), findsOneWidget);

    await tester.tap(find.text('Premier article'));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Ajouter aux favoris'), findsOneWidget);
    await tester.tap(find.byTooltip('Ajouter aux favoris'));
    await tester.pump();
    expect(find.byTooltip('Retirer des favoris'), findsOneWidget);

    await tester.tap(find.byTooltip('Retour'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Favoris'));
    await tester.pumpAndSettle();

    expect(find.text('Premier article'), findsWidgets);
    expect(find.byType(NavigationBar), findsOneWidget);
  });
}
