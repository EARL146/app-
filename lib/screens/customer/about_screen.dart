import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(backgroundColor: AppColors.pageBackground, title: const Text('About')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'BurgerBites',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Fresh ingredients. Fast service. Favorites you keep coming back for.',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
            ),
            SizedBox(height: 20),
            Text(
              'This mobile experience is structured for secure customer ordering with future API connectivity and production-grade session handling.',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}
