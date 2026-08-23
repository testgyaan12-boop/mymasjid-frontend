import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  bool _stepOtp = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSendOtp() async {
    if (!_formKey.currentState!.validate()) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create Account?'),
        content: Text(
          'Name: ${_nameCtrl.text.trim()}\nEmail: ${_emailCtrl.text.trim()}\n'
          '${_phoneCtrl.text.trim().isEmpty ? '' : 'Mobile: ${_phoneCtrl.text.trim()}\n'}\nCreate account with these details?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.secondary),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Create', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _loading = true);
    final auth = context.read<AuthProvider>();
    final ok = await auth.signup(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
      phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
    );
    setState(() => _loading = false);
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account created! Please login.')),
      );
      if (!context.mounted) return;
      context.go('/login');
    } else {
      final msg = context.read<AuthProvider>().error ?? 'Failed to create account';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Theme.of(context).colorScheme.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 40),
                Icon(Icons.person_add, size: 64, color: Theme.of(context).colorScheme.secondary),
                const SizedBox(height: 16),
                Text('Create Account', style: Theme.of(context).textTheme.displayMedium),
                const SizedBox(height: 8),
                Text('Join the Noor Al Masjid community', style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                )),
                const SizedBox(height: 32),

                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person)),
                  validator: (v) => v == null || v.isEmpty ? 'Enter name' : null,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _emailCtrl,
                  decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email)),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Enter email';
                    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                    if (!emailRegex.hasMatch(v.trim())) return 'Enter valid email';
                    if (v.trim().length > 150) return 'Email too long';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _phoneCtrl,
                  decoration: const InputDecoration(labelText: 'Mobile (optional)', prefixIcon: Icon(Icons.phone), hintText: '10 digits'),
                  keyboardType: TextInputType.phone,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return null;
                    final p = v.trim().replaceAll(RegExp(r'[\s-]'), '');
                    final phoneRegex = RegExp(r'^\+?[0-9]{10,15}$');
                    if (!phoneRegex.hasMatch(p)) return 'Enter valid 10-digit mobile';
                    if (p.replaceAll('+', '').length < 10) return 'Mobile must be 10 digits';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

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
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Enter password';
                    if (v.length < 8) return 'Min 8 characters';
                    if (!RegExp(r'[A-Z]').hasMatch(v)) return 'Need 1 uppercase';
                    if (!RegExp(r'[a-z]').hasMatch(v)) return 'Need 1 lowercase';
                    if (!RegExp(r'[0-9]').hasMatch(v)) return 'Need 1 number';
                    if (!RegExp(r'[@$!%*?&]').hasMatch(v)) return r'Need 1 special @$!%*?&';
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _handleSendOtp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      foregroundColor: Theme.of(context).colorScheme.onSecondary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _loading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Create Account', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                  ),
                ),

                const SizedBox(height: 16),

                TextButton(
                  onPressed: () => context.push('/login'),
                  child: const Text('Already have an account? Sign In'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
