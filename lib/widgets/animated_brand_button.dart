import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Wraps any interactive widget with a tactile press-and-hover scale animation
/// that respects [MediaQuery.disableAnimationsOf] and completes finitely so
/// widget tests calling `pumpAndSettle()` never hang.
class AnimatedPressScale extends StatefulWidget {
  const AnimatedPressScale({
    required this.child,
    this.onTap,
    this.borderRadius,
    this.pressedScale = 0.96,
    this.hoverScale = 1.015,
    this.duration = const Duration(milliseconds: 140),
    this.enabled = true,
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;
  final double pressedScale;
  final double hoverScale;
  final Duration duration;
  final bool enabled;

  @override
  State<AnimatedPressScale> createState() => _AnimatedPressScaleState();
}

class _AnimatedPressScaleState extends State<AnimatedPressScale> {
  bool _pressed = false;
  bool _hovered = false;

  void _setPressed(bool value) {
    if (!widget.enabled || _pressed == value) return;
    setState(() => _pressed = value);
  }

  void _setHovered(bool value) {
    if (!widget.enabled || _hovered == value) return;
    setState(() => _hovered = value);
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    final targetScale = !widget.enabled || disableAnimations
        ? 1.0
        : _pressed
        ? widget.pressedScale
        : _hovered
        ? widget.hoverScale
        : 1.0;

    Widget content = widget.child;
    if (widget.onTap != null) {
      content = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.enabled ? widget.onTap : null,
        child: content,
      );
    }

    return MouseRegion(
      cursor: widget.onTap != null && widget.enabled
          ? SystemMouseCursors.click
          : MouseCursor.defer,
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) => _setPressed(true),
        onPointerUp: (_) => _setPressed(false),
        onPointerCancel: (_) => _setPressed(false),
        child: AnimatedScale(
          scale: targetScale,
          duration: disableAnimations ? Duration.zero : widget.duration,
          curve: Curves.easeOutCubic,
          child: content,
        ),
      ),
    );
  }
}

/// A gradient-accented BurgerBites pill badge used on hero cards and headers.
class BrandGradientBadge extends StatelessWidget {
  const BrandGradientBadge({
    required this.label,
    this.icon,
    super.key,
  });

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        gradient: AppColors.primaryButtonGradient,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandOrange.withValues(alpha: 0.28),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: Colors.white),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.65,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Smoothly animates text/number changes (such as item quantities or live cart
/// totals) with a subtle scale + fade transition.
class AnimatedValueText extends StatelessWidget {
  const AnimatedValueText(
    this.text, {
    this.style,
    this.duration = const Duration(milliseconds: 180),
    super.key,
  });

  final String text;
  final TextStyle? style;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    if (disableAnimations) {
      return Text(text, style: style);
    }
    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: Curves.easeOutBack,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.88, end: 1.0).animate(animation),
          child: child,
        ),
      ),
      child: Text(
        text,
        key: ValueKey<String>(text),
        style: style,
      ),
    );
  }
}

/// Finite entrance fade + slide-up wrapper for cards and sections.
class AnimatedEntranceCard extends StatelessWidget {
  const AnimatedEntranceCard({
    required this.child,
    this.duration = const Duration(milliseconds: 240),
    this.verticalOffset = 10.0,
    super.key,
  });

  final Widget child;
  final Duration duration;
  final double verticalOffset;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return child;
    }
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, (1 - value) * verticalOffset),
          child: child,
        ),
      ),
      child: child,
    );
  }
}
