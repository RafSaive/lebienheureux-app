import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../config.dart';
import '../models/article.dart';
import '../state/favorites_controller.dart';
import '../state/reading_prefs.dart';
import '../state/speech_controller.dart';
import '../theme.dart';
import '../util/dates.dart';
import '../widgets/article_html.dart';
import '../widgets/journal_bits.dart';
import '../widgets/manchette.dart';

/// Lecture d'articles : on glisse latéralement vers l'article suivant ou
/// précédent de la liste d'où l'on vient.
class ArticleReader extends StatefulWidget {
  const ArticleReader({
    super.key,
    required this.articles,
    this.initialIndex = 0,
  });

  final List<Article> articles;
  final int initialIndex;

  @override
  State<ArticleReader> createState() => _ArticleReaderState();
}

class _ArticleReaderState extends State<ArticleReader> {
  late final PageController _pages = PageController(
    initialPage: widget.initialIndex,
  );
  late int _index = widget.initialIndex;
  late final SpeechController _speech;

  Article get _current => widget.articles[_index];

  @override
  void initState() {
    super.initState();
    _speech = context.read<SpeechController>();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _precacheAround(_index);
  }

  @override
  void dispose() {
    _speech.stop();
    _pages.dispose();
    super.dispose();
  }

  /// Télécharge à l'avance les images des articles voisins.
  void _precacheAround(int index) {
    for (final i in [index - 1, index + 1]) {
      if (i < 0 || i >= widget.articles.length) continue;
      final url = widget.articles[i].imageUrl;
      if (url != null) {
        precacheImage(CachedNetworkImageProvider(url), context).ignore();
      }
    }
  }

  void _goTo(int index) => _pages.animateToPage(
    index,
    duration: const Duration(milliseconds: 320),
    curve: Curves.easeOutCubic,
  );

  @override
  Widget build(BuildContext context) {
    final favorites = context.watch<FavoritesController>();
    final saved = favorites.contains(_current.id);

    return Scaffold(
      appBar: AppBar(
        title: const Manchette(size: 21, logo: false),
        shape: const Border(bottom: BorderSide(color: Palette.filet)),
        actions: [
          IconButton(
            tooltip: 'Taille du texte',
            icon: const Icon(Icons.text_fields),
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              backgroundColor: Palette.papier,
              shape: const RoundedRectangleBorder(),
              builder: (_) => const _TextSizeSheet(),
            ),
          ),
          IconButton(
            tooltip: saved
                ? 'Retirer des favoris'
                : 'Garder pour la prochaine pause',
            icon: Icon(saved ? Icons.bookmark : Icons.bookmark_border),
            color: saved ? Palette.rouge : null,
            onPressed: () {
              HapticFeedback.lightImpact();
              favorites.toggle(_current);
            },
          ),
          IconButton(
            tooltip: 'Partager',
            icon: const Icon(Icons.ios_share),
            onPressed: () => SharePlus.instance.share(
              ShareParams(
                subject: _current.title,
                text:
                    'Lu sur ${AppConfig.appName} : ${_current.title}\n${_current.link}',
              ),
            ),
          ),
        ],
      ),
      body: PageView.builder(
        controller: _pages,
        itemCount: widget.articles.length,
        onPageChanged: (i) {
          _speech.stop();
          setState(() => _index = i);
          _precacheAround(i);
        },
        itemBuilder: (context, i) => ArticleView(
          key: ValueKey(widget.articles[i].id),
          article: widget.articles[i],
          next: i + 1 < widget.articles.length ? widget.articles[i + 1] : null,
          onNext: () => _goTo(i + 1),
        ),
      ),
    );
  }
}

class ArticleView extends StatefulWidget {
  const ArticleView({super.key, required this.article, this.next, this.onNext});

  final Article article;
  final Article? next;
  final VoidCallback? onNext;

  @override
  State<ArticleView> createState() => _ArticleViewState();
}

class _ArticleViewState extends State<ArticleView> {
  final _scroll = ScrollController();
  final _progress = ValueNotifier<double>(0);

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      final max = _scroll.position.maxScrollExtent;
      _progress.value = max <= 0 ? 0 : (_scroll.offset / max).clamp(0, 1);
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.article;
    final width = MediaQuery.sizeOf(context).width;
    // Colonne de lecture limitée à ~680 px sur tablette.
    final side = math.max(20.0, (width - 680) / 2);
    // Taille choisie dans l'app, en plus du réglage du téléphone.
    final scale = context.watch<ReadingPrefs>().textScale;
    final system = MediaQuery.textScalerOf(context);

