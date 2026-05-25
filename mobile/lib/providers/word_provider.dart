import 'package:flutter/material.dart';
import '../models/word.dart';
import '../services/api_service.dart';

class WordProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<Word> _flashcards = [];
  int _currentIndex = 0;
  bool _loading = false;
  String? _error;
  String? _selectedLevel;

  List<Word> get flashcards => _flashcards;
  int  get currentIndex    => _currentIndex;
  bool get loading         => _loading;
  String? get error        => _error;
  String? get selectedLevel => _selectedLevel;

  Word? get currentWord =>
      _flashcards.isNotEmpty && _currentIndex < _flashcards.length
          ? _flashcards[_currentIndex]
          : null;

  bool get hasMore => _currentIndex < _flashcards.length - 1;

  void setLevel(String? level) {
    _selectedLevel = level;
    loadFlashcards();
  }

  Future<void> loadFlashcards({int count = 15}) async {
    _loading = true;
    _error = null;
    _currentIndex = 0;
    notifyListeners();
    try {
      _flashcards = await _api.fetchFlashcards(count: count, level: _selectedLevel);
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void next() {
    if (hasMore) {
      _currentIndex++;
      notifyListeners();
    }
  }

  void previous() {
    if (_currentIndex > 0) {
      _currentIndex--;
      notifyListeners();
    }
  }

  Future<void> markResult(bool correct) async {
    final word = currentWord;
    if (word == null) return;
    await _api.updateProgress(itemType: 'word', itemId: word.id, isCorrect: correct);
  }
}
