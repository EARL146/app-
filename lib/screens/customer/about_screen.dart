import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../widgets/food_image.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(title: const Text('About BurgerBites')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(17, 4, 17, 22),
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'OUR STORY · LOCAL FLAVOR',
              style: TextStyle(
                color: AppColors.brandOrange,
                fontSize: 8,
                fontWeight: FontWeight.w900,
                letterSpacing: .5,
              ),
            ),
          ),
          const SizedBox(height: 11),
          const Text(
            'Crafting every bite\nwith passion',
            style: TextStyle(
              fontSize: 22,
              height: 1.08,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Fresh burgers, bright flavors, and happy moments — the BurgerBites brand experience.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 156,
            child: Stack(
              children: [
                Positioned.fill(
                  child: FoodImage(
                    imageUrl: 'assets/products/smash_burger.jpg',
                    borderRadius: 17,
                  ),
                ),
                Positioned(
                  left: 10,
                  bottom: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .95),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.favorite_rounded,
                          color: AppColors.brandOrange,
                          size: 12,
                        ),
                        SizedBox(width: 5),
                        Text(
                          'Made for every craving',
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 13),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.storefront_rounded,
                        color: AppColors.brandOrange,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Born for burger lovers',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Our sample story is rooted in the comfort of a freshly cooked burger: crisp edges, warm buns, and flavors worth sharing.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 9,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 10),
                const Row(
                  children: [
                    Expanded(
                      child: _MiniFact(value: 'Fresh', label: 'made to order'),
                    ),
                    SizedBox(width: 7),
                    Expanded(
                      child: _MiniFact(
                        value: 'Local',
                        label: 'community focus',
                      ),
                    ),
                    SizedBox(width: 7),
                    Expanded(
                      child: _MiniFact(value: 'Happy', label: 'everyday bites'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 13),
          const Text(
            'The recipe for great bites',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          const _ValueCard(
            icon: Icons.eco_outlined,
            title: 'Fresh ingredients',
            description: 'A visual promise of crisp greens, golden fries, and made-to-order favorites.',
          ),
          const _ValueCard(
            icon: Icons.restaurant_menu_rounded,
            title: 'Made with care',
            description: 'The app highlights the choices and details customers need before ordering.',
          ),
          const _ValueCard(
            icon: Icons.groups_2_outlined,
            title: 'A welcoming table',
            description: 'A friendly neighborhood brand concept, designed around shared meals.',
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: AppColors.brandOrange,
                  size: 16,
                ),
                const SizedBox(width: 7),
                const Expanded(
                  child: Text(
                    'Brand story and values are illustrative sample content for this prototype.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 9,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 13),
          SizedBox(
            width: double.infinity,
            height: 45,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pushNamed('/contact'),
              icon: const Icon(Icons.mail_outline_rounded, size: 16),
              label: const Text('Get in touch'),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).pushNamed('/menu'),
              child: const Text(
                'Explore the menu',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniFact extends StatelessWidget {
  const _MiniFact({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 5),
    decoration: BoxDecoration(
      color: AppColors.pageBackground,
      borderRadius: BorderRadius.circular(11),
    ),
    child: Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: AppColors.brandOrange,
            fontWeight: FontWeight.w900,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 7),
        ),
      ],
    ),
  );
}

class _ValueCard extends StatelessWidget {
  const _ValueCard({
    required this.icon,
    required this.title,
    required this.description,
  });
  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 7),
    padding: const EdgeInsets.all(11),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.border),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.brandOrange, size: 17),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                description,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 8,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
