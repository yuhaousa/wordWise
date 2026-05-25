import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/word_provider.dart';
import '../services/api_service.dart';
import '../services/audio_service.dart';
import '../theme/app_theme.dart';

class FlashcardScreen extends StatefulWidget {
  final bool reviewMode;
  const FlashcardScreen({super.key, this.reviewMode = false});

  @override
  State<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen>
    with SingleTickerProviderStateMixin {
  final _audio = AudioService();
  final _api   = ApiService();
  bool _flipped = false;
  late AnimationController _flipCtrl;
  late Animation<double> _flipAnim;

  @override
  void initState() {
    super.initState();
    _flipCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _flipAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipCtrl, curve: Curves.easeInOut),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Read the level saved in Settings — never ask here
      final prefs = await SharedPreferences.getInstance();
      final savedLevel = prefs.getString('user_level');
      if (!mounted) return;
      final provider = context.read<WordProvider>();
      provider.setLevel(savedLevel); // null → all levels
    });
  }

  @override
  void dispose() {
    _flipCtrl.dispose();
    super.dispose();
  }

  void _toggleFlip() {
    setState(() => _flipped = !_flipped);
    _flipped ? _flipCtrl.forward() : _flipCtrl.reverse();
  }

  void _handleSwipe(bool correct, WordProvider provider) async {
    // Track wrong words silently before advancing
    if (!correct && provider.currentWord != null) {
      _api.addWrongWord(provider.currentWord!.id);
    }
    await provider.markResult(correct);
    setState(() { _flipped = false; });
    _flipCtrl.reverse();
    provider.next();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flashcards'),
        actions: [
          Consumer<WordProvider>(
            builder: (_, p, __) => Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  '${p.currentIndex + 1} / ${p.flashcards.length}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Consumer<WordProvider>(
        builder: (context, provider, _) {
          if (provider.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.error != null) {
            return Center(child: Text('Error: ${provider.error}'));
          }
          if (provider.flashcards.isEmpty) {
            return const Center(child: Text('No words found.'));
          }

          final word = provider.currentWord!;

          return Column(
            children: [
              // ── Progress bar ───────────────────────────
              LinearProgressIndicator(
                value: (provider.currentIndex + 1) / provider.flashcards.length,
                backgroundColor: Colors.grey.shade200,
                color: AppTheme.primary,
                minHeight: 4,
              ),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      // CEFR badge (display only — not a selector)
                      Chip(
                        label: Text(word.cefrLevel),
                        backgroundColor: AppTheme.cefrColor(word.cefrLevel),
                      ),
                      const SizedBox(height: 16),

                      // ── Flip card ───────────────────────
                      Expanded(
                        child: GestureDetector(
                          onTap: _toggleFlip,
                          child: AnimatedBuilder(
                            animation: _flipAnim,
                            builder: (_, child) {
                              final angle = _flipAnim.value * 3.14159;
                              final isBack = _flipAnim.value > 0.5;
                              return Transform(
                                alignment: Alignment.center,
                                transform: Matrix4.identity()
                                  ..setEntry(3, 2, 0.001)
                                  ..rotateY(angle),
                                child: isBack
                                    ? Transform(
                                        alignment: Alignment.center,
                                        transform: Matrix4.identity()..rotateY(3.14159),
                                        child: _CardBack(word: word, audio: _audio),
                                      )
                                    : _CardFront(word: word, audio: _audio),
                              );
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),
                      Text(
                        _flipped ? 'Tap card to flip back' : 'Tap card to reveal definition',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                      ),
                      const SizedBox(height: 20),

                      // ── Know / Don't know buttons ────────
                      if (_flipped)
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _handleSwipe(false, provider),
                                icon: const Icon(Icons.close, color: AppTheme.error),
                                label: const Text("Don't Know",
                                    style: TextStyle(color: AppTheme.error)),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: AppTheme.error),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _handleSwipe(true, provider),
                                icon: const Icon(Icons.check),
                                label: const Text('Got It!'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.secondary,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                          ],
                        ),

                      if (!provider.hasMore &&
                          provider.currentIndex == provider.flashcards.length - 1)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: TextButton(
                            onPressed: provider.loadFlashcards,
                            child: const Text('Load new batch'),
                          ),
                        ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Card front (word) ─────────────────────────────────────
class _CardFront extends StatelessWidget {
  final dynamic word;
  final AudioService audio;
  const _CardFront({required this.word, required this.audio});

  String _prettyPartOfSpeech(String raw) {
    if (raw.isEmpty) return 'Word';
    final normalized = raw.replaceAll('_', ' ').trim();
    return normalized
        .split(' ')
        .where((s) => s.isNotEmpty)
        .map((s) => s[0].toUpperCase() + s.substring(1).toLowerCase())
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(word.word,
                style: const TextStyle(
                    color: Colors.white, fontSize: 42, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            if ((word.chineseMeaning as String).isNotEmpty)
              Text(
                word.chineseMeaning,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFFFF3B0),
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            if ((word.chineseMeaning as String).isNotEmpty) const SizedBox(height: 8),
            if (word.phonetic.isNotEmpty)
              Text(word.phonetic,
                  style: const TextStyle(color: Colors.white70, fontSize: 18)),
            const SizedBox(height: 20),
            IconButton(
              icon: const Icon(Icons.volume_up_rounded, color: Colors.white, size: 32),
              onPressed: () => audio.speak(word.word),
            ),
            const SizedBox(height: 8),
            Chip(
              label: Text(
                _prettyPartOfSpeech(word.partOfSpeech),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
              avatar: const Icon(Icons.label_rounded, color: Colors.white, size: 14),
              backgroundColor: Colors.white24,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
              side: const BorderSide(color: Colors.white24),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Card back (definition) ────────────────────────────────
class _CardBack extends StatelessWidget {
  final dynamic word;
  final AudioService audio;
  const _CardBack({required this.word, required this.audio});

  List<String> _splitTerms(String raw) {
    if (raw.trim().isEmpty || raw.trim().toLowerCase() == 'none') return const [];
    return raw
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  Widget _termSection(String title, List<String> terms, {required Color color}) {
    if (terms.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: terms
              .map((t) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      t,
                      style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Definition', style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 8),
            Text(word.definition,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, height: 1.4)),
            if ((word.chineseMeaning as String).isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                '中文释义: ${word.chineseMeaning}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
            const Divider(height: 32),
            const Text('Example', style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 8),
            Text(word.exampleSentence,
                style: TextStyle(
                    fontSize: 15, fontStyle: FontStyle.italic, color: Colors.grey.shade700)),
            const SizedBox(height: 16),
            _termSection('同义词', _splitTerms(word.synonyms), color: AppTheme.primary),
            if (_splitTerms(word.synonyms).isNotEmpty) const SizedBox(height: 12),
            _termSection('反义词', _splitTerms(word.antonyms), color: AppTheme.error),
            const SizedBox(height: 12),
            InkWell(
              onTap: () => audio.speakWord(word: word.word, example: word.exampleSentence),
              borderRadius: BorderRadius.circular(8),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.volume_up_rounded, color: AppTheme.primary, size: 20),
                  SizedBox(width: 6),
                  Text('Listen',
                      style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
