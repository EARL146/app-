import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  String _selected = 'English';

  @override
  Widget build(BuildContext context) {
    final languages = ['English', 'Tagalog', 'Spanish', 'French'];

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        backgroundColor: AppColors.pageBackground,
        title: const Text('Change language'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: languages.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final language = languages[index];
          final selected = _selected == language;
          return InkWell(
            onTap: () => setState(() => _selected = language),
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
                  Expanded(
                    child: Text(
                      language,
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
