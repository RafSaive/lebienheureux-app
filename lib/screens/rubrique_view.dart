import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/local_store.dart';
import '../services/wp_api.dart';
import '../state/feed_controller.dart';
import '../theme.dart';
import '../widgets/feed_list.dart';
import '../widgets/journal_bits.dart';
import '../widgets/tiles.dart';

/// Page de rubrique : grand titre, puis les articles en photos pleine
/// largeur avec le titre en surimpression, comme sur le site.
class RubriqueView extends StatelessWidget {
  const RubriqueView({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final feed = context.watch<FeedController>();

    return FeedList(
      controller: feed,
      storageKey: 'rubrique-${feed.categoryId}',
      emptyTitle: 'Rubrique encore vide',
      emptyText: 'Le capybara n’a encore rien rangé ici.',
      rows: (context) {
        final items = feed.articles;
        return [
          (_) => Padding(
            padding: const EdgeInsets.only(top: 18, bottom: 6),
            child: Text(
              title.toUpperCase(),
              style: const TextStyle(
                fontFamily: Fonts.manchette,
                fontSize: 34,
                height: 1.05,
                color: Palette.encre,
              ),
            ),
          ),
          (_) => const Divider(color: Palette.filetMoyen),
          (_) => const SizedBox(height: 16),
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) (_) => const Filet(margin: 16),
            (_) => OverlayTile(article: items[i], list: items),
          ],
        ];
      },
    );
  }
}

/// Une rubrique ouverte depuis le menu (hors bandeau de navigation).
class RubriqueScreen extends StatelessWidget {
  const RubriqueScreen({
    super.key,
    required this.title,
    required this.categoryId,
  });

  final String title;
  final int categoryId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => FeedController(
        context.read<WpApi>(),
        context.read<LocalStore>(),
        categoryId: categoryId,
        cacheKey: 'cat:$categoryId',
      )..start(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(title.toUpperCase(), style: Typo.etiquette),
          shape: const Border(bottom: BorderSide(color: Palette.filet)),
        ),
        body: RubriqueView(title: title),
      ),
    );
  }
}
