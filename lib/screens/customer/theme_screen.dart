import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../services/api_service.dart';

class ThemeScreen extends StatefulWidget {
  const ThemeScreen({super.key});

  @override
  State<ThemeScreen> createState() => _ThemeScreenState();
}

class _ThemeScreenState extends State<ThemeScreen> {
  String _selected = 'Burger Bites';
  String _displayMode = 'Light';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadAppearance();
  }

  Future<void> _loadAppearance() async {
    final response = await ApiService().get<Map<String, dynamic>>(
      '/me/preferences',
      fromJson: (json) => json is Map<String, dynamic>
          ? json
          : throw const FormatException('Invalid preferences response.'),
    );
    if (!mounted || !response.success) return;
    final preferences = response.data?['preferences'];
    if (preferences is! Map<String, dynamic>) return;
    final palette = preferences['theme_palette'];
    final mode = preferences['theme_mode'] as String?;
    setState(() {
      if (_palettes.any((item) => item.name == palette)) {
        _selected = palette as String;
      }
      _displayMode = switch (mode) {
        'dark' => 'Dark',
        'system' => 'System',
        _ => 'Light',
      };
    });
  }

  Future<void> _saveAppearance() async {
    setState(() => _isSaving = true);
    final response = await ApiService().put<Map<String, dynamic>>(
      '/me/preferences',
      body: {
        'theme_palette': _selected,
        'theme_mode': _displayMode.toLowerCase(),
      },
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
              ? 'Appearance preference saved. The palette preview does not yet change every app screen.'
              : response.error ?? 'Unable to save appearance preference.',
        ),
      ),
    );
  }

  static const _palettes = [
    _Palette(
      'Burger Bites',
      'Fresh orange and warm cream',
      AppColors.brandOrange,
      AppColors.brandRed,
    ),
    _Palette(
      'Sizzling Crimson',
      'Bold red for a bright menu',
      Color(0xFFE53935),
      Color(0xFFB91C1C),
    ),
    _Palette(
      'Golden Mustard Cheddar',
      'Warm golden yellow',
      Color(0xFFE6A817),
      Color(0xFFC47E0D),
    ),
    _Palette(
      'Emerald Mint Fresh',
      'Cool green accents',
      Color(0xFF18A982),
      Color(0xFF117B67),
    ),
    _Palette(
      'Midnight Smoke Black',
      'Dark preview palette',
      Color(0xFF29201D),
      Color(0xFF120E0C),
    ),
    _Palette(
      'Sweet Berry Bloom',
      'Soft berry accents',
      Color(0xFFD64F79),
      Color(0xFFAA3157),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final selected = _palettes.firstWhere(
      (palette) => palette.name == _selected,
    );
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(title: const Text('Color themes')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(17, 4, 17, 16),
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
                    'APP PREFERENCES · CUSTOMER VIEW',
                    style: TextStyle(
                      color: AppColors.brandOrange,
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      letterSpacing: .5,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Color themes & appearance',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Preview a color palette for your BurgerBites app.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 13),
                Container(
                  padding: const EdgeInsets.all(13),
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
                          const Expanded(
                            child: Text(
                              'LIVE PREVIEW',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                                letterSpacing: .5,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: selected.primary.withValues(alpha: .12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              selected.name,
                              style: TextStyle(
                                color: selected.primary,
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(11),
                        decoration: BoxDecoration(
                          color: AppColors.pageBackground,
                          borderRadius: BorderRadius.circular(13),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 29,
                              height: 29,
                              decoration: BoxDecoration(
                                color: selected.primary,
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: const Icon(
                                Icons.lunch_dining_rounded,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'BurgerBites',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 10,
                                    ),
                                  ),
                                  Text(
                                    'Menu item preview',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 8,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: selected.primary,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'Preview',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'DISPLAY MODE',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .5,
                  ),
                ),
                const SizedBox(height: 7),
                Row(
                  children: ['Light', 'Dark', 'System']
                      .map(
                        (mode) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ChoiceChip(
                              label: Center(child: Text(mode)),
                              selected: _displayMode == mode,
                              onSelected: (_) =>
                                  setState(() => _displayMode = mode),
                              selectedColor: AppColors.surface,
                              backgroundColor: AppColors.surfaceMuted,
                              side: BorderSide(
                                color: _displayMode == mode
                                    ? AppColors.brandOrange
                                    : AppColors.border,
                              ),
                              showCheckmark: false,
                              labelStyle: TextStyle(
                                color: _displayMode == mode
                                    ? AppColors.brandOrange
                                    : AppColors.textSecondary,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Primary brand palettes',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const Text(
                      '6 palettes',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 8,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                ..._palettes.map(
                  (palette) => _PaletteTile(
                    palette: palette,
                    selected: palette.name == _selected,
                    onTap: () => setState(() => _selected = palette.name),
                  ),
                ),
                const SizedBox(height: 9),
                Container(
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: AppColors.brandOrange,
                        size: 15,
                      ),
                      SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          'Palette and display mode save to your account; the palette preview does not yet apply across every screen.',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 9,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(17, 5, 17, 12),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                height: 47,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveAppearance,
                  icon: const Icon(Icons.check_rounded, size: 17),
                  label: Text(_isSaving ? 'Saving…' : 'Save appearance'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Palette {
  const _Palette(this.name, this.description, this.primary, this.secondary);
  final String name;
  final String description;
  final Color primary;
  final Color secondary;
}

class _PaletteTile extends StatelessWidget {
  const _PaletteTile({
    required this.palette,
    required this.selected,
    required this.onTap,
  });
  final _Palette palette;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 7),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: selected ? palette.primary : AppColors.border),
    ),
    child: ListTile(
      dense: true,
      onTap: onTap,
      leading: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [palette.primary, palette.secondary],
          ),
          borderRadius: BorderRadius.circular(11),
        ),
        child: selected
            ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
            : null,
      ),
      title: Text(
        palette.name,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
      ),
      subtitle: Text(
        palette.description,
        style: const TextStyle(fontSize: 8, color: AppColors.textSecondary),
      ),
      trailing: selected
          ? Icon(
              Icons.radio_button_checked_rounded,
              color: palette.primary,
              size: 18,
            )
          : const Icon(
              Icons.radio_button_off_rounded,
              color: AppColors.border,
              size: 18,
            ),
    ),
  );
}
