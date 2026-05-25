import 'package:flutter/material.dart';
import '../models/quiz_question.dart';
import '../services/api_service.dart';

enum QuizState { idle, loading, active, reviewing, finished, error }

class QuizAnswer {
  final QuizQuestion question;
  final String given;
  final bool correct;
  const QuizAnswer({required this.question, required this.given, required this.correct});
}

class QuizProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<QuizQuestion> _questions = [];
  List<QuizAnswer>   _answers   = [];
  int         _currentIndex = 0;
  QuizState   _state        = QuizState.idle;
  String?     _error;
  String?     _selectedLevel;

  // current question state
  String? _selectedOption;
  bool?   _isCorrect;

  List<QuizQuestion> get questions     => _questions;
  List<QuizAnswer>   get answers       => _answers;
  int                get currentIndex  => _currentIndex;
  QuizState          get state         => _state;
  String?            get error         => _error;
  String?            get selectedOption => _selectedOption;
  bool?              get isCorrect      => _isCorrect;

  QuizQuestion? get currentQuestion =>
      _questions.isNotEmpty && _currentIndex < _questions.length
          ? _questions[_currentIndex]
          : null;

  int get score  => _answers.where((a) => a.correct).length;
  int get total  => _answers.length;
  double get pct => total == 0 ? 0 : score / _questions.length;

  void setLevel(String? level) => _selectedLevel = level;

  Future<void> startQuiz({int count = 10}) async {
    _state = QuizState.loading;
    _error = null;
    _answers.clear();
    _currentIndex = 0;
    _selectedOption = null;
    _isCorrect = null;
    notifyListeners();
    try {
      _questions = await _api.fetchQuizQuestions(count: count, level: _selectedLevel);
      _state = QuizState.active;
    } catch (e) {
      _error = e.toString();
      _state = QuizState.error;
    }
    notifyListeners();
  }

  Future<void> submitAnswer(String answer) async {
    final q = currentQuestion;
    if (q == null || _state != QuizState.active) return;

    _selectedOption = answer;
    _state = QuizState.reviewing;
    notifyListeners();

    try {
      final result = await _api.submitAnswer(q.id, answer);
      _isCorrect = result['data']['is_correct'] as bool? ?? false;
    } catch (_) {
      // fallback: local check
      _isCorrect = answer.trim().toLowerCase() == q.correctAnswer.trim().toLowerCase();
    }

    _answers.add(QuizAnswer(question: q, given: answer, correct: _isCorrect!));

    // ── Wrong Words tracking ──────────────────────────────
    // If the answer was wrong AND the question is tied to a word,
    // silently add / increment it in the wrong-words library.
    if (!(_isCorrect!) && q.wordId != null) {
      _api.addWrongWord(q.wordId!);
    }

    notifyListeners();
  }

  void nextQuestion() {
    _selectedOption = null;
    _isCorrect = null;
    if (_currentIndex < _questions.length - 1) {
      _currentIndex++;
      _state = QuizState.active;
    } else {
      _state = QuizState.finished;
    }
    notifyListeners();
  }

  void reset() {
    _questions.clear();
    _answers.clear();
    _currentIndex = 0;
    _state = QuizState.idle;
    _selectedOption = null;
    _isCorrect = null;
    notifyListeners();
  }
}
