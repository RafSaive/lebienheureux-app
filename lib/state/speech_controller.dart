import 'package:flutter/foundation.dart' show ChangeNotifier;
import 'package:flutter_tts/flutter_tts.dart';

import '../models/article.dart';
import '../util/html_text.dart';

/// « Écouter l'article » : lecture à voix haute par la synthèse vocale du
/// téléphone. Le texte est lu par blocs, car Android limite la longueur
/// d'un énoncé.
class SpeechController extends ChangeNotifier {
  FlutterTts? _tts;
  int? _playingId;

  static const _maxChunk = 1500;

  bool isPlaying(int articleId) => _playingId == articleId;

  Future<void> toggle(Article article) =>
      isPlaying(article.id) ? stop() : _play(article);

  Future<void> stop() async {
    if (_playingId == null) return;
    _playingId = null;
    notifyListeners();
    await _tts?.stop();
  }

  Future<void> _play(Article article) async {
    await stop();
    final tts = _tts ??= FlutterTts();
    await tts.setLanguage('fr-FR');
    await tts.setSpeechRate(0.5);
    await tts.awaitSpeakCompletion(true);

    _playingId = article.id;
    notifyListeners();

    for (final chunk in chunksFor(article)) {
      if (_playingId != article.id) return;
      await tts.speak(chunk);
    }
    if (_playingId == article.id) {
      _playingId = null;
      notifyListeners();
    }
  }

  /// Titre puis paragraphes, regroupés en blocs de taille raisonnable.
  static List<String> chunksFor(Article article) {
    final chunks = <String>[];
    var current = StringBuffer();
    for (final paragraph in [
      article.title,
      ...htmlToParagraphs(article.contentHtml),
    ]) {
      if (current.length + paragraph.length > _maxChunk && current.isNotEmpty) {
        chunks.add(current.toString());
        current = StringBuffer();
      }
      if (current.isNotEmpty) current.write('\n');
      current.write(paragraph);
    }
    if (current.isNotEmpty) chunks.add(current.toString());
    return chunks;
  }

  @override
  void dispose() {
    _tts?.stop();
    super.dispose();
  }
}
