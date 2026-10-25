import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:lebienheureux/models/article.dart';
import 'package:lebienheureux/state/speech_controller.dart';

class _FakeTts extends Fake implements FlutterTts {
  _FakeTts({this.fail = false});

  final bool fail;
  final spoken = <String>[];
  Completer<void>? pending;
  int stops = 0;

  @override
  Future<dynamic> setLanguage(String language) async {
    if (fail) throw Exception('pas de voix française');
    return 1;
  }

  @override
  Future<dynamic> setSpeechRate(double rate) async => 1;

  @override
  Future<dynamic> awaitSpeakCompletion(bool awaitCompletion) async => 1;

  @override
  Future<dynamic> speak(String text, {bool focus = false}) async {
    spoken.add(text);
    pending = Completer<void>();
    await pending!.future;
    return 1;
  }

  @override
  Future<dynamic> stop() async {
    stops++;
    pending?.complete();
    return 1;
  }

  /// Termine l'énoncé en cours.
  void finish() => pending?.complete();
}

Article _article({int paragraphs = 1}) => Article(
  id: 1,
  title: 'Titre',
  excerpt: '',
  contentHtml: List.filled(paragraphs, '<p>${'mot ' * 100}</p>').join(),
  link: '',
  date: DateTime(2026),
);

void main() {
  test('lit le titre puis le texte, bloc par bloc, jusqu’au bout', () async {
    final tts = _FakeTts();
    final speech = SpeechController(engine: () => tts);
    final article = _article(paragraphs: 8);

    final playing = speech.toggle(article);
    await pumpEventQueue();
    expect(speech.isPlaying(1), isTrue);

    while (tts.spoken.length < SpeechController.chunksFor(article).length) {
      tts.finish();
      await pumpEventQueue();
    }
    tts.finish();
    await playing;

    expect(tts.spoken.first, startsWith('Titre'));
    expect(tts.spoken.length, greaterThan(1));
    expect(speech.isPlaying(1), isFalse);
  });

  test('« Arrêter » interrompt la lecture', () async {
    final tts = _FakeTts();
    final speech = SpeechController(engine: () => tts);
    final article = _article(paragraphs: 8);

    final playing = speech.toggle(article);
    await pumpEventQueue();
    await speech.toggle(article);
    await playing;

    expect(speech.isPlaying(1), isFalse);
    expect(tts.spoken, hasLength(1));
    expect(tts.stops, 1);
  });

  test('sans moteur vocal, le bouton revient à l’état normal', () async {
    final speech = SpeechController(engine: () => _FakeTts(fail: true));
    await speech.toggle(_article());
    expect(speech.isPlaying(1), isFalse);
  });
}
