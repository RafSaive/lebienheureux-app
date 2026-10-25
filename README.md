# Le Bienheureux — application mobile

Application **Android et iOS** du journal [lebienheureux.be](https://lebienheureux.be), écrite en **Flutter** (une seule base de code pour les deux plateformes).

Les articles viennent directement du site WordPress via son API REST publique (`/wp-json/wp/v2`) : rien à installer ni à modifier côté site.

## Fonctionnalités

- **À la une** : derniers articles, chargement continu en faisant défiler
- **Rubriques** : filtre par catégorie WordPress
- **Recherche** dans tous les articles
- **Lecture** de l'article avec image, rubrique, date et auteur
- **Favoris** enregistrés sur le téléphone et lisibles **hors-ligne**
- **Hors-ligne** : la dernière une consultée reste affichée sans connexion
- **Partage** et ouverture de l'article sur le site
- Thème clair / sombre suivant le réglage du téléphone

## Structure

```
lib/
├── config.dart              # adresse du site, nom de l'app
├── theme.dart               # couleurs et styles
├── main.dart                # démarrage + barre de navigation
├── models/                  # Article, Category
├── services/
│   ├── wp_api.dart          # client de l'API WordPress
│   └── local_store.dart     # favoris et cache hors-ligne
├── state/                   # logique des écrans (pagination, filtres…)
├── screens/                 # Accueil, Article, Favoris
└── widgets/                 # carte d'article
test/                        # tests (API simulée, aucun accès réseau)
```

## Développement

```bash
flutter pub get
flutter test             # tests
flutter run              # sur un émulateur ou un téléphone branché
```

## Builds

La CI GitHub Actions (`.github/workflows/build.yml`) lance les tests puis produit :

- **Android** : un `.apk` installable, à télécharger dans l'onglet *Actions* → *Artifacts*
- **iOS** : une build non signée (compilée sur macOS par GitHub)

## Publication sur les stores

| | Google Play | App Store |
|---|---|---|
| Compte | Google Play Console (25 $ une fois) | Apple Developer Program (99 $/an) |
| Identifiant | `be.lebienheureux.lebienheureux` | `be.lebienheureux.lebienheureux` |
| Signature | clé d'upload Android | certificat + profil Apple |

L'identifiant ne peut plus changer après la première publication : à valider avant.

## Licence

Code propriétaire — tous droits réservés.
