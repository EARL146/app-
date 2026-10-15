import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../widgets/brand_logo.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final heroSize = (constraints.maxHeight * 0.37)
                .clamp(205.0, 315.0)
                .toDouble();
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: (constraints.maxHeight - 24).clamp(
                    0,
                    double.infinity,
                  ),
                ),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const BrandLogo(
                                width: 44,
                                height: 44,
                                animate: true,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'BurgerBites',
                                style: TextStyle(
                                  color: AppColors.brandRed,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(
                            height: (constraints.maxHeight * 0.025).clamp(
                              12,
                              22,
                            ),
                          ),
                          Center(child: _BurgerHero(size: heroSize)),
                          SizedBox(
                            height: (constraints.maxHeight * 0.035).clamp(
                              18,
                              28,
                            ),
                          ),
                          const Text(
                            'Your Cravings,\nOur Burgers',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 32,
                              height: 1.08,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.7,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Freshly made favorites, ready when you are.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 15,
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(height: 22),
                          SizedBox(
                            height: 58,
                            child: ElevatedButton(
                              onPressed: () =>
                                  Navigator.of(context).pushNamed('/register'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.brandOrange,
                                foregroundColor: Colors.white,
                                elevation: 2,
                                shadowColor: AppColors.brandOrange.withValues(
                                  alpha: 0.25,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Get Started',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  SizedBox(width: 9),
                                  Icon(Icons.arrow_forward_rounded, size: 19),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              const Text(
                                'Already have an account?',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pushNamed('/sign-in'),
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.brandOrangeDark,
                                  textStyle: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                  ),
                                ),
                                child: const Text('Log In'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _BurgerHero extends StatefulWidget {
  const _BurgerHero({required this.size});

  final double size;

  @override
  State<_BurgerHero> createState() => _BurgerHeroState();
}

class _BurgerHeroState extends State<_BurgerHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motion = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2800),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncMotion();
  }

  void _syncMotion() {
    if (MediaQuery.disableAnimationsOf(context)) {
      if (_motion.isAnimating) _motion.stop();
    } else if (!_motion.isAnimating) {
      _motion.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    return SizedBox(
      width: size,
      height: size,
      child: AnimatedBuilder(
        animation: _motion,
        builder: (context, _) {
          final progress = Curves.easeInOut.transform(_motion.value);
          return Transform.translate(
            offset: Offset(0, -4 - (progress * 7)),
            child: Transform.rotate(
              angle: -0.018 + (progress * 0.036),
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  // A moving studio glow sits behind the transparent burger cutout.
                  Container(
                    width: size * 0.94,
                    height: size * 0.94,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        center: Alignment(-0.12 + progress * 0.24, -0.16),
                        colors: [
                          const Color(0xFFFFE5C2).withValues(alpha: 0.90),
                          const Color(0xFFFFF5E9).withValues(alpha: 0.60),
                          AppColors.pageBackground.withValues(alpha: 0.02),
                        ],
                        stops: const [0, 0.64, 1],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: size * 0.10,
                    child: Container(
                      width: size * 0.70 - progress * size * 0.04,
                      height: size * 0.11,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(size),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF63351F)
                                .withValues(alpha: 0.18 + progress * 0.10),
                            blurRadius: size * (0.07 + progress * 0.035),
                            spreadRadius: size * 0.01,
                            offset: Offset(0, size * 0.035),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    width: size * 0.99,
                    height: size * 0.99,
                    child: Image.asset(
                      'assets/products/smash_burger_cutout.png',
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                      semanticLabel: 'Photorealistic double smash burger',
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
