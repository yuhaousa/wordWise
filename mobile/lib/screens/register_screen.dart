import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _nameCtrl  = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  final _confCtrl  = TextEditingController();
  bool _obscurePass = true;
  bool _obscureConf = true;
  bool _loading     = false;

  @override
  void dispose() {
    _nameCtrl.dispose(); _emailCtrl.dispose();
    _passCtrl.dispose(); _confCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    // TODO: send to real API
    await Future.delayed(const Duration(milliseconds: 900));

    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', true);
    await prefs.setString('user_email', _emailCtrl.text.trim());
    await prefs.setString('user_name',  _nameCtrl.text.trim());
    // Level is set later in Settings — default to B1 on first sign-up
    if (!prefs.containsKey('user_level')) {
      await prefs.setString('user_level', 'B1');
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (_) => false,
    );
  }

  InputDecoration _inputDeco(String hint, IconData icon) => InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.grey.shade400, size: 20),
        filled: true, fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.primary, width: 2)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.error)),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF3730A3), Color(0xFF4F46E5)],
            begin: Alignment.topCenter,
            end: Alignment.center,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── Top bar ────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 12, 24, 24),
                child: Row(children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
                  ),
                  const Spacer(),
                  const Text('📚', style: TextStyle(fontSize: 28)),
                  const Spacer(),
                  const SizedBox(width: 48),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 28),
                child: Column(children: [
                  const Text('Create Account',
                      style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 6),
                  Text('Start your learning journey today',
                      style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 13)),
                ]),
              ),

              // ── Form card ──────────────────────────
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                  ),
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
                  child: SingleChildScrollView(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Name
                          _Label('Full Name'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _nameCtrl,
                            textCapitalization: TextCapitalization.words,
                            decoration: _inputDeco('Your name', Icons.person_outline),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your name' : null,
                          ),
                          const SizedBox(height: 14),

                          // Email
                          _Label('Email'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            decoration: _inputDeco('you@example.com', Icons.email_outlined),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Please enter your email';
                              if (!v.contains('@')) return 'Enter a valid email';
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),

                          // Password
                          _Label('Password'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _passCtrl,
                            obscureText: _obscurePass,
                            decoration: _inputDeco('At least 6 characters', Icons.lock_outline).copyWith(
                              suffixIcon: IconButton(
                                icon: Icon(_obscurePass ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                    color: Colors.grey.shade400),
                                onPressed: () => setState(() => _obscurePass = !_obscurePass),
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Please enter a password';
                              if (v.length < 6) return 'Must be at least 6 characters';
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),

                          // Confirm password
                          _Label('Confirm Password'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _confCtrl,
                            obscureText: _obscureConf,
                            decoration: _inputDeco('Repeat password', Icons.lock_outline).copyWith(
                              suffixIcon: IconButton(
                                icon: Icon(_obscureConf ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                    color: Colors.grey.shade400),
                                onPressed: () => setState(() => _obscureConf = !_obscureConf),
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Please confirm your password';
                              if (v != _passCtrl.text) return 'Passwords do not match';
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),

                          // Create account button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _loading ? null : _register,
                              child: _loading
                                  ? const SizedBox(height: 20, width: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                                  : const Text('Create Account'),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Back to login
                          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Text('Already have an account? ',
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: const Text('Sign In',
                                  style: TextStyle(color: AppTheme.primary,
                                      fontWeight: FontWeight.w700, fontSize: 14)),
                            ),
                          ]),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF374151)));
}
