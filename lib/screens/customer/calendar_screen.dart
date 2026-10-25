import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../models/calendar_reminder.dart';
import '../../providers/calendar_reminders_provider.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/reminder_notification_service.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final ApiService _api = ApiService();
  DateTime _selectedDate = DateUtils.dateOnly(DateTime.now());
  List<CalendarReminder> _reminders = const [];
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  Future<void> _loadReminders() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    final response = await _api.get<Map<String, dynamic>>(
      '/me/calendar-reminders',
      fromJson: (json) => json is Map<String, dynamic>
          ? json
          : throw const FormatException('Invalid calendar response.'),
    );
    if (!mounted) return;
    final rawReminders = response.data?['reminders'];
    if (!response.success || rawReminders is! List) {
      setState(() {
        _isLoading = false;
        _errorMessage = response.error ?? 'Unable to load saved reminders.';
      });
      return;
    }
    try {
      final reminders =
          rawReminders
              .whereType<Map<String, dynamic>>()
              .map(CalendarReminder.fromJson)
              .toList(growable: false)
            ..sort((a, b) => a.dueAt.compareTo(b.dueAt));
      setState(() {
        _reminders = reminders;
        _isLoading = false;
        _errorMessage = null;
      });
      context.read<CalendarRemindersProvider>().setReminders(reminders);
    } on FormatException {
      setState(() {
        _isLoading = false;
        _errorMessage = 'The server returned an invalid reminder.';
      });
    }
  }

  Future<void> _showReminderEditor([CalendarReminder? reminder]) async {
    final draft = await showDialog<_ReminderDraft>(
      context: context,
      builder: (context) => _ReminderEditorDialog(
        initialDate: reminder?.date ?? _selectedDate,
        initialTime: reminder?.time ?? const TimeOfDay(hour: 9, minute: 0),
        initialTitle: reminder?.title ?? '',
        initialNotes: reminder?.notes ?? '',
      ),
    );
    if (draft == null || !mounted) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });
    final body = {
      'reminder_date': _dateKey(draft.date),
      'reminder_time': _timeKey(draft.time),
      'title': draft.title,
      'notes': draft.notes,
    };
    final response = reminder == null
        ? await _api.post<Map<String, dynamic>>(
            '/me/calendar-reminders',
            body: body,
            fromJson: (json) => json is Map<String, dynamic>
                ? json
                : throw const FormatException('Invalid reminder response.'),
          )
        : await _api.put<Map<String, dynamic>>(
            '/me/calendar-reminders/${reminder.id}',
            body: body,
            fromJson: (json) => json is Map<String, dynamic>
                ? json
                : throw const FormatException('Invalid reminder response.'),
          );
    if (!mounted) return;
    setState(() {
      _isSaving = false;
      if (response.success) _selectedDate = draft.date;
      if (!response.success) {
        _errorMessage = response.error ?? 'Unable to save this reminder.';
      }
    });
    if (response.success) {
      await _loadReminders();
    }
  }

  Future<void> _deleteReminder(CalendarReminder reminder) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete reminder?'),
        content: Text('“${reminder.title}” will be removed from your account.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });
    final response = await _api.delete<Map<String, dynamic>>(
      '/me/calendar-reminders/${reminder.id}',
      fromJson: (json) => json is Map<String, dynamic>
          ? json
          : throw const FormatException('Invalid delete response.'),
    );
    if (!mounted) return;
    setState(() {
      _isSaving = false;
      if (!response.success) {
        _errorMessage = response.error ?? 'Unable to delete this reminder.';
      }
    });
    if (response.success) await _loadReminders();
  }

  Future<void> _enableBrowserNotifications() async {
    final enabled = await ReminderNotificationService.requestPermission();
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          enabled ? 'Browser reminders are enabled.' : 'Notifications were not enabled. In-app reminders will still appear while BurgerBites is open.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final createdAt = context.watch<AuthService>().currentUserCreatedAt;
    final monthReminders = _reminders
        .where(
          (reminder) =>
              reminder.date.year == _selectedDate.year &&
              reminder.date.month == _selectedDate.month,
        )
        .toList(growable: false);

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(title: const Text('Calendar & reminders')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(17, 4, 17, 22),
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'ACCOUNT · PERSONAL REMINDERS',
              style: TextStyle(
                color: AppColors.brandOrange,
                fontSize: 8,
                fontWeight: FontWeight.w900,
                letterSpacing: .4,
              ),
            ),
          ),
          const SizedBox(height: 11),
          const Text(
            'Kalendaryo ug mga Petsa',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            'Save important BurgerBites dates to your account.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 10),
          ),
          const SizedBox(height: 12),
          if (createdAt != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.celebration_outlined,
                    color: AppColors.brandOrange,
                    size: 19,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Account created',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          DateFormat('MMMM d, y · h:mm a')
                              .format(createdAt.toLocal()),
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(17),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Icon(
                        Icons.event_available_rounded,
                        color: AppColors.brandOrange,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your account calendar',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            'Choose a date to view or add reminders',
                            style: TextStyle(
                              fontSize: 8,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _formatDate(_selectedDate),
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: AppColors.brandOrange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                CalendarDatePicker(
                  firstDate: DateTime(DateTime.now().year - 5),
                  lastDate: DateTime(DateTime.now().year + 10),
                  initialDate: _selectedDate,
                  currentDate: DateTime.now(),
                  onDateChanged: (value) =>
                      setState(() => _selectedDate = DateUtils.dateOnly(value)),
                ),
                Text(
                  'Today is highlighted; saved reminders appear below.',
                  style: TextStyle(fontSize: 8, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Saved reminders',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
                ),
              ),
              Text(
                _formatMonth(_selectedDate),
                style: TextStyle(color: AppColors.textSecondary, fontSize: 9),
              ),
            ],
          ),
          const SizedBox(height: 7),
          if (_isLoading) const LinearProgressIndicator(minHeight: 2),
          if (_errorMessage != null)
            _MessageCard(
              icon: Icons.cloud_off_rounded,
              message: _errorMessage!,
              actionLabel: 'Retry',
              onAction: _isSaving || _isLoading ? null : _loadReminders,
            ),
          if (!_isLoading && _errorMessage == null && monthReminders.isEmpty)
            const _MessageCard(
              icon: Icons.event_note_rounded,
              message: 'No reminders saved for this month yet.',
            ),
          for (final reminder in monthReminders)
            _ReminderTile(
              reminder: reminder,
              onEdit: _isSaving ? null : () => _showReminderEditor(reminder),
              onDelete: _isSaving ? null : () => _deleteReminder(reminder),
            ),
          const SizedBox(height: 5),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: AppColors.brandOrange,
                  size: 15,
                ),
                SizedBox(width: 7),
                Expanded(
                  child: Text(
                    'Reminders save to your account. At the saved time, BurgerBites alerts you while the app is open.',
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
          if (ReminderNotificationService.isSupported) ...[
            const SizedBox(height: 5),
            if (ReminderNotificationService.permission == 'granted')
              const Align(
                alignment: Alignment.centerRight,
                child: Chip(
                  avatar: Icon(Icons.notifications_active_rounded, size: 14),
                  label: Text('Browser notifications enabled'),
                  visualDensity: VisualDensity.compact,
                ),
              )
            else if (ReminderNotificationService.permission == 'denied')
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Browser notifications are blocked in site settings.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 9),
                ),
              )
            else
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _enableBrowserNotifications,
                  icon: const Icon(Icons.notifications_active_outlined),
                  label: const Text('Enable browser notifications'),
                ),
              ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            height: 44,
            child: ElevatedButton.icon(
              onPressed: _isLoading || _isSaving
                  ? null
                  : () => _showReminderEditor(),
              icon: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.add_rounded, size: 17),
              label: Text(
                _isSaving
                    ? 'Saving…'
                    : 'Add reminder for ${_formatDate(_selectedDate)}',
              ),
            ),
          ),
          const SizedBox(height: 6),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).pushNamed('/order-history'),
            icon: const Icon(Icons.receipt_long_rounded, size: 16),
            label: const Text('View order history'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) => '${date.month}/${date.day}/${date.year}';
  String _formatMonth(DateTime date) =>
      '${_monthName(date.month)} ${date.year}';
  String _dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  String _timeKey(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  String _monthName(int month) => const [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ][month - 1];
}

