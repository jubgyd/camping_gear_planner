import 'dart:io';

/// Native (desktop/mobile) file access. `file_picker.saveFile` returns a path
/// on desktop without writing, so the app writes the contents here.
Future<void> saveTextFile(String path, String text) =>
    File(path).writeAsString(text);

Future<String> readTextFile(String path) => File(path).readAsString();

bool get isMobilePlatform => Platform.isAndroid || Platform.isIOS;

/// Web-only: native platforms save through the file_picker dialog instead.
Future<bool> downloadTextFile(String fileName, String text) async =>
    throw UnsupportedError('downloadTextFile is web-only');
