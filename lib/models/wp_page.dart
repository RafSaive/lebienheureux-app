import '../util/html_text.dart';

/// Page statique du site (« À propos », « Mentions légales »…).
class WpPage {
  const WpPage({
    required this.title,
    required this.contentHtml,
    required this.link,
  });

  final String title;
  final String contentHtml;
  final String link;

  factory WpPage.fromWp(Map<String, dynamic> json) => WpPage(
    title: htmlToPlainText(
      (json['title'] as Map?)?['rendered'] as String? ?? '',
    ),
    contentHtml: (json['content'] as Map?)?['rendered'] as String? ?? '',
    link: json['link'] as String? ?? '',
  );
}
