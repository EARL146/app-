import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/app_colors.dart';
import '../models/product_model.dart';
import '../providers/favorites_provider.dart';
import 'customer_account_prompt.dart';

class FavoriteButton extends StatelessWidget {
  const FavoriteButton({required this.product, this.iconSize = 21, super.key});

  final Product product;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Consumer<FavoritesProvider>(
      builder: (context, favorites, _) {
        final selected = favorites.isFavorite(product.id);
        return IconButton(
          tooltip: selected ? 'Remove from favorites' : 'Add to favorites',
          visualDensity: VisualDensity.compact,
          constraints: const BoxConstraints.tightFor(width: 32, height: 32),
          padding: EdgeInsets.zero,
          onPressed: favorites.isLoading
              ? null
              : () async {
                  if (!await requireCustomerAccount(
                    context,
                    action: 'save this favorite',
                  )) {
                    return;
                  }
                  if (!context.mounted) return;
                  final changed = await context
                      .read<FavoritesProvider>()
                      .toggleFavorite(product);
                  if (!context.mounted || changed) return;
                  final error = context.read<FavoritesProvider>().errorMessage;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(error ?? 'Unable to update favorites.'),
                      behavior: SnackBarBehavior.floating,
                      action: (error?.startsWith('Sign in') ?? false)
                          ? SnackBarAction(
                              label: 'Sign in',
                              onPressed: () =>
                                  Navigator.of(context).pushNamed('/sign-in'),
                            )
                          : null,
                    ),
                  );
                },
          icon: Icon(
            selected ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            size: iconSize,
            color: selected ? AppColors.brandRed : AppColors.textSecondary,
          ),
        );
      },
    );
  }
}
