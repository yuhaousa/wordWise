import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/word.dart';
import '../models/sentence.dart';
import '../models/quiz_question.dart';
import '../models/user_progress.dart';
import '../models/wrong_word.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, [this.statusCode]);
  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String _userId = 'user_default'; // replaced after auth / device ID set
  void setUserId(String id) => _userId = id;

  final _client = http.Client();

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'X-User-Id': _userId,
      };

  Future<Map<String, dynamic>> _get(String url) async {
    final response = await _client.get(Uri.parse(url), headers: _headers);
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> _post(String url, Map<String, dynamic> body) async {
    final response = await _client.post(
      Uri.parse(url),
      headers: _headers,
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  Map<String, dynamic> _handleResponse(http.Response res) {
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode >= 200 && res.statusCode < 300 && json['success'] == true) {
      return json;
    }
    throw ApiException(json['error'] as String? ?? 'Unknown error', res.statusCode);
  }

  // ── Words ──────────────────────────────────────────────
  Future<List<Word>> fetchWords({String? level, String? category, int page = 1}) async {
    final url = '${ApiConfig.words}?page=$page${level != null ? '&level=$level' : ''}${category != null ? '&category=$category' : ''}';
    final json = await _get(url);
    return (json['data'] as List).map((e) => Word.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Word>> fetchFlashcards({int count = 10, String? level}) async {
    final json = await _get(ApiConfig.randomWords(n: count, level: level));
    return (json['data'] as List).map((e) => Word.fromJson(e as Map<String, dynamic>)).toList();
  }

  // ── Sentences ──────────────────────────────────────────
  Future<List<Sentence>> fetchSentenceBuilderBatch({int count = 5, String? level}) async {
    final json = await _get(ApiConfig.sentenceBuilder(n: count, level: level));
    return (json['data'] as List).map((e) => Sentence.fromJson(e as Map<String, dynamic>)).toList();
  }

  // ── Quiz ───────────────────────────────────────────────
  Future<List<QuizQuestion>> fetchQuizQuestions({int count = 10, String? level, String? type}) async {
    final json = await _get(ApiConfig.quizQuestions(n: count, level: level, type: type));
    return (json['data'] as List).map((e) => QuizQuestion.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Map<String, dynamic>> submitAnswer(int questionId, String answer) async {
    return _post(ApiConfig.submitQuiz(), {'question_id': questionId, 'answer': answer});
  }

  Future<Map<String, dynamic>> fetchQuizStats() async {
    return _get('${ApiConfig.quiz}/stats/$_userId');
  }

  // ── Progress ───────────────────────────────────────────
  Future<Map<String, dynamic>> fetchProgressSummary() async {
    return _get(ApiConfig.progressSummary(_userId));
  }

  Future<List<UserProgress>> fetchDueItems({String? itemType}) async {
    final url = '${ApiConfig.dueItems(_userId)}${itemType != null ? '?item_type=$itemType' : ''}';
    final json = await _get(url);
    return (json['data'] as List).map((e) => UserProgress.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> updateProgress({
    required String itemType,
    required int itemId,
    required bool isCorrect,
  }) async {
    await _post(ApiConfig.updateProgress(), {
      'item_type': itemType,
      'item_id': itemId,
      'is_correct': isCorrect,
    });
  }

  // ── Wrong Words Library ────────────────────────────────
  /// Fetch the user's wrong-words library.
  /// [includeMastered] — include words the user already marked as learned.
  /// [level] — optional CEFR filter (e.g. 'B1').
  Future<List<WrongWord>> fetchWrongWords({
    bool includeMastered = false,
    String? level,
    int limit = 50,
    int offset = 0,
  }) async {
    var url = '${ApiConfig.baseUrl}/api/wrong-words/$_userId'
        '?limit=$limit&offset=$offset'
        '${includeMastered ? '&include_mastered=true' : ''}';
    if (level != null) url += '&level=$level';
    final json = await _get(url);
    return (json['data'] as List)
        .map((e) => WrongWord.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Record a wrong word (or increment its miss count).
  /// Silently ignores errors so it never interrupts study flow.
  Future<void> addWrongWord(int wordId) async {
    try {
      await _post('${ApiConfig.baseUrl}/api/wrong-words', {'word_id': wordId});
    } catch (_) {}
  }

  /// Mark / un-mark a word as learned.
  Future<void> setWordMastered(int wordId, {required bool mastered}) async {
    final url = '${ApiConfig.baseUrl}/api/wrong-words/$_userId/$wordId/mastered';
    final response = await _client.patch(
      Uri.parse(url),
      headers: _headers,
      body: jsonEncode({'mastered': mastered}),
    );
    _handleResponse(response);
  }

  /// Remove a word from the library entirely.
  Future<void> deleteWrongWord(int wordId) async {
    await _client.delete(
      Uri.parse('${ApiConfig.baseUrl}/api/wrong-words/$_userId/$wordId'),
      headers: _headers,
    );
  }

  /// Fetch words for practice mode (most-missed first).
  Future<List<WrongWord>> fetchWrongWordsPractice({int count = 10, String? level}) async {
    var url = '${ApiConfig.baseUrl}/api/wrong-words/$_userId/practice?count=$count';
    if (level != null) url += '&level=$level';
    final json = await _get(url);
    // practice endpoint returns word fields directly, map to WrongWord
    return (json['data'] as List).map((e) {
      final m = e as Map<String, dynamic>;
      return WrongWord(
        id:              0,
        userId:          _userId,
        wordId:          m['id'] as int,
        wrongCount:      m['wrong_count'] as int? ?? 1,
        lastWrongAt:     '',
        mastered:        false,
        word:            m['word'] as String? ?? '',
        definition:      m['definition'] as String? ?? '',
        partOfSpeech:    m['part_of_speech'] as String? ?? '',
        cefrLevel:       m['cefr_level'] as String? ?? '',
        exampleSentence: m['example_sentence'] as String? ?? '',
        phonetic:        m['phonetic'] as String? ?? '',
      );
    }).toList();
  }

  /// Fetch stats (active / mastered / total-misses) for dashboard.
  Future<WrongWordStats> fetchWrongWordStats() async {
    final json = await _get('${ApiConfig.baseUrl}/api/wrong-words/$_userId/stats');
    return WrongWordStats.fromJson(json['data'] as Map<String, dynamic>);
  }
}
