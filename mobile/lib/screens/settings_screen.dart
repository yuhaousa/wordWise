import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _name        = 'Learner';
  String _email       = '';
  String _level       = 'B1';
  bool   _audioOn     = true;
  bool   _notifOn     = true;
  bool   _darkMode    = false;
  double _speechRate  = 0.45;

  final List<String> _levels = ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'];

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _name       = prefs.getString('user_name')    ?? 'Learner';
      _email      = prefs.getString('user_email')   ?? '';
      _level      = prefs.getString('user_level')   ?? 'B1';
      _audioOn    = prefs.getBool('audio_on')       ?? true;
      _notifOn    = prefs.getBool('notif_on')       ?? true;
      _speechRate = prefs.getDouble('speech_rate')  ?? 0.45;
    });
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_level',  _level);
    await prefs.setBool('audio_on',      _audioOn);
    await prefs.setBool('notif_on',      _notifOn);
    await prefs.setDouble('speech_rate', _speechRate);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings saved ✓'), backgroundColor: AppTheme.secondary),
    );
  }

  Future<void> _signOut() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', false);
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('Save', style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.primary)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // ── Profile card ────────────────────────
          _ProfileCard(name: _name, email: _email, level: _level),
          const SizedBox(height: 20),

          // ── Learning level ───────────────────────
          _SectionTitle('Learning Level'),
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('CEFR Level', style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: _levels.map((lvl) {
                    final sel = _level == lvl;
                    return GestureDetector(
                      onTap: () => setState(() => _level = lvl),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: sel ? AppTheme.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: sel ? AppTheme.primary : Colors.grey.shade300,
                          ),
                        ),
                        child: Text(lvl,
                            style: TextStyle(
                              color: sel ? Colors.white : Colors.grey.shade600,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            )),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Audio settings ───────────────────────
          _SectionTitle('Audio & Pronunciation'),
          _Card(
            child: Column(
              children: [
                _ToggleRow(
                  icon: Icons.volume_up_rounded,
                  label: 'Enable Audio',
                  subtitle: 'Text-to-speech for words and sentences',
                  value: _audioOn,
                  onChanged: (v) => setState(() => _audioOn = v),
                ),
                const Divider(height: 24),
                Row(children: [
                  const Icon(Icons.speed_rounded, color: AppTheme.primary, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Speech Speed', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        Text(
                          _speechRate <= 0.3 ? 'Slow' : _speechRate <= 0.5 ? 'Normal' : 'Fast',
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 120,
                    child: Slider(
                      value: _speechRate,
                      min: 0.2,
                      max: 0.8,
                      divisions: 6,
                      activeColor: AppTheme.primary,
                      onChanged: _audioOn ? (v) => setState(() => _speechRate = v) : null,
                    ),
                  ),
                ]),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Notifications ────────────────────────
          _SectionTitle('Notifications'),
          _Card(
            child: _ToggleRow(
              icon: Icons.notifications_rounded,
              label: 'Daily Review Reminders',
              subtitle: 'Get notified when items are due for review',
              value: _notifOn,
              onChanged: (v) => setState(() => _notifOn = v),
            ),
          ),
          const SizedBox(height: 16),

          // ── App ──────────────────────────────────
          _SectionTitle('App'),
          _Card(
            child: Column(
              children: [
                _NavRow(icon: Icons.info_outline_rounded, label: 'About WordWise',
                    onTap: () => _showAbout(context)),
                const Divider(height: 1),
                _NavRow(icon: Icons.privacy_tip_outlined, label: 'Privacy Policy', onTap: () {}),
                const Divider(height: 1),
                _NavRow(icon: Icons.star_outline_rounded, label: 'Rate the App', onTap: () {}),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Sign out ─────────────────────────────
          _Card(
            child: _NavRow(
              icon: Icons.logout_rounded,
              label: 'Sign Out',
              onTap: _signOut,
              color: AppTheme.error,
            ),
          ),
          const SizedBox(height: 32),
          Center(
            child: Text('WordWise v1.0.0',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('About WordWise', style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text(
            'WordWise is an English learning app for teens and students, featuring '
            'flashcards, sentence builder, quizzes, and spaced-repetition progress tracking.\n\n'
            'Version 1.0.0'),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

// ── Small reusable widgets ────────────────────────────────

class _ProfileCard extends StatelessWidget {
  final String name, email, level;
  const _ProfileCard({required this.name, required this.email, required this.level});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.primaryLight],
            begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: Colors.white.withOpacity(0.25),
          child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'L',
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
            if (email.isNotEmpty && email != 'guest')
              Text(email, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ]),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(99),
          ),
          child: Text(level, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        ),
      ]),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(text,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
              color: AppTheme.primary, letterSpacing: .04)));
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: child);
}

class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final String label, subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ToggleRow({required this.icon, required this.label, required this.subtitle,
      required this.value, required this.onChanged});
  @override
  Widget build(BuildContext context) => Row(children: [
        Icon(icon, color: AppTheme.primary, size: 22),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          Text(subtitle, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
        ])),
        Switch(value: value, onChanged: onChanged, activeColor: AppTheme.primary),
      ]);
}

class _NavRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  const _NavRow({required this.icon, required this.label, required this.onTap, this.color});
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(children: [
        Icon(icon, color: color ?? AppTheme.primary, size: 22),
        const SizedBox(width: 12),
        Expanded(child: Text(label,
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14,
                color: color ?? AppTheme.textPrimary))),
        Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400, size: 20),
      ]),
    ),
  );
}
