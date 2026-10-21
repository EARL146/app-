import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../services/auth_service.dart';
import '../../widgets/animated_burger_assembly.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, this.restoreSession = true});

  final bool restoreSession;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _introController;
  late final Animation<double> _brandReveal;

  @override
  void initState() {
    super.initState();
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4500),
    );
    _brandReveal = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.80, 0.94, curve: Curves.easeOut),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_continueAfterInitialization());
    });
  }

  Future<void> _continueAfterInitialization() async {
    if (widget.restoreSession) {
      final auth = context.read<AuthService>();
      await auth.initialization;
      if (!mounted) return;

      if (auth.isAuthenticated) {
        final route = auth.currentUserRole == 'admin'
            ? '/admin-home'
            : '/customer-home';
        Navigator.of(context).pushReplacementNamed(route);
        return;
      }
    }

    if (MediaQuery.of(context).disableAnimations) {
      _introController.value = 1;
      await Future<void>.delayed(const Duration(milliseconds: 350));
    } else {
      await _introController.forward();
    }

    if (!mounted) return;
    Navigator.of(context)
        .pushReplacementNamed('/customer-home', arguments: true);
  }

  @override
  void dispose() {
    _introController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final markSize = (constraints.maxHeight * 0.39)
                .clamp(160.0, 290.0)
                .toDouble();
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedBurgerAssembly(
                      animation: _introController,
                      size: markSize,
                    ),
                    const SizedBox(height: 8),
                    FadeTransition(
                      opacity: _brandReveal,
                      child: const Text(
                        'BurgerBites',
                        style: TextStyle(
                          color: AppColors.brandRed,
                          fontSize: 27,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
