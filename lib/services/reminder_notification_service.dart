import 'reminder_notifications_stub.dart'
    if (dart.library.html) 'reminder_notifications_web.dart'
    as platform;

class ReminderNotificationService {
  const ReminderNotificationService._();

  static bool get isSupported => platform.isSupported;
  static String get permission => platform.permission;

  static Future<bool> requestPermission() => platform.requestPermission();

  static bool show({
    required String title,
    required String body,
    required String tag,
  }) => platform.show(title: title, body: body, tag: tag);
}
