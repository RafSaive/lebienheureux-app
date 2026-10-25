/// Réglages à adapter si le site change d'adresse ou de nom.
abstract final class AppConfig {
  /// Nom affiché dans l'app.
  static const appName = 'Le Bienheureux';

  /// Adresse du site WordPress (sans slash final).
  static const siteUrl = 'https://lebienheureux.be';

  /// Racine de l'API REST WordPress.
  static const apiRoot = '$siteUrl/wp-json/wp/v2';

  /// Nombre d'articles chargés par page.
  static const perPage = 15;
}
