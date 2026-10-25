import 'package:flutter/foundation.dart' show ChangeNotifier;

import '../models/article.dart';
import '../services/local_store.dart';
import '../services/wp_api.dart';

/// Une liste d'articles paginée : la une, une rubrique ou une recherche.
/// Avec une [cacheKey], la première page est gardée pour s'afficher
/// immédiatement au prochain lancement et servir hors-ligne.
class FeedController extends ChangeNotifier {
  FeedController(this._api, this._store, {this.categoryId, this.cacheKey});

  final WpApi _api;
  final LocalStore _store;
  final int? categoryId;
  final String? cacheKey;

  List<Article> _articles = const [];
  String _query = '';
  int _page = 0;
  int _totalPages = 1;
  bool _loading = false;
  bool _loadingMore = false;
  bool _offline = false;
  bool _started = false;
  String? _error;

  // Incrémenté à chaque nouvelle requête de tête : une réponse arrivée après
  // un changement de recherche est ignorée.
  int _generation = 0;

  List<Article> get articles => _articles;
  String get query => _query;
  bool get loading => _loading;
  bool get loadingMore => _loadingMore;
  bool get offline => _offline;
  String? get error => _error;
  bool get hasMore => _page < _totalPages;
  bool get _cacheable => cacheKey != null && _query.isEmpty;

  /// Affiche le cache puis rafraîchit. Sans effet si déjà lancé.
  Future<void> start() {
    if (_started) return Future.value();
    _started = true;
    if (_cacheable) _articles = _store.loadList(cacheKey!);
    return refresh();
  }

  Future<void> refresh() async {
    final generation = ++_generation;
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _api.fetchPosts(
        page: 1,
        categoryId: categoryId,
        search: _query,
      );
      if (generation != _generation) return;
      _articles = result.items;
      _page = 1;
      _totalPages = result.totalPages;
      _offline = false;
      if (_cacheable) await _store.saveList(cacheKey!, result.items);
    } on ApiException catch (e) {
      if (generation != _generation) return;
      final cached = _cacheable
          ? _store.loadList(cacheKey!)
          : const <Article>[];
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
        categoryId: categoryId,
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

  Future<void> search(String query) {
    final q = query.trim();
    if (q == _query) return Future.value();
    _query = q;
    if (q.isEmpty) {
      _generation++;
      _articles = const [];
      _page = 0;
      _totalPages = 0;
      _error = null;
      _loading = false;
      notifyListeners();
      return Future.value();
    }
    return refresh();
  }
}
