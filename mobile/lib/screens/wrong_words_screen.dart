import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/wrong_word.dart';
import '../services/api_service.dart';
import '../services/audio_service.dart';
import '../theme/app_theme.dart';

// ═══════════════════════════════════════════════════════════════
//  WrongWordsScreen — Wrong Words Library
//  Shows all words the student missed, lets them practice and
//  mark words as "learned" once they feel confident.
// ═══════════════════════════════════════════════════════════════
class WrongWordsScreen extends StatefulWidget {
  const WrongWordsScreen({super.key});

  @override
  State<WrongWordsScreen> createState() => _WrongWordsScreenState();
}

class _WrongWordsScreenState extends State<WrongWordsScreen> {
  final _api   = ApiService();
  final _audio = AudioService();

  List<WrongWord> _words          = [];
  bool            _loading        = true;
  bool            _includeMastered = false;
  String?         _selectedLevel; // null = all
  WrongWordStats? _stats;

  static const _levels = ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _api.fetchWrongWords(
          includeMastered: _includeMastered,
          level: _selectedLevel,
        ),
        _api.fetchWrongWordStats(),
      ]);
      if (!mounted) return;
      setState(() {
        _words = results[0] as List<WrongWord>;
        _stats = results[1] as WrongWordStats;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not load wrong words: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleMastered(WrongWord ww) async {
    final newMastered = !ww.mastered;
    await _api.setWordMastered(ww.wordId, mastered: newMastered);
    setState(() {
      final idx = _words.indexOf(ww);
      if (idx >= 0) {
        _words[idx] = ww.copyWith(mastered: newMastered);
        // If we're hiding mastered, remove it from view after a short delay
        if (!_includeMastered && newMastered) {
          Future.delayed(const Duration(milliseconds: 400), () {
            if (mounted) setState(() => _words.removeAt(idx));
          });
        }
      }
    });
    _refreshStats();
  }

  Future<void> _delete(WrongWord ww) async {
    await _api.deleteWrongWord(ww.wordId);
    setState(() => _words.remove(ww));
    _refreshStats();
  }

  Future<void> _refreshStats() async {
    try {
      final s = await _api.fetchWrongWordStats();
      if (mounted) setState(() => _stats = s);
    } catch (_) {}
  }

  void _startPractice() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _PracticeModeScreen(level: _selectedLevel),
      ),
    ).then((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wrong Words Library'),
        actions: [
          if (_words.isNotEmpty)
            IconButton(
              tooltip: 'Practice these words',
              icon: const Icon(Icons.play_circle_outline_rounded, color: AppTheme.primary),
              onPressed: _startPractice,
            ),
        ],
      ),
      body: Column(
        children: [
          _buildHeader(),
          _buildFilters(),
          const Divider(height: 1),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _words.isEmpty
                    ? _buildEmpty()
                    : _buildList(),
          ),
        ],
      ),
    );
  }

  // ── Stats header ──────────────────────────────────────────
  Widget _buildHeader() {
    final active   = _stats?.active   ?? 0;
    final mastered = _stats?.mastered ?? 0;
    final misses   = _stats?.totalMisses ?? 0;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEF4444), Color(0xFFF97316)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEF4444).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Text('❌', style: TextStyle(fontSize: 32)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Wrong Words Library',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
                const SizedBox(height: 4),
                Text('$active to review · $mastered mastered · $misses total misses',
                    style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          if (active > 0)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFFEF4444),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _startPractice,
              child: const Text('Practice', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            ),
        ],
      ),
    );
  }

  // ── Filter row ────────────────────────────────────────────
  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          // Level filter chips
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: 'All',
                    selected: _selectedLevel == null,
                    onTap: () { setState(() => _selectedLevel = null); _load(); },
                  ),
                  ...List.generate(_levels.length, (i) {
                    final lvl = _levels[i];
                    return _FilterChip(
                      label: lvl,
                      selected: _selectedLevel == lvl,
                      color: AppTheme.cefrColor(lvl),
                      onTap: () { setState(() => _selectedLevel = lvl); _load(); },
                    );
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Show mastered toggle
          Tooltip(
            message: _includeMastered ? 'Hide learned' : 'Show learned',
            child: IconButton(
              icon: Icon(
                _includeMastered ? Icons.visibility : Icons.visibility_off_outlined,
                color: _includeMastered ? AppTheme.secondary : Colors.grey.shade400,
                size: 22,
              ),
              onPressed: () {
                setState(() => _includeMastered = !_includeMastered);
                _load();
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Empty state ───────────────────────────────────────────
  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text(
              'No wrong words yet!',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Words you miss during quizzes\nor flashcards will appear here.',
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ── Word list ─────────────────────────────────────────────
  Widget _buildList() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: _words.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) => _WordCard(
        ww: _words[i],
        audio: _audio,
        onMastered: () => _toggleMastered(_words[i]),
        onDelete: () => _showDeleteConfirm(_words[i]),
      ),
    );
  }

  Future<void> _showDeleteConfirm(WrongWord ww) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove word?'),
        content: Text('"${ww.word}" will be removed from your library.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
    if (ok == true) _delete(ww);
  }
}

// ─────────────────────────────────────────────────────────────
//  Individual word card
// ─────────────────────────────────────────────────────────────
class _WordCard extends StatefulWidget {
  final WrongWord ww;
  final AudioService audio;
  final VoidCallback onMastered;
  final VoidCallback onDelete;

  const _WordCard({
    required this.ww,
    required this.audio,
    required this.onMastered,
    required this.onDelete,
  });

  @override
  State<_WordCard> createState() => _WordCardState();
}

class _WordCardState extends State<_WordCard> with SingleTickerProviderStateMixin {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final ww       = widget.ww;
    final mastered = ww.mastered;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        color: mastered ? AppTheme.secondary.withOpacity(0.06) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: mastered ? AppTheme.secondary.withOpacity(0.4) : Colors.grey.shade200,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Header row ──
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
              child: Row(
                children: [
                  // Miss count badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: mastered
                          ? AppTheme.secondary.withOpacity(0.15)
                          : const Color(0xFFEF4444).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      mastered ? '✓' : '×${ww.wrongCount}',
                      style: TextStyle(
                        color: mastered ? AppTheme.secondary : AppTheme.error,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Word
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ww.word,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            decoration: mastered ? TextDecoration.lineThrough : null,
                            color: mastered ? Colors.grey.shade500 : AppTheme.textPrimary,
                          ),
                        ),
                        if (ww.phonetic.isNotEmpty)
                          Text(ww.phonetic,
                              style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                      ],
                    ),
                  ),
                  // CEFR chip
                  Chip(
                    label: Text(ww.cefrLevel,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                    backgroundColor: AppTheme.cefrColor(ww.cefrLevel),
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey.shade400,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          // ── Expanded detail ──
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 16),
                  // Part of speech
                  Text(ww.partOfSpeech.toUpperCase(),
                      style: const TextStyle(
                          color: AppTheme.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5)),
                  const SizedBox(height: 4),
                  // Definition
                  Text(ww.definition,
                      style: const TextStyle(fontSize: 14, height: 1.4)),
                  if (ww.exampleSentence.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('"${ww.exampleSentence}"',
                          style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 13,
                              fontStyle: FontStyle.italic)),
                    ),
                  ],
                  const SizedBox(height: 12),
                  // Action buttons row
                  Row(
                    children: [
                      // Listen
                      _ActionBtn(
                        icon: Icons.volume_up_rounded,
                        label: 'Listen',
                        color: AppTheme.primary,
                        onTap: () => widget.audio.speak(ww.word),
                      ),
                      const SizedBox(width: 8),
                      // Mark learned / un-learn
                      _ActionBtn(
                        icon: ww.mastered ? Icons.refresh_rounded : Icons.check_circle_outline_rounded,
                        label: ww.mastered ? 'Un-master' : 'Mark learned',
                        color: AppTheme.secondary,
                        onTap: widget.onMastered,
                      ),
                      const SizedBox(width: 8),
                      // Delete
                      _ActionBtn(
                        icon: Icons.delete_outline_rounded,
                        label: 'Remove',
                        color: AppTheme.error,
                        onTap: widget.onDelete,
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String   label;
  final Color    color;
  final VoidCallback onTap;
  const _ActionBtn({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 4),
              Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool   selected;
  final Color? color;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.selected, this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bg = selected
        ? (color ?? AppTheme.primary)
        : (color?.withOpacity(0.15) ?? Colors.grey.shade100);
    final fg = selected ? Colors.white : (color ?? Colors.grey.shade700);
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
          child: Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w600, fontSize: 12)),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  Practice Mode — flip-card drill on wrong words
// ═══════════════════════════════════════════════════════════════
class _PracticeModeScreen extends StatefulWidget {
  final String? level;
  const _PracticeModeScreen({this.level});

  @override
  State<_PracticeModeScreen> createState() => _PracticeModeScreenState();
}

class _PracticeModeScreenState extends State<_PracticeModeScreen>
    with SingleTickerProviderStateMixin {
  final _api   = ApiService();
  final _audio = AudioService();

  List<WrongWord> _words   = [];
  int             _index   = 0;
  bool            _loading = true;
  bool            _flipped = false;
  int             _known   = 0;
  int             _missed  = 0;
  bool            _done    = false;

  late AnimationController _flipCtrl;
  late Animation<double>   _flipAnim;

  @override
  void initState() {
    super.initState();
    _flipCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _flipAnim = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _flipCtrl, curve: Curves.easeInOut));
    _load();
  }

  @override
  void dispose() {
    _flipCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final words = await _api.fetchWrongWordsPractice(count: 20, level: widget.level);
      if (!mounted) return;
      setState(() {
        _words   = words;
        _loading = false;
        _index   = 0;
        _flipped = false;
        _known   = 0;
        _missed  = 0;
        _done    = false;
      });
    } catch (e) {
      if (mounted) Navigator.pop(context);
    }
  }

  void _flip() {
    if (_flipped) {
      _flipCtrl.reverse();
    } else {
      _flipCtrl.forward();
      _audio.speak(_words[_index].word);
    }
    setState(() => _flipped = !_flipped);
  }

  void _answer(bool knew) {
    setState(() {
      if (knew) {
        _known++;
        // Mark as mastered if user got it right
        _api.setWordMastered(_words[_index].wordId, mastered: true);
      } else {
        _missed++;
      }
      if (_index < _words.length - 1) {
        _index++;
        _flipped = false;
        _flipCtrl.reset();
      } else {
        _done = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Practice Mode')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _words.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('🎉', style: TextStyle(fontSize: 64)),
                      const SizedBox(height: 16),
                      const Text('Nothing to practice!',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 24),
                      TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Back to Library')),
                    ],
                  ),
                )
              : _done
                  ? _buildResults()
                  : _buildPractice(),
    );
  }

  Widget _buildPractice() {
    final ww = _words[_index];
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Progress bar
          LinearProgressIndicator(
            value: (_index + 1) / _words.length,
            backgroundColor: Colors.grey.shade200,
            color: AppTheme.primary,
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${_index + 1} of ${_words.length}',
                    style: const TextStyle(color: Colors.grey)),
                Row(children: [
                  const Icon(Icons.check_circle, color: AppTheme.secondary, size: 16),
                  Text(' $_known  ', style: const TextStyle(color: AppTheme.secondary, fontWeight: FontWeight.w600)),
                  const Icon(Icons.cancel, color: AppTheme.error, size: 16),
                  Text(' $_missed', style: const TextStyle(color: AppTheme.error, fontWeight: FontWeight.w600)),
                ]),
              ],
            ),
          ),

          // Flip card
          Expanded(
            child: GestureDetector(
              onTap: _flip,
              child: AnimatedBuilder(
                animation: _flipAnim,
                builder: (_, __) {
                  final angle = _flipAnim.value * math.pi;
                  final isFront = angle < math.pi / 2;
                  return Transform(
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..rotateY(angle),
                    alignment: Alignment.center,
                    child: isFront
                        ? _buildCardFace(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Chip(
                                  label: Text(ww.cefrLevel),
                                  backgroundColor: AppTheme.cefrColor(ww.cefrLevel),
                                ),
                                const SizedBox(height: 24),
                                Text(ww.word,
                                    style: const TextStyle(
                                        fontSize: 36,
                                        fontWeight: FontWeight.w900,
                                        color: AppTheme.primary)),
                                if (ww.phonetic.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(ww.phonetic,
                                      style: TextStyle(
                                          color: Colors.grey.shade500, fontSize: 16)),
                                ],
                                const SizedBox(height: 32),
                                Text('Tap to reveal',
                                    style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
                              ],
                            ),
                          )
                        : Transform(
                            transform: Matrix4.identity()..rotateY(math.pi),
                            alignment: Alignment.center,
                            child: _buildCardFace(
                              bg: const Color(0xFF4F46E5),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(ww.partOfSpeech.toUpperCase(),
                                      style: const TextStyle(
                                          color: Colors.white54,
                                          fontSize: 11,
                                          letterSpacing: 1.2)),
                                  const SizedBox(height: 16),
                                  Text(ww.definition,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          height: 1.4)),
                                  if (ww.exampleSentence.isNotEmpty) ...[
                                    const SizedBox(height: 20),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      child: Text('"${ww.exampleSentence}"',
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 13,
                                              fontStyle: FontStyle.italic)),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                  );
                },
              ),
            ),
          ),

          // Answer buttons (only shown when flipped)
          AnimatedOpacity(
            opacity: _flipped ? 1 : 0,
            duration: const Duration(milliseconds: 200),
            child: IgnorePointer(
              ignoring: !_flipped,
              child: Padding(
                padding: const EdgeInsets.only(top: 20, bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.error,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () => _answer(false),
                        icon: const Icon(Icons.close_rounded),
                        label: const Text('Still learning'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.secondary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () => _answer(true),
                        icon: const Icon(Icons.check_rounded),
                        label: const Text('Got it!'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardFace({required Widget child, Color? bg}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: bg ?? Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildResults() {
    final pct = _words.isEmpty ? 0.0 : _known / _words.length;
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(pct >= 0.8 ? '🎉' : pct >= 0.5 ? '👍' : '💪',
              style: const TextStyle(fontSize: 72)),
          const SizedBox(height: 20),
          Text(
            pct >= 0.8 ? 'Excellent!' : pct >= 0.5 ? 'Good progress!' : 'Keep going!',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Text(
            '$_known / ${_words.length} words mastered',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _load,
              child: const Text('Practice Again'),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Back to Library'),
          ),
        ],
      ),
    );
  }
}
