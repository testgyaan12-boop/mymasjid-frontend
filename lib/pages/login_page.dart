import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/auth_provider.dart';
import '../providers/masjid_provider.dart';
import '../services/biometric_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final auth = context.read<AuthProvider>();
    final ok = await auth.login(_emailCtrl.text.trim(), _passwordCtrl.text);
    setState(() => _loading = false);
    if (ok && mounted) {
      final prefs = await SharedPreferences.getInstance();
      final hasMasjid = prefs.getString('current_masjid_id') != null;
      if (!context.mounted) return;
      if (hasMasjid) {
        await context.read<MasjidProvider>().loadSavedMasjid();
        if (!context.mounted) return;
        context.go('/');
      } else {
        context.go('/masjid-select');
      }
    }
  }

  Future<void> _handleFingerprint() async {
    final bio = BiometricService();
    if (!await bio.isAvailable()) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Biometric not available on this device')),
      );
      return;
    }
    final authenticated = await bio.authenticate();
    if (authenticated && mounted) {
      // For biometric login, try auto-login with stored token
      final auth = context.read<AuthProvider>();
      await auth.tryAutoLogin();
      if (auth.isAuthenticated && mounted) {
        await context.read<MasjidProvider>().loadSavedMasjid();
        if (mounted) context.go('/');
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No saved session — sign in once with email/password first, then fingerprint works next time.')),
        );
      }
    }
  }

  Future<void> _continueAsGuest() async {
    final prefs = await SharedPreferences.getInstance();
    final hasMasjid = prefs.getString('current_masjid_id') != null;
    if (!context.mounted) return;
    if (hasMasjid) {
      await context.read<MasjidProvider>().loadSavedMasjid();
      if (!context.mounted) return;
      context.go('/');
    } else {
      context.go('/masjid-select');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 24),
                Icon(Icons.mosque, size: 56, color: Theme.of(context).colorScheme.secondary),
                const SizedBox(height: 12),
                Text('Welcome Back', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text('Sign in to your account', style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                )),
                const SizedBox(height: 28),

                TextFormField(
                  controller: _emailCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => v == null || v.isEmpty ? 'Enter email' : null,
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _passwordCtrl,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  obscureText: _obscure,
                  validator: (v) => v == null || v.isEmpty ? 'Enter password' : null,
                ),
                const SizedBox(height: 8),

                if (auth.error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(auth.error!, style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12)),
                  ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      foregroundColor: Theme.of(context).colorScheme.onSecondary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _loading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Sign In', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                  ),
                ),

                const SizedBox(height: 12),

                if (BiometricService().isSupported)
                  OutlinedButton.icon(
                    onPressed: _handleFingerprint,
                    icon: const Icon(Icons.fingerprint),
                    label: const Text('Sign In with Fingerprint'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                    ),
                  ),

                const SizedBox(height: 16),

                TextButton(
                  onPressed: () => context.push('/signup'),
                  child: const Text("Don't have an account? Sign Up"),
                ),

                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: Divider(color: Theme.of(context).dividerColor)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('OR', style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      )),
                    ),
                    Expanded(child: Divider(color: Theme.of(context).dividerColor)),
                  ],
                ),
                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonalIcon(
                    onPressed: _continueAsGuest,
                    icon: const Icon(Icons.mosque_rounded),
                    label: const Text('Continue with Masjid', style: TextStyle(fontWeight: FontWeight.w900)),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Browse as guest — see prayer times & updates without an account.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
