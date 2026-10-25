import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../l10n/app_translations.dart';
import '../../providers/app_preferences_provider.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  final _searchController = TextEditingController();
  bool _isSaving = false;

  Future<void> _saveLanguage() async {
    setState(() => _isSaving = true);
    final preferences = context.read<AppPreferencesProvider>();
    final saved = await preferences.saveLanguage();
    if (!mounted) return;
    setState(() => _isSaving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          saved
              ? preferences.canSyncToAccount
                    ? 'Language saved to your account.'.tr
                    : 'Language applied and saved on this device.'.tr
              : preferences.errorMessage ??
                    'Unable to save language preference.'.tr,
        ),
      ),
    );
  }

  static const _languages = [
    _Language(
      'Bisaya (Cebuano)',
      'Kasamtangang Gigamit · Active on this device',
      '🗣',
      true,
    ),
    _Language(
      'English (US / PH)',
      'Official international & business standard',
      '🌐',
      true,
    ),
    _Language('Tagalog (Filipino)', 'Pambansang wika ng Pilipinas', '☀️', true),
    _Language(
      'Ilonggo (Hiligaynon)',
      'Western Visayas regional dialect',
      '✦',
      true,
    ),
    _Language('Waray-Waray', 'Eastern Visayas regional dialect', '🌊', true),
    _Language('Español', 'Spanish language support', 'ES', false),
    _Language('日本語 (Japanese)', 'Japanese language support', 'JP', false),
    _Language('한국어 (Korean)', 'Korean language support', 'KR', false),
  ];
  static const _languageCodes = {
    'Bisaya (Cebuano)': 'ceb',
    'English (US / PH)': 'en',
    'Tagalog (Filipino)': 'fil',
    'Ilonggo (Hiligaynon)': 'ilo',
    'Waray-Waray': 'war',
    'Español': 'es',
    '日本語 (Japanese)': 'ja',
    '한국어 (Korean)': 'ko',
  };

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final preferences = context.watch<AppPreferencesProvider>();
    final selectedLanguage = _languageCodes.entries
        .firstWhere(
          (entry) => entry.value == preferences.languageCode,
          orElse: () => const MapEntry('English (US / PH)', 'en'),
        )
        .key;
    final query = _searchController.text.trim().toLowerCase();
    final languages = _languages
        .where(
          (item) =>
              item.name.toLowerCase().contains(query) ||
              item.description.toLowerCase().contains(query),
        )
        .toList();
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(title: Text('Change language'.tr)),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(17, 4, 17, 15),
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'APP PREFERENCES'.tr,
                    style: TextStyle(
                      color: AppColors.brandOrange,
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      letterSpacing: .5,
                    ),
                  ),
                ),
                const SizedBox(height: 13),
                Text(
                  'Change language'.tr,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 5),
                Text(
                  'Choose the language you prefer. Your selection will be saved on this device.'
                      .tr,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 13),
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.search_rounded),
                    hintText: 'Search languages…'.tr,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Regional & official'.tr,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Text(
                      'PH FIRST · FOOD READY'.tr,
                      style: TextStyle(
                        color: AppColors.brandOrange,
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...languages
                    .where((item) => item.local)
                    .map(
                      (item) => _LanguageTile(
                        item: item,
                        selected: selectedLanguage == item.name,
                        onTap: () => preferences.setLanguageCode(
                          _languageCodes[item.name] ?? 'en',
                        ),
                      ),
                    ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Other languages'.tr,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Text(
                      'GLOBAL VISITORS'.tr,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...languages
                    .where((item) => !item.local)
                    .map(
                      (item) => _LanguageTile(
                        item: item,
                        selected: selectedLanguage == item.name,
                        onTap: () => preferences.setLanguageCode(
                          _languageCodes[item.name] ?? 'en',
                        ),
                      ),
                    ),
                if (languages.isEmpty)
                  Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        'No languages found.'.tr,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.visibility_outlined,
                        color: AppColors.brandOrange,
                        size: 17,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'LANGUAGE PREFERENCE'.tr,
                              style: TextStyle(
                                color: AppColors.brandOrange,
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              selectedLanguage,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Your app language has been updated.'.tr,
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 9,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(17, 6, 17, 12),
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 47,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _saveLanguage,
                      icon: const Icon(Icons.save_outlined, size: 17),
                      label: Text(
                        _isSaving ? 'Saving…'.tr : 'Save language'.tr,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextButton(
                    onPressed: () => preferences.setLanguageCode('ceb'),
                    child: Text(
                      'Reset to Bisaya (Cebuano)'.tr,
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Language {
  const _Language(this.name, this.description, this.mark, this.local);
  final String name;
  final String description;
  final String mark;
  final bool local;
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.item,
    required this.selected,
    required this.onTap,
  });
  final _Language item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: Material(
      color: AppColors.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: selected ? AppColors.brandOrange : AppColors.border,
        ),
      ),
      child: ListTile(
        dense: true,
        onTap: onTap,
        leading: Container(
          width: 33,
          height: 33,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            item.mark,
            style: TextStyle(
              fontSize: item.mark.length > 2 ? 13 : 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        title: Text(
          item.name,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
        ),
        subtitle: Text(
          item.description,
          style: TextStyle(fontSize: 8, color: AppColors.textSecondary),
        ),
        trailing: Icon(
          selected ? Icons.check_circle_rounded : Icons.circle_outlined,
          color: selected ? AppColors.brandOrange : AppColors.border,
          size: 17,
        ),
      ),
    ),
  );
}
