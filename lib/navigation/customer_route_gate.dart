import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../widgets/customer_account_prompt.dart';

/// Keeps account-owned customer pages closed until a customer signs in.
///
/// The check lives at the route boundary so every entry point (including a
/// direct named-route navigation) follows the same access rule.
class CustomerRouteGate extends StatefulWidget {
  const CustomerRouteGate({
    required this.child,
    required this.action,
    super.key,
  });

  final Widget child;
  final String action;

  @override
  State<CustomerRouteGate> createState() => _CustomerRouteGateState();
}

class _CustomerRouteGateState extends State<CustomerRouteGate> {
  bool _isChecking = false;
  bool _isAuthorized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _requestAccess());
  }

  Future<void> _requestAccess() async {
    if (!mounted || _isChecking) return;
    setState(() => _isChecking = true);
    final allowed = await requireCustomerAccount(
      context,
      action: widget.action,
    );
    if (!mounted) return;
    setState(() {
      _isChecking = false;
      _isAuthorized = allowed;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isAuthorized) return widget.child;

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        title: const Text('Sign in required'),
        leading: IconButton(
          tooltip: 'Go back',
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Icon(
                      _isChecking
                          ? Icons.lock_clock_rounded
                          : Icons.lock_person_rounded,
                      color: AppColors.brandOrange,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _isChecking
                        ? 'Checking your account'
                        : 'Sign in to continue',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isChecking
                        ? 'Your account is required to ${widget.action}.'
                        : 'Log in or create a customer account to ${widget.action}.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (_isChecking)
                    const CircularProgressIndicator()
                  else ...[
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton.icon(
                        onPressed: _requestAccess,
                        icon: const Icon(Icons.login_rounded, size: 18),
                        label: const Text('Log in or create account'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      child: const Text('Go back'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
