import 'package:flutter/foundation.dart' show ChangeNotifier;

import '../config.dart';
import '../models/article.dart';
import '../models/category.dart';
import '../services/local_store.dart';
import '../services/wp_api.dart';

/// Rubriques du journal et blocs de rubrique de la une
/// (« Bien expliqué », « IA, encore! », « Pratique »).
class JournalController extends ChangeNotifier {
  JournalController(this._api, this._store);

  final WpApi _api;
  final LocalStore _store;

  static const sectionSize = 4;

  List<Category> _categories = const [];
  Map<String, List<Article>> _sections = const {};

  List<Category> get categories => _categories;

  /// Articles d'un bloc de la une, par slug de rubrique.
  List<Article> section(String slug) => _sections[slug] ?? const [];

  Category? bySlug(String slug) {
    for (final c in _categories) {
      if (c.slug == slug) return c;
    }
    return null;
  }

  /// Rubriques à lister dans le menu : celles qui ont des articles, ou des
  /// sous-rubriques qui en ont.
  List<Category> get rubriques {
    final parents = {
      for (final c in _categories)
        if (c.parent != 0 && c.count > 0) c.parent,
    };
    return [
      for (final c in _categories)
        if (c.parent == 0 && (c.count > 0 || parents.contains(c.id))) c,
    ];
  }

  Future<void> init() async {
    _categories = _store.loadCategories();
    _sections = {
      for (final slug in AppConfig.homeSections)
        slug: _store.loadList('section:$slug'),
    };
    notifyListeners();
    await refresh();
  }

  Future<void> refresh() async {
    try {
      _categories = await _api.fetchCategories();
      await _store.saveCategories(_categories);
    } on ApiException {
      // Les rubriques en cache restent utilisées.
    }
    final loaded = await Future.wait([
      for (final slug in AppConfig.homeSections) _loadSection(slug),
    ]);
    _sections = {
      for (final (slug, items) in loaded)
        slug: items ?? _sections[slug] ?? const [],
    };
    notifyListeners();
  }

  Future<(String, List<Article>?)> _loadSection(String slug) async {
    final category = bySlug(slug);
    if (category == null) return (slug, null);
    try {
      final page = await _api.fetchPosts(
        categoryId: category.id,
        perPage: sectionSize,
      );
      await _store.saveList('section:$slug', page.items);
      return (slug, page.items);
    } on ApiException {
      return (slug, null);
    }
  }
}
