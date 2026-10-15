import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../services/api_service.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  final _searchController = TextEditingController();
  String _selected = 'Bisaya (Cebuano)';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final response = await ApiService().get<Map<String, dynamic>>(
      '/me/preferences',
      fromJson: (json) => json is Map<String, dynamic>
          ? json
          : throw const FormatException('Invalid preferences response.'),
    );
    if (!mounted || !response.success) return;
    final preference = response.data?['preferences'];
    if (preference is! Map<String, dynamic>) return;
    const names = {
      'ceb': 'Bisaya (Cebuano)',
      'en': 'English (US / PH)',
      'fil': 'Tagalog (Filipino)',
      'ilo': 'Ilonggo (Hiligaynon)',
      'war': 'Waray-Waray',
      'es': 'Español',
      'ja': '日本語 (Japanese)',
      'ko': '한국어 (Korean)',
    };
    final name = names[preference['language']];
    if (name != null) setState(() => _selected = name);
  }

  Future<void> _saveLanguage() async {
    const codes = {
      'Bisaya (Cebuano)': 'ceb',
      'English (US / PH)': 'en',
      'Tagalog (Filipino)': 'fil',
      'Ilonggo (Hiligaynon)': 'ilo',
      'Waray-Waray': 'war',
      'Español': 'es',
      '日本語 (Japanese)': 'ja',
      '한국어 (Korean)': 'ko',
    };
    setState(() => _isSaving = true);
    final response = await ApiService().put<Map<String, dynamic>>(
      '/me/preferences',
      body: {'language': codes[_selected] ?? 'en'},
      fromJson: (json) => json is Map<String, dynamic>
          ? json
          : throw const FormatException('Invalid preferences response.'),
    );
    if (!mounted) return;
    setState(() => _isSaving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          response.success
              ? 'Language preference saved. App-wide translations are not yet available.'
              : response.error ?? 'Unable to save language preference.',
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
      appBar: AppBar(title: const Text('Change language')),
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
                  child: const Text(
                    'APP PREFERENCES',
                    style: TextStyle(
                      color: AppColors.brandOrange,
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      letterSpacing: .5,
                    ),
                  ),
                ),
                const SizedBox(height: 13),
                const Text(
                  'Change language',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Choose the language you prefer. Your selection will be saved on this device.',
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
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search_rounded),
                    hintText: 'Search languages…',
                  ),
                ),
                const SizedBox(height: 16),
                const Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Regional & official',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Text(
                      'PH FIRST · FOOD READY',
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
                        selected: _selected == item.name,
                        onTap: () => setState(() => _selected = item.name),
                      ),
                    ),
                const SizedBox(height: 12),
                const Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Other languages',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Text(
                      'GLOBAL VISITORS',
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
                        selected: _selected == item.name,
                        onTap: () => setState(() => _selected = item.name),
                      ),
                    ),
                if (languages.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        'No languages found.',
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
                      const Icon(
                        Icons.visibility_outlined,
                        color: AppColors.brandOrange,
                        size: 17,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'LANGUAGE PREFERENCE',
                              style: TextStyle(
                                color: AppColors.brandOrange,
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _selected,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'This preference is saved to your account. Most app screens remain in English.',
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
                        _isSaving
                            ? 'Saving…'
                            : 'Save ${_selected.split(' ').first}',
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextButton(
                    onPressed: () =>
                        setState(() => _selected = 'Bisaya (Cebuano)'),
                    child: const Text(
                      'Reset to Bisaya (Cebuano)',
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
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 7),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
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
        style: const TextStyle(fontSize: 8, color: AppColors.textSecondary),
      ),
      trailing: Icon(
        selected ? Icons.check_circle_rounded : Icons.circle_outlined,
        color: selected ? AppColors.brandOrange : AppColors.border,
        size: 17,
      ),
    ),
  );
}
