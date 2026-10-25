import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/article.dart';
import '../theme.dart';
import '../util/dates.dart';

/// « 🛰️ ACTUALITÉS • 25 OCTOBRE 2026 »
class Signe extends StatelessWidget {
  const Signe({super.key, required this.article, this.color = Palette.rouge});

  final Article article;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final style = Typo.signe.copyWith(color: color);
    return Text.rich(
      TextSpan(
        style: style,
        children: [
          if (article.mark.isNotEmpty)
            TextSpan(
              text: '${article.mark} ',
              style: const TextStyle(fontSize: 11),
            ),
          if (article.rubrique != null) ...[
            TextSpan(text: article.rubrique!.toUpperCase()),
            const TextSpan(text: '  •  '),
          ],
          TextSpan(text: signeDate(article.date)),
        ],
      ),
    );
  }
}

/// En-tête de bloc souligné de noir : « BIEN EXPLIQUÉ ……… TOUT VOIR › »
class Etiquette extends StatelessWidget {
  const Etiquette({super.key, required this.label, this.onToutVoir});

  final String label;
  final VoidCallback? onToutVoir;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 28, bottom: 14),
      padding: const EdgeInsets.only(bottom: 4),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Palette.encre)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(child: Text(label.toUpperCase(), style: Typo.etiquette)),
          if (onToutVoir != null)
            InkWell(
              onTap: onToutVoir,
              child: Text(
                'TOUT VOIR ›',
                style: Typo.etiquette.copyWith(fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}

/// Image d'article au format 3:2 du site. La place est réservée avant le
/// chargement (pas de saut de mise en page) et l'image est décodée à la
/// taille affichée, pour un défilement fluide.
class ArticleImage extends StatelessWidget {
  const ArticleImage({super.key, required this.url, this.semanticLabel = ''});

  final String? url;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final placeholder = const ColoredBox(color: Palette.papierCreux);
    return AspectRatio(
      aspectRatio: 3 / 2,
      child: url == null
          ? placeholder
          : LayoutBuilder(
              builder: (context, constraints) {
                final dpr = MediaQuery.devicePixelRatioOf(context);
                return CachedNetworkImage(
                  imageUrl: url!,
                  fit: BoxFit.cover,
                  memCacheWidth: (constraints.maxWidth * dpr).round(),
                  fadeInDuration: const Duration(milliseconds: 180),
                  placeholder: (_, _) => placeholder,
                  errorWidget: (_, _, _) => placeholder,
                  imageBuilder: (context, provider) => Semantics(
                    image: true,
                    label: semanticLabel,
                    child: Image(image: provider, fit: BoxFit.cover),
                  ),
                );
              },
            ),
    );
  }
}

/// Fine ligne grise entre deux articles.
class Filet extends StatelessWidget {
  const Filet({super.key, this.color = Palette.filet, this.margin = 14});

  final Color color;
  final double margin;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(vertical: margin),
    child: Divider(color: color, height: 1),
  );
}

/// Message centré avec le capybara (liste vide, hors-ligne, erreur…).
class CapybaraMessage extends StatelessWidget {
  const CapybaraMessage({
    super.key,
    required this.title,
    this.text,
    this.action,
    this.onAction,
  });

  final String title;
  final String? text;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 48, 32, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset('assets/brand/capybara.png', width: 96, height: 96),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Typo.titreCarte.copyWith(fontSize: 22),
          ),
          if (text != null) ...[
            const SizedBox(height: 8),
            Text(
              text!,
              textAlign: TextAlign.center,
              style: Typo.resume.copyWith(color: Palette.encreDoux),
            ),
          ],
          if (action != null) ...[
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: onAction,
              style: journalButtonStyle,
              child: Text(action!.toUpperCase()),
            ),
          ],
        ],
      ),
    );
  }
}

/// Bouton encadré de rouge, comme « ÉCOUTER L'ARTICLE » sur le site.
final journalButtonStyle = OutlinedButton.styleFrom(
  foregroundColor: Palette.rouge,
  side: const BorderSide(color: Palette.rouge),
  shape: const RoundedRectangleBorder(),
  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
  textStyle: const TextStyle(
    fontFamily: Fonts.sans,
    fontWeight: FontWeight.w700,
    fontSize: 12,
    letterSpacing: 0.6,
  ),
);
