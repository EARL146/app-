import 'package:flutter/material.dart';

class CalendarReminder {
  const CalendarReminder({
    required this.id,
    required this.date,
    required this.time,
    required this.title,
    this.notes,
  });

  final String id;
  final DateTime date;
  final TimeOfDay time;
  final String title;
  final String? notes;

  DateTime get dueAt =>
      DateTime(date.year, date.month, date.day, time.hour, time.minute);

  factory CalendarReminder.fromJson(Map<String, dynamic> json) {
    final rawDate = json['reminder_date'];
    final rawTime = json['reminder_time'] as String? ?? '09:00';
    if (rawDate is! String) {
      throw const FormatException('Invalid reminder date.');
    }
    final date = DateTime.tryParse('${rawDate}T00:00:00');
    final timeParts = rawTime.split(':');
    final hour = timeParts.isNotEmpty ? int.tryParse(timeParts[0]) : null;
    final minute = timeParts.length > 1 ? int.tryParse(timeParts[1]) : null;
    if (date == null ||
        hour == null ||
        minute == null ||
        hour < 0 ||
        hour > 23 ||
        minute < 0 ||
        minute > 59) {
      throw const FormatException('Invalid reminder date or time.');
    }
    return CalendarReminder(
      id: json['id'].toString(),
      date: date,
      time: TimeOfDay(hour: hour, minute: minute),
      title: json['title'] as String? ?? 'Reminder',
      notes: json['notes'] as String?,
    );
  }
}
