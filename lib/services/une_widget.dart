import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';

/// Widget d'écran d'accueil « La une » (Android et iOS).
///
/// Le widget natif va chercher lui-même les derniers articles sur le site.
/// L'app lui demande seulement de se rafraîchir quand elle vient de charger
/// une nouvelle une, et ouvre l'article touché dans le widget.
abstract final class UneWidget {
  /// `kind` du widget WidgetKit (ios/UneWidget/UneWidget.swift).
  static const iOSKind = 'UneWidget';

  /// Classe du widget Android (UneWidgetProvider.kt).
  static const androidProvider =
      'be.lebienheureux.lebienheureux.UneWidgetProvider';

  static bool get _supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  static Future<void> refresh() async {
    if (!_supported) return;
    try {
      await HomeWidget.updateWidget(
        iOSName: iOSKind,
        qualifiedAndroidName: androidProvider,
      );
    } on PlatformException {
      // Aucun widget posé, ou plateforme sans widget : rien à faire.
    } on MissingPluginException {
      // Idem (tests, plateformes non prises en charge).
    }
  }

  /// Lien du widget qui a lancé l'app, s'il y en a un.
  static Future<Uri?> initialLaunch() async {
    if (!_supported) return null;
    try {
      return await HomeWidget.initiallyLaunchedFromHomeWidget();
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  /// Liens touchés dans le widget pendant que l'app est ouverte.
  static Stream<Uri?> get clicks =>
      _supported ? HomeWidget.widgetClicked : const Stream.empty();

  /// `lebienheureux://article/2028?homeWidget` → 2028
  static int? articleId(Uri? uri) {
    if (uri == null || uri.scheme != 'lebienheureux' || uri.host != 'article') {
      return null;
    }
    return int.tryParse(uri.pathSegments.isEmpty ? '' : uri.pathSegments.first);
  }
}
