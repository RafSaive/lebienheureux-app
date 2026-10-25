import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/article.dart';
import '../models/category.dart';

/// Persistance locale : favoris (lisibles hors-ligne) et cache de la une.
class LocalStore {
  LocalStore(this._prefs);

  final SharedPreferences _prefs;

  static const _favoritesKey = 'favorites';
  static const _homeKey = 'home_cache';
  static const _categoriesKey = 'categories_cache';

  List<Article> loadFavorites() => _readArticles(_favoritesKey);

  Future<void> saveFavorites(List<Article> articles) =>
      _writeArticles(_favoritesKey, articles);

  List<Article> loadHome() => _readArticles(_homeKey);

  Future<void> saveHome(List<Article> articles) =>
      _writeArticles(_homeKey, articles);

  List<Category> loadCategories() {
    final raw = _prefs.getString(_categoriesKey);
    if (raw == null) return const [];
    try {
      return (jsonDecode(raw) as List)
          .cast<Map<String, dynamic>>()
          .map(Category.fromJson)
          .toList();
    } on FormatException {
      return const [];
    }
  }

  Future<void> saveCategories(List<Category> categories) => _prefs.setString(
        _categoriesKey,
        jsonEncode(categories.map((c) => c.toJson()).toList()),
      );

  List<Article> _readArticles(String key) {
    final raw = _prefs.getString(key);
    if (raw == null) return const [];
    try {
      return (jsonDecode(raw) as List)
          .cast<Map<String, dynamic>>()
          .map(Article.fromJson)
          .toList();
    } on FormatException {
      return const [];
    }
  }

  Future<void> _writeArticles(String key, List<Article> articles) =>
      _prefs.setString(
        key,
        jsonEncode(articles.map((a) => a.toJson()).toList()),
      );
}
