import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/quiz_provider.dart';
import '../services/audio_service.dart';
import '../theme/app_theme.dart';

class QuizScreen extends StatelessWidget {
  const QuizScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => QuizProvider(),
      child: const _QuizBody(),
    );
  }
}

class _QuizBody extends StatelessWidget {
  const _QuizBody();

  @override
  Widget build(BuildContext context) {
    final quiz = context.watch<QuizProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Quiz')),
      body: switch (quiz.state) {
        QuizState.idle     => _StartScreen(),
        QuizState.loading  => const Center(child: CircularProgressIndicator()),
        QuizState.active   => _QuestionScreen(),
        QuizState.reviewing => _QuestionScreen(),
        QuizState.finished => _ResultScreen(),
        QuizState.error    => Center(child: Text('Error: ${quiz.error}')),
      },
    );
  }
}

// ── Start screen ──────────────────────────────────────────
class _StartScreen extends StatefulWidget {
  const _StartScreen();
  @override
  State<_StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<_StartScreen> {
  String? _level;

  @override
  void initState() {
    super.initState();
    // Load the level saved in Settings — no selector shown here
    SharedPreferences.getInstance().then((prefs) {
      final saved = prefs.getString('user_level');
      if (!mounted) return;
      setState(() => _level = saved);
      context.read<QuizProvider>().setLevel(saved);
    });
  }

  @override
  Widget build(BuildContext context) {
    final quiz = context.read<QuizProvider>();
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.quiz_rounded, size: 80, color: AppTheme.primary),
            const SizedBox(height: 24),
            Text('Ready to test your English?',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
                textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Text('10 questions · Multiple types',
                style: TextStyle(color: Colors.grey.shade600)),
            if (_level != null) ...[
              const SizedBox(height: 12),
              // Display-only badge — not a selector
              Chip(
                label: Text('Level $_level'),
                backgroundColor: AppTheme.cefrColor(_level!),
              ),
            ],
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => quiz.startQuiz(),
                child: const Text('Start Quiz'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Question screen ───────────────────────────────────────
class _QuestionScreen extends StatelessWidget {
  const _QuestionScreen();

  @override
  Widget build(BuildContext context) {
    final quiz = context.watch<QuizProvider>();
    final q    = quiz.currentQuestion;
    if (q == null) return const SizedBox.shrink();

    final reviewing = quiz.state == QuizState.reviewing;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress
          LinearProgressIndicator(
            value: (quiz.currentIndex + 1) / quiz.questions.length,
            backgroundColor: Colors.grey.shade200,
            color: AppTheme.primary,
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Q ${quiz.currentIndex + 1} of ${quiz.questions.length}',
                  style: const TextStyle(color: Colors.grey)),
              Chip(
                label: Text(q.cefrLevel),
                backgroundColor: AppTheme.cefrColor(q.cefrLevel),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Question card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_typeLabel(q.type.value),
                      style: TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12)),
                  const SizedBox(height: 12),
                  Text(q.question,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, height: 1.4)),
                  if (q.type.value == 'spelling')
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: IconButton(
                        icon: const Icon(Icons.volume_up_rounded, color: AppTheme.primary),
                        onPressed: () => AudioService().speak(q.correctAnswer, slow: true),
                      ),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Options
          Expanded(
            child: ListView.separated(
              itemCount: q.options.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final opt = q.options[i];
                Color? bg;
                Color? border;

                if (reviewing) {
                  if (opt == q.correctAnswer) {
                    bg = AppTheme.secondary.withOpacity(0.15);
                    border = AppTheme.secondary;
                  } else if (opt == quiz.selectedOption && !(quiz.isCorrect ?? true)) {
                    bg = AppTheme.error.withOpacity(0.1);
                    border = AppTheme.error;
                  }
                }

                return GestureDetector(
                  onTap: reviewing ? null : () => quiz.submitAnswer(opt),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: bg ?? Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: border ?? Colors.grey.shade300, width: 2),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(child: Text(opt, style: const TextStyle(fontSize: 15))),
                        if (reviewing && opt == q.correctAnswer)
                          const Icon(Icons.check_circle, color: AppTheme.secondary),
                        if (reviewing && opt == quiz.selectedOption && !(quiz.isCorrect ?? true))
                          const Icon(Icons.cancel, color: AppTheme.error),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          if (reviewing)
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: quiz.nextQuestion,
                  child: Text(quiz.currentIndex < quiz.questions.length - 1
                      ? 'Next Question →'
                      : 'See Results'),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _typeLabel(String type) {
    return switch (type) {
      'word_definition'   => '📖 DEFINITION',
      'fill_blank'        => '✏️ FILL IN THE BLANK',
      'sentence_reorder'  => '🔀 REORDER',
      'choose_word'       => '🎯 CHOOSE THE WORD',
      'spelling'          => '🔤 SPELLING',
      _                   => type.toUpperCase(),
    };
  }
}

// ── Result screen ─────────────────────────────────────────
class _ResultScreen extends StatelessWidget {
  const _ResultScreen();

  @override
  Widget build(BuildContext context) {
    final quiz = context.watch<QuizProvider>();
    final pct  = quiz.pct;

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            pct >= 0.8 ? '🎉' : pct >= 0.5 ? '👍' : '💪',
            style: const TextStyle(fontSize: 72),
          ),
          const SizedBox(height: 20),
          Text(
            pct >= 0.8 ? 'Excellent!' : pct >= 0.5 ? 'Good job!' : 'Keep practicing!',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Text(
            '${quiz.score} / ${quiz.questions.length} correct  (${(pct * 100).round()}%)',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 36),

          // Review answers
          Expanded(
            child: ListView.builder(
              itemCount: quiz.answers.length,
              itemBuilder: (_, i) {
                final a = quiz.answers[i];
                return ListTile(
                  leading: Icon(a.correct ? Icons.check_circle : Icons.cancel,
                      color: a.correct ? AppTheme.secondary : AppTheme.error),
                  title: Text(a.question.question,
                      style: const TextStyle(fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
                  subtitle: a.correct
                      ? null
                      : Text('Correct: ${a.question.correctAnswer}',
                          style: const TextStyle(color: AppTheme.secondary, fontSize: 12)),
                );
              },
            ),
          ),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => quiz.startQuiz(),
              child: const Text('Play Again'),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () { quiz.reset(); Navigator.pop(context); },
            child: const Text('Back to Home'),
          ),
        ],
      ),
    );
  }
}
