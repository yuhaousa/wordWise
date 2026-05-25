import 'dart:convert';

enum QuizType {
  wordDefinition('word_definition'),
  fillBlank('fill_blank'),
  sentenceReorder('sentence_reorder'),
  chooseWord('choose_word'),
  spelling('spelling');

  const QuizType(this.value);
  final String value;

  static QuizType fromString(String s) =>
      QuizType.values.firstWhere((e) => e.value == s, orElse: () => QuizType.wordDefinition);
}

class QuizQuestion {
  final int id;
  final QuizType type;
  final String question;
  final String correctAnswer;
  final List<String> options;
  final int? wordId;
  final int? sentenceId;
  final String cefrLevel;

  const QuizQuestion({
    required this.id,
    required this.type,
    required this.question,
    required this.correctAnswer,
    required this.options,
    this.wordId,
    this.sentenceId,
    required this.cefrLevel,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    List<String> opts = [];
    final raw = json['options'];
    if (raw is String && raw.isNotEmpty) {
      opts = (jsonDecode(raw) as List).cast<String>();
    }
    return QuizQuestion(
      id:            json['id'] as int,
      type:          QuizType.fromString(json['type'] as String),
      question:      json['question'] as String,
      correctAnswer: json['correct_answer'] as String,
      options:       opts,
      wordId:        json['word_id'] as int?,
      sentenceId:    json['sentence_id'] as int?,
      cefrLevel:     json['cefr_level'] as String,
    );
  }
}
