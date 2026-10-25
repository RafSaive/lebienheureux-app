import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../state/feed_controller.dart';
import '../theme.dart';
import 'journal_bits.dart';
import 'skeleton.dart';

/// Liste défilante branchée sur un [FeedController] : tirer pour actualiser,
/// chargement continu en bas, états vide / hors-ligne / erreur.
/// [rows] construit les lignes à partir des articles chargés.
class FeedList extends StatefulWidget {
  const FeedList({
    super.key,
    required this.controller,
    required this.rows,
    required this.storageKey,
    this.emptyTitle = 'Rien à lire ici pour l’instant',
    this.emptyText,
    this.onRefresh,
  });

  final FeedController controller;
  final List<WidgetBuilder> Function(BuildContext context) rows;
  final String storageKey;
  final String emptyTitle;
  final String? emptyText;

  /// Ce que fait « tirer pour actualiser » (par défaut : la liste seule).
  final Future<void> Function()? onRefresh;

  @override
  State<FeedList> createState() => _FeedListState();
}

class _FeedListState extends State<FeedList> {
  bool _onScroll(ScrollNotification n) {
    if (n.metrics.axis == Axis.vertical && n.metrics.extentAfter < 900) {
      widget.controller.loadMore();
    }
    return false;
  }

  Future<void> _refresh() async {
    HapticFeedback.lightImpact();
    await (widget.onRefresh ?? widget.controller.refresh)();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;

    if (c.articles.isEmpty) {
      if (c.loading) return const UneSkeleton();
      return RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            if (c.error != null)
              CapybaraMessage(
                title: 'Pas de réseau dans la pièce ?',
                text:
                    '${c.error}\nLe journal arrive dès que la connexion revient.',
                action: 'Réessayer',
                onAction: c.refresh,
              )
            else
              CapybaraMessage(title: widget.emptyTitle, text: widget.emptyText),
          ],
        ),
      );
    }

    final rows = widget.rows(context);
    return RefreshIndicator(
      onRefresh: _refresh,
      child: NotificationListener<ScrollNotification>(
        onNotification: _onScroll,
        child: ListView.builder(
          key: PageStorageKey(widget.storageKey),
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
          itemCount: rows.length + 1,
          itemBuilder: (context, i) =>
              i < rows.length ? rows[i](context) : _footer(c),
        ),
      ),
    );
  }

  Widget _footer(FeedController c) {
    if (c.loadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: SizedBox.square(
            dimension: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    final text = c.offline
        ? 'Hors-ligne : voici l’édition gardée sous le coude.'
        : c.hasMore
        ? ''
        : 'Fin du rouleau : vous avez tout lu !';
    if (text.isEmpty) return const SizedBox(height: 48);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: Typo.chapo.copyWith(fontSize: 17, color: Palette.encrePale),
      ),
    );
  }
}
