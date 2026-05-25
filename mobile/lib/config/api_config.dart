/// Central configuration for API endpoints.
/// Switch [baseUrl] between local dev and Cloudflare production.
class ApiConfig {
  ApiConfig._();

  static const String _productionBaseUrl = 'https://english-learning-api.yuhaousa.workers.dev';

  // Local dev (wrangler dev)
  static const String _devBaseUrl = 'http://localhost:8787';

  /// Default to production; use --dart-define=ENV=dev for local testing.
  static const bool _isProduction = String.fromEnvironment('ENV', defaultValue: 'prod') != 'dev';

  static String get baseUrl => _isProduction ? _productionBaseUrl : _devBaseUrl;

  // ── Endpoints ────────────────────────────────────────────
  static String get words        => '$baseUrl/api/words';
  static String get sentences    => '$baseUrl/api/sentences';
  static String get quiz         => '$baseUrl/api/quiz';
  static String get progress     => '$baseUrl/api/progress';

  // Helpers
  static String wordById(int id)         => '$words/$id';
  static String randomWords({int n = 10, String? level}) =>
      '$words/random/batch?count=$n${level != null ? '&level=$level' : ''}';
  static String sentenceBuilder({int n = 5, String? level}) =>
      '$sentences/builder/batch?count=$n${level != null ? '&level=$level' : ''}';
  static String quizQuestions({int n = 10, String? level, String? type}) {
    final params = [
      'count=$n',
      if (level != null) 'level=$level',
      if (type  != null) 'type=$type',
    ].join('&');
    return '$quiz/questions?$params';
  }
  static String submitQuiz()            => '$quiz/submit';
  static String userProgress(String uid) => '$progress/$uid';
  static String dueItems(String uid)     => '$progress/$uid/due';
  static String progressSummary(String uid) => '$progress/$uid/summary';
  static String updateProgress()         => '$progress/update';
}
