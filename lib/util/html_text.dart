/// Entités HTML nommées les plus courantes dans les textes WordPress en français.
const _named = <String, String>{
  'amp': '&',
  'lt': '<',
  'gt': '>',
  'quot': '"',
  'apos': "'",
  'nbsp': ' ',
  'hellip': '…',
  'ndash': '–',
  'mdash': '—',
  'lsquo': '‘',
  'rsquo': '’',
  'ldquo': '“',
  'rdquo': '”',
  'laquo': '«',
  'raquo': '»',
  'rsaquo': '›',
  'euro': '€',
  'copy': '©',
  'reg': '®',
  'deg': '°',
  'oelig': 'œ',
  'OElig': 'Œ',
  'agrave': 'à',
  'aacute': 'á',
  'acirc': 'â',
  'auml': 'ä',
  'ccedil': 'ç',
  'Ccedil': 'Ç',
  'egrave': 'è',
  'eacute': 'é',
  'ecirc': 'ê',
  'euml': 'ë',
  'Eacute': 'É',
  'Egrave': 'È',
  'Agrave': 'À',
  'igrave': 'ì',
  'iacute': 'í',
  'icirc': 'î',
  'iuml': 'ï',
  'ocirc': 'ô',
  'ouml': 'ö',
  'ugrave': 'ù',
  'ucirc': 'û',
  'uuml': 'ü',
};

final _entity = RegExp(r'&(#x[0-9a-fA-F]+|#[0-9]+|[a-zA-Z][a-zA-Z0-9]*);');
final _tag = RegExp(r'<[^>]*>');
final _spaces = RegExp(r'\s+');
final _blockEnd = RegExp(
  r'</(p|h[1-6]|li|blockquote|figcaption)>|<br\s*/?>',
  caseSensitive: false,
);

/// Pictogramme placé en tête des titres du journal (« 🛰️ Starlink… »).
final _leadingMark = RegExp(r'^\s*([^\p{L}\p{N}\p{P}\s]+)\s+', unicode: true);

/// Remplace les entités HTML (`&#8217;`, `&eacute;`, `&amp;`…) par leur caractère.
String decodeEntities(String input) {
  return input.replaceAllMapped(_entity, (m) {
    final body = m.group(1)!;
    if (body.startsWith('#x') || body.startsWith('#X')) {
      final code = int.tryParse(body.substring(2), radix: 16);
      return code == null ? m.group(0)! : String.fromCharCode(code);
    }
    if (body.startsWith('#')) {
      final code = int.tryParse(body.substring(1));
      return code == null ? m.group(0)! : String.fromCharCode(code);
    }
    return _named[body] ?? m.group(0)!;
  });
}

/// Retire les balises, décode les entités et compacte les espaces.
String htmlToPlainText(String html) {
  return decodeEntities(html.replaceAll(_tag, ' '))
      .replaceAll(_spaces, ' ')
      .trim();
}

/// Découpe un contenu HTML en paragraphes de texte brut (pour la lecture à voix haute).
List<String> htmlToParagraphs(String html) {
  return html
      .split(_blockEnd)
      .map(htmlToPlainText)
      .where((p) => p.isNotEmpty)
      .toList();
}

/// Sépare le pictogramme de tête d'un titre : `('🛰️', 'Starlink…')`.
(String, String) splitLeadingMark(String title) {
  final m = _leadingMark.firstMatch(title);
  if (m == null) return ('', title.trim());
  return (m.group(1)!, title.substring(m.end).trim());
}
