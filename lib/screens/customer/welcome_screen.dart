import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../widgets/brand_logo.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  Timer? _continueTimer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _continueTimer ??= Timer(
      MediaQuery.disableAnimationsOf(context)
          ? const Duration(milliseconds: 650)
          : const Duration(milliseconds: 1450),
      _continue,
    );
  }

  void _continue() {
    if (!mounted) return;
    Navigator.of(context)
        .pushReplacementNamed('/customer-home', arguments: true);
  }

  @override
  void dispose() {
    _continueTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final logoWidth = math
                .min(constraints.maxWidth - 32, 330.0)
                .clamp(120.0, 330.0)
                .toDouble();
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  BurgerBitesWordmark(width: logoWidth),
                  const SizedBox(height: 14),
                  const Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: 'Welcome to '),
                        TextSpan(
                          text: 'burger',
                          style: TextStyle(
                            color: Color(0xFFE51C23),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        TextSpan(
                          text: 'Bites',
                          style: TextStyle(
                            color: Color(0xFF7B0D14),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF2C2927),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      letterSpacing: .2,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
