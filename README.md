# Le Bien Heureux — l'app

**L'essentiel geek, le temps d'une pause.** Application **Android et iOS** du journal [lebienheureux.be](https://lebienheureux.be), en **Flutter** (une seule base de code).

Gratuite, sans compte, sans abonnement, sans pub. Les articles viennent directement du site WordPress via son API publique : rien à installer ni à modifier côté site.

## Ce qu'on y trouve

**Le look du journal**
- Papier `#FAF8F3`, encre, rouge `#A70003`, filets : les couleurs du thème « lbnpapier » du site
- Manchette avec le capybara et le tampon « .be », bandeau des rubriques entre deux filets noirs
- Titres en Crimson Text, texte en Gelasio (l'équivalent libre de Georgia), signes en Open Sans
- Une calquée sur celle du site : grand article, titres, blocs « Bien expliqué », « IA, encore! », « Pratique », puis « Les jours précédents »

**Une lecture fluide**
- L'article s'ouvre instantanément (il arrive déjà complet avec la liste)
- On glisse vers l'article suivant ou précédent ; « Article suivant » en fin de lecture
- Barre de progression, taille du texte réglable (mémorisée)
- Images décodées à la taille d'écran, place réservée avant chargement : pas de saut
- « Écouter l'article » : lecture à voix haute par la synthèse vocale du téléphone

**Le reste**
- Rubriques (y compris les sous-rubriques de « Dossiers »), recherche dans tout le journal
- Favoris lisibles hors-ligne ; la dernière une reste disponible sans réseau
- Partage, pages « Le Bien Heureux ? », « À propos », « Mentions légales »
- **Widget « La une »** sur l'écran d'accueil (Android et iOS, plus l'écran verrouillé iOS) : il se met à jour seul et ouvre l'article touché
- Newsletter **gratuite** « Le Réveil du Bien Heureux » proposée en fin d'article — l'app ne parle jamais d'« abonnement »

## Structure

```
lib/
├── config.dart              # adresse du site, menu, blocs de la une
├── theme.dart               # couleurs, polices, styles du journal
├── main.dart                # démarrage, état partagé
├── models/                  # Article, Category, WpPage
├── services/
│   ├── wp_api.dart          # client de l'API WordPress
│   ├── local_store.dart     # favoris et caches hors-ligne
│   └── une_widget.dart      # lien avec le widget d'écran d'accueil
├── state/                   # une, rubriques, favoris, lecture vocale, préférences
├── screens/                 # accueil, rubriques, lecteur, recherche, favoris, pages, menu
└── widgets/                 # manchette, tuiles d'articles, contenu HTML…
android/…/UneWidgetProvider.kt, UneRepository.kt   # widget Android
ios/UneWidget/                                     # widget iOS (WidgetKit)
tool/add_ios_widget.rb                             # ajoute la cible du widget au projet Xcode
test/                        # tests Dart (API simulée, aucun accès réseau)
android/app/src/test/        # tests du widget Android (Robolectric)
```

## Développement

```bash
flutter pub get
flutter test                 # tests Dart
flutter run                  # sur un émulateur ou un téléphone branché

cd android && ./gradlew :app:testDebugUnitTest   # tests du widget Android
```

## Builds

La CI GitHub Actions (`.github/workflows/build.yml`) vérifie le format, analyse le code, lance tous les tests, puis produit :

- **Android** : un `.apk` à installer directement et un `.aab` pour Google Play, plus un aperçu du widget
- **iOS** : une build non signée de l'app et du widget (compilée sur macOS par GitHub)

## Publication sur les stores

| | Google Play | App Store |
|---|---|---|
| Compte | Google Play Console (25 $ une fois) | Apple Developer Program (99 $/an) |
| Identifiant | `be.lebienheureux.lebienheureux` | `be.lebienheureux.lebienheureux` (+ `.UneWidget`) |
| Signature | clé d'upload dans `android/key.properties` | certificat + profils (Xcode, signature automatique) |

`android/key.properties` (jamais versionné) :

```properties
storeFile=/chemin/vers/upload-keystore.jks
storePassword=…
keyAlias=upload
keyPassword=…
```

L'identifiant ne peut plus changer après la première publication : à valider avant.

## Licence

Code sous licence **MIT** — voir [`LICENSE`](LICENSE). Le nom « Le Bien Heureux », le logo capybara et les articles ne sont pas couverts par cette licence. Polices sous licence SIL OFL 1.1 (`assets/fonts/OFL-*.txt`).
