import 'dart:convert';

import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../widgets/admin_page_frame.dart';
import '../../services/api_service.dart';

class AdminSupportScreen extends StatefulWidget {
  const AdminSupportScreen({super.key});

  @override
  State<AdminSupportScreen> createState() => _AdminSupportScreenState();
}

class _AdminSupportScreenState extends State<AdminSupportScreen> {
  final _api = ApiService();
  List<Map<String, dynamic>> _messages = [];
  bool _loading = true;
  String? _error;
  String? _savingId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final response = await _api.get<Map<String, dynamic>>(
      '/admin/contact-messages',
      fromJson: (json) => json is Map<String, dynamic>
          ? json
          : throw const FormatException('Invalid support response.'),
    );
    if (!mounted) return;
    final rows = response.data?['messages'];
    if (!response.success || rows is! List) {
      setState(() {
        _loading = false;
        _error = response.error ?? 'Unable to load support messages.';
      });
      return;
    }
    setState(() {
      _messages = rows.whereType<Map<String, dynamic>>().toList();
      _loading = false;
    });
  }

  Future<void> _setStatus(Map<String, dynamic> message, String status) async {
    final id = message['id'].toString();
    setState(() => _savingId = id);
    final response = await _api.put<Map<String, dynamic>>(
      '/admin/contact-messages/${Uri.encodeComponent(id)}',
      body: {'status': status},
      fromJson: (json) => json is Map<String, dynamic>
          ? json
          : throw const FormatException('Invalid support status response.'),
    );
    if (!mounted) return;
    setState(() => _savingId = null);
    if (!response.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response.error ?? 'Unable to update status.')),
      );
      return;
    }
    setState(() => message['status'] = status);
  }

  Future<void> _showAttachments(Map<String, dynamic> message) async {
    final id = message['id'].toString();
    final response = await _api.get<Map<String, dynamic>>(
      '/admin/contact-messages/$id/attachments',
      fromJson: (json) => json is Map<String, dynamic>
          ? json
          : throw const FormatException(
              'Invalid support attachments response.',
            ),
    );
    if (!mounted) return;
    final raw = response.data?['attachments'];
    if (!response.success || raw is! List) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response.error ?? 'Unable to load photos.')),
      );
      return;
    }
    final photos = raw.whereType<Map<String, dynamic>>().toList();
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Customer photos'),
        content: SizedBox(
          width: 440,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final photo in photos)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          photo['name'] as String? ?? 'Photo',
                          style: const TextStyle(fontSize: 11),
                        ),
                        const SizedBox(height: 5),
                        Image.memory(
                          base64Decode(photo['image_base64'] as String),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.pageBackground,
    appBar: AppBar(
      title: const Text('Support inbox'),
      actions: [
        IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded)),
      ],
    ),
    body: AdminPageFrame(
      child: _loading && _messages.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _messages.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _load,
                      child: const Text('Try again'),
                    ),
                  ],
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: _messages.isEmpty
                  ? ListView(
                      children: [
                        SizedBox(height: 180),
                        Icon(
                          Icons.inbox_outlined,
                          size: 42,
                          color: AppColors.textSecondary,
                        ),
                        SizedBox(height: 12),
                        Center(child: Text('No support messages yet.')),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) =>
                          _messageCard(_messages[index]),
                    ),
            ),
    ),
  );

  Widget _messageCard(Map<String, dynamic> message) {
    final id = message['id'].toString();
    final status = message['status'] as String? ?? 'new';
    final createdAt = DateTime.tryParse(message['created_at'] as String? ?? '');
    return Container(
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
              Expanded(
                child: Text(
                  message['topic'] as String? ?? 'Support request',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              PopupMenuButton<String>(
                enabled: _savingId != id,
                initialValue: status,
                onSelected: (value) => _setStatus(message, value),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'new', child: Text('New')),
                  PopupMenuItem(
                    value: 'in_progress',
                    child: Text('In progress'),
                  ),
                  PopupMenuItem(value: 'resolved', child: Text('Resolved')),
                ],
                child: Chip(
                  label: Text(
                    _savingId == id ? 'Saving…' : _statusLabel(status),
                  ),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
          Text(
            '${message['full_name'] ?? ''} · ${message['email_or_phone'] ?? ''}',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
          ),
          if (createdAt != null) ...[
            const SizedBox(height: 3),
            Text(
              '${createdAt.toLocal()}',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 9),
            ),
          ],
          const Divider(height: 18),
          Text(message['message'] as String? ?? ''),
          if ((message['attachment_count'] as num?)?.toInt() case final count?
              when count > 0) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: () => _showAttachments(message),
                icon: const Icon(Icons.photo_library_outlined, size: 16),
                label: Text('View $count photo${count == 1 ? '' : 's'}'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _statusLabel(String status) => switch (status) {
    'in_progress' => 'In progress',
    'resolved' => 'Resolved',
    _ => 'New',
  };
}
