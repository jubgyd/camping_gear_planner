// Fallback used only if neither dart:io nor dart:html is available.

Future<void> saveTextFile(String path, String text) async =>
    throw UnsupportedError('No native file access on this platform');

Future<String> readTextFile(String path) async =>
    throw UnsupportedError('No native file access on this platform');

bool get isMobilePlatform => false;

Future<bool> downloadTextFile(String fileName, String text) async =>
    throw UnsupportedError('No native file access on this platform');
