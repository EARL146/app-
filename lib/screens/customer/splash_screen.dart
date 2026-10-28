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

  Widget _doodle({
    required String asset,
    required double width,
    required double height,
    double opacity = 0.92,
  }) {
    return Opacity(
      opacity: opacity,
      child: SizedBox(
        width: width,
        height: height,
        child: DecoratedBox(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(asset),
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final availableHeight = constraints.maxHeight;
            final availableWidth = constraints.maxWidth;
            final isShort = availableHeight < 300;
            final showDoodles = availableHeight >= 200 && availableWidth >= 200;

            final maxLogoWidth = math
                .min(
                  330.0,
                  math.min(
                    availableWidth - 32,
                    availableHeight * (isShort ? 0.70 : 0.38),
                  ),
                )
                .clamp(60.0, 330.0);

            final loaderSize = isShort
                ? math.max(24.0, availableHeight * 0.25)
                : math.min(160.0, availableHeight * 0.22).clamp(80.0, 160.0);

            final logoTop = availableHeight * (isShort ? 0.05 : 0.07);
            final loaderTop = availableHeight * (isShort ? 0.54 : 0.40);

            return Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                if (showDoodles) ...[
                  // Top-left bottle doodle
                  Positioned(
                    top: availableHeight * 0.04,
                    left: -4,
                    child: _doodle(
                      asset: 'assets/branding/doodle_bottle.png',
                      width: math.min(65.0, availableWidth * 0.20),
                      height: math.min(85.0, availableHeight * 0.15),
                    ),
                  ),
                  // Top-right burger with flag doodle
                  Positioned(
                    top: availableHeight * 0.03,
                    right: -4,
                    child: _doodle(
                      asset: 'assets/branding/doodle_burger.png',
                      width: math.min(68.0, availableWidth * 0.20),
                      height: math.min(78.0, availableHeight * 0.14),
                    ),
                  ),
                  // Middle-right burger with flag doodle
                  Positioned(
                    top: availableHeight * 0.58,
                    right: -4,
                    child: _doodle(
                      asset: 'assets/branding/doodle_burger.png',
                      width: math.min(70.0, availableWidth * 0.21),
                      height: math.min(80.0, availableHeight * 0.14),
                    ),
                  ),
                  // Bottom-left fries in carton doodle
                  Positioned(
                    bottom: availableHeight * 0.10,
                    left: -6,
                    child: _doodle(
                      asset: 'assets/branding/doodle_fries_box.png',
                      width: math.min(85.0, availableWidth * 0.25),
                      height: math.min(125.0, availableHeight * 0.18),
                    ),
                  ),
                  // Bottom-right fries bundle doodle
                  Positioned(
                    bottom: availableHeight * 0.02,
                    right: 0,
                    child: _doodle(
                      asset: 'assets/branding/doodle_fries_bundle.png',
                      width: math.min(65.0, availableWidth * 0.20),
                      height: math.min(75.0, availableHeight * 0.13),
                    ),
                  ),
                ],

                // Centered Burger Bites Logo Lockup at Top
                Positioned(
                  top: logoTop,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: BurgerBitesWordmark(
                      width: maxLogoWidth,
                      animate: true,
                    ),
                  ),
                ),

                // Center Large Circular Progress Indicator with Black Arc and Light Grey Track
                Positioned(
                  top: loaderTop,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Semantics(
                      label: 'Loading Burger Bites',
                      child: SizedBox.square(
                        dimension: loaderSize,
                        child: CircularProgressIndicator(
                          strokeWidth: isShort ? 5.0 : 15.0,
                          strokeCap: StrokeCap.round,
                          color: Colors.black,
                          backgroundColor: const Color(0xFFECECEC),
                        ),
                      ),
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
