import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

enum _SignInChoice { signIn, createAccount, notNow }

/// Returns true if the user is already signed in.
/// Otherwise shows a "Sign in required" popup and returns false.
/// Choosing Sign In / Create Account navigates to the respective page.
Future<bool> ensureSignedIn(BuildContext context, {String action = 'this'}) async {
  final auth = context.read<AuthProvider>();
  if (auth.isAuthenticated) return true;

  final choice = await showDialog<_SignInChoice>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Sign in required'),
      content: Text(
        'Create a free account to save $action to your profile. '
        'As a guest, nothing is saved on the server.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, _SignInChoice.notNow),
          child: const Text('Not Now'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, _SignInChoice.createAccount),
          child: const Text('Create Account'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, _SignInChoice.signIn),
          child: const Text('Sign In'),
        ),
      ],
    ),
  );

  if (!context.mounted) return false;
  switch (choice) {
    case _SignInChoice.signIn:
      context.push('/login');
      break;
    case _SignInChoice.createAccount:
      context.push('/signup');
      break;
    case _SignInChoice.notNow:
    case null:
      break;
  }
  return false;
}
