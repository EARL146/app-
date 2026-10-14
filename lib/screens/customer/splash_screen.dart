import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../services/auth_service.dart';
import '../../widgets/brand_logo.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, this.restoreSession = true});

  final bool restoreSession;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();
    _navigationTimer = Timer(const Duration(milliseconds: 1400), () {
      _continueAfterInitialization();
    });
  }

  Future<void> _continueAfterInitialization() async {
    if (!widget.restoreSession) {
      if (mounted) Navigator.of(context).pushReplacementNamed('/greetings');
      return;
    }
    final auth = context.read<AuthService>();
    await auth.initialization;
    if (!mounted) return;
    final route = auth.isAuthenticated
        ? auth.currentUserRole == 'admin'
              ? '/admin-home'
              : '/customer-home'
        : '/greetings';
    Navigator.of(context).pushReplacementNamed(route);
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const BrandLogo(width: 250, height: 250),
              const SizedBox(height: 8),
              const Text(
                'BurgerBites',
                style: TextStyle(
                  color: AppColors.brandRed,
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 28),
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: AppColors.brandOrange,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