class _ReminderDraft {
  const _ReminderDraft({
    required this.date,
    required this.time,
    required this.title,
    required this.notes,
  });

  final DateTime date;
  final TimeOfDay time;
  final String title;
  final String notes;
}

class _ReminderEditorDialog extends StatefulWidget {
  const _ReminderEditorDialog({
    required this.initialDate,
    required this.initialTime,
    required this.initialTitle,
    required this.initialNotes,
  });

  final DateTime initialDate;
  final TimeOfDay initialTime;
  final String initialTitle;
  final String initialNotes;

  @override
  State<_ReminderEditorDialog> createState() => _ReminderEditorDialogState();
}

class _ReminderEditorDialogState extends State<_ReminderEditorDialog> {
  late final TextEditingController _titleController = TextEditingController(
    text: widget.initialTitle,
  );
  late final TextEditingController _notesController = TextEditingController(
    text: widget.initialNotes,
  );
  late DateTime _date = widget.initialDate;
  late TimeOfDay _time = widget.initialTime;
  String? _validationMessage;

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _chooseDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(DateTime.now().year - 5),
      lastDate: DateTime(DateTime.now().year + 10),
    );
    if (picked != null) setState(() => _date = DateUtils.dateOnly(picked));
  }

  Future<void> _chooseTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  void _save() {
    final title = _titleController.text.trim();
    final notes = _notesController.text.trim();
    if (title.length < 2) {
      setState(
        () => _validationMessage = 'Enter a title with at least 2 characters.',
      );
      return;
    }
    if (title.length > 100 || notes.length > 500) {
      setState(
        () => _validationMessage = 'Title or notes exceed the allowed length.',
      );
      return;
    }
    Navigator.of(
      context,
    ).pop(_ReminderDraft(date: _date, time: _time, title: title, notes: notes));
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(
      widget.initialTitle.isEmpty ? 'Add a reminder' : 'Edit reminder',
    ),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _titleController,
            autofocus: true,
            maxLength: 100,
            decoration: const InputDecoration(labelText: 'Title'),
          ),
          TextField(
            controller: _notesController,
            maxLength: 500,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Notes (optional)'),
          ),
          TextButton.icon(
            onPressed: _chooseDate,
            icon: const Icon(Icons.calendar_month_rounded),
            label: Text('Date: ${_date.month}/${_date.day}/${_date.year}'),
          ),
          TextButton.icon(
            onPressed: _chooseTime,
            icon: const Icon(Icons.schedule_rounded),
            label: Text('Time: ${_time.format(context)}'),
          ),
          if (_validationMessage != null)
            Text(
              _validationMessage!,
              style: const TextStyle(color: AppColors.danger, fontSize: 12),
            ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      ElevatedButton(onPressed: _save, child: const Text('Save')),
    ],
  );
}

class _ReminderTile extends StatelessWidget {
  const _ReminderTile({
    required this.reminder,
    required this.onEdit,
    required this.onDelete,
  });

  final CalendarReminder reminder;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 7),
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.border),
    ),
    child: Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.event_note_rounded,
            color: AppColors.brandOrange,
            size: 16,
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                reminder.title,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${reminder.date.month}/${reminder.date.day}/${reminder.date.year} · ${reminder.time.format(context)}${reminder.notes == null ? '' : ' · ${reminder.notes}'}',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 9),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Edit reminder',
          visualDensity: VisualDensity.compact,
          onPressed: onEdit,
          icon: const Icon(Icons.edit_outlined, size: 16),
        ),
        IconButton(
          tooltip: 'Delete reminder',
          visualDensity: VisualDensity.compact,
          onPressed: onDelete,
          icon: const Icon(
            Icons.delete_outline_rounded,
            color: AppColors.danger,
            size: 16,
          ),
        ),
      ],
    ),
  );
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 7),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.border),
    ),
    child: Row(
      children: [
        Icon(icon, color: AppColors.brandOrange, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(message, style: const TextStyle(fontSize: 10))),
        if (actionLabel != null)
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
      ],
    ),
  );
}
