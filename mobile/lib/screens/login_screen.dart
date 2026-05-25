import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey    = GlobalKey<FormState>();
  final _emailCtrl  = TextEditingController();
  final _passCtrl   = TextEditingController();
  bool _obscure     = true;
  bool _loading     = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });

    // TODO: replace with real API call to your auth endpoint
    await Future.delayed(const Duration(milliseconds: 900)); // simulate network

    // For now: accept any valid email + password ≥ 6 chars
    final ok = _emailCtrl.text.contains('@') && _passCtrl.text.length >= 6;

    if (!mounted) return;
    if (ok) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_logged_in', true);
      await prefs.setString('user_email', _emailCtrl.text.trim());
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      setState(() {
        _error = 'Invalid email or password. Please try again.';
        _loading = false;
      });
    }
  }

  Future<void> _guestLogin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', true);
    await prefs.setString('user_email', 'guest');
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

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
              // ── Top hero ───────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
                child: Column(
                  children: [
                    const Text('📚', style: TextStyle(fontSize: 52)),
                    const SizedBox(height: 10),
                    const Text('WordWise',
                        style: TextStyle(
                            color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 6),
                    Text('Welcome back! Sign in to continue.',
                        style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 14)),
                  ],
                ),
              ),

              // ── White card with form ───────────────
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                  ),
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                  child: SingleChildScrollView(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Sign In',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w800)),
                          const SizedBox(height: 24),

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
                          const SizedBox(height: 16),

                          // Password
                          _Label('Password'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _passCtrl,
                            obscureText: _obscure,
                            decoration: _inputDeco('••••••••', Icons.lock_outline).copyWith(
                              suffixIcon: IconButton(
                                icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                    color: Colors.grey.shade400),
                                onPressed: () => setState(() => _obscure = !_obscure),
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Please enter your password';
                              if (v.length < 6) return 'Password must be at least 6 characters';
                              return null;
                            },
                          ),

                          // Forgot password
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {},
                              child: const Text('Forgot password?',
                                  style: TextStyle(color: AppTheme.primary, fontSize: 13)),
                            ),
                          ),

                          // Error message
                          if (_error != null)
                            Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: AppTheme.error.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppTheme.error.withOpacity(0.3)),
                              ),
                              child: Row(children: [
                                const Icon(Icons.error_outline, color: AppTheme.error, size: 18),
                                const SizedBox(width: 8),
                                Expanded(child: Text(_error!,
                                    style: const TextStyle(color: AppTheme.error, fontSize: 13))),
                              ]),
                            ),

                          // Sign in button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _loading ? null : _login,
                              child: _loading
                                  ? const SizedBox(
                                      height: 20, width: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2.5, color: Colors.white))
                                  : const Text('Sign In'),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Divider
                          Row(children: [
                            Expanded(child: Divider(color: Colors.grey.shade300)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text('or', style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
                            ),
                            Expanded(child: Divider(color: Colors.grey.shade300)),
                          ]),
                          const SizedBox(height: 12),

                          // Continue as guest
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _guestLogin,
                              icon: const Text('👤'),
                              label: const Text('Continue as Guest'),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppTheme.primary),
                                foregroundColor: AppTheme.primary,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Sign up link
                          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Text("Don't have an account? ",
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                            GestureDetector(
                              onTap: () => Navigator.push(context,
                                  MaterialPageRoute(builder: (_) => const RegisterScreen())),
                              child: const Text('Sign Up',
                                  style: TextStyle(
                                      color: AppTheme.primary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14)),
                            ),
                          ]),
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

  InputDecoration _inputDeco(String hint, IconData icon) => InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.grey.shade400, size: 20),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.error),
        ),
      );
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF374151)));
}
