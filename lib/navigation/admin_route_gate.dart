import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/app_colors.dart';
import '../services/auth_service.dart';

class AdminRouteGate extends StatelessWidget {
  const AdminRouteGate({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, auth, _) {
        if (auth.isInitializing) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (!auth.isAuthenticated || auth.currentUserRole != 'admin') {
          return Scaffold(
            backgroundColor: AppColors.pageBackground,
            body: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.admin_panel_settings_outlined,
                        size: 52,
                        color: AppColors.brandOrange,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Administrator sign-in required',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sign in with an administrator account issued by the BurgerBites server.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: () => Navigator.of(context)
                            .pushNamedAndRemoveUntil('/sign-in', (_) => false),
                        child: const Text('Go to sign in'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }
        return child;
      },
    );
  }
}
