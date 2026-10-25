import 'package:flutter_test/flutter_test.dart';
import 'package:lebienheureux/util/html_text.dart';

void main() {
  test('décode les entités numériques, hexadécimales et nommées', () {
    expect(
      decodeEntities('L&#8217;&eacute;t&eacute; &amp; l&#x2019;hiver'),
      'L’été & l’hiver',
    );
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

  test('découpe le contenu en paragraphes', () {
    expect(
      htmlToParagraphs('<p>Un.</p><h2>Deux</h2><ul><li>Trois</li></ul><p></p>'),
      ['Un.', 'Deux', 'Trois'],
    );
  });

  group('pictogramme de tête des titres', () {
    test('sépare un emoji simple', () {
      expect(splitLeadingMark('🛰️ Starlink revenu'), (
        '🛰️',
        'Starlink revenu',
      ));
    });

    test('sépare un emoji composé', () {
      expect(splitLeadingMark('👨‍💻 Le dev'), ('👨‍💻', 'Le dev'));
    });

    test('ne touche pas aux guillemets ni aux chiffres', () {
      expect(splitLeadingMark('« Fin » écrit Musk'), (
        '',
        '« Fin » écrit Musk',
      ));
      expect(splitLeadingMark('333 relais Tor'), ('', '333 relais Tor'));
      expect(splitLeadingMark('Titre normal'), ('', 'Titre normal'));
    });
  });
}
