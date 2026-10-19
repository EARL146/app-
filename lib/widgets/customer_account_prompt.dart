import 'package:flutter/material.dart';

import '../services/auth_service.dart';

enum _AccountPromptChoice { signIn, register }

/// Ensures customer-only actions require an authenticated customer session.
/// Returns true after an existing or newly created customer session is ready.
Future<bool> requireCustomerAccount(
  BuildContext context, {
  required String action,
}) async {
  final auth = AuthService();
  await auth.initialization;
  if (!context.mounted) return false;

  if (auth.isAuthenticated) {
    if (auth.currentUserRole == 'customer') return true;
    _showAccountMessage(
      context,
      'A customer account is required to $action. Sign out of the admin account first.',
    );
    return false;
  }

  final choice = await showDialog<_AccountPromptChoice>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Sign in to continue'),
      content: Text(
        'Sign in or create a customer account to $action. You can keep browsing the menu without an account.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Not now'),
        ),
        TextButton(
          onPressed: () =>
              Navigator.of(dialogContext).pop(_AccountPromptChoice.signIn),
          child: const Text('Log in'),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.of(dialogContext).pop(_AccountPromptChoice.register),
          child: const Text('Create account'),
        ),
      ],
    ),
  );

  if (!context.mounted || choice == null) return false;
  final route = choice == _AccountPromptChoice.signIn
      ? '/sign-in'
      : '/register';
  final authenticated = await Navigator.of(context)
      .pushNamed<bool>(route, arguments: true);
  if (!context.mounted || authenticated != true) return false;
  return auth.isAuthenticated && auth.currentUserRole == 'customer';
}

void _showAccountMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
  );
}
