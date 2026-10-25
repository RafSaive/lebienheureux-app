import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config.dart';
import '../services/local_store.dart';
import '../services/wp_api.dart';
import '../state/feed_controller.dart';
import '../state/journal_controller.dart';
import '../widgets/manchette.dart';
import '../widgets/nav_strip.dart';
import 'journal_drawer.dart';
import 'rubrique_view.dart';
import 'search_screen.dart';
import 'une_view.dart';

/// Écran principal : manchette, bandeau des rubriques, puis la une ou la
/// rubrique choisie.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  static const _une = 'une';

  final _scaffold = GlobalKey<ScaffoldState>();
  final _feeds = <String, FeedController>{};
  String _tab = _une;
  late final WpApi _api;
  late final LocalStore _store;

  @override
  void initState() {
    super.initState();
    _api = context.read<WpApi>();
    _store = context.read<LocalStore>();
  }

  @override
  void dispose() {
    for (final f in _feeds.values) {
      f.dispose();
    }
    super.dispose();
  }

  /// Les rubriques déjà ouvertes restent en mémoire : y revenir est instantané.
  FeedController _feedFor(int categoryId) => _feeds.putIfAbsent(
    '$categoryId',
    () => FeedController(
      _api,
      _store,
      categoryId: categoryId,
      cacheKey: 'cat:$categoryId',
    )..start(),
  );

  void _openRubrique(String slug) {
    if (AppConfig.navRubriques.contains(slug)) {
      setState(() => _tab = slug);
      return;
    }
    final category = context.read<JournalController>().bySlug(slug);
    if (category == null) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            RubriqueScreen(title: category.name, categoryId: category.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final journal = context.watch<JournalController>();
    final items = [
      (_une, 'À la une'),
      for (final slug in AppConfig.navRubriques)
        if (journal.bySlug(slug) case final c?) (slug, c.name),
    ];
    final category = _tab == _une ? null : journal.bySlug(_tab);

    final Widget body;
    if (category == null) {
      body = UneView(onRubrique: _openRubrique);
    } else {
      body = ChangeNotifierProvider.value(
        value: _feedFor(category.id),
        child: RubriqueView(title: category.name),
      );
    }

    return PopScope(
      canPop: _tab == _une,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _tab = _une);
      },
      child: Scaffold(
        key: _scaffold,
        drawer: JournalDrawer(onRubrique: _openRubrique),
        appBar: JournalTopBar(
          onMenu: () => _scaffold.currentState?.openDrawer(),
          onSearch: () => Navigator.of(
            context,
          ).push(MaterialPageRoute<void>(builder: (_) => const SearchScreen())),
        ),
        body: Column(
          children: [
            NavStrip(
              items: items,
              selected: category == null ? _une : _tab,
              onSelect: (key) => setState(() => _tab = key),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                switchInCurve: Curves.easeOut,
                child: KeyedSubtree(key: ValueKey(_tab), child: body),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
