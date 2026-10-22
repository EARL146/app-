import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../services/auth_service.dart';
import 'animated_brand_button.dart';

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
    barrierColor: const Color(0x88140C08),
    builder: (dialogContext) => Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: AnimatedEntranceCard(
          child: Container(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
            decoration: BoxDecoration(
              gradient: AppColors.warmSurfaceGradient,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: AppColors.brandOrange.withValues(alpha: 0.22),
                width: 1.2,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33140C08),
                  blurRadius: 32,
                  offset: Offset(0, 16),
                ),
                BoxShadow(
                  color: Color(0x1FFF5B22),
                  blurRadius: 20,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.center,
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFEFE6), Color(0xFFFFDFCE)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.brandOrange.withValues(
                              alpha: 0.28,
                            ),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.brandOrange.withValues(
                                alpha: 0.18,
                              ),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.lock_person_rounded,
                          color: AppColors.brandOrange,
                          size: 30,
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.topRight,
                      child: IconButton(
                        tooltip: 'Close',
                        visualDensity: VisualDensity.compact,
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        icon: const Icon(
                          Icons.close_rounded,
                          size: 20,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const BrandGradientBadge(
                  label: 'CUSTOMER ACCOUNT',
                  icon: Icons.lunch_dining_rounded,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Sign in to continue',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign in or create a customer account to $action. You can keep browsing the menu without an account.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 20),
                AnimatedPressScale(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryButtonGradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.brandOrange.withValues(alpha: 0.30),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.of(
                          dialogContext,
                        ).pop(_AccountPromptChoice.register),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: const Icon(
                          Icons.person_add_alt_1_rounded,
                          size: 18,
                        ),
                        label: const Text(
                          'Create account',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                AnimatedPressScale(
                  child: SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(
                        dialogContext,
                      ).pop(_AccountPromptChoice.signIn),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        backgroundColor: AppColors.surface,
                        side: const BorderSide(
                          color: AppColors.border,
                          width: 1.3,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const Icon(
                        Icons.login_rounded,
                        size: 18,
                        color: AppColors.brandOrange,
                      ),
                      label: const Text(
                        'Log in',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    visualDensity: VisualDensity.compact,
                  ),
                  child: const Text(
                    'Not now',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
