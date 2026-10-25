import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../services/api_service.dart';

class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();
  final _apiService = ApiService();
  String _topic = 'Order inquiry';
  bool _isSending = false;
  bool _storeLoading = true;
  Map<String, dynamic>? _storeProfile;
  final List<_ContactPhoto> _photos = [];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadStoreProfile();
  }

  Future<void> _loadStoreProfile() async {
    final response = await _apiService.get<Map<String, dynamic>>(
      '/store-profile',
      requiresAuth: false,
      fromJson: (json) => json is Map<String, dynamic>
          ? json
          : throw const FormatException('Invalid store profile response.'),
    );
    if (!mounted) return;
    setState(() {
      _storeLoading = false;
      final value = response.data?['store_profile'];
      _storeProfile = response.success && value is Map<String, dynamic>
          ? value
          : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(title: const Text('Contact us')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(17, 3, 17, 22),
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'BURGERBITES SUPPORT',
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
              'Get in touch',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 5),
            Text(
              'Send a support request about an order, your account, or BurgerBites.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 10,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 13),
            _storeDetailsCard(),
            const SizedBox(height: 14),
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
                  const Text(
                    'Send us a message',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Your message is saved to the BurgerBites support inbox for follow-up.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 9,
                    ),
                  ),
                  const SizedBox(height: 11),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Full name'),
                    validator: (value) =>
                        value == null || value.trim().length < 2
                        ? 'Enter your name.'
                        : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email or mobile number',
                    ),
                    validator: (value) =>
                        value == null || value.trim().length < 5
                        ? 'Enter a way for us to contact you.'
                        : null,
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _topic,
                    decoration: const InputDecoration(labelText: 'Topic'),
                    items: const [
                      DropdownMenuItem(
                        value: 'Order inquiry',
                        child: Text('Order inquiry'),
                      ),
                      DropdownMenuItem(
                        value: 'Account help',
                        child: Text('Account help'),
                      ),
                      DropdownMenuItem(
                        value: 'Feedback',
                        child: Text('Feedback'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => _topic = value);
                    },
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _messageController,
                    minLines: 3,
                    maxLines: 4,
                    decoration: const InputDecoration(labelText: 'Message'),
                    validator: (value) =>
                        value == null || value.trim().length < 5
                        ? 'Add a short message.'
                        : null,
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      onPressed: _isSending || _photos.length >= 5
                          ? null
                          : _pickPhotos,
                      icon: const Icon(
                        Icons.add_photo_alternate_outlined,
                        size: 17,
                      ),
                      label: Text('Add photos (${_photos.length}/5)'),
                    ),
                  ),
                  if (_photos.isNotEmpty) ...[
                    const SizedBox(height: 7),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final photo in _photos)
                          Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(11),
                                child: Image.memory(
                                  photo.bytes,
                                  width: 72,
                                  height: 72,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                right: 2,
                                top: 2,
                                child: InkWell(
                                  onTap: _isSending
                                      ? null
                                      : () => setState(
                                          () => _photos.remove(photo),
                                        ),
                                  child: const CircleAvatar(
                                    radius: 11,
                                    backgroundColor: Colors.black87,
                                    child: Icon(
                                      Icons.close_rounded,
                                      size: 13,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton.icon(
                      onPressed: _isSending ? null : _sendMessage,
                      icon: _isSending
                          ? const SizedBox.square(
                              dimension: 15,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send_rounded, size: 16),
                      label: Text(_isSending ? 'Sending…' : 'Send message'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Frequently asked',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 7),
            const _FaqTile(
              question: 'Is my address in the delivery area?',
              answer: 'Delivery coverage has not been configured yet. Confirm your address with the BurgerBites team before placing an order.',
            ),
            const _FaqTile(
              question: 'What payment options are available?',
              answer: 'Cash on delivery is available. GCash and Maya will be enabled after the payment provider sandbox is configured.',
            ),
            const _FaqTile(
              question: 'How do I check order status?',
              answer: 'Open My Orders to see the saved order status. Live GPS tracking is not connected.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _storeDetailsCard() {
    final profile = _storeProfile;
    final details =
        <(String, IconData)>[
          ('support_email', Icons.email_outlined),
          ('support_phone', Icons.phone_outlined),
          ('street_address', Icons.location_on_outlined),
          ('opening_hours', Icons.schedule_rounded),
          ('delivery_coverage', Icons.delivery_dining_rounded),
          ('facebook_url', Icons.public_rounded),
        ].where(
          (entry) => (profile?[entry.$1] as String?)?.trim().isNotEmpty == true,
        );
    final visibleDetails = details.toList(growable: false);
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.border),
      ),
      child: _storeLoading
          ? const Row(
              children: [
                SizedBox.square(
                  dimension: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 9),
                Expanded(child: Text('Loading verified store information…')),
              ],
            )
          : visibleDetails.isEmpty
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: AppColors.brandOrange,
                  size: 17,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Verified store phone, email, social page, opening hours, and location have not been provided yet. Use the message form below to contact support.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 9,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (profile?['store_name'] as String?) ?? 'BurgerBites',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 9),
                for (final (key, icon) in visibleDetails) ...[
                  if (key != visibleDetails.first.$1) const SizedBox(height: 7),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(icon, size: 15, color: AppColors.brandOrange),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SelectableText(
                          (profile![key] as String).trim(),
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 10,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
    );
  }

  Future<void> _sendMessage() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSending = true);
    final response = await _apiService.post<Map<String, dynamic>>(
      '/contact',
      body: {
        'full_name': _nameController.text.trim(),
        'email_or_phone': _emailController.text.trim(),
        'topic': _topic,
        'message': _messageController.text.trim(),
        'attachments': _photos
            .map(
              (photo) => {
                'name': photo.name,
                'image_base64': base64Encode(photo.bytes),
              },
            )
            .toList(growable: false),
      },
      fromJson: (json) => json is Map<String, dynamic>
          ? json
          : throw const FormatException('Invalid support response.'),
    );
    if (!mounted) return;
    setState(() => _isSending = false);
    if (!response.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response.error ?? 'Message could not be sent.')),
      );
      return;
    }
    _nameController.clear();
    _emailController.clear();
    _messageController.clear();
    setState(() => _photos.clear());
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Your support request was saved.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _pickPhotos() async {
    final remaining = 5 - _photos.length;
    if (remaining <= 0) return;
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp', 'gif'],
      allowMultiple: true,
      withData: true,
    );
    if (result == null || !mounted) return;
    var skippedLarge = false;
    final accepted = <_ContactPhoto>[];
    for (final file in result.files.take(remaining)) {
      final bytes = file.bytes;
      if (bytes == null || bytes.isEmpty) continue;
      if (bytes.length > 512 * 1024) {
        skippedLarge = true;
        continue;
      }
      accepted.add(_ContactPhoto(name: file.name, bytes: bytes));
    }
    setState(() => _photos.addAll(accepted));
    if (skippedLarge) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Each photo must be 512 KB or smaller.')),
      );
    }
    if (result.files.length > remaining) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You can attach up to five photos.')),
      );
    }
  }
}

class _ContactPhoto {
  const _ContactPhoto({required this.name, required this.bytes});
  final String name;
  final Uint8List bytes;
}

class _FaqTile extends StatelessWidget {
  const _FaqTile({required this.question, required this.answer});
  final String question;
  final String answer;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(13),
        side: BorderSide(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
        ),
        tilePadding: const EdgeInsets.symmetric(horizontal: 11),
        childrenPadding: const EdgeInsets.fromLTRB(11, 0, 11, 11),
        visualDensity: VisualDensity.compact,
        children: [
          Text(
            answer,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 9,
              height: 1.4,
            ),
          ),
        ],
      ),
    ),
  );
}
