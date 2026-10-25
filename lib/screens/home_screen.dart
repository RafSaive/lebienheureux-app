import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config.dart';
import '../state/articles_controller.dart';
import '../widgets/article_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _scroll = ScrollController();
  final _searchField = TextEditingController();
  Timer? _debounce;
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scroll.dispose();
    _searchField.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.extentAfter < 800) {
      context.read<ArticlesController>().loadMore();
    }
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      context.read<ArticlesController>().search(value);
    });
  }

  void _closeSearch() {
    _debounce?.cancel();
    _searchField.clear();
    setState(() => _searching = false);
    context.read<ArticlesController>().search('');
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ArticlesController>();

    return Scaffold(
      appBar: AppBar(
        title: _searching
            ? TextField(
                controller: _searchField,
                autofocus: true,
                textInputAction: TextInputAction.search,
                decoration: const InputDecoration(
                  hintText: 'Rechercher un article',
                  border: InputBorder.none,
                ),
                onChanged: _onQueryChanged,
                onSubmitted: (v) {
                  _debounce?.cancel();
                  c.search(v);
                },
              )
            : const Text(
                AppConfig.appName,
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
        actions: [
          IconButton(
            tooltip: _searching ? 'Fermer la recherche' : 'Rechercher',
            icon: Icon(_searching ? Icons.close : Icons.search),
            onPressed: _searching
                ? _closeSearch
                : () => setState(() => _searching = true),
          ),
        ],
        bottom: c.categories.isEmpty
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(52),
                child: _CategoryBar(controller: c),
              ),
      ),
      body: RefreshIndicator(
        onRefresh: c.refresh,
        child: _buildBody(c),
      ),
    );
  }

  Widget _buildBody(ArticlesController c) {
    if (c.articles.isEmpty) {
      if (c.loading) return const Center(child: CircularProgressIndicator());
      return _Message(
        icon: c.error != null ? Icons.cloud_off : Icons.article_outlined,
        text: c.error ??
            (c.query.isNotEmpty
                ? 'Aucun article ne correspond à « ${c.query} ».'
                : 'Aucun article pour le moment.'),
        onRetry: c.error != null ? c.refresh : null,
      );
    }

    final showFooter = c.loadingMore || c.offline;
    return ListView.separated(
      controller: _scroll,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: c.articles.length + (showFooter ? 1 : 0),
      separatorBuilder: (_, _) => const SizedBox(height: 16),
      itemBuilder: (context, i) {
        if (i < c.articles.length) return ArticleCard(article: c.articles[i]);
        if (c.offline) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Hors-ligne : articles enregistrés lors de la dernière visite.',
              textAlign: TextAlign.center,
            ),
          );
        }
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}

class _CategoryBar extends StatelessWidget {
  const _CategoryBar({required this.controller});

  final ArticlesController controller;

  @override
  Widget build(BuildContext context) {
    final categories = controller.categories;
    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        itemCount: categories.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final id = i == 0 ? null : categories[i - 1].id;
          final label = i == 0 ? 'À la une' : categories[i - 1].name;
          return ChoiceChip(
            label: Text(label),
            selected: controller.categoryId == id,
            onSelected: (_) => controller.selectCategory(id),
          );
        },
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text, this.onRetry});

  final IconData icon;
  final String text;
  final Future<void> Function()? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // ListView pour que le geste « tirer pour rafraîchir » reste possible.
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(32),
      children: [
        const SizedBox(height: 80),
        Icon(icon, size: 48, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(height: 12),
        Text(text, textAlign: TextAlign.center, style: theme.textTheme.bodyLarge),
        if (onRetry != null) ...[
          const SizedBox(height: 16),
          Center(
            child: FilledButton.tonal(
              onPressed: onRetry,
              child: const Text('Réessayer'),
            ),
          ),
        ],
      ],
    );
  }
}
