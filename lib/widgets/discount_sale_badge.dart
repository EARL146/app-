import 'dart:async';

import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../models/product_model.dart';

class DiscountSaleBadge extends StatefulWidget {
  const DiscountSaleBadge({required this.product, super.key});

  final Product product;

  @override
  State<DiscountSaleBadge> createState() => _DiscountSaleBadgeState();
}

class _DiscountSaleBadgeState extends State<DiscountSaleBadge> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void didUpdateWidget(covariant DiscountSaleBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.product.discountStartsAt != widget.product.discountStartsAt ||
        oldWidget.product.discountEndsAt != widget.product.discountEndsAt) {
      _startTimer();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    if (widget.product.discountStartsAt != null ||
        widget.product.discountEndsAt != null) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    if (!product.hasCurrentOrUpcomingDiscount) return const SizedBox.shrink();

    final now = DateTime.now().toUtc();
    final startsAt = product.discountStartsAt?.toUtc();
    final endsAt = product.discountEndsAt?.toUtc();
    final waitingForStart = startsAt != null && now.isBefore(startsAt);
    final deadline = waitingForStart ? startsAt : endsAt;
    final countdown = deadline == null
        ? null
        : _formatDuration(deadline.difference(now));
    final title = waitingForStart ? 'Starts' : 'Sale';
    final text = countdown == null
        ? '$title · ${product.discountPercent.toStringAsFixed(0)}% OFF'
        : '$title · ${product.discountPercent.toStringAsFixed(0)}% · $countdown';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.brandOrange,
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(
            color: Color(0x3022120C),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 8,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration remaining) {
    final seconds = remaining.inSeconds.clamp(0, 999999999);
    final days = seconds ~/ 86400;
    final hours = (seconds % 86400) ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final rest = seconds % 60;
    final hh = hours.toString().padLeft(2, '0');
    final mm = minutes.toString().padLeft(2, '0');
    final ss = rest.toString().padLeft(2, '0');
    return days > 0 ? '${days}d $hh:$mm:$ss' : '$hh:$mm:$ss';
  }
}
