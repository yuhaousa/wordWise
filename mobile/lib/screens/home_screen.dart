import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/progress_provider.dart';
import '../theme/app_theme.dart';
import 'flashcard_screen.dart';
import 'sentence_builder_screen.dart';
import 'quiz_screen.dart';
import 'progress_screen.dart';
import 'settings_screen.dart';
import 'wrong_words_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProgressProvider>().loadSummary();
    });
  }

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressProvider>();

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── App bar ───────────────────────────────────
            SliverAppBar(
              expandedHeight: 140,
              pinned: true,
              actions: [
                IconButton(
                  icon: const Icon(Icons.settings_outlined, color: Colors.white),
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const SettingsScreen())),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.primary, AppTheme.primaryLight],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 60, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Hello, Learner! 👋',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text('Keep up the streak!',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: Colors.white70)),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // ── Due items banner ───────────────────
                  if (!progress.loading && (progress.dueForReview) > 0)
                    _DueBanner(dueCount: progress.dueForReview),

                  const SizedBox(height: 20),
                  Text('What do you want to practice?',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),

                  // ── Feature cards grid ─────────────────
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.95,
                    children: [
                      _FeatureCard(
                        icon: Icons.style_rounded,
                        label: 'Flashcards',
                        subtitle: 'Learn new words',
                        color: const Color(0xFF4F46E5),
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const FlashcardScreen())),
                      ),
                      _FeatureCard(
                        icon: Icons.format_list_bulleted_rounded,
                        label: 'Sentence\nBuilder',
                        subtitle: 'Arrange words',
                        color: const Color(0xFF10B981),
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const SentenceBuilderScreen())),
                      ),
                      _FeatureCard(
                        icon: Icons.quiz_rounded,
                        label: 'Quiz',
                        subtitle: 'Test yourself',
                        color: const Color(0xFFF59E0B),
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const QuizScreen())),
                      ),
                      _FeatureCard(
                        icon: Icons.bar_chart_rounded,
                        label: 'Progress',
                        subtitle: 'Track mastery',
                        color: const Color(0xFFEF4444),
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const ProgressScreen())),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ── Wrong Words Library banner ──────────
                  _WrongWordsBanner(),

                  const SizedBox(height: 32),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Wrong Words Library banner ────────────────────────────
class _WrongWordsBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.push(
          context, MaterialPageRoute(builder: (_) => const WrongWordsScreen())),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFEF4444), Color(0xFFF97316)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFEF4444).withOpacity(0.25),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(children: [
          const Text('❌', style: TextStyle(fontSize: 28)),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Wrong Words Library',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
                SizedBox(height: 2),
                Text('Review words you got wrong',
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 16),
        ]),
      ),
    );
  }
}

class _DueBanner extends StatelessWidget {
  final int dueCount;
  const _DueBanner({required this.dueCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.accent.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.accent.withOpacity(0.4)),
      ),
      child: Row(children: [
        const Icon(Icons.notifications_active_rounded, color: AppTheme.accent),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            '$dueCount item${dueCount > 1 ? 's' : ''} due for review',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => const FlashcardScreen(reviewMode: true))),
          child: const Text('Review'),
        ),
      ]),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withOpacity(0.75)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: Colors.white, size: 36),
              const Spacer(),
              Text(label,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700, height: 1.2)),
              const SizedBox(height: 4),
              Text(subtitle,
                  style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}
