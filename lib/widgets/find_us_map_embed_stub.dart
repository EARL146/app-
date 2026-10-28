import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Opens an external Google Maps URL, falling back to copying the link on non-web.
Future<void> openExternalGoogleMapsUrl(BuildContext context, String url) async {
  await Clipboard.setData(ClipboardData(text: url));
  if (!context.mounted) return;
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    const SnackBar(
      content: Text('Google Maps link copied to clipboard'),
      behavior: SnackBarBehavior.floating,
      duration: Duration(seconds: 2),
    ),
  );
}
