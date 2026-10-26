import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../l10n/app_translations.dart';
import '../models/product_model.dart';
import 'animated_brand_button.dart';
import 'discount_sale_badge.dart';
import 'product_image_carousel.dart';

class DiscountSaleSection extends StatelessWidget {
  const DiscountSaleSection({
    required this.products,
    required this.isLoading,
    required this.onSeeAll,
    super.key,
  });

  final List<Product> products;
  final bool isLoading;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    final saleProducts = products
        .where(
          (product) =>
              product.available && product.hasCurrentOrUpcomingDiscount,
        )
        .toList(growable: false);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.brandOrange.withValues(alpha: .22)),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandOrange.withValues(alpha: .08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(14, 13, 8, 13),
            decoration: BoxDecoration(
              gradient: AppColors.primaryButtonGradient,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Discount Sale'.tr,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          height: 1.1,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Limited-time deals'.tr,
                        style: const TextStyle(
                          color: Color(0xFFFFE7DD),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (saleProducts.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .18),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      '${saleProducts.length} ${'items'.tr}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                TextButton(
                  onPressed: onSeeAll,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: Text(
                    'See all'.tr,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            switchInCurve: Curves.easeOutCubic,
            child: isLoading && products.isEmpty
                ? const SizedBox(
                    key: ValueKey('discount-sale-loading'),
                    height: 118,
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                  )
                : saleProducts.isEmpty
                ? _DiscountSaleEmptyState(
                    key: const ValueKey('discount-sale-empty'),
                    onBrowse: onSeeAll,
                  )
                : SizedBox(
                    key: const ValueKey('discount-sale-products'),
                    height: 236,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(11),
                      scrollDirection: Axis.horizontal,
                      itemCount: saleProducts.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 10),
                      itemBuilder: (context, index) => _DiscountSaleProductCard(
                        product: saleProducts[index],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _DiscountSaleEmptyState extends StatelessWidget {
  const _DiscountSaleEmptyState({required this.onBrowse, super.key});

  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'No sale items are available right now. Please check back later.'
                    .tr,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: onBrowse,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.brandOrange,
                visualDensity: VisualDensity.compact,
              ),
              child: Text(
                'Browse menu'.tr,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DiscountSaleProductCard extends StatelessWidget {
  const _DiscountSaleProductCard({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final isActive = product.hasActiveDiscount;
    final originalPrice = product.discountTargetBasePrice;
    final discountedPrice = product.previewDiscountPrice(originalPrice);

    return AnimatedPressScale(
      child: InkWell(
        onTap: () =>
            Navigator.of(context)
                .pushNamed('/product-details', arguments: product),
        borderRadius: BorderRadius.circular(15),
        child: Container(
          width: 144,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: AppColors.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 120,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ProductImageCarousel(
                      images: product.galleryImages,
                      category: product.category,
                    ),
                    Positioned(
                      top: 7,
                      right: 7,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.danger,
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 4,
                          ),
                          child: Text(
                            '${product.discountPercent.toStringAsFixed(0)}% OFF',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 7,
                      bottom: 7,
                      child: DiscountSaleBadge(product: product),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(9, 8, 9, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      if (discountedPrice != null) ...[
                        if (!isActive) ...[
                          Text(
                            'Starts soon'.tr,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.brandOrange,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                        ],
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '₱${discountedPrice.toStringAsFixed(0)}',
                              style: TextStyle(
                                color: AppColors.brandOrange,
                                fontSize: 16,
                                height: 1.05,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                '₱${originalPrice.toStringAsFixed(0)}',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 9,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        Text(
                          isActive
                              ? 'Discount applies to selected option'.tr
                              : 'Starts soon'.tr,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.brandOrange,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '₱${product.price.toStringAsFixed(0)}',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
