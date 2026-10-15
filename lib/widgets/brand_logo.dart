import 'package:flutter/material.dart';

/// The BurgerBites logo supplied by the project owner.
class BrandLogo extends StatefulWidget {
  const BrandLogo({
    super.key,
    this.width = 220,
    this.height = 220,
    this.animate = false,
  });

  final double width;
  final double height;
  final bool animate;

  @override
  State<BrandLogo> createState() => _BrandLogoState();
}

class _BrandLogoState extends State<BrandLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAnimation();
  }

  @override
  void didUpdateWidget(covariant BrandLogo oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncAnimation();
  }

  void _syncAnimation() {
    final shouldAnimate =
        widget.animate && !MediaQuery.disableAnimationsOf(context);
    if (shouldAnimate && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!shouldAnimate && _controller.isAnimating) {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      'assets/branding/burger_bites_logo_cutout.png',
      width: widget.width,
      height: widget.height,
      fit: BoxFit.contain,
      semanticLabel: 'BurgerBites chef burger logo',
      errorBuilder: (context, error, stackTrace) => SizedBox(
        width: widget.width,
        height: widget.height,
        child: const Center(
          child: Text(
            'BurgerBites',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ),
    );
    if (!widget.animate || MediaQuery.disableAnimationsOf(context)) {
      return image;
    }
    return AnimatedBuilder(
      animation: _controller,
      child: image,
      builder: (context, child) {
        final offset = -3.5 + (_controller.value * 7);
        return Transform.translate(
          offset: Offset(0, offset),
          child: Transform.rotate(
            angle: -0.012 + (_controller.value * 0.024),
            child: child,
          ),
        );
      },
    );
  }
}
