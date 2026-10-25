import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/article.dart';
import '../state/favorites_controller.dart';

class ArticleScreen extends StatelessWidget {
  const ArticleScreen({super.key, required this.article});

  final Article article;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final favorites = context.watch<FavoritesController>();
    final isFavorite = favorites.contains(article.id);
    final date = DateFormat.yMMMMd('fr_FR').format(article.date.toLocal());
    final meta = [date, if (article.author != null) article.author!].join(' · ');

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            tooltip: isFavorite ? 'Retirer des favoris' : 'Ajouter aux favoris',
            icon: Icon(isFavorite ? Icons.bookmark : Icons.bookmark_border),
            onPressed: () => favorites.toggle(article),
          ),
          IconButton(
            tooltip: 'Partager',
            icon: const Icon(Icons.ios_share),
            onPressed: () => SharePlus.instance.share(
              ShareParams(text: '${article.title}\n${article.link}'),
            ),
          ),
          IconButton(
            tooltip: 'Ouvrir sur le site',
            icon: const Icon(Icons.open_in_browser),
            onPressed: () => _open(article.link),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            if (article.imageUrl != null)
              AspectRatio(
                aspectRatio: 16 / 9,
                child: CachedNetworkImage(
                  imageUrl: article.imageUrl!,
                  fit: BoxFit.cover,
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (article.categories.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        for (final name in article.categories)
                          Text(
                            name.toUpperCase(),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                            ),
                          ),
                      ],
                    ),
                  const SizedBox(height: 8),
                  Text(
                    article.title,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    meta,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Divider(height: 32),
                  HtmlWidget(
                    article.contentHtml,
                    textStyle: theme.textTheme.bodyLarge?.copyWith(
                      fontSize: 18,
                      height: 1.6,
                    ),
                    onTapUrl: _open,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Future<bool> _open(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return Future.value(false);
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
