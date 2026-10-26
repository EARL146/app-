import 'dart:async';

import 'package:flutter/material.dart';

import 'food_image.dart';

/// Product gallery used on the guest and signed-in product details screen.
/// Existing products with one image keep the same single-image presentation.
class ProductImageCarousel extends StatefulWidget {
  const ProductImageCarousel({
    required this.images,
    required this.category,
    super.key,
  });

  final List<String> images;
  final String? category;

  @override
  State<ProductImageCarousel> createState() => _ProductImageCarouselState();
}

class _ProductImageCarouselState extends State<ProductImageCarousel> {
  late final PageController _controller;
  Timer? _timer;
  int _index = 0;

  List<String> get _images => widget.images.isEmpty
      ? const ['']
      : widget.images.take(3).toList(growable: false);

  @override
  void initState() {
    super.initState();
    _controller = PageController();
    _startTimer();
  }

  @override
  void didUpdateWidget(covariant ProductImageCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.images.join('\n') != widget.images.join('\n')) {
      _index = 0;
      if (_controller.hasClients) _controller.jumpToPage(0);
      _startTimer();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    if (_images.length < 2) return;
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_controller.hasClients) return;
      final next = (_index + 1) % _images.length;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 520),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final images = _images;
    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          controller: _controller,
          itemCount: images.length,
          onPageChanged: (value) => setState(() => _index = value),
          itemBuilder: (context, index) => AnimatedSwitcher(
            duration: const Duration(milliseconds: 360),
            child: FoodImage(
              key: ValueKey('${widget.category}:${images[index]}:$index'),
              imageUrl: images[index].isEmpty ? null : images[index],
              category: widget.category,
              borderRadius: 0,
            ),
          ),
        ),
        if (images.length > 1)
          Positioned(
            bottom: 13,
            right: 14,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: .38),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(images.length, (index) {
                    final selected = index == _index;
                    return GestureDetector(
                      onTap: () => _controller.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 360),
                        curve: Curves.easeOutCubic,
                      ),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: selected ? 17 : 6,
                        height: 6,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: selected ? Colors.white : Colors.white70,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
