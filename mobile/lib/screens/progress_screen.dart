import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../providers/progress_provider.dart';
import '../theme/app_theme.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});
  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProgressProvider>().loadSummary();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Progress')),
      body: Consumer<ProgressProvider>(
        builder: (context, provider, _) {
          if (provider.loading) return const Center(child: CircularProgressIndicator());
          if (provider.error != null) {
            return Center(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('Could not load progress', style: TextStyle(color: Colors.grey.shade600)),
                const SizedBox(height: 12),
                ElevatedButton(onPressed: provider.loadSummary, child: const Text('Retry')),
              ]),
            );
          }
          final summary = provider.summary;
          if (summary == null) {
            return const Center(child: Text('No progress data yet.\nStart learning to track your progress!',
                textAlign: TextAlign.center));
          }
          return _ProgressBody(summary: summary, dueCount: provider.dueForReview);
        },
      ),
    );
  }
}

class _ProgressBody extends StatelessWidget {
  final Map<String, dynamic> summary;
  final int dueCount;
  const _ProgressBody({required this.summary, required this.dueCount});

  @override
  Widget build(BuildContext context) {
    final words     = summary['words']     as List? ?? [];
    final sentences = summary['sentences'] as List? ?? [];

    return RefreshIndicator(
      onRefresh: () => context.read<ProgressProvider>().loadSummary(),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Due for review card ───────────────────────
          _StatCard(
            icon: Icons.alarm_on_rounded,
            label: 'Due for Review',
            value: '$dueCount',
            color: AppTheme.accent,
          ),
          const SizedBox(height: 20),

          Text('Word Mastery', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          _MasterySection(items: words),

          const SizedBox(height: 24),
          Text('Sentence Mastery', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          _MasterySection(items: sentences),

          const SizedBox(height: 24),
          // ── Circular overall progress ────────────────
          _OverallProgress(words: words, sentences: sentences),
        ],
      ),
    );
  }
}

class _MasterySection extends StatelessWidget {
  final List<dynamic> items;
  const _MasterySection({required this.items});

  static const _statusMeta = {
    'new':       {'label': 'New',       'color': Color(0xFF94A3B8)},
    'learning':  {'label': 'Learning',  'color': Color(0xFF60A5FA)},
    'reviewing': {'label': 'Reviewing', 'color': AppTheme.accent},
    'mastered':  {'label': 'Mastered',  'color': AppTheme.secondary},
  };

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Text('No data yet', style: TextStyle(color: Colors.grey.shade500));
    }
    final total = items.fold<int>(0, (sum, e) => sum + ((e['count'] as int?) ?? 0));
    return Column(
      children: _statusMeta.entries.map((entry) {
        final status = entry.key;
        final meta   = entry.value;
        final count  = items.firstWhere(
          (e) => e['status'] == status, orElse: () => {'count': 0})['count'] as int? ?? 0;
        final pct    = total == 0 ? 0.0 : count / total;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(children: [
            SizedBox(
              width: 80,
              child: Text(meta['label'] as String,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            ),
            Expanded(
              child: LinearPercentIndicator(
                lineHeight: 12,
                percent: pct.clamp(0.0, 1.0),
                progressColor: meta['color'] as Color,
                backgroundColor: Colors.grey.shade100,
                barRadius: const Radius.circular(6),
                padding: EdgeInsets.zero,
              ),
            ),
            const SizedBox(width: 10),
            Text('$count', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          ]),
        );
      }).toList(),
    );
  }
}

class _OverallProgress extends StatelessWidget {
  final List<dynamic> words;
  final List<dynamic> sentences;
  const _OverallProgress({required this.words, required this.sentences});

  int _mastered(List<dynamic> list) =>
      list.firstWhere((e) => e['status'] == 'mastered', orElse: () => {'count': 0})['count'] as int? ?? 0;
  int _total(List<dynamic> list) =>
      list.fold<int>(0, (s, e) => s + ((e['count'] as int?) ?? 0));

  @override
  Widget build(BuildContext context) {
    final wMastered = _mastered(words);
    final wTotal    = _total(words);
    final sMastered = _mastered(sentences);
    final sTotal    = _total(sentences);
    final totalMastered = wMastered + sMastered;
    final grandTotal    = wTotal + sTotal;
    final pct = grandTotal == 0 ? 0.0 : totalMastered / grandTotal;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          Text('Overall Mastery',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 20),
          CircularPercentIndicator(
            radius: 70,
            lineWidth: 12,
            percent: pct.clamp(0.0, 1.0),
            center: Text('${(pct * 100).round()}%',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.primary)),
            progressColor: AppTheme.primary,
            backgroundColor: Colors.grey.shade100,
            circularStrokeCap: CircularStrokeCap.round,
          ),
          const SizedBox(height: 16),
          Text('$totalMastered mastered out of $grandTotal items',
              style: TextStyle(color: Colors.grey.shade600)),
        ]),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _StatCard({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(width: 16),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          Text(value, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: color)),
        ]),
      ]),
    );
  }
}
