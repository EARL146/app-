// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;

bool get isSupported => html.Notification.supported;

String get permission => html.Notification.permission ?? 'unsupported';

Future<bool> requestPermission() async {
  if (!isSupported) return false;
  if (permission == 'granted') return true;
  if (permission == 'denied') return false;
  try {
    return await html.Notification.requestPermission() == 'granted';
  } catch (_) {
    return false;
  }
}

bool show({required String title, required String body, required String tag}) {
  if (!isSupported || permission != 'granted') return false;
  try {
    html.Notification(title, body: body, tag: tag);
    return true;
  } catch (_) {
    return false;
  }
}
