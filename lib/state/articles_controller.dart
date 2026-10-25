import 'package:flutter/foundation.dart' show ChangeNotifier;

import '../models/article.dart';
import '../models/category.dart';
import '../services/local_store.dart';
import '../services/wp_api.dart';

/// Liste d'articles de l'accueil : pagination, filtre par rubrique, recherche,
/// et repli sur le cache local quand le réseau manque.
class ArticlesController extends ChangeNotifier {
  ArticlesController(this._api, this._store);

  final WpApi _api;
  final LocalStore _store;

  List<Article> _articles = const [];
  List<Category> _categories = const [];
  int? _categoryId;
  String _query = '';
  int _page = 0;
  int _totalPages = 1;
  bool _loading = false;
  bool _loadingMore = false;
  bool _offline = false;
  String? _error;

  // Incrémenté à chaque nouvelle requête de tête : une réponse arrivée après
  // un changement de filtre est ignorée.
  int _generation = 0;

  List<Article> get articles => _articles;
  List<Category> get categories => _categories;
  int? get categoryId => _categoryId;
  String get query => _query;
  bool get loading => _loading;
  bool get loadingMore => _loadingMore;
  bool get offline => _offline;
  String? get error => _error;
  bool get hasMore => _page < _totalPages;
  bool get _isUnfiltered => _categoryId == null && _query.isEmpty;

  Future<void> init() async {
    _categories = _store.loadCategories();
    _articles = _store.loadHome();
    notifyListeners();
    await Future.wait([refresh(), _loadCategories()]);
  }

  Future<void> refresh() async {
    final generation = ++_generation;
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _api.fetchPosts(
        page: 1,
        categoryId: _categoryId,
        search: _query,
      );
      if (generation != _generation) return;
      _articles = result.items;
      _page = 1;
      _totalPages = result.totalPages;
      _offline = false;
      if (_isUnfiltered) await _store.saveHome(result.items);
    } on ApiException catch (e) {
      if (generation != _generation) return;
      final cached = _isUnfiltered ? _store.loadHome() : const <Article>[];
      _articles = cached;
      _page = 0;
      _totalPages = 0;
      _offline = cached.isNotEmpty;
      _error = cached.isEmpty ? e.message : null;
    } finally {
      if (generation == _generation) {
        _loading = false;
        notifyListeners();
      }
    }
  }

  Future<void> loadMore() async {
    if (_loading || _loadingMore || !hasMore) return;
    final generation = _generation;
    _loadingMore = true;
    notifyListeners();

    try {
      final result = await _api.fetchPosts(
        page: _page + 1,
        categoryId: _categoryId,
        search: _query,
      );
      if (generation != _generation) return;
      final known = _articles.map((a) => a.id).toSet();
      _articles = [
        ..._articles,
        ...result.items.where((a) => !known.contains(a.id)),
      ];
      _page += 1;
      _totalPages = result.totalPages;
    } on ApiException {
      // On garde ce qui est déjà affiché ; un nouveau défilement réessaiera.
    } finally {
      if (generation == _generation) {
        _loadingMore = false;
        notifyListeners();
      }
    }
  }

  Future<void> selectCategory(int? id) {
    if (id == _categoryId) return Future.value();
    _categoryId = id;
    return refresh();
  }

  Future<void> search(String query) {
    final q = query.trim();
    if (q == _query) return Future.value();
    _query = q;
    return refresh();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _api.fetchCategories();
      _categories = categories;
      await _store.saveCategories(categories);
      notifyListeners();
    } on ApiException {
      // Les rubriques en cache (ou aucune) restent affichées.
    }
  }
}
