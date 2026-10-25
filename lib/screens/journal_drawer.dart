import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config.dart';
import '../state/journal_controller.dart';
import '../theme.dart';
import '../widgets/article_html.dart';
import '../widgets/journal_bits.dart';
import '../widgets/manchette.dart';
import 'favorites_screen.dart';
import 'page_screen.dart';

/// Menu latéral : favoris, toutes les rubriques et les pages du journal.
class JournalDrawer extends StatelessWidget {
  const JournalDrawer({super.key, required this.onRubrique});

  final ValueChanged<String> onRubrique;

  @override
  Widget build(BuildContext context) {
    final journal = context.watch<JournalController>();

    void push(Widget screen) {
      Navigator.of(context)
        ..pop()
        ..push(MaterialPageRoute<void>(builder: (_) => screen));
    }

    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: Manchette(size: 24),
            ),
            const SizedBox(height: 8),
            Text(AppConfig.tagline, style: Typo.chapo.copyWith(fontSize: 17)),
            const SizedBox(height: 8),
            _Link(
              label: 'Mes favoris',
              icon: Icons.bookmark_border,
              onTap: () => push(const FavoritesScreen()),
            ),
            const Etiquette(label: 'Rubriques'),
            for (final c in journal.rubriques)
              _Link(
                label: c.name,
                onTap: () {
                  Navigator.of(context).pop();
                  onRubrique(c.slug);
                },
              ),
            const Etiquette(label: 'Le journal'),
            for (final (slug, title) in AppConfig.pages)
              _Link(
                label: title,
                onTap: () => push(PageScreen(slug: slug, title: title)),
              ),
            _Link(
              label: 'Contact',
              icon: Icons.north_east,
              onTap: () => openLink(AppConfig.contactUrl),
            ),
            const SizedBox(height: 28),
            Text(
              'Fait en Belgique, à lire où vous voulez.\n'
              'Surtout là où vous pensez.',
              style: Typo.credit,
            ),
          ],
        ),
      ),
    );
  }
}

class _Link extends StatelessWidget {
  const _Link({required this.label, required this.onTap, this.icon});

  final String label;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 11),
        child: Row(
          children: [
            Expanded(child: Text(label.toUpperCase(), style: Typo.nav)),
            Icon(
              icon ?? Icons.chevron_right,
              size: 18,
              color: Palette.encrePale,
            ),
          ],
        ),
      ),
    );
  }
}
