import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ProgressProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  Map<String, dynamic>? _summary;
  bool _loading = false;
  String? _error;

  Map<String, dynamic>? get summary => _summary;
  bool    get loading => _loading;
  String? get error   => _error;

  int get dueForReview => (_summary?['due_for_review'] as int?) ?? 0;

  Future<void> loadSummary() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final json = await _api.fetchProgressSummary();
      _summary = json['data'] as Map<String, dynamic>?;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
