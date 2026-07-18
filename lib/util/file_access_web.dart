// Web build: `file_picker.saveFile` performs the download directly from the
// bytes it is given, and import reads from in-memory bytes — so these native
// helpers are never exercised on web. They exist only to satisfy the shared
// interface without pulling in `dart:io`.

Future<void> saveTextFile(String path, String text) async {
  // no-op: the browser download is handled by file_picker.
}

Future<String> readTextFile(String path) async =>
    throw UnsupportedError('readTextFile is not used on web');

bool get isMobilePlatform => false;
