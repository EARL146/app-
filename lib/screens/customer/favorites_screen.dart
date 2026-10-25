import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../providers/favorites_provider.dart';
import '../../services/auth_service.dart';
import '../../widgets/favorite_button.dart';
import '../../widgets/food_image.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final favorites = context.watch<FavoritesProvider>();
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(title: const Text('Your favorites')),
      body: !auth.isAuthenticated
          ? _MessageState(
              icon: Icons.favorite_border_rounded,
              message: 'Sign in to see favorites saved to your account.',
              actionLabel: 'Sign in',
              onPressed: () => Navigator.of(context).pushNamed('/sign-in'),
            )
          : favorites.isLoading && favorites.favorites.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : favorites.errorMessage != null && favorites.favorites.isEmpty
          ? _MessageState(
              icon: Icons.cloud_off_outlined,
              message: favorites.errorMessage!,
              actionLabel: 'Try again',
              onPressed: () =>
                  context.read<FavoritesProvider>().loadFavorites(),
            )
          : favorites.favorites.isEmpty
          ? const _MessageState(
              icon: Icons.favorite_border_rounded,
              message:
                  'No favorites yet. Save a menu item and it will appear here.',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: favorites.favorites.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final product = favorites.favorites[index];
                return Material(
                  color: AppColors.surface,
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: AppColors.border),
                  ),
                  child: ListTile(
                    leading: SizedBox(
                      width: 54,
                      height: 54,
                      child: FoodImage(
                        imageUrl: product.imageUrl,
                        borderRadius: 12,
                      ),
                    ),
                    title: Text(
                      product.name,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text('₱${product.price.toStringAsFixed(2)}'),
                    onTap: () =>
                        Navigator.of(context)
                            .pushNamed('/product-details', arguments: product),
                    trailing: FavoriteButton(product: product, iconSize: 20),
                  ),
                );
              },
            ),
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onPressed,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 46, color: AppColors.brandOrange),
          const SizedBox(height: 14),
          Text(message, textAlign: TextAlign.center),
          if (actionLabel != null) ...[
            const SizedBox(height: 14),
            FilledButton(onPressed: onPressed, child: Text(actionLabel!)),
          ],
        ],
      ),
    ),
  );
}
