import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/favorites_controller.dart';
import '../theme.dart';
import '../widgets/journal_bits.dart';
import '../widgets/tiles.dart';

/// Articles gardés pour la prochaine pause, lisibles même sans réseau.
class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = context.watch<FavoritesController>().items;

    return Scaffold(
      appBar: AppBar(
        title: Text('MES FAVORIS', style: Typo.etiquette),
        shape: const Border(bottom: BorderSide(color: Palette.filet)),
      ),
      body: items.isEmpty
          ? ListView(
              children: const [
                CapybaraMessage(
                  title: 'Rien de côté pour l’instant',
                  text:
                      'Touchez le signet d’un article pour le garder pour la '
                      'prochaine pause. Il restera lisible même sans réseau.',
                ),
              ],
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              itemCount: items.length,
              separatorBuilder: (_, _) => const Filet(margin: 18),
              itemBuilder: (_, i) => PhotoTile(article: items[i], list: items),
            ),
    );
  }
}
