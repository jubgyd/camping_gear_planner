import 'dart:io';

/// Native (desktop/mobile) file access. `file_picker.saveFile` returns a path
/// on desktop without writing, so the app writes the contents here.
Future<void> saveTextFile(String path, String text) =>
    File(path).writeAsString(text);

Future<String> readTextFile(String path) => File(path).readAsString();

bool get isMobilePlatform => Platform.isAndroid || Platform.isIOS;
