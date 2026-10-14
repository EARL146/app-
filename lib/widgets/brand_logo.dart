import 'package:flutter/material.dart';

/// The BurgerBites logo supplied by the project owner.
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.width = 220, this.height = 220});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/branding/burger_bites_logo.png',
      width: width,
      height: height,
      fit: BoxFit.contain,
      semanticLabel: 'BurgerBites chef burger logo',
      errorBuilder: (context, error, stackTrace) => SizedBox(
        width: width,
        height: height,
        child: const Center(
          child: Text(
            'BurgerBites',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ),
    );
  }
}
