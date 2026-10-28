import 'dart:js_interop';

import 'package:flutter/widgets.dart';

@JS('window.open')
external JSAny? _windowOpen(JSString url, JSString target);

/// Opens Google Maps in a new browser tab on Flutter Web.
Future<void> openExternalGoogleMapsUrl(BuildContext context, String url) async {
  _windowOpen(url.toJS, '_blank'.toJS);
}
