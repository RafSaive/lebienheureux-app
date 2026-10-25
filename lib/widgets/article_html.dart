import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme.dart';

/// Contenu HTML d'un article ou d'une page, mis en forme comme sur le site.
/// En mode [sliver], le contenu est construit au fil du défilement, ce qui
/// garde les longs articles fluides.
class ArticleHtml extends StatelessWidget {
  const ArticleHtml(this.html, {super.key, this.sliver = false});

  final String html;
  final bool sliver;

  @override
  Widget build(BuildContext context) {
    return HtmlWidget(
      html,
      renderMode: sliver ? RenderMode.sliverList : RenderMode.column,
      textStyle: Typo.corps,
      customStylesBuilder: (element) => switch (element.localName) {
        'p' => const {'margin': '0 0 16px'},
        'h2' => const {
          'font-family': Fonts.titre,
          'font-weight': '600',
          'font-size': '24px',
          'line-height': '30px',
          'margin': '34px 0 12px',
        },
        'h3' || 'h4' => const {
          'font-family': Fonts.titre,
          'font-weight': '600',
          'font-size': '20px',
          'line-height': '26px',
          'margin': '26px 0 10px',
        },
        'a' => const {'color': '#A70003', 'text-decoration': 'none'},
        'strong' || 'b' => const {'font-weight': '600'},
        'li' => const {'margin': '0 0 8px'},
        'figure' => const {'margin': '20px 0'},
        'figcaption' => const {
          'font-family': Fonts.sans,
          'font-size': '12px',
          'line-height': '16px',
          'color': '#6A7282',
          'margin': '6px 0 0',
        },
        'blockquote' => const {
          'margin': '20px 0',
          'padding': '0 0 0 14px',
          'border-left': '3px solid #A70003',
          'font-style': 'italic',
        },
        'hr' => const {'border-top': '1px solid #D1D5DC', 'margin': '24px 0'},
        _ => null,
      },
      onTapUrl: openLink,
    );
  }
}

/// Liens d'articles : ouverts dans un navigateur intégré, sans quitter l'app.
Future<bool> openLink(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null) return Future.value(false);
  final web = uri.scheme == 'http' || uri.scheme == 'https';
  return launchUrl(
    uri,
    mode: web ? LaunchMode.inAppBrowserView : LaunchMode.externalApplication,
  );
}
