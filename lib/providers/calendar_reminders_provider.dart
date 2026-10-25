import 'dart:async';

import 'package:flutter/material.dart';

import '../models/calendar_reminder.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/reminder_notification_service.dart';
import '../widgets/app_scaffold_messenger.dart';

class CalendarRemindersProvider extends ChangeNotifier {
  CalendarRemindersProvider(this._authService, this._apiService) {
    _authService.addListener(_syncSignedInUser);
    _syncSignedInUser();
  }

  final AuthService _authService;
  final ApiService _apiService;
  final Set<String> _notifiedReminderKeys = {};
  List<CalendarReminder> _reminders = const [];
  Timer? _dueTimer;
  String? _activeUserId;

  void _syncSignedInUser() {
    final nextUserId =
        _authService.isAuthenticated &&
            _authService.currentUserRole == 'customer'
        ? _authService.currentUserId
        : null;
    if (nextUserId == _activeUserId) return;

    _activeUserId = nextUserId;
    _reminders = const [];
    _notifiedReminderKeys.clear();
    _dueTimer?.cancel();
    if (nextUserId != null) unawaited(refresh());
  }

  Future<void> refresh() async {
    final userId = _activeUserId;
    if (userId == null) return;
    final response = await _apiService.get<Map<String, dynamic>>(
      '/me/calendar-reminders',
      fromJson: (json) => json is Map<String, dynamic>
          ? json
          : throw const FormatException('Invalid calendar response.'),
    );
    if (userId != _activeUserId || !response.success) return;

    final rawReminders = response.data?['reminders'];
    if (rawReminders is! List) return;
    try {
      final reminders = rawReminders
          .whereType<Map<String, dynamic>>()
          .map(CalendarReminder.fromJson)
          .toList(growable: false);
      setReminders(reminders);
    } on FormatException {
      // The Calendar screen shows the API/data error. Keep the last schedule.
    }
  }

  void setReminders(List<CalendarReminder> reminders) {
    if (_activeUserId == null) return;
    _reminders = List.unmodifiable(reminders);
    _scheduleNextDueReminder();
  }

  void _scheduleNextDueReminder() {
    _dueTimer?.cancel();
    _deliverDueReminders();

    final now = DateTime.now();
    final futureReminders =
        _reminders
            .where(
              (reminder) =>
                  reminder.dueAt.isAfter(now) &&
                  !_notifiedReminderKeys.contains(_reminderKey(reminder)),
            )
            .toList()
          ..sort((a, b) => a.dueAt.compareTo(b.dueAt));
    if (futureReminders.isEmpty) return;

    final remaining = futureReminders.first.dueAt.difference(now);
    final delay = remaining > const Duration(days: 1)
        ? const Duration(days: 1)
        : remaining;
    _dueTimer = Timer(delay, _scheduleNextDueReminder);
  }

  void _deliverDueReminders() {
    final now = DateTime.now();
    for (final reminder in _reminders) {
      final dueAt = reminder.dueAt;
      if (dueAt.isAfter(now) ||
          now.difference(dueAt) > const Duration(hours: 24)) {
        continue;
      }
      final key = _reminderKey(reminder);
      if (!_notifiedReminderKeys.add(key)) continue;

      final body = reminder.notes?.trim().isNotEmpty == true
          ? reminder.notes!.trim()
          : 'Your saved reminder is due now.';
      final shownAsSystemNotification = ReminderNotificationService.show(
        title: reminder.title,
        body: body,
        tag: key,
      );
      if (!shownAsSystemNotification) {
        appScaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text('Reminder: ${reminder.title}'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 10),
          ),
        );
      }
    }
  }

  String _reminderKey(CalendarReminder reminder) =>
      '${reminder.id}:${reminder.dueAt.toIso8601String()}';

  @override
  void dispose() {
    _authService.removeListener(_syncSignedInUser);
    _dueTimer?.cancel();
    super.dispose();
  }
}