    return Stack(
      children: [
        MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(system.scale(18) / 18 * scale),
          ),
          child: Scrollbar(
            controller: _scroll,
            child: CustomScrollView(
              controller: _scroll,
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(side, 22, side, 0),
                  sliver: SliverToBoxAdapter(child: _Header(article: a)),
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(side, 24, side, 0),
                  sliver: ArticleHtml(a.contentHtml, sliver: true),
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(side, 8, side, 48),
                  sliver: SliverToBoxAdapter(
                    child: _Footer(
                      article: a,
                      next: widget.next,
                      onNext: widget.onNext,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: ValueListenableBuilder<double>(
            valueListenable: _progress,
            builder: (_, value, _) => LinearProgressIndicator(
              value: value,
              minHeight: 2,
              backgroundColor: Colors.transparent,
              color: Palette.rouge,
            ),
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.article});

  final Article article;

  @override
  Widget build(BuildContext context) {
    final a = article;
    final kicker = Typo.etiquette.copyWith(color: Palette.rouge);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text.rich(
          TextSpan(
            style: kicker,
            children: [
              if (a.mark.isNotEmpty) TextSpan(text: '${a.mark}  '),
              TextSpan(text: (a.rubrique ?? AppConfig.appName).toUpperCase()),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${kickerDate(a.date)}  ·  ≈ ${a.readingMinutes} MIN DE LECTURE',
          style: Typo.etiquette.copyWith(
            color: Palette.encrePale,
            fontSize: 12.5,
          ),
        ),
        const SizedBox(height: 14),
        Text(a.title, style: Typo.titreArticle),
        const Filet(margin: 16),
        if (a.excerpt.isNotEmpty) ...[
          Text(a.excerpt, style: Typo.chapo),
          const SizedBox(height: 18),
        ],
        Align(
          alignment: Alignment.centerLeft,
          child: Consumer<SpeechController>(
            builder: (context, speech, _) {
              final playing = speech.isPlaying(a.id);
              return OutlinedButton.icon(
                style: journalButtonStyle,
                onPressed: () => speech.toggle(a),
                icon: Icon(
                  playing ? Icons.stop_rounded : Icons.play_arrow_rounded,
                  size: 18,
                ),
                label: Text(
                  playing ? 'ARRÊTER LA LECTURE' : 'ÉCOUTER L\'ARTICLE',
                ),
              );
            },
          ),
        ),
        if (a.imageUrl != null) ...[
          const SizedBox(height: 22),
          ArticleImage(url: a.imageUrl, semanticLabel: a.imageAlt),
          if (a.imageCredit.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(a.imageCredit, style: Typo.credit),
            ),
        ],
      ],
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.article, this.next, this.onNext});

  final Article article;
  final Article? next;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Filet(color: Palette.encre, margin: 20),
        Text(
          'Fin de l’article. Bonne fin de pause !',
          textAlign: TextAlign.center,
          style: Typo.chapo.copyWith(fontSize: 18),
        ),
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: () => openLink(article.link),
            style: TextButton.styleFrom(foregroundColor: Palette.encrePale),
            child: Text(
              'LIRE SUR LEBIENHEUREUX.BE ›',
              style: Typo.etiquette.copyWith(
                fontSize: 12,
                color: Palette.encrePale,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _NewsletterCard(articleLink: article.link),
        if (next != null) ...[
          const SizedBox(height: 12),
          InkWell(
            onTap: onNext,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Palette.papierCreux,
                border: Border.all(color: Palette.filet),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ARTICLE SUIVANT ›',
                    style: Typo.etiquette.copyWith(
                      fontSize: 12,
                      color: Palette.rouge,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(next!.title, style: Typo.titreCarte),
                  const SizedBox(height: 4),
                  Text('ou glissez vers la gauche', style: Typo.credit),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _TextSizeSheet extends StatelessWidget {
  const _TextSizeSheet();

  @override
  Widget build(BuildContext context) {
    final prefs = context.watch<ReadingPrefs>();
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Etiquette(label: 'Taille du texte'),
            Row(
              children: [
                for (final s in ReadingPrefs.scales)
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        prefs.setTextScale(s);
                      },
                      child: Container(
                        height: 64,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: prefs.textScale == s
                                ? Palette.rouge
                                : Palette.filet,
                          ),
                        ),
                        child: Text(
                          'Aa',
                          textScaler: TextScaler.noScaling,
                          style: Typo.corps.copyWith(
                            fontSize: 18 * s,
                            color: prefs.textScale == s
                                ? Palette.rouge
                                : Palette.encre,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// La newsletter du matin. Toujours présentée comme gratuite, jamais comme
/// un « abonnement », pour qu'on ne la confonde pas avec un service payant.
class _NewsletterCard extends StatelessWidget {
  const _NewsletterCard({required this.articleLink});

  final String articleLink;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(border: Border.all(color: Palette.encre)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'NEWSLETTER GRATUITE',
            style: Typo.etiquette.copyWith(fontSize: 12, color: Palette.rouge),
          ),
          const SizedBox(height: 4),
          Text('☀️ Le Réveil du Bien Heureux', style: Typo.titreCarte),
          const SizedBox(height: 6),
          Text(
            'Chaque matin à 7 h, les nouveaux articles dans votre boîte mail. '
            'Gratuit, désinscription en un clic.',
            style: Typo.resume,
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            style: journalButtonStyle,
            onPressed: () =>
                openLink('$articleLink${AppConfig.newsletterAnchor}'),
            child: const Text('M’INSCRIRE — C’EST GRATUIT'),
          ),
        ],
      ),
    );
  }
}
