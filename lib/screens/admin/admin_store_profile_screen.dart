import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../services/api_service.dart';

class AdminStoreProfileScreen extends StatefulWidget {
  const AdminStoreProfileScreen({super.key});

  @override
  State<AdminStoreProfileScreen> createState() =>
      _AdminStoreProfileScreenState();
}

class _AdminStoreProfileScreenState extends State<AdminStoreProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _api = ApiService();
  late final Map<String, TextEditingController> _fields = {
    'store_name': TextEditingController(text: 'BurgerBites'),
    'support_email': TextEditingController(),
    'support_phone': TextEditingController(),
    'facebook_url': TextEditingController(),
    'street_address': TextEditingController(),
    'opening_hours': TextEditingController(),
    'delivery_coverage': TextEditingController(),
  };
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final controller in _fields.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final response = await _api.get<Map<String, dynamic>>(
      '/admin/store-profile',
      fromJson: (json) => json is Map<String, dynamic>
          ? json
          : throw const FormatException('Invalid store profile response.'),
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (response.success && response.data != null) {
        final profile = response.data!['store_profile'];
        if (profile is Map<String, dynamic>) {
          for (final entry in _fields.entries) {
            entry.value.text = (profile[entry.key] ?? '').toString();
          }
        }
      } else {
        _error = response.error ?? 'Could not load the store profile.';
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final response = await _api.put<Map<String, dynamic>>(
      '/admin/store-profile',
      body: {
        for (final entry in _fields.entries) entry.key: entry.value.text.trim(),
      },
      fromJson: (json) => json is Map<String, dynamic>
          ? json
          : throw const FormatException('Invalid saved store profile.'),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (!response.success) {
      setState(() => _error = response.error ?? 'Could not save changes.');
      return;
    }
    final profile = response.data?['store_profile'];
    if (profile is Map<String, dynamic>) {
      for (final entry in _fields.entries) {
        entry.value.text = (profile[entry.key] ?? '').toString();
      }
    }
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Store profile saved.')));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.pageBackground,
    appBar: AppBar(
      title: const Text('Store profile'),
      backgroundColor: AppColors.pageBackground,
      surfaceTintColor: Colors.transparent,
      actions: [
        IconButton(
          tooltip: 'Reload store profile',
          onPressed: _loading || _saving ? null : _load,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
                  children: [
                    const Text(
                      'Public business details',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'These details are shown to customers. Enter only verified information.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 18),
                    _field('store_name', 'Store name', required: true),
                    _field(
                      'support_email',
                      'Support email',
                      keyboardType: TextInputType.emailAddress,
                    ),
                    _field(
                      'support_phone',
                      'Support phone',
                      keyboardType: TextInputType.phone,
                    ),
                    _field('facebook_url', 'Facebook page URL'),
                    _field('street_address', 'Store address', maxLines: 2),
                    _field('opening_hours', 'Opening hours'),
                    _field(
                      'delivery_coverage',
                      'Delivery coverage',
                      maxLines: 3,
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _error!,
                          style: const TextStyle(color: AppColors.danger),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    SizedBox(
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _saving ? null : _save,
                        icon: _saving
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.save_rounded),
                        label: Text(_saving ? 'Saving…' : 'Save store profile'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.brandOrange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
  );

  Widget _field(
    String key,
    String label, {
    bool required = false,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: _fields[key],
      keyboardType: keyboardType,
      maxLines: maxLines,
      maxLength: switch (key) {
        'store_name' => 120,
        'support_email' => 254,
        'support_phone' => 32,
        'facebook_url' => 500,
        'street_address' || 'delivery_coverage' => 500,
        'opening_hours' => 160,
        _ => null,
      },
      validator: (value) {
        final text = value?.trim() ?? '';
        if (required && text.length < 2) return 'Enter a store name.';
        if (key == 'support_email' &&
            text.isNotEmpty &&
            !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(text)) {
          return 'Enter a valid email address.';
        }
        if (key == 'facebook_url' &&
            text.isNotEmpty &&
            Uri.tryParse(text)?.scheme != 'https') {
          return 'Use a complete HTTPS URL.';
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(13)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: AppColors.border),
        ),
      ),
    ),
  );
}
