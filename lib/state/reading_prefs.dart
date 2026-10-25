import 'package:flutter/foundation.dart' show ChangeNotifier;
import 'package:shared_preferences/shared_preferences.dart';

/// Préférences de lecture mémorisées sur l'appareil.
class ReadingPrefs extends ChangeNotifier {
  ReadingPrefs(this._prefs)
    : _textScale = _prefs.getDouble(_textScaleKey) ?? 1.0;

  final SharedPreferences _prefs;
  double _textScale;

  static const _textScaleKey = 'text_scale';
  static const scales = [0.9, 1.0, 1.15, 1.3];

  /// Multiplie la taille de texte réglée sur le téléphone.
  double get textScale => _textScale;

  Future<void> setTextScale(double value) {
    _textScale = value;
    notifyListeners();
    return _prefs.setDouble(_textScaleKey, value);
  }
}
