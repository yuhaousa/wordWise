import 'dart:convert';

class Sentence {
  final int id;
  final String sentence;
  final String translation;
  final String cefrLevel;
  final String category;
  final List<int> wordIds;
  final String grammarFocus;

  const Sentence({
    required this.id,
    required this.sentence,
    required this.translation,
    required this.cefrLevel,
    required this.category,
    required this.wordIds,
    required this.grammarFocus,
  });

  factory Sentence.fromJson(Map<String, dynamic> json) {
    final rawWordIds = json['word_ids'];
    List<int> parsedIds = [];
    if (rawWordIds is String && rawWordIds.isNotEmpty) {
      parsedIds = (jsonDecode(rawWordIds) as List).cast<int>();
    }
    return Sentence(
      id:           json['id'] as int,
      sentence:     json['sentence'] as String,
      translation:  json['translation'] as String? ?? '',
      cefrLevel:    json['cefr_level'] as String,
      category:     json['category'] as String? ?? 'general',
      wordIds:      parsedIds,
      grammarFocus: json['grammar_focus'] as String? ?? '',
    );
  }

  /// Returns the sentence words shuffled for the sentence-builder exercise.
  List<String> get shuffledWords {
    final words = sentence.replaceAll(RegExp(r'[^\w\s]'), '').trim().split(RegExp(r'\s+'));
    words.shuffle();
    return words;
  }
}
