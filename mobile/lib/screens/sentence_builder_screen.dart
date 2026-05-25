import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/sentence.dart';
import '../services/api_service.dart';
import '../services/audio_service.dart';
import '../theme/app_theme.dart';

class SentenceBuilderScreen extends StatefulWidget {
  const SentenceBuilderScreen({super.key});

  @override
  State<SentenceBuilderScreen> createState() => _SentenceBuilderScreenState();
}

class _SentenceBuilderScreenState extends State<SentenceBuilderScreen> {
  final _api   = ApiService();
  final _audio = AudioService();

  List<Sentence> _sentences   = [];
  int            _index        = 0;
  List<String>   _wordBank     = [];
  List<String?>  _answerSlots  = [];
  bool           _loading      = true;
  bool?          _result;
  String?        _level;       // read from Settings, never shown as a picker

  @override
  void initState() {
    super.initState();
    _loadBatch();
  }

  Future<void> _loadBatch() async {
    setState(() { _loading = true; _result = null; });
    // Read level from Settings on every batch load so it picks up changes
    final prefs = await SharedPreferences.getInstance();
    _level = prefs.getString('user_level');
    try {
      _sentences = await _api.fetchSentenceBuilderBatch(count: 5, level: _level);
      _index = 0;
      _setupCurrentSentence();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  void _setupCurrentSentence() {
    if (_sentences.isEmpty) return;
    final s = _sentences[_index];
    _wordBank    = List.from(s.shuffledWords)..shuffle();
    _answerSlots = List.filled(s.shuffledWords.length, null);
    _result      = null;
  }

  void _tapWordBank(int bankIdx) {
    if (_wordBank[bankIdx].isEmpty) return;
    final firstEmpty = _answerSlots.indexWhere((s) => s == null);
    if (firstEmpty == -1) return;
    setState(() {
      _answerSlots[firstEmpty] = _wordBank[bankIdx];
      _wordBank[bankIdx] = '';
    });
  }

  void _tapAnswer(int slotIdx) {
    if (_answerSlots[slotIdx] == null) return;
    final word = _answerSlots[slotIdx]!;
    final emptyInBank = _wordBank.indexWhere((w) => w.isEmpty);
    setState(() {
      _answerSlots[slotIdx] = null;
      if (emptyInBank >= 0) _wordBank[emptyInBank] = word;
    });
  }

  void _checkAnswer() {
    final current = _sentences[_index];
    final answer = _answerSlots.whereType<String>().join(' ').trim();
    final correct = current.sentence.trim();
    final isCorrect = answer.toLowerCase() == correct.toLowerCase();
    setState(() => _result = isCorrect);
    if (isCorrect) _audio.speak(correct);
  }

  void _next() {
    if (_index < _sentences.length - 1) {
      setState(() {
        _index++;
        _setupCurrentSentence();
      });
    } else {
      _loadBatch();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sentence Builder'),
        actions: [
          if (!_loading && _sentences.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text('${_index + 1} / ${_sentences.length}',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _sentences.isEmpty
              ? const Center(child: Text('No sentences found.'))
              : _buildBuilder(),
    );
  }

  Widget _buildBuilder() {
    final sentence = _sentences[_index];

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Level + grammar focus
          Row(children: [
            Chip(
              label: Text(sentence.cefrLevel),
              backgroundColor: AppTheme.cefrColor(sentence.cefrLevel),
            ),
            const SizedBox(width: 8),
            if (sentence.grammarFocus.isNotEmpty)
              Chip(
                label: Text(sentence.grammarFocus),
                backgroundColor: Colors.grey.shade100,
              ),
          ]),
          const SizedBox(height: 16),

          Text('Arrange the words to form a correct sentence:',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 20),

          // ── Answer slots ──────────────────────────────
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 80),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _result == null
                  ? Colors.grey.shade50
                  : _result!
                      ? AppTheme.secondary.withOpacity(0.1)
                      : AppTheme.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _result == null
                    ? Colors.grey.shade300
                    : _result!
                        ? AppTheme.secondary
                        : AppTheme.error,
                width: 2,
              ),
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(_answerSlots.length, (i) {
                final w = _answerSlots[i];
                return GestureDetector(
                  onTap: () => _tapAnswer(i),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: w != null ? AppTheme.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: w != null ? AppTheme.primary : Colors.grey.shade400,
                          style: w != null ? BorderStyle.solid : BorderStyle.solid,
                          width: w != null ? 1 : 1.5),
                    ),
                    child: Text(
                      w ?? '      ',
                      style: TextStyle(
                        color: w != null ? Colors.white : Colors.transparent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),

          // Result message
          if (_result != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                _result!
                    ? '✅ Correct! Well done!'
                    : '❌ Not quite. The correct sentence is:\n"${sentence.sentence}"',
                style: TextStyle(
                  color: _result! ? AppTheme.secondary : AppTheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

          const SizedBox(height: 24),

          // ── Word bank ─────────────────────────────────
          Text('Word Bank', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(_wordBank.length, (i) {
              final w = _wordBank[i];
              if (w.isEmpty) return const SizedBox.shrink();
              return GestureDetector(
                onTap: () => _tapWordBank(i),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.primary),
                    boxShadow: [
                      BoxShadow(color: AppTheme.primary.withOpacity(0.15), blurRadius: 4, offset: const Offset(0, 2))
                    ],
                  ),
                  child: Text(w,
                      style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600)),
                ),
              );
            }),
          ),

          const Spacer(),

          // ── Action buttons ────────────────────────────
          if (_result == null)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _answerSlots.every((s) => s != null) ? _checkAnswer : null,
                child: const Text('Check Answer'),
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _next,
                child: Text(_index < _sentences.length - 1 ? 'Next Sentence →' : 'Load More'),
              ),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
