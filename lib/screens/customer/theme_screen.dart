import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';

class ThemeScreen extends StatefulWidget {
  const ThemeScreen({super.key});

  @override
  State<ThemeScreen> createState() => _ThemeScreenState();
}

class _ThemeScreenState extends State<ThemeScreen> {
  String _selected = 'Sunset Orange';

  @override
  Widget build(BuildContext context) {
    final themes = [
      {'name': 'Sunset Orange', 'color': AppColors.brandOrange},
      {'name': 'Classic Red', 'color': AppColors.brandRed},
      {'name': 'Midnight', 'color': AppColors.darkSurface},
    ];

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(backgroundColor: AppColors.pageBackground, title: const Text('Color themes')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: themes.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final theme = themes[index];
          final selected = _selected == theme['name'];
          return InkWell(
            onTap: () => setState(() => _selected = theme['name'] as String),
            borderRadius: BorderRadius.circular(18),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: selected ? AppColors.brandOrange : AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: theme['color'] as Color,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      theme['name'] as String,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  if (selected) const Icon(Icons.check, color: AppColors.brandOrange),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
