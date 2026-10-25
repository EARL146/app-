bool get isSupported => false;

String get permission => 'unsupported';

Future<bool> requestPermission() async => false;

bool show({required String title, required String body, required String tag}) =>
    false;
