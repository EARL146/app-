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
            final compact = constraints.maxHeight < 320;
            final showBrand = constraints.maxHeight >= 48;
            final brandFontSize = compact
                ? (constraints.maxHeight * 0.2).clamp(12.0, 20.0).toDouble()
                : 27.0;
            final brandGap = showBrand ? (compact ? 4.0 : 8.0) : 0.0;
            final availableMarkSize =
                (constraints.maxHeight -
                        (showBrand ? brandFontSize + brandGap : 0))
                    .clamp(0.0, 290.0);
            final markSize = (constraints.maxHeight * 0.39)
                .clamp(0.0, availableMarkSize)
                .toDouble();
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedBurgerAssembly(
                      animation: _introController,
                      size: markSize,
                    ),
                    if (showBrand) ...[
                      SizedBox(height: brandGap),
                      FadeTransition(
                        opacity: _brandReveal,
                        child: Text(
                          'BurgerBites',
                          style: TextStyle(
                            color: AppColors.brandRed,
                            fontSize: brandFontSize,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ],
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
