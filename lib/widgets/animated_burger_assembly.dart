import 'package:flutter/material.dart';

import 'brand_logo.dart';

/// A lightweight ingredient-by-ingredient assembly used by the startup intro.
class AnimatedBurgerAssembly extends StatelessWidget {
  const AnimatedBurgerAssembly({
    super.key,
    required this.animation,
    required this.size,
  });

  final Animation<double> animation;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: Semantics(
        image: true,
        label: 'Bun, lettuce, cheese, and beef patty assemble into the BurgerBites logo',
        child: ExcludeSemantics(
          child: AnimatedBuilder(
            animation: animation,
            builder: (context, _) {
              final progress = animation.value;
              final logoReveal = _segment(progress, 0.79, 0.91);
              final ingredientFade = 1 - _segment(progress, 0.78, 0.90);

              return Stack(
                alignment: Alignment.center,
                children: [
                  Opacity(
                    opacity: ingredientFade,
                    child: Stack(
                      children: [
                        _positionedPart(
                          left: size * 0.25,
                          top: size * 0.68,
                          width: size * 0.50,
                          height: size * 0.15,
                          progress: _segment(progress, 0.08, 0.40),
                          from: Offset(0, size * 0.62),
                          child: const _Ingredient(
                            shape: _IngredientShape.bottomBun,
                          ),
                        ),
                        _positionedPart(
                          left: size * 0.15,
                          top: size * 0.59,
                          width: size * 0.70,
                          height: size * 0.16,
                          progress: _segment(progress, 0.20, 0.51),
                          from: Offset(0, size * 0.52),
                          child: const _Ingredient(
                            shape: _IngredientShape.patty,
                          ),
                        ),
                        _positionedPart(
                          left: size * 0.16,
                          top: size * 0.50,
                          width: size * 0.68,
                          height: size * 0.17,
                          progress: _segment(progress, 0.35, 0.65),
                          from: Offset(-size * 0.48, -size * 0.28),
                          child: const _Ingredient(
                            shape: _IngredientShape.cheese,
                          ),
                        ),
                        _positionedPart(
                          left: size * 0.11,
                          top: size * 0.42,
                          width: size * 0.78,
                          height: size * 0.14,
                          progress: _segment(progress, 0.48, 0.76),
                          from: Offset(size * 0.42, -size * 0.40),
                          child: const _Ingredient(
                            shape: _IngredientShape.lettuce,
                          ),
                        ),
                        _positionedPart(
                          left: size * 0.17,
                          top: size * 0.17,
                          width: size * 0.66,
                          height: size * 0.37,
                          progress: _segment(progress, 0.62, 0.86),
                          from: Offset(0, -size * 0.72),
                          child: const _Ingredient(
                            shape: _IngredientShape.topBun,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Opacity(
                    opacity: logoReveal,
                    child: Transform.scale(
                      scale: 0.96 + (0.04 * logoReveal),
                      child: BrandLogo(width: size * 0.88, height: size * 0.88),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _positionedPart({
    required double left,
    required double top,
    required double width,
    required double height,
    required double progress,
    required Offset from,
    required Widget child,
  }) {
    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: Opacity(
        opacity: progress,
        child: Transform.translate(
          offset: Offset(from.dx * (1 - progress), from.dy * (1 - progress)),
          child: Transform.scale(scale: 0.82 + (0.18 * progress), child: child),
        ),
      ),
    );
  }

  double _segment(double value, double start, double end) {
    final linear = ((value - start) / (end - start)).clamp(0.0, 1.0);
    return Curves.easeOutBack.transform(linear).clamp(0.0, 1.0);
  }
}

enum _IngredientShape { topBun, bottomBun, lettuce, cheese, patty }

class _Ingredient extends StatelessWidget {
  const _Ingredient({required this.shape});

  final _IngredientShape shape;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _IngredientPainter(shape));
}

class _IngredientPainter extends CustomPainter {
  const _IngredientPainter(this.shape);

  final _IngredientShape shape;

  @override
  void paint(Canvas canvas, Size size) {
    switch (shape) {
      case _IngredientShape.topBun:
        _paintTopBun(canvas, size);
      case _IngredientShape.bottomBun:
        _paintBottomBun(canvas, size);
      case _IngredientShape.lettuce:
        _paintLettuce(canvas, size);
      case _IngredientShape.cheese:
        _paintCheese(canvas, size);
      case _IngredientShape.patty:
        _paintPatty(canvas, size);
    }
  }

  void _paintTopBun(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final bun = Path()
      ..moveTo(w * 0.04, h * 0.86)
      ..quadraticBezierTo(w * 0.08, h * 0.34, w * 0.32, h * 0.14)
      ..quadraticBezierTo(w * 0.50, -h * 0.06, w * 0.68, h * 0.14)
      ..quadraticBezierTo(w * 0.92, h * 0.34, w * 0.96, h * 0.86)
      ..quadraticBezierTo(w * 0.50, h * 1.04, w * 0.04, h * 0.86)
      ..close();

    canvas.drawShadow(bun, const Color(0x33261C18), 5, true);
    canvas.drawPath(
      bun,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFD77C), Color(0xFFE99A35)],
        ).createShader(Offset.zero & size),
    );

    final seedPaint = Paint()..color = const Color(0xFFFFF1CB);
    for (final point in <Offset>[
      Offset(w * 0.28, h * 0.42),
      Offset(w * 0.39, h * 0.29),
      Offset(w * 0.50, h * 0.23),
      Offset(w * 0.61, h * 0.29),
      Offset(w * 0.72, h * 0.42),
      Offset(w * 0.20, h * 0.59),
      Offset(w * 0.34, h * 0.51),
      Offset(w * 0.66, h * 0.51),
      Offset(w * 0.80, h * 0.59),
    ]) {
      canvas.save();
      canvas.translate(point.dx, point.dy);
      canvas.rotate(-0.45);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset.zero,
          width: w * 0.025,
          height: h * 0.10,
        ),
        seedPaint,
      );
      canvas.restore();
    }
  }

  void _paintBottomBun(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      size.width * 0.04,
      size.height * 0.12,
      size.width * 0.92,
      size.height * 0.76,
    );
    final bun = RRect.fromRectAndRadius(
      rect,
      Radius.circular(size.height * 0.34),
    );
    canvas.drawShadow(Path()..addRRect(bun), const Color(0x33261C18), 4, true);
    canvas.drawRRect(
      bun,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFD178), Color(0xFFE99A35)],
        ).createShader(rect),
    );
  }

  void _paintLettuce(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(0, h * 0.30)
      ..quadraticBezierTo(w * 0.06, h * 0.02, w * 0.16, h * 0.24)
      ..quadraticBezierTo(w * 0.25, h * 0.48, w * 0.32, h * 0.18)
      ..quadraticBezierTo(w * 0.40, -h * 0.02, w * 0.49, h * 0.28)
      ..quadraticBezierTo(w * 0.59, h * 0.54, w * 0.68, h * 0.16)
      ..quadraticBezierTo(w * 0.79, -h * 0.02, w * 0.86, h * 0.30)
      ..quadraticBezierTo(w * 0.95, h * 0.04, w, h * 0.28)
      ..lineTo(w * 0.97, h * 0.78)
      ..quadraticBezierTo(w * 0.87, h * 0.60, w * 0.78, h * 0.90)
      ..quadraticBezierTo(w * 0.67, h * 1.06, w * 0.57, h * 0.76)
      ..quadraticBezierTo(w * 0.46, h * 0.57, w * 0.36, h * 0.92)
      ..quadraticBezierTo(w * 0.23, h * 1.06, w * 0.17, h * 0.72)
      ..quadraticBezierTo(w * 0.06, h * 0.93, 0, h * 0.64)
      ..close();

    canvas.drawShadow(path, const Color(0x33261C18), 3, true);
    canvas.drawPath(
      path,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF7BC642), Color(0xFF2D9A45)],
        ).createShader(Offset.zero & size),
    );
  }

  void _paintCheese(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cheese = Path()
      ..moveTo(w * 0.04, h * 0.08)
      ..lineTo(w * 0.96, h * 0.08)
      ..lineTo(w * 0.88, h * 0.72)
      ..lineTo(w * 0.73, h * 0.98)
      ..lineTo(w * 0.57, h * 0.72)
      ..lineTo(w * 0.41, h * 0.90)
      ..lineTo(w * 0.25, h * 0.68)
      ..lineTo(w * 0.10, h * 0.78)
      ..close();
    canvas.drawShadow(cheese, const Color(0x33261C18), 3, true);
    canvas.drawPath(
      cheese,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFFFD84F), Color(0xFFFFA51F)],
        ).createShader(Offset.zero & size),
    );
  }

  void _paintPatty(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      size.width * 0.03,
      size.height * 0.14,
      size.width * 0.94,
      size.height * 0.72,
    );
    final patty = RRect.fromRectAndRadius(
      rect,
      Radius.circular(size.height * 0.30),
    );
    canvas.drawShadow(
      Path()..addRRect(patty),
      const Color(0x44261C18),
      4,
      true,
    );
    canvas.drawRRect(
      patty,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF8D4828), Color(0xFF522819)],
        ).createShader(rect),
    );
    final grillPaint = Paint()
      ..color = const Color(0xFFBC7543).withValues(alpha: 0.55)
      ..strokeWidth = size.height * 0.035
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(size.width * 0.28, size.height * 0.42),
      Offset(size.width * 0.42, size.height * 0.36),
      grillPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.60, size.height * 0.65),
      Offset(size.width * 0.76, size.height * 0.58),
      grillPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _IngredientPainter oldDelegate) => false;
}
