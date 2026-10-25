import 'package:flutter/material.dart';

import '../models/article.dart';
import '../screens/article_reader.dart';
import '../theme.dart';
import 'journal_bits.dart';

/// Ouvre un article ; on peut ensuite glisser vers les articles voisins de [list].
void openArticle(BuildContext context, List<Article> list, Article article) {
  final index = list.indexWhere((a) => a.id == article.id);
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => ArticleReader(
        articles: index < 0 ? [article] : list,
        initialIndex: index < 0 ? 0 : index,
      ),
    ),
  );
}

class _Tap extends StatelessWidget {
  const _Tap({required this.list, required this.article, required this.child});

  final List<Article> list;
  final Article article;
  final Widget child;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => openArticle(context, list, article),
    splashColor: Palette.papierCreux,
    highlightColor: Palette.papierCreux.withValues(alpha: 0.5),
    child: child,
  );
}

/// L'article de une : grande photo, crédit, titre, signe et chapô.
class UneTile extends StatelessWidget {
  const UneTile({super.key, required this.article, required this.list});

  final Article article;
  final List<Article> list;

  @override
  Widget build(BuildContext context) {
    return _Tap(
      list: list,
      article: article,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ArticleImage(url: article.imageUrl, semanticLabel: article.imageAlt),
          if (article.imageCredit.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                article.imageCredit,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Typo.credit,
              ),
            ),
          const SizedBox(height: 12),
          Text(article.title, style: Typo.titreUne),
          const SizedBox(height: 8),
          Signe(article: article),
          if (article.excerpt.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(article.excerpt, style: Typo.resume.copyWith(fontSize: 16.5)),
          ],
        ],
      ),
    );
  }
}

/// Titre + signe, avec le chapô si [resume].
class TitreTile extends StatelessWidget {
  const TitreTile({
    super.key,
    required this.article,
    required this.list,
    this.resume = false,
  });

  final Article article;
  final List<Article> list;
  final bool resume;

  @override
  Widget build(BuildContext context) {
    return _Tap(
      list: list,
      article: article,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(article.title, style: Typo.titreCarte),
          const SizedBox(height: 6),
          Signe(article: article),
          if (resume && article.excerpt.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              article.excerpt,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: Typo.resume,
            ),
          ],
        ],
      ),
    );
  }
}

/// Photo puis titre et signe : premier article des blocs de rubrique,
/// « Les jours précédents », favoris.
class PhotoTile extends StatelessWidget {
  const PhotoTile({super.key, required this.article, required this.list});

  final Article article;
  final List<Article> list;

  @override
  Widget build(BuildContext context) {
    return _Tap(
      list: list,
      article: article,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ArticleImage(url: article.thumbUrl, semanticLabel: article.imageAlt),
          const SizedBox(height: 10),
          Text(article.title, style: Typo.titreCarte),
          const SizedBox(height: 6),
          Signe(article: article),
        ],
      ),
    );
  }
}

/// Carte des pages de rubrique : photo pleine largeur, titre en blanc sur
/// un dégradé sombre.
class OverlayTile extends StatelessWidget {
  const OverlayTile({super.key, required this.article, required this.list});

  final Article article;
  final List<Article> list;

  @override
  Widget build(BuildContext context) {
    return _Tap(
      list: list,
      article: article,
      child: Stack(
        children: [
          ArticleImage(url: article.thumbUrl, semanticLabel: article.imageAlt),
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.25, 1],
                  colors: [Color(0x00000000), Color(0xE6000000)],
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 14,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  article.title,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Typo.titreCarte.copyWith(
                    color: Colors.white,
                    fontSize: 21,
                  ),
                ),
                const SizedBox(height: 6),
                Signe(article: article, color: const Color(0xFFE5E7EB)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
