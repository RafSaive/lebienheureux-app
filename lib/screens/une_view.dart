import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config.dart';
import '../state/feed_controller.dart';
import '../state/journal_controller.dart';
import '../widgets/feed_list.dart';
import '../widgets/journal_bits.dart';
import '../widgets/tiles.dart';
import '../theme.dart';

/// La une, mise en page comme celle du site : l'article principal, les titres
/// suivants, les blocs de rubrique, puis « Les jours précédents » à l'infini.
class UneView extends StatelessWidget {
  const UneView({super.key, required this.onRubrique});

  /// Appelé par « Tout voir › » avec le slug de la rubrique.
  final ValueChanged<String> onRubrique;

  static const _withResume = 3;
  static const _une = 6;

  @override
  Widget build(BuildContext context) {
    final feed = context.watch<FeedController>();
    final journal = context.watch<JournalController>();

    return FeedList(
      controller: feed,
      storageKey: 'une',
      rows: (context) {
        final items = feed.articles;
        final rows = <WidgetBuilder>[];

        rows.add(
          (_) => Padding(
            padding: const EdgeInsets.only(top: 12),
            child: UneTile(article: items.first, list: items),
          ),
        );
        for (var i = 1; i < items.length && i < _une; i++) {
          rows.add((_) => const Filet());
          rows.add(
            (_) => TitreTile(
              article: items[i],
              list: items,
              resume: i < _withResume,
            ),
          );
        }
        rows.add((_) => const Filet(color: Palette.encre, margin: 22));

        for (final slug in AppConfig.homeSections) {
          final section = journal.section(slug);
          final category = journal.bySlug(slug);
          if (section.isEmpty || category == null) continue;
          rows.add(
            (_) => Etiquette(
              label: category.name,
              onToutVoir: () => onRubrique(slug),
            ),
          );
          rows.add((_) => PhotoTile(article: section.first, list: section));
          for (final a in section.skip(1)) {
            rows.add((_) => const Filet());
            rows.add((_) => TitreTile(article: a, list: section));
          }
        }

        if (items.length > _une) {
          rows.add((_) => const Etiquette(label: 'Les jours précédents'));
          for (var i = _une; i < items.length; i++) {
            if (i > _une) rows.add((_) => const Filet(margin: 18));
            rows.add((_) => PhotoTile(article: items[i], list: items));
          }
        }
        return rows;
      },
    );
  }
}
