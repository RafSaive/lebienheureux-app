import 'package:flutter/material.dart';

/// Couleurs relevées sur lebienheureux.be (thème « lbnpapier »).
abstract final class Palette {
  static const papier = Color(0xFFFAF8F3);
  static const papierCreux = Color(0xFFF0EDE5);
  static const encre = Color(0xFF000000);
  static const encrePale = Color(0xFF6A7282);
  static const encreDoux = Color(0xFF1E2939);
  static const titre = Color(0xFF101828);
  static const filet = Color(0xFFD1D5DC);
  static const filetMoyen = Color(0xFFA1A1A1);
  static const rouge = Color(0xFFA70003);
  static const jaune = Color(0xFFF1C400);
}

/// Familles déclarées dans pubspec.yaml.
abstract final class Fonts {
  static const manchette = 'Baskervville';
  static const titre = 'CrimsonText';
  static const sans = 'OpenSans';
  static const texte = 'Gelasio';
  static const tampon = 'ArchivoNarrow';
}

/// Styles de texte du journal, repris des feuilles de style du site.
abstract final class Typo {
  /// « 🛰️ ACTUALITÉS • 25 OCTOBRE 2026 »
  static const signe = TextStyle(
    fontFamily: Fonts.sans,
    fontSize: 12,
    height: 16 / 12,
    color: Palette.rouge,
  );

  static const titreUne = TextStyle(
    fontFamily: Fonts.titre,
    fontSize: 25,
    height: 1.2,
    fontWeight: FontWeight.w600,
    color: Palette.titre,
  );

  static const titreCarte = TextStyle(
    fontFamily: Fonts.titre,
    fontSize: 20,
    height: 1.25,
    fontWeight: FontWeight.w600,
    color: Palette.titre,
  );

  static const resume = TextStyle(
    fontFamily: Fonts.texte,
    fontSize: 15,
    height: 1.45,
    color: Palette.encre,
  );

  static const credit = TextStyle(
    fontFamily: Fonts.sans,
    fontSize: 12,
    height: 16 / 12,
    letterSpacing: 0.24,
    color: Palette.encrePale,
  );

  /// En-têtes de bloc : « BIEN EXPLIQUÉ ……… TOUT VOIR › »
  static const etiquette = TextStyle(
    fontFamily: Fonts.sans,
    fontSize: 14.4,
    height: 20.57 / 14.4,
    letterSpacing: 0.36,
    color: Palette.encre,
  );

  static const nav = TextStyle(
    fontFamily: Fonts.sans,
    fontSize: 13,
    letterSpacing: 1.3,
    color: Palette.encre,
  );

  /// Corps des articles : Georgia 18/28 sur le site, Gelasio ici.
  static const corps = TextStyle(
    fontFamily: Fonts.texte,
    fontSize: 18,
    height: 28 / 18,
    color: Palette.encre,
  );

  static const titreArticle = TextStyle(
    fontFamily: Fonts.titre,
    fontSize: 31,
    height: 34 / 30,
    color: Palette.encre,
  );

  static const chapo = TextStyle(
    fontFamily: Fonts.titre,
    fontStyle: FontStyle.italic,
    fontSize: 21,
    height: 1.5,
    color: Palette.encreDoux,
  );
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: Palette.rouge,
    primary: Palette.rouge,
    surface: Palette.papier,
    onSurface: Palette.encre,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: Palette.papier,
    fontFamily: Fonts.sans,
    appBarTheme: const AppBarTheme(
      backgroundColor: Palette.papier,
      foregroundColor: Palette.encre,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
    ),
    drawerTheme: const DrawerThemeData(
      backgroundColor: Palette.papier,
      shape: RoundedRectangleBorder(),
    ),
    dividerTheme: const DividerThemeData(
      color: Palette.filet,
      thickness: 1,
      space: 1,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: Palette.rouge,
    ),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: Palette.rouge,
      selectionHandleColor: Palette.rouge,
    ),
  );
}
