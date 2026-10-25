import 'package:flutter/foundation.dart';

import '../models/article.dart';
import '../services/local_store.dart';

/// Articles mis de côté, enregistrés en entier pour être lus hors-ligne.
class FavoritesController extends ChangeNotifier {
  FavoritesController(this._store) : _items = _store.loadFavorites();

  final LocalStore _store;
  List<Article> _items;

  List<Article> get items => _items;

  bool contains(int id) => _items.any((a) => a.id == id);

  Future<void> toggle(Article article) {
    _items = contains(article.id)
        ? _items.where((a) => a.id != article.id).toList()
        : [article, ..._items];
    notifyListeners();
    return _store.saveFavorites(_items);
  }
}
