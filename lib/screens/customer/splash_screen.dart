import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../widgets/brand_logo.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, this.restoreSession = true});

  final bool restoreSession;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _welcomeTimer;

  @override
  void initState() {
    super.initState();
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

    final delay = MediaQuery.of(context).disableAnimations
        ? const Duration(milliseconds: 700)
        : const Duration(milliseconds: 2200);
    _welcomeTimer = Timer(delay, () {
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/welcome');
    });
  }

  @override
  void dispose() {
    _welcomeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxHeight < 300;
            final widthLimit = math
                .max(56.0, constraints.maxWidth - 32)
                .toDouble();
            final heightLimit = compact
                ? constraints.maxHeight * .80
                : constraints.maxHeight * .48;
            final wordmarkWidth = math
                .min(350.0, math.min(widthLimit, heightLimit))
                .toDouble();
            final loaderSize = compact
                ? math.max(24.0, constraints.maxHeight * .25).toDouble()
                : math.min(156.0, constraints.maxHeight * .21).toDouble();
            final logoTop = constraints.maxHeight * (compact ? .06 : .08);
            final loaderTop = constraints.maxHeight * (compact ? .56 : .44);

            return Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                Positioned(
                  top: logoTop,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: BurgerBitesWordmark(
                      width: wordmarkWidth,
                      animate: true,
                    ),
                  ),
                ),
                Positioned(
                  top: loaderTop,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Semantics(
                      label: 'Loading Burger Bites',
                      child: SizedBox.square(
                        dimension: loaderSize,
                        child: const CircularProgressIndicator(
                          strokeWidth: 10,
                          strokeCap: StrokeCap.round,
                          color: Colors.black,
                          backgroundColor: Color(0xFFECEDEF),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: -18,
                  top: constraints.maxHeight * .10,
                  child: Transform.rotate(
                    angle: -.34,
                    child: Icon(
                      Icons.fastfood_outlined,
                      size: 54,
                      color: Colors.black.withValues(alpha: .24),
                    ),
                  ),
                ),
                Positioned(
                  right: -20,
                  top: constraints.maxHeight * .04,
                  child: Transform.rotate(
                    angle: .22,
                    child: Icon(
                      Icons.local_pizza_outlined,
                      size: 56,
                      color: Colors.black.withValues(alpha: .24),
                    ),
                  ),
                ),
                Positioned(
                  left: -15,
                  bottom: constraints.maxHeight * .13,
                  child: Transform.rotate(
                    angle: .46,
                    child: Icon(
                      Icons.local_cafe_outlined,
                      size: 62,
                      color: Colors.black.withValues(alpha: .20),
                    ),
                  ),
                ),
                Positioned(
                  right: -19,
                  bottom: constraints.maxHeight * .05,
                  child: Transform.rotate(
                    angle: -.28,
                    child: Icon(
                      Icons.fastfood_outlined,
                      size: 58,
                      color: Colors.black.withValues(alpha: .22),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
