/// Réglages à adapter si le site change d'adresse, de menu ou de rubriques.
abstract final class AppConfig {
  static const appName = 'Le Bien Heureux';
  static const tagline = 'L’essentiel geek, le temps d’une pause.';

  /// Adresse du site WordPress (sans slash final).
  static const siteUrl = 'https://lebienheureux.be';

  /// Racine de l'API REST WordPress.
  static const apiRoot = '$siteUrl/wp-json/wp/v2';

  /// Nombre d'articles chargés par page.
  static const perPage = 10;

  /// Rubriques du bandeau de navigation (slugs WordPress), comme le menu du site.
  static const navRubriques = [
    'actualites',
    'bien-explique',
    'pratique',
    'dossiers',
  ];

  /// Blocs de rubrique affichés sur la une, dans l'ordre du site.
  static const homeSections = ['bien-explique', 'ia-encore', 'pratique'];

  /// Pages du site lisibles dans l'app (slug, titre).
  static const pages = [
    ('le-bien-heureux', 'Le Bien Heureux ?'),
    ('a-propos', 'À propos'),
    ('mentions-legales', 'Mentions légales'),
  ];

  /// Le formulaire de contact reste sur le site.
  static const contactUrl = '$siteUrl/contact/';

  /// Ancre du formulaire d'inscription à la newsletter gratuite, présent
  /// sous chaque article du site. Dans l'app, on ne parle jamais d'« abonnement ».
  static const newsletterAnchor = '#mp_form_below_posts1';
}
