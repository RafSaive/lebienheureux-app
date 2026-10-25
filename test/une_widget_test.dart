import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lebienheureux/main.dart';
import 'package:lebienheureux/services/une_widget.dart';
import 'package:lebienheureux/services/wp_api.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fixtures.dart';

void main() {
  setUpAll(() => initializeDateFormatting('fr_FR'));

  group('liens du widget', () {
    test('reconnaît un lien d’article', () {
      expect(
        UneWidget.articleId(
          Uri.parse('lebienheureux://article/2028?homeWidget'),
        ),
        2028,
      );
    });

    test('ignore les autres liens', () {
      expect(UneWidget.articleId(null), isNull);
      expect(
        UneWidget.articleId(Uri.parse('https://lebienheureux.be/article/1')),
        isNull,
      );
      expect(
        UneWidget.articleId(Uri.parse('lebienheureux://article/')),
        isNull,
      );
      expect(
        UneWidget.articleId(Uri.parse('lebienheureux://autre/12')),
        isNull,
      );
    });
  });

  Future<List<MethodCall>> launch(WidgetTester tester, {String? from}) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final calls = <MethodCall>[];
    mockHomeWidget(launchedFrom: from, calls: calls);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final api = WpApi(
      client: fakeWordPress(
        [
          [
            wpPost(id: 1, title: 'Premier article'),
            wpPost(id: 2, title: 'Second article'),
          ],
        ],
        extra: [wpPost(id: 77, title: 'Un article plus ancien')],
      ),
    );
    await tester.pumpWidget(LebienheureuxApp(api: api, prefs: prefs));
    await tester.pumpAndSettle();
    return calls;
  }

  testWidgets('la nouvelle une met le widget à jour', (tester) async {
    final calls = await launch(tester);

    final updates = calls.where((c) => c.method == 'updateWidget').toList();
    expect(updates, hasLength(1));
    expect(updates.single.arguments['ios'], 'UneWidget');
    expect(
      updates.single.arguments['qualifiedAndroidName'],
      'be.lebienheureux.lebienheureux.UneWidgetProvider',
    );
  });

  testWidgets('un toucher sur le widget ouvre l’article', (tester) async {
    await launch(tester, from: 'lebienheureux://article/2?homeWidget');

    expect(find.text('ÉCOUTER L\'ARTICLE'), findsOneWidget);
    expect(find.text('Second article'), findsOneWidget);
  });

  testWidgets('un article absent de la une est chargé à la demande', (
    tester,
  ) async {
    await launch(tester, from: 'lebienheureux://article/77?homeWidget');

    expect(find.text('ÉCOUTER L\'ARTICLE'), findsOneWidget);
    expect(find.text('Un article plus ancien'), findsOneWidget);
  });
}
