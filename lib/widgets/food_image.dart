import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class FoodImage extends StatelessWidget {
  const FoodImage({
    super.key,
    this.imageUrl,
    this.category,
    this.fit = BoxFit.cover,
    this.borderRadius = 16,
    this.backgroundColor = AppColors.surfaceMuted,
  });

  final String? imageUrl;
  final String? category;
  final BoxFit fit;
  final double borderRadius;
  final Color backgroundColor;

  static String assetFor(String? imageUrl, String? category) {
    if (imageUrl != null && imageUrl.startsWith('assets/products/')) {
      return imageUrl;
    }
    switch ((category ?? '').toLowerCase()) {
      case 'sides':
        return 'assets/products/loaded_fries.jpg';
      case 'drinks':
        return 'assets/products/cola.jpg';
      case 'chicken':
        return 'assets/products/crispy_chicken.jpg';
      default:
        return 'assets/products/smash_burger.jpg';
    }
  }

  @override
  Widget build(BuildContext context) {
    final resolvedUrl = imageUrl ?? '';
    final provider = resolvedUrl.startsWith('http')
        ? NetworkImage(resolvedUrl) as ImageProvider
        : AssetImage(assetFor(imageUrl, category));

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Image(
        image: provider,
        fit: fit,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) => Container(
          color: backgroundColor,
          alignment: Alignment.center,
          child: Icon(
            _categoryIcon(category),
            size: 40,
            color: AppColors.brandOrange,
          ),
        ),
      ),
    );
  }

  static IconData _categoryIcon(String? category) {
    switch ((category ?? '').toLowerCase()) {
      case 'sides':
        return Icons.local_pizza_rounded;
      case 'drinks':
        return Icons.local_cafe_rounded;
      case 'chicken':
        return Icons.kebab_dining_rounded;
      default:
        return Icons.lunch_dining_rounded;
    }
  }
}
