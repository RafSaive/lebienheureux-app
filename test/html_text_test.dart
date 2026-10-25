import 'package:flutter_test/flutter_test.dart';
import 'package:lebienheureux/util/html_text.dart';

void main() {
  test('décode les entités numériques, hexadécimales et nommées', () {
    expect(decodeEntities('L&#8217;&eacute;t&eacute; &amp; l&#x2019;hiver'),
        'L’été & l’hiver');
  });

  test('laisse intactes les entités inconnues', () {
    expect(decodeEntities('&inconnu; &#xZZ;'), '&inconnu; &#xZZ;');
  });

  test('convertit un extrait HTML en texte brut', () {
    expect(
      htmlToPlainText('<p>Un <em>beau</em>\n jour&hellip;</p>\n'),
      'Un beau jour…',
    );
  });
}
