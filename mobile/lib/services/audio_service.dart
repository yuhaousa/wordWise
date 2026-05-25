import 'package:flutter_tts/flutter_tts.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final FlutterTts _tts = FlutterTts();
  bool _initialized = false;

  Future<void> _init() async {
    if (_initialized) return;
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.45);   // slower for learners
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    _initialized = true;
  }

  /// Speak [text] using TTS. Optionally [slow] for letter-by-letter spelling mode.
  Future<void> speak(String text, {bool slow = false}) async {
    await _init();
    await _tts.setSpeechRate(slow ? 0.3 : 0.45);
    await _tts.speak(text);
  }

  /// Speak a word followed by its phonetic and example sentence.
  Future<void> speakWord({
    required String word,
    String? example,
  }) async {
    await speak(word);
    if (example != null && example.isNotEmpty) {
      await Future.delayed(const Duration(milliseconds: 800));
      await speak(example);
    }
  }

  Future<void> stop() async {
    await _tts.stop();
  }

  Future<void> dispose() async {
    await _tts.stop();
  }
}
